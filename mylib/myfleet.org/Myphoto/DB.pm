package Myphoto::DB;

use DBD::mysql;
use MyphotoConfig qw(%photoconfig);

sub connect
{
	return DBI->connect("dbi:mysql:$photoconfig{'dbname'}:localhost", $photoconfig{'dbuser'}, $photoconfig{'dbpassword'} );
}

1;
