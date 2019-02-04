package MyphotoConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%photoconfig);

%photoconfig = (
	# general
	'title' => 'Windmill Class - Photos',
	'header' => 'myfleet',

	# database
	'dbname' => 'windmillclass',
	'dbuser' => 'windmillclass',
	'dbpassword' => 'clarkmills',

	# adsense
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],

	# analytics
	'analyticsId' => 'UA-242507-14',

	# directory
	'photoDirectory' => '/photos/',
	'rootPath' => $ENV{'DOCUMENT_ROOT'} . 'photos/',
);


1;
