#!/usr/local/bin/perl

use diagnostics;
use strict;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Roster;

print Myfleet::Roster::display_roster( new CGI() );
