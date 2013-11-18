#!/usr/local/bin/perl

use diagnostics;
use strict;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use Myphoto::Photo;
use Myfleet::Header;

print Myphoto::Photo::display_admin( new CGI() );
