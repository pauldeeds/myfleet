#!/usr/local/bin/perl

use strict;
use diagnostics;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MyfleetConfig qw(%config);
use Myfleet::Header;

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;
	
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} Administration"),
		"<h2>Working</h2>",
		"<ul>",
			"<li><a href=\"html/\">Edit HTML Pages</a></li>",
			"<li><a href=\"schedule/\">Edit Schedule</a></li>",
			"<li><a href=\"roster/\">Edit Roster</a></li>",
			"<li><a href=\"crew/\">Edit Crew List</a></li>",
			"<li><a href=\"dues/\">Edit Dues</a></li>",
			( $config{'mailingList'} ? 
				"<li><a href=\"http://myfleet.org/mailman/admin/$config{'mailingList'}\">Edit Mailing List</a></li>" : '' ),
			"<li><a href=\"photo/\">Edit Photos</a></li>",
			"<li><a href=\"config/\">View Configuration Settings</a></li>",
			"<li><a href=\"/msgs/\">Edit Messages</a> (just use 'deletePassword' from config to delete messages)</li>",
			"<li><a href=\"msgs/\">Deal with spam on message boards</a></li>",
		"</ul>",
		Myfleet::Header::display_footer();

	return @ret;
}
