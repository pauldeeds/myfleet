package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'santana22.com',

	# database
	'dbname' => 'santana22',
	'dbuser' => 'santana22',
	'dbpassword' => 'sailing',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],


	# style sheet (defaults to myfleet.css if not set)
	'style' => 'myfleet.css',

	# analytics
	'analyticsId' => 'UA-242507-8',

	# header
	'defaultTitle' => 'Santana 22',
	'headerHtml' => '<center><big>Santana 22 - Fleet One</big></center>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Events', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Mailing List', 'Articles', 'Rules', 'Photos', 'Dues' ],
	'menuHrefs' => {
		'Home' => '/',
		'Events' => '/schedule/',
		'Crew List' => '/crew/',
		'Roster' => '/roster/',
		'Photos' => '/photos/',
		'Messages' => '/msgs/?f=1',
		'For Sale' => '/msgs/?f=2',
		'Mailing List' => '/articles/emaillist',
		'Articles' => '/articles/articlelist',
		'Rules' => '/articles/rules',
		'Dues' => '/dues/',
	},

	# menu
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list
	'crewPositions' => ['Bow','Trim','Helm'],

	# schedule
	'defaultYear' => 2018,
	'series' => [
		{
			'name' => 'Spinnaker',
			'scoring' => 'lowpoint',
			'throwouts' => 2,
			'dbname' => 'series1',
			'style' => 'bold',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 1,
			'showNextOnHomePage' => 1
		},
		{
			'name' => 'White Sails',
			'scoring' => 'lowpoint',
			'throwouts' => 5,
			'dbname' => 'series2',
			'style' => 'asterisk',
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 1,
			'showNextOnHomePage' => 1
		},
	],

	# dues
	'dues1' => 'Local',
	# 'dues2' => 'National',
	
	# mailing list
	'mailingList' => 'tuna',

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# message board
	'deletePassword' => 'cityfront',

);


1;
