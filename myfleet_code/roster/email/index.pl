#!/usr/local/bin/perl

use strict;
use diagnostics;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::DB;

print display_page( new CGI() );

sub display_page
{
	my $q = shift;

	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_header("Roster","../.."),
		$q->start_html( -title=>"$config{'defaultTitle'}: E-Mail List" ),
		"<h3>$config{'defaultTitle'} -- Email List</h3>";

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select distinct email, firstname, lastname, boatname, hullnumber from person where email != '' order by lastname, firstname") || die $DBI::errstr;
	$sth->execute();

	push @ret, "<pre>\n";

	while ( my ( $address, $fname, $lname, $boat, $hull ) = $sth->fetchrow_array )
	{
		push @ret, "$fname $lname";
		if ( $boat ) {
			push @ret, " ($boat";
			if ( $hull ) {
				push @ret, " \#$hull)";
			} else {
				push @ret, ")";
			}
		}
		push @ret, " &lt;$address&gt;\n";
	}
	push @ret, "</pre>";
	return @ret;
}
