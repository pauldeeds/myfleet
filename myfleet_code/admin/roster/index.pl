#!/usr/local/bin/perl

use diagnostics;
use strict;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Roster;

print Myfleet::Roster::admin_roster( new CGI() );
