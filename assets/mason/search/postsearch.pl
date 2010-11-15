<%perl>
unless ($ARGS{query} =~ /^(.{3,}?)(\s.*)?$/) {
    print encode_json {
        Found => 1,
        Results => {
            text=> "No match. Type an author's name <b>followed by</b> keywords.",
            id=>0
            }
        };
    return;

}

my $author = squote($1);
my $k = $2;
my $comma = ($author =~ /,/ ? "" : ',');
my $ftm;
if (length($k)>3) {
    $ftm = " and match (subject) against ('" . squote($k) . "')";
}
#$user->elog("select posts.id,uId,body, posts.created,subject,target from posts join users on (posts.uId = users.id) where lastname like '$author%'$ftm");

my $r = xPapers::PostMng->get_objects_from_sql(
    sql=>"
        select posts.id,uId,body, posts.created,subject,target from posts join users on (posts.uId = users.id)
        where lastname like '$author%'$ftm 
        "
);
#print Dumper $r;
#return;

#$rend = xPapers::Render::RichText->new;
#$rend->{noOptions} = 1;
#$rend->{entryReady} = 1;

sub t { return shift() }
my @res = map { 
        { id => $_->id, text=>
            $_->user->fullname . ': "' . $_->subject .'"<br>' .
            '<em style="font-size:95%">' . rmTags(t($rend->wordSplit($_->body,25))) . '</em>...'
        } 
} @$r;

if ($#res==-1) {

    print encode_json {
        Found => 1,
        Results => {
            text=> "No match. Type an author's name <b>followed by</b> keywords.",
            id=>0
            }
        };
    return;
}

print encode_json {
    Found=>$#res+1,
    Results=>\@res
}

</%perl>
