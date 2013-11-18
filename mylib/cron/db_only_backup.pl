#!/usr/local/bin/perl
use strict;

my $backup_dir = '/usr/local/apache2/backup/';

# must set up host key verification for this to work at a new address
# my $scp = "pdeeds\@66.117.149.51:~/m5backup/";
# my $scp = "pdeeds\@pauldeeds.dyndns.org:~/m5backup/";
# my $scp = "pdeeds\@deeds.viewnetcam.com:~/m5backup/";
my $scp = "root\@diskstation:/volume1/m5backup/";

my $site;
my $db = '';

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $today = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);

if( scalar(@ARGV) == 2 ) {
    $site = $ARGV[0];
    $db = $ARGV[1];
} else {
    die "usage: make_backup.pl <site directory> <database name>\n";
}

-d $backup_dir || die "Directory $backup_dir not found.\n";

my @scp;

chdir( $backup_dir );

if( $db )
{
	my $db_file = "${site}__db__${today}.sql.gz";
	my $db_latest = "${site}__db__latest.sql.gz";
	`/usr/local/mysql/bin/mysqldump -uroot -pbeaver $db | gzip > $db_file`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $db_file $scp$db_latest";
}

# clean up old files
my @db_dates;

opendir(DIR, $backup_dir ) || die "can't open directory $backup_dir";
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


foreach my $scpcmd ( @scp )
{
	`$scpcmd`;
}
