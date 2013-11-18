#!/usr/local/bin/perl

use strict;
use diagnostics;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use CGI;
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;
use Myfleet::Regatta;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_header('Dues','../..',"Class Dues");

	my $dues1 = $config{'dues1'};
	my $dues2 = $config{'dues2'};
	my $dues3 = $config{'dues3'};
	my $dues4 = $config{'dues4'};

	my $year = int($q->param('year')) || $config{'defaultYear'};
	my $dbh = Myfleet::DB::connect();



	# add static html
	my ( $html, $title ) = Myfleet::Util::html( 'dues' );
	push @ret, $html;

	# other years available
	my $sth = $dbh->prepare("SELECT year, count(*) FROM dues_paid WHERE name <> '' AND ( dues1 OR dues2 OR dues3 OR dues4 ) GROUP BY year") || die $DBI::errstr;
	$sth->execute();
	if( $sth->rows )
	{
		push @ret, 'Years: ';
		while( my ( $oyear, $paid ) = $sth->fetchrow_array )
		{
			if( $year eq $oyear ) {
				push @ret, "<b>$year ($paid paid)</b> ";
			} else {
				push @ret, "<a href=\"?year=$oyear\">$oyear ($paid paid)</a> ";
			}		
		}
		push @ret, '<br/>';
	}

	# current year
	my $dues1_total = 0;
	my $dues2_total = 0;
	my $dues3_total = 0;
	my $dues4_total = 0;

	my $sth = $dbh->prepare("SELECT hullnumber, name, dues1, dues2, dues3, dues4, note FROM dues_paid WHERE year = ? AND ( name <> '' OR dues1 = 1 OR dues2 = 1 OR dues3 = 1 OR dues4 = 1 ) ORDER BY hullnumber") || die $DBI::errstr;
	$sth->execute( $year );
	if( $sth->rows ) 
	{
		push @ret, "<h1>$year dues paid</h1>";
		push @ret,
			'<table cellpadding="4" cellspacing="0" border="1">',
				'<tr>',
					'<td>Number</td>',
					'<td>Member</td>',
					( $dues1 ? "<td>$dues1</td>" : '' ),
					( $dues2 ? "<td>$dues2</td>" : '' ),
					( $dues3 ? "<td>$dues3</td>" : '' ),
					( $dues4 ? "<td>$dues4</td>" : '' ),
				'</tr>';

		while( my ( $hullnumber, $name, $dues1_val, $dues2_val, $dues3_val, $dues4_val, $note ) = $sth->fetchrow_array )
		{
			$name ||= '&nbsp;';
			push @ret, "<tr>",
				"<td>$hullnumber</td>",
				"<td>$name</td>",
				( $dues1 ? "<td>" . ( $dues1_val ? 'yes' : 'no' ) . "</td>"  : '' ),
				( $dues2 ? "<td>" . ( $dues2_val ? 'yes' : 'no' ) . "</td>"  : '' ),
				( $dues3 ? "<td>" . ( $dues3_val ? 'yes' : 'no' ) . "</td>"  : '' ),
				( $dues4 ? "<td>" . ( $dues4_val ? 'yes' : 'no' ) . "</td>"  : '' ),
				"</tr>";

				if( $dues1 && $dues1_val ) { $dues1_total++; }
				if( $dues2 && $dues2_val ) { $dues2_total++; }
				if( $dues3 && $dues3_val ) { $dues3_total++; }
				if( $dues4 && $dues4_val ) { $dues4_total++; }
		}

		# totals
		push @ret, "<tr>",
						"<td colspan=\"2\"><b>Total Paid</b></td>",
						( $dues1 ? "<td><b>$dues1_total</b></td>": '' ),
						( $dues2 ? "<td><b>$dues2_total</b></td>" : '' ),
						( $dues3 ? "<td><b>$dues3_total</b></td>" : '' ),
						( $dues4 ? "<td><b>$dues4_total</b></td>" : '' ),
					"</tr>";

		push @ret, "</table>";
	}
	else
	{
		push @ret, "<h2>$year - nobody has paid yet!</h2>";
	}


	return @ret;
}
