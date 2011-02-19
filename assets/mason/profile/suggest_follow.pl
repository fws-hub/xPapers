<%perl>
# Followed by followed
event('suggest_follow','start');
my $order = $ARGS{all} ? "aliases.name" : "rating+rand()*50+if(isnull(af2.aId),0,rand()*10+5) desc";
my $limit = $ARGS{all} ? '500' : 6;

my $q = "
    select aliases.uId,max(rating) as rating from follow_suggestions fs
    left join followers on (followers.uId=$user->{id} and fs.name=followers.alias)
    join aliases on (fs.name=aliases.name)
    left join affils_m af1 on (aliases.uId=af1.uId)
    left join affils_m af2 on (af2.uId=$user->{id} and af1.aId=af2.aId)
    where fs.uId=$user->{id} and isnull(followers.alias) 
    and not aliases.uId=$user->{id}
    group by (aliases.uId)
    order by $order
    limit  $limit 
";
#print $q;
my $res = xPapers::DB->exec($q);
my $f = 0;
while (my ($id,$rating) = map {decode('utf8',$_)} $res->fetchrow_array) {
    print "<p style='margin-bottom:5px'><em style='color:#555'>People in your areas you might want to follow</em>:<ul class='normal;margin-top:0'>" unless $f;
    $f=1;
    my $u = xPapers::User->get($id);
    next unless $u;
    my $name = $u->fullname;
    print "<li>" . $rend->renderUserC($u);
    print "<span class='hint'>";
    print " [ <span id='followXUser_$u->{id}' class='ll hint' onclick='updateFollowXUser($u->{id})'>follow $name</span> ]";
    print "</span>";

    #print xPapers::User->get($id)->fullname . "\n";
}
print "</ul>" if $f;
unless ($ARGS{all}) {
    print "<a href='/profile/$user->{id}/suggest_follow.pl?all=1'>Show me more</a>";
}


event('suggest_follow','end');
</%perl>
