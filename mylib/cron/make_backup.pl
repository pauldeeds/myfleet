#!/usr/local/bin/perl
use strict;

my $backup_dir = '/usr/local/apache2/backup/';
my $htdocs_dir = '/usr/local/apache2/htdocs/';
my $mylib_dir = '/usr/local/apache2/mylib/';

# must set up host key verification for this to work at a new address
# my $scp = "pdeeds\@66.117.149.51:~/m5backup/";
# my $scp = "pdeeds\@pauldeeds.dyndns.org:~/m5backup/";
# my $scp = "pdeeds\@deeds.viewnetcam.com:~/m5backup/";
my $scp = "root\@diskstation:/volume1/m5backup/";

my $site;
my $db = '';

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $today = sprintf("%d%02d%02d",$year+1900,$mon+1,$mday);

if( scalar(@ARGV) == 1 ) {
	$site = $ARGV[0];
} elsif( scalar(@ARGV) == 2 ) {
	$site = $ARGV[0];
	$db = $ARGV[1];
} else {
	die "usage: make_backup.pl <site directory> <optional database name>\n";
}

-d $backup_dir || die "Directory $backup_dir not found.\n";
-d $htdocs_dir || die "Directory $htdocs_dir not found.\n";
-d $mylib_dir || die "Directory $mylib_dir not found.\n";

my @scp;
if( -d "$htdocs_dir/$site" )
{
	chdir( $htdocs_dir );
	my $htdocs_file = "$backup_dir${site}__htdocs__${today}.tar.gz";
	my $htdocs_latest = "${site}__htdocs__latest.tar.gz";
	`tar -cpzf $htdocs_file $site/\n`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $htdocs_file $scp$htdocs_latest";
}

if( -d "$mylib_dir/$site" )
{
	chdir( $mylib_dir );
	my $mylib_file = "$backup_dir${site}__mylib__${today}.tar.gz";
	my $mylib_latest = "${site}__mylib__latest.tar.gz";
	`tar -cpzf $mylib_file $site/*`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $mylib_file $scp$mylib_latest";
}

if( $site eq 'mailman' )
{
	chdir('/usr/local/mailman/');
	my $mailman_lists_file = "$backup_dir${site}__lists__${today}.tar.gz";
	my $mailman_lists_latest = "${site}__lists__latest.tar.gz";
	my $mailman_archives_file = "$backup_dir${site}__archives__${today}.tar.gz";
	my $mailman_archives_latest = "${site}__archives__latest.tar.gz";

	`tar -cpzf $mailman_lists_file lists/`;
	`tar -cpzf $mailman_archives_file archives/private/*mbox/*mbox`;

	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $mailman_lists_file $scp$mailman_lists_latest";
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $mailman_archives_file $scp$mailman_archives_latest";
}

chdir( $backup_dir );

if( $db )
{
	my $db_file = "${site}__db__${today}.sql.gz";
	my $db_latest = "${site}__db__latest.sql.gz";
	`/usr/local/mysql/bin/mysqldump -uroot -pbeaver $db | gzip > $db_file`;
	push @scp, "scp -o StrictHostKeyChecking=no -B -l1500 $db_file $scp$db_latest";
}

# clean up old files
my @htdocs_dates;
my @mylib_dates;
my @db_dates;

opendir(DIR, $backup_dir ) || die "can't open directory $backup_dir";
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


foreach my $scpcmd ( @scp )
{
	# print "$scpcmd\n";
	`$scpcmd`;
}
