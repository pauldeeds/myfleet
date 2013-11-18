use strict;
use diagnostics;

package Santana::Mail;
$Santana::Mail::VERSION = 0.1;

sub sendmail
{
	my %args = @_;
	

	my $to_email = $args{'-to_email'};
	my $to_name = $args{'-to_name'};
	my $from_email = $args{'-from_email'};
	my $from_name = $args{'-from_name'};
	my $msg = $args{'-msg'};
	my $subject = $args{'-subject'};

        my $mailprog = "/usr/lib/sendmail -t -f$from_email";

        open (MAIL, "|$mailprog");

        print MAIL "From: $from_name <$from_email>\n";
        print MAIL "To: $to_name <$to_email>\n";
        print MAIL "Subject: $subject\n";
        print MAIL "\n\n";

	print MAIL $msg;

        close(MAIL);
}

1;
