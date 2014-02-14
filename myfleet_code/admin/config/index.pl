#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Data::Dumper;
use HTML::Entities;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} Administration");

	$Data::Dumper::Indent = 2;
	$Data::Dumper::Terse = 1;
	push @ret, "<pre>";
	foreach my $key ( sort keys %config )
	{
		push @ret, "<b>$key</b> => " . encode_entities( Dumper($config{$key}) ) . '<br/>';
		
	}
	push @ret, "</pre>";

	push @ret,
		Myfleet::Header::display_footer();

	return @ret;
}
