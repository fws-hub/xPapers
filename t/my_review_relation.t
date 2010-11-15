use strict;
use warnings;
use Test::More;
use xPapers::Relations::ReviewOf;
use xPapers::Entry;

my $rr = xPapers::Relations::ReviewOf->new;
isa_ok( $rr, 'xPapers::Relations::ReviewOf', 'xPapers::Relations::ReviewOf object created' );


my $it = xPapers::EntryMng->get_objects_iterator();

my $entry1 = $it->next;
my $entry2 = $it->next;

$entry1->review_of( [ $entry2 ] );
$entry1->save;

$rr = xPapers::Relations::ReviewOf::Manager->get_objects_iterator( query => [ reviewed_id => $entry2->id, reviewer_id => $entry1->id ] )->next;

ok( $rr, 'Relation created' );

done_testing;

