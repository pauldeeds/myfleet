#!/usr/local/bin/perl
use strict;

use lib '/home/pdeeds/src/myfleet/mylib/myfleet.org/';

use Myfleet::S3;
use Net::Amazon::S3;
use Net::Amazon::S3::Client;

my $local_backup_dir = '/var/www/backups/';
my %s3_conf = Myfleet::S3::parseConfig();
my $scp = "pdeeds\@sfrents.org:~/remote_backup/"; # must set up ssh keys for this to work

my $site;
my $db = '';
my $mysqlpw = '';

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $today = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);

if( scalar(@ARGV) == 3 ) {
	$site = $ARGV[0];
	$db = $ARGV[1];
	$mysqlpw = $ARGV[2];
} else {
	die "usage: make_backup.pl <site directory> <database name> <mysql password>\n";
}

-d $local_backup_dir || die "Directory $local_backup_dir not found.\n";

my @scp;
my %filesToS3;

chdir( $local_backup_dir );

if( $db )
{
	my $db_file = "${site}__db__${today}.sql.gz";
	my $db_latest = "${site}__db__latest.sql.gz";
	`/usr/bin/mysqldump -uroot -p$mysqlpw $db | gzip > $db_file`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $db_file $scp$db_latest";
	$filesToS3{$db_file} = $db_file;
}

# clean up old files
my @db_dates;

opendir(DIR, $local_backup_dir ) || die "can't open directory $local_backup_dir";
foreach my $file ( sort( readdir(DIR) ) )
{
	if( $file =~ /^${site}__db__(\d{8})\.sql.gz$/ )
	{
		push @db_dates, $1;
	}
}

while( scalar(@db_dates) > 14 )
{
	my $date = shift(@db_dates);
	`rm -f ${site}__db__${date}.sql.gz`;
}

foreach my $file ( keys(%filesToS3) )
{
	my $s3key = "$site/$filesToS3{$file}";
	my $s3 = Net::Amazon::S3->new( \%s3_conf );
	my $bucket = $s3->bucket('myfleet-backups');
	$bucket->add_key_filename($s3key,$file, {content_type => 'application/gzip' } ) || die "Could not write $file to s3 bucket" . $s3->err . ": " . $s3->errstr;
}

#foreach my $scpcmd ( @scp )
#{
#	`$scpcmd`;
#}
