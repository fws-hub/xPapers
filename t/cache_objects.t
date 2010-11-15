use Test::More;
use xPapers::Object::CacheObject;
use xPapers::Cat;
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

my $test = xPapers::Object::CacheObject->new(oId=>'testing',class=>'testing_class');
$test->save;

my $id = $test->id;

my $recovered = xPapers::Object::CacheObject->get($id);

$recovered->{values}->{bla} = 'ok';

$recovered->save;

my $again = xPapers::Object::CacheObject->get($id);

is( $again->{values}->{bla}, 'ok', 'basic save/restore' );

my $root = xPapers::Cat->get(1);
$root->forget_cache;

is( $root->cacheId, undef, 'forget' );

is( $root->cache, $root->cache, 'repeated gets' );

$root->cache->{dummy} = 2;
$root->save_cache;

is( $root->cache->{dummy}, 2, 'category cache - same instance' );

my $cache = xPapers::Object::CacheObject->get($root->cacheId);
is( $cache->{values}->{dummy}, 2, 'cache object retrieved' );

my $other = xPapers::Cat->get(1);
#ok( defined $other->{__cache_obj}, 'cache object is remembered' );
is( $other->cache->{dummy}, 2, 'category cache - different instance' );

done_testing;
