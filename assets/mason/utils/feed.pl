<%perl>

# Make the feed
my $comp = rmp($ARGS{__action} || $m->request_comp->path);
my ($base,$p) = url2hash($ENV{REQUEST_URI});
trimRSSArgs($p);
$p->{format} = 'rss';
my $u = hash2url($comp,$p);
my $f = xPapers::Feed->create(url=>$u,uId=>$user->{id});
$p->{dg} = $f->k;
$u = hash2url($comp,$p);
$m->comp("../header.html",subtitle=>"RSS Feed");
print gh("RSS Feed");
print "<p>Here is the link to the feed you requested: <a href=\"$u\">RSS</a>";

return;



# old stuff below


my %C = %ARGS;
$C{user} = $user->{id} if $user->{id};
$C{format} = 'rss';
$C{serial} = uniqueKey(); 
#$C{pk} = $user->{id} ? $user->pk : "";
my $cmp = rmp ($ARGS{__action} || $m->request_comp->path);
my $actual_req = mkquery($cmp, \%C);
my $url = rssURL($cmp,\%C,($user->{id} ? $user->pk : ""));
#print $url."<br>";
#print mydigest($cmp,\%C,$user->pk);
#redirect($s,$q,$url);
$m->comp("../header.html",subtitle=>"RSS Feed");
print gh("RSS Feed");
print "<p>Here is the link to the feed you requested: <a href=\"$url\">RSS</a>";

sub rmp {
    my $i = shift;
    $i =~ s/^\Q$s->{server}\E//;
    return $i;
}

sub serial {
    my $ip = $ENV{REMOTE_ADDR};
    $ip =~ tr/0-9./KiUED6HVAQo/;
    return $ip . "v" . (time()-1219279115);
}


</%perl>

