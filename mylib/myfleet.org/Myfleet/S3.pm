package Myfleet::S3;

sub parseConfig
{
	my $filename = glob('~/.ssh/amazon-aws.key');
	open (my $fh, "<$filename") ||  die "Could not open file $filename";

	my %s3_hash = ();
	while (my $line = <$fh>)
	{
		chomp($line);
		my ($key,$val) = split('=', $line );

		if ($key eq 'AWSAccessKeyId')
		{
			$s3_hash{'aws_access_key_id'} = $val;
		}
		elsif ($key eq 'AWSSecretKey')
		{
			$s3_hash{'aws_secret_access_key'} = $val;
		}
		else
		{
			$s3_hash{$key} = $val;
		}
	}

	#foreach my $key (keys(%s3_hash))
	#{
	#	print "$key=$s3_hash{$key}\n";
	#}

	if (!$s3_hash{'aws_access_key_id'} || !$s3_hash{'aws_secret_access_key'})
	{
		die "key or secret key missing from aws file";
	}

	return %s3_hash;
}

1;
