<& ../header.html, subtitle=>"Cross ref selector" &>
<% gh("Cross ref selector") %>
<%perl>
use xPapers::Link::HarvestJournal;
use URI::Escape;

my @columns = qw/issn name publisher subjects lastSuccess fetched newEntries oldEntries suggestion/;
my $page = $ARGS{p} || 0;
$ARGS{to_harvest} ||= 'h';

if( $r->method eq 'GET' ){
    </%perl>


    <form method="GET">
    Keyword(s): <input type="text" name="query" value="<%$ARGS{query}%>">&nbsp;&nbsp;&nbsp; 
    <span style="background:#eef">
    <input type="radio" name="to_harvest" value="a" <%$ARGS{to_harvest} eq 'a' ? 'checked' : ''%>> all&nbsp;&nbsp;&nbsp;
    <input type="radio" name="to_harvest" value="h" <%$ARGS{to_harvest} eq 'h' ? 'checked' : ''%>> harvested&nbsp;&nbsp;&nbsp;
    <input type="radio" name="to_harvest" value="n" <%$ARGS{to_harvest} eq 'n' ? 'checked' : ''%>> not harvested&nbsp;&nbsp;&nbsp;
    </span>
    <input type="checkbox" name="suggestion" value="1" <%$ARGS{suggestion} ? 'checked' : ''%>> only suggested
    <input type="submit" value="Go">
    </form>
    <%perl>
    if( $page > 0 ){
        my %currargs;
        $currargs{p} = $page - 1;
        $currargs{query} = $ARGS{query};
        $currargs{to_harvest} = $ARGS{to_harvest};
        $currargs{sort_by} = $ARGS{sort_by} if $ARGS{sort_by};
        $currargs{suggestion} = 1 if $ARGS{suggestion};
        my $uri = URI->new();
        $uri->query_form( \%currargs );
        print qq{&nbsp;&nbsp;&nbsp;<a href="$uri">Previous Page</a>};
    }
    print '<form method="POST">';
    print '<table><tr>';
    print "<th></th>";
    print "<th>issn</th>";
    print "<th><a href='?sort_by=name;query=$ARGS{query};to_harvest=$ARGS{to_harvest}'>name</a></th>";
    print "<th>publisher</th>";
    print "<th>subjects</th>";
    print "<th>last success</th>";
    print "<th>fetched</th>";
    print "<th>new</th>";
    print "<th>old</th>";
    print "<th>suggested?</th>";
    print "<th>entries</th>";
    print '</tr>';

    my $q2 = quote($ARGS{query});
    $q2 =~ s/\b(\w+)/\+$1/g;
   
    my @query = ( 
        inCrossRef => '1',
        '!deleted' => 1,
    );
    push @query, [ \'MATCH(name, subjects) AGAINST (?)' => $ARGS{query} ] if $ARGS{query}; 
    push @query, suggestion => 1 if $ARGS{suggestion};

    if( $ARGS{to_harvest} eq 'n' ){
        push @query, or => [ toHarvest => undef, toHarvest => 0 ];
    }
    elsif( $ARGS{to_harvest} eq 'h' ){
        push @query, or => [ toHarvest => 1 ];
    }
    my %args = ( 
        limit => 501, 
        offset => 500 * $page,
        query => \@query,
    );
    $args{sort_by} = 'name' unless $ARGS{query};
    $args{clauses} = [ "match(name, subjects) against ('$q2' in boolean mode)" ] if $ARGS{query};
    $args{sort_by} = $ARGS{sort_by} if $ARGS{sort_by};

    my $it = xPapers::Link::HarvestJournalMng->get_objects_iterator( %args );

    my $i = 0;
    while( my $journal = $it->next ){
        if( $i++ < 500 ){
            my $id = $journal->id;
            my $background = $journal->toHarvest ? "#eef" : 'white';
            my $checked = $journal->toHarvest ? " checked" : "";
            my $java = qq{onclick="if (event.target.tagName != 'INPUT') document.getElementById('checked_$id').checked = !document.getElementById('checked_$id').checked"};
            my $java_back = qq{onMouseOver="this.style.background='#efe'" onMouseOut="this.style.background='$background'"};
           
            print qq{<tr style="background:$background" $java_back>};
            print qq{<td $java><input type="hidden" name="id_$id"><input type="checkbox" name="checked_$id" id="checked_$id" $checked></td>};
            print "<td $java>" . ($_ eq 'name' ? "<a onclick='return false' href=\"http://www.google.com/search?q=$journal->{name}%20$journal->{publisher}\">$journal->{name}</a>" : $journal->$_) . '</td>' for @columns;
            if( $journal->oai_set ){
                print '<td><a href="crossref_papers.html?set_spec=' . uri_escape($journal->oai_set) . '">entries</a></td>';
            }
            else{
                print '<td>not found</td>';
            }
            print '</tr>';
        }
    }
    print '</table>';
    print "$i journals displayed.<p>";
    print '<input type="submit" value="Save">';
    print '</form>';
    print '<hr>';

    if( $i > 500 ){
        my %currargs;
        $currargs{p} = $page + 1;
        $currargs{query} = $ARGS{query};
        $currargs{to_harvest} = $ARGS{to_harvest};
        $currargs{sort_by} = $ARGS{sort_by} if $ARGS{sort_by};
        $currargs{suggestion} = 1 if $ARGS{suggestion};
        my $uri = URI->new();
        $uri->query_form( \%currargs );
        print qq{<a href="$uri">Next Page</a>};
    }
    $it->finish;
}
else{
    for my $arg ( keys %ARGS ){
        if( $arg =~ /id_(\d+)/ ){
            my $id = $1;
            my $journal = xPapers::Link::HarvestJournal->get( $id );
            if(exists $ARGS{ 'checked_' . $id } ){
                $journal->toHarvest(1);
            }
            else{
                $journal->toHarvest(0);
            }
            $journal->save;
        }
    }
    print redirect( $s, $q, url( 'crossref.pl', { p => $page, query => $ARGS{query} } ) );
}


</%perl>


