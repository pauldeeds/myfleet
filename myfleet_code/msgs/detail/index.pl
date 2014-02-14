#!/usr/local/bin/perl -w

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::MessageBoard;

print Myfleet::MessageBoard::display_detail( new CGI() );
