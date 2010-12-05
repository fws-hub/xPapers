package xPapers::AI::Categorizer;
use Moose;
use MooseX::AttributeHelpers;
use autodie qw(:all);
use List::Util 'shuffle';
use Storable qw/ freeze thaw store retrieve/;
use Lingua::StopWords 'getStopWords';
use AI::Categorizer::KnowledgeSet;
use Data::Dumper;
use File::Path 'mkpath';
use File::Find::Rule;
use AI::Categorizer::Learner::NaiveBayes;
use AI::Categorizer::Learner::SVM;
use Algorithm::NaiveBayes::Model::Frequency;

use xPapers::Conf '$AUTOCAT_USER';
use xPapers::Entry;
use xPapers::Cat;
use xPapers::DB;
use xPapers::Util qw/parseName2 rmDiacritics/;
use xPapers::AI::FileCollection;
use AI::Categorizer::FeatureSelector::ChiSquare;
use AI::Categorizer::Experiment::FPStats;
use AI::Categorizer::Learner::Intersection;

binmode STDOUT,":utf8";
$Data::Dumper::Terse = 1;

my $var = 'var';

has comment  => ( is => 'ro', isa => 'Str' );
has cat_root => ( is => 'ro', isa => 'Str' );
has cat_level=> ( is => 'ro', isa => 'Int' );
has data_root => ( is => 'ro', isa => 'Str', default => 'var' );
has data_dir => ( is => 'ro', lazy_build => 1 );
sub _build_data_dir {
    my $self = shift;
    return $self->data_root . '/' . $self->cat_root . '-' . $self->cat_level;
}

has train_with => ( is => 'ro', isa => 'Num' );
has max_tests => ( is => 'ro', isa => 'Num' );
has db_limit => ( is => 'ro', isa => 'Int' );

has do_intersection => ( is => 'ro', isa => 'Bool', default => 1 );

has cw => ( 
    is => 'ro',
    isa => 'HashRef',
    default => sub { { title => 1.5, source => 0.5, authors => 0.5, descriptors => 1, author_abstract => 1, editors => 0.5 } },
);

has tf => ( is => 'ro', isa => 'Str', default => 'xxx' );

has features_kept => ( is => 'ro', isa => 'Int', default => 6000 );

has 'learners' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[ HashRef ]',
    default   => sub { [] },
    provides  => {
        'push'      => 'add_learner',
    }
);

has categories => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
sub _build_categories {
    my $self = shift;
    return retrieve( $self->data_dir . '/categories' );
}

sub categorize {
    my( $class, %params ) = @_;
    my $entry = delete $params{entry};
    my @cats =  $class->suggest( entry=>$entry, %params );
    for my $cat ( @cats ) {
        $cat->addEntry( $entry, $AUTOCAT_USER, deincest=>1 );
    }
    return @cats;
}

sub suggest { 
    my( $self, %params ) = @_;
    my $entry = delete $params{entry};
    my $c;

    # make/retrieve new categorizer if specified params
    if (keys %params) {
        $c = $self->make_or_retrieve( %params );
    } else {
        $c = $self; 
    }

    $c->{__learner} ||= AI::Categorizer::Learner::Intersection->new(
        learner1 => $c->learners->[0]->{learner},
        learner2 => $c->learners->[1]->{learner},
    );
    $c->{__features} ||= retrieve( $c->data_dir . '/features' );
    my $doc = $self->entry2doc( $entry, $c->{__features} );
    my $r = $c->{__learner}->categorize( $doc );

    #use Data::Dumper;
    #print Dumper($r->categories);
    my @cats = str2cats($r->categories);

    unless ($params{noExistingCheck}) {
         @cats = grep { !$_->containsUnder($entry) } @cats;
    }
    unless ($params{noExclusions}) {
        @cats = grep { !$_->isExcluded($entry) } @cats;
    }

    return @cats;

}

sub str2cats {
    my @ids;
    for (@_) {
        push @ids, $1 if m/^(\d+)\s-\s/;
    }
    return  map { xPapers::Cat->get($_) } @ids;
}

sub entry2doc {
    my( $class, $entry, $features ) = @_;
    my %content;
    $content{authors} = join ' ', map( &xPapers::AI::FileCollection::process_names, grep {defined($_)} $entry->getAuthors );
    $content{editors} = join ' ', map( &xPapers::AI::FileCollection::process_names, grep {defined($_)} $entry->getEditors );
    $content{$_} = transform($entry->$_) for qw/title descriptors author_abstract/;
    $content{source} = $entry->source;
    $content{source} =~ s/\s/xx/g;
    $content{source} = "xx$content{source}xx" if $content{source};
    return AI::Categorizer::Document->new( name => $entry->id, content => \%content, use_features => $features );
}

sub transform {

    my $in = shift;
    return undef unless defined $in;
    # argument of dretske -> arguementxxofxxdretske dretske
    $in =~ s/([\w\'\-]+)\s+of\s([\w\'\-]+)/$1xxofxx$2 $2/g;
    # externalism about content -> externalismxxaboutxxcontent content
    $in =~ s/([\w\'\-]+)\s+about\s([\w\'\-]+)/$1xxaboutxx$2 $2/g;
    return $in;

}

sub make {
    my ( $class, %params ) = @_; 
    return $class->make_or_retrieve( %params, forceTrain=>1 );
}

sub make_or_retrieve {
    my( $class, %params ) = @_;
    my $c = $class->new( %params );
    if( ! -d $c->data_dir ){
        mkpath $c->data_dir;
    }
    if( ! -f $c->data_dir . '/training' ){
        $c->generate_sets;
    }
    my @saves = File::Find::Rule->directory()
        ->name( '*_saved' )
        ->in( $c->data_dir );
    if( @saves and !$params{forceTrain} ){
        for my $save ( @saves ){
            open my $fh, '<', "$save/self";
            my $class = <$fh>;
            $class =~ /(AI::Categorizer::Learner(::\w+)*)/;
            $class = $1;
            eval "require $class";
            close $fh;
            my $learner = $class->restore_state( $save );
            my $label = $save;
            $label =~ s/_save$//;
            $c->add_learner( { label => $label, learner => $learner } );
        }
    }
    else{
        $c->train;
    }

    return $c;
}

sub generate_sets {
    my $self = shift;
    my $query = "
        select 
        main.id, 
        group_concat(distinct concat(cats.id,' - ',cats.name) SEPARATOR ';;') as catnames
        from main 
        join cats_me on (cats_me.eId=main.id) 
        join primary_ancestors a1 on (a1.cId=cats_me.cId)
        join cats on (cats.id=a1.aId and cats.pLevel=?) 
        join primary_ancestors a2 on (a2.aId=? and a2.cId=a1.aId) 
        where not deleted=1 
        group by main.id
        order by rand()
        " 
        ;
    $query .= ' limit ' . $self->db_limit if defined $self->db_limit;
    my $sth = xPapers::DB->exec( $query, $self->cat_level, $self->cat_root );

    my @input_list = shuffle( @{ $sth->fetchall_arrayref } );
    my $total = $#input_list+1;
    my %categories;
    open my $training_fh, '>:encoding(UTF-8)', $self->data_dir . '/training';
    open my $testing_fh, '>:encoding(UTF-8)', $self->data_dir . '/testing';
    my $i = 0;
    print "Fetching\n";
    while( my $row =  pop @input_list ){
        my( $id, $categories ) = @$row;
        my @cats = split ';;', $categories;
        $categories{ $_ } = 1 for @cats;
        my $entry = xPapers::Entry->new( id => $id )->load;
        die "Entry does not exist: $id\n"  unless $entry;
        my $deflated = $self->deflate_entry( $entry );
        $deflated =~ s/\n/ /g; 
        $deflated = rmDiacritics($deflated);
        $deflated =~ s/\b[xiv]+\b//;  # roman numbers
        if( $i < int($self->train_with*$total) ){
            print $training_fh "$id||||$categories||||$deflated\n";
        }
        else{
            print $testing_fh "$id||||$categories||||$deflated\n";
        }
        print "$i / $total done\n" if ! ($i++ % 100);
        last if $i >= ($self->train_with*$total) + ($self->max_tests*$total);
    }

    store \%categories, $self->data_dir . '/categories';
}

sub deflate_entry {
    my ( $self, $entry ) = @_;
    my $out = '';
    for my $col ( qw/ title source descriptors author_abstract / ){
        $out .= (defined $entry->$col ? $entry->$col : '') . "||||";
    }
    $out .= join( '::', $entry->getAuthors ) . '||||';
    $out .= join( '::', $entry->getEditors );
    return $out;
}

sub train {
    my $self = shift;
    print "Init learner object\n";

    print "Build knowledge sets\n";

    my $collection = xPapers::AI::FileCollection->new( path => $self->data_dir . '/training', delimiter => "\n", );

    my $fs = AI::Categorizer::FeatureSelector::ChiSquare->new( features_kept => $self->features_kept, verbose => 1 );
    my $stopwords = getStopWords('en');
    $stopwords->{$_} = 1 for 'a' .. 'z';
    my $features = $fs->scan_features( collection => $collection, stopwords => $stopwords, );

            my $h = $features->as_hash;
            my @sorted = sort {$h->{$b}<=>$h->{$a}} keys %$h;
            open F, ">/tmp/features7";
            print F "$_ -> $h->{$_}\n" for @sorted;
            print F "\n"; # just to avoid a 'possible typo' warning
            close F;

    store $features, $self->data_dir . '/features';
    my $ks = new AI::Categorizer::KnowledgeSet(
        name => 'Test',
        tfidf_weighting => $self->tf,
        #                        collection => xPapers::AI::FileCollection->new( path => 't/data/entries', delimiter => "\n", ),
    );
    $ks->features( $features );

    open my $entries_fh, '<:encoding(UTF-8)', $self->data_dir . '/training';

    my $i = 0;
    while( my $line = <$entries_fh> ){ 
        my ( $id, $content, $categories ) = xPapers::AI::FileCollection::parse_line( $line );
        my %args = ( 
            categories => $categories, 
            name => $id, 
            content => $content, 
            use_features => $features,
    #        stemming => 'porter',
    #        front_bias => 0.5,
        );
        $args{ content_weights } = $self->cw if $self->cw;
        $ks->make_document( %args );
        print "$i done.\n" if !( $i++ % 100 );
    }
    $self->add_learner( { label => "Bayes_0.9",   learner => AI::Categorizer::Learner::NaiveBayes->new(threshold=>0.9) } );
    $self->add_learner( { label => "SVM_default", learner=> AI::Categorizer::Learner::SVM->new() } );

    for my $conf ( @{$self->learners} ) {
        my $learner = $conf->{learner};
        my $time = time;
        $learner->train( knowledge_set => $ks );
        my $training_time = time - $time;
        $conf->{training_time} = $training_time;
        $learner->save_state( $self->data_dir . '/' . $conf->{label} . '_saved');
    }
}

sub find_all_cats {
    my( $self, $doc ) = @_;
    my $entry = xPapers::Entry->get($doc->{id});
    my %areas;
    for my $cat ( $entry->publicCats ){
        if ($cat->pLevel == 1) {
                $areas{ $cat->id } = $cat;
        } else {
            for my $area( $cat->areas( $self->cat_level ) ){
                $areas{ $area->id } = $area;
            }
        }
    }
    my @result;
    for my $area ( values %areas ){
        push @result, $area->id . ' - ' . $area->name;
    }
    #use Data::Dumper;
    #warn $doc->{id};
    #print Dumper(\@result);
    return [ @result ];
}

sub report_testing {
    my $self = shift;
    my @test_docs;
    open my($tests_fh), '<:encoding(UTF-8)', $self->data_dir . '/testing';
    while( my $line = <$tests_fh> ){ 
        my ( $id, $content, $categories ) = xPapers::AI::FileCollection::parse_line( $line );
        push @test_docs,  { doc => AI::Categorizer::Document->new( name => $id, content => $content ), categories => $categories, content => $content, id => $id };
    }
    open my($io), '>', $self->data_dir . '/report'; 
    open my($global_io), '>>', $self->data_root . '/report.csv'; 
    $io->autoflush( 1 );
    print $io $self->comment . "\n\n";

    my @results;
    for my $conf ( @{ $self->learners } ) {
        print $io "*" x 50 . "\n";
        print $io $conf->{label} . "\n";
        my $learner = $conf->{learner};
        print $io 'trained in: ' . $conf->{training_time} . "\n";
        my $e = AI::Categorizer::Experiment::FPStats->new( categories => $self->categories );
        my $with_at_least_one_cat = 0;
        my $no_cats = 0;
        for my $doc (@test_docs){
            my $r = $learner->categorize( $doc->{doc} );
            $doc->{all_cats} ||= $self->find_all_cats( $doc );
            $e->add_hypothesis($r, $doc->{all_cats} );
            $with_at_least_one_cat++ if $r->categories;
            $no_cats++ if ! $r->categories;
        }
        my $result = { learner=>$conf->{label}, f1=>$e->micro_F1, experiment =>$e, set=>undef, training_time => $conf->{training_time} };
        push @results, $result;
        $self->print_result( $io, $result );
        $self->print_result( $global_io, $result );
        print $io "with_at_least_one_cat: $with_at_least_one_cat, no_cats: $no_cats\n";
        print $io $e->stats_table;
    }

    my @learners = @{ $self->learners };
    if ($self->do_intersection) {
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
                my $errors = {};

                my $e = AI::Categorizer::Experiment::FPStats->new(categories=>$self->categories);
                my $with_at_least_one_cat = 0;
                my $no_cats = 0;
                for my $doc (@test_docs){
                    my $r = $learner->categorize( $doc->{doc} );
                    $e->add_hypothesis($r, $doc->{all_cats} );
                    record_errors( $errors, $r, $doc->{all_cats}, $doc );
                    $with_at_least_one_cat++ if $r->categories;
                    $no_cats++ if ! $r->categories;
                }
                my $result = { learner=>$name, f1=>$e->micro_F1, experiment =>$e, set=>undef };
                push @results, $result;
                $self->print_result( $io, $result );
                $self->print_result( $global_io, $result );
                print $io "with_at_least_one_cat: $with_at_least_one_cat, no_cats: $no_cats\n";
                print $io $e->stats_table;

                $self->print_errors( $errors );
            }
        }
    }
}

sub print_errors {
    my( $self, $errors ) = @_;
    my $errors_file = $self->data_dir . '/errors'; 
    open my $fh, '>:encoding(UTF-8)', $errors_file;
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


sub print_result {
    my ( $self, $fh, $r, ) = @_;
    my $set = $r->{set};
    my $line = 'global: ' . $self->comment 
    . ' cat_level: ' . $self->cat_level
    . ' cat_root: ' . $self->cat_root
    . ' learner: ' . $r->{learner} 
    . ' training with (%): ' . $self->train_with
    . ' tf: ' . $self->tf 
    . ' cw: ' . ( $self->cw ? 'YES' : 'NO' ) 
    . ' features_kept: ' . (defined $self->features_kept ? $self->features_kept : ' NO')
    . ' training_time: ' . (defined $r->{training_time} ? $r->{training_time} : '' )
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





1;

__END__

=head1 NAME

xPapers::AI::Categorizer

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<Moose::Object>



=head1 ATTRIBUTES

=head2 cat_level 



=head2 cat_root 



=head2 categories 



=head2 comment 



=head2 cw 



=head2 data_dir 



=head2 data_root 



=head2 db_limit 



=head2 do_intersection 



=head2 features_kept 



=head2 learners 



=head2 max_tests 



=head2 tf 



=head2 train_with 



=head1 METHODS

=head2 categorize 



=head2 deflate_entry 



=head2 entry2doc 



=head2 find_all_cats 



=head2 generate_sets 



=head2 make 



=head2 make_or_retrieve 



=head2 print_errors 



=head2 print_result 



=head2 record_errors 



=head2 report_testing 



=head2 str2cats 



=head2 suggest 



=head2 train 



=head2 transform 




=head1 DIAGNOSTICS

=head1 AUTHORS

Zbigniew Lukasiak with contributions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



