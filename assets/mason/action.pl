<%init>

=notes

How to use:

in Javascript, you do ppAct('commandName',{param1:value1,...});

this will make a request with $ARGS{c} = 'commandName', $ARGS{param1} = value1, etc. to this script.

=cut

use File::Slurp 'slurp';
use HTML::TagFilter;

$NOFOOT = 1;
my %QUESTIONS;
$QUESTIONS{catExists} = 'select id as answer from cats where canonical and name like ?';

</%init>
<%perl>

if ($ARGS{c} eq 'go') {
writeLog($root->dbh,$q,$tracker,"go");
return;
}

#jserror(join("  ", map { "$_ : $ARGS{$_}" } keys %ARGS));

# Generic params
my ($tuser, $entry, $forum, $thread, $list, $filter, $cat, $group, $alert, $lo, $poll);
#
# Check and preload some common params
#

if ($ARGS{eId}) {
$entry = xPapers::Entry->get($ARGS{eId});
jserror("Entry not found") unless $entry;
}

if ($ARGS{lId}) {
$list = xPapers::Cat->get($ARGS{lId});
jserror("List not found") unless $list;
}

if ($ARGS{fId}) {
$filter = xPapers::Query->get($ARGS{fId});
jserror("Invalid filter") unless $filter;
}

if ($ARGS{cId}) {
$cat = xPapers::Cat->get($ARGS{cId});
jserror("Invalid category") unless $cat;
}

if ($ARGS{bId}) {
$forum = xPapers::Forum->get($ARGS{bId});
jserror("Invalid forum") unless $forum;
}

if ($ARGS{tId}) {
$thread = xPapers::Thread->get($ARGS{tId});
jserror("Invalid thread") unless $thread;
}

if ($ARGS{gId}) {
$group = xPapers::Group->get($ARGS{gId});
jserror("Invalid group") unless $group;
}

if ($ARGS{uId}) {
$tuser = xPapers::User->get($ARGS{uId});
jserror("Invalid user") unless $tuser;
}

if ($ARGS{aId}) {
$alert = xPapers::Alert->get($ARGS{aId});
jserror("Invalid alert") unless $alert;
}

if ($ARGS{poId}) {
    $poll = xPapers::Polls::Poll->get($ARGS{poId});
    jserror("Invalid poll") unless $poll;
}


if ($ARGS{c} eq 'unlockEntry') {
    return unless $user->{id}; # silently ignore if not logged in
    unless ($entry and $entry->unlock($user->{id})) {
        #jserror("Could not unlock entry $entry->{id}. (This is problably not too serious.)");
    }
    return;
}

# Simple questions
#
if ($ARGS{c} eq 'question') {
    my $qu = $QUESTIONS{$ARGS{quest}};    
    jserror("Invalid question") unless $qu;
    my $sth = $root->dbh->prepare($qu);
    $sth->execute(split(/\s*\|\s*/,$ARGS{qparams}));
    my $h = $sth->fetchrow_hashref; 
    print $h ? $h->{answer} : "";
    return;
}

writeLog($root->dbh,$q, $tracker, "ajax", 
    "c:=$ARGS{c}|" . join("|", grep { $_ } map { $ARGS{$_} ? "$_:=$ARGS{$_}" : "" } qw/aId uId gId tId bId fId eId lId cId/)
,$s);

if( $ARGS{c} eq 'uploadProgress' ){
    my $uploadId = $ARGS{upId};
    my $file = "$PATHS{LOCAL_BASE}/var/files/tmp/$uploadId";
    if( -f "$file.finished" ){
        print 1;
        unlink "$file.finished";
        return;
    }
    if( !-r "$file.size" ){
        print 0;
        return;
    }
    my $full_size = slurp "$file.size";
    return if !$full_size;
    my $size = (stat $file)[7];
    print $size/$full_size . ' ' . $size;
    return;
}


#
# Accounts only
#

jserror("You must be logged in to use this feature",1) unless $user and $user->{id};

if ($ARGS{c} eq "reverseDiff") {
    my $diff = xPapers::Diff->get($ARGS{dId});
    jserror("Invalid diff:$ARGS{dId}") unless $diff;
    my $cat;
    $cat = xPapers::Cat->get($diff->relo1) if $diff->relo1;
    my $editor = ($cat and $cat->isEditor($user));
    jserror("Not allowed") unless $diff->uId == $user->id or $editor or $SECURE;
    my $r = $diff->reverse;
    $r->checked(1) if $editor or $SECURE;
    $r->uId($user->id);
    $r->host($ENV{REMOTE_ADDR});
    $r->accept;
    $diff->checked(1);
    $diff->reversed(1);
    $diff->save;
    return;
} elsif ($ARGS{c} eq 'resetAliases') {
    $user->calcDefaultAliases;
    return;
} elsif ($ARGS{c} eq 'setUserFlag') {
    $user->setFlag($ARGS{flag});
    $user->save;
    return;
} elsif ($ARGS{c} eq 'unsetUserFlag') {
    $user->rmFlag($ARGS{flag});
    $user->save;
    return;
} elsif ($ARGS{c} eq 'toggle') {
    my $obj = $ARGS{oType}->get($ARGS{oId});
    jserror("Object invalid") unless $obj;
    jserror("Not allowed") unless 

        #himself is ok
        ($obj->meta->class eq 'xPapers::User' and $obj->id == $user->id) or

        # an object he owns
        $obj->{owner} == $user->id or 
        $obj->{uId} == $user->id or 

        # dealing with admin
        $SECURE;

    my $field = $ARGS{oField};
    my $f = grep {$_ eq $field } $obj->userFields;

    jserror("Not allowed") if 
                (
                    !$f or
                    $obj->notUserFields->{$field} or 
                    ($obj->{$field} and $obj->{$field} ne '1')
                ) and !$SECURE;

    $obj->elog($obj->$field);
    $obj->$field($obj->{$field} ? 0 : 1);
    $obj->elog($obj->$field);
    $obj->save;
    $obj->elog($obj->$field);

    return;
} elsif ($ARGS{c} eq 'setUserField') {

    my $field = $ARGS{oField};
    my $f = grep {$_ eq $field } $user->userFields;
    jserror("Not allowed") unless $f;
    $user->$field($ARGS{val});
    $user->save;
    return;
   
} elsif ($ARGS{c} eq 'getPublicCatsForEntry') {
    print encode_json [ 
            map { id=>$_->id, name=>$_->name, longName=>$rend->renderCat($_) },
            $entry->publicCats 
        ];
    return;
} elsif ($ARGS{c} eq 'getCatsForEntry') {
    
    print encode_json [ 
        map { id=>$_->id, name=>$_->name, longName=>$rend->renderCat($_) },
        grep { $_->owner and !$_->system and $_->canWrite($user->{id}) }
        $entry->categories
        ];
    return;
} elsif ($ARGS{c} eq 'addToList') {
    jserror("Access denied: can't add to list #$list->{id}. This may be a bug. Please report and include list #.") unless $list->canDo("AddPapers",$user->{id});
    return unless $entry;
    jserror("Entry already in list") if $list->contains($entry->id);
    jserror("You have reached your quota of categorization for today, sorry") if !$list->isEditor($user) and $user->danger("CatAdd");
    eval {
    $list->addEntry($entry,$user->{id},deincest=>1);
    };
    return;
} elsif ($ARGS{c} eq 'addToListMulti') {
    jserror("Select some entries first") unless $ARGS{entries};
    jserror("Not allowed") unless $list->canDo("AddPapers",$user->{id});
    my @ents = split(";",$ARGS{entries});
    jserror("You have reached your quota of categorization for today, sorry") if !$list->isEditor($user) and $user->danger("CatAdd",$#ents+1);
    for (@ents) {
        next unless $_;
        my $e = xPapers::Entry->get($_);
        my $diff = $list->addEntry($e,$user->{id},deincest=>1);
    }
    #open L, ">>/tmp/bug";
    #print L "$$ ============\n";
    #$Data::Dumper::Indent = 2;
    #$Data::Dumper::Maxdepth = 3;
    #print L Dumper $list;
    #close L;
    return;
} elsif ($ARGS{c} eq 'removeFromList') {

    #open L, ">>/tmp/bug";
    #print L "$$ ============\n";
    #$Data::Dumper::Indent = 2;
    #$Data::Dumper::Maxdepth = 3;
    #print L Dumper $list;
    #close L;
    jserror("Access denied") unless $list->canDo("DeletePapers",$user->{id});
    jserror("You have reached your quota of categorization for today, sorry") if !$list->isEditor($user) and $user->danger("CatDelete");
    my $diff = $list->deleteEntry($entry,$user->{id});
    #$diff->save if $diff;
    return;
} elsif ($ARGS{c} eq 'moveList') {
    my $target = xPapers::Cat->get($ARGS{toList});
    jserror("Bad target list") unless $target;
    jserror("Access denied") unless $list->canDo("DeletePapers",$user->{id}) and $target->canDo("AddPapers",$user->{id});
    my $diff = $list->deleteEntry($entry,$user->{id});
    $diff->save if $diff;
    my $diff2 = $target->addEntry($entry,$user->{id});
    $diff2->save if $diff2;
    return;
} elsif ($ARGS{c} eq 'setAside') {
    jserror("You must be editor of the category to do this.") unless $list->isEditor($user);
    xPapers::DB->exec("update cats_me set setAside=1 where cId=? and eId=?",$list->id,$entry->id);
    return;
} elsif ($ARGS{c} eq 'checkSherpaRomeo') {
    jserror("Specify the journal's name first") unless $ARGS{journalTitle}; 
    eval {
        my $res = xPapers::Link::SherpaRomeo::policy(title=>$ARGS{journalTitle});
        unless ($res) {
            print "Unknown policy. Please contact the publisher directly.";
            return;
        }
        print $res->{text};
        print "<br>See <a target=\"_blank\" href=\"$res->{url}\">this page</a> for more details." if $res->{url}; 
        return;
    };
    if ($@) {
        jserror("Error contacting Sherpa/Romeo for publisher's policy about journal `$ARGS{journalTitle}`.\nPlease consult the publisher's web site.");
    }
    return;
} elsif ($ARGS{c} eq 'subscribeThread') {
    $thread->add_subscribers($user->id);
    $thread->save;
    return;
} elsif ($ARGS{c} eq 'unsubscribeThread') {
    $thread->delete_user($user->id);
    return;
} elsif ($ARGS{c} eq 'subscribeEntryForum') {
    my $f = $entry->forum_o;
    $f->add_subscribers($user->id);
    $f->save;
    $user->clear_cache;
    return;
} elsif ($ARGS{c} eq 'subscribeForum') {
    $forum->add_subscribers($user->id);
    $forum->save;
    $user->clear_cache;
    return;
} elsif ($ARGS{c} eq 'unsubscribeForum') {
    $forum->delete_user($user->id);
    $user->clear_cache;
    return;
} elsif ($ARGS{c} eq 'withdrawFromGroup') {
    jserror("You cannot withdraw, you are the administrator") if $group->hasLevel($user->id,40);
    $group->deleteUser($user->id);
    for ($group->usersAt(40)) {
        my $n = xPapers::Mail::Message->new(uId => $_->id, brief=> $user->fullname . " has left the group " . $group->name);
        $n->save;
    }
    return;
} elsif ($ARGS{c} eq 'evict') {
    jserror("Not allowed") unless $group->hasLevel($user->id,40);
    $group->deleteUser($tuser->id);
    xPapers::Mail::Message->new(uId=>$tuser->id, brief=>"You have been expelled from the group ". $group->name)->save;
    return;
}  elsif ($ARGS{c} eq 'promote') {
    jserror("Not allowed") unless $group->hasLevel($user->id,40);
    $group->addUser($tuser->id,30);
    xPapers::Mail::Message->new(uId=>$tuser->id, brief=>"You have been promoted to moderator status for the group ". $group->name)->save;
    return;
}  elsif ($ARGS{c} eq 'demote') {
    jserror("Not allowed") unless $group->hasLevel($user->id,40);
    $group->addUser($tuser->id,10);
    xPapers::Mail::Message->new(uId=>$tuser->id, brief=>"You have been demoted from moderator to normal status for the group ". $group->name)->save;
    return;
} elsif ($ARGS{c} eq 'userDelete') {
    my $diff = xPapers::Diff->new;
    $diff->delete_object($entry);
    $diff->uId($user->id);
    $diff->note($ARGS{reason});
    $diff->compute;
    $diff->save;
    return;
} elsif ($ARGS{c} eq 'createAlert') {

    jserror("Bad alert spec") unless $ARGS{__action} and $ARGS{__name};
    my $cmp = $ARGS{__action};
    my $name = $ARGS{__name};
    delete $ARGS{$_} for qw/__action __name/;
    $ARGS{sort} = 'added';
    my $params = join("&", map { "$_=".urlEncode($ARGS{$_}) } keys %ARGS);

    my $a = xPapers::Alert->new;
    $a->url("$cmp?$params");
    $a->uId($user->id);
    $a->lastChecked(DateTime->now);
    $a->name($name);

    my $same = xPapers::AlertManager->get_objects(query=>[url=>$a->url,uId=>$user->id]);
    if ($#$same > -1) {
        jserror("You already have an identical alert set up (named `$same->[0]->{name}`)");
    }

    $a->save;
    return;

} elsif ($ARGS{c} eq 'deleteAlert') {
    jserror("Not yours") unless $alert->uId == $user->id;
    $alert->delete;
    return;
} elsif ($ARGS{c} eq 'cancelEdApp') {
    my $app = xPapers::Editorship->get($ARGS{edId});
    jserror("Application not found") unless $app;
    jserror("Not allowed") unless $app->uId == $user->id;
    $app->status(-20);
    $app->save;
    return;
} elsif ($ARGS{c} eq "runTrawler") {
    jserror("Not allowed") unless $cat->isEditor($user);
    jserror("Bad cat") unless $cat;
    my $t = $cat->prepTrawler($user);
    $t->execute;
    print $t->{found};
    return;
} elsif ($ARGS{c} eq "resetTrawler") {
    jserror("Not allowed") unless $cat->isEditor($user);
    jserror("Bad cat") unless $cat;
    $cat->edfChecked(undef);
    $cat->save;
    return;
} elsif ($ARGS{c} eq "trawlerChecked") {
    jserror("Not allowed") unless $cat->isEditor($user);
    jserror("Bad cat") unless $cat;
    $cat->edfChecked(DateTime->now(time_zone=>$TIMEZONE));
    $cat->save;
    return;
} elsif ($ARGS{c} eq "markEdChecked") {
    jserror("Not allowed") unless $cat->isEditor($user);
    jserror("Bad cat") unless $cat;
    $root->dbh->do("update diffs set checked=1 where relo1='$cat->{id}' and type='update' and class='xPapers::Entry' and not checked and status > 0");
    return;
} elsif ($ARGS{c} eq "createTrawler") {
    jserror("Not allowed") unless $cat->isEditor($user);     
    jserror("Bad cat") unless $cat;
    my $f = xPapers::Query->new(
        filterMode=>"advanced",
        advMode=>"normal",
        name=>"Trawler for category " . $cat->name,
        system=>1,
        trawler=>$cat->id,
        owner=>0
    )->save;
    $cat->edfId($f->{id});
    $cat->save;
    return;
} elsif ($ARGS{c} eq 'createList') {

    jserror("You didn't provide a name") unless $ARGS{name};
    jserror("You already have a list with name '$ARGS{name}'") if xPapers::CatMng->get_objects_count(query=>[owner=>$user->id, name=>$ARGS{name}]); 
    $list = $user->createBiblio($ARGS{name});
    if ($entry) {
        $list->add_entries($entry->id);
        $list->save;
    }
    return;
}


if ($ARGS{c} eq 'getListsForEntry') {
    my %r;
#    if (!$user->{mybib}) {
#        print encode_json [];
#        return;
#    }
    if ($user->{mybib}) {
        my @lists = 
            map { { id=>$_->id, name=> $_->name, included=>$_->contains($entry)} } 
            grep { $_->id ne $ARGS{cList} }
            $user->myBiblio->children;
        $r{user} = \@lists;
    }
    my $edited = $user->editedCats;
    if ($#$edited > -1) {
        $r{edited} = $edited;
    }
    print encode_json \%r;
    return;
} 
 elsif ($ARGS{c} eq 'getCats') {
    print encode_json menuTree($cat);
    return;
}
if ($ARGS{c} eq 'addToReadingList') {
    # check that user has it
    my $rl = $user->reads;
    if (!$rl) {
        $rl = xPapers::Cat->new();
        $rl->{name} = $READING_LIST_NAME;
        $rl->{owner} = $user->id;
        $rl->{system} = 1;
        $rl->save;
        $user->readingList($rl->id);
        $user->save;
    }
    $rl->addEntry($entry->id,$user->{id}); 
    return;
} elsif ($ARGS{c} eq 'removeFromReadingList') {
    my $rl = $user->reads;
    jserror("Reading list not found") unless $rl;
    $rl->deleteEntry($entry->id,$user->{id});
    return;
}


if ($ARGS{c} eq 'getAnonymousFollowing') {
    print $user->anonymousFollowing();
    return;
}

if ($ARGS{c} eq 'setAnonymousFollowing') {
    $user->anonymousFollowing( $ARGS{value} );
    $user->save;
    print 'done';
    return;
}

if ($ARGS{c} eq 'updateFollowXUser') {
    if( !defined( $user->anonymousFollowing ) ){
        print $m->scomp("followx/firstTimeDialog.pl", fuId => $ARGS{fuId});
        return;
    }
    my @authors;
    my $fuser = xPapers::User->get( $ARGS{fuId} );
    if( $fuser->hide && !$fuser->confirmed ){
        print "Cannot follow this user";
        return;
    }
    my $original_name = $fuser->lastname . ', ' . $fuser->firstname;
    my @aliases = map { $_->name } $fuser->aliases;
    push @aliases, $original_name;
    for my $alias ( @aliases ){
        my $f = xPapers::Follower->new( uId => $user->id, original_name => $original_name, alias => $alias, );
        $f->load;
        $f->ok( 1 );
        $f->fuId( $ARGS{fuId} );
        $f->save;
    }
    print "following";
    return;
}

if ($ARGS{c} eq 'followName') {
    if( !defined( $user->anonymousFollowing ) ){
        print $m->scomp("followx/firstTimeDialog.pl", eId => $ARGS{eId});
        return;
    }
    my $name = composeName( parseName( $ARGS{name} ) );
    my @fs = $user->followName( name => $name );
    my $i = $ARGS{j};
    my $id = $fs[0]->id;
    print "<li id='follow-li-$i'><span class='ll' onclick='toggleAliases($id,$i)' id='followInput_$i' ><span>[<span id='followPlus_$i'>+</span>]</span> " . reverseName($name) . "</span>";
    print "&nbsp;&nbsp;<span class='hint'>(";
    print "<a class='hint' style='color:#555' href=\"/s/" . urlEncode(reverseName($name)) . "\">search</a>, <span class='ll hint' id='rmfx-$i' onclick='removeFollow($i,$id)'>unfollow</span>)</span>";
    print "<ul id='followUl_$i' style='display:none;list-style:none;padding-left:5px'>";
    my $j = 0;
    for my $f ( @fs ){
        my $alias = $f->alias;
        my $rev_name = reverseName( $alias);
        my $checked = $f->ok ? 'checked="1"' : '';
        my $id = $f->id;
        print "<li> <input type='checkbox' name='alias_$i-$j' id='alias_$i-$j' onclick='updateFollowAlias1($id,$i,$j)' value='$id' $checked >" . $f->alias . " <span id='change_indicator_$i-$j'></span>";
        $j++;
    }
    print '</ul>';
    return;
}


 
if ($ARGS{c} eq 'updateFollowX') {
    if( !defined( $user->anonymousFollowing ) ){
        print $m->scomp("followx/firstTimeDialog.pl", eId => $ARGS{eId});
        return;
    }
    my $i = 0;
    my @msgs;
    my @authors;
    for my $author ( $entry->getAuthors ){
        push @authors, $author;
        my $f = xPapers::FollowerMng->get_objects_iterator( query => [ uId => $user->id, original_name => $author ] )->next;
        if( !$f ){
            $f = $user->add_to_followers_of( $author );
        }
        my $rev_auth = reverseName( $author ); 
        my $fid = $f->id;
        push @msgs, qq{$rev_auth (<span class='ll' id='rmfx-$i' onclick='removeFollow($i,$fid)'>unfollow</span>)};
        $i++;
    }
    print 'Following: ' . ( join ', ', @msgs ) . '.';
    return;
}

if ($ARGS{c} eq 'updateFollowAlias') {
    my $f = xPapers::Follower->get( $ARGS{foId} );
    $f->ok( $ARGS{ok} );
    $f->save;
    return;
}

if ($ARGS{c} eq 'markAliasesAsSeen') {
    my $f = xPapers::Follower->get( $ARGS{foId} );
    my $f_it = xPapers::FollowerMng->get_objects_iterator(
        query => [ uId => $f->uId, original_name => $f->original_name ],
    );
    while( my $fa = $f_it->next ){
        $fa->seen(1);
        $fa->save;
    }
    return;
}

if ($ARGS{c} eq 'removeFollow') {
    my $fid = $ARGS{fid};
    $user->remove_from_followers_of( $fid );
    return;
}

if ($ARGS{c} eq 'unfollowName') {
    print $ARGS{name};
    for my $f ( $user->unfollowName( $ARGS{name} ) ){
        print $f->alias, ' ';
    }
    return;
}

if ($ARGS{c} eq 'deleteFilter') {
    jserror("Not yours") unless $filter->{owner} == $user->id;
    $filter->delete;
    return;
}

if ($ARGS{c} eq 'setOpenURL') {
    jserror("Need to log in") unless $user->{id};
    if ($ARGS{rId}) {
        $user->rId( $ARGS{rId} );
    } else {
        my $resolver = xPapers::Link::Resolver->new(
            url => $ARGS{openurl},
            weight=>-1,
        );
        $resolver->save;
        $user->rId($resolver->id);
    }
    $user->save;
    return;
}

if ($ARGS{c} eq 'saveNote') {
    jserror("Need to log in") unless $user->{id};
    jserror("Need entry") unless $entry;
    my $note = $user->note_for_entry( $entry ) || Papers::Note->new( uId => $user->{id}, eId => $ARGS{eId}, created=>DateTime->now );
    $ARGS{body} =~ s/(\<|&lt;)!--.*?--(\[[^\]]*\])?(&gt;|\>)//sig;
    my $filter = new HTML::TagFilter;
    $filter->allow_tags( {
            sup => { none => [] },
            sub => { none => [] },
            blockquote => { none => [] }
        }
    );
    $ARGS{body} = $filter->filter($ARGS{body});
    $note->modified(DateTime->now);
    $note->body( $ARGS{body} );
    $note->save;
    print $note->id;
    return;
}
#
# Operations on $list require ownership
#
jserror("Not allowed") unless $list->{owner} and $list->{owner} eq $user->id;

if ($ARGS{c} eq 'resetList') {
    $list->entries([]);
    $list->save;
} elsif ($ARGS{c} eq 'renameList') {
    # Check that we don't already have one with that name
    my $oth = xPapers::Cat->new(name=>$ARGS{name},owner=>$user->id);
    jserror("You already have a list with name `$ARGS{name}`") if $oth->load_speculative;
    $list->name($ARGS{name});
    $list->save;
} elsif ($ARGS{c} eq 'deleteList') {
    $list->delete;
} elsif ($ARGS{c} eq 'linkListToFilter') {
    $list->{filter_id} = $filter->id;
    $list->save;
} elsif ($ARGS{c} eq 'unlinkListFromFilter') {
    $list->{filter_id} = 0;
    $list->save;
} 


return "OK";


</%perl>
