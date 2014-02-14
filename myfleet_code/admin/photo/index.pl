#!/usr/local/bin/perl

use diagnostics;
use strict;

use Myphoto::Photo;
use Myfleet::Header;

print Myphoto::Photo::display_admin( new CGI() );
