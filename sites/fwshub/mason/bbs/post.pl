<%perl>
my $p = xPapers::Post->get($ARGS{pId});
notfound($q) unless $p;
my $t = $p->thread;
my $f = $t->forum;
error("Access denied. Did you log in?") unless $f->canDo("ViewPosts",$user->{id});
$m->comp("../header.html", subtitle=>$t->firstPost->subject . " (Discussion)");
print gh("From $s->{niceName} forum " . $rend->renderForum($f) . ":");
print "<p>";
$m->comp("expanded.html", post=>$p);
print "<p><b>";
print '<a style="font-size:16px" href="' . $rend->threadURL($t) . '">View thread</a> ';
print '| <a style="font-size:16px" href="' . $rend->forumURL($f) . '">View forum</a></b>';
writeLog($root->dbh,$q, $tracker, "post", $p->{id},$s);
</%perl>

