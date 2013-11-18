use Myfleet::DB;

package Myfleet::Util;

sub display_date
{
	my ( $startdate, $enddate ) = @_;
	if ( $enddate )
	{
		my $startmonth = "x";
		my $endmonth = "y";
		my $endday = "";
		if( $startdate =~ /^([A-Za-z]*) (\d+)$/ ) {
			$startmonth = $1;
		}
		if ( $enddate =~ /^([A-Za-z]*) (\d+)$/ ) {
			$endmonth = $1;
			$endday = $2;
		}

		$enddate =~ s/ /\&nbsp;/g;
		$startdate =~ s/ /\&nbsp;/g;
		if ( $startmonth eq $endmonth )
		{
			return "$startdate&nbsp;-&nbsp;$endday";
		}
		else
		{
			return "$startdate&nbsp;-&nbsp;$enddate";
		}
	}
	else
	{
		return $startdate || "&nbsp;";
	}
}

sub obscureEmail
{
	my $email = shift;

	my ( $pre, $post ) = split /\@/, $email;
	my $obscuredEmail = $email;
	if( length($pre) > 3 ) {
		$obscuredEmail =~ s/.{3}\@/\.\.\.\@/;
	} else {
		$obscuredEmail =~ s/\@.{3}/\@\.\.\./; 
	}
	return $obscuredEmail;
}

sub html
{
	my $u = shift;
	my $dbh = Myfleet::DB::connect();
	my $sth = $dbh->prepare("select html, title from html where uniquename = ?");
	$sth->execute( $u );
	my $html = ''; # "<a href=\"/admin/html/?u=$u\">[$u html is empty - click to edit]</a>";
	my $title = 'Not found';
	if( $sth->rows > 0 )
	{
		( $html, $title ) = $sth->fetchrow_array;
	}
	return ( $html, $title );
}

1;
