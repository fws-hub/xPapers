use xPapers::EntryMng;
use xPapers::Util;
use xPapers::Conf;

my $it = xPapers::EntryMng->get_objects_iterator(query=>['source'=>{like=>'[Journal (Paginated)]'}]);

my $count = 0;
while (my $e = $it->next) {
    cleanAll($e,$PATHS{INTEL_FILES});
    $count++;
    $e->save;
}
print "$count modified.\n";


