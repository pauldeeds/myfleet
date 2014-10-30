package MyphotoConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%photoconfig);

%photoconfig = (
	# general
	'title' => 'RYC Sunday Laser Photos',
	'header' => 'myfleet',

	# database
	'dbname' => 'rycsunday',
	'dbuser' => 'rycsunday',
	'dbpassword' => 'centerboard',

	# adsense
	'adsenseId' => 'pub-8024486686536860',
	'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],

	# analytics
	'analyticsId' => 'UA-242507-21',

	# directory
	'photoDirectory' => '/photos/',
	'rootPath' => $ENV{'DOCUMENT_ROOT'} . 'photos/',
);


1;
