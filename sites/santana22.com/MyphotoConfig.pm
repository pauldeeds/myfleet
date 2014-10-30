package MyphotoConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%photoconfig);

%photoconfig = (
	# general
	'title' => 'Santana 22 Photos',
	'header' => 'myfleet',

	# database
	'dbname' => 'santana22',
	'dbuser' => 'santana22',
	'dbpassword' => 'sailing',

	# adsense
	'adsenseId' => 'pub-8024486686536860',
	'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],

	# analytics
	'analyticsId' => 'UA-242507-2',

	# directory
	'photoDirectory' => '/photos/',
	'rootPath' => $ENV{'DOCUMENT_ROOT'} . 'photos/',
);


1;
