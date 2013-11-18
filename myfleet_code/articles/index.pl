#!/usr/local/bin/perl

use strict;
use diagnostics;

use lib '/usr/local/apache2/mylib/myfleet.org/';
use Myfleet::Article;

print Myfleet::Article::display_article( new CGI(), 'Articles' );

