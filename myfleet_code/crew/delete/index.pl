#!/usr/local/bin/perl

use strict;
use diagnostics;

use Myfleet::Crew;

print Myfleet::Crew::display_delete( new CGI() );
