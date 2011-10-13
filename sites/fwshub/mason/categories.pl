<%perl>

    print $m->comp("header.html",subtitle=>"$s->{niceName} Categories",description=>"Entry point to $s->{niceName}' category system");
    print gh("Browse by category");
print "$s->{niceName} is developing Categories within Food and Water Security, ranging from broad areas to narrow subtopics. Choose the area where you would like to start browsing below, or <a href='/browse/all'>view all categories</a>.<p> ";

    print "<div class='toc-1'><div class='toc'>";
    $m->comp("browse/struct_c2.pl",__cat__=>$root,depth=>0,level=>1,dlevelOffset=>3);
    #print "<ul>";
    #print "<li><a href='/browse/$_->{id}'>$_->{name}</a> <span class='subtle'>(" . format_number($_->preCountWhere($s)) . " items)</span></li>" for @{ $root->children_o };
    #print "</ul>";
    print "</div></div>";
</%perl>

