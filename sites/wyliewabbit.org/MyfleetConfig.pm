package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'wyliewabbit.org',

	# database
	'dbname' => 'wyliewabbit',
	'dbuser' => 'wyliewabbit',
	'dbpassword' => 'trapeze',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# style
	'style' => 'wabbit.css',

	# analytics
	'analyticsId' => 'UA-242507-11',

	# header
	'defaultTitle' => 'Wylie Wabbit',
	'headerHtml' => '<img src="/docs/images/banner.gif" width="216" height="87" style="margin-right:30px"> <big style="font-size:50px; line-height:87px; vertical-align:top">Wylie Wabbit Class</big>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',
	'menuItems' => [ 'Home', 'Events', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Articles', 'Rules', 'Photos'  ],
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

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list
	'crewPositions' => ['Trapeze','Trim','Helm'],

	# schedule
	'defaultYear' => 2019,
    'series' => [
        {
            'name' => 'Season',
            'scoring' => 'lowpoint',
            'throwouts' => 2,
            'dbname' => 'series1',
            'style' => 'bold',
            'showScheduleOnHomePage' => 1,
            'showResultsOnHomePage' => 0,
            'showNextOnHomePage' => 1
        },
        {
            'name' => 'Fun',
            'scoring' => 'lowpoint',
            'throwouts' => 2,
            'dbname' => 'series2',
            'style' => 'italic',
            'showScheduleOnHomePage' => 1,
            'showResultsOnHomePage' => 0,
            'showNextOnHomePage' => 1
        },
        {
            'name' => 'Travel',
            'scoring' => 'lowpoint',
            'throwouts' => 2,
            'dbname' => 'series3',
            'style' => 'asterisk',
            'showScheduleOnHomePage' => 1,
            'showResultsOnHomePage' => 0,
            'showNextOnHomePage' => 1
        },
    ],

	# dues
	'dues1' => 'Local',
	# 'dues2' => 'National',

	# mailing list
	'mailingList' => '',

	# contacts on home page
	'maximumSpecialOrder' => 5,

	# messages
	'deletePassword' => 'trapeze',
	'trackDirectory' => $ENV{'DOCUMENT_ROOT'} . '/tracks/'
);


1;
