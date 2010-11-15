<%perl>
if (0) {
#    $m->comp("header.html");
</%perl>
<h3>Sorry</h3>
This service is currently disabled as we are trying to resolve a problem. It should be re-activated in 24 hours. 
<%perl>
return;
}
use xPapers::Util qw/cleanNames/;
my $h = ( !$ARGS{embed} ? 'header.html' : 
          ($ARGS{embed} eq '2' ? '' : '') );
my $br = $ARGS{embed} ? "\n" : '<br>';
$m->comp($h,title=>"Edit", onLoad=>"",%ARGS) if $h;
# check signed in
if (!$user->{id}) {
        print "<div style='padding:10px'>";
        $m->comp("/checkLogin.html",%ARGS,noheader=>1);
        print "</div>";
        return;
        #print "You need to be logged in before editing or submitting entries. <p>";
        #$m->comp('inoff.html',noheader=>1,after=>"$PATHS{EDIT_SCRIPT}?id=$ARGS{id}\&step=$ARGS{step}");
        #return;
} 
# check quota
if ($user->danger($ARGS{id} ? "Edit" : "Submit",1)) {
    print  "<p><b>You have reached your quota of edits / submits for today, sorry. Please contact us if you wish to increase your quota.</b>";
    return;
}


# if first step
if ($ARGS{step} eq '1') {
    $m->comp('step1.html',%ARGS);
    return;
}
if ($ARGS{embed} == 1) {
#        print "<script type='text/javascript'>var blocks=['";
#        print join("','",qw/basic publicationDetails onlineDetails classificationDetails adminOnly submitBlock/);
#        print "'];</script>\n";
#    print '<script type="text/javascript">var currentBlock="basic";</script>';
}
print "<div id='editor'>\n" unless $ARGS{embed} == 2;


my %a = %ARGS;
my $new;
my $errors ="";

# Check if we have an incomplete submission for addition, and preprocess uploaded file
my $badSubmit = 0;
my $e = $q->param('id') ? xPapers::Entry->get($q->param('id')) : xPapers::Entry->new;
error("Bad entry id") unless $e;
unless ($e->lock($user->{id})) {
    error("Someone else is currently editing this entry. Please try again later.",$ARGS{embed});
}


my $diff = xPapers::Diff->new;
$diff->before($e);
$diff->session(uniqueKey());
$diff->host($ENV{REMOTE_ADDR});
my $inFile;
if ($q->param('write')) {
    form2entry($q,$b,$SECURE, $e);
    $errors .= "Some mandatory information is missing." .$br if isIncomplete($e) and $e->{pub_type} ne 'unknown';
    if ($ARGS{fileAction} =~ /replace/) {
        $inFile = $ARGS{upsession};
        if ($inFile !~ /\.(pdf|doc|rtf|txt|docx|ps)$/i) {
            unlink "$PATHS{UPLOAD}/$e->{session}.*" unless $ARGS{embed}; 
            $errors .= "Invalid file format. The only valid formats are pdf, doc (MS Word), docx (new MS Word), rtf, postscript, and plain text (.txt). [$e->{session}, $inFile]$br";
        }
    }
    $e->{fileAction} = 'replace2' if $e->{fileAction} eq 'replace' and $errors and !$ARGS{embed};
}


# Open / create for editing or re-editing
$new = 0;
if (!$q->param('write') or $errors) {
    if (!$errors) {
        if (!$ARGS{'id'} or !($e=xPapers::Entry->new(id=>$ARGS{id})->load)) {
            if ((!$ARGS{author} or !$ARGS{title}) and !$ARGS{force}) {
                print "<div class='step1 centered'><br>";
                print gh(" Oops..");
                print "You need to provide a title and author first.<br><br>";
                print "<input type='button' value='Try again' onclick='history.go(-1)'></div>";
                return;
            }
            $e = new xPapers::Entry;
            $e->{pub_status} = 'published';
            $e->{type} = 'article';
            $e->{pub_in} = 'journal';
            $e->{pub_type} = 'journal';
            $e->{fileAction} = 'none';
            $e->addAuthors(parseAuthors($ARGS{author}));
            $e->{addToList} = $ARGS{addToList};
            $e->{title} = $ARGS{title};
            my @m = xPapers::EntryMng->fuzzyMatch($e);
            if (!$ARGS{force} and fuzzyGrep($e,\@m,0.3,1)) {
                $rend->{bib} = $b;
                found(\%ARGS,$e,\@m,$rend);
                return;
            }
            $new = 1;
        } else {
            $e->{bookmark} = $ARGS{bookmark};
        }
        #$e->{session} = "1" . time() . rand(1000000);
        #$e->{session} =~ s/\.//g;
    } else {
        if ($ARGS{embed}) {
            jserror($errors);
        } else {
            $e = $e;
            $new = !$q->param('id');
            print "<div style='color:red'>There is a problem with your submission:<p>$errors</p></div>";
        }
    }

    # Some harvested items have images replacing special characters.. we can't let people edit those.
    if (($e->author_abstract . $e->title) =~  /<img/) {
        print "Sorry, this item cannot be edited.";
        return;
    }

    print ($ARGS{id} ? gh("Edit entry") : gh("New entry")) unless $ARGS{embed};
    $m->comp('editor.html',e=>$e,new=>$new,%ARGS);
    return;
} 


# Save / create
cleanNames($e);


# Process uploaded file
if ($e->{fileAction} eq 'delete') {

    $e->{file} = "";

} elsif ($e->{fileAction} =~ /replace/) {

    die "invalid extension" unless $inFile =~ /\.(.*?)$/;
    my $ext = $1;

    # figure out new file name
    my $i = 1;
    # get key if new
    $e->setKey unless $e->id;
    my $eid = $e->id;
    while (-e "$PATHS{ARCHIVE}/$eid.$i.$ext") { $i++ };
    my $file = "$eid.$i.$ext";
    `mv $PATHS{UPLOAD}/$inFile $PATHS{ARCHIVE}/$file`;
    #if ($SECURE) {
    #    unlink "$PATHS{ARCHIVE}/$eid.$ext";
    #    `ln -s $PATHS{ARCHIVE}/$file $PATHS{ARCHIVE}/$eid.$ext`;
    #}
    $e->{file} = $file;

    # remove tmp files
    if ($inFile =~ /^(\w+)/) {
        unlink glob("$PATHS{UPLOAD}/$1*"); 
    }

}

# Save / add

#$e->pro(1) if $e->published;
#$e->addSite("pp") if $e->links or $e->file or $e->{fileAction} =~ /replace/;
#print STDERR "First: " . Dumper($e->{sites}) if $e->{sites};
$diff->note($ARGS{note});
#print STDERR Dumper($e->{sites}) if $e->{sites};
# This is an update
if ($q->param('id') and $q->param('id') ne '') { 
    warn "UPDATE";
    $diff->after($e);
    $diff->compute;
    #jserror(Dumper($diff->{diff}));
    #print "<pre>" . Dumper($diff->{diff}) . "</pre>";
    $diff->uId($user->{id} || 0);
    #print "null: " .$diff->is_null;
    $diff->accept unless $diff->is_null;
} 
# This is a new entry

else {
    warn 'INSERT';
   $e->{source_id} = 'pp//' . $e->id;
   $e->{db_src} = 'user';
   #print Dumper $e->{authors};
   $diff->uId($user->{id}||0);
   $diff->create_object($e); 
   $diff->accept;
   $e = $diff->object;
   $e->elog("after create:$e->{title}");
   xPapers::EntryMng->addAdded($e);
}

# Set/remove pro flag
#$e->calcPro;
# Do the same to the user
$user->calcPro unless $user->pro;

# Make separate diffs for category changes
my @nm;
foreach ($q->param()) {
    next unless /^cat-(\d+)$/;
    my $cat = xPapers::Cat->new(id=>$1)->load;
    next unless $cat;
    push @nm, $cat;
}
xPapers::Cat->mkDiffs($e,\@nm,$diff,"accept");

$e->syncSites({mp=>2});

# Add to user cat if so requested
if ($ARGS{addToList}) {
    #print STDERR "here: $ARGS{addToList}, $e->{id}";
    my $uc = xPapers::Cat->get($ARGS{addToList});
    $uc->addEntry($e,$user->{id});
    #print STDERR "done";
}

$e->unlock($user->{id});

writeLog($root->dbh,$q, $tracker, "edit", $MISCLOG,$s);

# say something  

if ($ARGS{embed}) {
    # print back
    $rend->{entryReady} = 1;
    $e->load;
    print $rend->renderEntry($e);
    return;
} else {
    my $aft = $q->param('after'); 
    print gh("Submission saved.");
    print "<p>Thanks you for your contribution! Your submission should be processed shortly.<p>";
    if ($aft) {
        print "<a href='$aft>Click here to return where you left.</a>";
    } else {
        print "<a href='$PATHS{BASE_URL}'>Click here to return to the home page.</a>";
    }
}

print "</div>";





sub make_select {
	
	my $selected = shift;
	my $default = shift;
	my $t = shift;
	my @options =@$t;
	my $r = "";
	foreach my $o (@options) {
		$r .= "<option name='$o' ";
		$r .= ($selected eq $o or (!$selected and $default eq $o)) ? " selected " : "";
		$r .= ">$o</option>\n";
	}
	return $r;
}

#
# Found
#

sub found {

    my ($args,$e,$m,$rend,$other) = @_;
    print "<div class='step1'>";
    print gh('Check existing entries');
    $args->{force} = 1;
    my $edp = join(",", 
                map { "$_:\"" . encode_entities($args->{$_}) . "\"" } 
                qw/title embed force author addToList/
                ); 
    print <<END;
<form id="myform" action="$PATHS{EDIT_SCRIPT}">
<input type="hidden" name="force" value="1">
<input type="hidden" name="title" value="$args->{title}">
<input type="hidden" name="embed" value="$args->{embed}">
<input type="hidden" name="author" value="$args->{author}">
<input type="hidden" name="addToList" value="$args->{addToList}">
</form>
<b>This work might already be in the database.</b><br>
Please verify that your submission is not already available below. You may either <span class='ll' onclick='customEditor({$edp})'>continue with your submission</span> or edit one of these existing entries. Duplicate submissions will normally be rejected. 

<p>Some of the entries shown below might not be publicly displayed on the site because they do not meet all our requirements at the moment (online availability for $s->{niceName}, a suitable category assignment for MindPapers). They might also have been officially removed from the public site ("deleted"), in which case they are no longer available for editing.<p>
END

    $rend->{noExtras} = 1;
    $rend->{compact} = 0;
    $rend->{limited} = 0;
    $rend->{LIMITED} = 0;
    $rend->{noOptions} = 1;
    $rend->{showAbstract} = 0;
    $rend->{linkNames} = 0;
    print "<b>Papers found:</b>";
    print $rend->startBiblio($b,{nosh=>1});
    print $rend->beginCategory;
    foreach my $f (@$m) {
        next unless sameEntry($e,$f,0.3,1);
        $rend->{foundOptions} = !$e->{deleted};
        print $rend->renderEntry($f);
    };
    print $rend->endCategory;

}


sub block {
    my ($id,$caption,$embed,$active) = @_;
    if ($embed==1) {
        my ($icon,$disp,$xclass);
        if ($active) {
            $icon = "[--]";
            $disp = "block";
            $xclass = "acBlockHact";
        } else {
            $icon = "[+]";
            $disp = "none";
            $xclass = "acBlockHna";
        }
        return "<div class='acBlockH $xclass' id='$id' 
                    onmouseover='achOver(\"$id\")'  
                    onclick='achClick(\"$id\")' 
                    onmouseout='achOut(\"$id\")'>
                    <div class='acBlockHI'>
                    <span id='${id}I'>$icon</span>
                    $caption
                    </div>
                </div>
                <div id='${id}C' style='display:$disp' class='acBlockC'>";
    } else {
        return "<div class='block'>";#<div class='acBlockHact' id='$id'>$caption</div><div class='acBlockC'>";
    }
}
</%perl>
