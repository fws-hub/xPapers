use xPapers::Editorship;
use xPapers::Cat;
use xPapers::Operations::ImportEntries;
use xPapers::Diff;
use xPapers::Mail::Message;
use xPapers::Relations::CatEntry;

my $sum = "";

# check unconfirmed editorships
my %dur = ( 10 => "in ten days from now", 7 => "in seven days from now", 3 => "in three days from now", 1=> "in just a few hours" );
for my $l (keys %dur) {
    my $u = xPapers::ES->get_objects(clauses=>["status = 10 and date(confirmBy) = date(date_add(now(), interval $l day))"]);
    for my $uc (@$u) {
        next if $uc->confirmWarnings <= $l;
        $sum .= '- ' . $uc->user->fullname . "'s ($uc->{uId}) offer for " . $uc->cat->name . " lapses $dur{$l}.\n";
        xPapers::Mail::Message->new(
            uId=>$uc->uId,
            brief=>"Your editorship offer will lapse",
            content=>"[HELLO]This is a reminder that your editorship offer for " . $uc->cat->name . " will lapse $dur{$l} if you do not officially accept it by going to \"this page\":" . $DEFAULT_SITE->{server} . "/utils/edconfirm.pl \n\nPlease decline the offer by going to the same page if you are no longer interested. [BYE]" 
        )->save;
        $uc->confirmWarnings($l);
        $uc->save;
    }
}

xPapers::Mail::MessageMng->notifyAdmin("Pending editorship offers",$sum) if $sum;

my $eds = xPapers::ES->get_objects(query=>['!start'=>undef,'end'=>undef],sort_by=>['uId','cId']);

my $c = 0;
my %seen_user;
my $total_io = 0;

for my $e (@$eds) {

    $e->GIO(
       xPapers::D->get_objects_count(query=>[
            uId=>$e->uId,
            type=>'update',
            class=>'xPapers::Entry',
            created=>{ge=>$e->start}
       ], clauses=>['relo1'])
    );
    unless ($seen_user{$e->uId}) {
        $total_io += $e->GIO;
        $seen_user{$e->uId} = 1;
    }

    $e->IO(
       xPapers::D->get_objects_count(query=>[
            uId=>$e->uId,
            type=>'update',
            class=>'xPapers::Entry',
            relo1=>$e->cId,
            created=>{ge=>$e->start}
       ])
    );

    my ($count) = xPapers::DB->exec("select count(*) from cats_me where cId=? and created>=? and editor",$e->cId,$e->start)->fetchrow_array; 
    $e->added($count);

    my ($lastAdded) = xPapers::DB->exec("select max(created) from cats_me where cId=? and editor",$e->cId)->fetchrow_array; 
    $e->lastAdded($lastAdded);

    ($count) = xPapers::DB->exec("select count(*) from cats_me join primary_ancestors pa on cats_me.cId=pa.cId and aId=?",$e->cId)->fetchrow_array; 
    $e->entryCountUnder($count);

    ($count) = xPapers::DB->exec("select count(*) from cats_me where cId=?",$e->cId)->fetchrow_array; 
    $e->entryCount($count);

    $e->imports(
        xPapers::B->get_objects_count(query=>[
            uId=>$e->uId,
            cId=>$e->cId,
            created=>{ge=>$e->start}
        ])
    );

    $e->checked(
        xPapers::D->get_objects_count(query=>[
            checked=>1,
            relo1=>$e->cId,
            type=>'update',
            class=>'xPapers::Entry',
            created=>{ge=>$e->start}
       ])
    );
    
    $e->excluded(
        xPapers::Relations::CE->get_objects_count(query=>[
            created=>{ge=>$e->start},
            cId=>$e->cat->{exclusions}
        ])
    );

    $e->save;
    #print $c++ . "\n";
}

# add new editors to group
#

xPapers::DB->new->dbh->do("insert ignore into groups_m (uId,gId,level) select uId,6,10 from cats_eterms where status = 20");
xPapers::DB->new->dbh->do("insert ignore into forums_m (uId,fId) select uId,138 from cats_eterms where status = 20");

#print "total io: $total_io\n";
1;
