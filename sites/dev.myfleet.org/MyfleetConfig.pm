package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'dev.myfleet.org',

	# database
	'dbname' => 'dev',
	'dbuser' => 'dev',
	'dbpassword' => 'dev',

	# adsense
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-2',

	# header
	'defaultTitle' => 'Myfleet Sample Site',
	'headerHtml' => '<center>Myfleet.org Sample Site</center>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Events', 'Dues', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Articles', 'Photos', 'Rules' ],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		'Roster' => '/roster/',
		'Crew List' => '/crew/',
		'Messages' => '/msgs/?f=1',
		'For Sale' => '/msgs/?f=2',
		# 'Email List' => '/articles/emaillist',
		'Articles' => '/articles/articlelist',
		'Photos' => '/photos/',
		'Rules' => '/articles/rules',
		'Dues' => '/dues/',
	},

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list 
	'crewPositions' => ['Bow','Mast','Pit','Trim','Helm'],

	# schedule
	'defaultYear' => 2014,
	'series' => [
		{
			'name' => 'Highpoint Series',
			'scoring' => 'highpoint',
			'dbname' => 'series1',
			'style' => 'bold',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'Lowpoint',
			'scoring' => 'lowpoint',
			'dbname' => 'series3',
			'style' => 'italic',
			'showScheduleOnHomePage' => 0,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
	],

	# dues
	'dues1' => 'Local',
	'dues2' => 'National',
	
	# mailing list
	'mailingList' => 'Sf-express27',

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'dev',
	'trackDirectory' => $ENV{'DOCUMENT_ROOT'} . '/tracks/'
);


1;
