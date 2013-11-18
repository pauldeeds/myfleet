use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Myfleet::Header;
use Myfleet::DB;
use Myfleet::Util;
use Authen::Captcha;
use File::Path;
use Data::Dumper;

use diagnostics;
use strict;

package Myfleet::Crew;

use MyfleetConfig qw(%config);

sub display_roster
{
	my ( $q ) = @_;
	my @ret;

	push @ret,
		$q->header( -expires => 600 ),
		Myfleet::Header::display_header("Crew List", '..', "$config{'defaultTitle'} Crew List" );

	push @ret,
		"<br/>",
		'<a href="add/">Add me to the List</a><br/>',
		'<a href="delete/">Delete me from the list</a><br/>',
		'<a href="add/?update=1">Update my entry</a><br/>',
		'<br/>';

	my ( $html, $title ) = Myfleet::Util::html( 'crewlist' );
	push @ret, $html;

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, firstname, lastname, city, state, password, phone, email, height, weight, positions, note, date_format(lastupdate, '%m-%d-%y') from crew order by lastupdate desc") || die $DBI::errstr;
	$sth->execute || die $DBI::errstr;

	if( ! $sth->rows )
	{
		push @ret,
			'<br/>Crew list is empty.  You can be the first!<br/>';
	}
	else
	{
		push @ret,
			'<table border="1" cellpadding="4" cellspacing="0" width="100%">',
				'<tr>',
					'<th>Name</th>',
					'<th>Email</th>',
					'<th>Phone</th>',
					'<th>Positions</th>',
					'<th>Location</th>',
					'<th>Height</th>',
					'<th>Weight</th>',
					# '<th>Age</th>',
					'<th>Updated</th>',
				'</tr>';


		while ( my ( $id, $firstname, $lastname, $city, $state, $birthday, $phone, $email, $height, $weight, $positions, $note, $lastupdate  ) = $sth->fetchrow )
		{
				my $obscuredEmail = Myfleet::Util::obscureEmail( $email );
				my $detail = "onClick=\"window.open('detail/?i=$id','emailwindow','width=500,height=300'); return true;\"";
				my $dHeight = int($height/12) . "'" . $height % 12 . '"';
				my ( $bmonth, $bday, $byear ) = split /-/, $birthday;
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
				$mon++;
				my $age = ( $year - $byear );
				if( $mon < $bmonth || ( $mon == $bmonth && $mday < $bday ) ) { $age--; }
				
				push @ret,
					'<tr>',
						"<td><a href=\"#\" $detail>$firstname $lastname</a></td>",
						"<td><a href=\"#\" $detail>$obscuredEmail</a></td>",
						"<td>$phone</td>",
						'<td>', join(', ', split(',',$positions)), '</td>',
						"<td>$city, " . uc($state) . '</td>',
						"<td>$dHeight</td>",
						"<td>$weight lbs</td>",
						# "<td>$age</td>",
						"<td>$lastupdate</td>",
					'</tr>';
		}

		push @ret, '</table>';
		push @ret, '<div style="margin-top:0.3em; font-size:small;"><i>(Click name for full email address and additional notes)</i></div>';
	}

	push @ret, Myfleet::Header::display_footer();

	return @ret;
}

sub display_add
{
	my $q = shift;
	my @ret;

	my $p = $q->Vars;
	$p->{'positions'} =~ s/\0/,/g;

	push @ret,
		$q->header( -expires=>0 ),
		Myfleet::Header::display_header("Crew List","../..");

	my $dbh = Myfleet::DB::connect();

	#foreach my $z ( keys %$p ) {
	# 	push @ret, "$z='$p->{$z}'<br/>";
	#}
	push @ret, "&laquo; <a href=\"..\">back to crew list</a><br/><br/>";

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
			my $sth = $dbh->prepare("select id, firstname, lastname, city, state, phone, email, height, weight, positions, note from crew where firstname = ? and lastname = ? and password = ?") || die $DBI::errstr;
			$sth->execute( $p->{'firstname'}, $p->{'lastname'}, $p->{'birthday'} ) || die $DBI::errstr;
			if( $sth->rows )
			{
				my ( $id, $firstname, $lastname, $city, $state, $phone, $email, $height, $weight, $positions, $note ) = $sth->fetchrow_array();

				$q->param(-name=>'id',-value=>$id);
				$q->param(-name=>'firstname',-value=>$firstname);
				$q->param(-name=>'lastname',-value=>$lastname);
				$q->param(-name=>'city',-value=>$city);
				$q->param(-name=>'state',-value=>$state);
				$q->param(-name=>'phone',-value=>$phone);
				$q->param(-name=>'email',-value=>$email);
				$q->param(-name=>'height',-value=>$height);
				$q->param(-name=>'weight',-value=>$weight);
				$q->param(-name=>'positions',-values=>[split(/,/,$positions)]),
				$q->param(-name=>'note',-value=>$note);
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
			my $sth = $dbh->prepare("select id, password from crew where firstname = ? and lastname = ?") || die $DBI::errstr;
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
					push @error, "A person with that name already exists on the crew list, but with a different birthday.";
				}
			}
			else
			{
				# go ahead with the add
				my $stz = $dbh->prepare("insert into crew ( firstname, lastname, password, city, state, phone, email, height, weight, positions, note ) values ( ?,?,?,?,?, ?,?,?,?,?, ? )") || die $DBI::errstr;
				$stz->execute( $p->{firstname}, $p->{lastname}, $p->{birthday}, $p->{city}, $p->{state}, $p->{phone}, $p->{email}, $p->{height}, $p->{weight}, $p->{positions}, $p->{note} ) || die $DBI::errstr;
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
			my $stz = $dbh->prepare("update crew set city = ?, state = ?, phone = ?, email = ?, height = ?, weight = ?, positions = ?, note = ?, lastupdate = now() where id = ? and firstname = ? and lastname = ? and password = ?" ) || die $DBI::errstr;
			$stz->execute( $p->{city}, $p->{state}, $p->{phone}, $p->{email}, $p->{height}, $p->{weight}, $p->{positions}, $p->{note}, $p->{id}, $p->{firstname}, $p->{lastname}, $p->{birthday} ) || die $DBI::errstr;

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
			"<h2>", $doUpdate ? "Update Crew List" : "Add To Crew List", "</h2>",
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
					'<td>Birthday</td>',
					'<td>', $doUpdate ? '<b>'.$q->param('birthday').'</b>' : $q->textfield(-name=>'birthday', -size=>8) . ' (ie. 06-30-75)', '</td>',
				'</tr>',
				'<tr>',
					'<td>City</td>',
					'<td>', $q->textfield(-name=>'city', -size=>30 ), '</td>',
				'</tr>',
				'<tr>',
				'<td>State</td>',
					'<td>', $q->textfield(-name=>'state', -size=>2 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Day Phone</td>',
					'<td>', $q->textfield(-name=>'phone', -size=>20 ), '</td>',
				'</tr>',
				'<tr>',
					'<td>Email</td>',
					'<td>', $q->textfield(-name=>'email', -size=>30 ), ' (will only be displayed to verified humans)</td>',
				'</tr>',
				'<tr>',
					'<td>Height</td>',
					'<td>', $q->textfield(-name=>'height', -size=>5 ), ' in inches (ie. 67)', '</td>',
				'</tr>',
				'<tr>',
					'<td>Weight</td>',
					'<td>', $q->textfield(-name=>'weight', -size=>5 ), ' in pounds (ie. 145)', '</td>',
				'</tr>',
				'<tr>',
					'<td valign="top">Positions</td>',
					'<td>', $q->checkbox_group(-name=>'positions', -values=>$config{'crewPositions'}, -linebreak=>'true' ), '</td>',
				'</tr>',
				'<tr>',
					'<td valign="top">Notes<br/><small>(briefly describe<br/>your experience, ability,<br/>interests, etc.)</small></td>',
					'<td>', $q->textarea(-name=>'note', -rows=>5, -cols=>60 ), '</td>',
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
		Myfleet::Header::display_header("Crew List","../..");

	my $dbh = Myfleet::DB::connect();

	# foreach my $z ( keys %$p ) {
	# 	push @ret, "$z='$p->{$z}'<br>";
	# }
	push @ret, "&laquo; <a href=\"..\">back to crew list</a><br/><br/>";

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
			my $sth = $dbh->prepare("delete from crew where firstname = ? and lastname = ? and password = ?") || die $DBI::errstr;
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
		"<h2>Delete From Crew List</h2>",
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

	$q->param('i') || die "no user id specified.";

	my $output_folder = $ENV{'DOCUMENT_ROOT'} . '/captcha/';
	my $data_folder = '/usr/local/apache2/captcha/' . $ENV{'SERVER_NAME'};
	if( ! -e $data_folder ) { File::Path::mkpath($data_folder); }
	my $captcha = Authen::Captcha->new();
	$captcha->data_folder( $data_folder );
	$captcha->output_folder( $output_folder );

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, firstname, lastname, city, state, password, phone, email, height, weight, positions, note, date_format(lastupdate, '%m-%d-%y') from crew where id = ?") || die $DBI::errstr;
	$sth->execute( $q->param('i') ) || die $DBI::errstr;
	$sth->rows || die "Could not locate the specified crew.";

	my ( $id, $firstname, $lastname, $city, $state, $birthday, $phone, $email, $height, $weight, $positions, $note, $lastupdate  ) = $sth->fetchrow;

	push @ret, $q->start_html("$firstname $lastname");
	push @ret, "&laquo; <a href=\"javascript:self.close()\">close window</a><br/><br/>";

	if( $q->param('md5') && $q->param('code') && $captcha->check_code($q->param('code'),$q->param('md5')) == 1 )
	{
		my $obscuredEmail = Myfleet::Util::obscureEmail( $email );
		my $dHeight = int($height/12) . "'" . $height % 12 . '"';
		my ( $bmonth, $bday, $byear ) = split /-/, $birthday;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$mon++;
		my $age = ( $year - $byear );
		if( $mon < $bmonth || ( $mon == $bmonth && $mday < $bday ) ) { $age--; }
			
		push @ret,
			"$firstname $lastname<br/>",
			"<a href=\"mailto:$email\">$email</a><br/>",
			"$phone<br/>",
			"$city, " . uc($state) . "<br/>",
			"$dHeight $weight ($age years old)<br/>",
			join(', ', split(',',$positions)), '<br/>',
			( $note ne '' ? "<p>Note: $note</p>" : '' ),
			"<small>Last Updated: $lastupdate</small><br/>";
	}
	else
	{
	 	my $md5sum = $captcha->generate_code(4);


		if( $q->param('md5') && $q->param('code') )
		{
			push @ret, '<span style="color:#f00;">Text does not match, please try again.</span><br/>';
			$q->param('md5',$md5sum); $q->param('code','');
		}

		push @ret,
			"<b>Fetching information for $firstname $lastname</b><br/><small>(Please confirm that you are human)</small>";

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
		Myfleet::Header::display_admin_header('../..',"$config{'defaultTitle'} Crew List Editor");

	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select id, firstname, lastname, city, state, password, phone, email, height, weight, positions, note, date_format(lastupdate, '%m-%d-%y') from crew order by lastupdate") || die $DBI::errstr;
	$sth->execute( $q->param('i') ) || die $DBI::errstr;

	if( $sth->rows )
	{
		while( my ( $id, $firstname, $lastname, $city, $state, $birthday, $phone, $email, $height, $weight, $positions, $note, $lastupdate  ) = $sth->fetchrow )
		{
			my $obscuredEmail = Myfleet::Util::obscureEmail( $email );
			my $dHeight = int($height/12) . "'" . $height % 12 . '"';
			my ( $bmonth, $bday, $byear ) = split /-/, $birthday;
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
			$mon++;
			my $age = ( $year - $byear );
			if( $mon < $bmonth || ( $mon == $bmonth && $mday < $bday ) ) { $age--; }
				
			push @ret,
				"$firstname $lastname<br/>",
				"<i>$lastname, $firstname</i> [ <a href=\"add/?Continue=admin&i=$id&birthday=$birthday&firstname=$firstname&lastname=$lastname\">Update</a> <a href=\"delete/?i=$id&birthday=$birthday&firstname=$firstname&lastname=$lastname\">Delete</a> ]<br/>",
				"<a href=\"mailto:$email\">$email</a><br/>",
				"$phone<br/>",
				"$city, " . uc($state) . "<br/>",
				"$dHeight $weight ($age years old)<br/>",
				join(', ', split(',',$positions)), '<br/>',
				( $note ne '' ? "<p>Note: $note</p>" : '' ),
				"<small>Last Updated: $lastupdate</small><br/><br/>";
		}
	}
	else
	{
		push @ret,
			"<h2>No crews yet!</h2>";
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
		my $detail = "onClick=\"window.open('../roster/detail/?i=$id','emailwindow','width=500,height=300'); return true;\"";

		push @ret,
			"<tr>",
			"<td><a href=\"#\" $detail><img src=\"/i/mail.gif\" border=\"0\"></a></td>",
			"<td><small><b>$special</td>",
			"<td align=right><small><a href=\"#\" $detail>$firstname&nbsp;$lastname</a></td>",
			"</tr>";
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

	if ( ! $p->{'birthday'} ) {
		push @error, "You must specify your birthday.";
	} elsif( $p->{'birthday'} !~ /^\d{2}-\d{2}-\d{2}$/ ) {
		push @error, "Your birthday should be in this format: mm-dd-yy";
	}

	if ( ! $p->{'city'} ) {
		push @error, "You must specify your city.";
	} elsif( $p->{'city'} !~ /^[\w\s\.]+$/ ) {
		push @error, "Please use only letters, spaces, and periods in your city name.";
	}

	if ( ! $p->{'state'} ) {
		push @error, "You must specify your state.";
	} elsif( $p->{'state'} !~ /^\w{2,3}$/ ) {
		push @error, "Please use a two or three letter abbreviation for you state";
	}

	if( ! $p->{'email'} ) {
		push @error, "You must specify your email address.";
	} elsif ( $p->{'email'} !~ /^([a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-])+/ ) {
		push @error, "The email address you entered appears invalid.";
	}

	if( ! $p->{'phone'} ) {
		push @error, "You must specify a phone number.";
	}

	if( ! $p->{'height'} ) {
		push @error, "You must specify a height.";
	} elsif ( $p->{'height'} !~ /^\d{2}$/ ) {
		push @error, "Please enter your height in inches, which should be a 2 digit number.";
	}

	if( ! $p->{'weight'} ) {
		push @error, "You must specify a weight.";
	} elsif ( $p->{'weight'} !~ /^\d{2,3}$/ ) {
		push @error, "Please enter your weight in pounds, which should be a 2 or 3 digit number.";
	}

	if( $p->{'type'} eq 'Owner' )
	{
		if( $p->{'sailnumber'} eq '' && $p->{'hullnumber'} eq '' )
		{
			push @error, "Please specify either your hullnumber, sailnumber, or both.";
		}
	}

	if( ! $p->{'positions'} )
	{
		push @error, "Please choose at least one position.";
	}

	return @error;
}

1;
