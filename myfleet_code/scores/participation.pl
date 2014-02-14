#!/usr/local/bin/perl

#use strict;
use diagnostics;

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
		Myfleet::Header::display_header('Regattas','../..',"Participation");

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select year(startdate), result from regatta");
	$sth->execute();

	my %years;
	my %boats;

	while ( my ( $year, $result ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );
		my @line = split /\n/, $result;
		my @temp = split /\s*,\s*/, $line[0];
		my $noname = 0;
		if ( $temp[2] =~ /\d+/ ) {
			$noname = 1;
		}
		foreach ( @line )
		{
			if ( $noname ) {
				( $pos, $boat, $tot, @races ) = split /\s*,\s*/;
			} else {
				( $pos, $boat, $nm, $tot, @races ) = split /\s*,\s*/;
			}
			$boat = lc($boat);
			if( $boat eq 'freaks ona leash' ) { $boat = 'freaks on a leash'; }
			if( $boat eq 'express way' ) { $boat = 'expressway'; }
			if( $boat eq 'abigial morgan' || $boat eq 'abagail morgan' ) { $boat = 'abigail morgan'; }
			if( $boat eq 'diane' ) { $boat = 'dianne'; }
			if( $boat eq 'jalepeno' ) { $boat = 'jalapeno'; }
			if( $boat eq 'wile e. coyote' || $boat eq 'wile e.coyote' ) { $boat = 'wile e coyote'; }
			if( $boat eq 'taz' || $boat eq 'taz!!' ) { $boat = 'taz!'; }
			if( $boat eq 'baffet' ) { $boat = 'baffett'; }
			if( $boat eq 'stega' ) { $boat = 'strega'; }

			$boats{$boat}{$year} += scalar(@races);
			$years{$year} += scalar(@races);
			$nm = ''; # squelch warning
		}
	}

	push @ret, '<table border="1" cellpadding="2" cellspacing="0">';

	push @ret, "<tr><th>Boat</th>";
	foreach my $year ( sort(keys(%years)) )
	{
		next if ( $year < 2002 );
		push @ret, "<th>$year</th>";
	}
	push @ret, "<th>Total</th></tr>";

	foreach my $boat ( sort(keys(%boats)) )
	{
		my $tot = 0;
		my @tmp = ();
		foreach my $year ( sort(keys(%years)) )
		{
			next if ( $year < 2002 );
			push @tmp, '<td align="right">', $boats{$boat}{$year} ? $boats{$boat}{$year} : 0, "</td>";
			$tot += $boats{$boat}{$year};
		}

		if( $tot > 0 ) {
			push @ret, "<tr><td>$boat</td>", @tmp, "<td>$tot</td></tr>";
		}
	}
	push @ret, "</table>";

	return @ret;
}

