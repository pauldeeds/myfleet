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
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id from regatta limit 1");
	$sth->execute() || die $DBI::errstr;

	return
		$q->header,
		"Status: up";
}
