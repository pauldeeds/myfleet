#!/usr/local/bin/perl

use diagnostics;
use strict;

use lib '/usr/local/apache2/mylib/myfleet.org/';

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::DB;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header( -expires => 600 ),
		$q->start_html,
		'<head>',
			'<meta name="robots" content="noindex">',
		'</head>',
		'<body>';

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select distinct hullnumber from oldperson order by hullnumber" ) || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;

	push @ret,
		'<h2>Old Roster</h2>',
		"<table width=100%>",
		"<tr><td colspan=4><h3>Boats</h3>";

	while ( my ( $hullnumber ) = $sth->fetchrow )
	{
		# next if ( ! $hullnumber );
		my $stz = $dbh->prepare( "select firstname, lastname, sailnumber, boatname, special, email, city, state from oldperson where hullnumber = ? and type='owner' order by lastname, firstname" ) || die $DBI::errstr;

		$stz->execute( $hullnumber ) || die $DBI::errstr;
		my $first = 1;
		while ( my ( $firstname, $lastname, $sailnumber, $boatname, $special, $email, $city, $state ) = $stz->fetchrow )
		{
			my $catname = $firstname . $lastname;
			$catname =~ s/ //g;
			$catname =~ s/\&//g;
			my $oldname = "";
			push @ret,
				"<tr>",
				( ( ! $first ) ? "<td>&nbsp" : "<td>#&nbsp;$hullnumber&nbsp;&nbsp;" ),
				( ( $sailnumber && ( $sailnumber ne $hullnumber ) ) ? "<td><small>($sailnumber)" : "<td>&nbsp;" ),
				( $boatname ? "<td>$boatname" : "<td>&nbsp;" );

				if ( $catname ne $oldname )
				{
					push @ret,
						"<td><a href='#${catname}'>$firstname $lastname</a>",
						( ( $special ) ? "<br><small>($special)</small>&nbsp;&nbsp;" : ""),
						( ( ! $email ) ? "<td>&nbsp;" :"<td><a href='mailto:$email'>$email" ),
						"<td>$state";
						$oldname = $catname;
				}
				else
				{
					push @ret, "<td colspan=3>[ see above ]";
				}
				$first = 0;
		}
	}

	$sth = $dbh->prepare("select firstname, lastname, special, email, city, state from oldperson where type='crew' order by lastname, firstname") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;
	
	if ( $sth->rows ) { push @ret, "<tr><td colspan=4><br><h3>Crews</h3>"; }

	while ( my ( $firstname, $lastname, $special, $email, $city, $state ) = $sth->fetchrow )
	{
		my $catname = $firstname . $lastname;
		$catname =~ s/ //g;
		$catname =~ s/\&//g;
		push @ret,
			"<tr><td colspan=3>&nbsp;",
			"<td><a href='#${catname}'>$firstname $lastname</a>",
			( ( $special ) ? " <small>($special)</small>&nbsp;&nbsp;" : ""),
			( ( ! $email ) ? "<td>&nbsp;</td>" :"<td><a href='mailto:$email'>$email" ),
			"<td>$state";
	}

	$sth = $dbh->prepare("select firstname, lastname, special, email, city, state from oldperson where type='other' and id > 0 order by lastname, firstname") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;
	
	if ( $sth->rows ) { push @ret, "<tr><td colspan=4><br><h3>Other</h3>"; }

	while ( my ( $firstname, $lastname, $special, $email, $city, $state ) = $sth->fetchrow )
	{
		my $catname = $firstname . $lastname;
		$catname =~ s/ //g;
		$catname =~ s/\&//g;
		push @ret,
			"<tr><td colspan=3>&nbsp;",
			"<td><a href='#${catname}'>$firstname $lastname</a>",
			( ( $special ) ? " <small>($special)</small>&nbsp;&nbsp;" : ""),
			( ( ! $email ) ? "<td>&nbsp;</td>" :"<td><a href='mailto:$email'>$email" ),
			"<td>$state";
	}

	$sth = $dbh->prepare("select firstname, lastname, special, email, city, state from oldperson where type='Crew List' and id > 0 order by lastname, firstname") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;
	
	if ( $sth->rows ) { push @ret, "<tr><td colspan=4><br><h3>Crew List</h3>"; }

	while ( my ( $firstname, $lastname, $special, $email, $city, $state ) = $sth->fetchrow )
	{
		my $catname = $firstname . $lastname;
		$catname =~ s/ //g;
		$catname =~ s/\&//g;
		push @ret,
			"<tr><td colspan=3>&nbsp;",
			"<td><a href='#${catname}'>$firstname $lastname</a>",
			( ( $special ) ? " <small>($special)</small>&nbsp;&nbsp;" : ""),
			( ( ! $email ) ? "<td>&nbsp;" :"<td><a href='mailto:$email'>$email" ),
			"<td>$state";
	}
	push @ret, "</table>";

	push @ret, "<table>";

	$sth = $dbh->prepare("select firstname, lastname, street, city, state, zip, homephone, workphone, faxphone, email, url, type, special, note, boatname, sailnumber, hullnumber from oldperson order by lastname, firstname") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;
	while ( my ( $firstname, $lastname, $street, $city, $state, $zip, $homephone, $workphone, $faxphone, $email, $url, $type, $special, $note, $boatname, $sailnumber, $hullnumber ) = $sth->fetchrow )
	{
		my $catname = $firstname . $lastname;
		$catname =~ s/ //g;
		$catname =~ s/\&//g;
		my $search = $lastname;
		if ( $type eq "Owner" && $hullnumber ) { $search .= " $hullnumber"; }
		if ( $type eq "Owner" && $sailnumber ) { $search .= " $sailnumber"; }
		if ( $type eq "Owner" && $boatname ) { $search .= " $boatname"; }
		$search =~ s/\s+/\+/g;
		my $ad2 = $street;
		$ad2 =~ s/ /\+/g;
                $ad2 =~ s/\#\d+//g;
		my $ad3 = $city . '%2C ' . $state . ' ' . $zip;
		$ad3 =~ s/ /\+/g;
		$url =~ s/http:\/\///;


		push @ret,
			"<tr><td>",
			"<a name=$catname>",
			( $special ? "<b>$special</b><br>" : "" ),
			"<i>$lastname, $firstname</i>",
			( $type ne "Other" ? "<br>$type" : "" ),
			( $type eq "Owner" && $hullnumber ? " #$hullnumber" : "" ),
			( $sailnumber && $sailnumber ne $hullnumber ? " (sail #$sailnumber)" : "" ),
			"<br>",
			( $type eq "Owner" && $boatname ? "$boatname<br>" : "" ),
			"<a href=/photos/?search=$search>find photos</a><br>",
			( $email ? "<a href=\"mailto:$email\">$email</a><br>" : "" ),
			# "<a target=other href='http://maps.yahoo.com/py/maps.py?BFCat=&Pyt=Tmap&newFL=Use+Address+Below&addr=$ad2&csz=$ad3&Country=us&Get%A0Map=Get+Map'>$street</a><br>",
 			"<a target=other href='http://maps.google.com/?q=$ad2+$ad3'>$street</a><br>",
			"$city, $state $zip<br>",
			( $homephone ? "(H) $homephone<br>" : "" ),
			( $workphone ? "(W) $workphone<br>" : "" ),
			( $faxphone ? "(F) $faxphone<br>" : "" ),
			( $url ? "<a href=\"http://$url\">$url</a><br>" : "" ),
			"<br>",
			"<td>",
			( $note ? "$note" : "" );
	}

	push @ret, "</table>";

	push @ret, '</body>', $q->end_html;

	return @ret;
}
