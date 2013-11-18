use diagnostics;
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;
use Authen::Captcha;
use File::Path;
use Data::Dumper;

package Myfleet::Roster;

use MyfleetConfig qw(%config);

sub display_roster
{
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header( -expires => 600 ),
		Myfleet::Header::display_header("Roster", '..', "$config{'defaultTitle'} Roster" );


	push @ret,
		"<br/>",
		'<a href="add/">Add me to the List</a><br/>',
		'<a href="delete/">Delete me from the list</a><br/>',
		'<a href="add/?update=1">Update my entry</a><br/>',
		'<br/>';

	my ( $html, $title ) = Myfleet::Util::html( 'roster' );

	push @ret,
		$html,
		'<table border="0" width="100%">',
		'<tr><td colspan="6"><h3>Boats & Owners</h3></td></tr>';

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select distinct hullnumber from person where hullnumber is not null order by hullnumber" ) || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;

	while ( my ( $hullnumber ) = $sth->fetchrow )
	{
		# next if ( ! $hullnumber );
		my $stz = $dbh->prepare( "select id, firstname, lastname, sailnumber, boatname, special, email, city, state from person where hullnumber='" . $hullnumber . "' and type='owner' order by lastname, firstname" ) || die $DBI::errstr;

		$stz->execute || die $DBI::errstr;
		my $first = 1;
		while ( my ( $id, $firstname, $lastname, $sailnumber, $boatname, $special, $email, $city, $state ) = $stz->fetchrow )
		{
			my $obscuredEmail = Myfleet::Util::obscureEmail($email);

			my $catname = $firstname . $lastname;
			$catname =~ s/ //g;
			$catname =~ s/\&//g;
			my $oldname = "";
			push @ret,
				"<tr>",
				( ( ! $first ) ? "<td>&nbsp;</td>" : "<td>#&nbsp;$hullnumber&nbsp;&nbsp;</td>" ),
				( ( $sailnumber && ( $sailnumber ne $hullnumber ) ) ? "<td><small>($sailnumber)</small></td>" : "<td>&nbsp;</td>" ),
				( $boatname ? "<td>$boatname</td>" : "<td>&nbsp;</td>" );

				if ( $catname ne $oldname )
				{
					my $detail = "onClick=\"newwin = window.open('detail/?i=$id','emailwindow','width=500,height=300'); if(window.focus) newwin.focus(); return true;\"";
					push @ret,
						"<td><a href=\"#\" $detail>$firstname $lastname</a>",
						( ( $special ) ? " <small>($special)</small>&nbsp;&nbsp;</td>" : "</td>"),
						( ( ! $email ) ? "<td>&nbsp;</td>" : "<td><a href=\"#\" $detail>$obscuredEmail</a></td>" ),
						'<td>', $city, ', ', uc($state), '</td>';
						$oldname = $catname;
				}
				else
				{
					push @ret, "<td colspan=3>[ see above ]";
				}
				$first = 0;
		}
	}


	$sth = $dbh->prepare("select id, firstname, lastname, special, email, city, state from person where type = ? order by lastname, firstname") || die $DBI::errstr;
	foreach my $type ( 'Other', 'Crew', 'Owner' )
	{
		$sth->execute($type) || die $DBI::errstr;
		if ( $sth->rows ) { push @ret, "<tr><td colspan=\"6\"><br/><h3>${type}s</h3></td></tr>"; }

		while ( my ( $id, $firstname, $lastname, $special, $email, $city, $state ) = $sth->fetchrow )
		{
			my $obscuredEmail = Myfleet::Util::obscureEmail($email);
			my $detail = "onClick=\"newwin = window.open('detail/?i=$id','emailwindow','width=500,height=300'); if(window.focus) newwin.focus(); return true;\"";

			push @ret,
				'<tr><td colspan="3">&nbsp;</td>',
				"<td><a href=\"#\" $detail>$firstname $lastname</a> ",
				( ( $special ) ? " <small>($special)</small>&nbsp;&nbsp;</td>" : "</td>"),
				( ( ! $email ) ? "<td>&nbsp;</td>" : "<td><a href=\"#\" $detail>$obscuredEmail</a></td>" ),
				"<td>$city, $state</td>",
				'</tr>';
		}
	}

	push @ret, '</table>';

	push @ret, Myfleet::Header::display_footer();

	return @ret;
}

sub display_add
{
	my $q = shift;
	my @ret;

	my $p = $q->Vars;
	push @ret,
		$q->header( -expires=>0 ),
		Myfleet::Header::display_header("Roster","../..");

	my $dbh = Myfleet::DB::connect();

	#foreach my $z ( keys %$p ) {
	# 	push @ret, "$z='$p->{$z}'<br>";
	#}
	push @ret, "&laquo; <a href=\"..\">back to roster</a><br/><br/>";

	my @error;
	my @message;

	my $doUpdate = 0;

	if ( $p->{'Continue'} )
	{
		# validate that person exists with that birthday
		if ( ! $p->{'firstname'} ) {
			push @error, "You must specify your first name";
		}
		if ( ! $p->{'lastname'} ) {
			push @error, "You must specify your last name";
		}
		if ( ! $p->{'birthday'} )
		{
			push @error, "You must specify your birthday";
		} elsif( $p->{'birthday'} !~ /^\d{2}-\d{2}-\d{2}$/ ) {
			push @error, "Your birthday should be in the format mm-dd-yy";
		}

		if ( scalar(@error) == 0 )
		{
			# if so try and load the rest of their data
			my $sth = $dbh->prepare("select id, firstname, lastname, street, city, state, zip, phone, email, url, type, special, specialorder, note, boatname, sailnumber, hullnumber from person where firstname = ? and lastname = ? and password = ?") || die $DBI::errstr;
			$sth->execute( $p->{'firstname'}, $p->{'lastname'}, $p->{'birthday'} ) || die $DBI::errstr;
			if( $sth->rows )
			{
				my ( $id, $firstname, $lastname, $street, $city, $state, $zip, $phone, $email, $url, $type, $special, $specialorder, $note, $boatname, $sailnumber, $hullnumber ) = $sth->fetchrow_array();
				$q->param('id', $id );
				$q->param('firstname',$firstname);
				$q->param('lastname',$lastname);
				$q->param('street',$street);
				$q->param('city',$city);
				$q->param('state',$state);
				$q->param('zip',$zip);
				$q->param('phone',$phone);
				$q->param('email',$email);
				$q->param('url',$url);
				$q->param('type',$type);
				$q->param('special',$special);
				$q->param('note',$note);
				$q->param('boatname',$boatname);
				$q->param('sailnumber',$sailnumber);
				$q->param('hullnumber',$hullnumber);
				$q->param('special',$special);
				$q->param('specialorder',$specialorder);
				$doUpdate = 1;
			}
			else
			{
				push @error, "No matching record found.";
			}
		}
	}
	elsif ( $p->{'Add Me'} )
	{
		@error = validate_form( $p );
		if ( scalar(@error) == 0 )
		{
			my $sth = $dbh->prepare("select id, password from person where firstname = ? and lastname = ?") || die $DBI::errstr;
			$sth->execute( $p->{firstname}, $p->{lastname} ) || die $DBI::errstr;
			if( $sth->rows )
			{
				# person exists
				my ( $id, $password ) = $sth->fetchrow_array;
				if( $password eq $p->{birthday} )
				{
					# person exists, and birthday matches so lets just do an update instead
					$p->{'Update Me'} = 'From Add';
					$p->{'id'} = $id;
				}
				else
				{
					push @error, "A person with that name already exists on the roster, but with a different birthday.";
				}
			}
			else
			{
				# go ahead with the add
				my $stz = $dbh->prepare("insert into person ( firstname, lastname, password, street, city, state, zip, phone, email, url, type, hullnumber, note, boatname, sailnumber ) values ( ?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,? )") || die $DBI::errstr;
				$stz->execute( $p->{firstname}, $p->{lastname}, $p->{birthday}, $p->{street}, $p->{city}, $p->{state}, $p->{zip}, $p->{phone}, $p->{email}, $p->{url}, $p->{type}, $p->{hullnumber}, $p->{note}, $p->{boatname}, $p->{sailnumber} ) || die $DBI::errstr;
				push @message, "Your record has been added.";
			}
		}
	}

	if ( $p->{'Update Me'} )
	{
		$doUpdate = 1;
		@error = validate_form( $p );
		if ( scalar(@error) == 0 )
		{
			if( $p->{'admin'} )
			{
				my $stz = $dbh->prepare("update person set street = ?, city = ?, state = ?, zip = ?, phone = ?, email = ?, url = ?, type = ?, hullnumber = ?, note = ?, boatname = ?, sailnumber = ?, special = ?, specialorder = ?, lastupdate = now() where id = ? and firstname = ? and lastname = ? and password = ?" ) || die $DBI::errstr;
				$stz->execute( $p->{street}, $p->{city}, $p->{state}, $p->{zip}, $p->{phone}, $p->{email}, $p->{url}, $p->{type}, ( $p->{hullnumber} eq '' ? undef : $p->{hullnumber} ), $p->{note}, $p->{boatname}, ( $p->{sailnumber} eq '' ? undef : $p->{sailnumber}), $p->{'special'}, $p->{'specialorder'}, $p->{id}, $p->{firstname}, $p->{lastname}, $p->{birthday} ) || die $DBI::errstr;
			}
			else
			{
				my $stz = $dbh->prepare("update person set street = ?, city = ?, state = ?, zip = ?, phone = ?, email = ?, url = ?, type = ?, hullnumber = ?, note = ?, boatname = ?, sailnumber = ?, lastupdate = now() where id = ? and firstname = ? and lastname = ? and password = ?" ) || die $DBI::errstr;
				$stz->execute( $p->{street}, $p->{city}, $p->{state}, $p->{zip}, $p->{phone}, $p->{email}, $p->{url}, $p->{type}, ( $p->{hullnumber} eq '' ? undef : $p->{hullnumber} ), $p->{note}, $p->{boatname}, ( $p->{sailnumber} eq '' ? undef : $p->{sailnumber}), $p->{id}, $p->{firstname}, $p->{lastname}, $p->{birthday} ) || die $DBI::errstr;
			}

			push @message, "Your record has been updated.";
		}
	}

	if( scalar(@error) )
	{
		push @ret, '<font color=red><ul><li>', join('<li>', @error ), '</ul></font>';
	}
	elsif ( scalar(@message) )
	{
		push @ret, '<ul>', join('<li>', @message ), '</ul>';
		return @ret;
	}

	if( ! $doUpdate && $p->{'update'} )
	{
		# form for validating a person for update
		push @ret,
			$q->start_form,
			$q->hidden(-name=>'update'),
			'<h3>First verify who you are</h3>',
			'<table>',
				'<tr>',
					'<td>First Name</td>',
					'<td>', $q->textfield(-name=>'firstname', -size=>30), '</td>',
				'</tr>',
				'<tr>',
					'<td>Last Name</td>',
					'<td>', $q->textfield(-name=>'lastname', -size=>30), '</td>',
				'</tr>',
				'<tr>',
					'<td>Birthday</td>',
					'<td>', $q->textfield(-name=>'birthday', -size=>8), ' (ex. 06-30-75 -- for verification)</td>',
				'</tr>',
			'</table>',
			$q->submit(-name=>'Continue'),
			$q->end_form;
	}
	else
	{
		push @ret,
			$q->start_form,
			( $doUpdate ?
				$q->hidden(-name=>'firstname') .
				$q->hidden(-name=>'lastname') .
				$q->hidden(-name=>'birthday') .
				$q->hidden(-name=>'id')
				: '' ),
			"<h2>", $doUpdate ? "Update Roster" : "Add To Roster", "</h2>",
			"<table>",
				'<tr>',
					'<td colspan="2"><h3>Required</h3></td>',
				'</tr>',
				'<tr>',
					'<td>First Name</td>',
					'<td>', $doUpdate ? '<b>'.$q->param('firstname').'</b>' : $q->textfield(-name=>'firstname', -size=>30), '</td>',
				'</tr>',
				'<tr>',
					'<td>Last Name</td>',
					'<td>', $doUpdate ? '<b>'.$q->param('lastname').'</b>' : $q->textfield(-name=>'lastname', -size=>30), '</td>',
				'</tr>',
				'<tr>',
					'<td>Type</td>',
					'<td>', $q->scrolling_list(-name=>'type', -values=>['Owner','Crew','Other'], -size=>1 ), ' <small>(Either sailnumber, hullnumber, or both is required for owners)</small>', '</td>',
				'</tr>',
				'<tr>',
					'<td>Birthday</td>',
					'<td>', $doUpdate ? '<b>'.$q->param('birthday').'</b>' : $q->textfield(-name=>'birthday', -size=>8) . ' (ex. 06-30-75 -- only for verification of later update or delete)', '</td>',
				'</tr>',
				'<tr>',
					'<td>Street</td>',
					'<td>', $q->textfield(-name=>'street', -size=>30 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>City</td>',
					'<td>', $q->textfield(-name=>'city', -size=>30 ), '</td>',
				'</tr>',
				'<tr>',
				'<td>State</td>',
					'<td>', $q->textfield(-name=>'state', -size=>3 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Postal Code</td>',
					'<td>', $q->textfield(-name=>'zip', -size=>10 ), '</td>',
				'</tr>',
				'<tr>',
					'<td colspan="2"><br/><h3>Optional</h3></td>',
				'</tr>',
				'<tr>',
					'<td>Phone</td>',
					'<td>', $q->textfield(-name=>'phone', -size=>20 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Email</td>',
					'<td>', $q->textfield(-name=>'email', -size=>30 ), ' (will only be displayed to verified humans)</td>',
				'</tr>',
				'<tr>',
					'<td>URL</td>',
					'<td>', $q->textfield(-name=>'url', -size=>30 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Boat Name</td>',
					'<td>',$q->textfield(-name=>'boatname', -size=>30 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Sail Number</td>',
					'<td>', $q->textfield(-name=>'sailnumber', -size=>10 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Hull Number</td>',
					'<td>', $q->textfield(-name=>'hullnumber', -size=>10 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Note</td>',
					'<td>', $q->textarea(-name=>'note', -rows=>4, -cols=>40 ), '</td>',
				'</tr>',
				( $q->param('admin') ? join('',
					'<tr>',
						'<td>Special Title</td>',
						'<td>', $q->textfield(-name=>'special', -size=>30 ), ' Order ', $q->textfield(-name=>'specialorder', -size=>3 ), '<br/><small>(An order other than 0 will cause this person to be displayed in the contacts list on the home page, lowest order first)</small>', '</td>' ) : '' ), 
				'</tr>',

			"</table>",
			$doUpdate ? $q->submit(-name=>'Update Me') : $q->submit(-name=>'Add Me'),
			$q->end_form;
	}
		
	push @ret, Myfleet::Header::display_footer();
			
	return @ret;
}

sub display_delete
{
	my $q = shift;
	my @ret;

	my $p = $q->Vars;
	push @ret,
		$q->header( -expires=>0 ),
		Myfleet::Header::display_header("Roster","../..");

	my $dbh = Myfleet::DB::connect();

	# foreach my $z ( keys %$p ) {
	# 	push @ret, "$z='$p->{$z}'<br>";
	# }
	push @ret, "&laquo; <a href=\"..\">back to roster</a><br/><br/>";

	my @error;
	my @message;
	if ( $p->{'Delete Me'} )
	{
		if ( ! $p->{'firstname'} ) {
			push @error, "You must specify your first name";
		}
		if ( ! $p->{'lastname'} ) {
			push @error, "You must specify your last name";
		}

		if ( ! $p->{'birthday'} )
		{
			push @error, "You must specify your birthday";
		} elsif( $p->{'birthday'} !~ /^\d{2}-\d{2}-\d{2}$/ ) {
			push @error, "Your birthday should be in the format mm-dd-yy";
		}

		if ( scalar(@error) == 0 )
		{
			my $sth = $dbh->prepare("delete from person where firstname = ? and lastname = ? and password = ?") || die $DBI::errstr;
			$sth->execute( $p->{'firstname'}, $p->{'lastname'}, $p->{'birthday'} ) || die $DBI::errstr;
			if ( $sth->rows )
			{
				push @ret, "Your record was deleted.";
				return @ret;
			} else {
				push @ret, "A matching record could not be found.";
			}
		} else {
			push @ret, '<font color=red><li>', join('<li>', @error ), '</font>';
		}
	}



	push @ret,
		$q->start_form,
		"<h2>Delete From Roster</h2>",
		"<table>",
			'<tr>',
				'<td colspan="2"><h3>Required</h3></td>',
			'</tr>',
			'<tr>',
				'<td>First Name</td>',
				'<td>', $q->textfield(-name=>'firstname', -size=>30), '</td>',
			'</tr>',
			'<tr>',
				'<td>Last Name</td>',
				'<td>', $q->textfield(-name=>'lastname', -size=>30), '</td>',
			'</tr>',
			'<tr>',
				'<td>Birthday</td>',
				'<td>', $q->textfield(-name=>'birthday', -size=>8), ' (ex. 06-30-75 -- for verification)</td>',
			'</tr>',
		"</table>",
		$q->submit(-name=>'Delete Me'),
		$q->end_form;
		
	push @ret, Myfleet::Header::display_footer();
			
	return @ret;
}

sub display_detail
{
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header( -expires => 0 );

	$q->param('i') || $q->param('e') || die "no user id specified.";

	my $output_folder = $ENV{'DOCUMENT_ROOT'} . '/captcha/';
	my $data_folder = '/usr/local/apache2/captcha/' . $ENV{'SERVER_NAME'};
	if( ! -e $data_folder ) { File::Path::mkpath($data_folder); }
	my $captcha = Authen::Captcha->new();
	$captcha->data_folder( $data_folder );
	$captcha->output_folder( $output_folder );

	my $dbh = Myfleet::DB::connect();
	my $sth;

	my $mode = 'roster';
	my $emailAddress;

	if( $q->param('e') )
	{
		my $sti = $dbh->prepare('select email from email where email_id = ?') || die $DBI::errstr;
		$sti->execute( $q->param('e') ) || die $DBI::errstr;
		( $emailAddress ) = $sti->fetchrow_array();

		$sth = $dbh->prepare("select firstname, lastname, street, city, state, zip, phone, email, url, type, special, note, boatname, sailnumber, hullnumber from person where email = ?") || die $DBI::errstr;
		$sth->execute( $emailAddress ) || die $DBI::errstr;
		if( ! $sth->rows ) { $mode = 'email'; }
	}
	else
	{
		$sth = $dbh->prepare("select firstname, lastname, street, city, state, zip, phone, email, url, type, special, note, boatname, sailnumber, hullnumber from person where id = ?") || die $DBI::errstr;
		$sth->execute( $q->param('i') ) || die $DBI::errstr;
		$sth->rows || die "Can't find user with that id.";
	}

	my ( $firstname, $lastname, $street, $city, $state, $zip, $phone, $email, $url, $type, $special, $note, $boatname, $sailnumber, $hullnumber ) = $sth->fetchrow;

	push @ret, $q->start_html("$firstname $lastname");
	push @ret, "&laquo; <a href=\"javascript:self.close()\">close window</a><br/><br/>";

	if( $q->param('md5') && $q->param('code') && $captcha->check_code($q->param('code'),$q->param('md5')) == 1 )
	{
		if( $mode eq 'roster' )
		{
			my $ad2 = $street;
			$ad2 =~ s/ /\+/g;
			$ad2 =~ s/\#\d+//g;
			my $ad3 = $city . '%2C ' . $state . ' ' . $zip;
			$ad3 =~ s/ /\+/g;
			$url =~ s/http:\/\///;
		
			push @ret,
				( $special ? "<b>$special</b><br/>" : "" ),
				"<i>$lastname, $firstname</i>",
				( $type ne "Other" ? "<br/>$type" : "" ),
				( $type eq "Owner" && $hullnumber ? " #$hullnumber" : "" ),
				( $sailnumber && $sailnumber ne $hullnumber ? " (sail #$sailnumber)" : "" ),
				"<br/>",
				( $type eq "Owner" && $boatname ? "$boatname<br/>" : "" ),
				( $email ? "<a href=\"mailto:$email\">$email</a><br/>" : '' ),
 				"<a target=other href='http://maps.google.com/?q=$ad2+$ad3'>$street</a><br/>",
				"$city, $state $zip<br/>",
				( $phone ? "$phone<br/>" : "" ),
				( $url ? "<a target=\"_new\" href=\"http://$url\">$url</a><br/>" : "" ),
				"<br/>",
				( $note ? "$note" : "" );
		} else {
			push @ret, 
				"<a href=\"mailto:$emailAddress\">$emailAddress</a>";
		}
	}
	else
	{
	 	my $md5sum = $captcha->generate_code(4);


		if( $q->param('md5') && $q->param('code') )
		{
			push @ret, '<span style="color:#f00;">Text does not match, please try again.</span><br/>';
			$q->param('md5',$md5sum); $q->param('code','');
		}

		if( $mode eq 'roster' )
		{
			push @ret,
				"<b>Fetching information for $firstname $lastname</b><br/><small>(Please confirm that you are human)</small>";
		} else  {
			my $obscuredEmail = Myfleet::Util::obscureEmail($emailAddress);

			push @ret,
				"<b>Fetching full email address for $obscuredEmail</b><br/><small>(Please confirm that you are human)</small>";
		}

		push @ret,
				'<form method="post" action="">',
					$q->param('i') ? $q->hidden( -name=>'i' ) : $q->hidden( -name=>'e' ),
					$q->hidden( -name=>'md5', -value=>$md5sum ),
					'<div style="height:41px; line-height:41px; vertical-align:middle; border:1px solid #ccc; padding:3px; width:400px; text-align:center;">',
						 "<img src=\"/captcha/$md5sum.png\" style=\"width:100px; height:35px; vertical-align:middle; margin-right:10px;\" /> ",
						'Enter distorted text: ',
						'<input name="code" size="4" /> ',
						'<input type="submit" value="Submit" />',
					'</div>',
				'</form>';
	}
	push @ret, Myfleet::Header::display_footer();

	return @ret;
}

sub admin_roster
{
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header,
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} Roster Editor");

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, firstname, lastname, password, street, city, state, zip, phone, email, url, type, special, note, boatname, sailnumber, hullnumber from person order by lastname, firstname") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;
	while ( my ( $id, $firstname, $lastname, $birthday, $street, $city, $state, $zip, $phone, $email, $url, $type, $special, $note, $boatname, $sailnumber, $hullnumber ) = $sth->fetchrow )
	{
		my $ad2 = $street;
		$ad2 =~ s/ /\+/g;
		$ad2 =~ s/\#\d+//g;
		my $ad3 = $city . '%2C ' . $state . ' ' . $zip;
		$ad3 =~ s/ /\+/g;
		$url =~ s/http:\/\///;
		
		push @ret,
			( $special ? "<b>$special</b><br/>" : "" ),
			"<i>$lastname, $firstname</i> [ <a href=\"add/?Continue=admin&i=$id&birthday=$birthday&firstname=$firstname&lastname=$lastname\">Update</a> <a href=\"delete/?i=$id&birthday=$birthday&firstname=$firstname&lastname=$lastname\">Delete</a> ]",
			( $type ne "Other" ? "<br/>$type" : "" ),
			( $type eq "Owner" && $hullnumber ? " #$hullnumber" : "" ),
			( $sailnumber && $sailnumber ne $hullnumber ? " (sail #$sailnumber)" : "" ),
			"<br/>",
			( $type eq "Owner" && $boatname ? "$boatname<br/>" : "" ),
			( $email ? "<a href=\"mailto:$email\">$email</a><br/>" : '' ),
 			"<a target=other href='http://maps.google.com/?q=$ad2+$ad3'>$street</a><br/>",
			"$city, $state $zip<br/>",
			( $phone ? "$phone<br/>" : "" ),
			( $url ? "<a href=\"http://$url\">$url</a><br/>" : "" ),
			"<br/>",
			( $note ? "$note<br/><br/>" : "" );
	}
	push @ret, Myfleet::Header::display_footer();

	return @ret;
}

sub display_contacts
{
	my ( $thresh ) = @_;
	$thresh ||= 5;

	my @ret;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, firstname, lastname, special, email from person where specialorder <= ? and specialorder > 0 order by specialorder") || die $DBI::errstr;
	$sth->execute( $thresh ) || die $DBI::errstr;
	push @ret, '<table cellpadding="2" cellspacing="0" width="100%">';
	while ( my ( $id, $firstname, $lastname, $special, $email ) = $sth->fetchrow_array )
	{
		my $detail = "onClick=\"newwin = window.open('../roster/detail/?i=$id','emailwindow','width=500,height=300'); if(window.focus) newwin.focus(); return true;\"";

		push @ret,
			"<tr>",
			"<td><a href=\"#\" $detail><img src=\"/i/mail.gif\" border=\"0\" alt=\"Contact Information for $firstname $lastname\"></a></td>",
			"<td><small><b>$special</b></small></td>",
			"<td align=right><small><a href=\"#\" $detail>$firstname&nbsp;$lastname</a></small></td>",
			"</tr>\n";
	}
	push @ret, "</table>";

	return @ret;
}

sub validate_form
{
	my $p = shift;
	my @error;

	# validate all the entries
	if ( ! $p->{'firstname'} ) {
		push @error, "You must specify your first name.";
	} elsif( $p->{'firstname'} !~ /^[\w\s\.]+$/ ) {
		push @error, "Please use only letters, spaces, and periods for your first name.";
	}

	if ( ! $p->{'lastname'} ) {
		push @error, "You must specify your last name.";
	} elsif( $p->{'lastname'} !~ /^[\w\s\.]+$/ ) {
		push @error, "Please use only letters, spaces, and periods for your last name.";
	}

	if ( ! $p->{'street'} ) {
		push @error, "You must specify your street address.";
	} elsif( $p->{'street'} !~ /^[\w\s\.\,\#]+$/ ) {
		push @error, "Please use only letters, spaces, periods, and # in your street address.";
	}

	if ( ! $p->{'city'} ) {
		push @error, "You must specify your city.";
	} elsif( $p->{'city'} !~ /^[\w\s\.]+$/ ) {
		push @error, "Please use only letters, spaces, and periods in your city name.";
	}

	if ( ! $p->{'state'} ) {
		push @error, "You must specify your state.";
	} elsif( $p->{'state'} !~ /\w{2,3}/ ) {
		push @error, "Please use a two or three letter abbreviation for you state";
	}

	if ( ! $p->{'zip'} ) {
		push @error, "You must specify your postal code.";
	} elsif( $p->{'zip'} !~ /^[\w\s]+$/ ) {
		push @error, "Please use letters and numbers to specify your postal code";
	}

	if ( ! $p->{'birthday'} ) {
		push @error, "You must specify your birthday.";
	} elsif( $p->{'birthday'} !~ /^\d{2}-\d{2}-\d{2}$/ ) {
		push @error, "Your birthday should be in this format: mm-dd-yy";
	}

	if( $p->{'email'} ne '' && $p->{'email'} !~ /^([a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-])+/ )
	{
		push @error, "The email address you entered appears invalid.";
	}

	if( $p->{'type'} eq 'Owner' )
	{
		if( $p->{'sailnumber'} eq '' && $p->{'hullnumber'} eq '' )
		{
			push @error, "Please specify either your hullnumber, sailnumber, or both.";
		}
	}

	return @error;
}

1;
