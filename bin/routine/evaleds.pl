use xPapers::Editorship;
use xPapers::Cat;
use xPapers::Operations::ImportEntries;
use xPapers::Diff;
use xPapers::Mail::Message;
use xPapers::Relations::CatEntry;
use xPapers::Conf;
use strict;
#$TEST_MODE = 1;
my $sum = "";

# check unconfirmed editorships
my %dur = ( 10 => "will lapse in ten days from now", 7 => "will lapse in seven days from now", 3 => "will lapse in three days from now", 1=> "will lapse in just a few hours", -1 => "has lapsed"  );
for my $l (keys %dur) {
    my $u = xPapers::ES->get_objects(clauses=>["status = 10 and ( date(confirmBy) = date(date_add(now(), interval $l day)) )"]);
    for my $uc (@$u) {
        next if $uc->confirmWarnings <= $l;
        $sum .= '- ' . $uc->user->fullname . "'s ($uc->{uId}) offer for " . $uc->cat->name . " $dur{$l}.\n";
        xPapers::Mail::Message->new(
            uId=>$uc->uId,
            brief=>"Your editorship offer" . ($l > 0 ? ' will lapse' : 'has lapsed'),
            content=>$l > 0 ? "[HELLO]This is a reminder that your editorship offer for " . $uc->cat->name . " $dur{$l} if you do not officially accept it by going to \"this page\":" . $DEFAULT_SITE->{server} . "/utils/edconfirm.pl \n\nPlease decline the offer by going to the same page if you are not interested. [BYE]" : "[HELLO]Please note that your editorship offer for ".$uc->cat->name." has lapsed.[BYE]"
        )->save;
        $uc->confirmWarnings($l);
        $uc->save;
    }
}

xPapers::Mail::MessageMng->notifyAdmin("Pending and expired editorship offers",$sum) if $sum;

my $eds = xPapers::ES->get_objects(query=>['!start'=>undef,'end'=>undef],sort_by=>['uId','cId']);

my $c = 0;
my %seen_user;
my $total_io = 0;

for my $e (@$eds) {
    print "Doing user $e->{uId} - cat $e->{cId}\n";
    my $cat = xPapers::Cat->get($e->{cId});
=old
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
=cut


    my $diffs = 
       xPapers::D->get_objects_iterator(query=>[
            uId=>$e->uId,
            type=>'update',
            class=>'xPapers::Entry',
            relo1=>$e->cId,
            and => [
            created=>{ge=>$e->start},
            created=>{ge=>DateTime->now->subtract(years=>1)}
            ]
       ]);
    my ($in,$out);
    $in = 0;
    $out = 0;
    while (my $d = $diffs->next) {
        $d->load;
        use Data::Dumper;
        if ( cat_add($d->{diff},$e->{cId}) ) {
            $in++;    
        } else {
            $out++;
        }
        
        #print Dumper($d->{diff});
#        die if (@{$d->{diff}->{memberships}->{to_add}});
#        die if $d->{oId} eq 'BOUPPA';
    }
    $e->input($in);
    $e->output($out);
    print "In: $in; out: $out\n";

    # Now input under
    my $res = xPapers::DB->exec("select diffs.id,diffs.relo1 from diffs join ancestors on (diffs.relo1=ancestors.cId and ancestors.aId=$e->{cId}) where uId=$e->{uId} and diffs.created >= date_sub(now(),interval 1 year)");
    $in = 0;
    $out = 0;
    while (my ($id,$cId) = $res->fetchrow_array) {
        my $d = xPapers::Diff->get($id);
        if (cat_add($d->{diff},$cId)) {
            #warn "added under: $cId";
            $in++;
        } else {
            #warn "removed under: $cId";
            $out++;
        }
    }
    #warn "under:$in";
    $e->inputu($in);

    # now almost the same, but for six-month period

    $diffs = 
       xPapers::D->get_objects_iterator(query=>[
            uId=>$e->uId,
            type=>'update',
            class=>'xPapers::Entry',
            relo1=>$e->cId,
            and => [
            created=>{ge=>$e->start},
            created=>{ge=>DateTime->now->subtract(months=>6)}
            ]
       ]);
    $in = 0;
    $out = 0;
    while (my $d = $diffs->next) {
        $d->load;
        #use Data::Dumper;
        if ( cat_add($d->{diff},$e->{cId}) ) {
            $in++;    
        } else {
            $out++;
        }
        #print Dumper($d->{diff});
#        die if (@{$d->{diff}->{memberships}->{to_add}});
#        die if $d->{oId} eq 'BOUPPA';
    }
    $e->input6m($in);
    $e->output6m($out);
    #print "In: $in; out: $out\n";

    # Now input under
    my $res = xPapers::DB->exec("select diffs.id,diffs.relo1 from diffs join ancestors on (diffs.relo1=ancestors.cId and ancestors.aId=$e->{cId}) where uId=$e->{uId} and diffs.created >= date_sub(now(),interval 6 month)");
    $in = 0;
    $out = 0;
    while (my ($id,$cId) = $res->fetchrow_array) {
        my $d = xPapers::Diff->get($id);
        if (cat_add($d->{diff},$cId)) {
            #warn "added under: $cId";
            $in++;
        } else {
            #warn "removed under: $cId";
            $out++;
        }
    }
    #warn "under:$in";
    $e->inputu6m($in);


    my ($count) = xPapers::DB->exec("select count(*) from cats_me join main on (cats_me.eId=main.id and not main.deleted) where cId=? and created>=? and editor",$e->cId,$e->start)->fetchrow_array; 
    $e->added($count);

    my ($lastAdded) = xPapers::DB->exec("select max(created) from cats_me where cId=? and editor",$e->cId)->fetchrow_array; 
    $e->lastAdded($lastAdded);

    ($count) = xPapers::DB->exec("select count(*) from cats_me join primary_ancestors pa on cats_me.cId=pa.cId and aId=? join main on (cats_me.eId=main.id and not main.deleted) ",$e->cId)->fetchrow_array; 
    $e->entryCountUnder($count);

    if ($cat->{catCount}) {
        #($count) = xPapers::DB->exec("select count(*) from cats_me where cId=?",$e->cId)->fetchrow_array; 
        $e->entryCount(xPapers::Cat->get($e->cId)->localCount($DEFAULT_SITE));
    } else {
        $e->entryCount(0);#this represent 'uncategorized' stuff
    }

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
            created=>{ge=>$e->start},
            '!uId'=>$e->uId
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
#xPapers::DB->new->dbh->do("insert ignore into forums_m (uId,fId) select uId,138 from cats_eterms where status = 20");

sub cat_add {
    my $diff = shift;
    my $cat = shift;
    return grep { $_->{cId} == $cat } @{$diff->{memberships}->{to_add}};
}
#print "total io: $total_io\n";
1;
