package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'rycsunday.myfleet.org',

	# database
	'dbname' => 'rycsunday',
	'dbuser' => 'rycsunday',
	'dbpassword' => 'centerboard',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-21',

	# header
	'defaultTitle' => 'Sunday Laser Series - Richmond Yacht Club',
	'headerHtml' => '<h1>Sunday Laser Series - Richmond Yacht Club</h1>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Events', 'Messages', 'Links', 'Photos' ],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		# 'Crew List' => '/crew/',
		'Messages' => '/msgs/?f=1',
		'Links' => '/articles/links',
		'Photos' => '/photos/'
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
			'name' => 'Full Rig',
			'scoring' => 'sunday_highpoint',
			'dbname' => 'series1',
			'style' => 'italic',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 1,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'Radial',
			'scoring' => 'sunday_highpoint',
			'dbname' => 'series2',
			'style' => 'bold',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 1,
			'showNextOnHomePage' => 1
		},
		#{
		#	'name' => 'Thursday',
		#	'scoring' => 'thursday_highpoint',
		#	'dbname' => 'series2',
		#	'style' => 'asterisk',
		#	'showScheduleOnHomePage' => 0,
		#	'showResultsOnHomePage' => 1,
		#	'showNextOnHomePage' => 0,
		#	'sponsorHtml' => 'thursday_svendsens_ad'
		#},
		#{
		#	'name' => 'Championship',
		#	'scoring' => 'highpoint',
		#	'dbname' => 'series1',
		#	'style' => 'bold',
		#	'showScheduleOnHomePage' => 1,
		#	'showResultsOnHomePage' => 1,
		#	'showNextOnHomePage' => 0
		#},
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
	'dues1' => 'Sunday',
	# 'dues2' => 'National',
	
	# mailing list
	#'mailingList' => 'Sfv15',

	# contacts on home page
	'maximumSpecialOrder' => 10,

	# messages
	'deletePassword' => 'centerboard'
);


1;
