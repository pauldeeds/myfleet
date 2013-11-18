use strict;
use diagnostics;

use CGI;
use DBD::mysql;
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;
use Geo::Gpx;
use Data::Dumper;

package Myfleet::GPS;

use MyfleetConfig qw(%config);
use POSIX qw(strftime);
use URI::Escape qw(uri_escape);

sub all_gps
{
	my $dbh = Myfleet::DB::connect() || die "could not connect to database";
	my $sth = $dbh->prepare("select gps_id, regattaid, filename, unix_timestamp(start_time) as start_time, unix_timestamp(end_time) as end_time, boat, description, unix_timestamp(upload_date) as upload_date from gps order by upload_date DESC") || die $DBI::errstr;
	$sth->execute();
	my @gps;
	while( my $track = $sth->fetchrow_hashref ) {
		push @gps, $track;
	}
	return @gps;
}

sub gps_by_regatta 
{
	my $regattaid = shift;

	my $dbh = Myfleet::DB::connect() || die "could not connect to database";
	my $sth = $dbh->prepare("select gps_id, regattaid, filename, unix_timestamp(start_time) as start_time, unix_timestamp(end_time) as end_time, boat, description, unix_timestamp(upload_date) as upload_date from gps WHERE regattaid = ? order by upload_date DESC") || die $DBI::errstr;
	$sth->execute( $regattaid );
	my @gps;
	while( my $track = $sth->fetchrow_hashref ) {
		push @gps, $track;
	}

	return @gps;
}

sub insert_gps
{
	my ( $regattaid, $filename, $start_time, $end_time, $boat, $description ) = @_;

	my $dbh = Myfleet::DB::connect() || die "could not connect to database";
	my $sti = $dbh->prepare("insert into gps ( regattaid, filename, start_time, end_time, boat, description, upload_date ) values ( ?,?,from_unixtime(?),from_unixtime(?),?,?,now() )" ) || die $DBI::errstr;
	$sti->execute( $regattaid, $filename, $start_time, $end_time, $boat, $description ) || die $DBI::errstr;
	my $gps_id = $sti->{mysql_insertid};
	# rename( "$config{'trackDirectory'}/tmp", "$photoconfig{'trackDirectory'}/${gps_id}." );
	return $gps_id;
}

sub update_gps_time
{
	my ( $gps_id, $start_time, $end_time ) = @_;

	my $dbh = Myfleet::DB::connect() || die "could not connect to database";
	my $sti = $dbh->prepare("update gps set start_time=from_unixtime(?), end_time=from_unixtime(?) where gps_id = ?" ) || die $DBI::errstr;
	$sti->execute( $start_time, $end_time, $gps_id ) || die $DBI::errstr;
	return $gps_id;
}

sub update_gps_boat
{
	my ( $gps_id, $regattaid, $boat, $description ) = @_;

	my $dbh = Myfleet::DB::connect() || die "could not connect to database";
	my $sti = $dbh->prepare("update gps set regattaid=?, boat=?, description=? where gps_id = ?" ) || die $DBI::errstr;
	$sti->execute( $regattaid, $boat, $description, $gps_id ) || die $DBI::errstr;
	return $gps_id;
}

sub gps_url
{
	my $id = shift;
	my $regatta = shift;
	my $day = shift;
	my $boatname = shift;
	my $format = shift;

	$regatta =~ s/ /\-/g;
	$boatname =~ s/ /\-/g;

	return "/track/$id-" . uri_escape($regatta) . '-' . uri_escape($day) . '-' . uri_escape($boatname) . ".$format";
}

sub gps_regatta_url
{
	my $regattaid = shift;
	my $regatta = shift;
	my $day = shift;

	$regatta =~ s/ /\-/g;

	return '/track/r' . $regattaid . '-' . uri_escape($regatta) . '-' . uri_escape($day) . ".kmz";
}

sub regex_filecopy
{
	my $in_file = shift;
	my $out_file = shift;
	my $search = shift;
	my $replace = shift;

	open(READ,"<$in_file") || die "can't open file $in_file for reading";
	open(WRITE,">$out_file") || die "can't open file $out_file for writing";

	while (my $str = <READ>)
	{
		$str =~ s/$search/$replace/;
		print WRITE $str;
	}

	close(READ);
	close(WRITE);
}

sub regex_filecopy_multi
{
	my $in_file = shift;
	my $out_file = shift;
	my $search = shift; # array ref
	my $replace = shift; # array ref
	my $debug = shift;

	local $/=undef;
	open(READ,"<$in_file") || die "can't open file $in_file for reading";
	my $contents = <READ>;
	close(READ);

	for ( my $i=0; $i < scalar(@{$search}); $i++)
	{
		if ( $debug && $contents =~ /($search->[$i])/ms )
		{
			print "found match: $1\n";
		}
		$contents =~ s/$search->[$i]/$replace->[$i]/ms;
	}

	open(WRITE,">$out_file") || die "can't open file $out_file for writing";
	print WRITE $contents;
	close(WRITE);
}

sub make_regatta_kml
{
	my $regattaid = shift;
	my $regatta = Myfleet::Regatta::regatta($regattaid);
	my @gps_by_regatta = gps_by_regatta($regattaid);

	my @boats;
	if (scalar(@gps_by_regatta)>0)
	{
		my %tmp_gpx;
		foreach my $gps (@gps_by_regatta)
		{
			my $day = strftime("%a",localtime($gps->{'start_time'}));
			my $in_file = "$config{'trackDirectory'}/$gps->{gps_id}.gpx";
			my $out_file = "$config{'trackDirectory'}/$regattaid.$day.$gps->{gps_id}.gpx";

			regex_filecopy($in_file,$out_file,'<name>(.*?)<\/name>',"<name>$gps->{boat}<\/name>");

			push @boats, $gps->{boat};
			push @{$tmp_gpx{$day}}, $out_file;
		}

		my @colors =  (
			'ffffff00',
  			'ff000000',
  			'ffff0000',
  			'ffff00ff',
  			'ff808080',
  			'ff008000',
  			'ff00ff00',
  			'ff000080',
  			'ff800000',
  			'ff008080',
  			'ff800080',
  			'ff0000ff',
  			'ffc0c0c0',
  			'ff808000',
  			'ffffffff',
  			'ff00ffff',
		);

		my @style;
		foreach my $boat (@boats)
		{
			my $boatid = $boat;
			$boatid =~ s/\s+//; # no whitespace
			my $boatcolor = pop @colors;
		
			my $boatstyle = <<STYLE;
    <Style id="${boatid}_n">
      <LineStyle>
        <color>${boatcolor}</color>
        <width>2</width>
      </LineStyle>
      <IconStyle>
        <Icon>
          <href>http://earth.google.com/images/kml-icons/track-directional/track-0.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="${boatid}_h">
      <LineStyle>
        <color>${boatcolor}</color>
        <width>4</width>
      </LineStyle>
      <IconStyle>
        <scale>1.2</scale>
        <Icon>
          <href>http://earth.google.com/images/kml-icons/track-directional/track-0.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <StyleMap id="${boatid}">
      <Pair>
        <key>normal</key>
        <styleUrl>#${boatid}_n</styleUrl>
      </Pair>
      <Pair>
        <key>highlight</key>
        <styleUrl>#${boatid}_h</styleUrl>
      </Pair>
    </StyleMap>
STYLE
			push @style, $boatstyle;
		}

		my @rm; # tmp files to cleanup
		foreach my $day ( keys %tmp_gpx )
		{
			my $fileparam = '';
			foreach my $file ( @{$tmp_gpx{$day}} )
			{
				# my $color = pop @colors;
				# my $kmlfile = $file;
				# $kmlfile =~ s/\.gpx$/\.kml/;
				# `gpsbabel -i gpx -f $file -o kml,line_width=2,line_color=$color,points=1,lines=1,track=1 -F $kmlfile.tmp`;
				$fileparam .= "-f $file ";
				push @rm, $file;
			}
			my $tmpkml = "$config{'trackDirectory'}r$regattaid-$day.tmp.kml";
			my $finalkml = "$config{'trackDirectory'}r$regattaid-$day.kml";
			my $kmz = "$config{'trackDirectory'}r$regattaid-$day.kmz";
			`gpsbabel -i gpx $fileparam -o kml,track=1,points=0,lines=0 -F $tmpkml`;

			my $regex_search;
			my $regex_replace;
			my $regex_multi;
			# KML file name fix up
			push @{$regex_search}, '<name>GPS device<\/name>';
			push @{$regex_replace}, "<name>$regatta->{'name'} $regatta->{'year'} $day<\/name>";
			push @{$regex_multi}, '0';

			# KML style fix up
			push @{$regex_search}, '\t*<Style.*<\/Style>';
			push @{$regex_replace}, join('',@style);
			push @{$regex_multi}, '1';

			foreach my $boat (@boats)
			{
				my $boatid = $boat;
				$boatid =~ s/\s+//; # no whitespace

				push @{$regex_search}, "<name>$boat<\/name>\\n\\s+<styleUrl>#multiTrack<\/styleUrl>";
				push @{$regex_replace}, "<name>$boat<\/name><styleUrl>#$boatid<\/styleUrl>";
				push @{$regex_multi}, '0';
			}

			regex_filecopy_multi($tmpkml,$finalkml,$regex_search,$regex_replace);

			push @rm, $tmpkml;
			`zip $kmz $finalkml`;

			foreach my $fn ( @rm )
			{
				if ( -e $fn )
				{
					unlink($fn);
				}
			}
		}
	}
}

sub display_page
{
	my ( $q, $options ) = @_;

	my @ret;

	# DO UPLOAD PROCESSING
	my $file = $q->upload('upload');
	my $info = $q->uploadInfo($file);

	my $original_extension = '';
	my $original_filename = '';
	if ($info->{'Content-Disposition'} =~ /filename=\"(.*)\"/)
	{
		$original_filename = $1;
		if ($original_filename =~ /.([a-zA-Z0-9]+)$/)
		{
			$original_extension = $1;
		}
	}

	# processes additional information submission
	if ( $q->param('gpsid') )
	{
		update_gps_boat($q->param('gpsid'), $q->param('regattaid'), $q->param('boatname'), $q->param('notes'));
		make_regatta_kml($q->param('regattaid'));
	}

	if ( $file && ($original_extension != 'kml' || $original_extension != 'gpx') )
	{
		push @ret, "<div class=\"error\">Unrecognized file format, please upload a gpx or kml file.</div>";
	}
	elsif ( $file )
	{
		# do initial insert so we can name the file
		my $gps_id = insert_gps( 0, $original_filename, 0, 0, '', '' );

		my $filename = "$config{'trackDirectory'}/$gps_id";
		open( OUTFILE,">$filename.$original_extension" ) || die "can't write to file $filename.$original_extension";
		my $in;
		my $buffer;
		while( $in = read($file,$buffer,1024)) {
			print OUTFILE $buffer;
		}
		close( OUTFILE );
		close( $file );

		# convert to GPX or KML
		if ($original_extension eq 'kml' )
		{
			`gpsbabel -i kml -f $filename.$original_extension -o gpx -F $filename.gpx`;
		}
		elsif ($original_extension eq 'gpx' )
		{
			`gpsbabel -i gpx -f $filename.$original_extension -o kml,track=1,line_width=3 -F $filename.kml`;
		}

		# zip up the KML
		`zip $filename.kmz $filename.kml`;

		# DETAILS FORM
		my $gpx = Geo::Gpx->new(input=>"$filename.gpx");
		my ( $maxtime, $mintime ) = (0,2147483647);
		my $iter = $gpx->iterate_points();
		while (my $pt = $iter->())
		{
			if ($pt->{'time'} < $mintime ) { $mintime = $pt->{'time'}; }
			if ($pt->{'time'} > $maxtime ) { $maxtime = $pt->{'time'}; }
		}

		update_gps_time($gps_id,$mintime,$maxtime);

		my @regatta_id;
		my %regatta_name;
		my $regatta_min = ( $maxtime == 0 ? time - (86400*90) : $mintime );
		my $regatta_max = ( $maxtime == 0 ? time : $maxtime );
			
		foreach my $r ( Myfleet::Regatta::regattas_by_daterange($regatta_min,$regatta_max) )
		{
			push @regatta_id, $r->{'id'};
			$regatta_name{$r->{'id'}} = $r->{'name'};
		}

		my $start_date = strftime "%Y-%m-%d %H:%M", localtime($mintime);
		my $end_date = strftime "%Y-%m-%d %H:%M", localtime($maxtime);

		if ( $q->cookie('boatname') ) { $q->param('boatname',$q->cookie('boatname')); }

		push @ret,
			# upload image form
			'<div id="upload_box" style="background-color:#ccc;padding:10px">',
				"The file $original_filename was uploaded sucessfully.<br/>",
				( $mintime == 0 ?
						"<span style=\"color:red;font-weight:bold\">This file does not seem to contain time data for the individual points!</span>" :
					"It contains data from <strong>$start_date</strong> to <strong>$end_date</strong>" ),
				'<br/>',
				"<h3 id=\"upload\">Please enter some additional information about this track ...</h3>",
				$q->start_multipart_form( -action=>'' ),
					'<strong>Boat Name</strong><br/>',
					$q->textfield(-name=>'boatname',-size=>20, -maxlength=>50),
					'<br/>',
					'<strong>Regatta</strong><br/>',
					$q->scrolling_list(
						-values=>\@regatta_id,
						-name=>'regattaid',
						-labels=>\%regatta_name,
						-size=>1
					),
					'<br/>',
					'<strong>Brief Notes (optional)</strong><br/>',
					$q->textfield(-name=>'notes',-size=>80, -maxlength=>300),
					'<br/>',
					$q->hidden(-name=>'gpsid',-value=>$gps_id),
					$q->submit(),
				'</form>',
			'</div>';
	}
	# DO ADDITIONAL INFO PROCESSING
	else
	{
		push @ret,
				# UPLOAD FORM
				'<h3>Upload a File</h3>',
				$q->start_multipart_form( -action=>'/gps/' ),
					$q->filefield(-name=>'upload', -size=>10, -onchange=>'this.form.submit()' ),
					' (GPX or KML supported, GPX preferred)<br/>',
				'</form>',
				'<h3>GPS Tracks</h3>',
				'<table border="1" cellpadding="2" cellspacing="0" width="100%">',
					display_gps_tablehead(),
					'<tbody>';

		foreach my $gps ( all_gps() )
		{
			push @ret, display_gps_row($gps);
		}

		push @ret,
					'</tbody>',
				'</table>';
	}

	return @ret;
}

sub display_regatta_gps
{
	my $q = shift;
	my $regatta_id = shift;
	if ( ! $config{'trackDirectory'} ) { return ''; }

	my @ret;
	my @gps_by_regatta = gps_by_regatta($regatta_id);
	my $regatta = Myfleet::Regatta::regatta($regatta_id);


	push @ret,
		'<table border="0" cellpadding="4" cellspacing="0" width="100%">',
			'<tr><td bgcolor="blue"><big><font color="white">GPS Tracks</font></big></td></tr>',
			'<tr><td>',
				'<a href="/gps/" class="mbaction">[ Upload a GPS Track ]</a>';

	foreach my $regatta_file ( <$config{'trackDirectory'}/r$regatta_id*.kmz> )
	{
		if ($regatta_file =~ /\-([a-zA-Z]{3})\.kmz$/)
		{
			my $day = $1;
			push @ret, "<br/>Combined $day:",
						' <a href="' . gps_regatta_url($regatta_id,$regatta->{'name'},$day) . '">KML (Google Earth)</a>',
						' <a href="http://maps.google.com/?q=http://' . $config{'domain'} . gps_regatta_url($regatta_id,$regatta->{'name'},$day) . '">Google Map</a>',
		}
	}

	if (scalar(@gps_by_regatta) > 0 )
	{
		push @ret,
				'<table border="1" cellpadding="2" cellspacing="0">',
					display_gps_tablehead(1),
					'<tbody>';

		foreach my $gps ( @gps_by_regatta )
		{
			push @ret, display_gps_row($gps,1);
		}

		push @ret,
					'</tbody>',
				'</table>';
	}

	push @ret,
		'</td></tr>',
		'</table>';

	return @ret;
}

sub display_gps_tablehead
{
	my $regatta_context = shift;
	my @ret;

	push @ret,
		'<thead>',
			'<tr>',
				( $regatta_context ? '<th>Day/Race</th>' : '<th>Regatta</th>' ),
				'<th>Boat</th>',
				'<th>Files</th>',
				'<th>Notes</th>',
				'<th>Start Time</th>',
				'<th>End Time</th>',
				'<th>Upload Date</th>',
			'</tr>',
		'</thead>';

	return @ret;
}

sub display_gps_row
{
	my $gps = shift;
	my $regatta_context = shift;

	my @ret;
	my $regatta = Myfleet::Regatta::regatta($gps->{'regattaid'});
	my $day = strftime("%a",localtime($gps->{'start_time'}));

	my $regatta_name = '';
	if ($regatta_context)
	{
		$regatta_name = ( $gps->{'start_time'} ? strftime('%A',localtime($gps->{'start_time'})) : '' );
	}
	else
	{
		$regatta_name = "<a href=\"/schedule/$regatta->{'id'}\">$regatta->{'name'} $regatta->{'year'}</a> " . ( $gps->{'start_time'} ? strftime('%A',localtime($gps->{'start_time'})) : '' );
	}
	push @ret,
		'<tr>',
			'<td>', $regatta_name, '</td>',
			'<td>',$gps->{'boat'},'</td>',
			'<td>',
				'<a href="' . gps_url($gps->{'gps_id'},$regatta->{'name'},$day,$gps->{'boat'},'gpx'), '">GPX</a>',
				' <a href="' . gps_url($gps->{'gps_id'},$regatta->{'name'},$day,$gps->{'boat'},'kmz'), '">KML</a>',
			'</td>',
			'<td>', ( $gps->{'description'} ? $gps->{'description'} : '&nbsp;' ),'</td>',
			'<td>', ( $gps->{'start_time'} ? strftime("%Y-%m-%d %H:%M",localtime($gps->{'start_time'})) : 'unknown' ), '</td>',
			'<td>', ( $gps->{'start_time'} ? strftime("%Y-%m-%d %H:%M",localtime($gps->{'end_time'})) : 'unknown' ), '</td>',
			'<td>', strftime("%Y-%m-%d %H:%M",localtime($gps->{'upload_date'})), '</td>',
		'</tr>';

	return @ret;
}

1;
