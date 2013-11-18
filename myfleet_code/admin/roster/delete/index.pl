#!/usr/local/bin/perl

use strict;
use diagnostics;
use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Roster;

my $q = new CGI();
$q->param('admin',1);
print Myfleet::Roster::display_delete( $q );
