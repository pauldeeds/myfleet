#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);

print display_page( new CGI() );

sub display_page
{
	# redirect for old links
	my $q = shift;
	return $q->redirect('/articles/' . $q->param('u') );
}
