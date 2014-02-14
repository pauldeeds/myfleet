#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;

print display_page( new CGI() );

sub display_page
{	
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} HTML Editor");

	my @message; 
	if ( $q->param('Save Changes') )
	{
		my $dbh = Myfleet::DB::connect();
		my $sth = $dbh->prepare("replace into html (html,title,uniquename) values (?,?,?)") || die $DBI::errstr;
		$sth->execute( $q->param('html'), $q->param('title'), $q->param('u') ) || die $DBI::errstr;
		push @message, "Saved '", $q->param('u'), "'. <a href=\"?u=", $q->param('u'), "\">EDIT AGAIN</a>";
		$q->param('u','');
	}
	elsif( $q->param('delete') )
	{
		my $dbh = Myfleet::DB::connect();
		my $sth = $dbh->prepare("delete from html where uniquename = ?") || die $DBI::errstr;
		$sth->execute( $q->param('delete') ) || die $DBI::errstr;
		push @message, "Deleted '", $q->param('delete'), "'.";
	}

	if( scalar(@message) )
	{
		push @ret,
			'<font color="red">', @message, '</font><br/><br/>';
	}

	if ( $q->param('u') )
	{
		my $html;
		my $title;

		( $html, $title ) = Myfleet::Util::html( $q->param('u') );
		if( $title ne 'Not found' )
		{
			$q->param('html', $html );
			$q->param('title', $title );
		}

		push @ret,
			'<a href=".">View All Pages</a><br/><br/>',
			'<form action="" method="post">',
			"<b>Key:</b><br/>", $q->textfield(-name=>'u', -size=>20), "<br/>",
			"<b>Title:</b><br/>", $q->textfield(-name=>'title', -size=>60), "<br/>",
			"<b>Html:</b><br/>", $q->textarea(-name=>'html', -rows=>30, -style=>'width:90%' ),
			"<br/>",
			$q->submit(-name=>'Save Changes'),
			# $q->submit(-name=>'Add As New'),
			"</form>";
	}
	else
	{
		my $dbh = Myfleet::DB::connect();
		my $sth = $dbh->prepare("select html, title, uniquename, date_format(lastupdate,'%b %e %l %i %p') as lastupdate from html order by lastupdate") || die $DBI::errstr;
		$sth->execute || die $DBI::errstr;

		push @ret, 
			'<form action="" method="get">',
				'Key: <input type="text" name="u"/>',
				'<input type="submit" value="Add New Page"/>',
			'</form>';

		push @ret,
			'<table cellpadding="2" cellspacing="0" border="1">',
				'<tr>',
					'<td><b>Key</b></td>',
					'<td><b>Title</b></td>',
					'<td><b>Last Updated</b></td>',
					'<td><b>Actions</b></td>',
				'</tr>';

		while ( my $h = $sth->fetchrow_hashref )
		{
			push @ret,
				'<tr>',
					"<td>$h->{uniquename}</td>",
					"<td>$h->{title}</td>",
					"<td>$h->{lastupdate}</td>",
					"<td>",
						"<a href=\"/articles/$h->{uniquename}\">View</a> ",
						"<a href=\"?u=$h->{uniquename}\">Edit</a> ",
						"<a href=\"?delete=$h->{uniquename}\" onclick=\"return confirm('Are you sure you want to delete $h->{uniquename} ?')\">Delete</a>",
					"</td>";
		}

		push @ret,
			'</table>';

		push @ret,
			'<h2>Interior Page Keys</h2>',
			'<p>When defined the following will be displayed in spots on the interior of programatic pages.</p>',
			'<h3>Homepage</h3>',
				'<ul>',
					'<li><a href="?u=homepage_top">homepage_top</a></li>',
					'<li><a href="?u=homepage_aftermsg">homepage_aftermsg</a></li>',
					'<li><a href="?u=homepage_bottom">homepage_bottom</a></li>',
				'</ul>',
			'<h3>Dues</h3>',
				'<ul>',
					'<li><a href="?u=dues">dues</a></li>',
				'</ul>',
			'<h3>Crewlist</h3>',
				'<ul>',
					'<li><a href="?u=crewlist">crewlist</a></li>',
				'</ul>',
			'<h3>Roster</h3>',
				'<ul>',
					'<li><a href="?u=roster">roster</a></li>',
				'</ul>',
			'<h3>Regatta</h3>',
				'<ul>',
					'<li><a href="?u=sponsorHtml">sponsorHtml</a> (only if series has sponsor configured)</li>',
				'</ul>';
				
	}

	return @ret;
}
