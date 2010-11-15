use xPapers::EntryMng;
use xPapers::Utils::Profiler;
my $it = xPapers::EntryMng->get_objects_iterator(clauses=>['isnull(cacheId)']);;
my $c = 0;
event('time elapsed','start');
while (my $e = $it->next) {
    $e->cache;
    print "$c done\n" if ++$c % 1000 == 0;
}
event('time elapsed','end');
print summarize_text();
