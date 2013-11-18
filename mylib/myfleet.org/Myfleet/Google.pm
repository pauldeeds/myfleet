use strict;
use diagnostics;

package Myfleet::Google;

use MyfleetConfig qw(%config);

sub google_ad
{
	my %args = @_;

	# Google ad client id
	my $client = $args{'-client'} || $config{'adsenseId'};
	
	# Legal dimensions
	# ----------------
	# banners and buttons: 728x90 468x60 125x125
	# towers: 120x600 160x600 120x240
	# inline rectangles: 300x250 250x250 336x280 180x150

	my ( $width, $height ) = split /x/, $args{'-size'};
	my $format = "${width}x${height}_as";
	my $channel = $args{'-channel'};

	# Color schemes
	my ( $color_border, $color_link, $color_bg, $color_text, $color_url ) = @{$config{'adsenseColor'}};

	return
qq[<script type="text/javascript"><!--
google_ad_client = "$client";
google_ad_width = "$width";
google_ad_height = "$height";
google_ad_format = "$format";] .
( $channel ? "google_ad_channel = \"$channel\";\n" : "" )
. qq[google_color_border = "$color_border";
google_ad_type = "text_image";
google_color_bg = "$color_bg";
google_color_link = "$color_link";
google_color_text = "$color_text";
google_color_url = "$color_url";
google_ui_features = "rc:6";
//--></script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>];

}

1;
