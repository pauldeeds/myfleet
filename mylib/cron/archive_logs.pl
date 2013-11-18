#!/usr/local/bin/perl
use strict;

my $log_dir = '/usr/local/apache2/logs/';
my $archive_dir = '/usr/local/apache2/logs/archive/';

#my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#my $today = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);
#my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + 86400);
#my $tommorow = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - (1*86400));
my $twodaysago = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);

opendir(DIR, $log_dir) || die "can't opendir $log_dir";

# print "today: $today\n";
# print "yesterday: $yesterday\n";

print "archiving before: $twodaysago\n";

my @process;
foreach my $file ( sort(readdir(DIR)) )
{
	if( $file =~ /log\.(\d{8})$/ )
	{
		if( $1 < $twodaysago )
		{
			print "-- archiving: $file\n";
			print `gzip $log_dir$file`;
			print `mv $log_dir$file.gz $archive_dir$file.gz`;
			push @process, $file;
		}
		else
		{
			print "-- not archiving: $file\n";
		}
	}
}
close(DIR);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - (30*86400));
my $onemonthago = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);
print "purging archives before: $onemonthago\n";
opendir(DIR, $archive_dir ) || die "can't opendir $archive_dir";
chdir($archive_dir);
foreach my $file ( readdir(DIR) )
{
	if( $file =~ /(.*)\_\_(?:access|error)\_log\.(\d{4})(\d{2})(\d{2})\.gz$/ )
	{
		my $fulldate = "$2$3$4";
		my $monthfile = "$1__$2$3.tar";
		if( $fulldate < $onemonthago )
		{
			print "-- deep archiving: $file to $monthfile\n";
			if( -e $monthfile )
			{
				# append 
				print `tar rvfp $monthfile --remove-files $file`;
			}
			else
			{
				# create
				print `tar cvfp $monthfile --remove-files $file`;
			}
		}
		else
		{
			# print "-- skipping file: $file\n";
		}
	}
	else
	{
		# print "-- unrecognized file: $file\n";
	}
}
close(DIR);

