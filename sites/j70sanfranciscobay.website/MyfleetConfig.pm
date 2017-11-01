package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'j70sanfranciscobay.website',

	# database
	'dbname' => 'j70sf',
	'dbuser' => 'j70sf',
	'dbpassword' => 'bowsprit',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-2',

    # style sheet (defaults to myfleet.css if not set)
    'style' => 'j70sf.css',

	# header
	'defaultTitle' => 'J70 San Francisco Bay Fleet',
	'headerHtml' => '<img style="float:left" src="/j70sf-logo.png" height=120" alt="J70 San Francisco Logo"/> <h1 style="padding-top:40px;font-size:30px">J70 San Francisco Bay Fleet</h1>',
	'menuBackground' => '#1c4982',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Regattas', 'Dues', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Articles', 'Photos', 'Rules' ],
	'menuHrefs' => {
		'Home' => '/',
		'Regattas' => '/schedule/',
		'Roster' => '/roster/',
		'Crew List' => '/crew/',
		'Messages' => '/msgs/?f=1',
		'For Sale' => '/msgs/?f=2',
		# 'Email List' => '/articles/emaillist',
		'Articles' => '/articles/articlelist',
		'Photos' => '/photos/?gallery=126',
		'Rules' => '/articles/rules',
		'Dues' => '/dues/',
	},

	# matches up with menu for events/schedule
	'EventsMenu' => 'Regattas',
	'CrewListMenu' => 'Crew List',

	# crew list 
	'crewPositions' => ['Bow','Jib/Spinnaker Trimmer','Main Trimmer','Driver'],

	# schedule
	'defaultYear' => 2017,
	'series' => [
		{
			'name' => 'J70 San Francisco',
			'scoring' => 'highpoint',
			'dbname' => 'series1',
			'style' => 'bold',
			# 'prelim' => 1,
			'showScheduleOnHomePage' => 1,
			'showResultsOnHomePage' => 0,
			'showNextOnHomePage' => 1
		},
	],

	# dues
	'dues1' => 'Local',
	# 'dues2' => 'National',

	# mailing list
	#'mailingList' => 'Sf-express27',

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'bowsprit',
	'trackDirectory' => $ENV{'DOCUMENT_ROOT'} . '/tracks/'
);


1;
