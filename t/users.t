use Test::More;
use Test::Deep;
use xPapers::User;
use xPapers::Follower;

my $user = xPapers::User->get( '3858' );
is( $user->countPapersUnderCat( '21' ), 2, 'countPapersUnderCat' );

#$user->countActivities( '21' );

my $entry = xPapers::Entry->get( 'TURIMA' );
$user->note_for_entry( $entry );


xPapers::FollowerMng->delete_objects( where => [ uId => 10 ], debug => 1 );

$user = xPapers::User->get( 10 );
$user->add_to_followers_of( 'Turing, A.M.' );
$user->add_to_followers_of( 'Turing, A.M.', 'aaa' );  # check if can be called twice

is( xPapers::FollowerMng->get_objects_count( query => [ uId => 10 ] ), 4, 'Test user added to followers' );
$user->remove_from_followers_of( 'Turing, A.M.' );
is( xPapers::FollowerMng->get_objects_count( query => [ uId => 10 ] ), 0, 'Test user removed from followers' );

ok( !$user->follow_all_aliases_of( 5 ), 'follow_all_aliases_of' );

$user->remove_from_followers_of( 'Goedel, Kurt.' );
my @followings = $user->followName( name => 'Kurt Goedel', facebook_id => 1 );

cmp_deeply( $followings[0], 
    methods( original_name => 'Goedel, Kurt', alias => 'Goedel, Kurt', facebook_id => num(1) ),
);

cmp_deeply( $followings[1], 
    methods( original_name => 'Goedel, Kurt', alias => 'Goedel, K.', facebook_id => num(1) ),
);

my @followings = $user->followName( name => 'Kurt Goedel', facebook_id => 2 );

cmp_deeply( $followings[0], 
    methods( original_name => 'Goedel, Kurt', alias => 'Goedel, Kurt', facebook_id => num(1) ),
    'Does not change facebook_id if existing record'
);

$user->unfollowName( 'Goedel, K.' );
is( xPapers::FollowerMng->get_objects_count( query => [ uId => $user->id, alias => 'Goedel, K.' ] ), 0, 'unfollowName' );

done_testing;

