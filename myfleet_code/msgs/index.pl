#!/usr/local/bin/perl -w

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBD::mysql;
use Apache::Session::Generate::MD5;
use Text::Wrap;
use Myfleet::MessageBoard;

print Myfleet::MessageBoard::display_page( new CGI() );
