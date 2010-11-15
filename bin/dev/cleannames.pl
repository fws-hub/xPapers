use xPapers::Entry;
use xPapers::Util;

my $it = xPapers::EntryMng->get_objects_iterator(query=>[
    '!authors' => { like => '%,%' } ,
]);
while (my $e = $it->next) {
    #next if $e->source_id =~ /^crossref/;
    my $bef = $e->toString; 
    cleanNames($e);
    next if $bef eq $e->toString;
    print "Before: $bef\n";
    print "After: " . $e->toString . "\n";
    $e->save;
}
