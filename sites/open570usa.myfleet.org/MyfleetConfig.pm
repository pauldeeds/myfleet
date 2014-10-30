package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'open570usa.myfleet.org',

	# database
	'dbname' => 'open570usa',
	'dbuser' => 'open570usa',
	'dbpassword' => 'finotgroup',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-24',

	# header
	'defaultTitle' => 'Open 5.70 USA',
	'headerHtml' => '<center><h1>Open 5.70 USA</h1></center>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Events', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Articles', 'Photos', 'Links' ],
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
		'Links' => '/articles/links',
		'Dues' => '/dues/',
	},
	'external_style' => 'http://www.open570usa.com/myfleet.css',
	'external_script' => 'http://www.open570usa.com/myfleet.js',

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list 
	'crewPositions' => ['Bow','Trim','Helm'],

	# schedule
	'defaultYear' => 2014,
	'series' => [
		{
			'name' => 'Championship',
			'scoring' => 'open570_highpoint',
			'dbname' => 'series1',
			'style' => 'bold',
			# 'prelim' => 1,
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 1,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'Just For Fun',
			'scoring' => 'open570_highpoint',
			'dbname' => 'series2',
			'style' => 'asterisk',
			# 'prelim' => 1,
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
	],

	# dues
	'dues1' => 'San Francisco Fleet',

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'finotgroup',
	'trackDirectory' => '/usr/local/apache2/htdocs/open570usa.com/tracks/'
);


1;
