#!/usr/local/bin/perl

#use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::Regatta;
use Myfleet::DB;
use Myfleet::Util;
use Myfleet::GPS;

print display_page( new CGI() );

sub display_page
{
	my $q = shift;

	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_header('GPS','../',"GPS Tracks"),
		Myfleet::GPS::display_page($q),
		Myfleet::Header::display_footer();

	return @ret;
}

