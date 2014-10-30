package MyphotoConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%photoconfig);

%photoconfig = (
	# general
	'title' => 'J24 Fleet 21 - Photos',
	'header' => 'myfleet',

	# database
	'dbname' => 'j24fleet21',
	'dbuser' => 'j24fleet21',
	'dbpassword' => 'jibeset',

	# adsense
	'adsenseId' => 'pub-8024486686536860',
	'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],

	# analytics
	'analyticsId' => 'UA-3237132-1',

	# directory
	'photoDirectory' => '/photos/',
	'rootPath' => $ENV{'DOCUMENT_ROOT'} . 'photos/',
);


1;
