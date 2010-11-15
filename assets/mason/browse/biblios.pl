<div class='ah'>Contributed bibliographies:</div>
<%perl>
event('biblio','start');
    my $cat = $ARGS{__cat__};
    my @bibs =   sort { $a->name cmp $b->name }    
                 map { @{$_->related ? $_->unofficial->children_o : []} }
                 $cat, @{$cat->children_o};
    if ($#bibs > -1) {
        print "<ul class='normal'>";
       for my $l (@bibs) {
            next unless $l->publish;
            print "<li><a href='/browse/" . $l->id . "'><b>" . $l->name . "</b></a>, compiled by " . 
            $rend->renderUserC($l->user) . "</li>\n";
       }
       print "</ul>";

    } else {
        print "<em>There are currently no bibliographies in this area.</em><p>";
    }
    print "<p>";
event('biblio','end');
</%perl>

