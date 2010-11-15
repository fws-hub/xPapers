<%perl>
my $f = $ARGS{__forum__};
return if $m->cache_self(key=>"bbs-brief2-$f->{id}",expires_in=>"1 hour");
event('bbs brief','start');

my @threads = $f->threads_o("true","ct desc",0,5);
unless ($#threads> -1) {
    print "No threads found (<a href='" . $rend->forumURL($f) . "'>Go to forum</a>)<p>";
    return;
}
print "<ul class='normal'>";
for my $p (map { $_->firstPost } @threads) {
</%perl>

    <li><a href="<%$rend->postURL($p)%>"><%$p->subject%></a>, <span class='subtle'>posted <%$rend->renderDate($p->created) %></span> by <%$rend->renderUserC($p->user,1)%></li>
    
%}
<li><a href="<%$rend->forumURL($f)%>"><b>Go to forum</b></a></li>
</ul>
%event('bbs brief','end');
