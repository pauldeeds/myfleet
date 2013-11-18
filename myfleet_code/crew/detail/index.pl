#!/usr/local/bin/perl

use strict;
use diagnostics;
use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myfleet::Crew;

print Myfleet::Crew::display_detail( new CGI() );
