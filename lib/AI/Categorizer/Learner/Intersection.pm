use strict;
use warnings;

package AI::Categorizer::Learner::Intersection;

use base 'AI::Categorizer::Learner';


__PACKAGE__->valid_params(
    learner1 => { isa => 'AI::Categorizer::Learner' },
    learner2 => { isa => 'AI::Categorizer::Learner' },
);

sub learner1 {
    my $self = shift;
    $self->{learner1} = shift if @_;
    return $self->{learner1};
}

sub learner2 {
    my $self = shift;
    $self->{learner2} = shift if @_;
    return $self->{learner2};
}

sub train {
    my ($self, %args) = @_;
    $self->learner1->train( %args );
    $self->learner2->train( %args );
}

sub categorize {
    my ($self, $doc) = @_;

    my $h1 = $self->learner1->categorize( $doc );
    my $h2 = $self->learner2->categorize( $doc );

    my %cats = map { $_ => 1 } $h1->all_categories(), $h2->all_categories;
    my %c1 = map { $_ => 1 } $h1->categories;
    my %c2 = map { $_ => 1 } $h2->categories;
    my %scores;
    for my $cat ( keys %cats ){
        if( $c1{$cat} && $c2{$cat} ){
            $scores{$cat} = 1;
        }
        else{
            $scores{$cat} = 0;
        }
    }
    
    my @doc_name;
    @doc_name = ( document_name => $h1->document_name ) if defined $h1->document_name;
    @doc_name = ( document_name => $h2->document_name ) if defined $h2->document_name;
    return AI::Categorizer::Hypothesis->new(
        all_categories => [ keys %cats ],
        scores => \%scores,
        threshold => 0.5,
        @doc_name,
    );
}
      
