#!/usr/local/bin/perl -w

use strict;
use diagnostics;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::MessageBoard;

print Myfleet::MessageBoard::display_detail( new CGI() );
