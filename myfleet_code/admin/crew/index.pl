#!/usr/local/bin/perl

use diagnostics;
use strict;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Crew;

print Myfleet::Crew::admin_roster( new CGI() );
