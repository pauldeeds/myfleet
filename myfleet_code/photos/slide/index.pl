#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp 'fatalsToBrowser';
use Myphoto::Photo;
use MyphotoConfig qw(%photoconfig);
use Myfleet::Header;

print Myphoto::Photo::display_slide( new CGI() );
