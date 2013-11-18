package Myphoto::Photo;

use Myphoto::DB;
use MyphotoConfig qw(%photoconfig);

use CGI;
use CGI::Carp 'fatalsToBrowser';
use Image::Magick;
use Data::Dumper;

sub galleries
{
	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sth = $dbh->prepare("select gallery.id, gallery.name, gallery.description, gallery.hide, sum(NOT photo.hide) as num from gallery LEFT OUTER JOIN photo ON ( gallery.id = photo.gallery_id ) where ( photo.hide IS NULL OR photo.hide = '0' ) group by gallery.id, gallery.name, gallery.hide, gallery.description") || die $DBI::errstr;
	$sth->execute();
	my @galleries;
	while( my $gallery = $sth->fetchrow_hashref ) {
		push @galleries, $gallery;
	}
	
	return @galleries;
}

sub photo
{
	my $photo = shift;

	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sth = $dbh->prepare("select id, width, height, thumb_width, thumb_height, caption, hide, gallery_id from photo where id = ?") || die $DBI::errstr;
	$sth->execute( $photo );
	$sth->rows || die "photo $photo could not be found.";

	return $sth->fetchrow_hashref;
}

sub photos
{
	my $gallery = shift;
	my $showHidden = shift || 0;

	my $hide = $showHidden ? '' : ' and hide = 0';

	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sth = $dbh->prepare("select id, width, height, thumb_width, thumb_height, caption, hide, gallery_id from photo where gallery_id = ? $hide") || die $DBI::errstr;
	$sth->execute( $gallery );
	my @photos;
	while( my $photo = $sth->fetchrow_hashref ) {
		push @photos, $photo;
	}

	return @photos;
}

sub insert_photo
{
	my ( $ext, $gallery_upload, $file, $caption ) = @_;
	# my $ext = shift;

	my $image = Image::Magick->new;
	$image->Read("$photoconfig{'rootPath'}/tmp.$ext");
	my ( $width, $height ) = $image->Get('width','height');
	my $thumb_height = 120;
	my $thumb_width = int(( $thumb_height * $width ) / $height );

	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sti = $dbh->prepare("insert into photo ( height, width, caption, gallery_id, thumb_height, thumb_width, filename ) values ( ?,?,?,?,?,?,? )" ) || die $DBI::errstr;
	$sti->execute( $height, $width, $caption, $gallery_upload, $thumb_height, $thumb_width, $file ) || die $DBI::errstr;
	my $photo_id = $sti->{mysql_insertid};

	if ( $ext == "jpg" ) {
		rename( "$photoconfig{'rootPath'}/tmp.$ext", "$photoconfig{'rootPath'}/${photo_id}.jpg" );
	} else {
		$image->Write("$photoconfig{'rootPath'}/${photo_id}.jpg");
	}
	$image->Resize( width=>$thumb_width, height=>$thumb_height, filter=>"Blackman" );
	$image->Set( quality=>90 );
	$image->Write("$photoconfig{'rootPath'}/${photo_id}_tmb.jpg");

	# make the 400 width thumb
	my $image400 = Image::Magick->new;
	$image400->Read("$photoconfig{'rootPath'}/${photo_id}.jpg");
	( $width, $height ) = $image400->Get('width','height');

	my $thumb_width400 = 400;
	my $thumb_height400 = int(( $thumb_width400 * $height ) / $width );

	$image400->Resize( width=>$thumb_width400, height=>$thumb_height400, filter=>"Blackman");
	$image400->Set( quality=>80 );
	$image400->Write("$photoconfig{'rootPath'}/${photo_id}_400.jpg");

	# make the 800 width thumb
	my $image800 = Image::Magick->new;
	$image800->Read("$photoconfig{'rootPath'}/${photo_id}.jpg");
	( $width, $height ) = $image800->Get('width','height');

	my $thumb_width800 = 800;
	my $thumb_height800 = int(( $thumb_width800 * $height ) / $width );

	$image800->Resize( width=>$thumb_width800, height=>$thumb_height800, filter=>"Blackman");
	$image800->Set( quality=>80 );
	$image800->Write("$photoconfig{'rootPath'}/${photo_id}_800.jpg");

}

sub update_photo
{
	my ( $id, $caption, $gallery_id, $hide ) = @_;
	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sti = $dbh->prepare("update photo set caption = ?, gallery_id = ?, hide = ? where id = ?" ) || die $DBI::errstr;
	$sti->execute( $caption, $gallery_id, $hide, $id ) || die $DBI::errstr;
}

sub update_gallery
{
	my ( $id, $name, $description, $hide ) = @_;
	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sti = $dbh->prepare("update gallery set name = ?, description = ?, hide = ? where id = ?" ) || die $DBI::errstr;
	$sti->execute( $name, $description, $hide, $id ) || die $DBI::errstr;
}

sub insert_gallery
{
	my ( $name, $description ) = @_;

	my $dbh = Myphoto::DB::connect() || die "could not connect to database";
	my $sth = $dbh->prepare("insert into gallery ( name, description ) values ( ?,? )");
	$sth->execute( $name, $description ) || die $DBI::errstr;

	return $sth->{mysql_insertid};
}

sub display_page
{
	my ( $q, $options ) = @_;

	my @ret;

	my $gallery = $q->param('gallery') || $q->param('gallery_upload') || 1;

	# DO NEW GALLERY PROCESSING
	if ( $q->param('gallery_name') )
	{
		$gallery = insert_gallery( $q->param('gallery_name'), $q->param('gallery_desc') );
		$gallery_upload = $gallery;
		$q->param('gallery_name',"");
		$q->param('gallery_desc',"");
	}

	# LOAD GALLERY LIST
	my %gallery_name;
	my @gallery_id;
	my %gallery_desc;
	my %gallery_count;
	my %gallery_hide;

	foreach my $g ( galleries() )
	{
		push @gallery_id, $g->{'id'};
		$gallery_name{$g->{'id'}} = $g->{'name'} || "No name";
		$gallery_desc{$g->{'id'}} = $g->{'description'} || "";
		$gallery_count{$g->{'id'}} = $g->{'num'} || 0;
		$gallery_hide{$g->{'id'}} = $g->{'hide'} || 0;
	}

	push @ret,$q->header;
	if( $photoconfig{'header'} eq 'myfleet' ) {
		push @ret, Myfleet::Header::display_header('Photos','..', "$photoconfig{'title'}: $gallery_name{$gallery}" );
	} else {
		push @ret, $q->start_html( -title=>"$photoconfig{'title'}: $gallery_name{$gallery}" );
	}

	# DO UPLOAD PROCESSING
	my $file = $q->upload('upload');
	my $info = $q->uploadInfo($file);
	if ( $file && $info->{'Content-Type'} !~ /^image/ ) {
		push @ret, "<font color=red>You must upload image files only.</font>";
		$file = "";
	} 
	if (!$file && $q->cgi_error ) {
		push @ret, "<font color=red><b>Error receiving file.</font>";
	}

	if ( $file )
	{
		my $gallery_upload = $q->param('gallery_upload');
		my $ext = "jpg";
		if ( $info->{'Content-Type'} =~ /gif/ ) {
			$ext = "gif";
		}
		open( OUTFILE,">$photoconfig{'rootPath'}/tmp.$ext" ) || die "can't write to file $photoconfig{'rootPath'}/tmp.$ext";
		my $in;
		my $buffer;
		while( $in = read($file,$buffer,1024)) {
			print OUTFILE $buffer;
		}
		close( OUTFILE );
		close( $file );

		insert_photo( $ext, $gallery_upload, $file, $q->param('caption') );

		$q->param('caption',"");
	}

	my @drop_down_ids;

	# UPLOAD FORM
	push @ret,
		'<div style="float:right; background:#ffc; padding:10px; vertical-align:top;">',
			# gallery list
			"<h3 style=\"margin-bottom:3px; margin-top:3px;\">Galleries</h3> (<a href=\"#upload\">upload a photo</a>)",
			"<table cellpadding=\"0\" cellspacing=\"0\">";
				foreach my $id ( @gallery_id )
				{
					if( ! $gallery_hide{$id} )
					{
						push @drop_down_ids, $id;
						push @ret, "<tr><td><small>($gallery_count{$id} picture", ($gallery_count{$id} != 1 ? "s)" : ")" ), '</td>',
								"<td>&nbsp;</td><td><small><a href=\"?gallery=$id\">$gallery_name{$id}</a></td></tr>";
					}
				}
	push @ret,
			"</table>";

	push @ret,
			# upload image form
			"<a name=\"upload\">",
			"<h3 style=\"margin-bottom:3px;\">Upload an image</h3>",
			$q->start_multipart_form( -action=>'' ),
			"<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\">",
				"<tr><td align=\"right\"><small>File:</td><td>", $q->filefield(-name=>'upload', -size=>20, -maxlength=>80 ), '</td></tr>',
				"<tr><td align=\"right\"><small>Caption:</td><td>", $q->textfield(-name=>'caption', -size=>30, -maxlength=>80 ), '</td></tr>',
				"<tr><td align=right><small>Gallery:</td><td>", $q->scrolling_list(
					-values=>\@drop_down_ids,
					-name=>'gallery_upload',
					-labels=>\%gallery_name,
					-size=>1,
					-default=>$gallery,
				), '</td></tr>',
			'</table>',
			$q->submit( "Upload Photo" ),
			'</form>';

	push @ret,
			"<h3 style=\"margin-bottom:3px;\">Add a new gallery</h3>",
			$q->start_form( -action=>'', -method=>'post' ),
			"<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\">",
				"<tr><td align=right><small>Name: <td>", $q->textfield(-name=>'gallery_name', -size=>30, -maxlength=>30 ),
				# "<tr><td colspan=2><small>Description:",
				# "<tr><td>&nbsp;<td>", $q->textarea( -name=>'gallery_desc', -cols=>25, -rows=>4, -noscroll=>1 ),
			"</table>",
			$q->submit("Add Gallery"),
			'</form>',
			'<br/>';

	push @ret, "</div>";

	push @ret,
			"<h2 style=\"margin-bottom:5px;\">$photoconfig{'title'}</h2>",
			"<h1 style=\"margin-bottom:5px;\">$gallery_name{$gallery}</h1>";
	
	# DISPLAY PHOTOS
	push @ret, "<a href=\"wide/?gallery=$gallery\">wide view</a> <a href=\"slide/?gallery=$gallery\">slide show</a><br/><br/>";
	foreach my $p ( photos($gallery) )
	{
		push @ret, "<a name=\"$p->{id}\"><a href=\"$photoconfig{'photoDirectory'}$p->{id}.jpg\" target=\"expimg\"><img src=\"$photoconfig{'photoDirectory'}$p->{id}_tmb.jpg\" height=\"$p->{thumb_height}\" width=\"$p->{thumb_width}\" ALT=\"$p->{caption}\" border=\"0\" /></a> ";
	}
	
	if( $photoconfig{'header'} eq 'myfleet' ) {
		push @ret, Myfleet::Header::display_footer();
	} else {
		push @ret, $q->end_html;
	}

	return @ret;
}

sub display_admin
{
	my ( $q, $options ) = @_;

	my @ret;

	my $gallery = $q->param('gallery') || $q->param('gallery_upload') || 1;

	if( $q->param('Update Gallery') )
	{
		update_gallery( $q->param('gallery'), $q->param('gallery_name'), $q->param('gallery_desc'), $q->param('hidden') eq 'on' );
	}

	# LOAD GALLERY LIST
	my %gallery_name;
	my @gallery_id;
	my %gallery_desc;
	my %gallery_count;
	my %gallery_hide;

	foreach my $g ( galleries() )
	{
		push @gallery_id, $g->{'id'};
		$gallery_name{$g->{'id'}} = $g->{'name'} || "No name";
		$gallery_desc{$g->{'id'}} = $g->{'description'} || "";
		$gallery_count{$g->{'id'}} = $g->{'num'} || 0;
		$gallery_hide{$g->{'id'}} = $g->{'hide'} || 0;
	}

	push @ret,$q->header;


	if( $q->param('p') )
	{
		if( $q->param('Update Photo') )
		{
			update_photo( $q->param('p'), $q->param('caption'), $q->param('gallery_id'), $q->param('hidden') eq 'on' );
			push @ret,
				'<h2>Update has been made.</h2>',
				'<ul>',
					'<li>Refresh the gallery to see the change.</li>',
					'<li>This window will automatically close in 3 seconds</li>',
				'</ul>',
				$q->submit( -value=>'Close Window', onClick=>'self.close()' ),
				"<script>window.setTimeout('self.close()',3000);</script>";
		}
		else
		{
			# popup for photo editing
			my $p = photo( $q->param('p') );
			my $newheight = int((400 * $p->{'height'} ) / $p->{'width'} );

			push @ret,
				'<script language="text/javascript">window.focus()</script>',
				$q->start_multipart_form( -action=>'' ),
				'Caption:<br/>',
					$q->textfield(-name=>'caption', -size=>50, -maxlength=>80, -default=>$p->{caption} ), '</td></tr>',
				'<br/>',
				'Gallery:<br/>',
					$q->scrolling_list(
						-values=>\@gallery_id,
						-name=>'gallery_id',
						-labels=>\%gallery_name,
						-size=>1,
						-default=>$p->{'gallery_id'},
					),
				'<br/>',
				$q->checkbox( -name=>'hidden', -checked=>$p->{hide} ),
				'<br/><br/>',
				$q->hidden( -name=>'p' ),
				$q->submit( 'Update Photo' ),
				$q->submit( -value=>"Cancel", onClick=>'self.close()' ),
				'</form>';

			push @ret, 
				"<img src=\"$photoconfig{'photoDirectory'}$p->{id}_400.jpg\" height=\"$newheight\" width=\"400\" ALT=\"$p->{caption}\" />";
		}
	}
	else
	{

		# gallery listing
		if( $photoconfig{'header'} eq 'myfleet' ) {
			push @ret, Myfleet::Header::display_admin_header('..', "Admin $photoconfig{'title'}: $gallery_name{$gallery}" );
		} else {
			push @ret, $q->start_html( -title=>"Admin: $photoconfig{'title'}: $gallery_name{$gallery}" );
		}

		# GALLERY LIST
		push @ret,
			'<div style="float:right; background:#ffc; padding:10px; vertical-align:top;">',
				# gallery list
				"<h3 style=\"margin-bottom:3px; margin-top:3px;\">Galleries</h3>",
				"<table cellpadding=\"0\" cellspacing=\"0\">";
		foreach my $id ( @gallery_id )
		{
			push @ret, "<tr><td><small>($gallery_count{$id} picture", ($gallery_count{$id} != 1 ? "s)" : ")" ), '</td>',
					"<td>&nbsp;</td><td><small><a href=\"?gallery=$id\" ",
						($gallery_hide{$id} ? 'style="background-color:#ddd"' : '' ),
						">$gallery_name{$id}</a></td></tr>";
		}
		push @ret,
				"</table>",
			'</div>';
	
		push @ret,
				# "<h3 style=\"margin-bottom:5px;\">$photoconfig{'title'}</h3>",
				# "<h2 style=\"margin-bottom:5px;\">$gallery_name{$gallery}</h2>",
				$q->start_multipart_form( -action=>'' ),
				'<b>Gallery Name:</b>',
				'<br/>',
				$q->textfield(-name=>'gallery_name', -size=>30, -maxlength=>30, -default=>$gallery_name{$gallery} ),
				'<br/>',
				'<b>Gallery Description:</b>',
				'<br/>',
				$q->textarea( -name=>'gallery_desc', -cols=>60, -rows=>3, -noscroll=>1, -default=>$gallery_desc{$gallery} ),
				'<br/>',
				$q->checkbox( -name=>'hidden', -checked=>$gallery_hide{$gallery} ),
				'<br/><br/>',
				$q->hidden( -name=>'gallery' ),
				$q->submit( 'Update Gallery' ),
				'</form>',
				"<p>Click on photo to edit - hidden photos have a border around them</p>";
		
		# DISPLAY PHOTOS
		foreach my $p ( photos($gallery,1) )
		{
			my $windowheight = int((400 * $p->{'height'} ) / $p->{'width'} ) + 180;
			my $onClick = "newwin = window.open('?p=$p->{'id'}', 'editphoto', 'width=420,height=$windowheight'); if(window.focus) newwin.focus(); return true;";
			my $border = $p->{hide} ? '5px' : '0px';
			my $padding = $p->{'hide'} ? '1px' : '6px';
			push @ret, "<a href=\"#\" onClick=\"$onClick\"><img src=\"$photoconfig{'photoDirectory'}$p->{id}_tmb.jpg\" height=\"$p->{thumb_height}\" width=\"$p->{thumb_width}\" ALT=\"$p->{caption}\" style=\"border:$border solid #00f; padding:$padding;\" /></a>";
		}
	}
	
	push @ret, $q->end_html;

	return @ret;
}

sub display_wide
{
	my ( $q, $options ) = @_;

	my @ret;


	my $gallery = $q->param('gallery') || 1;

	my @galleries = galleries();
	my $name = 'Gallery Not Found';
	my $description = '';
	foreach my $g ( @galleries )
	{
		if( $gallery eq $g->{'id'} )
		{
			$name = $g->{'name'};
			$description = $g->{'description'};
		}
	}

	push @ret, $q->header;
	if( $photoconfig{'header'} eq 'myfleet' ) {
		push @ret, Myfleet::Header::display_header('Photos','../..', "$photoconfig{'title'}: $name" );
	} else {
		push @ret, $q->start_html( -title=>"$photoconfig{'title'}: $name" );
	}
	
	push @ret,
		"<h2>$name</h2>",
		"<p>$description</p><br/>",
		"<a href=../?gallery=$gallery>regular view</a> <a href=../slide/?gallery=$gallery>slide show</a></p>";

	my @right;
	my @left;
	my $leftheight = 0;
	my $rightheight = 0;
	foreach $p ( photos($gallery) )
	{
		my $newheight = int((400 * $p->{'height'} ) / $p->{'width'} );
		my $html = "<a name=$p->{'id'}><a href=\"$photoconfig{'photoDirectory'}$p->{'id'}.jpg\" target=\"expimg\"><img src=\"$photoconfig{'photoDirectory'}$p->{'id'}_400.jpg\" width=\"400\" height=\"$newheight\" ALT=\"$p->{'caption'}\" border=\"0\"></a><br/>$p->{'caption'} (Original: $p->{'width'}x$p->{'height'})<br/><br/>";

		if ( $leftheight - $rightheight < $newheight ) {
			push @left, $html;
			$leftheight += $newheight;
		} else {
			push @right, $html;
			$rightheight += $newheight;
		}
	}

	push @ret, "<center><table cellpadding=2 cellspacing=2><tr><td valign=top><small>", @left, "<td valign=top><small>", @right, "</table>";

	if( $photoconfig{'header'} eq 'myfleet' ) {
		push @ret, Myfleet::Header::display_footer();
	} else {
    	push @ret, $q->end_html;
	}

	return @ret;
}

sub display_slide
{
	my ( $q, $options ) = @_;

	my @ret;
	my @script;

	my $gallery = $q->param('gallery') || 1;

	my @galleries = galleries();
	my $name = 'Gallery Not Found';
	my $description = '';
	foreach my $g ( @galleries )
	{
		if( $gallery eq $g->{'id'} )
		{
			$name = $g->{'name'};
			$description = $g->{'description'};
		}
	}

	push @ret, 
		$q->header,
		# $q->start_html(-title=>"$photoconfig{'title'}: $name slide show"),
		'<head>',
		qq[
<script type="text/javascript">
var slideShowSpeed = 5000
var crossFadeDuration = 3
var Pic = new Array()
var Caption = new Array()
var preLoad = new Array()
var j = 0
];


	my $first_pic;
	my @photos = photos($gallery);
	if ( @photos )
	{
		my $num = 0;
		foreach my $p ( @photos )
		{
			$first_pic ||= "$photoconfig{'photoDirectory'}/$p->{'id'}_800.jpg";
			push @ret, "Pic[$num]= '$photoconfig{'photoDirectory'}/$p->{'id'}_800.jpg'\n";
			push @ret, "Caption[$num]= \"$p->{'caption'}\"\n";
			$num++;
		}
	}

push @ret,
qq[

function initImages(){
	p = Pic.length
	for (i = 0; i < p; i++){
		preLoad[i] = new Image()
		preLoad[i].src = Pic[i]
	}
}

function resizeImage(){
	if (document.all)
	{
		expectedWidth = document.body.clientWidth - 30;
		if( expectedWidth > 800 ) { expectedWidth = 800; }
	}
	else
	{
		expectedWidth = window.innerWidth - 50;
		if( expectedWidth > 800 ) { expectedWidth = 800; }
	}

	if ( document.images.SlideShow.width != expectedWidth )
	{
		document.images.SlideShow.width = expectedWidth;
	}
}

function runSlideShow(){
	resizeImage()
	t = setTimeout('runSlideShow()', slideShowSpeed)
	if (document.all){
		document.images.SlideShow.style.filter="blendTrans(duration=crossFadeDuration)"
		document.images.SlideShow.filters.blendTrans.Apply()		
	}

	document.images.SlideShow.src = preLoad[j].src
	document.all.caption.innerHTML = Caption[j]
	if (document.all){
		document.images.SlideShow.filters.blendTrans.Play()
	}
	j = j + 1
	if (j > (p-1)) j=0
}
</script>
</head>];

	push @ret,
		'<body onload="initImages(); runSlideShow()">',
		"<h2>$photoconfig{'title'}: $name</h2>",
		"<a href=\"../?gallery=$gallery\">regular view</a> <a href=\"../wide/?gallery=$gallery\">wide view</a><br/><br/>",
		"<img src=\"$first_pic\" name=\"SlideShow\" width=\"800\" />",
		"<br/>",
		"<div id=\"caption\"></div>";

	if( $photoconfig{'header'} eq 'myfleet' ) {
		push @ret, Myfleet::Header::display_footer();
	} 

	push @ret,
		$q->end_html;
	
	return @ret;
}

1;
