<%perl>
$m->comp("../header.html", title=>"Pick a forum");
print gh("Pick a forum..");
</%perl>
Please choose the forum where you would like to post your message. If your message is about a book or article in particular, you should post it in the book's or article's associated forum (not shown here). Find the book or article using the search box above, and click the "discuss" link which appears under it. Your message will appear in the forums corresponding to the book's or article's associated categories as well.
<p>
<%perl>
for my $g (@FORUM_GROUPS) {
 next if $g->{name} =~ /^Aggreg/; 
 print "<h3>$g->{name}</h3><p>";
 for my $f (@{$g->{contents}}) {
    next if $ROFORUMS{$f->{id}};
    print "<a href='/bbs/newmsg.pl?fId=$f->{id}'>$f->{name}</a><br>"
 }
}
</%perl>
