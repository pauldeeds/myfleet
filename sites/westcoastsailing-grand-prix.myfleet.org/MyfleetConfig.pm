package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'westcoastsailing-grand-prix.myfleet.org',

	# database
	'dbname' => 'sven',
	'dbuser' => 'sven',
	'dbpassword' => 'boatyard',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-22',

	# header
	'defaultTitle' => 'West Coast Sailing Grand Prix',
	'headerHtml' => '<span style="float:left"><img src="/i/westcoastsailing_header_logo.jpg" width="768" height="173" alt="West Coast Sailing"/></span> <h1>West Coast Sailing Grand Prix</h1>',
	'style' => 'westcoastsailing-grand-prix.css',
	'menuItems' => [ 'Home', 'Events', 'Messages', 'Rules', 'Links', 'Photos' ],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		# 'Crew List' => '/crew/',
		# 'Roster' => '/roster/',
		'Messages' => '/msgs/?f=1',
		'Links' => '/articles/links',
		'Rules' => '/articles/rules',
		'Photos' => '/photos/'
	},

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	# 'CrewListMenu' => 'Crew List',

	# crew list 
	# 'crewPositions' => ['Helm','Crew'],

	# schedule
	'defaultYear' => 2020,
	'series' => [
        {
            'name' => 'Standard',
            'scoring' => 'regatta_highpoint_laser',
            'dbname' => 'series1',
            'style' => 'italic',
            'showScheduleOnHomePage' => 1,
            'showResultsOnHomePage' => 1,
            'showNextOnHomePage' => 1,
            'sponsorHtml' => 'thursday_svendsens_ad'
        },
        {
            'name' => 'Radial',
            'scoring' => 'regatta_highpoint_laser',
            'dbname' => 'series2',
            'style' => 'bold',
            'showScheduleOnHomePage' => 1,
            'showResultsOnHomePage' => 1,
            'showNextOnHomePage' => 1
        },
		#{
		#	'name' => 'Weekend',
		#	'scoring' => 'highpoint',
		#	'dbname' => 'series4',
		#	'style' => '',
		#	'showScheduleOnHomePage' => 0,
		#	'showResultsOnHomePage' => 0,
		#	'showNextOnHomePage' => 1
		#},
		#{
		#	'name' => 'Tuesday',
		#	'scoring' => 'highpoint',
		#	'dbname' => 'series3',
		#	'style' => 'italic',
		#	'showScheduleOnHomePage' => 0,
		#	'showResultsOnHomePage' => 0,
		#	'showNextOnHomePage' => 0
		#},
		#{
		#	'name' => 'Midwinter',
		#	'scoring' => 'thursday_highpoint',
		#	'dbname' => 'series5',
		#	'style' => '',
		#	'showScheduleOnHomePage' => 0,
		#	'showResultsOnHomePage' => 0,
		#	'showNextOnHomePage' => 0
		#},
	],

	# dues
	'dues1' => 'Class Dues',
	# 'dues2' => 'National',
	
	# mailing list
	#'mailingList' => 'Sfv15',

	# contacts on home page
	'maximumSpecialOrder' => 10,

	# messages
	'deletePassword' => 'boatyard'
);


1;
