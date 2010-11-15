use xPapers::User;
use xPapers::Entry;
use xPapers::Cat;
use xPapers::Utils::Profiler;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

initProfiling();

event('load user with cache','start');
for (1..1000) {
    my $u = xPapers::User->get(1);
    $u->cache;
}
event('load user with cache','end');
print summarize_text;

initProfiling();

event('load entry with cache','start');
for (1..1000) {
    my $u = xPapers::Entry->get('BOUCIU');
    $u->cache;
}
event('load entry with cache','end');
print summarize_text;

initProfiling();

event('load cat with cache','start');
for (1..1000) {
    my $u = xPapers::Cat->get(1);
    $u->cache;
}
event('load cat with cache','end');

print summarize_text;
