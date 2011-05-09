use xPapers::DB;
use xPapers::Mail::Message;
use xPapers::User;

my $res = xPapers::DB->exec("select count(*) as nb, group_concat(jlId) as ids, jlOwner from main_jlists group by jlOwner having nb > 1 and jlOwner > 0");

while (my $h = $res->fetchrow_hashref) {
    my @ids = split(/,/,$h->{ids});
#    print join(";",@ids). "\n";
    my @counts = map {count($_)} @ids;
    print "--\n";
    print join(";",@ids)."\n";
    print join(";",@counts)."\n";
    if ($counts[0] > $counts[1]) {
        setlist($h->{jlOwner},$ids[0])
    } else {
        setlist($h->{jlOwner},$ids[1])
    }
}

sub count {

   my $id= shift;
   my $r2 = xPapers::DB->exec("select count(*) as nb from main_jlm where jlId=$id");
   return $r2->fetchrow_hashref->{nb};

}

sub setlist {
    my ($owner,$listid) = @_;
    return if $owner == 2;
    print "set $listid for $owner\n";
    my $u = xPapers::User->get($owner) || die;
    #xPapers::DB->exec("delete from main_jlists where jlOwner=$owner and jlName='My sources' and not jlId=$listid");
    xPapers::Mail::Message->new(
        uId=>$u->id,
        brief=>"Fix to 'my journals'",
        content=>"[HELLO]This is to inform you that a technical problem with your list of favourite journals has been fixed. It is possible that the content of your list has been altered in the process. We apologize for any inconvenience and invite you to have a look at the list \"here\":http://philpapers.org/profile/myjournals.pl to make sure everything is in order. Unfortunately, we cannot restore your list to its previous state if it has been affected due to corrupted data. We apologize for the inconvenience.[BYE]"

    )->send;
    $u->mysources($listid);
    $u->save(modified_only=>1);

}
