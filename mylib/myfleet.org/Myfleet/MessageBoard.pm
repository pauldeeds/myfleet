use CGI;
# use CGI::Carp qw(fatalsToBrowser);
use DBD::mysql;
use Apache::Session::Generate::MD5;
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Regatta;
use Myfleet::Google;
use Myfleet::GPS;
use XML::RSS;
use Data::Dumper;
use Authen::Captcha;
use File::Path;

package Myfleet::MessageBoard;

use MyfleetConfig qw(%config);
use Text::Wrap qw($huge);
$huge = 'overflow'; # causes long words to overflow rather than wrap (for urls)

sub display_page
{
	my ( $q ) = @_;

	my %p = $q->Vars;
	my %c;


	my @ret = ();
	my @crumbs = ();
	my @alerts = ();
	my @output = ();
	my @bottom_output = ();
	my @cookies = ();

	my $cookie_domain = ".$config{'domain'}";

	foreach( 'boatname', 'sailnumber', 'skipper' ) {
		if ( $q->param($_) ) {
			push @cookies, $q->cookie( -name=>$_, -domain=>$cookie_domain, -value=>$q->param($_), -expires=>'+1y' );
		}
	}
	foreach( 'name', 'email', 'lastdate', 'thisdate', 'session', 'boatname', 'sailnumber', 'skipper' ) {
		if ( $q->cookie($_) ) {
			$c{$_} = $q->cookie($_);
			# warn "in cookie: $_ = $c{$_}";
		}
	}
	if ( ! defined $c{'lastdate'} ) {
		$c{'lastdate'} = 0;
	}

	if ( ! $c{'session'} ) {
		$c{'session'} = Apache::Session::Generate::MD5::generate();
		push @cookies,
			$q->cookie(-name=>'session', -domain=>$cookie_domain, -value=>$c{'session'}, -expires=>'+3y');
	}

	if ( $p{'r'} ) { $p{'f'} = $p{'r'} + 1000; }
	# if ( $p{'f'} > 1000 ) { $p{'r'} = $p{'f'} - 1000; }

	my $dbh = Myfleet::DB::connect() || die "Couldn't connect to database: $DBI::errstr.";

	# reset last visit date if it was more than 2 hrs
	my $stz = $dbh->prepare("select unix_timestamp(now())") || die $DBI::errstr;
	$stz->execute() || die $DBI::errstr;
	my ( $now ) = $stz->fetchrow_array();
	if ( defined $c{'thisdate'} && ( $now - $c{'thisdate'} ) > 3600 ) {
		# warn "updating cookie: $c{'thisdate'} : $now : $c{'lastdate'}";
		push @cookies, 
			$q->cookie(-name=>'lastdate', -domain=>$cookie_domain, -value=>$c{'thisdate'}, -expires=>'+3y' );
		$c{'lastdate'} = $c{'thisdate'};
		push @cookies,
			$q->cookie(-name=>'thisdate', -domain=>$cookie_domain, -value=>$now, -expires=>'+3y');
		$c{'thisdate'} = $now;
	}

	if ( ! defined $c{'thisdate'} ) {
		push @cookies,
			$q->cookie(-name=>'thisdate', -domain=>$cookie_domain, -value=>$now, -expires=>'+3y');
		$c{'thisdate'} = $now;
	}

	# warn @cookies;

	my $forum_id = $p{'f'};
	my $forum_name = "";
	my $msg_id = $p{'m'} || 0;
	my $msg = msg( $dbh, $msg_id );

	my $page_title = $config{'defaultTitle'};

	push @crumbs, "<a href=\"/msgs/\">Forums</a>";
	if ( $forum_id ) {
		$forum_name = forum_name( $dbh, $forum_id );
		push @crumbs, "<a href=\"?f=$forum_id\">$forum_name</a>";
		# $page_title .= " :: $forum_name";
		$page_title = "$forum_name";
	}

	my $output_folder = $ENV{'DOCUMENT_ROOT'} . '/captcha/';
	my $data_folder = $ENV{'DOCUMENT_ROOT'} . '../captcha/' . $ENV{'SERVER_NAME'};
	if( ! -e $data_folder ) { File::Path::mkpath($data_folder); }
	my $captcha = Authen::Captcha->new();
	my $md5sum;
	if( defined $p{'pm'} || defined $p{'p'} )
	{
		$captcha->data_folder( $data_folder );
		$captcha->output_folder( $output_folder );
		$md5sum = $captcha->generate_code(4);
	}

	if ( defined $p{'pm'} && ( $p{'pm'} eq 'Post Message' || $p{'pm'} eq 'Preview' ) )
	{
		$p{'email'} = strip_html( $p{'email'} );
		$p{'title'} = strip_html( $p{'title'} );
		$p{'name'} = strip_html( $p{'name'} );
		$p{'msg'} = strip_html( $p{'msg'} );

		# prevent spam
		if( $p{'name'} eq 'keiresing' ||
			$p{'name'} eq 'powderbondchemical' ||
			$p{'msg'} =~ /tipcell/i  ||
			$p{'title'} =~ /tipcell/i || 
			$p{'msg'} =~ /powderbond/i ||
			$p{'msg'} =~ /benwis/i ||
			$p{'msg'} =~ /oemresources/i ||
			$p{'msg'} =~ /ruiyu/i )
		{
			push @alerts, 'Please stop spamming our message boards.  Links in messages are all NO FOLLOW.';
		} 

		if( $p{'pm'} eq 'Post Message' )
		{
			if( ! $q->param('md5') || ! $q->param('code') )
			{
				push @alerts, "Please enter the distorted text in order to post your message.";
			}
			elsif( $captcha->check_code($q->param('code'),$q->param('md5')) != 1 )
			{
				push @alerts, "Your text did not match the distorted text, please try again.";
				$q->param('md5',$md5sum); $q->param('code','');
			}
		}

		if( $p{'email'} ne '' && $p{'email'} !~ /^([a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-])+/ ) {
			push @alerts, "The email address you entered appears invalid.";
		}

		if ( $p{'title'} =~ /^\s*$/ ) {
			push @alerts, "You must enter a subject";
		}
	
		if ( $p{'name'} =~ /^\s*$/ ) {
			push @alerts, "You must enter a name";
		}
		$page_title .= " :: Post Message";
	}
	
	if ( defined $p{'pm'} && $p{'pm'} eq 'Post Message' )
	{
		if ( @alerts ) {
			$p{'pm'} = 'Error'; # don't post message
			push @alerts, "Message not posted due to errors.";
			$page_title .= " :: Post Message Error";
		}
		else
		{
			$msg_id = insert_msg( $dbh, $forum_id, $p{'name'}, $p{'email'}, $p{'title'}, $p{'msg'}, $p{'replyto'}, $p{'t'}, $p{'password'}, $c{'session'} );
			push @alerts, "Message posted (please do not reload this page).";
			if ( defined $c{'email'} && defined $p{'email'} && $c{'email'} ne $p{'email'} ) {
				$c{'email'} = $p{'email'};
				push @cookies,
					$q->cookie(-name=>'email', -domain=>$cookie_domain -value=>$c{'email'}, -expires=>'+3y');
			}
			if ( defined $c{'name'} && defined $p{'name'} &&  $c{'name'} ne $p{'name'} ) {
				$c{'name'} = $p{'name'};
				push @cookies,
					$q->cookie(-name=>'name', -domain=>$cookie_domain, -value=>$c{'name'}, -expires=>'+3y');
			}
			$msg = msg( $dbh, $msg_id );
			$page_title .= " :: Message Posted";

			# if message is posted we do a quick redirect to prevent double postings (by clicking reload)
			return
				join('',
					$q->header,
					$q->start_html,
					'<head>',
						"<meta http-equiv=\"refresh\" content=\"2;URL=?f=$forum_id\" />",
					'</head>',
					'<body>',
						'<h1>Your message has been posted</h1>',
						"<p>Click here to <a href=\"?f=$forum_id\">continue</a>, if you are not redirected automatically</p>",
					'</body>',
					$q->end_html
				);
		}
	}

	if ( defined $p{'pm'} && ( $p{'pm'} eq 'Preview' || $p{'pm'} eq 'Error' ) )
	{
		if ( $p{'pm'} eq 'Preview' ) {
			push @alerts, "This is a preview.  Message has not been posted.";
		}

		my $obscuredEmail = Myfleet::Util::obscureEmail( $p{'email'} );

		push @output,
			"<table width=100% bgcolor=#efefd1><tr><td>",
			"<i>Author:</i> $p{'name'} ", ( $p{'email'} ? "($obscuredEmail)" : ''), "<br/>",
			"<i>Subject:</i> $p{'title'}<br/>",
			"</table>",
			"<br/>",
			html_msg( format_text( $p{'msg'} ) ),
			"<br/>",
			"<hr/>";
		$p{'p'} = 'post';
		$page_title .= " :: Message Post Preview";
	}

	if ( defined $p{'p'} and $p{'p'} eq 'new' ) {
		push @crumbs, "Post New Message";
		$page_title .= " :: Post New Message";
	} elsif ( defined $p{'p'} && $p{'p'} eq 'reply' ) {
		push @crumbs, "Reply To Message";
		$q->param(-name=>'title',value=>"$msg->{title}");
		$q->param(-name=>'msg',value=>"\n\r\n\r" . quote_text( $msg->{txt} ) );
		$q->param(-name=>'replyto',value=>$msg->{msg_id});
		$q->param(-name=>'t',value=>$msg->{thread_id});
		$page_title .= " :: Reply to Message '$msg->{title}'";
	}

	if ( defined $p{'delete'} )
	{
		if( defined $p{'delete_password'} && $p{'delete_password'} )
		{
			if( delete_msg( $dbh, $msg_id, $p{'delete_password'} ) )
			{
				return
					join('',
						$q->header,
						$q->start_html,
						'<head>',
							"<meta http-equiv=\"refresh\" content=\"2;URL=?f=$forum_id\" />",
						'</head>',
						'<body>',
							'<h1>The message has been deleted</h1>',
							"<p>Click here to <a href=\"?f=$forum_id\">continue</a>, if you are not redirected automatically</p>",
						'</body>',
						$q->end_html
				);
			}
			else
			{
				push @alerts, "Error deleting message, password probably incorrect.";
			}
		}

		push @output, 
			'<div style="border:2px solid #f00; padding:0.5em; margin:0.5em;">',
			"<form method=\"post\" enctype=\"application/x-www-form-urlencoded\">",
				'<b>Enter password to delete this message:</b> ',
					$q->textfield(-name=>'delete_password', -size=>20 ),
					' ',
					$q->hidden('delete'),
					$q->hidden('f'),
					$q->hidden('m'),
					$q->submit(-name=>'Delete Message'),
			"</form>",
			'</div>';
	}

	if ( $p{'t'} && $msg_id ) {
		my $sth = $dbh->prepare("select forum_id from thread where thread_id = ?") || die $DBI::errstr;
		$sth->execute( $p{'t'} ) || die $DBI::errstr;
		$sth->rows || die "Thread $p{'t'} not found.";
		( $forum_id ) = $sth->fetchrow_array();
		
		# push @output, display_thread( $dbh, $p{'t'}, $forum_id, $msg_id, $c{'lastdate'} );
	}

	if ( $msg->{msg_id} && $forum_id )
	{
		if ( $p{'rate'} ) {
			rate_msg( $dbh, $msg, $forum_id, $p{'rate'} );
			if ( $p{'rate'} eq 'good' ) {
				push @alerts, "You rated this message good.";
			} elsif ( $p{'rate'} eq 'bad' ) {
				push @alerts, "Thank you for reporting spam."; # "You rated this message bad.";
			}
		}

		if ( defined $p{'p'} && $p{'p'} eq 'reply' ) {
			push @output, "<big>Replying to this message</big>";
		}

		push @output, display_msg_options( $msg, $forum_id );
		push @output, display_msg( $dbh, $msg );
		if ( ! $p{'p'} ) {
			push @output, display_msg_options( $msg, $forum_id );
			push @output,
				'<table width="100%">',
					'<tr>',
						( $p{'f'} < 1000 || Myfleet::Regatta::regatta_has_results( $p{'r'} ) ?
		
						 	'<td width="120" valign="top">' .
						 		Myfleet::Google::google_ad( -size=>'120x240' ) .
						'</td>' : '' ),
						'<td valign="top">',
							display_thread( $dbh, $msg->{'thread_id'}, $forum_id, $msg->{'msg_id'}, $c{'lastdate'} ),
							# Myfleet::Google::google_ad( -size=>'468x60' ),
						'</td>',
					'</tr>',
				'</table>';
		}
		if ( defined $p{'p'} && $p{'p'} eq 'reply' ) {
			push @output, display_msg_options( $msg, $forum_id ), "<br/>";
		}
		$page_title = "$msg->{'title'}";
	}

	if ( $p{'p'} && $forum_id )
	{

		if ( ! defined $p{'email'} && $c{'email'} ) {
			$q->param(-name=>'email', value=>$c{'email'} );
		}
		if ( ! defined $p{'name'} && $c{'name'} ) {
			$q->param(-name=>'name', value=>$c{'name'} );
		}

		my $request = Apache::Session::Generate::MD5::generate();
		my $cols = 70;
		if ( $p{'f'} > 1000 ) { $cols = 50; }
		push @output,
			'<a name="reply">';
	
		if ( $p{'f'} < 1000 ) {
			push @output,
			"<ul>",
			"<li>HTML will be stripped from message.</li>",
			"<li>A URL will be activated if it begins with http:// or https://</li>",
			"<li>Text will be formatted as paragraphs, unless the line begins with a '-'</li>",
			"<li>You can preview your message to see how it will appear.</li>",
			"</ul>";
		}

		$abortUrl = "?f=$forum_id" . ( defined $msg->{msg_id} ? "&m=$msg->{msg_id}" : '' );
		push @output,
			"<form method=\"post\" action=\"?$request#Message\" enctype=\"application/x-www-form-urlencoded\">\n",
			# $q->start_form(-method=>'post', -action=>"/msgs/"),
			$q->textfield(-name=>'name', -size=>30, -style=>'margin-right:0.2em;'), " <b>Your Name</b><br/>",
			$q->textfield(-name=>'email', -size=>30, -style=>'margin-right:0.2em;'), " <b>Your E-Mail (optional)</b><br/>",
			$q->textfield(-name=>'title', -size=>30, -style=>'margin-right:0.2em;'), " <b>Subject</b><br/>",
			$q->textfield(-name=>'password', -size=>15, -style=>'margin-right:0.2em;'), " <b>Password</b> <small>(optional - allows you to delete later)</small><br/>",
			$q->textarea(-name=>'msg', -rows=>18, cols=>$cols, -style=>'margin-right:0.2em;'), "<br/>", 
			$q->hidden(-name=>'t'),
			$q->hidden(-name=>'f'),
			$q->hidden(-name=>'replyto'),
			$q->hidden(-name=>'md5', -value=>$md5sum),
			'<br/>',
			"<img src=\"/captcha/$md5sum.png\" style=\"width:100px; height:35px; float:left;\" /> ",
			'<div style="height:35px; padding-left:10px;"><input name="code" size="4" style="vertical-align:middle; height:35px; font-size:25px; padding:0px; 5px;" /> <b>Enter Distorted Text to Post</b></div>',
			'<br/>',
			$q->submit(-value=>'Post Message', -name=>'pm'),
			' ',
			$q->submit(-value=>'Preview', -name=>'pm'),
			' ',
			"<input type=\"button\" value=\"Cancel\" onClick=\"location.href='$abortUrl';\">",
		"</form>\n";
	}

	if( $p{'e'} || $p{'s'} || $p{'n'} || ( $forum_id && $forum_id < 1000 && ! $p{'m'} && ! $p{'p'} ) )
	{
		push @output,
			$q->start_form(-method=>'get'),
			$q->textfield(-name=>'s', -size=>25 ),
			'<input type="submit" value="Search Messages">',
		        $q->end_form;
	}

	if ( $forum_id && ! $msg->{msg_id} && ! $p{'p'} ) {
		if( $forum_id < 1000 )
		{
			push @output, 
				'<div id="msgs" style="float:left; min-width:400px;">',
					display_forum_msgs( $dbh, $forum_id, 0, $c{'lastdate'}, "0,11" ),
				'</div>',
				'<div id="ad" style="float:left; width:160px; margin-left:1em;">',
				 	Myfleet::Google::google_ad( -size=>'160x600' ),
				'</div>',
				'<div id="msgs_bottom" style="float:left; clear:left">',
					display_forum_msgs( $dbh, $forum_id, 0, $c{'lastdate'}, "11,40" ),
				'</div>';
					
		}
		elsif ( Myfleet::Regatta::regatta_has_results( $p{'r'} ) )
		{
			push @output, 
				'<div id="msgs" style="float:left; min-width:300px">',
					display_forum_msgs( $dbh, $forum_id, 0, $c{'lastdate'}, "0,4" ),
				'</div>',
				'<div id="ad" style="float:left; width:120px; margin-left:1em;">',
				 	Myfleet::Google::google_ad( -size=>'120x240' ),
				'</div>',
				'<div id="msgs_bottom" style="float:left; clear:left">',
					display_forum_msgs( $dbh, $forum_id, 0, $c{'lastdate'}, "4,47" ),
				'</div>';
		}
		else
		{
			push @output, display_forum_msgs( $dbh, $forum_id, 0, $c{'lastdate'}, "0,5" );
			push @bottom_output, display_forum_msgs( $dbh, $forum_id, 0, $c{'lastdate'}, "5,45" );
		}
		$page_title .= " :: All Messages";
	}


	if ( $p{'e'} )
	{
		# display by email address
		my $sti = $dbh->prepare("select email from email where email_id = ?") || die $DBI::errstr;
		$sti->execute( $p{'e'} ) || die $DBI::errstr;
		$sti->rows || die "Address with email_id: $p{'e'} not found.";
		my ( $email ) = $sti->fetchrow_array();

		my $obscuredEmail = Myfleet::Util::obscureEmail( $email );
		push @output, "<big>All messages from $obscuredEmail</big><br/>";

		my $sth = $dbh->prepare(qq{
		select
			msg.msg_id,
			name,
			title,
			views,
			good,
			bad,
			thread_id,
			nomessage,
			date_format(insert_date,'%W %c-%e-%y %r')
		from
			msg,
			name,
			title
		where 
			email_id = ? and
			msg.deleted = 0 and
			msg.name_id = name.name_id and
			msg.title_id = title.title_id
			order by msg.insert_date DESC
		} ) || die $DBI::errstr;
			
		$sth->execute( $p{'e'} ) || die $DBI::errstr;
		if ( $sth->rows ) {
			while( my ( $msg_id, $name, $title, $views, $good, $bad, $thread_id, $nomessage, $date ) = $sth->fetchrow_array ) {
				push @output, "<li><a href=\"?t=$thread_id&m=$msg_id#Message\">$title</a>", ( $nomessage ? ' <font color=red>*NM*</font>' : '' ),
				# " <small>($views views - good: $good bad: $bad)</small>",
				" <small>($views views)</small>",
				" ~ <small><i>$date</i></small></li>";
			}
		} else {
			push @output, "No message found.";
		}
	}

	if ( $p{'n'} )
	{
		# display by name
		my $sti = $dbh->prepare("select name from name where name_id = ?") || die $DBI::errstr;
		$sti->execute( $p{'n'} ) || die $DBI::errstr;
		$sti->rows || die "Name with name_id: $p{'n'} not found.";
		my ( $name ) = $sti->fetchrow_array();
		push @output, "<big>All messages written by '$name'</big><br/>";

		my $sth = $dbh->prepare(qq{
		select
			msg.msg_id,
			title,
			views,
			good,
			bad,
			txt,
			thread_id,
			date_format(insert_date,'%W %c-%e-%y %r')
		from
			msg,
			title,
			txt
		where 
			name_id = ? and
			msg.deleted = 0 and
			msg.txt_id = txt.txt_id and
			msg.title_id = title.title_id
			order by msg.insert_date DESC
		} ) || die $DBI::errstr;
			
		$sth->execute( $p{'n'} ) || die $DBI::errstr;
		if ( $sth->rows ) {
			while( my ( $msg_id, $title, $views, $good, $bad, $txt, $thread_id, $date ) = $sth->fetchrow_array ) {
				push @output, "<li><a href=\"?t=$thread_id&m=$msg_id#Message\">$title</a>", ( $txt eq '' ? ' <font color=red>*NM*</font>' : '' ),
				" <small>($views views)</small>",
				" ~ <small><i>$date</i></small></li>";
			}
		} else {
			push @output, "No message found.";
		}
	}

	if ( $p{'s'} )
	{
		# display by search

		if( $p{'o'} eq 'date' )
		{
			$orderby = 'msg.insert_date DESC';
		} else { 
			$orderby = 'matchScore DESC';
		}

		my $sth = $dbh->prepare(qq{
		select
			msg.msg_id,
			name,
			title,
			views,
			good,
			bad,
			txt,
			thread_id,
			MATCH(title) AGAINST ( ? ) + MATCH(txt) AGAINST ( ? ) + 0.5 * MATCH(name) AGAINST ( ? ) as matchScore,
			date_format(insert_date,'%W %c-%e-%y %r')
		from
			msg,
			title,
			name,
			txt
		where 
			msg.deleted = 0 AND
			msg.name_id = name.name_id AND
			msg.txt_id = txt.txt_id AND
			msg.title_id = title.title_id AND
			(
				MATCH (title) AGAINST ( ? ) OR
				MATCH (txt) AGAINST ( ? ) OR
				MATCH (name) AGAINST ( ? )
			)
		order by
			$orderby
		limit
			200 
		} ) || die $DBI::errstr;
			
		if( $p{'o'} eq 'date' )
		{
			$sth->execute( $p{'s'}, $p{'s'}, $p{'s'}, $p{'s'}, $p{'s'}, $p{'s'} ) || die $DBI::errstr;
		} else {
			$sth->execute( $p{'s'}, $p{'s'}, $p{'s'}, $p{'s'}, $p{'s'}, $p{'s'} ) || die $DBI::errstr;
		}

		push @output,
			"<big>Search for '$p{'s'}'</big>";

		if ( $sth->rows )
		{
			my $rows = $sth->rows;
			if( $p{'o'} eq 'date' )
			{
				$url = $ENV{'REQUEST_URI'};
				$url =~ s/\&o=date//g;
				push @output, " - $rows found<br/>[ <a href=\"$url\">By Relevance</a> | By Date ]<br/>";
			} else { 
				push @output, " - $rows found<br/>[ By Relevance | <a href=\"$ENV{'REQUEST_URI'}&o=date\">By Date</a> ]<br/>";
			}

			while( my ( $msg_id, $name, $title, $views, $good, $bad, $txt, $thread_id, $matchScore, $date ) = $sth->fetchrow_array ) {
				push @output, "<li><a href=?t=$thread_id&m=$msg_id#Message>$title</a> ", ( $txt eq '' ? ' <font color=red>*NM*</font>' : '' ),
					" - <small>$name ~ <i>$date</i></small></li>";
			}
		} else {
			push @output, "<br/>No messages found.";
		}
	}

	if ( ! $p{'m'} && ! $p{'e'} && ! $p{'n'} && ! $p{'s'} && ! $forum_id )
	{
		pop @crumbs;
		push @crumbs, "Forums";
		push @output, display_forums( $dbh, $c{'lastdate'} );
	}

	push @ret,
		$q->header( -expires=>'now', -type=>'text/html', -cookie=>[@cookies]);

	# warn @cookies;
	
	my $display_ads = 0;
	my $finish_table = 0;

	if ( $p{'r'} )
	{
	    push @ret, Myfleet::Regatta::display_regatta_header( $q );

		if ( Myfleet::Regatta::regatta_has_results( $p{'r'} ) )
		{
			push @ret,
				Myfleet::Regatta::display_regatta( $q ),
				'<br/>',
				Myfleet::GPS::display_regatta_gps( $q, $p{'r'} ),
				'<br/>',
				'<a name="Message"></a>',
				'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
					'<tr>',
						'<td bgcolor="red">',
							'<big><font color="white">Regatta Message Board</font></big>',
						'</td>',
					'</tr>',
				'</table>',
				'<br/>';
		}
		else
		{
			push @ret,
				'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
					'<tr>',
						'<td width="40%" valign="top">', 
							Myfleet::Regatta::display_regatta( $q ),
						'</td>',
						'<td width="60%" valign="top">',
							'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
                      	  		'<tr>',
									'<td bgcolor="blue">',
										'<big><font color="white">Sign Up</font></big>',
									'</td>',
								'</tr>',
							'</table>',
							Myfleet::Regatta::display_regatta_form( $q ),
							Myfleet::GPS::display_regatta_gps( $q, $p{'r'} ),
							"<a name=\"Message\"></a>\n",
							'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
								'<tr>',
									'<td bgcolor="red">',
										'<big><font color="white">Regatta Message Board</font></big>',
									'</td>',
								'</tr>',
							'</table>';
			$finish_table = 1;
		}
	}
	else
	{
		my $menu;
		if ( $forum_id ) {
			if ( $forum_id eq "1" ) { $menu = "Messages"; }
			elsif ( $forum_id eq "2" ) { $menu = "For Sale"; }
			elsif ( $forum_id eq "3" ) { $menu = "Guestbook"; }
		}
		push @ret, Myfleet::Header::display_header( $menu, "..", $page_title );
		$display_ads = 1;
	}

	# push @ret, dump_info( $q );
	if( @alerts )
	{
		push @ret,
			'<div style="border:2px solid #f00; padding:0.5em; margin:0.5em;">',
				'<ul><li>',
					join('</li><li>', @alerts ),
				'</li></ul>',
			'</div>';
	}
	push @ret, @output;

#	if ( $p{'r'} ) {
#		push @ret, "</td></tr></table>";
#	}

	push @ret, @bottom_output;

	if ( $finish_table ) {
		push @ret, "</table>";
	}

	push @ret, Myfleet::Header::display_footer();
	
	return join('', @ret );
}

#sub display_rss
#{
#	my ( $dbh, $days ) = @_;
#	$days ||= 60;
#
#	my $sth = $dbh->prepare('select distinct forum_id from thread where modification_date > date_sub(now(), INTERVAL $days DAY)') || die "$DBI::errstr";
#	$sth->execute();
#
#	my $rss = new XML::RSS (version => '1.0');
#	while ( my ( $forum_id ) = $sth->fetchrow_array() )
#	{
#		# the forum information
#		my $forum_name = forum_name( $dbh, $forum_id );
#		my $forum_url = "http://$config{'domain'}/" . ( $forum_id < 1000  ? "msgs/?f=${forum_id}" : "schedule/?r=" . ( $forum_id - 1000 ));
#		$rss->channel(
#			title => "$config{'defaultTitle'}: ${forum_name}",
#			link => $forum_url,
#			description => "$config{'defaultTitle'}: ${forum_name}",
#			language => 'en-us',
#			taxo => ['http://dmoz.org/Recreation/Boating/Sailing/Classes/']
#		);
#
#		# the forum threads
#		my $sth = $dbh->prepare("select thread_id, first_msg, modification_date from thread where forum_id = ? and modification_date > date_sub(now(), INTERVAL $days DAY) order by modification_date DESC") || die $DBI::errstr;
#		$sth->execute( $forum_id ) || die $DBI::errstr;
#
#		while( my ( $thread_id, $first_msg, $modification_date ) = $sth->fetchrow_array )
#		{
#			my $sth = $dbh->prepare(qq{
#		select
#			name,
#			title,
#			views,
#			good,
#			bad,
#			nomessage,
#			date_format(insert_date,'%W %c-%e-%y %r'),
#			unix_timestamp(insert_date)
#		from
#			msg,
#			name,
#			title
#		where 
#			msg_id = ? and
#			msg.name_id = name.name_id and
#			msg.title_id = title.title_id 
#		} ) || die $DBI::errstr;
#	$sth->execute( $msg_id ) || die $DBI::errstr;
#	$sth->rows || die "Error message $msg_id not found.";
#	my ( $name, $title, $views, $good, $bad, $nomessage, $date, $unixdate ) = $sth->fetchrow_array;
#			$rss->add_item(
#				
#		}
#	}
#}

sub display_forums {
	my ( $dbh, $lastdate ) = @_;
	my @ret;
	my $sth = $dbh->prepare('select forum_id, name from forum order by modification_date') || die "$DBI::errstr";
	$sth->execute || die "$DBI::errstr";
	my $sti = $dbh->prepare('select count(*) from thread where forum_id = ? and modification_date > date_sub(now(), interval 1095 day)') || die $DBI::errstr;
	my $stz = $dbh->prepare('select count(*) from thread where forum_id = ? and modification_date > from_unixtime(?) and modification_date > date_sub(now(), interval 1095 day)') || die $DBI::errstr;
	while ( my ( $forum_id, $name ) = $sth->fetchrow_array ) {
		$sti->execute( $forum_id ) || die $DBI::errstr;
		my ( $total ) = $sti->fetchrow_array();
		$stz->execute( $forum_id, $lastdate ) || die $DBI::errstr;
		my ( $new ) = $stz->fetchrow_array();
		push @ret, "<li><a href=?f=$forum_id>$name</a> ($total thread", ( $total != 1 ? 's' : ''), ", <font color=blue>$new new thread", ($new != 1 ? 's' : '' ),  "</font>)";
	}
	return join('',@ret);
}

sub forum_name {
	my ( $dbh, $forum_id ) = @_;
	if ( $forum_id < 1000 )  {
		my $sth = $dbh->prepare('select name from forum where forum_id = ?') || die "$DBI::errstr";
		$sth->execute( $forum_id ) || die $DBI::errstr;
		$sth->rows || die "Forum $forum_id not found";
		my ( $forum_name ) = $sth->fetchrow_array;
		return $forum_name;
	} else {
		my $sth = $dbh->prepare('select name from regatta where id = ?') || die "$DBI::errstr";
		$sth->execute( $forum_id - 1000  ) || die $DBI::errstr;
		$sth->rows || die "Forum $forum_id not found";
		my ( $forum_name ) = $sth->fetchrow_array;
		return $forum_name;
	}
}

sub display_forum_msgs {
	my ( $dbh, $forum_id, $highlight_msg_id, $lastdate, $limit ) = @_;
	$limit ||= "100";
	my $display_post = 1;
	if ( $limit =~ /(\d+),(\d+)/ && $1 ) { $display_post = 0; }
	my @ret;
	if ( $display_post ) {
		push @ret, "<a rel=\"nofollow\" class=\"mbaction\" href=\"?p=new&amp;f=$forum_id#Message\">[Post new message]</a> ";
	}

	# push @ret, "<a href=/msgs/>[All Forums]</a><br/>";
	# display messages
	my $sth = $dbh->prepare("select thread.thread_id, first_msg, thread.modification_date from thread, msg where forum_id = ? and thread.first_msg = msg.msg_id and msg.deleted = 0 AND thread.modification_date > date_sub(now(), INTERVAL 1095 DAY) order by modification_date DESC limit $limit") || die $DBI::errstr;
	$sth->execute( $forum_id ) || die $DBI::errstr;

	if ( ! $sth->rows && $display_post )  {
		push @ret, "<br/><b>No current messages.</b><br/>\n";
	}

	while( my ( $thread_id, $first_msg, $modification_date ) = $sth->fetchrow_array ) {
		push @ret,
			display_msgs( $dbh, $first_msg, $forum_id, $highlight_msg_id, $lastdate );
	}
	return join('', @ret);
}

# recursive function for displaying msgs

sub display_thread
{
	my ( $dbh, $thread_id, $forum_id, $highlight_msg_id, $lastdate ) = @_;
	my $sth = $dbh->prepare("select first_msg from thread where thread_id = ?") || die $DBI::errstr;
	$sth->execute( $thread_id ) || die $DBI::errstr;
	$sth->rows || die "Can't locate thread $thread_id";
	my ( $first_msg ) = $sth->fetchrow_array;
	display_msgs( $dbh, $first_msg, $forum_id, $highlight_msg_id, $lastdate );
}

sub display_msgs
{
	my ( $dbh, $msg_id, $forum_id, $highlight_msg_id, $lastdate ) = @_;
	my @ret;
	my $sth = $dbh->prepare(qq{
		select
			name,
			title,
			views,
			good,
			bad,
			deleted,
			nomessage,
			date_format(insert_date,'%W %c-%e-%y %r'),
			unix_timestamp(insert_date)
		from
			msg,
			name,
			title
		where 
			msg_id = ? and
			msg.name_id = name.name_id and
			msg.title_id = title.title_id
		} ) || die $DBI::errstr;
	$sth->execute( $msg_id ) || die $DBI::errstr;
	$sth->rows || die "Error message $msg_id not found.";
	my ( $name, $title, $views, $good, $bad, $deleted, $nomessage, $date, $unixdate ) = $sth->fetchrow_array;

	if( ! $deleted )
	{
		push @ret, "<ul><li>\n",
		        "<a name=\"m$msg_id\"></a><a href=\"?f=$forum_id&amp;m=$msg_id#Message\">$title</a>", ( $nomessage == 1 ? ' <font color="red">*NM*</font>' : '' ),
			# " <small>($views views - good: $good bad: $bad)</small>",
			" <small>",
				"($views views)",
				" [<a href=\"#\" onClick=\"location.href='?f=$forum_id&amp;m=$msg_id&amp;delete=$msg_id'; return true;\" rel=\"nofollow\">x</a>]",
			"</small>",
			( $lastdate && ( $lastdate - $unixdate < 0 ) ? ' <font color="red"><small>(new since last visit)</small></font>' : ''),
			( defined $highlight_msg_id && $msg_id == $highlight_msg_id ? "<font color=\"red\"> (current)</font>" : "" ),  "<br/>",
			"$name ~ <small><i>$date</i></small>\n";
	}

	my $sti = $dbh->prepare("select msg_id from msg where reply_to = ? order by insert_date") || die $DBI::errstr;
	$sti->execute( $msg_id );
	while ( my ( $reply_id ) = $sti->fetchrow_array() ) {
		push @ret, display_msgs( $dbh, $reply_id, $forum_id, $highlight_msg_id, $lastdate );
	}
	if( ! $deleted ) { push @ret, "</li></ul>\n";  }
	return join('', @ret);
}

sub rate_msg
{
	my ( $dbh, $msg, $forum_id, $rate ) = @_;
	if ( $rate eq 'good' ) {
		my $sti = $dbh->prepare( "update msg set good = good + 1 where msg_id = ?" ) || die $DBI::errstr;
		$sti->execute( $msg->{msg_id} );
	} elsif ( $rate eq 'bad' ) {
		my $sti = $dbh->prepare( "update msg set bad = bad + 1 where msg_id = ?" ) || die $DBI::errstr;
		$sti->execute( $msg->{msg_id} );
	}
}

sub display_msg
{
	my ( $dbh, $msg ) = @_;
	my $sti = $dbh->prepare( "update msg set views = views + 1 where msg_id = ?" ) || die $DBI::errstr;
	$sti->execute( $msg->{msg_id} );


	return join('',
		# '<div id="ad" style="float:left; width:120px; margin-right:0.5em;">',
		# 	Myfleet::Google::google_ad( -size=>'120x600' ),
		# '</div>',
		"<table width=\"100%\" bgcolor=\"#efefd1\" style=\"margin-bottom:0.5em\"><tr><td>",
		"<i>Author:</i> <a href=\"/msgs/?n=$msg->{name_id}#Message\">$msg->{name}</a> ", ( $msg->{email} ? "(<a href=\"?e=$msg->{email_id}\">$msg->{obscuredEmail}</a>) <a href=\"#\" rel=\"nofollow\" onClick=\"window.open('../roster/detail/?e=$msg->{email_id}','emailwindow','width=500,height=300'); return true;\">contact the author</a>" : '' ), "<br/>",
		"<i>Subject:</i> $msg->{title}<br/>",
		# "<i>Info:</i> ($msg->{views} views - good: $msg->{good} bad: $msg->{bad}) <small><i>$msg->{insert_date}</i></small>",
		"<i>Info:</i> ($msg->{views} views) <small><b>Posted: $msg->{insert_date}</b></small>",
		"</table>",
		'<div id="msg" style="width:100%;">',
			# '<div id="ad" style="float:right; width:120px; margin-left:1em;">',
			# 	Myfleet::Google::google_ad( -size=>'125x125' ),
			# '</div>',
			$msg->{deleted} ? 'Sorry, this message has been deleted.<br/><br/>' : html_msg( $msg->{txt} ),
		'</div>',
	);
}

sub display_msg_options
{
	my ( $msg, $forum_id ) = @_;

	return join('',
		'<table width="100%" bgcolor="#cccccc"><tr><td>',
		"<a href=\"?m=$msg->{msg_id}&amp;f=$forum_id&amp;p=reply#reply\" rel=\"nofollow\">Reply</a> | ",
		"<a href=\"?f=$forum_id&amp;p=new#Message\" rel=\"nofollow\">Post New Message</a> | ",
		"<a href=\"?f=$forum_id#m$msg->{msg_id}\">All Messages</a> | ",
		# "<a href=\"#\" onClick=\"location.href='?f=$forum_id&amp;m=$msg->{msg_id}&delete=$msg->{msg_id}'; return true;\" rel=\"nofollow\">Delete</a> | ",
		"<a href=\"#\" onClick=\"location.href='?f=$forum_id&amp;rate=bad&amp;m=$msg->{msg_id}'; return true;\" rel=\"nofollow\">this message is spam</a>",
		"</table>",
	);
		# "<a href=/msgs/>[All Forums]</a> ",
		# " Rate this message: <a href=?f=$forum_id&amp;r=good&amp;m=$msg->{msg_id}>[Good]</a> <a href=?f=$forum_id&amp;r=bad&amp;m=$msg->{msg_id}>[Bad]</a>",
		
}

sub msg {
	my ( $dbh, $msg_id ) = @_;
	my $sth = $dbh->prepare(qq{
		select 
			msg_id,
			reply_to,
			msg.name_id,
			name,
			msg.email_id,
			email,
			txt,
			msg.addr_id,
			addr,
			msg.title_id,
			title,
			views,
			good,
			bad,
			deleted,
			thread_id,
			date_format(insert_date,'%W %c-%e-%y %r')
		from
			msg,
			name,
			email,
			txt,
			addr,
			title
		where
			msg.name_id = name.name_id and
			msg.email_id = email.email_id and
			msg.txt_id = txt.txt_id and
			msg.addr_id = addr.addr_id and
			msg.title_id = title.title_id and
			msg.msg_id = ?
		} ) || die $DBI::errstr;
	$sth->execute( $msg_id ) || die $DBI::errstr;
	my $msg;
	$sth->rows || return $msg; # die "Message $msg_id not found.";
	( $msg->{msg_id}, $msg->{reply_to}, $msg->{name_id}, $msg->{name}, $msg->{email_id}, $msg->{email}, $msg->{txt}, $msg->{addr_id}, $msg->{addr}, $msg->{title_id}, $msg->{title}, $msg->{views}, $msg->{good}, $msg->{bad}, $msg->{deleted}, $msg->{thread_id}, $msg->{insert_date} ) = $sth->fetchrow_array;
	$msg->{obscuredEmail} = Myfleet::Util::obscureEmail( $msg->{email} );
	return $msg;
}

sub delete_msg
{
	my ( $dbh, $msg_id, $password ) = @_;

	my $sth;
	if( $password eq $config{'deletePassword'} )
	{
		$sth = $dbh->prepare("update msg set deleted = 1 where msg_id = ?");
		$sth->execute( $msg_id ) || die $DBI::errstr;
	} else {
		$sth = $dbh->prepare("update msg set deleted = 1 where msg_id = ? and password = ?");
		$sth->execute( $msg_id, $password ) || die $DBI::errstr;
	}
	return $sth->rows;
}

sub insert_msg
{
	my ( $dbh, $forum_id, $name, $email, $title, $msg, $replyto, $thread_id, $password, $session, $date ) = @_;

	my $name_id = str_id( $dbh, $name, 'name' );
	my $email_id = str_id( $dbh, $email, 'email' );
	my $title_id = str_id( $dbh, $title, 'title'  );
	my $txt_id = str_id( $dbh, format_text( $msg ), 'txt' );
	my $addr_id = str_id( $dbh, "$ENV{REMOTE_HOST} ($ENV{REMOTE_ADDR})", "addr" );
	my $session_id = str_id( $dbh, $session, 'session' );
	$password ||= '';
	if ( ! $replyto ) { $replyto = 0; }

	my $msg_id;
	if ( $date )
	{
		if ( ! $replyto ) {
			my $sti = $dbh->prepare("insert into thread ( forum_id, modification_date ) values ( ?,? )" ) || die $DBI::errstr;
			$sti->execute( $forum_id, $date ) || die $DBI::errstr;
			$thread_id = $dbh->{mysql_insertid};
		}

		my $sth = $dbh->prepare(qq{
			insert into msg (
				reply_to,
				name_id,
				email_id,
				txt_id,
				addr_id,
				title_id,
				thread_id,
				session_id,
				password,
				nomessage,
				insert_date ) values ( ?,?,?,?,?, ?,?,?,?,?, ? )
			} ) || die $DBI::errstr;
		$sth->execute( $replyto, $name_id, $email_id, $txt_id, $addr_id, $title_id, $thread_id, $session_id, $password, ($msg eq '' ? '1' : '0' ), $date ) || die $DBI::errstr;
		$msg_id = $dbh->{mysql_insertid};
	}
	else
	{
		if ( ! $replyto )
		{
			my $sti = $dbh->prepare("insert into thread ( forum_id ) values ( ? )" ) || die $DBI::errstr;
			$sti->execute( $forum_id ) || die $DBI::errstr;
			$thread_id = $dbh->{mysql_insertid};
		}

		my $sth = $dbh->prepare(qq{
			insert into msg (
				reply_to,
				name_id,
				email_id,
				txt_id,
				addr_id,
				title_id,
				thread_id,
				session_id,
				password,
				nomessage, 
				insert_date) values ( ?,?,?, ?,?,?, ?,?,?,?,now() )
			} ) || die $DBI::errstr;
		$sth->execute( $replyto, $name_id, $email_id, $txt_id, $addr_id, $title_id, $thread_id, $session_id, $password, ($msg eq '' ? '1' : '0' ) ) || die $DBI::errstr;
		$msg_id = $dbh->{mysql_insertid};
	}

	if ( ! $replyto ) {
		my $sti = $dbh->prepare("update thread set first_msg = ? where thread_id = ?") || die $DBI::errstr;
		$sti->execute( $msg_id, $thread_id ) || die $DBI::errstr;
	}

	if ( $replyto ) {
		my $sti = $dbh->prepare("update thread set modification_date = now() where thread_id = ?") || die $DBI::errstr;
		$sti->execute( $thread_id ) || die $DBI::errstr;
	}

	return $msg_id;
}

sub str_id {
	my ( $dbh, $str, $table ) = @_;
	my $idcol = $table . "_id";
	my $id;
	if ( $table ne 'txt' )  {
		my $sth = $dbh->prepare("select $idcol from $table where $table  = ?") || die $DBI::errstr;
		$sth->execute( $str ) || die $DBI::errstr;
		if ( $sth->rows ) {
			( $id ) = $sth->fetchrow_array;
		}
	}
	if ( ! $id ) {
		my $sth = $dbh->prepare("insert into $table ( $table ) values ( ? )") || die $DBI::errstr;
		$sth->execute( $str );
		$id = $dbh->{mysql_insertid};
		# push @output, "Insert_$table($str)=$id<br/>";
	}
	return $id;
}


sub dump_info
{
	my ( $q ) = @_;
	my @ret;
	my %p = $q->Vars;
	foreach( sort keys %p ) {
		push @ret, "<li>$_ = $p{$_}</li>";
	}
	push @ret, "Cookie: ", $q->raw_cookie, "<br/>";
	return join('', @ret );
}

sub html_msg
{
	my ( $text ) = @_;
	my @ret;
	my $pre = 0;

	# activates urls, shortening long ones for display
	# doesn't handle # correctly
	$text =~ s{(
(?:https?://(?:(?:(?:(?:(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?))|(?:(?:\d+)(?:\.(?:\d+)){3}))(?::(?:\d+))?)(?:/(?:(?:(?:(?:[a-zA-Z\d\$\-_.+!~*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*)(?:/(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*))*)(?:\?(?:(?:(?:[a-zA-Z\d\$-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*))?)?))}{"<a href=\"$1\" rel=\"nofollow\">" . (length($1) < 60 ? $1 : substr($1,0,65) . '...' ) . '</a>'}xge;

#	$text =~ s {(
#(?:https?://
#	(?:
#		(?:
#			(?:
#				(?:
##					(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)
#					\.
#				)*
#				(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)
#			)
#			|(?:(?:\d+)(?:\.(?:\d+)){3})
#		)
#		(?::(?:\d+))
#	?)
#	(?:/
#		(?:
#			(?:
#				(?:(?:[a-zA-Z\d$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])
#			*)
#			(?:/
#				(?:
#					(?:(?:[a-zA-Z\d$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])
#				*)
#			)
#		*)
#	(?:\?
#		(?:
#			(?:
#				(?:[a-zA-Z\d$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))
#			|[;:@&=])
#		*)
#	)
#	?)
#?)
#)}{<a href="$1" target=_new>$1</a>}xg;


#	$text =~ s {(
#(?:http://(?:(?:(?:(?:(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)\.
#)*(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?))|(?:(?:\d+)(?:\.(?:\d+)
#){3}))(?::(?:\d+))?))
#)}{<a href="$1" target=_new>$1</a>}xg;

#(?:/(?:(?:(?:(?:[a-zA-Z\d$\-_.+!*'(),]|(?:%[a-fA-F
#\d]{2}))|[;:@&=])*)(?:/(?:(?:(?:[a-zA-Z\d$\-_.+!*'(),]|(?:%[a-fA-F\d]{
#2}))|[;:@&=])*))*)(?:\?(?:(?:(?:[a-zA-Z\d$\-_.+!*'(),]|(?:%[a-fA-F\d]{
#2}))|[;:@&=])*))?)?))}{<a href="$1" target=_new>$1</a>}xg;

	foreach my $line ( split /\r\n/, $text ) {
		if ( $line =~ /^(:: )*-/ ) {
			if ( $pre ) {
				push @ret, "$line\n";
			} else {
				push @ret, "<pre>$line\n";
				$pre = 1;
			}
		} elsif ( $line =~ /^::/ ) {
			if ( $pre ) { push @ret, "</pre>"; $pre = 0; }
			push @ret, "$line<br/>";
		} else {
			if ( $pre ) { push @ret, "</pre>"; $pre = 0; }
			push @ret, "$line<p>";
		}
	}
	if ( $pre ) { push @ret, "</pre>"; }
	return join('', @ret );
}

sub format_text
{
	my ( $text ) = @_;
	local($Text::Wrap::columns = 70);
	my @final = ();
	my @format = ();

	foreach my $line ( split /\r\n/, $text ) { 
		if ( $line =~ /^::/ || $line =~ /^-/ || $line eq '') {
			if ( @format ) {
				push @final, Text::Wrap::fill("","", @format ), "\r\n";
				@format = ();
			}
			push @final, "$line\r\n";
		} else {
			push @format, "$line\r\n";
		}
	}
	if ( @format ) {
		push @final, Text::Wrap::fill("","", @format );
	}
	return join('', @final );
}

sub quote_text
{
	my ( $text ) = @_;
	local($Text::Wrap::columns = 60);
	my @final = ();
	my @format = ();
	foreach my $line ( split /\r\n/, $text ) { 
		if ( $line =~ /^::/ || $line =~ /^-/ || $line eq '' ) {
			if ( @format ) {
				push @final, Text::Wrap::fill(":: ",":: ", @format ), "\r\n";
				@format = ();
			}
			push @final, ":: $line\r\n";
		} else {
			push @format, "$line\r\n";
		}
	}
	if ( @format ) {
		push @final, Text::Wrap::fill(":: ",":: ", @format );
	}
	return join('',@final);
}

#########################################################
# striphtml ("striff tummel")
# tchrist@perl.com
# version 1.0: Thu 01 Feb 1996 1:53:31pm MST
# version 1.1: Sat Feb  3 06:23:50 MST 1996
# (fix up comments in annoying places)
#########################################################
#
# how to strip out html comments and tags and transform
# entities in just three -- count 'em three -- substitutions;
# sed and awk eat your heart out.  :-)
#
# as always, translations from this nacré rendition into
# more characteristically marine, herpetoid, titillative,
# or indonesian idioms are welcome for the furthering of
# comparitive cyberlinguistic studies.
#


sub strip_html
{
	my ( $txt ) = @_;

$txt =~ s{ <!                   # comments begin with a `<!'
                        # followed by 0 or more comments;
     (.*?)		# this is actually to eat up comments in non
			# random places
      (                 # not suppose to have any white space here                         
			# just a quick start;
      --                # each comment starts with a `--'
        .*?             # and includes all text up to and including
      --                # the *next* occurrence of `--'
        \s*             # and may have trailing while space
                        #   (albeit not leading white space XXX)
     )+                 # repetire ad libitum  XXX should be * not +
    (.*?)		# trailing non comment text
   >                    # up to a `>'
}{
    if ($1 || $3) {	# this silliness for embedded comments in tags
	"<!$1 $3>";
    }
}gesx;                 # mutate into nada, nothing, and niente

#########################################################
# next we'll remove all the <tags>
#########################################################

$txt =~ s{ <                    # opening angle bracket     
	(?:             # Non-backreffing grouping paren
         [^>'"] *       # 0 or more things that are neither > nor ' nor "
            |           #    or else
         ".*?"          # a section between double quotes (stingy match)
            |           #    or else
         '.*?'          # a section between single quotes (stingy match)
    ) +                 # repetire ad libitum
                        #  hm.... are null tags <> legal? XXX
   >                    # closing angle bracket
}{}gsx;                 # mutate into nada, nothing, and niente

return $txt;
}

1;
