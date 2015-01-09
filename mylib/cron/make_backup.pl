#!/usr/local/bin/perl
use strict;

use lib '/home/pdeeds/src/myfleet/mylib/myfleet.org/';

use Myfleet::S3;
use Net::Amazon::S3;
use Net::Amazon::S3::Client;

my $local_backup_dir = '/var/www/backups/';
my $htdocs_dir = '/var/www';
my $mylib_dir = '/home/pdeeds/src/myfleet/sites/';


my %s3_conf = Myfleet::S3::parseConfig();

# must set up host key verification for this to work at a new address
# my $scp = "root\@diskstation:/volume1/m5backup/";
my $scp = "pdeeds\@sfrents.org:~/remote_backup/";

my $site;
my $db = '';
my $mysqlpw = '';

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $today = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);

if( scalar(@ARGV) == 1 ) {
	$site = $ARGV[0];
} elsif( scalar(@ARGV) == 3 ) {
	$site = $ARGV[0];
	$db = $ARGV[1];
	$mysqlpw = $ARGV[2];
} else {
	die "usage: make_backup.pl <site directory> <optional database name> <optional mysql password>\n";
}

-d $local_backup_dir || die "Directory $local_backup_dir not found.\n";
-d $htdocs_dir || die "Directory $htdocs_dir not found.\n";
-d $mylib_dir || die "Directory $mylib_dir not found.\n";

my @scp;
my %filesToS3;
if( -d "$htdocs_dir/$site" )
{
	chdir( $htdocs_dir );
	my $htdocs_file = "$local_backup_dir${site}__htdocs__${today}.tar.gz";
	my $htdocs_latest = "${site}__htdocs__latest.tar.gz";
	#print "tar -cpzf $htdocs_file $site/*\n";
	`tar -cpzf $htdocs_file $site/*`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $htdocs_file $scp$htdocs_latest";
	$filesToS3{$htdocs_file} = "${site}__htdocs__${today}.tar.gz";
}
else
{
	print "ERROR - $htdocs_dir/$site is not a directory\n";
}

if( -d "$mylib_dir/$site" )
{
	chdir( $mylib_dir );
	my $mylib_file = "$local_backup_dir${site}__mylib__${today}.tar.gz";
	my $mylib_latest = "${site}__mylib__latest.tar.gz";
	#print "tar -cpzf $mylib_file $site/*\n";
	`tar -cpzf $mylib_file $site/*`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $mylib_file $scp$mylib_latest";
	$filesToS3{$mylib_file} = "${site}__mylib__${today}.tar.gz";
}
else
{
	print "ERROR - $mylib_dir/$site is not a directory\n";
}

if( $site eq 'mailman' )
{
	chdir('/var/lib/mailman/');
	my $mailman_lists_file = "$local_backup_dir${site}__lists__${today}.tar.gz";
	my $mailman_lists_latest = "${site}__lists__latest.tar.gz";
	my $mailman_archives_file = "$local_backup_dir${site}__archives__${today}.tar.gz";
	my $mailman_archives_latest = "${site}__archives__latest.tar.gz";

	`tar -cpzf $mailman_lists_file lists/`;
	`tar -cpzf $mailman_archives_file archives/private/*mbox/*mbox`;

	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $mailman_lists_file $scp$mailman_lists_latest";
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $mailman_archives_file $scp$mailman_archives_latest";

	$filesToS3{$mailman_lists_file} = "${site}__lists__${today}.tar.gz";
	$filesToS3{$mailman_archives_file} = "${site}__archives__${today}.tar.gz";
}

chdir( $local_backup_dir );

if( $db )
{
	my $db_file = "${site}__db__${today}.sql.gz";
	my $db_latest = "${site}__db__latest.sql.gz";
	`/usr/bin/mysqldump -uroot -p${mysqlpw} $db | gzip > $db_file`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $db_file $scp$db_latest";

	$filesToS3{$db_file} = $db_file;
}

# clean up old files
my @htdocs_dates;
my @mylib_dates;
my @db_dates;
my @mailman_dates;
my @mailman_list_dates;

opendir(DIR, $local_backup_dir ) || die "can't open directory $local_backup_dir";
foreach my $file ( sort( readdir(DIR) ) )
{
	if( $file =~ /^${site}__htdocs__(\d{8})\.tar\.gz$/ )
	{
		push @htdocs_dates, $1;
	}
	elsif( $file =~ /^${site}__mylib__(\d{8})\.tar\.gz$/ )
	{
		push @mylib_dates, $1;
	}
	elsif( $file =~ /^${site}__db__(\d{8})\.sql.gz$/ )
	{
		push @db_dates, $1;
	}
	elsif ( $file =~ /^${site}__archives__(\d{8})\.tar.gz/ )
	{
		push @mailman_dates, $1;
	}
	elsif ( $file =~ /^${site}__lists__(\d{8})\.tar.gz/ )
	{
		push @mailman_list_dates, $1;
	}
}

while( scalar(@htdocs_dates) > 2 )
{
	my $date = shift(@htdocs_dates);
	`rm -f ${site}__htdocs__${date}.tar.gz`;
}

while( scalar(@mylib_dates) > 2 )
{
	my $date = shift(@mylib_dates);
	`rm -f ${site}__mylib__${date}.tar.gz`;
}

while( scalar(@db_dates) > 2 )
{
	my $date = shift(@db_dates);
	`rm -f ${site}__db__${date}.sql.gz`;
}

while( scalar(@mailman_dates) > 2 )
{
	my $date = shift(@mailman_dates);
	`rm -f ${site}__archives__${date}.sql.gz`;
}

while( scalar(@mailman_list_dates) > 2 )
{
	my $date = shift(@mailman_list_dates);
	`rm -f ${site}__lists__${date}.sql.gz`;
}

foreach my $file ( keys(%filesToS3) )
{
	my $s3key = "$site/$filesToS3{$file}";
	# print "Copying $file to $s3key ...\n";

    my $s3 = Net::Amazon::S3->new( \%s3_conf );
    my $bucket = $s3->bucket('myfleet-backups');
    $bucket->add_key_filename($s3key, $file, {content_type => 'application/gzip' } ) || die "Could not write $file to s3 bucket" . $s3->err . ": " . $s3->errstr;
}


#foreach my $scpcmd ( @scp )
#{
#	# print "$scpcmd\n";
#	`$scpcmd`;
#}
