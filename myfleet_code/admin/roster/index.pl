#!/usr/local/bin/perl

use diagnostics;
use strict;

use Myfleet::Roster;

print Myfleet::Roster::admin_roster( new CGI() );
