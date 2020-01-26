package MyfleetConfig;
use vars qw(%config @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = ('Exporter');
@EXPORT_OK = qw(%config);


# database
%config = (
	# domain name
	'domain' => 'windmillclass.com',

	# database
	'dbname' => 'windmillclass',
	'dbuser' => 'windmillclass',
	'dbpassword' => 'clarkmills',

	# adsense
	# 'adsenseId' => 'pub-8024486686536860',
	# 'adsenseColor' => ['2D5893', '99aacc', '000000', '000099', '003366' ],
	# 'adsenseColor' => ['efefd1','0033ff','efefd1', '000000', '0033ff' ],
	'adsenseId' => 'pub-8317794337664028',
	'adsenseColor' => ['cccccc','0000ff','f0f0f0', '000000', '008000' ],

	# analytics
	'analyticsId' => 'UA-242507-14',

	# header
	'style' => 'windmill.css',
	'defaultTitle' => 'Windmill Class Association',
	'headerHtml' => '<div id="titlewrap"><img id="logoimg" width="120" height="120" src="/images/logo.jpg" alt="Windmill Logo"/><div id="wordswrap"><h1>Windmill Class Association</h1><br/><span id="planefun">Windmill Sailing <u>_/)</u> Just Plane Fun</span></div></div>',
	'menuBackground' => '#000080',
	'menuForeground' => '#ffffff',
	'menuSelected' => '#c0c0ff',

    'menuItems' => [ 'Home', 'Events', 'Dues', 'Roster', 'Crew List', 'Messages', 'For Sale', 'Advertisers', 'The Jouster', 'Articles', 'Rigging & Tuning', 'Photos' ],
    'menuHrefs' => {
        'Home' => '/',
        'Events' => '/schedule/',
        'Roster' => '/roster/',
        'Crew List' => '/crew/',
        'Messages' => '/msgs/?f=1',
        'For Sale' => '/msgs/?f=2',
        # 'Email List' => '/articles/emaillist',
        'The Jouster' => '/static/Jouster/',
        'Advertisers' => '/articles/advertisers',
        'Articles' => '/articles/articlelist',
        'Rigging & Tuning' => '/articles/rigging-and-tuning',
        'Photos' => '/photos/',
        # 'Rules' => '/articles/rules',
        'Dues' => '/dues/',
	},

	# matches up with menu for events/schedule
	'EventsMenu' => 'Events',
	'CrewListMenu' => 'Crew List',

	# crew list 
	'crewPositions' => ['Skipper','Crew'],

	# schedule
	'defaultYear' => 2020,

	# dues
	'dues1' => 'Active',
	'dues3' => 'Associate',

	# mailing list
	'mailingList' => '',

	# contacts on home page
	'maximumSpecialOrder' => 10,

	# messages
	'deletePassword' => 'clarkmills',

	# tracks
	'trackDirectory' => $ENV{'DOCUMENT_ROOT'} . '/tracks/'
);


1;
