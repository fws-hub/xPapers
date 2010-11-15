<%perl>
use Data::Dumper;

# check if user is signed in
if (!$user->{id}) {
        print "<div style='padding:10px'>";
        print "You have to <a href='/inoff.html'>sign in first</a>.";
        print "</div>";
        return;
}

# process entries:
my $author;
if ($q->param('author_id') eq '0') {
    # new entry
    $author = xPapers::Pages::PageAuthor->new;
    $author->created('now');
    # We save an empty author; then we can treat the action as an
    # update rather than an addition, so that it shows up as an
    # un-accepted diff in the admin menu. (We need to save anyway
    # because new pages need a foreign key to the author id.)
    $author->save;
}
elsif ($q->param('author_id')) {
    # altered entry:
    $author = xPapers::Pages::PageAuthor->new(id => $q->param('author_id'))->load(with => ['areas', 'pages']);
}
if ($author) {
    my $diff = xPapers::Diff->new;
    $diff->uId($user->{id} || 0);
    $diff->before($author);
    $author->loadUserFields(\%ARGS);
    $author->{accepted} = 1;
    my @areas;
    for my $i (1..4) {
        if ($q->param("area$i") =~ /cat(\d+)/) {
            push @areas, xPapers::Cat->new(id=>$1)->load;
        }
    }
    $author->areas(@areas);
    $diff->after($author);
    unless ($diff->is_null) {
        # We could $diff->accept if $SECURE, but we'd have to make
        # sure to communicate updates to the opp server, which we
        # also have to do anyway on the admin interface; so we do
        # it only there.
        $diff->save;
    }
    # pages:
    my %new_pages; # hash id => 1
    for my $i (0..19) { # max 20
        next unless $q->param("url$i") && length($q->param("url$i")) > 5;
        my $page;
	if ($q->param("page_id$i")) {
	    # existing page
	    $page = xPapers::Pages::Page->new(id => $q->param("page_id$i"))->load;
            $new_pages{$page->{id}} = 1;
        }
        else {
	    # new page: as with authors, we save an empty object.
	    $page = xPapers::Pages::Page->new;
            $page->{author_id} = $author->{id};
            $page->{url} = "";
            $page->save;
        }
	my $pdiff = xPapers::Diff->new;
	$pdiff->uId($user->{id} || 0);
        $pdiff->before($page);
        my $u = $q->param("url$i");
        $u = "http://$u" unless $u =~ /^https?:\/\//;
        $page->{url} = $u;
        $page->{author_id} = $author->{id};
        $page->{accepted} = 1;
        $pdiff->after($page);
        next if $pdiff->is_null;
        $pdiff->save;
    }
    # deletions:
    for my $page (@{$author->pages}) {
        next if $new_pages{$page->{id}};
        next unless ($page->{accepted} && !$page->{deleted});
	my $pdiff = xPapers::Diff->new;
	$pdiff->uId($user->{id} || 0);
        $pdiff->before($page);
        $page->{deleted} = 1;
        $pdiff->after($page);
        $pdiff->save;
        # $pdiff->delete_object($page);
    }
    if (0) {
    for my $i (1..20) { # max
        last unless $q->param("url$i") && length($q->param("url$i")) > 1;
        my $page;
	if ($q->param("page_id$i")) {
	    # existing page
	    $page = xPapers::Pages::Page->new(id => $q->param("page_id$i"))->load;
        }
        else {
	    # new page: as with authors, we save an empty object.
	    $page = xPapers::Pages::Page->new;
            $page->{author_id} = $author->{id};
            $page->{url} = "";
            $page->save;
        }
	my $pdiff = xPapers::Diff->new;
	$pdiff->uId($user->{id} || 0);
        if ($q->param("url$i") eq 'DEL') {
            $pdiff->delete_object($page);
        }
        else {
            $pdiff->before($page);
            $page->{url} = $q->param("url$i");
            $page->{title} = $q->param("title$i");
            $page->{author_id} = $author->{id};
            $page->{accepted} = 1;
            $pdiff->after($page);
            next if $pdiff->is_null;
        }
        $pdiff->save;
    }
}
    print "Thanks! Your changes will be reviewed shortly.";
    return;
}

# present the editor:
if ($q->param('id')) {
    $author = xPapers::Pages::PageAuthor->new(id => $q->param('id'))->load();
}
else {
    $author = xPapers::Pages::PageAuthor->new;
    if ($q->param('user') && ($q->param('user') eq $user->{id})) {
        $author->{user_id} = $q->param('user');
    }
}
$m->comp('pageseditor.html', author => $author, %ARGS);

</%perl>
