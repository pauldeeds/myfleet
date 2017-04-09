package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'beniciav15.org',

	# database
	'dbname' => 'beniciav15',
	'dbuser' => 'beniciav15',
	'dbpassword' => 'carquinez',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-23',

	# header
	'defaultTitle' => 'Benicia V15 Fleet 76',
	'headerHtml' => '<span style="float:left"><img src="/i/benicia-flag76.jpg" width="161" height="100" alt="Benicia Fleet 76 Flag"/></span><h1>Benicia V15 Fleet 76</h1>',

	'style' => 'beneciav15.css',
	'menuItems' => [ 'Home', 'Events', 'Crew List', 'Roster', 'Messages', 'For Sale', 'Links', 'Resources', 'Dues', 'Photos' ],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		'Crew List' => '/crew/',
		'Roster' => '/roster/',
		'Messages' => '/msgs/?f=1',
		'For Sale' => '/msgs/?f=2',
		'Links' => '/articles/links',
		'Resources' => '/articles/resources',
		'Dues' => '/dues/',
		'Photos' => '/photos/',
	},

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list
	'crewPositions' => ['Helm','Crew'],

	# schedule
	'defaultYear' => 2017,
	'series' => [
		{
			'name' => 'Friday Night Series',
			'scoring' => 'lowpoint',
			'throwouts' => 10,
			'dbname' => 'series1',
			'style' => 'bold',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 1,
			'showNextOnHomePage' => 1
		},

	],

	# dues
	'dues1' => 'Regular',

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'carquinez',
	'trackDirectory' => '/usr/local/apache2/htdocs/beniciav15.org/tracks/'
);


1;
