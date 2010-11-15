$|=1;
use strict;
use warnings;

use lib '/home/xpapers/lib';
use xPapers::Entry;
use xPapers::DB;
use File::Slurp 'slurp';
use List::Util 'shuffle';
use AI::Categorizer;
use AI::Categorizer::KnowledgeSet;
use AI::Categorizer::Learner::SVM;
use AI::Categorizer::Learner::NaiveBayes;
use AI::Categorizer::Learner::KNN;
use AI::Categorizer::Learner::DecisionTree;
use AI::Categorizer::Learner::Intersection;
use AI::Categorizer::Learner::Purifier;
use AI::Categorizer::FeatureSelector::ChiSquare;
use AI::Categorizer::Experiment::FPStats;

use IO::Handle;
use Data::Dumper;
use AI::Categorizer::Experiment;
use Storable 'retrieve';
use autodie;
use Lingua::StopWords 'getStopWords';

use xPapers::AI::FileCollection;
    

$Data::Dumper::Terse = 1;

my $entries_file = 'entries';

print "Init learner object\n";

my @learners;
#push @learners, { label=>"Purified Bayes $_", learner => AI::Categorizer::Learner::Purifier->new(
#    learner => AI::Categorizer::Learner::NaiveBayes->new(threshold=>$_) 
#) } for qw/0.5/;
push @learners, { label=>"Bayes 0.9", learner => AI::Categorizer::Learner::NaiveBayes->new(threshold=>0.9) };
#push @learners, { label=>"Purified SVM default $_", learner => AI::Categorizer::Learner::Purifier->new(
#    learner => AI::Categorizer::Learner::SVM->new() 
#) };
push @learners, { label=>"SVM default", learner=> AI::Categorizer::Learner::SVM->new() };


#push @learners, { 
#    label=>"Intersection", 
#        learner => AI::Categorizer::Learner::Intersection->new(
#            learner1 => AI::Categorizer::Learner::SVM->new(), 
#            learner2 => AI::Categorizer::Learner::NaiveBayes->new( threshold=> 0.5 ) 
#        ) 
#};

my $do_intersection = 1;
my %categories = %{ retrieve( 'categories' ) };
my @training_levels = (25600 );#( 0.10 ); #, 0.32, 0.64 );
#my @tfidf_weightings = ( 'xxx', 'bxx', 'xfx', 'npc', 'nxx', 'xpx', 'xxc' );
my @tfidf_weightings = ( 'xxx');
my $chi = 6000;
my @cw = ( {title => 1.5, source => 0.5, authors => 0.5, descriptors => 1, author_abstract => 1, editors => 0.5, },);# undef );
my $testing_max = 10000;

print "Build knowledge sets\n";

my $collection = xPapers::AI::FileCollection->new( path => $entries_file, delimiter => "\n", );

my $fs = AI::Categorizer::FeatureSelector::ChiSquare->new(features_kept=>$chi,verbose=>1 );
my $stopwords = getStopWords('en');
$stopwords->{$_} = 1 for 'a' .. 'z';
my $features = $fs->scan_features( collection => $collection, stopwords => $stopwords, );

        my $h = $features->as_hash;
        my @sorted = sort {$h->{$b}<=>$h->{$a}} keys %$h;
        open F, ">/tmp/features7";
        print F "$_ -> $h->{$_}\n" for @sorted;
        close F;

my @training_sets;
for my $level ( @training_levels ){
    for my $tf ( @tfidf_weightings ){
            for my $cw ( @cw ){
                my $ks = new AI::Categorizer::KnowledgeSet(
                    name => 'Test',
                    tfidf_weighting => $tf,
                    #                        collection => xPapers::AI::FileCollection->new( path => 't/data/entries', delimiter => "\n", ),
                );
                $ks->features( $features );
                push @training_sets, {
                    set => $ks,
                    level => $level,
                    cw => $cw,
                    tf => $tf,
                    chi=> $chi
                }
            }
    }
}

open my $entries_fh, '<', $entries_file;

my $i = 0;
while( my $line = <$entries_fh> ){ 
    my ( $id, $content, $categories ) = xPapers::AI::FileCollection::parse_line( $line );
    for my $set ( @training_sets ){
        if( $i < $set->{level} ){
            my @cw = ();
            @cw = ( content_weights => $set->{cw} ) if $set->{cw};
            my %args = ( 
                categories => $categories, 
                name => $id, 
                content => $content, 
                @cw,
                use_features => $features,
#                stemming => 'porter',
#                front_bias => 0.5,
            );
            $set->{set}->make_document( %args );
        }
    } 
    last if $i++ >= $training_levels[ $#training_levels ];

    print "$i done.\n" if $i % 100 == 0;
}


my @test_docs;
$i = 0;
while( my $line = <$entries_fh> ){ 
    my ( $id, $content, $categories ) = xPapers::AI::FileCollection::parse_line( $line );
    push @test_docs,  { doc => AI::Categorizer::Document->new( name => $id, content => $content ), categories => $categories, content => $content, id => $id };
    last if $i++ >= $testing_max;
}

my $io = IO::Handle->new;
$io->fdopen(fileno(STDERR),"w") or die 'Cannot write to STDERR';
$io->autoflush( 1 );

my @results;
for my $conf ( @learners ) {

    print $io "*" x 50 . "\n";
    print $io $conf->{label} . "\n";
    my $learner = $conf->{learner};

    for my $set ( @training_sets ){
        my $time = time;
        eval {
            $learner->train( knowledge_set =>$set->{set} );
        };
        if ($@) {
            print $io "Error in training: $@\n";
            print $io "I'm skipping this set-learner pair.\n";
            next;
        }
        my $training_time = time - $time;
        print $io 'trained in: ' . $training_time . "\n";
        my $e = AI::Categorizer::Experiment::FPStats->new(categories=>\%categories);
        my $with_at_least_one_cat;
        my $no_cats;
        for my $doc (@test_docs){
            my $r = $learner->categorize( $doc->{doc} );
            $e->add_hypothesis($r, $doc->{categories} );
            $with_at_least_one_cat++ if $r->categories;
            $no_cats++ if ! $r->categories;
        }
        my $result = { learner=>$conf->{label}, f1=>$e->micro_F1, experiment =>$e, set=>$set, training_time => $training_time };
        push @results, $result;
        print_result( $io, $result );
        print $io "with_at_least_one_cat: $with_at_least_one_cat, no_cats: $no_cats\n";
        print $io $e->stats_table;

        open my $fh, '>', 'top_ten' or die "Cannot write to top_ten: $!";
        top_ten( $fh, \@results );
        close $fh or die "Cannot close top_ten: $!";
    }
}


if ($do_intersection) {
    for (my $first=0; $first <= $#learners; $first++) {
        for (my $second=$first+1; $second <= $#learners; $second++) {
             next if ref($learners[$first]->{learner}) eq ref($learners[$second]->{learner});
             my $name = "Intersection of $learners[$first]->{label} and $learners[$second]->{label}";
             print $io "*" x 50 . "\n";
             print $io $name . "\n";
             my $learner = AI::Categorizer::Learner::Intersection->new(
                learner1=>$learners[$first]->{learner},
                learner2=>$learners[$second]->{learner}
             );
             for my $set ( @training_sets ){

                 my $errors = {};

                 my $e = AI::Categorizer::Experiment::FPStats->new(categories=>\%categories);
        my $with_at_least_one_cat;
        my $no_cats;
                 for my $doc (@test_docs){
                     my $r = $learner->categorize( $doc->{doc} );
                     $e->add_hypothesis($r, $doc->{categories} );
                     record_errors( $errors, $r, $doc->{categories}, $doc );
            $with_at_least_one_cat++ if $r->categories;
            $no_cats++ if ! $r->categories;
                 }
                 my $result = { learner=>$name, f1=>$e->micro_F1, experiment =>$e, set=>$set };
                 push @results, $result;
                 print_result( $io, $result );
        print $io "with_at_least_one_cat: $with_at_least_one_cat, no_cats: $no_cats\n";
                 print $io $e->stats_table;

                 open my $fh, '>', 'top_ten' or die "Cannot write to top_ten: $!";
                 top_ten( $fh, \@results );
                 close $fh or die "Cannot close top_ten: $!";
                 print_errors( $errors );
            }
        }
    }
}

open my $fh, '>>', 'top_ten.csv' or die "Cannot write to top_ten: $!";
top_ten( $fh, \@results );
close $fh or die "Cannot close top_ten: $!";

sub print_errors {
    my $errors = shift;
    my $errors_file = "errors/$ARGV[0]"; 
    open my $fh, '>', $errors_file or die "Cannot write to $errors_file : $!";
    for my $cat ( keys %{$errors->{fpos}} ){
        print $fh "=== false positives: $cat (" . scalar @{ $errors->{fpos}{$cat} } . ")\n";
        for my $doc( @{ $errors->{fpos}{$cat} } ){
            $doc->{content}{id} = $doc->{id};
            print $fh Dumper( $doc->{content} );
        }
    }
    for my $cat ( keys %{$errors->{fneg}} ){
        print $fh "=== false negatives: $cat (" . scalar @{ $errors->{fneg}{$cat} } . ")\n";
        for my $doc( @{ $errors->{fneg}{$cat} } ){
            $doc->{content}{id} = $doc->{id};
            print $fh Dumper( $doc->{content} );
        }
    }
}

sub record_errors {
    my( $errors, $h, $categories, $doc ) = @_;
    my %assigned = map { $_ => 1 } $h->categories;
    for my $cat ( @$categories ){
        $errors->{fneg}{$cat} = [] if !$errors->{fneg}{$cat};
        push @{$errors->{fneg}{$cat}}, $doc if !$assigned{$cat};
    }
    my %correct = map { $_ => 1 } @$categories;
    for my $cat ( $h->categories ){
        $errors->{fpos}{$cat} = [] if !$errors->{fpos}{$cat};
        push @{$errors->{fpos}{$cat}}, $doc if !$correct{$cat};
    }
}

sub top_ten {
    my( $fh, $results ) = @_;

    my @sorted = sort { $b->{f1} <=> $a->{f1} } @$results;
    for my $r (@sorted[0..9]) {
       last if ! defined $r;
       print_result($fh, $r);
    }
}

sub print_result {
    my ( $fh, $r, ) = @_;
    my $set = $r->{set};
    my $line = 'globals: ' . $ARGV[0]
    . ' learner: ' . $r->{learner} 
    . ' level: ' . $set->{level} 
    . ' tf: ' . $set->{tf} 
    . ' cw: ' . ( $set->{cw} ? 'YES' : 'NO' ) 
    . ' chi: ' . (defined $set->{chi} ? $set->{chi} : ' NO')
    . ' training_time: ' . $r->{training_time}
    . ' time_stamp: ' . scalar localtime(time)
    ;
    for my $m ( qw/micro macro/ ){
        for my $stat ( qw/accuracy error precision recall F1/ ){
            my $meth = $m . '_' . $stat;
            $line .= "\t" . sprintf('%.4f', $r->{experiment}->$meth);
        }
    }
    $line .= "\n";
    print $fh $line;
}


