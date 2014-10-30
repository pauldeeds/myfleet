package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'j24fleet155.org',

	# database
	'dbname' => 'j24fleet155',
	'dbuser' => 'j24fleet155',
	'dbpassword' => 'jibeset',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-18',

	# header
	'defaultTitle' => 'J24 Fleet 155',
	'headerHtml' => qq[
<center><h1>J24 Fleet 155</h1></center>
],
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => ['Home','Events','Messages','For Sale','Roster','Crew List','Resources','Photos','Dues'],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		'Roster' => '/roster/',
		'Crew List' => '/crew/',
		'Messages' => '/msgs/?f=1',
		'For Sale' => '/msgs/?f=2',
		'News' => '/articles/news',
		'Resources' => '/articles/resources',
		'Photos' => '/photos/',
		'Videos' => '/articles/videos',
		'Dues' => '/dues/',
	},

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list 
	'crewPositions' => ['Bow','Mast','Pit','Trim','Helm'],

	# schedule
	'defaultYear' => 2013,
	'series' => [
		{
			'name' => 'Regular',
			'scoring' => 'highpoint',
			'dbname' => 'series1',
			'style' => 'bold',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
	],

	# dues
	'dues1' => 'Local',
	
	# mailing list
	'mailingList' => '', 

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'jibeset'
);


1;
