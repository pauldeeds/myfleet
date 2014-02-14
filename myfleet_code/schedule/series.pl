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

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;

	print Dumper( $q );

	if ( $q->param('f') ) {
		$q->param('r', $q->param('f') - 1000 );
	}

	if ( $q->param('r') )
	{
		if ( $q->param('Looking') || $q->param('Sailing') ) {
			my $status = ( $q->param('Looking') ? 'Looking' : 'Sailing' );
			if ( $q->param('sailnumber') || $q->param('boatname') || $q->param('skipper') ) {
				my $dbh = Myfleet::DB::connect();
				my $stx = $dbh->prepare("delete from boats where regattaid = ? and sailnumber = ?");
				$stx->execute( $q->param('r'), $q->param('sailnumber') );
				my $sth = $dbh->prepare("insert into boats ( regattaid, sailnumber, skipper, crew, note, status ) values (?,?,?,?,?,?)");
				$sth->execute( $q->param('r'), $q->param('sailnumber'), $q->param('skipper'), $q->param('boatname'), $q->param('note'), $status );
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
		push @ret,
			$q->header,
			Myfleet::Header::display_header( $config{'EventsMenu'}, '..' );

		my $dbh = Myfleet::DB::connect();
		my $sth = $dbh->prepare("select distinct year(startdate) year from regatta order by year desc");
		$sth->execute();
		my @years;
		while( my ( $y ) = $sth->fetchrow_array ) {
			push @years, $y;
		}
		my $year = $q->param('y') || $years[0];

		push @ret,
			'<br/>',
			'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
				'<tr bgcolor="silver">',
					'<td>', "<big><b>$year Events</b></big>", '</td>';

		if ( scalar( @years ) > 1 ) {
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
		my @seriesLegend;
		foreach my $series ( @{$config{'series'} } )
		{
			push @seriesLegend,
				"<b>$series->{'style'}</b> - " . lc($series->{'name'}) . " series ";
		}
		push @ret, '<small>', join(', ', @seriesLegend ), '</small>';

		push @ret,
			Myfleet::Regatta::display_events( $year );
	}

	push @ret, Myfleet::Header::display_footer();

	return @ret;
}
