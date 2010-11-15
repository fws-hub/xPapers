<%perl>
$m->comp("../checkLogin.html",%ARGS);
#print STDOUT $q->header;
my %C = %ARGS;
$C{user} = $user->{id} if $user->{id};
$C{format} = 'alert';
my $cmp = $ARGS{__action} || $m->request_comp->path;
my $url = rssURL($cmp,\%C,($user->{id} ? $user->pk : ""));
#print $url."<br>";
#print mydigest($cmp,\%C,$user->pk);

my $a = xPapers::Alert->new;
$a->url($url);
$a->uId($user->id);
$a->lastChecked(DateTime->now);
$a->save;


</%perl>

