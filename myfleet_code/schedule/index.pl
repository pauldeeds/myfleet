#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);

use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;
use Myfleet::Regatta;
use Myfleet::MessageBoard;
use Data::Dumper;

use Data::ICal;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;


	if ( $q->param('f') && ! $q->param('r') ) {
		$q->param('r', $q->param('f') - 1000 );
	}

	if ( $q->param('r') )
	{
		if( $q->param('csv') )
		{
			my $id = $q->param('r');
			return
				$q->header(-type=>'excel/ms-excel',-attachment => "$id.csv"),
				Myfleet::Regatta::display_regatta_csv( $q );
					
		}

		# The choices are looking, sailing, and "not racing".  In
		# all cases, delete any existing entry for this boat in
		# this event.
		my $dbh = Myfleet::DB::connect();
		my $sailnumber = $q->param('sailnumber');
		my $skipper = $q->param('skipper');
		my $boatname = $q->param('boatname');
		my $note = $q->param('note');

		if ( $q->param('sailnumber') || $q->param('boatname') || $q->param('skipper') )
		{
			my $stx = $dbh->prepare("delete from boats where regattaid = ? and ( sailnumber = ? OR skipper = ? )");
			$stx->execute( $q->param('r'), $q->param('sailnumber'), $q->param('skipper') );
		
			# remove html
			$sailnumber =~ s/</&lt;/g; $sailnumber =~ s/>/&rt;/g;
			$skipper =~ s/</&lt;/g; $skipper =~ s/>/&rt;/g;
			$boatname =~ s/</&lt;/g; $boatname =~ s/>/&rt;/g;
			$note =~ s/</&lt;/g; $note =~ s/>/&rt;/g;
		}

		if ( $q->param('Looking') || $q->param('Sailing') )
		{
			my $status = ( $q->param('Looking') ? 'Looking' : 'Sailing' );
			if ( $note !~ /href=/ && $note !~ /http/ )
			{
				my $sth = $dbh->prepare("insert into boats ( regattaid, sailnumber, skipper, crew, note, status ) values (?,?,?,?,?,?)");
				$sth->execute( $q->param('r'), $sailnumber, $skipper, $boatname, $note, $status );
				$q->cookie('sailnumber',$q->param('sailnumber'));
				$q->cookie('boatname',$q->param('boatname'));
				$q->cookie('skipper',$q->param('skipper'));
			}
		}

		# regatta page
		return Myfleet::MessageBoard::display_page( $q );
	}
	else
	{
		# event listing

		my $dbh = Myfleet::DB::connect();
		my $sth = $dbh->prepare("select distinct year(startdate) year from regatta order by year desc");
		$sth->execute();
		my @years;
		while( my ( $y ) = $sth->fetchrow_array ) {
			push @years, $y;
		}

		my $current_year = (localtime)[5] + 1900;
		my $year = $q->param('y') || $years[0] || $current_year; # $current_year; # $years[0];
		my $series = $q->param('series') || '';

		my @seriesLegend;
		my $seriesname = 'Regattas';
		foreach my $s ( @{$config{'series'} } )
		{
			my $styleString = '';
			if( $s->{'style'} =~ /bold$/ || $s->{'style'} =~ /italic$/ || $s->{'style'} =~ /asterisk$/ )
			{
				$styleString = "($s->{'style'})";
			}
			if( $s->{'dbname'} eq $series )
			{
				push @seriesLegend,
					lc($s->{'name'}) . " series $styleString";
					$seriesname = $s->{'name'} . " Series";
			}
			else
			{
				push @seriesLegend,
					"<a href=\"$s->{'dbname'}?y=$year\">" . lc($s->{'name'}) . " series $styleString</a> ";
			}
		}

		my $title = "$year $seriesname - $config{'defaultTitle'}";

		if( $q->param('ical') )
		{
			my $calendar = Myfleet::Regatta::display_events( $year, 'Regular', $series, Data::ICal->new() );

			$calendar->add_properties(
				'CALSCALE' => 'GREGORIAN',
				'SUMMARY' => $title,
				'METHOD' => 'PUBLISH'
			);

			my $filename = $title;
			$filename =~ s/[^a-zA-Z0-9]//g;

			return
				$q->header(-type=>'text/calendar',-attachment => "$filename.ics" ),
				$calendar->as_string;
		}
		else
		{
			push @ret,
				$q->header,
				Myfleet::Header::display_header( $config{'EventsMenu'}, '..', $title ),
				'<br/>',
				'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
					'<tr bgcolor="silver">',
						'<td>', "<big><b>$year Events</b></big>", '</td>';
	
			if ( scalar( @years ) > 1 || ( scalar(@years) == 1 && $years[0] ne $year) ) {
				push @ret, '<td align="right">Years: ';
				foreach my $yr ( @years ) {
					if ( $yr ne $year ) {
						push @ret, "<a href=\"?y=$yr\">$yr</a> ";
					} else {
						push @ret, "<b>$yr</b> ";
					}
				}
				push @ret, '</td>';
			}
			push @ret,
				"</table>";
		
			# display series designators
			if( @seriesLegend )
			{
				if( $series eq '' )
				{
					unshift @seriesLegend, 'all events';
				}
				else
				{
					unshift @seriesLegend, '<a href="/schedule/?y=' . $year . '">all events</a>';
				}
				push @ret, '<div style="float:right; padding:0.3em 0;"><a href="?y=' . $year . '&ical=1"><small>[export]</small></a></div>';
				push @ret, '<div style="padding:0.3em 0;">' . join(' | ', @seriesLegend ) . '</div>';
			}
			push @ret,
				Myfleet::Regatta::display_events( $year, 'Regular', $series, 0 );
		}
	}

	push @ret, Myfleet::Header::display_footer();

	return @ret;
}
