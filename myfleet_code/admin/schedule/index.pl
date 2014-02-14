#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;
use Myfleet::Regatta;
use Myfleet::MessageBoard;
use Data::Dumper;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;


	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} Schedule Editor");

	my $dbh = Myfleet::DB::connect();

	# push @ret, "<pre>", Dumper( $q ), "</pre>";
	my @warning;
	my @message;

	if ( $q->param('r') && ( $q->param('Save') eq 'Save Changes' || 
		$q->param('Add') eq 'Add As New Regatta' ) )
	{
		if ( $q->param('startdate') !~ /\d\d\d\d-\d\d-\d\d/ ) {
			push @warning, "Invalid Start Date";
		}
		if ( $q->param('enddate') ne '' and $q->param('enddate') !~ /\d\d\d\d-\d\d-\d\d/ ) {
			push @warning, "Invalid End Date";
		}

		if( $q->param('newvenue') )
		{
			my $sti = $dbh->prepare("insert into venue ( name ) values ( ? )") || die $DBI::errstr;
			$sti->execute( $q->param('newvenue') ) || die $DBI::errstr;
			$q->param('venue',$dbh->{mysql_insertid});
		}

		my %series;
		foreach my $s ( 'series1', 'series2', 'series3', 'series4', 'series5' ) {
			$series{$s} = 0;
		}
		foreach my $s ( $q->param('series') ) {
			$series{$s} = 1;
		}

		if ( @warning == 0 ) {
			if ( $q->param('Add') eq 'Add As New Regatta' ) {
				my $sti = $dbh->prepare("insert into regatta ( name, startdate, enddate, venue, contact, series1, series2, series3, series4, series5, url, result, description, story ) values ( ?,?,?,?,?, ?,?,?,?,?, ?,?,?,?  )") || die $DBI::errstr;
				$sti->execute(
					$q->param('name'),
					$q->param('startdate'),
					( $q->param('enddate') eq '' ? undef : $q->param('enddate')),
					$q->param('venue'),
					$q->param('contact'),
					$series{'series1'},
					$series{'series2'},
					$series{'series3'},
					$series{'series4'},
					$series{'series5'},
					$q->param('url'),
					( $q->param('result') eq '' ? undef : $q->param('result') ),
					( $q->param('description') eq '' ? undef : $q->param('description') ),
					( $q->param('story') eq '' ? undef : $q->param('story') )
				) || die "Error adding regatta: $DBI::errstr";
				push @message, "Regattas has been added.";

			}
			else
			{
				my $stu = $dbh->prepare("update regatta set name = ?, startdate = ?, enddate = ?, venue = ?, contact = ?, series1 = ?, series2 = ?, series3 = ?, series4 = ?, series5 = ?, url = ?, result = ?, description = ?, story = ? where id = ?") || die $DBI::errstr;

				$stu->execute(
					$q->param('name'),
					$q->param('startdate'),
					( $q->param('enddate') eq '' ? undef : $q->param('enddate')),
					$q->param('venue'),
					$q->param('contact'),
					$series{'series1'},
					$series{'series2'},
					$series{'series3'},
					$series{'series4'},
					$series{'series5'},
					$q->param('url'),
					( $q->param('result') eq '' ? undef : $q->param('result') ),
					( $q->param('description') eq '' ? undef : $q->param('description') ),
					( $q->param('story') eq '' ? undef : $q->param('story') ),
					$q->param('r')
				) || die "Error updating regatta: $DBI::errstr " . Dumper( $q );

				push @message, "Regattas has been updated.";
			}
		}
	}

	if ( $q->param('r') && $q->param('Delete') eq 'Delete this Regatta' )
	{
		my $sti = $dbh->prepare("delete from regatta where id = ?") || die $DBI::errstr;
		$sti->execute($q->param('r')) || die $DBI::errstr;
		if( $sti->rows > 0 )
		{
			push @message, "Regattas has been deleted.";
		}
		$q->param('r','');
	}

	if ( @warning ) {
		push @ret, '<big><b><font color=\"red\">Your changes were not saved:</font></big></b>';
		push @ret, '<ul>';
		foreach my $warn ( @warning ) 
		{
			push @ret, "<li>$warn</li>";
		}
		push @ret, '</ul>';
	}

	if ( @message )
	{
		push @ret, '<ul>';
		foreach my $msg ( @message ) 
		{
			push @ret, "<li>$msg</li>";
		}
		push @ret, '</ul>';
	}

	if ( $q->param('r') )
	{
		if( $q->param('r') eq 'new' ) {
			push @ret,
				'<a href=".">&laquo; Back to regatta list</a><br/>',
				'<h3>Add Event</h3>';
		} else {
			push @ret,
					'<a href=".">&laquo; Back to regatta list</a><br/>', # or <a href="?r=new">Add new event</a><br/>',
					'<h3>Edit Event</h3>';
		}
		
		# '(<a href="?r=new">Add new regatta</a>)';

		# push @ret, "<a href=../?r=", $q->param('r'), ">View this regatta page</a>";
		my $sth = $dbh->prepare("select id, name from venue order by name") || die $DBI::errstr;
		$sth->execute;
		my %venue_hash;
		my @venue_list;
		while( my ( $venue_id, $venue_name ) = $sth->fetchrow_array ) {
			push @venue_list, $venue_id;
			$venue_hash{$venue_id} = $venue_name;
		}

		my %person_hash;
		my @person_list;
		push @person_list, -1;
		$person_hash{-1} = 'No Contact Person';
		$sth = $dbh->prepare("select id, firstname, lastname from person order by lastname, firstname") || die $DBI::errstr;
		$sth->execute || die $DBI::errstr;
		while ( my ( $person_id, $person_firstname, $person_lastname ) = $sth->fetchrow_array ) {
			push @person_list, $person_id;
			$person_hash{$person_id} = "$person_lastname, $person_firstname";
		}

		$sth = $dbh->prepare("select id, startdate, enddate, lastupdate, name, venue, contact, series1, series2, series3, series4, series5, url, result, description, story from regatta where id = ?") || die $DBI::errstr;
		$sth->execute( $q->param('r') ) || die $DBI::errstr;
		my $regatta = $sth->fetchrow_hashref;


		my $saveButtons = join('',
			( $q->param('r') ne 'new' ?
				$q->submit( -name=>'Save', -value=>'Save Changes' ) : '' ),
			$q->submit( -name=>'Add', -value=>'Add As New Regatta' ),
			( $q->param('r') ne 'new' ?
				$q->submit( -name=>'Delete', -value=>'Delete this Regatta' ) : '' ),
		);

		my @series_values;
		my %series_labels;
		my @series_selected;
		foreach my $series ( @{$config{'series'}} )
		{
			push @series_values, $series->{'dbname'};
			$series_labels{$series->{'dbname'}} = $series->{'name'};
			if( $regatta->{$series->{'dbname'}} ) {
				push @series_selected, $series->{'dbname'};
			}
		}
		$q->param(-name=>'series', -values=>\@series_selected );

		push @ret,
			"<form method=post>",
			$q->hidden( -name=>'r'),
			"<table>",
				"<tr><td>Name:<td>", $q->textfield( -name=>'name', -value=>$regatta->{name}, -size=>64 ),
				"<tr><td>Start Date:<td>", $q->textfield( -name=>'startdate', -value=>$regatta->{startdate}, -size=>10 ), ' (ie: 2006-01-09)',
				"<tr><td>End Date:<td>", $q->textfield( -name=>'enddate', -value=>$regatta->{enddate}, -size=>10 ), " (Leave blank for single day events)",
				"<tr><td>Venue:<td>",
					$q->scrolling_list(
						-name=>'venue',
						-values=>\@venue_list,
						-size=>1,
						-labels=>\%venue_hash,
						-default=>$regatta->{venue} ),
					' or new venue: ',	$q->textfield(-name=>'newvenue', -size=>20),
				"<tr><td>Contact:<td>",
					$q->scrolling_list(
						-name=>'contact',
						-values=>\@person_list,
						-size=>1,
						-labels=>\%person_hash,
						-default=>$regatta->{contact} ),
						' (must be on roster)',
				"<tr><td>Series:<td>",
					$q->checkbox_group( -name=>'series', -values=>\@series_values, -labels=>\%series_labels ),
				"<tr><td>URL:<td>",
					$q->textfield( -name=>'url', -value=>$regatta->{url}, -size=>64 ),
				"<tr><td valign=top>Result:<td>",
					$q->textarea( -name=>'result', -value=>$regatta->{result}, -cols=>80, -rows=>15 ),
					'<br/><small><i>',
						'each line: [place],[boat name],[optional owner name],[total points],[race 1],[race 2], ...<br/>',
						'DNS - did not start, OCS - over early,  DNF - did not finish, RAF or RET - retired after finishing, DSQ - disqualified, RDG - redress for series<br/>',
						'You can optionally wrap throwouts in parentheses or brackets (e.g. (9) or [9])',
					'</i></small>',
				"<tr><td valign=top>Story:<br/><small>(optional<br/> html ok)<td>",
					$q->textarea( -name=>'story', -value=>$regatta->{story}, -cols=>80, -rows=>10 ),
				"<tr><td valign=top>Description:<br/><small>(optional<br/>html ok)<td>",
					$q->textarea( -name=>'description', -value=>$regatta->{description}, -cols=>80, -rows=>10 ),
			"</table>",
			$saveButtons,
			"</form>";
	}
	else
	{
		# event listing
		my $sth = $dbh->prepare("select distinct year(startdate) year from regatta order by year desc") || die $DBI::errstr;
		$sth->execute();
		my @years;
		while( my ( $y ) = $sth->fetchrow_array ) {
			push @years, $y;
		}

		if( scalar(@years) > 0 )
		{
			my $year = $q->param('y') || $years[0];

			push @ret,
				'<a href="?r=new" style="font-size:1.5em;">Add new event</a><br/><br/>',
				'<table border="0" cellpadding="4" cellspacing="0" width="100%"><tr bgcolor="silver"><td><big><b>'.$year.' Events';
			if ( scalar( @years ) > 1 ) {
				push @ret, "<td align=right>Years: ";
				foreach my $yr ( @years ) {
					if ( $yr ne $year ) {
						push @ret, "<a href=?y=$yr>$yr</a> ";
					} else {
						push @ret, "<b>$yr</b> ";
					}
				}
			}
			push @ret,
				"</table><br>",
				Myfleet::Regatta::display_events( $year, 'Edit' );
		} else {
			push @ret,
				'<a href="?r=new">Add new regatta</a>',
				"<br/><b>You have no events.</b>";
		}
	}

	return @ret;
}
