#!/usr/local/bin/perl

#use strict;
use diagnostics;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::Regatta;
use Myfleet::DB;
use Myfleet::Util;
use Myfleet::Scores;
use URI::URL;

print display_page( new CGI() );

sub display_page
{
	my $q = shift;

	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_header('Regattas','../..',"Scores");

	my $dbh = Myfleet::DB::connect();

	my $year = $q->param('year') || $config{'defaultYear'};

	if( ! $q->param('series') )
	{
		push @ret,
			"<h2>Choose a series</h2>",
			"<ol>";
		foreach my $series ( @{$config{'series'}} )
		{
			my $url = URI::URL->new("/scores/$series->{dbname}");
			push @ret, "<li><a href=\"$url\">$series->{name} Series</a></li>";
		}
		push @ret, "</ol>";

		return @ret;
	}

	foreach my $series ( @{$config{'series'}} )
	{
		if( $series->{dbname} eq $q->param('series') )
		{
			my $scoringFunction = "Myfleet::Scores::display_$series->{scoring}";
			push @ret,
				'<table class="scores">',
					'<tr>',
						'<td>',
							"<big><b>$year $series->{name} Series Standings</b></big>",
							'<br/>',
							( $series->{'throwouts'} ? 
								"<small>(throwouts in parantheses - $series->{throwouts} allowed)</small>" : '' ),
						'</td>',
					'</tr>',
					'<tr>',
						'<td>',
							&$scoringFunction( $year, $boatname, 'All', $series->{'dbname'}, $series->{'throwouts'} ),
						'</td>',
					'</tr>',
				'</table>';
		}
	}

	return @ret;
}

