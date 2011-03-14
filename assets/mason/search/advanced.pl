<%perl>
    

# Header

$m->comp('../header.html', subtitle=> 'Advanced search');

# Check query
error("Your query is too short") unless $ARGS{advMode} eq 'fields' or $ARGS{fId} or 2 < length($ARGS{advMode} eq 'normal' ? "$ARGS{w_ez}$ARGS{w_ezn}$ARGS{w_ezn2}" : join('',$ARGS{w_e},$ARGS{w_a},$ARGS{w_g},$ARGS{w_p}));

if ($HTML) {
</%perl>
<table class="wrap_table">
<tr>
<td class="main_td" id="main">
<%perl>
#print Dumper($filters) if $SECURE;
#print Dumper($ARGS{proOnly}) if $SECURE;
}

my ($q,$error);
if ($user->{id} and ( (!$ARGS{fId} and $ARGS{name}) or $ARGS{op} =~ /save/i ) ) {
    ($q, $error) = xPapers::Query::saveForm($user,\%ARGS);
    $ARGS{fId} = $q->id unless $error;
} elsif ($ARGS{fId}) {
    $m->comp("../checkLogin.html",%ARGS);
    $q = xPapers::Query->new(id=>$ARGS{fId})->load_speculative;
    error("Not yours") unless $q->owner == $user->id or ($q->trawler and $q->trawlerCat->isEditor($user)) or $SECURE;
    $q->executed('now');
    $q->save;
    if ($ARGS{op} =~ /save/) {
        $error = $q->loadForm(\%ARGS);
        $q->save unless $error; 
    }
} else {
    $q = xPapers::Query->new;
    $error = $q->loadForm(\%ARGS);
}
error($error) if $error;

$ARGS{sort} ||= 'relevance';
$ARGS{start} ||= 0;
$ARGS{limit} ||= 100;

#hack
$ARGS{idx} = 2 if $q->{name} =~ /^Autocategorization/ and !$q->owner;

$q->{debug} = $m if $SECURE;
push @$filters, ('added', { gt => $ARGS{since} }) if $ARGS{since};
$q->prepare({
    user => $user, 
    sort=>$ARGS{sort}, 
    start=>$ARGS{start},
    limit=>$ARGS{limit},
    lowRelevance=>$ARGS{lowRelevance},
    filter=>$filters,
    index=>$INDEXES{$ARGS{idx}} || undef

});
$q->{dontDieOnError} = 1 if $q->{advMode} eq 'fields'; 
unless ($q->execute) {
    
    print gh('Ooops..') . "Your query has generated an error. Its syntax might be wrong. Here is the error message: <blockquote>$DBI::errstr</blockquote}";
    return;

}
#return;

my ($header, $header2);
if ($ARGS{lowRelevance}) {
    my $list = xPapers::Cat->new(id=>$ARGS{lowRelevance})->load_speculative; 
    return unless $list;
    $header = "Low relevance results for `" . $q->name . "`<br> currently not in category `". $list->name . "`";
    $header2 = " <span class='ghx'>(<a href='/advanced.html?fId=$ARGS{fId}'>edit search</a>)</span>";
    $rend->{cur}->{addToList} = $ARGS{lowRelevance};
} else {
    $header = "Results for custom query " . ($q->name ? "`" . $q->name . "`" : "");
    for (keys %ARGS) {
        delete $ARGS{$_} unless $ARGS{$_};
    }
    if ($ARGS{fId}) {
        $header2 = " <span class='ghx'>(<a href='/advanced.html?fId=$ARGS{fId}'>edit</a>)</span>";
    } else {
        $header2 = " <span class='ghx'>(<a href='" . mkquery('/advanced.html',\%ARGS,{},\%NOCOPY) . "'>edit</a>)</span>";
    }
}

if ($HTML) {
    print mkform('allparams','',\%ARGS);
    jsLoader(1);
}

$rend->{cur}->{showRelevance} = 1;

print $rend->startBiblio(undef, { 
    header => $header,
    found => $q->foundRows,
    header_part2 => $header2,
    header_right=>nbFound(\%ARGS,'',$q->{found},$q->{limit},$q->{offset}, sorter(\%ARGS,'',\%SORTER,1))
});

print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$ARGS{limit},$ARGS{limit},$q->{found},'')) if $ARGS{start};
while (my $e = $q->next) {
    print $rend->renderEntry($e);
    print $rend->afterEntry;
}

print $rend->endBiblio;
print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$ARGS{limit},$ARGS{limit},$q->{found},''));


if ($HTML) {

if ($q->{found} < 1) {
print "<p><em>Nothing found.</em>";
}
</%perl>
<td valign="top" class="side_td" align="right">
<& ../side.html, %ARGS &>
</td>
</tr>
</table>

<%perl>
}

writeLog($q->dbh,$m->cgi_object, $tracker, "advsearch",$q->{id} ,$s);

</%perl>
