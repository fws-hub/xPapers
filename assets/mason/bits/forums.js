[
{ text: "View all threads", url: "/bbs/allforums.pl"},
{ text: "Overview / list of all forums", url: "/bbs/forums.pl"},
{ text: "The <% $s->{niceName} %> Blog", url: "/blog"},
{ text: "<em style='color:#666'>Aggregated forums:</em>", disabled:true },

<%perl>
print submenu2({contents=>$AGGFORUMS});
</%perl>

]
<%perl>
sub submenu2 {
    my $g = shift;
    return join(",", 
        map { "{ text: \"$_->{name}\", url:\"" . $rend->forumURL($_) . "\" }" }
        @{$g->{contents}}
    );
}
</%perl>
