use xPapers::Diff;
use xPapers::OAI::Repository;
use Data::Dumper;
use Test::More;

{
package TestObject;

use base qw/xPapers::Object xPapers::Object::Diffable/;

__PACKAGE__->meta->setup
(
  table   => 'dummy',
  columns => 
  [
    id                       => { type => 'serial', not_null => 1 },
    name             => { type => 'varchar', length => 255 },
    array_value              => { type => 'array',dimensions=>1 },
    set_value                => { type => 'set' }
  ], 
  primary_key_columns => [ 'id' ],

);

sub diffable { return { array_value => 1, name => 1, set_value=>1 } };

}


my $r = TestObject->new;

my $d1 = xPapers::Diff->new;

$r->name('name1');
$r->array_value([1,2]);
$r->set_value([1,2]);
$d1->before($r);
$r->name('name2');
$r->array_value([2,3]);
$r->set_value([2,3]);
$d1->after($r);
$d1->compute;

is( $d1->{diff}->{name}->{after}, 'name2', 'Scalar 1');
is( $d1->{diff}->{name}->{before}, 'name1', 'Scalar 2');
is( $d1->{diff}->{array_value}->{to_add}->[0], 3, 'Array fields - adding');
is( $d1->{diff}->{array_value}->{to_delete}->[0], 1, 'Array fields - deleting');
is( $d1->{diff}->{set_value}->{to_add}->[0], 3, 'Set fields - adding');
is( $d1->{diff}->{set_value}->{to_delete}->[0], 1, 'Set fields - deleting');
$r->array_value([1,2]);
$d1->apply($r);
is_deeply( [$r->array_value], [2,3], 'Apply');

my $reversed = $d1->reverse;
is_deeply( $reversed->{diff}->{array_value}->{after}, [1,2], 'Reverse');

#my $d2 = xPapers::Diff->new;
#$d2->before($r);
#$r->value([]);
#$d2->after($r);
#$d2->compute;
#
#is( $d2->{diff}->{value}->{to_delete}->[0]->{a}, 1, 'Array fields - removing');

done_testing;
