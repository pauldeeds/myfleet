package Myfleet::Header;

use MyfleetConfig qw(%config);

sub display_footer
{
	return join('',
		qq[
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "$config{'analyticsId'}";
urchinTracker();
</script>
		],
		qq[
<!-- Start Quantcast tag -->
<script type="text/javascript" src="http://edge.quantserve.com/quant.js"></script>
<script type="text/javascript">_qacct="p-5dkG7c4EwjS8w";quantserve();</script>
<noscript>
<a href="http://www.quantcast.com/p-5dkG7c4EwjS8w" target="_blank"><img src="http://pixel.quantserve.com/pixel/p-5dkG7c4EwjS8w.gif" style="display: none" border="0" height="1" width="1" alt="Quantcast"/></a>
</noscript>
<!-- End Quantcast tag -->
		],
		'</body>',
	);
}

sub display_header
{
	my $current = shift;
	my $toroot = shift;
	my $title = shift || $config{'defaultTitle'};
	$toroot ||= "..";
	$current ||= "";

	my $stylesheet = $config{'style'} || 'myfleet.css'; 
	my @ret;

	push @ret,
	        "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n",
   "\"http://www.w3.org/TR/html4/loose.dtd\">\n",
		"<head>",
			"<link rel=\"stylesheet\" type=\"text/css\" href=\"/s/$stylesheet\">",
			"<title>$title</title>",
		"</head>\n",
		"<body>",
			'<div id="header">',
				$config{'headerHtml'},
				'<table width="100%" cellpadding="4" cellspacing="0" style="padding-bottom:0.3em;" id="menubar">',
					'<tr class="bar">';

	my @menuitems = @{$config{'menuItems'}};
	my %menuhrefs = %{$config{'menuHrefs'}};

	foreach my $item ( @menuitems )
	{
		my $xitem = $item;
		$xitem =~ s/ /&nbsp;/g;
		push @ret, '<td>';
		if ( $current eq $item )
		{
			push @ret, "<a class=\"current\" href=\"$toroot$menuhrefs{$item}\">$xitem</a>";
		}
		else
		{
			push @ret, "<a class=\"menu\" href=\"$toroot$menuhrefs{$item}\">$xitem</a>";
		}
	}
	push @ret,
		'</table>',
		"</div>\n";
	return @ret;
}

sub display_admin_header
{
	my $toroot = shift || "..";
	my $title = shift || "$config{'defaultTitle'} Administration";

	my @ret;
	push @ret, 
		"<head>",
			"<title>$title</title>",
		"</head>",
		"<body>",
		'<a href="/">&laquo; Back to Site</a> | <a href="/admin/">Admin Interface</a>',
		"<h3>$title</h3>";

	return @ret;
}

1;
