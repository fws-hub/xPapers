=usage

use this script to (re-)apply the cleanAll procedure from xPapers::Util to entries. 

do "perl cleanup.pl F T" to apply cleanAll to all non-deleted entries which have text T in field F. 
do "perl cleanup.pl" to apply cleanAll to all non-deleted entries.

=cut
use xPapers::Entry;
use xPapers::Util;
use xPapers::Conf;

my @clauses;
if (defined $ARGV[0] and defined $ARGV[1]) {
    if ($ARGV[0] eq 'where') {
        push @clauses, $ARGV[1];
    } else {
        push @clauses, "`$ARGV[0]` like '%" . quote($ARGV[1]) . "%'";
    }
}
push @clauses, "not deleted";
my $it = xPapers::EntryMng->get_objects_iterator(clauses=>\@clauses);
while (my $e = $it->next) {
    print "Cleaning ". $e->toString ."\n";
    #print $e->pub_type . "\n";
    #print "before:$e->{source}\n";
    cleanAll($e);

    #my @au = map { fix($_)  } $e->getAuthors;
    #$e->deleteAuthors;
    #$e->addAuthors(@au);

    print "Cleaned " . $e->toString . "\n";
    #print "after:$e->{source}\n";
    $e->save;

}

sub fix {
    my $in = shift;
    $in =~ s/Kirk, Robert E./Kirk, Robert/;
    return $in;
}

