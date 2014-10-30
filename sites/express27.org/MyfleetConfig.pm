package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'express27.org',

	# database
	'dbname' => 'express27',
	'dbuser' => 'express27',
	'dbpassword' => 'lightship',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-2',

	# header
	'defaultTitle' => 'Express 27',
	'headerHtml' => '<center><img src="/images/bexpusm.gif" alt="Express 27 - The Ultimate Sailing Machine"></center>',
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
			'name' => 'SF Championship',
			'scoring' => 'highpoint',
			'dbname' => 'series1',
			'style' => 'bold',
			# 'prelim' => 1,
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'SF Long Distance',
			'scoring' => 'highpoint',
			'dbname' => 'series2',
			'style' => 'asterisk',
			# 'prelim' => 1,
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'SF Midwinter',
			'scoring' => 'lowpoint',
			'dbname' => 'series3',
			'style' => 'italic',
			'showScheduleOnHomePage' => 0,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'Detroit Buoy',
			'scoring' => 'highpoint',
			'dbname' => 'series4',
			'style' => 'green bold',
			'showScheduleOnHomePage' => 0,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 0
		},
		{
			'name' => 'Detroit Distance',
			'scoring' => 'highpoint',
			'dbname' => 'series5',
			'style' => 'green asterisk',
			'showScheduleOnHomePage' => 0,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 0
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
	'deletePassword' => 'lightship',
	'trackDirectory' => $ENV{'DOCUMENT_ROOT'} . '/tracks/'
);


1;
