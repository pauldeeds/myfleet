#!/usr/local/bin/perl

use diagnostics;
use strict;

use Myfleet::Roster;

print Myfleet::Roster::display_roster( new CGI() );
