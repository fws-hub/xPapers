use xPapers::Conf;
use xPapers::Cat;
use xPapers::CatMng;
use xPapers::UserMng;
use Search::Sitemap;
use xPapers::Render::HTML;

my $r = xPapers::Render::HTML->new;
$r->{cur}->{site} = $DEFAULT_SITE;

my $m = Search::Sitemap->new();
my $base = $DEFAULT_SITE->{server};
my %count;

# Home
$m->add({
    loc=>"$base/",
    changefreq=>"daily",
    priority=>1
});


# Secondary pages, daily
$m->add({
    loc=>"$base/$_",
    changefreq=>"daily",
    priority=>0.9
}) for qw/recent/;

# Secondary pages, weekly
$m->add({
    loc=>"$base/$_",
    changefreq=>"weekly",
    priority=>0.9
}) for qw|categories.pl journals/ bbs/ help/ help/about.html|;

# Categories. Priority is an inverse function of depth. 
my $cats = xPapers::CatMng->get_objects_iterator(query=>[canonical=>1,pLevel=>{ge=>1}],sort_by=>['dfo']);
while (my $c = $cats->next) {
    $m->add({
        loc=>"$base/browse/" . ($c->eun),
        changefreq=>"weekly",
        priority=>max(0.2, (9 - $c->pLevel)/10 )
    });
	$count{categories}++;
}

$m->write("$LOCAL_BASE/assets/raw/sitemap.gz");

# Now we make maps that contain users, threads, and entries with good content
my @items;

# Users.
my $users = xPapers::UserMng->get_objects_iterator(query=>[publish=>1,pro=>1],clauses=>["myworks"]);
while (my $u = $users->next) {
    push @items,{
        loc=>"$base/profile/$u->{id}",
        changefreq=>"monthly",
        priority=>(0.3)
    };
	$count{users}++;
}

my $threads = xPapers::ThreadMng->get_objects_iterator();
while (my $t = $threads->next) {
	my $url = $r->threadURL($t);
	$url =~ s/#.+?$//;
    push @items,{
        loc=>$url,
        changefreq=>"weekly",
        priority=>(0.1)
    };
	$count{threads}++;

}

my $entries = xPapers::EntryMng->get_objects_iterator(query=>$DEFAULT_SITE->{defaultFilter},clauses=>["pro and length(author_abstract)>20"]);
while (my $e = $entries->next) {
    push @items,{
        loc=>"$base/rec/$e->{id}",
        changefreq=>"monthly",
        priority=>(0.1)
    };
	$count{entries}++;

}

my $map = Search::Sitemap->new();
my $used = 0;
my $in_this = 0;
for (my $i=0; $i <= $#items; $i++) {
	if ($in_this >= 9990) {
		$map->write("$LOCAL_BASE/assets/raw/xmap-$used.gz");
		$map = Search::Sitemap->new();
		$used++;
		$in_this = 0;
	}
	$in_this++;
	$map->add($items[$i]);
}
$map->write("$LOCAL_BASE/assets/raw/xmap-$used.gz");

for (sort keys %count) {
	print "$_: $count{$_}\n";
}


sub max {
    my ($a, $b) = @_;
    return $a > $b ? $a : $b;
}

1;
