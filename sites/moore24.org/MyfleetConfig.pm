package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'moore24.org',

	# database
	'dbname' => 'moore24',
	'dbuser' => 'moore24',
	'dbpassword' => 'ditchrun',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-23',

	# header
	'defaultTitle' => 'Moore 24',
	'headerHtml' => '<center><h1>Moore 24</h1></center>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Events', 'Dues', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Email List', 'Articles', 'Photos', 'Rules' ],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		'Roster' => '/roster/',
		'Crew List' => '/crew/',
		'Messages' => '/msgs/?f=1',
		'For Sale' => '/msgs/?f=2',
		'Email List' => '/articles/emaillist',
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
	'defaultYear' => 2015,
	'series' => [
		{
			'name' => 'Championship',
			'scoring' => 'lowpoint',
			'dbname' => 'series1',
			'style' => 'bold',
			# 'prelim' => 1,
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},

	],

	# dues
	'dues1' => 'Regular',
	'dues2' => 'Associate',
	
	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'ditchrun',
	'trackDirectory' => '/usr/local/apache2/htdocs/moore24.org/tracks/'
);


1;
