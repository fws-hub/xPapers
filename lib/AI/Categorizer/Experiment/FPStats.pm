use strict;
use warnings;

package AI::Categorizer::Experiment::FPStats;
use base 'AI::Categorizer::Experiment';

__PACKAGE__->valid_params (
    fp_stats => { type => 'REF', default => {} },
);

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_); 
    $self->{fp_stats} = {};
    $self->{cat_stats} = {};
    return $self;
}

sub fp_stats {
    my $self = shift;
    $self->{fp_stats} = shift if @_;
    return $self->{fp_stats};
}

sub cat_stats {
    my $self = shift;
    $self->{cat_stats} = shift if @_;
    return $self->{cat_stats};
}

sub add_hypothesis {
    my $self = shift;
    my ($h, $correct) = @_;
    $self->SUPER::add_hypothesis( @_ );
    my $fp_stats = $self->fp_stats;
    my %correct = map { $_ => 1 } @$correct;
    $self->{cat_count} ||= 0;
    $self->{case_count} ||= 0;
    $self->{case_count}++;
    for my $cat ( $h->categories ){
        $self->{cat_count}++;
        $self->cat_stats()->{$cat}++;
        $fp_stats->{$cat}++ if !$correct{$cat};
    }
}
sub stats_table {
    my $self = shift;
    my $fp_stats = $self->fp_stats;
    my $cat_stats = $self->cat_stats;
    my $out = '';
    my $i;
    for my $cat ( sort { $fp_stats->{$b}/$cat_stats->{$b} <=> $fp_stats->{$a}/$cat_stats->{$a} } keys %$fp_stats ){
        $out .= "$cat: " . sprintf( '%.4f', $fp_stats->{$cat}/$cat_stats->{$cat} ) . ' ' . $cat_stats->{$cat} . ' ' . $fp_stats->{$cat} . "\n";
#        last if $i++ > 20;
    }
    return 
    $self->SUPER::stats_table() .
    (int($self->{cat_count} / $self->{case_count} *100) / 100) . " categories per case.\n" .
    "The most missapplied categories:\n$out" if $self->{case_count};
}

