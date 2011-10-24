<%perl>
use xPapers::Link::Affiliate::QuoteMng;

my $st = $ARGS{recent} ? "Most recently added entries" :
         $ARGS{uncat} ? "Material to categorize" :
         "";
my $cat = $ARGS{__cat__};
my $direct = xPapers::Cat->new(id=>$cat->id,name=>($cat->{catCount} ? "Material to categorize" : "Content"));
my %sortinf = %SORTER;
$ARGS{sort} = undef if $ARGS{sort} eq 'relevance' and !$ARGS{catq};
$ARGS{sort} ||= 'relevance' if $ARGS{catq};
$sortinf{'book price'} = ['book price','affiliate_quotes.price asc'];
$ARGS{sort} = undef unless $sortinf{$ARGS{sort}};
if ($cat->{catCount}) {
    $sortinf{cat} = ['categories','dfo,main.authors asc, main.date desc, main.id'];
    $ARGS{sort} ||= 'cat';
} else {
    $ARGS{sort} ||= 'firstAuthor';
}
$ARGS{limit} ||= $DEFAULT_LIMIT;
$ARGS{start} ||= 0;
$ARGS{new} = 1;

# for quickcat link
$rend->{cur}->{root} = $cat;

# for delete link
$rend->{cur}->{currentList} = $cat->id if $cat->canDo("DeletePapers",$user->{id});

my $edfo = $ARGS{uncat} ? $cat->{dfo} : $cat->{edfo};
my $qu = xPapers::Query->new;

if ($ARGS{uncat} and $cat->{__user_is_editor}) {
</%perl>

<p><em>This page shows material to categorize inside this category. As Editor, you have the option of setting some items aside in order to progress through the list (click "Set aside for now").<br><%$ARGS{setAside}? "<b>You are currently displaying the  items which have been set aside. Click <a href=\"/browse/".$cat->eun."?uncat=1\">here</a> for the normal listing.</b>" : "If you want to see the items you or previous editors have set aside, click <a href=\"$ENV{REQUEST_URI}&setAside=1\">here</a>"%>.</em></p>

<%perl>
}

# search inside
my ($searchWhere, $searchSelect, $ftJoin);
if ($ARGS{catq} or $ARGS{cats}) {
    $sortinf{relevance} = ['relevance','relevance desc'];
    ($searchWhere,$searchSelect,$ftJoin) = $qu->ftQuery($ARGS{catq},filters=>$filters);
    $searchWhere = " and $searchWhere"; 
    $searchSelect = ", $searchSelect";
}

my ($gid, $catWhere, $xjoin);
$xjoin = $ftJoin;
if ($ARGS{sort} eq 'cat' or $ARGS{recent}) {
    $catWhere = " cats.dfo >= $cat->{dfo} and cats.dfo <= $edfo ";
    if ($ARGS{recent}) {
        $catWhere .= " and added >= date_sub(now(),interval 90 day)";
        $gid = 'group by main.id';
    }
} elsif ($ARGS{sort} eq 'book price') {
    my $locale = xPapers::Link::Affiliate::QuoteMng->computeLocale(
        user => $user,
        ip => $ENV{REMOTE_ADDR}
    );
    $xjoin .= " join affiliate_quotes on (affiliate_quotes.eId=main.id and locale='$locale')"; 
    $catWhere = " cats.dfo >= $cat->{dfo} and cats.dfo <= $edfo ";
    $catWhere .= " and pub_type = 'book'";
    $gid .= " group by main.id";
} else {
#    $catWhere = " cats.dfo >= $cat->{dfo} and cats.dfo <= $edfo ";
    $xjoin .= " join ancestors on (aId = '$cat->{id}' and ancestors.cId=cats.id)";
    $catWhere = "true";
    $gid = 'group by main.id';
}
my $since;
if ($ARGS{since}) {
    $since = "and cme.created > '" . quote($ARGS{since}) . "'";
}

if ($ARGS{uncat}) {
    if (!$ARGS{setAside}) {
        $catWhere .= " and not setAside";
    } else {
        $catWhere .= " and setAside=1";
    }
} 

# query
my $qs = "
    select SQL_CALC_FOUND_ROWS main.id, date(cme.created) as added, cats.dfo, cats.name, cats.id as cId, pLevel $searchSelect
    from cats
    join cats_me cme on (cme.cId=cats.id)
    join main on (cme.eId=main.id)
    $xjoin
    where 
        $catWhere
        $searchWhere
        $since
        and (
            %s
        )
    $gid
    order by $sortinf{$ARGS{sort}}->[1]
";
#push @$filters, ('added', { gt => $ARGS{since} }) if $ARGS{since};

# This keeps track of whether we fetch one of the items of the previous page to see what cat it was in
my $modifier = $ARGS{start} > 0 ? 1 : 0;

$qu->preparePureSQL($qs,$filters, { start=> $ARGS{start} - $modifier, limit=>$ARGS{limit}, inject=>1 });

#$qu->{debug} = $m if $SECURE;
#print $qs;
#print $qu->sql if $SECURE;
eval {
#return if $SECURE;
$qu->execute;
};
#$root->elog("query",$qs) if $SECURE;
if ($@) {
    error("There is an error in your query (are you misusing some special characters?)");
}

if ($HTML) {
    print mkform('allparams',"",\%ARGS);
    jsLoader(1);
    </%perl>
    <div class='miniheader' style='border-top:1px solid #aaa'>
    <table width="100%">
        <tr>
        <td style='width:80px;text-align:left'>
            <div id="foundCap" style="text-align:left">
            <% $st ||$qu->foundRows %> found
            </div>
        </td>
        <td>
            <form id="inside">
                Search inside: <input type="text" name="catq" value="<%$ARGS{catq}%>">
                <input type="hidden" name="sort" value="relevance">
                <input type="submit" value="go" class='button'>
            </form>


        </td>
        <td align="right" width="320px">
            (<span class='ll' title='Display more options' onclick="$('optrow').show()">import / add options</span>) &nbsp;
            <% sorter(\%ARGS,'',\%sortinf,$ARGS{catq})%>
        </td>
        </tr>
        <tr style="display:none" id='optrow'>
        <td>Options: </td>
        <td colspan="2">
% if($cat->canDo("AddPapers",$user->{id})) {
        <script type="text/javascript">var currentList=<%$cat->id%>;</script>
        <%perl>
        $m->comp("../search/papercomplete.js",%ARGS,_l=>$cat,caption=>"Add an entry to this list: ");
        </%perl>
        <span class='ll hint' onclick='faq("addBox")'>(help)</span>
        <br>
        <span style=""><span class="ll" title="Add entries from a bibliography" onclick="window.location='/utils/batch_import.pl?addToList=<%$cat->id%>'">Batch import</a>.</span> Use this option to import a large number of entries from a bibliography into this category.
        <br>
        <span style='font-size:11px'>(<span class='ll' onclick='$("optrow").hide()'>hide options</span>)</span>
%}
        </td>
        </tr>

    </table>
    </div>
%if ($ARGS{catq}) {
    <div style='font-weight:bold'>
    Content filtered with query: `<%$ARGS{catq}%>`. 
    <a href="/browse/<%$cat->eun%>"><% $cat->pLevel > 1 ? "Show all entries" : "&lt;&lt; Back to table of contents"%></a>.<br>
    </div>
%}
<table class='nospace' width="100%">
<tr>
<td class='main_td'>
    <div class='rlist'>
<%perl>
}

$q->param('cId',$cat->id); #sometimes we don't get the cat through cId
writeLog($root->dbh,$q, $tracker, "browse",undef,$s);

print $rend->startBiblio(
    undef, {
        found=>$qu->foundRows-$modifier,
        header=>undef #$cat->name
    }
);
my @stack;
my %found;
my $struct = ($ARGS{sort} eq 'cat');
print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$ARGS{limit},$ARGS{limit},$qu->foundRows));

my $catFromPrevPage = undef;
if ( $modifier and my $fromPrevPage = $qu->next ) {
   $catFromPrevPage = $fromPrevPage->{cId}; 
}

while (my $e = $qu->next) {

    $e->{pubAdded} = $qu->{row}->{added} if $ARGS{sort} eq 'added';

    # if cat is different from current, open/close cats as required
    # print "<h2>stack: " . join(", ", @stack) . "</h2>" if $SECURE;

    if ($struct) {

    unless ($e->{cId} == $stack[-1]) {

        my $c = xPapers::Cat->get($e->{cId});
        $rend->{cur}->{root} = $c;
        #print "C: $c->{id} / $e->{cId}<br>" if $SECURE;
        my @a = $c->pAncestry();
        #print "<h3>$cat->{pLevel} a: " . join(", ", map { $_->{id} } @a) . "</h3>" if $SECURE;
        splice(@a, 0, $cat->{pLevel}); # cut out up to the viewed cat
        push @a,$direct if $c->{id} == $cat->{id} and $#a==-1 and $cat->{catCount} and !$ARGS{uncat};
        #print "<h3>$c->{pLevel} a: " . join(", ", map { $_->{id} } @a) . "</h3>" if $SECURE;

        for (0..$#a) {
            # skip until divergent
            next if $#stack >= $_ and $stack[$_] == $a[$_]->{id};
            # here we differ, close current cats and open new ones
            #print "GOT DIV $c->{id}<bR>" if $SECURE;

            for my $i ($_..$#stack) {
                last if $i < 0;
                print $rend->afterGroup($i);
                lafter($stack[-1],\%found);
                #print "AFTER<br>";
                pop @stack;
            }

            for my $i ($_..$#a) {
                my $id = join("-", map { sprintf("%012d", $_->{dfo}) } @a[0..$i]);
                push @stack,$a[$i]->{id};
                print $rend->beforeGroup($#stack,"c$id");

                # see also
                my $also;
                if ($a[$i]->{catCount}) {
                    $also = 
                        join(", ",
                        map { $rend->renderCatC($_) }
                        grep { $a[$i]->{id} != $_->{ppId} }
                        @{$a[$i]->children_o}
                        );
                    $also = "<br><div class='also'>See also: " . $also . "</div>" if $also;
                }
                my $displayName = $a[$i]->{name};
                $displayName .= " (continued)" if $a[$i]->{id} == $catFromPrevPage;
                print $rend->renderHeader("c$id", {header=>'%s%s'}, [$displayName,$also],$i);
                $xPapers::Utils::CGI::REQ_LOGGED = 0;
                $q->param('cId',$a[$i]->{id});
                writeLog($root->dbh,$q, $tracker, "browse",undef,$s);
#                print $rend->renderHeader("c$id", {header=>'%s'}, [join(" :: ", map {$_->{name}} @a[0..$i])],$i);
            }
            last;
        }

    }
    if ($e->{id} eq '%') {
#        print "<div style='padding:10px; font-style:italic;font-size:12px'>Nothing here.</div>";
        next;
    }
    $found{$stack[$_]}++ for (0..$#stack);

    } #struct

    print $rend->renderEntry($e);
#    print $rend->afterEntry($e);

}

# close all open cats
for (0..$#stack) {
    print $rend->afterGroup("c$stack[$_]");
    lafter($stack[$_],\%found);
}
print "<div style='padding:5px;font-style:italic'>Nothing in this category. <span style='font-style:normal'>Everyone can categorize entries. Please help if you have the expertise.</span></div>" unless $qu->foundRows or !$HTML;
print $rend->endBiblio;
print "</div>" if $HTML;
#$ARGS{cId} = $stack[-1] if $#stack > -1;
print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$ARGS{limit},$ARGS{limit},$qu->foundRows));


sub lafter {
    my ($id,$found) = @_;
    return unless $HTML;
    unless ($found->{$id}) {
        print "<div style='padding:5px;font-style:italic;font-size:11px'>Nothing found $id.</div>";
    }
}


</%perl>
%if ($HTML) {
    </div>
    </td>
    <td class='side_td'>
    <& ../side.html, %ARGS &>
    </td>
    </tr>
    </table>
%}
