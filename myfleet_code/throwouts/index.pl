#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::Header;
use Myfleet::Util;

print display_page( new CGI() );

sub display_page
{	
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_header('Regattas'),
		"<h3>Throwout Calculator</h3>",
		'<p>Qualification and the number of throwouts each boat gets in a season series is determined by two factors</p>',
	   	'<ul><li>the total number of races in the series<li>the number of races the boat participates in<br>(races not started do not count against you, but races not finished do)</ul>',
		"<form method=get>",
		"Total Races: ", $q->textfield(-name=>'races', -default=>'45'), " ",
		"<input type=submit value=Submit>",
		"</form>";

	my $total = $q->param('races') || 45;
	if ( $total <= 0 || $total > 500 )
	{
		push @ret, "Please choose a value between 1 and 500.";
	}
	else
	{
		my $p50 = 0.5 * $total;
		my $qualifytotal = ( $p50 == int($p50) ? $p50 : int($p50) + 1 );

		push @ret, "$qualifytotal of $total races required to qualify.";

		push @ret, "<table border=1 cellpadding=2 cellspacing=0><tr><td>Races Sailed<td>Throwouts";
		foreach my $races ( $qualifytotal .. $total )
		{
			my $throws = throwouts( $total, $races );
			push @ret, "<tr><td>$races<td>$throws";
		}
		push @ret, "</table>";
	}

	return @ret;
}


sub throwouts
{
	my ( $realracetotal , $races ) = @_;

	# copied from Scores.pm
	# 1 throwout for every 2.5 races from 50-55% of total
	# 1 throwout for every 2 races from 55-60% of total
	# 1 throwout for every 1.5 races from 60-65% of total
	# 1 throwout for every 1 race over 65% of total
	
	my $throws = 0;

	my $p50 = 0.5 * $realracetotal;
	my $p55 = 0.55 * $realracetotal;
	my $p60 = 0.6 * $realracetotal;
	my $p65 = 0.65 * $realracetotal;

	if ( $races <= $p50 )
	{
		$throws = 0;
	}
	if ( $races > $p50 && $races <= $p55 )
	{
		$throws = ( $races - $p50 ) / 2.5;
	}
	elsif ( $races > $p55 && $races <= $p60 )
	{
		$throws = (( $p55 - $p50 ) / 2.5) + (( $races - $p55 ) / 2);
	}
	elsif ( $races > $p60 && $races <= $p65 )
	{
		$throws = (( $p55 - $p50 )/2.5) + (( $p60 - $p55 )/2) + (( $races - $p60)/1.5);
	}
	elsif ( $races > $p65 )
	{
		$throws = (( $p55 - $p50 )/2.5) + (( $p60 - $p55 )/2) + (( $p65 - $p60)/1.5) + ( $races - $p65);
	}
	return int( $throws + 0.5 );
	# return $throws;
}
