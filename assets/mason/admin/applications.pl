<& ../header.html, subtitle=>"Editorship applications" &>
<% gh("Applications") %>
<%perl>
use Text::Textile qw/textile/;
</%perl>
<p>
<script type="text/javascript">
function process(id) {
    formReq($('edf'+id), function() {$('cat'+id).hide()});    
}
function deleteApp(id) {
    admAct("deleteApplication",{id:id},function() {
        $('app-'+id).remove();
    });
}
</script>
Message templates:<br>
<table style='border:2px solid #aaa'>
<tr>
<td width="400px" valign="top">
    <%perl>
    print "Acceptance message:<br>";
    my $c = getFileContent($DEFAULT_SITE->fullConfFile( 'msg_tmpl/ed_app_accepted.txt' ));
    print textile($c);
    </%perl>
</td>
<td width="400px" valign="top">
    <%perl>
    print "Rejection message:<br>";
    $c = getFileContent($DEFAULT_SITE->fullConfFile( 'msg_tmpl/ed_app_rejected.txt' ));
    print textile($c);
    </%perl>
</td>
</tr>
<tr>
<td colspan="2">
The tag [CUSTOM_MSG] will be replaced with what you enter in the box next to an applicant's name, if you enter anything.
</td>
</tr>
</table>
<br><br>
Note that editorships will not be effective immediately. The user has to confirm first. If a user declines or takes more than two weeks to confirm, his/her application will be cancelled and existing applications for the category will appear here again.
<br><br>
<%perl>

# Cancel non-accepted applications
$root->dbh->do("update cats_eterms set status=-20 where status=10 and confirmBy<now()");

my $covered = xPapers::CatMng->get_objects(require_objects=>['editors']);
my %covered = map { $_->{id} => 1 } @$covered;

my %offered = map { $_->{cId} => 1 } @{xPapers::ES->get_objects(query=>[status=>10])};

#print Dumper(\%covered);

my $es = xPapers::ES->get_objects(require_objects=>['cat'],query=>[status=>{ge=>0},status=>{le=>5}],sort_by=>['t2.dfo']);

my $submit = "</div><input type='button' onclick='process(%s)' value='Accept selected'> <input type='button' onclick='\$(\"declineAll%s\").value=1;process(%s)' value='Decline all'></form></div>";
my $cc;
my $cco;
my $confirmPending = 0;
my @stack;
for my $e (@$es) {
    next if $covered{$e->cId} or $offered{$e->{cId}};
    next if $confirmPending and $cc == $e->cId;

    my $u = $e->user;
    my $first = "";
    my $cat;

    unless ($cc == $e->cId) {
        # if we already have picked someone, skip that cat
        # this isn't used anymore
        if (0 and $e->status==10 or $covered{$e->cId}) {
            print "CONFIRM: $e->{cId}, $e->{uId}<br>";
            $confirmPending = 1;
            $cc = $e->cId;
            next;
        } else {
            printf($submit,$cc,$cc,$cc) if $cc and !$confirmPending;
            $confirmPending = 0;
        }
        $cc = $e->cId;
        $cat = $e->cat;
        $first = "checked";
        my $space = 0;
        # cut the stack based on level
        #splice(@stack,$cat->pLevel-1,$#stack);
        #print join(",",@stack) . "<br>";
        my $sidx = indexOf(\@stack,$cat->{ppId});
        # if parent is in stack, number of spaces of parent + 1 unit
        if ($sidx > -1) {
            $space = $sidx*20 + 20; 
            splice(@stack,$sidx+1,$#stack) unless $sidx == $#stack;
            push @stack,$cat->id;
        } 
        # if parent is not in stack, clear 
        else { 
            @stack = ($cat->id);
        }
        print "<div id='cat$cat->{id}' style='margin-left:${space}px;border:1px solid #aaa;margin-top:5px;margin-bottom:5px;padding:5px'><form id='edf$e->{cId}' action='/admin.pl'><input type='hidden' name='cId' value='$cat->{id}'><input type='hidden' name='c' value='processEdApps'><input type='hidden' id='declineAll$e->{cId}' name='declineAll' value='0'>";
        my $cur = join(", ", map { $rend->renderUserC($_,1) } $cat->editors);

        print "<b>" . $rend->renderCatC($cat) . " </b><span class='subtle'>$cat->{id} $cur</span><div style='padding:5px'>";
    }
    my $rec = $e->recursive ? '**' : "";
    print "<div id='app-$e->{id}'><input type='radio' value='$u->{id}' name='choice' $first> <input type='checkbox' name='keep$u->{id}' checked> keep " . $rend->renderUserC($u,1) . " [ $u->{pubRating} / $u->{pubRatingW} / $u->{nbCatL} ]"  . " <input type='text' size='60' name='msg$u->{id}'> <span class='ll' onclick='deleteApp($e->{id})'>delete</span>";
    if ($e->{comment}) {
        print "<div>";
        print substr($e->{comment},0,500);
        print "</div>";
    }
    print "</div>";


}
printf($submit,$cc,$cc,$cc) if $cc and !$confirmPending;

</%perl>

