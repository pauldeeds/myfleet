use strict;
use diagnostics;

use CGI;
use DBD::mysql;
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;

use Data::ICal;
use Date::ICal;
use Data::ICal::Entry;
use Data::ICal::Entry::Event;

package Myfleet::Regatta;

use MyfleetConfig qw(%config);

sub regatta
{
	my $regattaid = shift;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select regatta.id, year(startDate) as 'year', startdate orderdate, date_format(regatta.startdate,'%M %e') startdate, date_format(regatta.enddate,'%M %e') enddate, unix_timestamp(startdate) as epoch_start, unix_timestamp(enddate) as epoch_end, date_format(regatta.startdate,'%Y%m%d') as ical_start, date_format(regatta.enddate,'%Y%m%d') as ical_end, regatta.name, venue.id venueid, venue.name venuename, regatta.series1, regatta.series2, regatta.series3, regatta.series4, regatta.series5, regatta.series6, regatta.series7, regatta.url, ! isnull(regatta.result) hasresult, result,  ! isnull(regatta.description) hasdescription, ! isnull(regatta.story) hasstory from regatta, venue where regatta.venue = venue.id and regatta.id = ?") || die $DBI::errstr;
	$sth->execute($regattaid) || die $DBI::errstr;
	my $regatta = $sth->fetchrow_hashref;
	return $regatta;
}

# listing of all events for a year
sub display_events
{
	my $year = shift;
	my $mode = shift || "Regular";
	my $seriesDbName = shift || '';
	my $calendar = shift || 0;

	# my $calendar = Data::ICal->new();

	my @ret;

	push @ret, '<table cellpadding="4" cellspacing="0" width="100%">';

	my $series;
	my $seriesSql = '';
	foreach my $s ( @{$config{'series'}} ) {
		$series->{$s->{'dbname'}} = $s;
		if( $seriesDbName eq $s->{'dbname'} ) { $seriesSql = " $seriesDbName > 0 and "; }
	}

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select regatta.id, startdate orderdate, date_format(regatta.startdate,'%M %e') startdate, date_format(regatta.enddate,'%M %e') enddate, unix_timestamp(startdate) as epoch_start, unix_timestamp(enddate) as epoch_end, date_format(regatta.startdate,'%Y%m%d') as ical_start, date_format(regatta.enddate,'%Y%m%d') as ical_end, regatta.name, venue.id venueid, venue.name venuename, regatta.series1, regatta.series2, regatta.series3, regatta.series4, regatta.series5, regatta.series6, regatta.series7, regatta.url, ! isnull(regatta.result) hasresult, result,  ! isnull(regatta.description) hasdescription, ! isnull(regatta.story) hasstory from regatta, venue where $seriesSql regatta.venue = venue.id and year(startdate) = ? order by orderdate, series1, series2, series3, series4, series5, series6, series7") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;


	my $count = 0;
	while ( my $regatta = $sth->fetchrow_hashref )
	{
		my $bgcolor = ( $count++ % 2 == 0 ? "#efefd1" : "#ffffff" );

		my $bold = '';
		my $italic = '';
		my $asterisk = '';
		my $fgcolor = 'black';
		foreach my $series ( @{$config{'series'}} ) {
			if( $regatta->{$series->{'dbname'}} ) {
				if( $series->{'style'} =~ /asterisk$/ ) { $asterisk = 1; }
				elsif( $series->{'style'} =~ /bold$/ ) { $bold = 1; }
				elsif( $series->{'style'} =~ /italic$/ ) { $italic = 1; }

				if( $series->{'style'} =~ /^([a-z]+) / ) { $fgcolor = $1; }
			}
		}

		my $boats = 0;
		my $looking = 0;
		my $races = 0;

		if ( $regatta->{hasresult} ) {
			my ( @allboats ) = split /\n/, $regatta->{result};
			$boats = scalar( @allboats );
			my ( @boat ) = split /,/, $allboats[0];
			my $noname = 0;
			if ( $boat[2] =~ /\d+/ || $boat[2] =~ /DNS|DNF|DSQ|RET/ ) { $noname = 1; }
			$races = ( scalar @boat ) - ( 4 - $noname );
			if ( $races == 0 ) { $races = 1; }
		}
		else
		{
			my $stz = $dbh->prepare("select count(distinct sailnumber) from boats where regattaid = ? and status = 'Sailing'");
			$stz->execute( $regatta->{id} );
			( $boats ) = $stz->fetchrow_array;

			$stz = $dbh->prepare("select count(distinct sailnumber) from boats where regattaid = ? and status = 'Looking'");
			$stz->execute( $regatta->{id} );
			( $looking ) = $stz->fetchrow_array;
		}

		push @ret,
			"<tr bgcolor=\"$bgcolor\">",
				'<td>',
					( $mode eq 'Edit' ? "<a href=\"$regatta->{id}\">Edit</a>" :
						join('',
							( $regatta->{hasresult} ? "<a href=\"$regatta->{id}#Result\">Result</a> " : "" ),
							( $regatta->{hasstory} ? "<a href=\"$regatta->{id}#Story\">Story</a>" : "" ),
							( ! $regatta->{hasresult} && ! $regatta->{hasstory} ? "<a href=\"$regatta->{id}\">Details</a>" : "" ),
						)
					),
				'</td>',
				'<td style="color:', $fgcolor, '">',
					($bold?'<b>':''),
					($italic?'<i>':''),
					$regatta->{name},
					($asterisk ? ' *':''),
					'<br/>',
					"<small>$regatta->{venuename}</small>",
					($italic?'</i>':''),
					($bold?'</b>':''),
				'</td>',
				'<td>',
					( $regatta->{hasresult} ? "$boats boats<br/><small>$races races" : "$boats sailing" . ( $looking ? "<br/><small>$looking looking</small>" : "") ),
				'</td>',
				'<td align="right">',
					($bold?'<b>':''),
					Myfleet::Util::display_date( $regatta->{startdate}, $regatta->{enddate} ),
					($bold?'</b>':''),
				'</td>',
			'</tr>';


		if( $calendar )
		{
			my $vevent = Data::ICal::Entry::Event->new();
			$vevent->add_properties(
				'summary' => "$regatta->{name}",
				'location' => $regatta->{venuename},
				# 'description' => '',
		  		# 'dtstart' => Date::ICal->new( epoch => $regatta->{epoch_start} )->ical,
		  		# 'dtend' => Date::ICal->new( epoch => $regatta->{epoch_end} )->ical,
				'DTSTART;VALUE=DATE' => $regatta->{ical_start},
		  		'url' => 'http://' . $config{'domain'} . '/schedule/' . $regatta->{id},
				'UID' => $config{'domain'} . '__' . $regatta->{id},
				'DTSTAMP' => Date::ICal->new()->ical,
			);

			if( $regatta->{ical_end} && $regatta->{ical_end} != $regatta->{ical_start} )
			{
				$vevent->add_properties(
					'DTEND;VALUE=DATE' => $regatta->{ical_end}
				);
			}
		 	$calendar->add_entry($vevent);
		 }
	}

	push @ret, "</table>";

	if( $calendar ) { return $calendar; }

	return @ret;
}

sub display_regatta_header
{
	my $q = shift;

	my $id = $q->param('r') || $q->param('f') - 1000;
	my $detail = $q->param('d');

	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, date_format(startdate,'%M %e') startdate, date_format(enddate,'%M %e') enddate, date_format(startdate,'%Y') as year, name, venue, contact, series1, series2, series3, series4, series5, series6, series7,  url, result, description, story from regatta where id = ?") || die $DBI::errstr;
	$sth->execute($id) || die $DBI::errstr;

	if ($sth->rows)
	{
		my ( $regatta ) = $sth->fetchrow_hashref;

		$sth = $dbh->prepare("select id, name, url from venue where id = ?");
		$sth->execute($regatta->{venue});
		my ( $venue ) = $sth->fetchrow_hashref;

		$venue->{url} =~ s/^http:\/\///i;

		push @ret,
			Myfleet::Header::display_header( $config{'EventsMenu'}, '..', "$regatta->{'name'} @ $venue->{'name'} ($regatta->{'year'}) - $config{'defaultTitle'}" ),
			'<br/>',
			'<table border="0" cellpadding="4" cellspacing="2" width="100%">',
				'<tr bgcolor="silver">',
					'<td align="center">',
						"<big>$regatta->{name}</big>",
						( $regatta->{venue} ? ( $venue->{url} ? " at <a href=\"http://$venue->{url}\">$venue->{name}</a>" : " at $venue->{name}" ) : ""),
					'</td>',
					'<td align="center"><b>',
						Myfleet::Util::display_date( $regatta->{startdate}, $regatta->{enddate} ),
					'</b></td>',
				'</tr>',
			"</table>";
	}

	return @ret;
}

sub regatta_has_results
{
	my $id = shift;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select ! isnull(result) hasresult, ! isnull(story) hasstory from regatta where id = ?") || die $DBI::errstr;
	$sth->execute( $id ) || die $DBI::errstr;
	my ( $hasresult, $hasstory ) = $sth->fetchrow_array;
	return ( $hasresult or $hasstory );
}

sub display_regatta_csv
{
	my $q = shift;
	my $id = $q->param('r') || $q->param('f') - 1000;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, date_format(startdate,'%M %e') startdate, date_format(enddate,'%M %e') enddate, name, venue, contact, series1, series2, series3, series4, series5, series6, series7, url, result, description, story from regatta where id = ?") || die $DBI::errstr;
	$sth->execute($id) || die $DBI::errstr;
	my ( $regatta ) = $sth->fetchrow_hashref;
	return display_regatta_result_csv( $regatta->{result} );
}

sub display_regatta
{
	my $q = shift;
	
	my $id = $q->param('r') || $q->param('f') - 1000;
	my $detail = $q->param('d');

	my @ret;

	my $all_html;
	my $title;
	my @html_array;
	my $num_choices;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, date_format(startdate,'%M %e') startdate, date_format(enddate,'%M %e') enddate, name, venue, contact, series1, series2, series3, series4, series5, series7, series7, url, result, description, story from regatta where id = ?") || die $DBI::errstr;
	$sth->execute($id) || die $DBI::errstr;
	my ( $regatta ) = $sth->fetchrow_hashref;

	$sth = $dbh->prepare("select id, name, url from venue where id = ?") || die $DBI::errstr;
	$sth->execute($regatta->{venue}) || die $DBI::errstr;
	my ( $venue ) = $sth->fetchrow_hashref;

	my $display_ad = 0;
	my $ad = Myfleet::Google::google_ad( -size=>'468x60' );

        # Put event-specific or series-specific sponsor html here (19-feb-07, dbyron).
	
	# Go through the series configuration for this site.  If
	# there's sponsorHtml for a series that this regatta is a part
	# of, display it.
	foreach my $series ( @{$config{'series'}} ) {
	    if( $regatta->{$series->{'dbname'}} ) {
		# This regatta is part of a series configured in this site
		if( $series->{'sponsorHtml'} ) {
		    # There's sponsor HTML for this series
		    push @ret, "<!-- sponsor HTML is $series->{'sponsorHtml'} -->\n";

		    # In case there are multiple things in the custom
		    # HTML, we want to choose one at random.  Use ---
		    # on its own line as the divider and then pick
		    # one.
		    ($all_html, $title) = Myfleet::Util::html($series->{'sponsorHtml'});
		    $num_choices = (@html_array= split(/SEPARATOR/,$all_html));

		    push @ret, "<!-- $num_choices different blocks of HTML to choose from -->\n";

		    # If there are less than 2 choices, just print the entire HTML blob
		    if ( $num_choices < 2 )
		    {
			push @ret, $all_html;
		    } else {
			# Choose a random array element.  For now just choose 1.
			my $array_element = int(rand($num_choices));
			push @ret, $html_array[$array_element];
		    }
		}
	    }
	}


	if ( ! $detail && $regatta->{result} )
	{
		if ( $regatta->{story} )
		{
			my $story = $regatta->{story};
			$story =~ s/\n/<br>/g;
			push @ret,
				'<a name="Story"></a>',
				'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
					'<tr>',
						'<td bgcolor="blue">',
							'<big><font color="white">Story</font></big>',
						'</td>',
					'</tr>',
					'<tr>',
						'<td>',
							$story,
							( $display_ad ? "<br/><br/><center>$ad</center><br/><br/>" : "" ),
						'</td>',
					'</tr>',
				'</table>';
		}

		push @ret, "<a name=\"Result\"></a><table border=0 cellpadding=4 cellspacing=0 width=\"100%\">",
			"<tr>",
				"<td bgcolor=green>",
					"<big><font color=white>Result</font></big>",
				'</td>',
			"<tr><td>",
				display_regatta_result( $regatta->{result} ),
			"</table>",
			'<a rel="nofollow" href="?csv=1">export csv</a><br/>';
	} else {
		$sth = $dbh->prepare("select id, firstname, lastname, city, state, email from person where id = ?");
		$sth->execute( $regatta->{contact} );
		my ( $contact ) = $sth->fetchrow_hashref;

		if ( $regatta->{description} ) {
			push @ret, "<table border=0 cellpadding=4 cellspacing=0>",
				"<tr><td bgcolor=blue><big><font color=white>Info</font></big></td>",
				"<tr><td>$regatta->{description}",
				"</table>\n";
		}


		if ( $contact->{firstname} && $contact->{lastname} && $contact->{email} )
		{
			push @ret, "<table border=0 cellpadding=4 cellspacing=0 width=\"100%\">",
				"<tr><td bgcolor=purple><big><font color=white>Contact Person</font></big></td></tr>",
				"<tr><td>",
					"<a href=\"mailto:$contact->{email}_REMOVE\">$contact->{firstname} $contact->{lastname}</a>",
				"</td></tr></table>\n";
		}

		push @ret, "<table border=0 cellpadding=4 cellspacing=0 width=\"100%\">",
			"<tr><td bgcolor=green><big><font color=white>Looking for a Ride or Crew</font></big></td></tr>",
			"<tr><td>",
				display_regatta_looking( $q ),
			"</td></tr></table>\n";

		push @ret, "<table border=0 cellpadding=4 cellspacing=0 width=\"100%\">",
			"<tr><td bgcolor=green><big><font color=white>Boats Racing</font></big></td></tr>",
			"<tr><td>",
				display_regatta_boats( $q ),
			"</td></tr></table>\n";
	}
	return @ret;
}

sub display_regatta_looking
{
	my $q = shift;
	my $id = $q->param('r') || $q->param('f') - 1000;

	my @ret;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select sailnumber, skipper, crew boatname, note, date_format(lastupdate,'%b %e %l:%i %p') postdate, lastupdate from boats where regattaid = ? and status = 'Looking' order by lastupdate");
	$sth->execute( $id );

	if ( $sth->rows ) {
		push @ret, "<table border=0 cellpadding=4 cellspacing=0 width=\"100%\">";
		while( my $boat = $sth->fetchrow_hashref ) 
		{
			push @ret,
				"<tr><td><b>",
			( $boat->{sailnumber} ? "#$boat->{sailnumber}" : "&nbsp;" ), "</b></td>";
				
			if ( $boat->{boatname} ) {
				push @ret,
					"<td>$boat->{boatname}",
				( $boat->{skipper} ? " ($boat->{skipper})" : "" ), "</td>";
			} elsif ( $boat->{skipper} ) {
				push @ret, "<td>$boat->{skipper}</td>";
			} else {
				push @ret, "<td>&nbsp;</td>";
			}
			push @ret, ( $boat->{note} ? "<tr><td colspan=3><small>$boat->{note} (<i>$boat->{postdate}</i>)</small></td></tr>" : "" );
		}
		push @ret, "</table>";
	} else {
		push @ret, "None.";
	}

	return @ret;
}

sub display_regatta_form
{
	my $q = shift;
	my @ret;
	if ( $q->cookie('sailnumber') ) { $q->param('sailnumber',$q->cookie('sailnumber')); }
	if ( $q->cookie('boatname') ) { $q->param('boatname',$q->cookie('boatname')); }
	if ( $q->cookie('skipper') ) { $q->param('skipper',$q->cookie('skipper')); }
	push @ret, 
		$q->start_form(-method=>'post'),
		"<center>",
		"<table border=0 cellpadding=2 cellspacing=0 width=\"100%\">",
			"<tr><td><small>Sail Number</small></td><td align=left>", $q->textfield(-name=>'sailnumber', -size=>'20'), "</td>",
			"<tr><td><small>Boat Name</small></td><td align=left>", $q->textfield(-name=>'boatname', -size=>'20'), "</td>", 
			"<tr><td><small>Name</small></td><td align=left>", $q->textfield(-name=>'skipper', -size=>'20'), "</td>", 
			"<tr><td><small>Note</small></td><td align=left>", $q->textarea(-name=>'note', -rows=>'4', -cols=>'28' ), "</td>", 
			"<tr><td colspan=2><center>",
				$q->submit(-name=>'Looking',-value=>'Looking'),
				" ",
				$q->submit(-name=>'Sailing',-value=>'Racing'),
				" ",
				$q->submit(-name=>'NotRacing',-value=>'Remove'),
				$q->hidden(-name=>'r'), "<br/><em><small>Note: To remove an entry fill in just your sail number or your name.<br/>All fields are optional.</small></em></center></td>",
		"</table>",
		"</center>",
                $q->end_form(), "\n";
	return @ret;
}

# used by GPS
sub regattas_by_daterange
{
	# timestamp
	my $mindate = shift;
	my $maxdate = shift; 

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, name FROM regatta WHERE startdate BETWEEN date(from_unixtime(?)) AND date(from_unixtime(?)) OR enddate BETWEEN date(from_unixtime(?)) AND date(from_unixtime(?)) OR (startdate <= from_unixtime(?) AND enddate >= from_unixtime(?)) ") || die $DBI::errstr;
	$sth->execute( $mindate, $maxdate, $mindate, $maxdate, $mindate, $maxdate ) || die $DBI::errstr;

	my @regattas;
	while( my $r = $sth->fetchrow_hashref ) 
	{
		push @regattas, $r;
	}
	
	return @regattas;
}

sub display_regatta_boats
{
	my $q = shift;
	my $id = $q->param('r') || $q->param('f') - 1000;

	my @ret;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select sailnumber, skipper, crew boatname, note, date_format(lastupdate,'%b %e %l:%i %p') postdate, lastupdate from boats where regattaid = ? and status = 'Sailing' order by lastupdate");
	$sth->execute( $id );

	if ( $sth->rows ) {
		push @ret, "<table border=0 cellpadding=4 cellspacing=0 width=\"100%\">";
		while( my $boat = $sth->fetchrow_hashref ) 
		{
			push @ret,
				"<tr><td><small><b>",
				( defined $boat->{sailnumber} ? "#$boat->{sailnumber}" : "&nbsp;" ), "</b></small></td>";
				
			if ( $boat->{boatname} ) {
				push @ret,
					"<td><small>$boat->{boatname}",
					( $boat->{skipper} ? " ($boat->{skipper})" : "" ), "</small></td>";
			} elsif ( $boat->{skipper} ) {
				push @ret, "<td>$boat->{skipper}</td>";
			} else {
				push @ret, "<td>&nbsp;</td>";
			}
			if ( $boat->{note} ) {
				push @ret, "<tr><td colspan=2><small>$boat->{note} (<i>$boat->{postdate}</i>)</small></td>";
			}
		}
		push @ret, "</table>\n";
	} else {
		push @ret, "None.\n";
	}

	return @ret;
}

sub display_regatta_result
{
	my $result = shift;

	my @ret;
	# push @ret, "<pre>$result</pre>";

        my $noname = 0;
        push @ret,"<table width=\"100%\" border=0 cellpadding=2 cellspacing=0>";
        my ( @line ) = split /\n/, $result;
        push @ret,"<tr bgcolor=\"#d1d1d1\">\n";
        my @temp = split /\s*,\s*/, $line[0];
        if ( $temp[2] =~ /\d+/ ) {
                $noname = 1;
        }
        my $numraces = ( scalar @temp ) - (4 - $noname);
        if ( $numraces == -1 )
        {
                if ( $noname ) {
                        push @ret, "<th><small>Pos</small></th><th align=left><small>Boat";
                } else {
                        push @ret, "<th><small>Pos</small></th><th align=left><small>Boat<th align=left><small>Name";
                }
        }
        else
        {
                if ( $noname ) {
                        push @ret, "<th><small>Pos</small></th><th align=left><small>Boat</small></th><th>Total</th>";
                } else {
                        push @ret, "<th><small>Pos</small></th><th align=left><small>Boat</small></th><th align=left><small>Name</small></th><th><small>Total</small></th>";
                }
        }
        my $x = 0;
        while ( $x++ < $numraces ) { push @ret, "<th><small>Race $x</small>"; }
        my $linenum = 0;
        foreach ( @line )
        {
		my $pos;
		my $txt;
		my $tot;
		my @races;
		my $nm;
                if ( $noname ) {
                         ( $pos, $txt, $tot, @races ) = split /\s*,\s*/;
                } else {
                        ( $pos, $txt, $nm, $tot, @races ) = split /\s*,\s*/;
                }
                push @ret, ( $linenum++ % 2 ? "<tr bgcolor=\"#efefd1\">\n" : "<tr bgcolor=white>\n" );
                push @ret, "<td align=center><small><b>$pos</b></small></td>";
                if ( $noname ) {
                        push @ret, "<td><small>$txt</small></td>";
                } else {
                        push @ret, "<td><small>$txt</small></td><td><small>$nm</small></td>";
                }
                push @ret, "<td align=center><small><b>$tot</b></small></td>";
                my $runtot = 0;
                foreach ( @races )
                {
                        my $val = $_;
                        $val =~ s/^\(//;
                        $val =~ s/\)//;

                        $val =~ s/^\[//;
                        $val =~ s/\]//;
			if ( $val =~ /DN/ || $val =~ /OCS/ || $val =~ /RET/ || $val =~ /RAF/ || $val =~ /DSQ/ ) {
				$runtot += scalar( @line ) + 1;
			} else {
                        	$runtot += $val;
			}
                        if ( $numraces > 3 && $runtot != 0 )
                        {
                                push @ret, "<td align=center><small>$_<sub><i>($runtot)</i></sub></small></td>";
                        }
                        else
                        {
                                push @ret, "<td align=center><small>$_</small></td>";
                        }
                }
        }

        push @ret, "</table>";
	return @ret;
}

sub display_regatta_result_csv
{
	my $result = shift;

	my @ret;
	# push @ret, "<pre>$result</pre>";

        my $noname = 0;
        my ( @line ) = split /\n/, $result;
        my @temp = split/,/, $line[0];
        if ( $temp[2] =~ /\d+/ ) {
                $noname = 1;
        }
        my $numraces = ( scalar @temp ) - (4 - $noname);
        if ( $numraces == -1 )
        {
                if ( $noname ) {
                        push @ret, "Pos,Boat";
                } else {
                        push @ret, "Pos,Boat,Name";
                }
        }
        else
        {
                if ( $noname ) {
                        push @ret, "Pos,Boat,Total";
                } else {
                        push @ret, "Pos,Boat,Name,Total";
                }
        }
        my $x = 0;
        while ( $x++ < $numraces ) { push @ret, ",Race $x"; }
		push @ret, "\n";

        my $linenum = 0;
        foreach ( @line )
        {
		my $pos;
		my $txt;
		my $tot;
		my @races;
		my $nm;
                if ( $noname ) {
                         ( $pos, $txt, $tot, @races ) = split /\s*,\s*/;
                } else {
                        ( $pos, $txt, $nm, $tot, @races ) = split /\s*,\s*/;
                }
                push @ret, "$pos";
                if ( $noname ) {
                        push @ret, ",$txt";
                } else {
                        push @ret, ",$txt,$nm";
                }
                push @ret, ",$tot";
                my $runtot = 0;
                foreach ( @races )
                {
                        my $val = $_;
                        $val =~ s/^\(//;
                        $val =~ s/\)//;
			if ( $val =~ /DN/ || $val =~ /OCS/ ) {
				$runtot += scalar( @line ) + 1;
			} else {
                        	$runtot += $val;
			}
                        if ( $numraces > 3 && $runtot != 0 )
                        {
                                push @ret, ",$_";
                        }
                        else
                        {
                                push @ret, ",$_";
                        }
                }
			push @ret, "\n";
        }

	return @ret;
}

1;
