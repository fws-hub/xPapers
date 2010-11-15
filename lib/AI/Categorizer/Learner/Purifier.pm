use strict;
use warnings;

package AI::Categorizer::Learner::Purifier;

use base 'AI::Categorizer::Learner';
use Data::Dumper;


__PACKAGE__->valid_params(
    learner => { isa => 'AI::Categorizer::Learner' },
);

sub learner {
    my $self = shift;
    $self->{learner} = shift if @_;
    return $self->{learner};
}

sub train {
    my ($self, %args) = @_;
#    my $bad = $self->bad_items($args{knowledge_set});    
    my ($a,$b) = $self->split($args{knowledge_set});
    my $bad = $self->bad_items($a,$b);
    print "Original set: " . scalar($args{knowledge_set}->documents) . "\n";
    print "Eliminated items: " . scalar(keys %$bad) . "\n";
    my %kparams = %{$args{knowledge_set}->dump_parameters};
    my $new_set = AI::Categorizer::KnowledgeSet->new(%kparams);
    for my $doc ($args{knowledge_set}->documents) {
        next if $bad->{$doc->name};
        $new_set->add_document($doc);
    }
    print "New set: " . scalar($new_set->documents) . "\n";
    my %params = %{$self->learner->dump_parameters};
    $self->learner(
        ref($self->learner)->new(%params)
    );
    print "TRAIN REAL\n";
    return $self->learner->train(knowledge_set=>$new_set);
    print "END REAL\n";
}

sub bad_items {
    my ($self, $seta, $setb, $bad) = @_;
    $setb ||= $seta;
    $bad = $self->_bad_items($seta,$setb,$bad);
    $self->_bad_items($setb,$seta,$bad) unless $seta==$setb;
    return $bad;
}

sub _bad_items {
    my ($self, $seta, $setb, $bad) = @_;
    print scalar $seta->documents . " docs in bad training\n";
    print scalar $seta->categories . " categories in bad training\n";
    $self->learner->train( knowledge_set=>$seta );
    $bad = {} unless defined $bad;
    OUTER: for my $doc ($setb->documents) {
        my $h = $self->learner->categorize($doc);
        my @found = $h->categories;
        #print scalar @found . " found\n";
        for my $cat ($h->categories) {
            unless (grep { $cat eq $_->name } $doc->categories) {
                $bad->{$doc->name} = 1;
                next OUTER;
                #print "bad for $cat:\n" . $doc->name . "\n" . join(";", $doc->categories) . "\n" . Dumper($doc->features) . "\n";
            } else {
                #print "$cat is in: " . join("; ", map { $_->name } $doc->categories) . "\n";
            }
        }
    }
    return $bad;
}

sub split {
    my ($self,$set) = @_;
    my @all = $set->documents;
    my @docs1;
    for (0..int($#all/2)) {
      push @docs1, splice @all, rand(@all), 1;
    }
    my %orig = %{$set->dump_parameters};
    delete $orig{documents};
    my $set1 = ref($set)->new(%orig);
    $set1->add_document($_) for @docs1;
    my $set2 = ref($set)->new(%orig);
    $set2->add_document($_) for @all;
    
    #print scalar $set1->documents . "\n";
    #print Dumper($docs1[0]->name);
    #print Dumper($all[0]->name);
    #print scalar $set2->documents . "\n";
    #exit;
    #print Dumper($set1->documents);
    #print Dumper($set2->documents);
    return ($set1,$set2);
}

sub categorize {
    my ($self, $doc) = @_;
    return $self->learner->categorize( $doc );
}
      
