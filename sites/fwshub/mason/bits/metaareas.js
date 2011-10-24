[
<%perl>
if ($ARGS{d}) {
print "DEBUG\n";
print Dumper($root->children_o);
}
#if ($SECURE) {
#print $CACHE{menu};
#print $user->cache->{menu};
#print "cache:" . $root->{__FROM_CACHE__};
#}
    my $cats = $root->children_o;
    print join(",\n", map {"
        {
            text: '" . squote($_->name) . "', 
            url: '/browse/" . $_->eun . "'" .
            submenu($_) . "
        }"
    } @$cats);
</%perl>
    , { text: "Uncategorised Material", url: "/utils/uncategorized.pl" }
] 


<%perl>
sub submenu {
    my $c = shift;
#    if ($user->{id} == 1 and !$c->{catCount}) {
#        print $root->elog("NOT CATCOUNT",$c);
#    }
#    return unless $c->{catCount};
    return "
        , submenu: {
            id: 'aream" . $c->id . "',
            itemdata: [" .
                join(",\n", map { 
                        "{ text: '" .  quote($_->name) .  "', url:'/browse/" . ($_->eun||$_->id) .  "'}" 
                      } 
                      grep { $_->canonical }
                      grep { ref($_) eq 'xPapers::Cat' }
                      @{$c->children_o}
                    )
            . "]
        }
    ";
}
</%perl>
