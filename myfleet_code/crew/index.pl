#!/usr/local/bin/perl

use diagnostics;
use strict;

use Myfleet::Crew;

print Myfleet::Crew::display_roster( new CGI() );
