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

print display_page( new CGI() );

sub display_page
{
	my ( $q ) = @_;

	my @ret;

    my $dbh = Myfleet::DB::connect();


	my %vars = $q->Vars();

	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} Administration");

	while (my($key,$val)=each(%vars))
	{
		# push @ret, "$key=$val<br/>";

		if ($val == 'on' && $key =~ /^deleteMsg(\d+)/)
		{
			if (Myfleet::MessageBoard::delete_msg($dbh,$1,$config{'deletePassword'}))
			{
				push @ret, "Deleted message #$1<br/>";
			}
		}
	}


	# update all threads to proper modification date
	my $sth = $dbh->prepare("select thread_id, max(insert_date) from msg where deleted = 0 group by 1") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;
	my $sti = $dbh->prepare("update thread set modification_date = ? where thread_id = ?") || die $DBI::errstr;
	while( my ( $thread_id, $date ) = $sth->fetchrow_array ) {
		$sti->execute($date,$thread_id) || die $DBI::errstr;
		# push @ret, "$thread_id, $date<br/>";
	}

	my $sth = $dbh->prepare("select msg.msg_id, msg.thread_id, msg.password, txt.txt from msg join txt ON ( msg.txt_id = txt.txt_id ) where msg.insert_date > DATE_SUB(now(),INTERVAL 365 DAY) AND deleted=0 ORDER BY msg.insert_date DESC") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;

	push @ret,
		$q->start_form(-method=>'post'),
		'<table border="1" cellpadding="4" cellspacing="0"><tr><th>delete</th><th>msg_id</th><th>txt</th></tr>';

	while ( my ($msg_id,$thread_id,$password,$txt) = $sth->fetchrow_array())
	{
		push @ret, "<tr><td>", $q->checkbox(-name=>"deleteMsg$msg_id", -label=>'') ,"</td><td>$msg_id</td><td>$txt</td></tr>";
	}

	push @ret,
		$q->end_form,
		'</table>',
		'<br/>',
		$q->submit(-value=>'Delete Checked Messages'),
		'<br/><br/><br/>';

	push @ret,
		Myfleet::Header::display_footer();

	return @ret;
}
