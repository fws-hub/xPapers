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
use AI::Categorizer::Experiment;
use xPapers::Util qw/parseName2/;
use Storable 'retrieve';
use autodie;
use Lingua::StopWords 'getStopWords';

print "Init learner object\n";

my $c_bayes = AI::Categorizer->new;
my $c_svm = AI::Categorizer->new( learner => AI::Categorizer::Learner::SVM->new() );
#my $c_svm_radial = AI::Categorizer->new( learner => AI::Categorizer::Learner::SVM->new( svm_kernel => 'radial' ) );

my %categories = %{ retrieve( 'categories' ) };
my @training_levels = ( 0.04, 0.16 ); #, 0.32, 0.64 );
my @tfidf_weightings = ( 'xxx', 'npc', 'nxx', 'xpx', 'xxc' );
my $testing_max = 100;
my $total = 80000;

print "Total entries: $total\n";
print "Build knowledge sets\n";

my @training_sets;
for my $level ( @training_levels ){
    for my $tf ( @tfidf_weightings ){
        for my $cw ( undef, { title => 3, source => 2, authors => 3, descriptors => 2, author_abstract => 1, editors => 1, }, ){
            push @training_sets, {
                set => new AI::Categorizer::KnowledgeSet(
                    name => 'Test',
                    stopwords => [ keys %{ getStopWords( 'en' ) } ],
                    tfidf_weighting => $tf,
                ),
                level => $level,
                tf => $tf,
                cw => $cw,
            }
        }
    }
}

open my $entries_fh, '<', 'entries';

my $i = 0;
while( my $line = <$entries_fh> ){ 
    chomp $line;
    my @line = split '\|\|\|\|', $line;
    my $id = shift @line;
    my @categories = split ',', shift @line;
    my %content;
    $content{$_} = shift @line for qw/ title source descriptors author_abstract authors editors /;
    for my $set ( @training_sets ){
        if( $i < ( $total * $set->{level} ) ){
            my @cw = ();
            @cw = ( content_weights => $set->{cw} ) if $set->{cw};
            my %args = ( 
                categories => \@categories, 
                name => $id, 
                content => \%content, 
                @cw,
#                stemming => 'porter',
#                front_bias => 0.5,
            );
            $set->{set}->make_document( %args );
        }
    } 
    last if $i++ >= $total * $training_levels[ $#training_levels ];

    print "$i done.\n" if $i % 100 == 0;
}

my @test_docs;
$i = 0;
while( my $line = <$entries_fh> ){ 
    chomp $line;
    my @line = split '\|\|\|\|', $line;
    my $id = shift @line;
    my @categories = split ',', shift @line;
    my %content;
    $content{$_} = shift @line for qw/ title source descriptors author_abstract authors editors /;
    push @test_docs,  { doc => AI::Categorizer::Document->new( name => $id, content => \%content ), categories => \@categories };
    last if $i++ >= $testing_max;
}
 
for my $set ( @training_sets ){
    print "Training Bayes..\n";
    $c_bayes->learner->train(knowledge_set=>$set->{set} );
    print "Training SVM..\n";
    $c_svm->learner->train( knowledge_set =>$set->{set} );
#    print "Training SVM radial..\n";
#    $c_svm_radial->learner->train( knowledge_set =>$set);

    print "Running tests..\n";
    print 'level: '. $set->{level} . 'tf: ' . $set->{tf} . ' cw: ' . ( $set->{cw} ? 'YES' : 'NO' ) . "\n";
    for my $cizer ($c_bayes,$c_svm, ) {
        my $e = new AI::Categorizer::Experiment(categories => \%categories);
        for my $doc (@test_docs){
            my $r = $cizer->learner->categorize( $doc->{doc} );
            $e->add_hypothesis($r, $doc->{categories} );
        }
        print $e->stats_table; # Show several stats in table form
        print "\n";
    }
    print "\n\n========================\n\n";
}

sub retrieve_doc {
    my $rec = shift;
    my $id = $rec->{id};
    my $entry = xPapers::Entry->new( id => $id )->load;
    die "Wrong article id: $id" if !$entry;
#    print "Real Categories: ", join(', ', @categories), "\n";
    my $content= '';
    $content .= ( join(" ", map { process_name($_) } $entry->getAuthors) . "\n" ) x 4 if defined $entry->authors;
    $content .= ( $entry->title     . "\n" ) x 4;
    $content .= ( $entry->source . "\n" ) x 2 if defined $entry->source;
    $content .= ( join(" ", map { process_name($_) } $entry->getEditors) . "\n" ) x 2 if defined $entry->getEditors;
    $content .= ( $entry->descriptors. "\n" ) x 2 if defined $entry->descriptors;
    $content .= ( $entry->author_abstract. "\n" ) if defined $entry->author_abstract;
    return (
        name => $id,
        categories => $rec->{categories},
        content => $content,
    );
}

sub process_name {
    my $in = shift;
    my ($first,$init,$last) = parseName2($in);
    return "xx${last}yy" . (defined $first ? $first : '');
}

