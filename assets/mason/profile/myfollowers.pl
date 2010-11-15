<& ../header.html, subtitle=>'My followers' &>
<%gh("My followers")%>

<& 'social_banner.html' &>

<& ../checkLogin.html/, %ARGS &>


<%perl>
#error("This feature is currently disabled, sorry. Back soon.") unless $SECURE;
use xPapers::Follower;

my $limit = 100;
$ARGS{fpage} ||= 0;

my $dbh = $root->dbh;
my $f_count = $user->followerCount;

if( $f_count ){
    my $f = $f_count == 1 ? 'follower' : 'followers';
    my $offset = $ARGS{fpage} * $limit;
    my $query = "
    select SQL_CALC_FOUND_ROWS followers.uId as fuId, 
    concat( ifnull( users.lastname, ''), ', ', ifnull( users.firstname, '') ) as fname
    from aliases join followers on aliases.name = followers.alias join users on followers.uId = users.id
    where aliases.uId = ? and users.anonymousFollowing = 0 and users.hide = 0 and users.confirmed
    group by fuId, fname order by users.lastname,users.firstname
    limit $limit offset $offset
    ";
    my $sth = $dbh->prepare( $query );
    $sth->execute( $user->id );
    my $s2 = $dbh->prepare("select found_rows() as f");
    $s2->execute;
    my $found = $s2->fetchrow_hashref->{f};
    print "You have " . num($f_count,'follower') . ". That is, " . num($f_count,'person') . " follow one or more of <a href='/profile/$user->{id}/aliases.pl'>your aliases</a>. <p>Here are the people who follow you publicly ($found in total):\n";
    print "<ul>\n";
    while( my $match = $sth->fetchrow_hashref ){
        my $follower = xPapers::User->get($match->{fuId});
        my $name = $follower->fullname;
        print "<li>" . $rend->renderUserC($follower);
        print "<span class='hint'>";
        if( $user->follow_all_aliases_of( $match->{fuId} ) ){
            print " [ <span class='hint' id='followXUser_$match->{fuId}' >following</span> ]";
        }
        else{
            print " [ <span id='followXUser_$match->{fuId}' class='ll hint' onclick='updateFollowXUser($match->{fuId})'>follow $name</span> ]";
        }
        print "</span>";
    }
    print "</ul>\n";
    if( $found > $limit ){
        my $query = "?fpage=";
        print pager(
            type => "notes",
            showText=>1,
            prevLink => ( $ARGS{fpage} > 0 ? $query . ( $ARGS{fpage} > 1 ? $ARGS{fpage} - 1 : 0 ) : undef),
            nextLink => ( ( $ARGS{fpage} + 1 ) * $limit < $found ? $query . ( $ARGS{fpage} + 1 ) : undef ),
        );
    }
}
else{
    print "You don't have any followers yet.";
}

</%perl>


