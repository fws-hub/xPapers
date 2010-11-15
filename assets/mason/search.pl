<%perl>
use xPapers::Utils::Lang qw/ isLang getSuggestion /;

event('search.pl','start');
my $con = $root->dbh;
my $nosh = 0;

# To disable me when debugging
#$user = undef if $user and $user->{id} == 1;

$rend->{flat} = 1;

my $table = xPapers::Entry->meta->table;
# Content control variables
my ($highlight,$renderParams,$areaUser,$jsLoader,$relevance,$readingList, $list, $GMT, @split,$autoSplit, $thisScript, $jlist,$having,$where,$join,$areas,$sect,$order,$limit,$futureLimit,$prefix,$exclude,$title,$subtitle,$extraSelect,$extraGroup,$splitFunc,$miscLog,$group,$stop,$start);

# Content to display alongside results
my ($listClass, $nbFound,$search_header,$extras,$showSorter,$sorter,$footer,$header,$header_part2,$header_right,$warning);
$search_header = $ARGS{search_header} || 'search_header.html';

#
# Limit and offset
#

$futureLimit = $ARGS{nolimit} ? 500 : 
    (   ($ARGS{limit} and $ARGS{limit} <= 500) ? $ARGS{limit} : $DEFAULT_LIMIT  );
$limit = $ARGS{__limit} || $futureLimit;

$start = quote($ARGS{start}) || 0;
$start =~ s/^-//;
error("You're reading too much.") if ($start >= 8000);

#
# Filters good for all modes
#

$jsLoader = 1;

$readingList = ($user->{id} ? $user->reads : undef);


# search by relations
#
if ($ARGS{relation}) {
    $where .= " and not (id = " . $con->quote($ARGS{opv}) . ") and relation = " . $con->quote($ARGS{relation}) . " and op2 = " . $con->quote($ARGS{opv});
    $rend->{noCount} = 1;
    $rend->{reload} = 1;
    $rend->{biblioHeader} = undef;
} 

# list view
#
elsif ($ARGS{list}) {
    return unless $SAFE_PARAMS;
    $showSorter = 1;
    $ARGS{sort} = 'pubYear' unless $ARGS{sort};
    if ($readingList and $ARGS{list} eq $readingList->id) {
        $where .= " and not isnull(elists_m.entry_id)";
        $header = $readingList->name;
    } else {
        $list = $ARGS{list}; 
        $header = $list->name;
    }
    $thisScript = 'list.html';
}

# normal search
#
elsif ($ARGS{searchStr} or $ARGS{filterMode} or $ARGS{sugMode} or $ARGS{search}) {
    $ARGS{searchStr} =~ s/^\s+//;
    $ARGS{searchStr} =~ s/\s+$//;
    error("Search string must be at least three characters long.") unless length($ARGS{searchStr}) >= 3;
    $q->param('TOC','0');
    $q->param('root','');
    $subtitle = 'search:' . $ARGS{searchStr};

    $showSorter = 1;

    if ($ARGS{since}) {
        $where .= " and ${table}.added >= '".quote($ARGS{since})."'";
    }

    if ($ARGS{filterMode} eq 'authors') {
#           $where .= " and match authors against('\"" . quote($ARGS{searchStr}) ."\"')";
        my ($au_where,$au_join) = xPapers::Query->authorQuery($ARGS{searchStr},$ARGS{strict},$ARGS{year});
        $where .= " and $au_where";
        $join .= " $au_join";
        my $nice = $ARGS{__nice} || $ARGS{searchStr};
        my $again = $ARGS{__origStr} || $ARGS{searchStr};
        if ($ARGS{year}) {
            $header = ($ARGS{year} eq 'forthcoming') ? "Forthcoming works by $nice" : "Works by $nice published in $ARGS{year}";
        } else {
            $header = "Works by $nice";
        }
        $header .= " (exact spelling)" if $ARGS{strict};
        #print $where if $SECURE;
        if (!$ARGS{__bothModes}) { 
            $header .= "<span class='ghx'> ( ";
            $header .= "<a href='" . mkquery($PATHS{SEARCH_SCRIPT},\%ARGS,{author=>$ARGS{searchStr},searchStr=>$again,filterMode=>'notauthors',sort=>'relevance'},\%NOCOPY) .
                                    "'>view other items matching `$again`</a>, ";
            $header .= "<a href='" . mkquery($PATHS{SEARCH_SCRIPT},\%ARGS,{author=>$ARGS{searchStr},searchStr=>$again,filterMode=>'keywords',sort=>'relevance'},\%NOCOPY) .
                                    "'>view all matches</a> ";
            $header .= ")</span> "; 
            $header_part2 .= $m->scomp("bits/namelinks.html", authors=>$ARGS{__authors});
        } else {
            $header .= "<span class='ghx'> ( <a href='#other'>scroll down for other related works</a> )</span>";
        }

    } elsif ($ARGS{filterMode} eq 'keywords' or $ARGS{filterMode} eq 'notauthors') {

        my $s = $ARGS{searchStr};
        $highlight=1;

        # joe => "joe joe's", to deal with ' stupidly being a word character
        #$s =~ s/([^\s']+)(\s|$)/$1${2}s $1/g;

        my ($wherebit, $selectbit, $joinbit) = xPapers::Query->ftQuery($ARGS{searchStr},%ARGS,filters=>$filters);
        $where .= " and $wherebit";
        $extraSelect .= " $selectbit";
        $join .= " $joinbit";

        my $gooq = $ARGS{searchStr};
        $gooq =~ s/&quot;/"/gi;
        $gooq = urlEncode($gooq);

        $header = "Search results for '$ARGS{searchStr}' <span class='subtle'>(<a href='http://scholar.google.com/scholar?q=$gooq'>try it on Scholar</a>)</span>";

        if ($ARGS{filterMode} eq 'notauthors') {
            $header .= " (not author)";
            $header .= " <span class='ghx'> ( <a href='" . mkquery($PATHS{SEARCH_SCRIPT},\%ARGS,{filterMode=>'authors'},\%NOCOPY) .  "'>search as author name</a> )</span>" if $HTML; 
            my $comma = ($ARGS{searchStr} =~ /,/ ? "" : ',');
            $where .= " and not main.authors like '%;" . quote($ARGS{searchStr}) . "$comma%'";
        }

        $relevance=1;
        $ARGS{sort} = 'relevance' unless $ARGS{sort};

    } elsif ($ARGS{filterMode} eq 'admin') {
        $where .= " and db_src=" . $con->quote($ARGS{db_src}) if $ARGS{db_src};
        $where .= " and date like " . $con->quote($ARGS{date}) if $ARGS{date};
        $where .= " and source like " . $con->quote($ARGS{source}) if $ARGS{source};
        $where .= " and source_id like " . $con->quote($ARGS{source_id}) if $ARGS{source_id};
        $order = "source asc, date desc";
        $order = "date desc, source asc" if $ARGS{date};
        $rend->{noOptions} = 1;
        #$rend->{showAbstracts} = 1;
    }

    event('writelog','start');
    writeLog($root->dbh,$q, $tracker, "search", $MISCLOG,$s);
    event('writelog','end');
# flag search
#
} elsif ($ARGS{crit}) {
    $where .= " and " . $ARGS{crit} . " = 1"; 
    $order = "id asc";
    $rend->{biblioHeader} .= "<h1>Entries marked as " . $ARGS{crit} . "</h1>";

# specified field
#
} elsif ($ARGS{field}) {

    $where .= " and " . $ARGS{field} . " = " . quote($ARGS{value}); 
    $order = "id asc";
    $rend->{biblioHeader} .= "<h1>Custom search:</h1>";


} elsif (0 and $user and $user->{id} == 1 and $ARGS{filterByAreas} eq 'on') {

   @split = ({
        header=>"<span class='header_period'>%s <span style='font-size:smaller'>GMT</span></span>\n",
        idtpl=>"h%s",
        type=>"day",
        fields=>['period','prank'],
        idFields=>['prank'],
        rendConf=>{showPub=>1,extraClass=>''},
        before=>"\n<div class='group'>\n",
        after=>"\n</div>\n",
    });
    $autoSplit=1;
    $jlist = $ARGS{jlist} eq 'all' ? undef : $ARGS{jlist};
   $areaUser = $ARGS{filterByAreas} eq 'on' ? ($user->{id}||$ARGS{areaUser}) : undef;
   $extraSelect = "
            date_format(cats_me.created,'\%b \%D %Y') as period,
            1000000 - to_days(cats_me.created) as prank
   ";
   $where .= " and main.added > date_sub(cats_me.created, interval 1 month) and date >= year(now())";
   $order = 'cats_me.created desc';
   $subtitle = 'New items in your areas';
   $header = "New items";
   $header_part2 = " <span class='ghx'>In <a href='/profile/areas.html'>your areas</a>, by classification date</span>";

# latest additions
#

} elsif (my $lat = $ARGS{latest}) {

    $GMT = 1;
    #$user = undef if $user and $user->{id} == 1;

    # check timezone offset
    #if ($ARGS{tz_offset}) {
    #    #$tz_offset = "+00:00" unless $tz_offset =~ /^(-|\+)(\d\d):(\d\d)$/ and $1 <= 12 and $2 <= 60;
    #} else {
    #    $tz_offset = $TZ_OFFSET_STR;
    #}
    # check range and offset
    error("Bad request") unless $ARGS{range} <= 200 and
                                $ARGS{offset} <= 199 and
                                $ARGS{offset} >= 0;

    $jlist = $ARGS{jlist} eq 'all' ? undef : $ARGS{jlist};
    my $now = $TIME->ymd;
    $where .= " and (date >= year(now()) or date = 'forthcoming' or date='manuscript' or date='unknown' or date='' or isnull(date))";

    if ($ARGS{filterByAreas} eq 'on') {

       $areaUser = ($user->{id}||$ARGS{areaUser}||undef);
       $extraSelect = "
                date_format(cats_me.created,'\%b \%D %Y') as period,
                1000000 - to_days(cats_me.created) as prank
       ";
       $where .= " and main.added > date_sub(cats_me.created, interval 2 month)";
       $where .= " and cats_me.created >= '" . quote($ARGS{since}) . "'" if $ARGS{since};
       $order = 'cats_me.created desc';
       @split = ($SPLIT[0]);


    } else {

        $order = "  date(main.added) desc,
                    case
                        when type='book' then 0
                        when pub_type='journal'  or pub_type='online collections' then 1
                        when db_src='web' or db_src='archives' then 2
                        else 3
                    end,
                    main.source,
                    pub_details,
                    main.id
                    ";

        if ($ARGS{since}) {
            $where .= " and main.added >= '".quote($ARGS{since})."'";
        } else {
            $where .= " and main.added >= date_sub('$now',interval $ARGS{offset} day) and main.added < date_sub('$now',interval " . ($ARGS{offset}-$ARGS{range}) ." day)";
        }

        @split = @SPLIT;
        $extraSelect = $SPLIT_EXTRA;
        $extraSelect .= $split[$_]->{extraSelect} for (0..$#split);

    }

    delete $ARGS{sort}; # we don't understand some options

    $thisScript = '/recent';
    # we use in_l as marker of 'all' because that used to be user submissions, and generally that implies all
    unless ($ARGS{in_l} eq 'on') {
        my @type_conds;
        push @type_conds, "type='book'" if $ARGS{in_b} eq 'on';
        push @type_conds, "pub_type='journal' or pub_type='online collection'" if $ARGS{in_j} eq 'on';
        push @type_conds, "db_src='web' or db_src='archives' or pub_type='manuscript'" if $ARGS{in_w} eq 'on';
        push @type_conds, "false";
        $where .= " and (" . join(" or ", map { "($_)" } @type_conds) . ")";
    }

    # Config clustering

    $autoSplit = 1;

    $subtitle = 'latest additions';
    $header = 
            $ARGS{in_l} eq 'on' ? 'New books and articles' :
             (
                only_in("b",\%ARGS) ? 'New books' :
                only_in('j',\%ARGS) ? 'New journal articles' :
                only_in('w',\%ARGS) ? 'New manuscripts' :
                'New books and articles'
              #$ARGS{preset} eq 'books' ? "New books" :
              #$ARGS{preset} eq 'journals' ? "New journal articles" :
              #$ARGS{preset} eq 'web' ? "New manuscripts" : "New books and articles" 
             );
    $header_part2 = " <span class='ghx'>From the most recently added</span>";
    $rend->{cur}->{flagDirect} = 1;

    writeLog($root->dbh,$q, $tracker, "recent", $MISCLOG,$s);

# people you follow
} elsif ($ARGS{followed}) {

    $header = "Books and articles by people you follow";
    $header .= " <span class='ghx'>From the most recent</span>" if $ARGS{sort} eq 'added';
    $where = " and uId = $user->{id}";
    $join = "join main_authors on (main.id = eId) join followers on name = alias";
    $ARGS{sort} = 'added' unless $ARGS{sort};
    $showSorter = 1;

# pure sql
} elsif ($ARGS{__sql__}) {

    # config the split system if provided
    if ($ARGS{__split__}) {
        @split = @{$ARGS{__split__}};
        $autoSplit =1;
    }
    $renderParams = $ARGS{__renderParams__};

# specific pub
} elsif ($ARGS{pub} or $ARGS{pubn}) {

    $limit = 1000;
    $jsLoader = 0;

    my $j = $ARGS{pub} ? xPapers::Journal->get($ARGS{pub}) : xPapers::Journal->getByName($ARGS{pubn});
    error("Sorry, we do not have historical tables of contents for this publication at the moment.") unless $j;
    my $pub = $j->{name};
    $subtitle = "$pub (contents)";

    # year is either specified or default to first
    my $years = jYears($root->dbh,$pub); 
    error("Nothing found for this journal") unless $#$years > -1;
    my $year = $ARGS{year} || $years->[0]; 
    my $idx = indexOf($years,$year);
    error("Nothing available for this year in this journal") if $idx == -1;
    my $lH;

    $where .= " and pub_type='journal' and source='" . quote($j->{name}) . "' and date like '".quote($year)."'";
    $order = "volume desc, length(issue) desc, issue desc, authors asc";

    # set up formatting
    if (lc $year == 'forthcoming') {
        $lH = "<div class='sh sh0' style='margin-bottom:0;font-size:12px;color:#000'>Forthcoming articles</div>"; 
        $rend->{titleAuthor} = 1;
    }  else {
        $autoSplit = 1;
        if ($j->{showIssues}) {
            push @split,{
                header => "<div class='header_pubissue' <a name='v%s'>Year: %s, Volume: %s, Issue: %s</a></div>",
                fields => ['volume','date','volume','issue'],
            };
        } else {
            push @split,{
                header => "<div class='header_pubissue' <a name='v%s'>Volume: %s, Issue: %s</a></div>",
                fields => ['volume','volume','issue'],
            };
        }
    }

    # footer

    $footer = pager(
        type => "issues",
        showText=>1,
        prevLink => ($idx < $#$years ? "$s->{server}/pub/$j->{id}/" . $years->[$idx+1] : undef),
        nextLink => ($idx > 0 ? "$s->{server}/pub/$j->{id}/" . $years->[$idx-1] : undef),
    );

    $rend->{titleAuthor} = 1;

    my $p = "<form name='vpick' id='vpick' action='$PATHS{SEARCH_SCRIPT}' method=GET style='display:inline'><p><b>Year:</b> ";
    $p .= "<input type='hidden' id='vpickpub' name='pub' value='$j->{id}'>"; 
    $p .= "<select name='year' onchange=\"window.location='/pub/'+\$F('vpickpub')+'/'+this.value\">";
    $p .= opt($_,$_,$year) for @$years;
    $p .= "</select>";
    $p .= "</p></form>";
    $header = "<a href='?pub=$j->{id}'><span class='pub_name'>$pub</span></a>";

    if ($SECURE) {
        my $targetCatPicker = $m->scomp("bits/cat_picker.html",
            caption=>'Target category (optional)',
            cId=>$j->cId,
            onSelect=>"admAct('setJournalTargetCat',{jId:$j->{id},cId:id})"
        );
        $extras .= "<div class='admin'>$targetCatPicker</div>";
    }

    $extras .= "$p$lH"; 
    $listClass='pub';
    $rend->{showPub} = 0;
    #$nosh=1;

    writeLog($root->dbh,$q, $tracker, "journal", $j->{id},$s);

# stored/special request
#
} elsif ($ARGS{special}) {
    my $req;
    error('bad request') unless $req = $SPECIAL_REQUESTS{$ARGS{special}};
    $where .= " and ". $req->{where};
    $order = $req->{order};
	$limit = $req->{limit};
    my $desc = $req->{desc};
    if ($req->{exclude}) {
        $exclude .= "$_|" for @{$req->{exclude}};
        $exclude =~ s/.$//;
    }
    $rend->{entryPrefix} = $req->{prefix};
    $desc =~ s/[\[\]]//g; # remove optional bit markers
    $rend->{biblioHeader} .= "<h1>$desc</h1>";
    $subtitle = $desc;
    $rend->{compact} = 1;
    $rend->{div} = "ol";
    $miscLog = 'special';
}
elsif ($ARGS{crossref}) {
    my $set_spec = quote( $ARGS{set_spec} );
    $header = "Books and articles from CrossRef";
    $header .= " <span class='ghx'>From the most recent</span>" if $ARGS{sort} eq 'added';
    $where = " and set_spec = '$set_spec'";
    $join = "join entry_origin on main.id = eId";
    $showSorter = 1;
}

# for mp+opc
if (!$ARGS{noheader}) {
    $m->comp("/header.html",title=>$s->{HTML_TITLE},subtitle=>$subtitle,%ARGS);
}


#
#  GO!
#

#$header = $ARGS{gh} if $ARGS{gh};
jsLoader($jsLoader) if $HTML and !$ARGS{nojs};

# fix for googlebot bug...
if ($ARGS{sort} eq 'relevance' and $ARGS{filterMode} eq 'authors') {
    $ARGS{sort} = 'pubYear';
}
if (!$order) {
    if ($ARGS{sort} eq 'firstAuthor') {
        $order = 'main.authors asc, main.date desc, main.id asc';
    } elsif ($ARGS{sort} eq 'added') {
        $order = 'main.added desc, main.date desc, main.id asc';
    } elsif ($ARGS{sort} eq 'relevance') {
        $order = 'relevance desc, main.id asc';
    } elsif ($ARGS{sort} eq 'viewings') {
        $order = 'main.viewings desc';
    } else {
        $order = 'main.date desc, main.authors asc, main.id asc';
        $ARGS{sort} = 'pubYear';
    }
}
$rend->{cur}->{showAdded} = 1 if $ARGS{sort} eq 'added' and !$ARGS{al};

#if ($group = $ARGS{group}) {
#    $order = "$group desc";
#}

# Get root category if relevant
my $vRoot;
if ($ARGS{root}) {
	$vRoot = xPapers::Cat->get($ARGS{root});
}
#return if $ARGS{searchStr} =~ /Marjorie/ and !$SECURE;

event('initIterator','start');
my $qu = xPapers::Query->new;
#$qu->{debug} = $m;
if ($SECURE) {
#    $qu->{debug} = $m;
}
if ($ARGS{__sql__}) {
    $qu->preparePureSQL($ARGS{__sql__},$filters);
} else {
    $qu->prepareSQL(
        where=>$where,
        join=>$join,
        order=>$order,
        jlist=>$jlist,
        areaUser=>$areaUser,
        extraSelect=>$extraSelect,
        start=>$start,
        limit=>$limit,
        having=>$having,
        filter=>$filters,
        useGMT=>$GMT,
        inject=>1,
        in => 0
    );
}
#if ($areaUser) {
#    print $qu->sql;
#    return;
#}
eval {
    $qu->execute;
};
if ($@) {
    error("Your query could not be executed, probably because its syntax is incorrect.<p>Note that the following are reserved characters whose use is explained on the <a href='/help/search.html'>the search help page</a>: &amp; | ^ \$ ~ + - \" * ~ &lt; ( ) \@.<br>" . ($SECURE? "<p><pre>$@</pre>" : ""));
}
event('initIterator','end');
event('intermediate','start');

my $foundRows = $qu->foundRows();

#
# Output 
#

# Add reading list hook to renderer
$rend->{cur}->{readingList} = $readingList;

# Prepare extra header elements
if (!$nosh and !$ARGS{nosh}) {

    $sorter = sorter(\%ARGS,$thisScript,\%SORTER,$relevance) if $showSorter;
    $header_right = nbFound(\%ARGS,$thisScript,$foundRows,$limit,$start,$sorter) if $foundRows > 3;
}



if ($HTML and ($ARGS{__users} or $ARGS{__cats})) {
    $extras = $m->scomp("bits/otherlinks.pl",%ARGS);
}

print $rend->startBiblio($b, 
$renderParams ||
{
    header=>$header,
    header_part2=>$header_part2,
    header_right=>$header_right,
    sorter=>undef,#$sorter,
    form=>mkform('allparams',($thisScript||$PATHS{SEARCH_SCRIPT}),\%ARGS),
    nosh=>$nosh || !$header,
    warning=>$warning,
    found=>$foundRows,
    extras=>$extras,
    listClass=>$listClass
});

if( $HTML and $foundRows < 3 ){
    my $searchStr = $ARGS{searchStr};
    my $searchDisplayed = $searchStr;
    my @words = split( /\W+/, $searchStr );
    my $changed = 0;
    for my $word ( @words ){
        if( ! isLang( $word )) {
            my $alt = getSuggestion( $word );
            next if ! length $alt;
            $searchStr =~ s/$word/$alt/;
            $searchDisplayed =~ s{$word}{<b><i>$alt</i></b>};
            $changed++;
        }
    }
    if( $changed ){
        print "Did you mean: ";
        print '<b><a href="/s/' . urlEncode($searchStr). '">' . $searchDisplayed . '</a></b>';
    }
}

$m->comp("bits/tips.html") if $HTML and !$ARGS{start};
print $rend->renderNav(prevAfter(\%ARGS,$start,$limit,$futureLimit,$foundRows,($thisScript||$PATHS{SEARCH_SCRIPT}))) if $ARGS{start};
print $rend->beginCategory;

my %prev;
my %prev_group;
my $sugM = $ARGS{sugMode};
my $noDupCheck = $ARGS{noDupCheck} || $sugM || $ARGS{crit} eq 'duplicate';
my $c = 0;
event('intermediate','end');
event ('render loop','start');

my @words;
@words = split(/\s+/,$ARGS{searchStr}) if $highlight;
#print "<ul class='entryList'>" unless !$HTML or $autoSplit;

while (my $e = $qu->next()) { 
    $c++;
    #print "$c:". $e->toString . "\n";
    next if !$noDupCheck and $prev{lc $e->toString};
    if ($autoSplit) {

        # for each group level
        for (my $i=0; $i<=$#split; $i++) {

            # prepare header
            my @hv = map { prepf($e,$_,$splitFunc) } @{$split[$i]->{fields}};
            my $sh = $rend->headerId($split[$i],$e); 

            #print "<h2>$sh</h2>" if $SECURE;

            # if this is a new header at that level and not the same as prev level, 
            # close all groups of same level and open new one
            # and ($i == 0 or $prev_group{$i-1} ne $sh)

            if ($prev_group{$i} ne $sh) {

                for ($i .. $#split) {
                    print $rend->afterGroup($_) if $prev_group{$_};
                    $prev_group{$_} = undef;
                }

                # do not open new group if not right kind of entry (e.g. not journal article)
                next unless !$split[$i]->{condition} or $e->{$split[$i]->{condition}->{field}} eq
                                                        $split[$i]->{condition}->{value} or
                                                        $e->{$split[$i]->{condition}->{field}} eq
                                                        $split[$i]->{condition}->{value2};

                print $rend->beforeGroup($i,$sh);
            #print "<p>$sh</p>";
            #use Data::Dumper;
            #print Dumper(\@hv);
                print $rend->renderHeader($sh,$split[$i],\@hv,$i);

                # adapt renderer to this group
                my $rc = $split[$i]->{rendConf};
                for (keys %$rc) {
                    $rend->{$_} = $rc->{$_};
                }
            }

            $prev_group{$i} = $sh;

        }

        #print "$e->{source_type},$e->{pubHarvest}<br>";

    }

    highlight($e,\@words) if $highlight;
#    open D,">>/tmp/encode";
#    binmode(D,":utf8");
#    print D $e->toString . "\n";
#    close D;
    print $rend->renderEntry($e);
    #print "$e->{pub_type} | $e->{date} | $e->{source} | $e->{db_src}";
    print $rend->afterEntry($e);
    $prev{lc $e->toString} = 1;
}



event('render loop','end');

# close open groups
if ($autoSplit) {
for (0..$#split) {
    print $rend->afterGroup($_) if $prev_group{$_};
}
}
#print "</ul>" unless !$HTML or $autoSplit;
print $rend->endCategory;
if ($foundRows <= 0 and !$ARGS{nonothing}) {
    print $rend->nothingMsg if $HTML;
} else {
}
print $rend->endBiblio;
print $rend->renderNav(prevAfter(\%ARGS,$start,$limit,$futureLimit,$foundRows,($thisScript||$PATHS{SEARCH_SCRIPT})));

print $footer unless ($ARGS{noheader} and !$ARGS{pub}) or !$HTML;

event('search.pl','end');

# end of main program


#
# Utility functions
#

sub prepf {
    my ($v,$k,$f) = @_;
    if ($k eq 'period') {
        return $v->{$k};
    } elsif ($k =~ s/^__//) {
        return urlEncode($v->{$k});
    } else {
        return $f ? &$f($v->{$k}) : $v->{$k};
    }

}

sub highlight {
    my ($e, $words) = @_;
    $e->{highlighted} = {};
    my %done;
    my $re = join('|', map { "\Q$_\E" } grep { length($_) > 3 } @$words);
    for my $k (qw/title author_abstract/) {
        my $n = $e->{$k};
#        for (grep {length($_) > 3} @$words) {
#            next if $done{$_};
            $n =~ s/\b($re)\b/<span class='Hi'>$1<\/span>/sig;
#            $done{$_} = 1;
#        }
        $e->{highlighted}->{$k} = "$n";
    }
    my @a = $e->getAuthors;
    my @na;
    for my $a (@a) {
        $a =~ s/(\W)(\Q$_\E)(\W)/$1<span class='Hi'>$2<\/span>$3/sig for grep {length($_) > 3} @$words;
        push @na,$a;
    }
    $e->{highlighted}->{authors} = \@na;
}

sub only_in {
    my $letter = shift;
    my $args = shift;
    return 0 unless $args->{"in_$letter"} eq 'on';
    for my $k (qw/b j w/) {
        next if $k eq $letter;
        return 0 if $args->{"in_$k"} eq 'on';
    }
    return 1;
}



</%perl>
