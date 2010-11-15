use strict;
use warnings;
use Test::More;
use JSON::XS 'decode_json', 'encode_json';

use xPapers::OAI::Repository;
use xPapers::Diff;
use xPapers::OAI::EntryOrigin;
use xPapers::Entry;
use xPapers::Conf;
use xPapers::Utils::Cache;

#warn encode_json( undef );

my $id;
my $repo = xPapers::OAI::Repository->new;
$repo->name( 'Test' );
$repo->save;
$id = $repo->id;
END{ $repo->delete };


my $sets_hash = { 
    aaa => { spec => 'aaa', type => 'bb', name => 'aaaaaaaaa' }, 
    bbb => { spec => 'bbb', type => 'ccc', },
};
{
    my $new_repo = xPapers::OAI::Repository->get( $id );
    $new_repo->set_sets_hash( $sets_hash );
    $new_repo->save;
}
my $new_repo = xPapers::OAI::Repository->get( $id );
is_deeply( $new_repo->sets_hash, $sets_hash, 'sets_hash' );

$new_repo->sets([]);
my $diff = xPapers::Diff->new;
$diff->before($new_repo);
$new_repo->set_sets_hash( $sets_hash );
$diff->after($new_repo);
$diff->compute;

is( $diff->{diff}{sets}{type}, 'array', 'Array diff' ); 

my $new_sets_hash = { aaa => { type => 'bb', name => 'aaaaaaaaa' }, bbb => { type => 'ccc', } };
$new_repo->set_sets_hash( $new_sets_hash );

is_deeply( $new_repo->sets_hash, $sets_hash, 'no specs' );

my $yet_another = {
 aaa => { spec => 'aaa', type => 'bb', name => 'aaaaaaaaa' }, 
 ccc => { spec => 'ccc', type => 'partial', name => 'bad philosophy set' }
};

$new_repo->set_sets_hash($yet_another);

$new_repo->updateSetsFromRemote( { aaa => {}, ddd => { type => 'ddd' }, ccc => { } } );
is_deeply( $new_repo->sets_hash, $yet_another, 'updateSetsFromRemote' );


$new_repo->set_sets_hash( { aaa => { type => 'type to preserve' } } );
$new_repo->downloadType( 'partial' );

my %ftest = (
   'Subject = B Philosophy. Psychology. Religion: BD Speculative Philosophy' => 'complete',
   'Subject = B Philosophy. Psychology. Religion: BP Islam. Bahaism. Theosophy, etc' => 'partial',
   'Subject = Historical and Philosophical studies: Philosophy' => 'complete',
   "Subject = Australian and New Zealand Standard Research Classification: PHILOSOPHY AND RELIGIOUS STUDIES (220000): PHILOSOPHY (220300): Phenomenology" => 'complete',
   "Subject = Australian and New Zealand Standard Research Classification: PHILOSOPHY AND RELIGIOUS STUDIES (220000): RELIGION AND RELIGIOUS TRADITIONS (220400): Comparative Religious Studies (220402)" => 'partial',
   "Subject = Arts, Celtic Studies & Philosophy: French" => 'partial',
   "Subject = B Philosophy. Psychology. Religion: BH Aesthetics" => 'complete',
   "MIUR Scientific Area = Area 11 - History, Philosophy, Pedagogy and Psychology: M-FIL/05 Philosophy and Theory of Language" => 'partial',
   "ANZSRC Field of Research codes = 22 PHILOSOPHY AND RELIGIOUS STUDIES: 2201 Applied Ethics: 220104 Human Rights and Justice Issues" => 'partial',
   "Department Of Religious Studies, Classics and Philosophy" => 'partial',
   "Subject = B Philosophy. Psychology. Religion: B Philosophy (General)" => 'partial',
   "Subject = Historical and Philosophical studies: Philosophy: Moral Philosophy" => 'complete',
   "Administration for Divinity, History & Philosophy research" => 'partial',
   "Philosophy (Department)" => 'complete',
   "philosophy theses" => 'complete'
);
my $input = { 
        aaa => { type => 'this is discarded' }, 
        bbb => { name => 'Doctor of Philosophy' },
        ccc => { name => 'philosophy' }, 
        ddd => { name => 'blalblba'  } 
    };
$input->{$_} = { name => $_ } for keys %ftest;

my $output ={ 
        aaa => { spec => 'aaa', type => 'type to preserve' },
        bbb => { spec => 'bbb', type => 'partial', name => 'Doctor of Philosophy' },
        ccc => { spec => 'ccc', type => 'complete', name => 'philosophy' },
    };
$output->{$_} = { name => $_, spec => $_, type => $ftest{$_} } for keys %ftest;

$new_repo->updateSetsFromRemote( $input );
is_deeply( $new_repo->sets_hash, $output ,'automatic set selection');

is( $new_repo->downloadType, 'sets', 'updateSetsFromRemote switches downloadType to sets' );
$new_repo->updateSetsFromRemote( { } );
is( $new_repo->downloadType, 'partial', 'updateSetsFromRemote switches downloadType to partial' );

{ 
    package xPapers::LCRangeMng;

    sub classes { qw/ BJ BP BS / };
    sub class_behavior {
        my( $self, $class ) = @_;
        my %complete = map {$_ => 1} qw/BJ BH BD/;
        my %partial = map {$_ => 1} qw/BP B/;
        #print "Fake class checker: $class\n";
        return 'complete' if $complete{$class};
        return 'partial' if $partial{$class};
        return undef;
    }
}
$new_repo->updateSetsFromRemote( { 
        aaa => { type => 'ccc', name => 'Subject = B Philosophy. Psychology. Religion: BJ Ethics' }, 
        bbb => { name => 'Subject = B Philosophy. Psychology. Religion: BP Islam. Bahaism. Theosophy' },
        ccc => { spec => 'ccc', type => 'ccc', name => 'Subject = B Philosophy. Psychology. Religion: BS The Bible' },
    } 
);
is_deeply( $new_repo->sets_hash, { 
        aaa => { spec => 'aaa', type => 'complete', name => 'Subject = B Philosophy. Psychology. Religion: BJ Ethics' }, 
        bbb => { spec => 'bbb', type => 'partial', name => 'Subject = B Philosophy. Psychology. Religion: BP Islam. Bahaism. Theosophy' } 
    },
    'updateSetsFromRemote with bib of congress taxonomy'
);


my $e_wrong_subject = xPapers::Entry->new(
    id => 'TEST', 
    source_subjects => 'aaa', 
    serial => undef,
);
$e_wrong_subject->save;
END { $e_wrong_subject->delete if $e_wrong_subject };

my $origin = xPapers::OAI::EntryOrigin->new(
    eId => $e_wrong_subject->id,
    repo_id  => $new_repo->id,
    set_spec => 'aaa',
    set_name => 'Aaa',
    type     => 'complete',
);
$origin->save;
END { $origin->delete if $origin };

my $count = xPapers::OAI::EntryOrigin::Manager->get_objects_count( query => [
        repo_id => $repo->id,
        set_spec => 'aaa',
    ]
); 
is( $count, 1, 'Entry origin' );

$new_repo->downgrade_set( 'aaa', 'partial' );
xPapers::Utils::Cache::clear();
my $e1 = xPapers::Entry->get( 'TEST' );
ok( $e1->deleted, 'Entry with wrong subject deleted when set downgraded' ) or warn $e1;
$new_repo = xPapers::OAI::Repository->get( $new_repo->id );
is( $new_repo->sets_hash->{aaa}{type}, 'partial', 'type downgraded' );

my $e_good_subject = xPapers::Entry->new(
    id => 'TEST2', 
    source_subjects => 'philosophy', 
    serial => undef,
);
$e_good_subject->save;
END { $e_good_subject->delete if $e_good_subject };

$origin = xPapers::OAI::EntryOrigin->new(
    eId => $e_good_subject->id,
    repo_id  => $new_repo->id,
    set_spec => 'bbb',
    set_name => 'Aaa',
    type     => 'partial',
);
$origin->save;
END { $origin->delete if $origin };

$count = xPapers::OAI::EntryOrigin::Manager->get_objects_count( query => [
        repo_id => $repo->id,
        set_spec => 'bbb',
    ]
); 
is( $count, 1, 'Entry origin' );
$new_repo->downgrade_set( 'bbb', 'excluded' );
xPapers::Utils::Cache::clear();
my $e2 = xPapers::Entry->get( 'TEST2' );
ok( $e2->deleted, 'Entry with good subject deleted when partial set downgraded' );
$new_repo = xPapers::OAI::Repository->get( $new_repo->id );
is( $new_repo->sets_hash->{bbb}{type}, 'excluded', 'type downgraded' );

my %big_sets_hash;
for my $i ( 0 .. 2000 ){
    $big_sets_hash{$i} = { type => 'partial', name => $i };
}
$new_repo->set_sets_hash( \%big_sets_hash );
$new_repo->save;

done_testing;

