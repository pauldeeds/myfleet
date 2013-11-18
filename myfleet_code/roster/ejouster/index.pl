#!/usr/local/bin/perl

# this is just for the windmill class

use CGI;
use Data::Dumper;
use Email::Valid;

my $q = new CGI();

my $sendmail = "/usr/sbin/sendmail -t";
my $to = "alan\@lakelevel.com";
# $to = "pauldeeds\@gmail.com";

print
	$q->header,
	$q->start_html( -title=>'e-Jouster Registration' ),
	'<img border="0" src="/static/Jouster/eJouster.bmp" width="336" height="250">';

my $show_form = 1;

if( $q->param('Sign Up') || $q->param('Remove Me') )
{
	my @errors;
	if( ! $q->param('MemberName') )
	{
		push @errors, 'Please enter your name.';
	}
	if( ! $q->param('Email') )
	{
		push @errors, 'Please enter your email address.';
	}
	elsif( ! Email::Valid->address($q->param('Email')) )
	{
		push @errors, $q->param('Email') . ' does not appear to be a valid email address';
	}

	if( scalar(@errors) == 0 )
	{

		my $reply_to = "Reply-to: " . $q->param('Email') . "\n";
		my $subject = "Subject: EJouster " . ( $q->param('Sign Up') ? 'Sign Up: ' : 'Remove: ' ) . $q->param('MemberName') . "\n";

		my $content = $q->param('Sign Up') ? 'Sign me up.' : 'Remove me.';
		$content .= "\n\nMember Name: " . $q->param('MemberName') . "\n" . "Email: " . $q->param('Email') . "\n\n";

		open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
		print SENDMAIL $reply_to;
		print SENDMAIL $subject;
		print SENDMAIL "To: $to\n";
		print SENDMAIL "Content-type: text/plain\n\n";
		print SENDMAIL $content;
		close(SENDMAIL); 

		# print "<pre>${reply_to}${subject}To: ${to}\nContent-type: text/plain\n\n${content}</pre>";

		if( $q->param('Sign Up') )
		{
			print "<p>Thank you, you've been added to the list.</p><a href=\"/static/Jouster/\">&laquo; Back to Jouster</a><br/><a href=\"/\">&laquo; Back to Windmill Class</a></p>";
		} elsif ( $q->param('Remove Me') ) {
			print "<p>Thank you, you've been removed from the list.</p><a href=\"/static/Jouster/\">&laquo; Back to Jouster</a><br/><a href=\"/\">&laquo; Back to Windmill Class</a></p>";
		}

		$show_form = 0;
	}
	else
	{
		print '<p style="color:#f00">Errors were found.',
				'<ul style="color:#f00"><li>',
					join('</li><li>', @errors ),
				'</li></ul>',
				'</p>';
	}
}

if( $show_form )
{
	print 
		'<p>If you would like to receive the e-Jouster<br/>',
		'Enter your name and e-mail address below.</p>',
		$q->start_form(-method=>'post'),
		'Name: ', $q->textfield(-name=>'MemberName', -size=>60), '<br/><br/>',
		'Email: ', $q->textfield(-name=>'Email', -size=>60 ), '<br/><br/>',
		$q->submit(-value=>'Sign Up',-name=>'Sign Up'),
		$q->submit(-value=>'Remove Me',-name=>'Remove Me'),
		$q->end_form;
}

print
	$q->end_html;

