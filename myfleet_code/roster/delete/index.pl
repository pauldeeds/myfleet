#!/usr/local/bin/perl

use strict;
use diagnostics;
use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Roster;

print Myfleet::Roster::display_delete( new CGI() );
