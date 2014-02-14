#!/usr/local/bin/perl

#use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use MyphotoConfig qw(%photoconfig);
use Myfleet::Header;
use Myfleet::Regatta;
use Myfleet::DB;
use Myfleet::Util;
use Myfleet::Scores;
use Myfleet::Roster;
use URI::URL;

print display_page( new CGI() );

sub display_page
{
	my $q = shift;

	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_header('Home','.',"$config{'defaultTitle'} Home");
	my $dbh = Myfleet::DB::connect();

	# next event
	my $next;
	my $sth = $dbh->prepare("select regatta.id, startdate orderdate, date_format(regatta.startdate,'%M %e') startdate, date_format(regatta.enddate,'%M %e') enddate, regatta.name, venue.id venueid, venue.name venuename, regatta.series1, regatta.series2, regatta.series3, regatta.series4, regatta.series5, regatta.url, ! isnull(regatta.result) hasresult, result,  ! isnull(regatta.description) hasdescription, ! isnull(regatta.story) hasstory from regatta, venue where regatta.venue = venue.id and startdate >= now() order by orderdate ASC limit 1") || die $DBI::errstr;
	$sth->execute() || die $DBI::errstr;
	if( $sth->rows > 0 )
	{
		$next = $sth->fetchrow_hashref;
		$sth = $dbh->prepare("select count(distinct sailnumber) from boats where regattaid = ? and status = 'Sailing'") || die $DBI::errstr;
		$sth->execute( $next->{id} ) || die $DBI::errstr;
		$next->{boats} = $sth->fetchrow_array;
		$sth = $dbh->prepare("select count(distinct sailnumber) from boats where regattaid = ? and status = 'Looking'") || die $DBI::errstr;
		$sth->execute( $next->{id} );
		$next->{looking}  = $sth->fetchrow_array;
	}

	# previous event
	my $last;
	$sth = $dbh->prepare("select regatta.id, startdate orderdate, date_format(regatta.startdate,'%M %e') startdate, date_format(regatta.enddate,'%M %e') enddate, regatta.name, venue.id venueid, venue.name venuename, regatta.series1, regatta.series2, regatta.series3, regatta.series4, regatta.series5, regatta.url, ! isnull(regatta.result) hasresult, result,  ! isnull(regatta.description) hasdescription, ! isnull(regatta.story) hasstory from regatta, venue where regatta.venue = venue.id and startdate <= now() order by orderdate DESC limit 1") || die $DBI::errstr;
	$sth->execute() || die $DBI::errstr;
	if( $sth->rows > 0 )
	{
		$last = $sth->fetchrow_hashref;
		if ( $last->{hasresult} )
		{
			my ( @allboats ) = split /\n/, $last->{result};
			$last->{boats} = scalar( @allboats );
			my ( @boat ) = split /,/, $allboats[0];
			my $noname = 0;
			if ( $boat[2] =~ /\d+/ || $boat[2] =~ /DNS|DNF|DSQ/ ) { $noname = 1; }
			my $races = ( scalar @boat ) - ( 4 - $noname );
			if ( $races == 0 ) { $races = 1; }
			$last->{races} = $races;
		}
	}

	my @seriesHtml;
	# next series events
	foreach my $series ( @{$config{'series'}} )
	{
		# season series schedule
		if( $series->{'showNextOnHomePage'} )
		{
			$sth = $dbh->prepare("select regatta.id, startdate orderdate, date_format(regatta.startdate,'%M %e') startdate, date_format(regatta.enddate,'%M %e') enddate, regatta.name, venue.id venueid, venue.name venuename, regatta.series1, regatta.series2, regatta.series3, regatta.series4, regatta.series5, regatta.url, ! isnull(regatta.result) hasresult, result,  ! isnull(regatta.description) hasdescription, ! isnull(regatta.story) hasstory from regatta, venue where regatta.venue = venue.id and startdate >= now() and $series->{'dbname'} <> 0 order by orderdate ASC limit 1") || die $DBI::errstr;
			$sth->execute() || die $DBI::errstr;
			if( $sth->rows > 0 )
			{
				$nextseries = $sth->fetchrow_hashref;
				$sth = $dbh->prepare("select count(distinct sailnumber) from boats where regattaid = ? and status = 'Sailing'") || die $DBI::errstr;
				$sth->execute( $nextseries->{id} ) || die $DBI::errstr;
				$nextseries->{boats} = $sth->fetchrow_array;
				$sth = $dbh->prepare("select count(distinct sailnumber) from boats where regattaid = ? and status = 'Looking'") || die $DBI::errstr;
				$sth->execute( $nextseries->{id} );
				$nextseries->{looking}  = $sth->fetchrow_array;
				if( $nextseries->{id} != $next->{id} )
				{
					push @seriesHtml,
						"<b>Next $series->{name} Series Event:</b> ",
						"<a href=\"schedule/$nextseries->{id}\">$nextseries->{name} @ $nextseries->{venuename}</a>",
						' (', Myfleet::Util::display_date( $nextseries->{startdate}, $nextseries->{enddate} ), ")<br/>";
				}
			}
		}
	}

	# next / previous event
	push @ret,
		'<table width="100%">',
			'<tr>',
				'<td valign="top">',
					'<h3>Next Event</h3>',
					( $next ? 
						"<a href=\"schedule/$next->{id}\">$next->{name}</a><br/>" .
						"$next->{venuename}<br/>" .
						Myfleet::Util::display_date( $next->{startdate}, $next->{enddate} ) . "<br/>" .
						"($next->{boats} boats, $next->{looking} looking)" : 'nothing scheduled' ),
				'</td>',
				'<td align="right" valign="top">',
					'<h3>Last Event</h3>',
					( $last ?
						"<a href=\"schedule/$last->{id}\">$last->{name}</a><br/>" .
						"$last->{venuename}<br/>" .
						Myfleet::Util::display_date( $last->{startdate}, $last->{enddate} ) . "<br/>" .
						( $last->{hasresult} ? 
							"($last->{boats} boats, $last->{races} race" . ($last->{races} > 1 ? "s" : "" ) . ")" :
							"(results not in yet)" ) : 'nothing scheduled' ),
				'</td>',
			'</tr>',
		"</table>",
			( @seriesHtml ? '<br/><small>' . join('', @seriesHtml) . '</small>' : '' ),
		'<br/>';

	# photo
	my @photo_html;
	$sth = $dbh->prepare("select photo.id, photo.gallery_id, gallery.name galleryname, width, height, caption, rand() rand from photo, gallery where photo.gallery_id = gallery.id and length(caption) > 4 and width > 300 and photo.hide != 1 and gallery.hide != 1 order by rand DESC limit 1");
	$sth->execute() || die $DBI::errstr;
	if( $sth->rows )
	{
		my $photo;
		$photo = $sth->fetchrow_hashref;
		$photo->{height400} = int( (400 * $photo->{height}) / $photo->{width} ); 
		push @photo_html,
			"<h3>File Photo: $photo->{galleryname}</h3>",
			"$photo->{caption}<br/>",
				"<a href=\"$photoconfig{'photoDirectory'}wide/?gallery=$photo->{gallery_id}#$photo->{id}\"><img border=\"0\" src=\"$photoconfig{'photoDirectory'}/$photo->{id}_400.jpg\" width=\"400\" height=\"$photo->{height400}\" alt=\"$photo->{caption}\"></a><br/>\n";
	}

	# display new messages since last visit
	my @message_html;
	if ( $q->cookie('lastdate') )
	{
		my @message;
		my $stf = $dbh->prepare("select thread.forum_id, count(*) from msg, thread where msg.thread_id = thread.thread_id and msg.deleted = 0 and unix_timestamp(msg.insert_date) > ? group by forum_id" ) || die $DBI::errstr;
		$stf->execute( $q->cookie('lastdate') ) || die $DBI::errstr;

		while( my ( $forum_id, $count ) = $stf->fetchrow_array )
		{
			my $name;
			if ( $forum_id > 1000 ) {
				my $str = $dbh->prepare("select regatta.id id, regatta.name name, venue.name venuename from regatta, venue where regatta.venue = venue.id and regatta.id = ?");
				my $id = $forum_id - 1000;
				$str->execute( $id );
				if ( $str->rows ) {
					my ( $reg ) = $str->fetchrow_hashref;
					$name = "<a href=\"schedule/$reg->{id}#Messages\" style=\"font-size:small;\">$reg->{name} \@ $reg->{venuename}</a>";
				}
			} else {
				my $str = $dbh->prepare("select name from forum where forum_id = ?") || die $DBI::errstr;
				$str->execute( $forum_id ) || die $DBI::errstr;
				my ( $for ) = $str->fetchrow_hashref;
				$name = "<a href=\"msgs/?f=$forum_id\" style=\"font-size:small\">$for->{name}</a>";
			}
			push @message, "$name <small style=\"color:#f00;\">($count new message" . ( $count > 1 ? "s" : "" ) . ")</small>";
		}

		if ( scalar @message )
		{
			push @message_html,
				"<h3>New Messages Since Your Last Visit</h3>",
				"<ul>",
			 		"<li>" . join("</li><li>", @message ) . "</li>",
				"</ul>";
		}
	}

	my ( $homepage_top ) = Myfleet::Util::html('homepage_top');
	my ( $homepage_bottom ) = Myfleet::Util::html('homepage_bottom');
	my ( $homepage_aftermsg ) = Myfleet::Util::html('homepage_aftermsg');

	my @left;
	push @left,
		$homepage_top,
		@message_html,
		$homepage_aftermsg,
		@photo_html,
		$homepage_bottom;

	my $boatname = '';
	if ( $q->cookie('boatname') ) {
		$boatname = $q->cookie('boatname');
	}


	my @right;
	push @right,
		'<table cellpadding="0" cellspacing="0" border="0" width="100%">',

			# contacts
			'<tr>',
				'<td colspan="2" class="ttitle">',
					'Class Contacts',
				'</td>',
			'</tr>',
			'<tr>',
				'<td colspan="2">',
					'<hr class="homehr">',
				'</td>',
			'</tr>',
			'<tr>',
				'<td colspan="2">',
					Myfleet::Roster::display_contacts( $config{'maximumSpecialOrder'} ),
				'</td>',
			'</tr>',
			'<tr>',
				'<td colspan="2">',
					'&nbsp;',
				'</td>',
			'</tr>';

	foreach my $series ( @{$config{'series'}} )
	{
		# season series schedule
		if( $series->{'showScheduleOnHomePage'} )
		{
			push @right,
				'<tr>',
					'<td class="ttitle">',
						"$config{'defaultYear'} $series->{name} Series",
							( $series->{'prelim'} ? ' <em><small>(preliminary)</small></em>' : '' ),
					'</td>',
					'<td align="right">',
						( $series->{'showResultsOnHomePage'} ? "<a href=\"#$series->{dbname}\">scores</a>" : "<a href=\"/scores/$series->{dbname}\">standings</a>" ),
						
					'</td>',
				'</tr>',
				'<tr>',
					'<td colspan="2">',
						'<hr class="homehr">',
						Myfleet::Scores::display_schedule( $config{'defaultYear'}, $series->{'dbname'} ),
					'</td>',
				'</tr>',
				'<tr>',
					'<td colspan="2">',
						'&nbsp;',
					'</td>',
				"</tr>\n";
		}
	}

	foreach my $series ( @{$config{'series'}} )
	{
		if( $series->{'showResultsOnHomePage'} )
		{
			my $scoringFunction = "Myfleet::Scores::display_$series->{scoring}";

			my $lastYear = $config{'defaultYear'} - 1;
			my $url = URI::URL->new("/scores/$series->{name}");

			# season scores
			push @right,
				'<tr>',
					'<td>',
						"<a name=\"$series->{dbname}\"></a>",
						"<big><b>$config{'defaultYear'} $series->{'name'} Series Standings</b></big>",
					'</td>',
					'<td align="right">',
						"<a href=\"/scores/$series->{dbname}\">detail</a>",
					'</td>',
				'</tr>',
				'<tr>',
					'<td colspan="2">',
						&$scoringFunction( $config{'defaultYear'}, $boatname, 'Narrow', $series->{'dbname'}, $series->{'throwouts'} ),
					'</td>',
				'</tr>',
				'<tr>',
					'<td colspan="2">',
						'&nbsp;',
					'</td>',
				'</tr>';
		}
	}

	push @right,
		'</table>';


		# "<div align=\"center\"><a href=\"/articles/seasonscoring\">Scoring Rules</a></div>";

	# body divs
	push @ret,
	"<div id=\"main\">\n",
		"<div id=\"left\">\n",
			@left,
		"</div>\n",
		"<div id=\"right\">",
			@right,
		"</div>\n",
	"</div>\n",
	'<div style="clear:both; float:right; font-size:0.8em; border:1px solid #ccc; padding:5px; margin-bottom:1em;"><a href="http://myfleet.org">site hosted by myfleet.org</a></div>',
		Myfleet::Header::display_footer();

	return @ret;
}

