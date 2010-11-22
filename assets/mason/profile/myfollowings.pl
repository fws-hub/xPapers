<%gh("People I follow")%> 
<& 'social_banner.html' &>
<& ../checkLogin.html, %ARGS &>

    <p>
    This page shows the people you are currently following. Clicking on a name will reveal all aliases you are currently following that person under. (An alias is a variation on a name). You can remove some of these aliases if necessary. To follow someone under additional aliases, just follow one of <a href="add_followers.pl">these methods</a>. 
    <p>
    <div style="border:1px dotted #ccc;padding:2px">
    <%$rend->checkboxAuto($user,"Send me a regular digest of new books and articles by people I follow.",'alertFollowed')%> (See <a href='/profile/myalerts.pl'>My Alerts</a> for more settings.)
    <br>
    <%$rend->checkboxAuto($user,"I prefer to follow anonymously.",'anonymousFollowing')%>
    <br>
    <span class='hint'>The list on this page is private, but people you follow will be able to see that you follow them unless you tick this box.</span> 
    </div>

    <p>
    <% $ARGS{all} 
    ? '<a href="myfollowings.pl?">Show only authors with papers in our database.</a>' 
    : "Note: this list does not show people who do not have any works indexed on $s->{niceName}. (<a href='myfollowings.pl?all=1'>Show everyone</a>)"
    %>
<p>

<%perl>
use xPapers::Follower;
use Encode;


my $query = "select * from followers where uId = ?";
if( !$ARGS{all} ){
    $query = "select f1.* from followers f1 join followers f2 on f2.original_name = f1.original_name and f2.uId = f1.uId join main_authors on name = f2.alias 
    where f1.uId = ? group by f1.id order by f1.original_name";
}

my $dbh = xPapers::DB->new->dbh;
my $sth = $dbh->prepare( $query );
$sth->execute( $user->id );

my $followings = $sth->fetchall_arrayref({});


if( @$followings ){
    my $i;
    </%perl>

    <%perl>
    print "<ul>";
    my %seen;
    my $not_first;
    my $i = 0;
    for my $f ( @$followings ) {
        $i++;
        my $checked = $f->{ok} ? 'checked="1"' : '';
        my $oname = decode('utf8',$f->{original_name});
        $f->{alias} = decode('utf8',$f->{alias});
        my $id = $f->{id};
        if( !$seen{$oname}++ ){
            print '</ul>' if $not_first++;
            print "<li id='follow-li-$i'><span class='ll' onclick='toggleAliases($id,$i)' id='followInput_$i' ><span>[<span id='followPlus_$i'>+</span>]</span> " . reverseName($oname) . "</span>";
            print "&nbsp;&nbsp;<span class='hint'>(";
            print "<a class='hint' style='color:#555' href=\"$s->{server}/s/" . urlEncode(reverseName($oname)) . "\">search</a>, <span class='ll hint' id='rmfx-$i' onclick='removeFollow($i,$id)'>unfollow</span>)</span>";
            print "<ul id='followUl_$i' style='display:none;list-style:none;padding-left:5px'>";
        }
        print "<li> <input type='checkbox' name='alias_$i' id='alias_$i' onclick='updateFollowAlias($id,$i)' value='$id' $checked >" . $f->{alias} . " <span id='change_indicator_$i'></span>";
    }
    print '</ul></ul>';
}
else{
    print '<em>You are not following anyone yet</em>';
}
</%perl>


