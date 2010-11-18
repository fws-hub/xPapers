use xPapers::Entry;
use xPapers::Util;
use xPapers::Conf;
binmode(STDOUT,":utf8");

my $it = xPapers::EntryMng->get_objects_iterator(query=>[
    'source' => { like => 'Ntm %' },
    pub_type=>'journal'
]);
while (my $e = $it->next) {
    print "Before: " . $e->source . "\n";
    $e->source(cleanJournal($e->source));
    print "After: " . $e->source . "\n";
    $e->save;
}
