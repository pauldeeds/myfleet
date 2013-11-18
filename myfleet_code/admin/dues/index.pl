#!/usr/local/bin/perl

use strict;
use diagnostics;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use CGI;
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('Class Dues Edit');

	my $year = $q->param('year') || $config{'defaultYear'};
	my $dbh = Myfleet::DB::connect();

	# grab config
	my $dues1 = $config{'dues1'};
	my $dues2 = $config{'dues2'};
	my $dues3 = $config{'dues3'};
	my $dues4 = $config{'dues4'};

	# perist update
	if( $q->param('hullnumber') )
	{
		my $sti = $dbh->prepare("REPLACE INTO dues_paid ( year, hullnumber, name, dues1, dues2, dues3, dues4 ) VALUES ( ?,?,?,?,?,?,? )") || die $DBI::errstr;
		$sti->execute( $year, $q->param('hullnumber'), $q->param('name'), $q->param($dues1) eq 'on' ? 1 : 0, $q->param($dues2) eq 'on' ? 1 : 0, $q->param($dues3) eq 'on' ? 1: 0, $q->param($dues4) eq 'on' ? 1 : 0 ) || die $DBI::errstr;
	}

	# other years available
	my $sth = $dbh->prepare("SELECT year, count(*) FROM dues_paid WHERE name <> '' OR dues1 OR dues2 OR dues3 OR dues4 GROUP BY year") || die $DBI::errstr;
	$sth->execute();
	if( $sth->rows )
	{
		push @ret, 'Years: ';
		while( my ( $oyear, $num ) = $sth->fetchrow_array )
		{
			if( $year eq $oyear ) {
				push @ret, "<b>$year ($num paid)</b> ";
			} else {
				push @ret, "<a href=\"?year=$oyear\">$oyear ($num paid)</a> ";
			}
		}
	}
	push @ret, '&nbsp;&nbsp;<a href="/admin/html/?u=dues">edit dues html</a><br/>';

	
	push @ret, 
		'<p>Dues are keyed to hull number and year.  Any data you enter here will replace previous values for the same hullnumber and year.  Enter a hull number and year with the rest of the fields blank to delete a record.</p>',
		'<form method=post>',
			'Hull Number ', $q->textfield(-name=>'hullnumber', -size=>4, -maxlength=>4 ),
			' Name ', $q->textfield(-name=>'name', -size=>50, -maxlength=>200 ), ' ',
			' Year ', $q->textfield(-name=>'year', -size=>4, -maxlength=>4 ), ' ',
			( $dues1 ? $q->checkbox(-name=>$dues1) : '' ), ' ',
			( $dues2 ? $q->checkbox(-name=>$dues2) : '' ), ' ',
			( $dues3 ? $q->checkbox(-name=>$dues3) : '' ), ' ',
			( $dues4 ? $q->checkbox(-name=>$dues4) : '' ), ' ',
			' <input type=submit value="Add or Update Record">',
		'</form>';




	my $sth = $dbh->prepare("SELECT hullnumber, name, dues1, dues2, dues3, dues4, note FROM dues_paid WHERE year = ? AND ( name <> '' OR dues1 = 1 OR dues2 = 1 OR dues3 = 1 OR dues4 = 1 ) ORDER BY hullnumber") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	push @ret, "<h1>$year dues paid</h1>";
	push @ret,
		'<table cellpadding="4" cellspacing="0" border="1">',
			'<tr>',
				'<td>Hull Number</td>',
				'<td>Name</td>',
				( $dues1 ? "<td>$dues1</td>" : '' ),
				( $dues2 ? "<td>$dues2</td>" : '' ),
				( $dues3 ? "<td>$dues3</td>" : '' ),
				( $dues4 ? "<td>$dues4</td>" : '' ),
			'</tr>';

	while( my ( $hullnumber, $name, $dues1_val, $dues2_val, $dues3_val, $dues4_val, $note ) = $sth->fetchrow_array )
	{
		$name ||= '&nbsp;';
		push @ret,
			"<tr>",
				"<td>$hullnumber</td>",
				"<td>$name</td>",
				( $dues1 ? "<td>" .( $dues1_val ? 'yes' : 'no' ) . "</td>" : '' ),
				( $dues2 ? "<td>" .( $dues2_val ? 'yes' : 'no' ) . "</td>" : '' ),
				( $dues3 ? "<td>" .( $dues3_val ? 'yes' : 'no' ) . "</td>" : '' ),
				( $dues4 ? "<td>" .( $dues4_val ? 'yes' : 'no' ) . "</td>" : '' ),
			"</tr>";
	}
	push @ret, "</table>";

	return @ret;
}
