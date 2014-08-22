package Myfleet::Scores;

use Myfleet::DB;
use MyfleetConfig qw(%config);
use Data::Dumper;

sub display_schedule
{
	my ( $year, $type ) = @_;

	$year ||= $config{'defaultYear'};
	$type ||= 'series1';


	my @ret;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id, date_format(startdate,'%b %e'), date_format(enddate,'%b %e'), unix_timestamp(startdate) < unix_timestamp(now()) as 'inpast' from regatta where $type > 0 and year(startdate) = $year order by startdate") || die $DBI::errstr;
	$sth->execute();

	push @ret, "<table width=\"100%\" cellpadding=\"2\" cellspacing=\"0\">\n";

	my $over = 1;
	my $first = 1;
	while ( my ( $result, $rname, $highpoint, $rid, $startdate, $enddate, $inpast ) = $sth->fetchrow_array )
	{
		if ( $inpast ) # $result && length( $result ) > 10 )
		{
			push @ret, "<tr><td><a href=\"./schedule/$rid\"><small>$rname" . ($highpoint > 1 ? " (${highpoint}x)" : '' ) . "</small></a></td>\n";
		}
		else
		{
			if ( $over == 1 ) {
				if ( $first != 1 ) { push @ret, '<tr><td colspan="2"><hr/></td></tr>'; }
				$over = 0;
			}
			push @ret, "<tr><td><a href=\"schedule/$rid\"><small>$rname" . ($highpoint > 1 ? " (${highpoint}x)" : '' )  . "</small></a></td>\n";
		}
		push @ret,
			'<td width="40%" align="right">',
				'<small>',
					Myfleet::Util::display_date( $startdate, $enddate ),
				'</small>',
			'</td>';

		$first = 0;
	}
	push @ret, "</table>\n";

	return @ret;
}

sub display_contacts
{
	my ( $thresh ) = @_;
	$thresh ||= 5;
	
	my @ret;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select firstname, lastname, special, email from person where specialorder <= $thresh order by specialorder") || die $DBI::errstr;
	$sth->execute();
	push @ret, '<table cellpadding="2" cellspacing="0" width="100%">';

	while ( my ( $firstname, $lastname, $special, $email ) = $sth->fetchrow_array )
	{
		my $catname = $firstname . $lastname;
		$catname =~ s/ //g;
		$catname =~ s/\&//g;
		push @ret,
			"<tr>",
				"<td><a href=\"mailto:$email\"><img src=\"/i/mail.gif\" border=\"0\"></a></td>",
				"<td><small><b>$special</td>",
				"<td align=right><small><a href=\"./roster/#${catname}\">$firstname&nbsp;$lastname</a></small></td>",
			"</tr>";
	}

	push @ret, "</table>";
	return @ret;
}

# used by santana22.com
sub display_lowpoint
{
	my $year = shift;
	my $boatname = shift;
	my $format = shift;
	my $type = shift;
	my $throwouts = shift || 0;


	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;


	my @regattas;
	my %boats;
	my %lowpoint_score;

	# parse results
	while ( my ( $result, $rname, $seriesPosition, $rid ) = $sth->fetchrow_array )
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

			$lowpoint_score{$boat}{$rid}->{position} = $pos;
			$lowpoint_score{$boat}{$rid}->{points} = $pos;
			$boats{$boat}->{'regattas'}++;
		}

		my $regatta;
		$regatta->{boats} = scalar( @line );
		$regatta->{name} = $rname;
		$regatta->{rid} = $rid;
		push @regattas, $regatta;
	}

	if( scalar(@regattas) == 0 )
	{
		push @ret, '<i>Sorry, no results yet for this series.</i>';
		return @ret;
	}

	# fill in missed events
	foreach my $regatta ( @regattas )
	{
		foreach my $boat ( keys %boats )
		{
			if( !$lowpoint_score{$boat}{$regatta->{rid}}->{points} )
			{
				$lowpoint_score{$boat}{$regatta->{rid}}->{points} = $regatta->{boats} + 1;
				$lowpoint_score{$boat}{$regatta->{rid}}->{position} = ($regatta->{boats} + 1) . ' [DNC]';
			}
		}
	}

	if( scalar( @regattas ) >= 2 * $throwouts )
	{
		foreach my $throwout ( 1 .. $throwouts )
		{
			foreach my $boat ( keys %boats )
			{
				my $highest = 0;
				my $highest_rid = 0;
				foreach my $regatta ( reverse @regattas )
				{
					if( $lowpoint_score{$boat}{$regatta->{rid}}->{points} > $highest &&
						! $lowpoint_score{$boat}{$regatta->{rid}}->{throwout} )
					{
						$highest = $lowpoint_score{$boat}{$regatta->{rid}}->{points};
						$highest_rid = $regatta->{rid};
					}
				}

				$lowpoint_score{$boat}{$highest_rid}->{throwout} = 1;
			}
		}
	}

	foreach my $boat ( keys %boats )
	{
		$boats{$boat}->{total} = 0;
	}

	foreach my $boat ( keys %boats )
	{
		foreach my $rid ( keys %{$lowpoint_score{$boat}} )
		{
			if( ! $lowpoint_score{$boat}{$rid}->{throwout} )
			{
				$boats{$boat}->{total} += $lowpoint_score{$boat}{$rid}->{position};
			}
		}
	}

	# render
	push @ret,
		'<table class="score">',
			'<tr class="scoreHead">',
				'<td>Pos</td>',
				'<td>Boat</td>',
				'<td>Total</td>';
	
		if ( $format eq 'All' )
		{
			foreach my $regatta ( @regattas )
			{
				push @ret, "<td><a style=\"font-size:0.7em\" href=\"/schedule/$regatta->{rid}\">$regatta->{'name'}</a></td>";
			}
		}
		elsif( $format eq 'Narrow' )
		{
			push @ret, "<td>Sailed</td>";
		}

		push @ret, '</tr>';

		my $pos = 1;
		foreach my $boat ( sort { $boats{$a}->{total} <=> $boats{$b}->{total} } keys %boats )
		{
			push @ret, '<tr class="' . ( $pos % 2 ? 'score1' : 'score2' ) . '">';
			push @ret,
				"<td>$pos</td>",
				"<td>$boat</td>",
				"<td>$boats{$boat}->{total}</td>";

			if( $format eq 'All' )
			{
				foreach my $regatta ( @regattas )
				{
					push @ret,
						( $lowpoint_score{$boat}{$regatta->{rid}}->{throwout} ?
							"<td>($lowpoint_score{$boat}{$regatta->{rid}}->{position})</td>" :
							"<td>$lowpoint_score{$boat}{$regatta->{rid}}->{position}</td>"  );
				}
				push @ret, '</tr>';
			}
			elsif ( $format eq 'Narrow' )
			{
				push @ret,
					"<td>$boats{$boat}->{regattas}</td>";
			}
	
			$pos++;
		}

	push @ret, '</table>';

	#push @ret, '<pre>';
	#push @ret, Dumper( @regattas ), '<hr/>';
	#push @ret, Dumper( %boats ), '<hr/>';
	#push @ret, Dumper( %lowpoint_score ), '<hr/>';
	# push @ret, Dumper( %boats );
	# push @ret, '</pre>';

	return @ret;
}

# used by j24 fleet
sub display_regatta_highpoint
{
	my $year = shift;
	my $boatname = shift;
	my $format = shift;
	my $type = shift;
	# my $throwouts = shift || 0;

	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my @regattas;
	my %boats;
	my %highpoint_score;

	# parse results
	while ( my ( $result, $rname, $seriesPosition, $rid ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );

		my @line = split /\n/, $result;
		my @temp = split /\s*,\s*/, $line[0];
		my $noname = 0;
		if ( $temp[2] =~ /\d+/ ) {
			$noname = 1;
		}

		my $regatta;
		$regatta->{boats} = scalar( @line );
		$regatta->{name} = $rname;
		$regatta->{rid} = $rid;

		foreach ( @line )
		{
			if ( $noname ) {
				( $pos, $boat, $tot, @races ) = split /\s*,\s*/;
			} else {
				( $pos, $boat, $nm, $tot, @races ) = split /\s*,\s*/;
			}

			$highpoint_score{$boat}{$rid}->{position} = $pos; 
			$highpoint_score{$boat}{$rid}->{points} = ( $regatta->{boats} - $pos ) + 1;
			$highpoint_score{$boat}{$rid}->{possible} = $regatta->{boats};
			$boats{$boat}->{'regattas'}++;
		}

		push @regattas, $regatta;
	}

	if( scalar(@regattas) == 0 )
	{
		push @ret, '<i>Sorry, no results yet for this series.</i>';
		return @ret;
	}

	# you must do 70% of the regattas to qualify, and you can throwout
	# anything beyond that (rounded up to the nearest regatta)
	my $throwouts = int( 0.5 + (scalar(@regattas) * 0.3) );
	my $qualify = scalar(@regattas) - $throwouts;

	# fill in missed events
	foreach my $regatta ( @regattas )
	{
		foreach my $boat ( keys %boats )
		{
			if( !$highpoint_score{$boat}{$regatta->{rid}}->{points} ) 
			{
				$highpoint_score{$boat}{$regatta->{rid}}->{points} = 0;
				$highpoint_score{$boat}{$regatta->{rid}}->{possible} = $regatta->{boats};
				$highpoint_score{$boat}{$regatta->{rid}}->{position} = 'DNC';
			}
		}
	}

	if( scalar( @regattas ) >= 2 * $throwouts )
	{
		foreach my $throwout ( 1 .. $throwouts ) 
		{
			foreach my $boat ( keys %boats )
			{
				my $tmp_points = 0;
				my $tmp_possible = 0;
				my $highest_rid;

				foreach my $regatta ( reverse @regattas )
				{
					next if( $highpoint_score{$boat}{$regatta->{rid}}->{throwout} ); # already thrown out
					$tmp_points += $highpoint_score{$boat}{$regatta->{rid}}->{points};
					$tmp_possible += $highpoint_score{$boat}{$regatta->{rid}}->{possible};
				}

				# print "processing throwout $throwout for $boat, starting score is $tmp_points / $tmp_possible<br/>";

				my $highest_score = 0;
				foreach my $regatta ( reverse @regattas )
				{
					next if( $highpoint_score{$boat}{$regatta->{rid}}->{throwout} ); # already thrown out
		
					my $new_points = $tmp_points - $highpoint_score{$boat}{$regatta->{rid}}->{points};
					my $new_possible = $tmp_possible - $highpoint_score{$boat}{$regatta->{rid}}->{possible};

					if( $new_possible <= 0 ) { $new_possible = 1; }
					my $new_score = $new_points / $new_possible;
		
					if( $new_score > $highest_score )
					{
						$highest_rid = $regatta->{rid};
						$highest_score = $new_score;
					}
				}
		
				$highpoint_score{$boat}{$highest_rid}->{throwout} = 1;
			}
		}
	}

	foreach my $boat ( keys %boats )
	{
		$boats{$boat}->{sailed} = 0;
		$boats{$boat}->{points} = 0;
		$boats{$boat}->{possible} = 0;
		foreach my $regatta ( reverse @regattas )
		{
			if( $highpoint_score{$boat}{$regatta->{rid}}->{position} != 'DNC' )
			{
				$boats{$boat}->{sailed}++;
			}
			next if( $highpoint_score{$boat}{$regatta->{rid}}->{throwout} ); # throwout
			$boats{$boat}->{points} += $highpoint_score{$boat}{$regatta->{rid}}->{points};
			$boats{$boat}->{possible} += $highpoint_score{$boat}{$regatta->{rid}}->{possible};
		}
	
		$boats{$boat}->{score} = $boats{$boat}->{points} / $boats{$boat}->{possible};
	}

	# render
	push @ret,
		'<table cellspacing="2" cellpadding="2" style="font-size:80%" width="100%">',
			'<tr>',
				'<td>Pos</td>',
				'<td>Boat</td>',
				'<td>Score</td>',
				'<td>Points</td>';
	
		if ( $format eq 'All' )
		{
			foreach my $regatta ( @regattas )
			{
				push @ret, "<td align=\"center\"><a style=\"font-size:0.8em\" href=\"/schedule/$regatta->{rid}\">$regatta->{'name'}</a></td>";
			}
		}
		elsif( $format eq 'Narrow' )
		{
			push @ret, "<td>Sailed</td>";
		}

		push @ret, '</tr>';

		my $pos = 1;
		foreach my $boat ( sort { $boats{$b}->{score} <=> $boats{$a}->{score} } keys %boats )
		{
			push @ret, '<tr class="' . ( $pos % 2 ? 'score1' : 'score2' ) . '">';
			push @ret,
				'<td align="center">', ( $boats{$boat}->{sailed} >= $qualify ? "$pos" : '' ), '</td>',
				"<td>$boat</td>",
				sprintf("<td>%0.3f</td>", $boats{$boat}->{score}),
				"<td align=\"center\">$boats{$boat}->{points}/$boats{$boat}->{possible}</td>";

			if( $format eq 'All' )
			{
				foreach my $regatta ( @regattas )
				{
					my $disp = "$highpoint_score{$boat}{$regatta->{rid}}->{points}/$regatta->{boats}";
					push @ret,
						( $highpoint_score{$boat}{$regatta->{rid}}->{throwout} ?
							"<td bgcolor=\"#ccc\" align=\"center\">$disp</td>" :
							"<td align=\"center\">$disp</td>" );
				}
				push @ret, '</tr>';
			}
			elsif ( $format eq 'Narrow' )
			{
				push @ret,
					"<td>$boats{$boat}->{regattas}</td>";
			}
	
			$pos++;
		}

	push @ret, '</table>';

	#push @ret, '<pre>';
	#push @ret, Dumper( @regattas ), '<hr/>';
	#push @ret, Dumper( %boats ), '<hr/>';
	#push @ret, Dumper( %lowpoint_score ), '<hr/>';
	# push @ret, Dumper( %boats );
	# push @ret, '</pre>';

	return @ret;
}

# for laser grand prix (svendsens series)
sub display_regatta_highpoint_laser
{
	my $year = shift;
	my $boatname = shift;
	my $format = shift;
	my $type = shift;

	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my @regattas;
	my %boats;
	my %highpoint_score;

	# parse results
	while ( my ( $result, $rname, $seriesPosition, $rid ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );

		my @line = split /\n|\r\n/, $result;
		my @temp = split /\s*,\s*/, $line[0];
		my $noname = 0;
		if ( $temp[2] =~ /\d+/ ) {
			$noname = 1;
		}

		my $regatta;
		$regatta->{boats} = scalar( @line );
		$regatta->{name} = $rname;
		$regatta->{rid} = $rid;

		foreach ( @line )
		{
			if ( $noname ) {
				( $pos, $boat, $tot, @races ) = split /\s*,\s*/;
				$nm = $boat;
			} else {
				( $pos, $boat, $nm, $tot, @races ) = split /\s*,\s*/;
			}

			if( $regatta->{boats} >= 50 ) {
				$maxpoints = 30;
			} elsif ( $regatta->{boats} >= 35 ) {
				$maxpoints = 25;
			} elsif ( $regatta->{boats} >= 20 ) {
				$maxpoints = 20;
			} elsif ( $regatta->{boats} >= 10 ) {
				$maxpoints = 15;
			} else {
				$maxpoints = $regatta->{boats};
			}

			my $alldns = 1;
			if (scalar(@races) == 0)
			{
				$alldns = 0;
			}
			foreach my $race ( @races )
			{
				if($race ne 'DNS' && $race ne 'DNC')
				{
					$alldns = 0;
				}
			}

			if (!$alldns)
			{
				$points = ( $maxpoints - $pos ) + 1;
				if( $points < 1 ) { $points = 1; }
				$highpoint_score{$nm}{$rid}->{position} = $pos; 
				$highpoint_score{$nm}{$rid}->{points} = $points;
				$boats{$nm}->{'regattas'}++;
			}
		}

		push @regattas, $regatta;
	}

	if( scalar(@regattas) == 0 )
	{
		push @ret, '<i>Sorry, no results yet for this series.</i>';
		return @ret;
	}

	# you must do more than half of the events to qualify
	my $qualify = int((0.5 * scalar(@regattas)) + 1 );

	# fill in missed events
	foreach my $regatta ( @regattas )
	{
		foreach my $nm ( keys %boats )
		{
			if( ! $highpoint_score{$nm}{$regatta->{rid}}->{points} ) 
			{
				$highpoint_score{$nm}{$regatta->{rid}}->{points} = 0;
				$highpoint_score{$nm}{$regatta->{rid}}->{position} = 'DNC';
			}
		}
	}
	
	foreach my $nm ( keys %boats )
	{
		$boats{$nm}->{sailed} = 0;
		$boats{$nm}->{points} = 0;
		foreach my $regatta ( reverse @regattas )
		{
			if( $highpoint_score{$nm}{$regatta->{rid}}->{position} != 'DNC' )
			{
				$boats{$nm}->{sailed}++;
			}

			$boats{$nm}->{points} += $highpoint_score{$nm}{$regatta->{rid}}->{points};
		}
	
		$boats{$nm}->{score} = $boats{$nm}->{points};
	}

	# render
	push @ret,
		'<table cellspacing="2" cellpadding="2" style="font-size:80%" width="100%">',
			'<tr>',
				'<td>Pos</td>',
				'<td>Boat</td>',
				'<td align="center">Total Points</td>';
	
		if ( $format eq 'All' )
		{
			foreach my $regatta ( @regattas )
			{
				push @ret, "<td align=\"center\"><a style=\"font-size:0.8em\" href=\"/schedule/$regatta->{rid}\">$regatta->{'name'}</a></td>";
			}
		}
		elsif( $format eq 'Narrow' )
		{
			push @ret, "<td align=\"center\">Sailed</td>";
		}

		push @ret, '</tr>';

		my $pos = 1;
		foreach my $nm ( sort { $boats{$b}->{score} <=> $boats{$a}->{score} } keys %boats )
		{
			push @ret, '<tr class="' . ( $pos % 2 ? 'score1' : 'score2' ) . '">';
			push @ret,
				'<td align="center">', ( $boats{$nm}->{sailed} >= $qualify ? "$pos" : '' ), '</td>',
				"<td>$nm</td>",
				"<td align=\"center\">$boats{$nm}->{points}</td>";

			if( $format eq 'All' )
			{
				foreach my $regatta ( @regattas )
				{
					my $disp = "$highpoint_score{$nm}{$regatta->{rid}}->{points}";
					push @ret, "<td align=\"center\">$disp</td>";
				}
				push @ret, '</tr>';
			}
			elsif ( $format eq 'Narrow' )
			{
				push @ret,
					"<td align=\"center\">$boats{$nm}->{regattas}</td>";
			}
	
			$pos++;
		}

	push @ret, '</table>';

	#push @ret, '<pre>';
	#push @ret, Dumper( @regattas ), '<hr/>';
	#push @ret, Dumper( %boats ), '<hr/>';
	#push @ret, Dumper( %lowpoint_score ), '<hr/>';
	# push @ret, Dumper( %boats );
	# push @ret, '</pre>';

	return @ret;
}


sub display_highpoint
{
	my $year = shift || $config{'defaultYear'};
	my $boatname = shift;
	my $format = shift || "All";
	my $type = shift || "series1";

	my @ret;

	my @highpoint_possible;
	my %highpoint_score;
	my %highpoint_t_possible;
	my %highpoint_t_score;
	my @regattas;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my $racenumtot = 1;
	while ( my ( $result, $rname, $highpoint, $rid ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );
		my @line = split /\n/, $result;
		my @temp = split /\s*,\s*/, $line[0];
		my $noname = 0;
		if ( $temp[2] =~ /\d+/ ) {
			$noname = 1;
		}

		my $weight = $highpoint > 1 ? $highpoint : 1;

		my @res;
		my @dnf;
		my @dsq;
		my @dns;
		my @rdg;
		my @tot;

		foreach ( @line )
		{
			if ( $noname ) {
				( $pos, $boat, $tot, @races ) = split /\s*,\s*/;
			} else {
				( $pos, $boat, $nm, $tot, @races ) = split /\s*,\s*/;
			}
			my $racenum = 0;
			foreach my $race ( @races ) {
				# remove throwout symobls
				$race =~ s/^\(//;
				$race =~ s/\)$//;

				# see http://raceadmin.ussailing.org/Assets/Race+Admin/Race+Officers/Documents/PDF/AppA-Guidance-V4-0.pdf
				# technically DNS should probably be treated differently than DNC
				$racenum++;
				if ( $race =~ /DNS/ || $race =~ /DNC/ ) {
					push @{ $dns[$racenum] }, $boat;
				} elsif ( $race =~ /DSQ/ ) {
					$tot[$racenum]++;
					push @{ $dsq[$racenum] }, $boat;
				} elsif ( $race =~ /RAF/ ) {
					$tot[$racenum]++;
					push @{ $raf[$racenum] }, $boat;
				} elsif ( $race =~ /DNF/ || $race =~ /OCS/ ) {
					$tot[$racenum]++;
					push @{ $dnf[$racenum] }, $boat;
				} elsif ( $race =~ /RDG/ ) {
					# TODO: redress, you get average points for the series
					$tot[$racenum]++;
					push @{ $rdg[$racenum] }, $boat;
				} else {
					$tot[$racenum]++;
					$res[$racenum]{$boat} = $race;
				}
			}
		}

	 	foreach my $racenum ( 1 .. scalar @races )
		{
			$actualracenum = $racenum + $racenumtot - 1;
			$highpoint_possible[$actualracenum] = $weight * $tot[$racenum];
			foreach my $boat ( @{ $dnf[$racenum] } ) {
				$highpoint_score{$boat}[$actualracenum] = $weight * ( 0.5 * ( scalar @{ $dnf[$racenum] } + 1));
			}
			foreach my $boat ( @{ $raf[$racenum] } ) {
				$highpoint_score{$boat}[$actualracenum] = $weight * ( 0.5 * ( scalar @{ $raf[$racenum] } + 1));
			}
			foreach my $boat ( @{ $dsq[$racenum] } ) {
				# $highpoint_score{$boat}[$racenumtot] = 0;
				$highpoint_score{$boat}[$actualracenum] = '0.0';
			}
			foreach my $boat ( keys %{ $res[$racenum] } ) {
				$highpoint_score{$boat}[$actualracenum] = $weight * (( $tot[$racenum] + 1 ) - ${ $res[$racenum]}{$boat});
			}
		}

		# apply redress

		# first figure out average score for each boat before throwouts
		my %avg_total;
		my %avg_position;
		foreach my $boat ( sort keys %highpoint_score )
		{
			my $total;
			my $possible;
			my $races;
			foreach my $racenum ( 1 .. $racenumtot ) {
				if ( defined $highpoint_score{$boat}[$racenum] ) {
					$races++;
					$possible += $highpoint_possible[$racenum];
					$total += $highpoint_score{$boat}[$racenum];
				}
			}
			# round to nearest 0.05
			if( $races > 0 )
			{
				$avg_total{$boat} = $total / $races;
				$avg_possible{$boat} = $possible / $races;
			}
		}

	 	foreach my $racenum ( 1 .. scalar @races )
		{
			$actualracenum = $racenum + $racenumtot - 1;
			$highpoint_possible[$actualracenum] = $weight * $tot[$racenum];
			foreach my $boat ( @{ $rdg[$racenum] } )
			{
				$score = $tot[$racenum] * $avg_total{$boat} / $avg_possible{$boat};
				$score = int(($score*20)+0.5) / 20; # round to nearest 0.05
				$highpoint_score{$boat}[$actualracenum] = $weight * $score;
			}
		}

		my $regatta;
		$regatta->{races} = scalar @races;
		$regatta->{name} = $rname;
		push @regattas, $regatta;
		$racenumtot += scalar @races;
	}

	my $realracetotal = $racenumtot - 1;
	my $qualifytotal = 0;

	my %throwouts;
	my %totraces;
	my %totthrowouts;
	my %totscore;
	foreach my $boat ( sort keys %highpoint_score )
	{
		my $total;
		my $possible;
		my $races;
		foreach my $racenum ( 1 .. $racenumtot ) {
			if ( defined $highpoint_score{$boat}[$racenum] ) {
				$races++;
				$possible += $highpoint_possible[$racenum];
				$total += $highpoint_score{$boat}[$racenum];
			}
		}

		my $used = 0;
		my $throws = 0;

		if ( $year == 2003 ) {
			if ( $races >= 42 ) { $throws = 13; }
			elsif ( $races >= 41 ) { $throws = 12; }
			elsif ( $races >= 40 ) { $throws = 11; }
			elsif ( $races >= 39 ) { $throws = 10; }
			elsif ( $races >= 38 ) { $throws = 9; }
			elsif ( $races >= 36 ) { $throws = 8; }
			elsif ( $races >= 34 ) { $throws = 7; }
			elsif ( $races >= 32 ) { $throws = 6; }
			elsif ( $races >= 30 ) { $throws = 5; }
			elsif ( $races >= 28 ) { $throws = 4; }
			elsif ( $races >= 25 ) { $throws = 3; }
			elsif ( $races >= 22 ) { $throws = 2; }
			elsif ( $races >= 20 ) { $throws = 1; }
			$qualifytotal = 20;
		} elsif ( $year == 2004 ) {
			if ( $races >= 36 ) { $throws = 12; }
			elsif ( $races >= 35 ) { $throws = 11; }
			elsif ( $races >= 34 ) { $throws = 10; }
			elsif ( $races >= 33 ) { $throws = 9; }
			elsif ( $races >= 32 ) { $throws = 8; }
			elsif ( $races >= 31 ) { $throws = 7; }
			elsif ( $races >= 29 ) { $throws = 6; }
			elsif ( $races >= 27 ) { $throws = 5; }
			elsif ( $races >= 25 ) { $throws = 4; }
			elsif ( $races >= 23 ) { $throws = 3; }
			elsif ( $races >= 20 ) { $throws = 2; }
			elsif ( $races >= 17 ) { $throws = 1; }
			$qualifytotal = 17;
		}
		else
		{
			# 1 throwout for every 2.5 races from 50-55% of total
			# 1 throwout for every 2 races from 55-60% of total
			# 1 throwout for every 1.5 races from 60-65% of total
			# 1 throwout for every 1 race over 65% of total
			# 50% of races required to qualify

			my $p50 = 0.5 * $realracetotal;
			my $p55 = 0.55 * $realracetotal;
			my $p60 = 0.6 * $realracetotal;
			my $p65 = 0.65 * $realracetotal;
			$qualifytotal = ( $p50 == int($p50) ? $p50 : int($p50) + 1 );

			if ( $races <= $p50 )
			{
				$throws = 0;
			}
			if ( $races > $p50 && $races <= $p55 )
			{
				$throws = (( $races - $p50 ) / 2.5);
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

			# round to nearest whole number
			$throws = int( $throws + 0.5 );
		}

		while( $used < $throws && $possible != 0 )
		{
			my $best = $total / $possible;
			my $bestrace = 0;
			foreach my $racenum ( 1 .. $racenumtot )
			{
				if ( defined $highpoint_score{$boat}[$racenum] &&
					! $throwouts{$boat}[$racenum]
				)
				{
					next if $highpoint_score{$boat}[$racenum] eq '0.0';
					my $newpossible = $possible - $highpoint_possible[$racenum];
					my $newtotal = $total - $highpoint_score{$boat}[$racenum];
					my $newscore = $newtotal / $newpossible;
					if ( $newscore > $best ) {
						$best = $newscore;
						$bestrace = $racenum;
					}
				}
			}

			$throwouts{$boat}[$bestrace] = 1;
			$total -= $highpoint_score{$boat}[$bestrace];
			$possible -= $highpoint_possible[$bestrace];
			$used++;
		}
		$highpoint_t_possible{$boat} = $possible;
		$highpoint_t_total{$boat} = $total;
		$totraces{$boat} = $races;
		$totthrowouts{$boat} = $throws;
		$totscore{$boat} = $total / $possible;
	}


	if ( $format eq 'All' ) {
			push @ret, '<table border="0"><tr bgcolor="#d1d1d1"><td align="center"><font size="-2"><b>&nbsp;Pos&nbsp;</font></td><td align="left"><font size="-2"><b>Boat</b></font></td><td align="right"><font size="-2"><b>Races</b></font></td><td align="center" colspan="2"><font size="-2">Score</font></td>';
		foreach my $reg ( @regattas ) {
			$plural = $reg->{races} == 1 ? '' : 's';
			push @ret, "<td colspan=$reg->{races} align=center><font size=-2>$reg->{name}<br/>($reg->{races} race$plural)</font>";
		}
	} elsif ( $format eq 'Narrow' ) {
		push @ret, '<table border="0" cellpadding="2" cellspacing="0" width="100%"><tr bgcolor="#d1d1d1"><td align="center"><small><b>&nbsp;Pos&nbsp;</b></small></td><td align="left"><small><b>Boat</b></small></td><td align="right"><small><b>Races</b></small></td><td>&nbsp;</td><td align="center" colspan="2"><b><small>Score</small></b></td>';
	}

	my $linenum = 1;
	my $rank = 1;
	foreach my $boat ( sort { $totscore{$b} <=> $totscore{$a} } keys %totscore ) {
		if ( defined $boat && defined $boatname && $boat eq $boatname ) {
			push @ret, "<tr bgcolor=\"#ffccff\">"; 
			$linenum++;
		} else {
			push @ret, ( ( $linenum++ % 2 ) ? "<tr bgcolor=\"#efefd1\">\n" : "<tr bgcolor=white>\n" );
		}
		if ( $totraces{$boat} >= $qualifytotal ) {
			if ( $format eq 'All' ) { 
				push @ret, "<td align=center><font size=-2>$rank</font>";
			} elsif ( $format eq 'Narrow' ) {
				push @ret, "<td align=center><small>$rank</small>";
			}
			$rank++;
		} else {
			push @ret, "<td align=center>&nbsp";
		}
		if ( $format eq 'All' ) {
			push @ret,
				"<td><font size=-2>$boat</font>",
				"<td align=center><font size=-2>$totraces{$boat}&nbsp;($totthrowouts{$boat})</font>",
				sprintf( "<td align=right><b><font size=-2>%.2f</font></b>", $totscore{$boat} ),
				"<td align=center><font size=-2>($highpoint_t_total{$boat}&nbsp;/&nbsp;$highpoint_t_possible{$boat})</font>\n";
		} elsif ( $format eq 'Narrow' ) {
			push @ret, "<td>", ( defined $boat && defined $boatname && $boat eq $boatname ? "<big><b>" : "" ), "<small>$boat</small>";
			push @ret, "<td align=right><small>$totraces{$boat} ($totthrowouts{$boat})</small>",
				"<td>&nbsp;",
				"<td align=right><small><b>", sprintf("%.2f", $totscore{$boat}), "</b></small>",
				"<td align=center><font size=-2>($highpoint_t_total{$boat}&nbsp;/&nbsp;$highpoint_t_possible{$boat})</font>\n";
			
		}

		if ( $format eq 'All' ) {
			foreach my $racenum ( 1 .. ( $racenumtot - 1 ) ) {
				if ( defined $highpoint_score{$boat}[$racenum] ) {
					if ( $throwouts{$boat}[$racenum] ) {
						push @ret, "<td bgcolor=\"#cccccc\" align=center>";
					} else {
						push @ret, "<td align=center>";
					}
					push @ret, "<font size=-2>$highpoint_score{$boat}[$racenum]/$highpoint_possible[$racenum]</font>";
				} else {
					push @ret, "<td>&nbsp;";
				}

			}
			push @ret, "\n";
		}
	}
	push @ret, "</table>";
	push @ret, "<center><small><i>$realracetotal possible races so far, $qualifytotal required to qualify (50% or more).  <a href=\"/throwouts/?races=$realracetotal\">throwout schedule</a></i></small></center>";
        push @ret, "<center><small><a href=\"/articles/seasonscoring\">Season scoring calculation explanation</a></small></center>";
	return @ret;
}

sub display_pure_highpoint
{
	my $year = shift || $config{'defaultYear'};
	my $boatname = shift;
	my $format = shift || "All";
	my $type = shift || "series1";

	my @ret;

	my @highpoint_possible;
	my %highpoint_score;
	my %highpoint_t_possible;
	my %highpoint_t_score;
	my @regattas;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my $racenumtot = 1;
	while ( my ( $result, $rname, $highpoint, $rid ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );
		my @line = split /\n/, $result;
		my @temp = split /\s*,\s*/, $line[0];
		my $noname = 0;
		if ( $temp[2] =~ /\d+/ ) {
			$noname = 1;
		}

		my @res;
		my @dnf;
		my @dsq;
		my @dns;
		my @raf;
		my @tot;

		foreach ( @line )
		{
			if ( $noname ) {
				( $pos, $boat, $tot, @races ) = split /\s*,\s*/;
			} else {
				( $pos, $boat, $nm, $tot, @races ) = split /\s*,\s*/;
			}
			my $racenum = 0;
			foreach my $race ( @races ) {
				# remove throwout symobls
				$race =~ s/^\(//;
				$race =~ s/\)$//;

				$racenum++;
				if ( $race =~ /DNS/ || $race =~ /DNC/ ) {
					push @{ $dns[$racenum] }, $boat;
				} elsif ( $race =~ /DSQ/ ) {
					$tot[$racenum]++;
					push @{ $dsq[$racenum] }, $boat;
				} elsif ( $race =~ /RAF/ ) {
					$tot[$racenum]++;
					push @{ $raf[$racenum] }, $boat;
				} elsif ( $race =~ /DNF/ || $race =~ /OCS/ ) {
					$tot[$racenum]++;
					push @{ $dnf[$racenum] }, $boat;
				} else {
					$tot[$racenum]++;
					$res[$racenum]{$boat} = $race;
				}
			}
		}

	 	foreach my $racenum ( 1 .. scalar @races )
		{
			$actualracenum = $racenum + $racenumtot - 1;
			$highpoint_possible[$actualracenum] = $tot[$racenum];
			foreach my $boat ( @{ $dnf[$racenum] } ) {
				$highpoint_score{$boat}[$actualracenum] = 0.5 * ( scalar @{ $dnf[$racenum] } + 1) ;
			}
			foreach my $boat ( @{ $raf[$racenum] } ) {
				$highpoint_score{$boat}[$actualracenum] = 0.5 * ( scalar @{ $raf[$racenum] } + 1) ;
			}
			foreach my $boat ( @{ $dsq[$racenum] } ) {
				# $highpoint_score{$boat}[$racenumtot] = 0;
				$highpoint_score{$boat}[$actualracenum] = '0.0';
			}
			foreach my $boat ( keys %{ $res[$racenum] } ) {
				$highpoint_score{$boat}[$actualracenum] = ( $tot[$racenum] + 1 ) - ${ $res[$racenum]}{$boat};
			}
		}

		my $regatta;
		$regatta->{races} = scalar @races;
		$regatta->{name} = $rname;
		push @regattas, $regatta;
		$racenumtot += scalar @races;
	}

	my $realracetotal = $racenumtot - 1;
	my $qualifytotal = 0;

	my %throwouts;
	my %totraces;
	my %totthrowouts;
	my %totscore;
	foreach my $boat ( sort keys %highpoint_score )
	{
		my $total;
		my $possible;
		my $races;
		foreach my $racenum ( 1 .. $racenumtot ) {
			if ( defined $highpoint_score{$boat}[$racenum] ) {
				$races++;
				$possible += $highpoint_possible[$racenum];
				$total += $highpoint_score{$boat}[$racenum];
			}
		}

		$totraces{$boat} = $races;
		$totscore{$boat} = $total;
	}


	if ( $format eq 'All' ) {
			push @ret, '<table border="0"><tr bgcolor="#d1d1d1"><td align="center"><font size="-2"><b>&nbsp;Pos&nbsp;</font></td><td align="left"><font size="-2"><b>Boat</b></font></td><td align="right"><font size="-2"><b>Races</b></font></td><td align="center"><font size="-2">Highpoints</font></td>';
		foreach my $reg ( @regattas ) {
			$plural = $reg->{races} == 1 ? '' : 's';
			push @ret, "<td colspan=$reg->{races} align=center><font size=-2>$reg->{name}<br/>($reg->{races} race$plural)</font>";
		}
	} elsif ( $format eq 'Narrow' ) {
		push @ret, '<table border="0" cellpadding="2" cellspacing="0" width="100%"><tr bgcolor="#d1d1d1"><td align="center"><small><b>&nbsp;Pos&nbsp;</b></small></td><td align="left"><small><b>Boat</b></small></td><td align="right"><small><b>Races</b></small></td><td>&nbsp;</td><td align="center" colspan="2"><b><small>Highpoints</small></b></td>';
	}

	my $linenum = 1;
	my $rank = 1;
	foreach my $boat ( sort { $totscore{$b} <=> $totscore{$a} } keys %totscore ) {
		if ( defined $boat && defined $boatname && $boat eq $boatname ) {
			push @ret, "<tr bgcolor=\"#ffccff\">"; 
			$linenum++;
		} else {
			push @ret, ( ( $linenum++ % 2 ) ? "<tr bgcolor=\"#efefd1\">\n" : "<tr bgcolor=white>\n" );
		}

		if ( $format eq 'All' ) { 
			push @ret, "<td align=center><font size=-2>$rank</font>";
		} elsif ( $format eq 'Narrow' ) {
			push @ret, "<td align=center><small>$rank</small>";
		}
		$rank++;

		if ( $format eq 'All' ) {
			push @ret,
				"<td><font size=-2>$boat</font>",
				"<td align=center><font size=-2>$totraces{$boat}</font>",
				sprintf( "<td align=right><b><font size=-2>%d</font></b>", $totscore{$boat} );
		} elsif ( $format eq 'Narrow' ) {
			push @ret, "<td>", ( defined $boat && defined $boatname && $boat eq $boatname ? "<big><b>" : "" ), "<small>$boat</small>";
			push @ret, "<td align=right><small>$totraces{$boat}</small>",
				"<td align=right><small><b>", sprintf("%d", $totscore{$boat}), "</b></small>";
		}

		if ( $format eq 'All' ) {
			foreach my $racenum ( 1 .. ( $racenumtot - 1 ) ) {
				if ( defined $highpoint_score{$boat}[$racenum] ) {
					push @ret, "<td align=center>";
					push @ret, "<font size=-2>$highpoint_score{$boat}[$racenum]</font>";
				} else {
					push @ret, "<td>&nbsp;";
				}
			}
			push @ret, "\n";
		}
	}
	push @ret, "</table>";
	push @ret, "<center><small><i>$realracetotal possible races so far.</center>";
	return @ret;
}

# used by vanguard15.org
sub display_thursday_highpoint
{
	my $year = shift || $config{'defaultYear'};
	my $boatname = shift;
	my $format = shift || "All";
	my $type = shift || "series1";
	# my ( $year ) = @_;
	# $year ||= 2006;

	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my %highpoint = ();
	my %highpointreggattas = ();
	my %highpointpeople = ();
	my %highpointbest12 = ();
	while ( my ( $result ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );
		my @line = split /\n/, $result;
		my $numboats = $#line + 1;
		foreach ( @line )
		{
			my ( $pos, $sailnumber, $people, @rest ) = split /\s*,\s*/;

			my $thisScore = ( $numboats - $pos ) + 1;
			#see if this score should get added
			my $scorecnt = $#{$highpointbest12{$sailnumber}} + 1; #returns last index, not count

			#keep only 12 best scores			
	       	if ($scorecnt < 12)
			{
				push @{$highpointbest12{$sailnumber}}, $thisScore;
			} else
			{
			   @{$highpointbest12{$sailnumber}} = sort {$b <=> $a} @{$highpointbest12{$sailnumber}};
				if (${$highpointbest12{$sailnumber}}[$scorecnt-1] < $thisScore)
				{
				   ${$highpointbest12{$sailnumber}}[$scorecnt-1] = $thisScore;
				}
         }
			$highpointregattas{$sailnumber}++;
			$highpointpeople{$sailnumber}{$people}++;
		}
	}
	
	foreach my $sailnumber (keys %highpointbest12)
	{
	   my $totalScore = 0;
		foreach my $score (@{$highpointbest12{$sailnumber}})
		{
  		    $totalScore += $score;
		}
		$totalScore += $highpointregattas{$sailnumber} * ( $year >= 2009 ? 3: 5 );  #each sailor earns 5 points for every sailed night (even beyond 12)
		$highpoint{$sailnumber} = $totalScore;
}

		push @ret, '<table border=0 cellpadding=2 cellspacing=0 width="100%">',
		'<tr bgcolor="#d1d1d1">',
		"<th><small>Pos</small></th><th align=left><small>Sail #</small></th><th><small>People</small></th><th><small>Points</small></th><th><small>Events</small></th>",
    '</tr>';


	my $pos = 1;
	foreach my $sailnumber ( sort { $highpoint{$b} <=> $highpoint{$a} } keys %highpoint )
	{
		push @ret, ( ( $linenum++ % 2 ) ? "<tr bgcolor=\"#efefd1\">" : "<tr bgcolor=white>" ),
			"<td align=center><small>$pos</small></td>",
			"<td><small>$sailnumber</small></td>",
			"<td><span style=\"font-size:0.6em\">";
		foreach my $person ( keys %{$highpointpeople{$sailnumber}} ) {
			push @ret, "$person<br>";
		}
		push @ret, "</span></td>";
		push @ret, 
			"<td align=center><small>$highpoint{$sailnumber}</small></td>",
			"<td align=center><small>$highpointregattas{$sailnumber}</small></td>\n";
		$pos++;
	}

	push @ret, "</table>";

	return @ret;
}

sub display_open570_highpoint
{
	my $year = shift || $config{'defaultYear'};
	my $boatname = shift;
	my $format = shift || "All";
	my $type = shift || "series1";

	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my $bestWeeks = ( $sth->rows >= 4 ? $sth->rows - 1 : $sth->rows ); # one throwout

	my %highpoint = ();
	my %highpointreggattas = ();
	my %highpointpeople = ();
	my %highpointbest = ();
	while ( my ( $result ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );
		my @line = split /\n/, $result;
		my $numboats = $#line + 1;
		foreach ( @line )
		{
			my ( $pos, $sailnumber, $people, @rest ) = split /\s*,\s*/;

			my $thisScore = 1 + ( 9 / $numboats ) * ( $numboats - $pos + 0.5 );
			#see if this score should get added
			my $scorecnt = $#{$highpointbest{$sailnumber}} + 1; #returns last index, not count

			# die $bestWeeks;
			# die $scorecnt;
			# die $#{$highpointbest{$sailnumber}};


			# next if ($scorecnt == 0);

			#keep only best scores
			if ($scorecnt < $bestWeeks)
			{
				push @{$highpointbest{$sailnumber}}, $thisScore;
			}
			else
			{
				@{$highpointbest{$sailnumber}} = sort {$b <=> $a} @{$highpointbest{$sailnumber}};
				if (${$highpointbest{$sailnumber}}[$scorecnt-1] < $thisScore)
				{
				   ${$highpointbest{$sailnumber}}[$scorecnt-1] = $thisScore;
				}
			}
			$highpointregattas{$sailnumber}++;
			$highpointpeople{$sailnumber}{$people}++;
		}
	}

	foreach my $sailnumber (keys %highpointbest)
	{
		my $totalScore = 0;
		foreach my $score (@{$highpointbest{$sailnumber}})
		{
  		    $totalScore += $score;
		}
		$highpoint{$sailnumber} = $totalScore;
	}

	push @ret,
		'<table border=0 cellpadding=2 cellspacing=0 width="100%">',
			'<tr bgcolor="#d1d1d1">',
			"<th><small>Pos</small></th><th align=left><small>Sail #</small></th><th><small>People</small></th><th><small>Points</small></th><th><small>Events</small></th>",
    		'</tr>';

	my $pos = 1;
	foreach my $sailnumber ( sort { $highpoint{$b} <=> $highpoint{$a} } keys %highpoint )
	{
		push @ret, ( ( $linenum++ % 2 ) ? "<tr bgcolor=\"#efefd1\">" : "<tr bgcolor=white>" ),
			"<td align=center><small>$pos</small></td>",
			"<td><small>$sailnumber</small></td>",
			"<td><span style=\"font-size:0.6em\">";

		foreach my $person ( keys %{$highpointpeople{$sailnumber}} )
		{
			push @ret, "$person<br>";
		}
		push @ret, "</span></td>";
		push @ret, 
			"<td align=center><small>$highpoint{$sailnumber}</small></td>",
			"<td align=center><small>$highpointregattas{$sailnumber}</small></td>\n";
		$pos++;
	}

	push @ret, "</table>";

	return @ret;
}

# used by rycsunday.myfleet.org
sub display_sunday_highpoint
{
	my $year = shift || $config{'defaultYear'};
	my $boatname = shift;
	my $format = shift || "All";
	my $type = shift || "series1";

	my $bestWeeks = 6; # your score is based on the best X weeks
	my $participationPoints = 1; # you also get this number of points for each week you participate

	my @ret;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select result, name, $type, id from regatta where $type > 0 and startdate < now() and year(startdate) = ? order by startdate") || die $DBI::errstr;
	$sth->execute( $year ) || die $DBI::errstr;

	my %highpoint = ();
	my %highpointreggattas = ();
	my %highpointpeople = ();
	my %highpointbest = ();
	while ( my ( $result ) = $sth->fetchrow_array )
	{
		next if ( ! $result || length( $result ) < 10 );
		my @line = split /\n/, $result;
		my $numboats = $#line + 1;
		foreach ( @line )
		{
			my ( $pos, $sailnumber, $people, @rest ) = split /\s*,\s*/;

			my $thisScore = ( $numboats - $pos ) + 1;
			#see if this score should get added
			my $scorecnt = $#{$highpointbest{$sailnumber}} + 1; #returns last index, not count

			#keep only best scores			
			if ($scorecnt < $bestWeeks)
			{
				push @{$highpointbest{$sailnumber}}, $thisScore;
			}
			else
			{
				@{$highpointbest{$sailnumber}} = sort {$b <=> $a} @{$highpointbest{$sailnumber}};
				if (${$highpointbest{$sailnumber}}[$scorecnt-1] < $thisScore)
				{
				   ${$highpointbest{$sailnumber}}[$scorecnt-1] = $thisScore;
				}
			}
			$highpointregattas{$sailnumber}++;
			$highpointpeople{$sailnumber}{$people}++;
		}
	}
	
	foreach my $sailnumber (keys %highpointbest)
	{
		my $totalScore = 0;
		foreach my $score (@{$highpointbest{$sailnumber}})
		{
  		    $totalScore += $score;
		}
		$totalScore += $highpointregattas{$sailnumber} * $participationPoints;  # each sailor earns 1 extra point for every sunday sailed (even beyond max)
		$highpoint{$sailnumber} = $totalScore;
	}

	push @ret,
		'<table border=0 cellpadding=2 cellspacing=0 width="100%">',
			'<tr bgcolor="#d1d1d1">',
			"<th><small>Pos</small></th><th align=left><small>Sail #</small></th><th><small>People</small></th><th><small>Points</small></th><th><small>Events</small></th>",
    		'</tr>';

	my $pos = 1;
	foreach my $sailnumber ( sort { $highpoint{$b} <=> $highpoint{$a} } keys %highpoint )
	{
		push @ret, ( ( $linenum++ % 2 ) ? "<tr bgcolor=\"#efefd1\">" : "<tr bgcolor=white>" ),
			"<td align=center><small>$pos</small></td>",
			"<td><small>$sailnumber</small></td>",
			"<td><span style=\"font-size:0.6em\">";

		foreach my $person ( keys %{$highpointpeople{$sailnumber}} )
		{
			push @ret, "$person<br>";
		}
		push @ret, "</span></td>";
		push @ret, 
			"<td align=center><small>$highpoint{$sailnumber}</small></td>",
			"<td align=center><small>$highpointregattas{$sailnumber}</small></td>\n";
		$pos++;
	}

	push @ret, "</table>";

	return @ret;
}

1;
