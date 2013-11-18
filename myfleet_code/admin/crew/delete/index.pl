#!/usr/local/bin/perl

use strict;
use diagnostics;
use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Crew;

my $q = new CGI();
$q->param('admin',1);
print Myfleet::Crew::display_delete( $q );
