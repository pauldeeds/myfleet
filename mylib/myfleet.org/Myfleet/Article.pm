use diagnostics;
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;

package Myfleet::Article;

use MyfleetConfig qw(%config);

sub display_article
{
	my ( $q, $tab ) = @_;
	my @ret;

	$tab ||= 'Articles';
	my $html = '<h2>No article specified</h2>';
	my $title = 'No article specified';

	if( $q->param('u') )
	{
		( $html, $title ) = Myfleet::Util::html( $q->param('u') );
		foreach my $menu ( keys %{$config{'menuHrefs'}} )
		{
			if( defined( $ENV{'REQUEST_URI'}) && $ENV{'REQUEST_URI'} eq $config{'menuHrefs'}{$menu} )
			{
				$tab = $menu;
				last;
			}
		}
	}

	push @ret,
		$q->header,
		Myfleet::Header::display_header($tab,'..',$title),
		$html,
		Myfleet::Header::display_footer();

	return @ret;
}

1;
