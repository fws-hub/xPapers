package xPapers::AI::FileCollection;

use base 'AI::Categorizer::Collection::SingleFile';
use strict;
use AI::Categorizer::Category;
use xPapers::Util qw/parseName2 rmDiacritics/;
use Tie::Hash::Indexed;

sub next {
    my $self = shift;

    my $fh = $self->{fh}; # Must put in a simple scalar
    my $content = do {local $/ = $self->{delimiter}; <$fh>};

    if (!defined $content) { # File has been exhausted
        unless (@{$self->{path}}) { # All files have been exhausted
            $self->{fh} = undef;
            return undef;
        }
        $self->_next_path;
        return $self->next;
    } 
    elsif ($content =~ /^\s*$self->{delimiter}$/) { # Skip empty docs
        return $self->next;
    }

    return $self->create_delayed_object('document', $self->parse( $content ) );
}

sub parse {
    my( $self, $line ) = @_;
    my ( $id, $content, $categories ) = parse_line( $line );
    return ( 
        content => $content, 
        name => $id,  
        categories => [ map { AI::Categorizer::Category->by_name( name => $_ ) } @$categories ],
    );
}

sub parse_line {
    my $line = shift;
    chomp $line;
    my @line = split '\|\|\|\|', $line;
    my $id = shift @line;
    my @categories = split ';;', shift @line;
    tie my %content, 'Tie::Hash::Indexed';
    $content{$_} = shift @line for qw/ title source descriptors author_abstract authors editors /;
    $content{source} =~ s/\s/xx/g;
    $content{source} = "xx$content{source}xx" if $content{source};
    $content{authors} = process_names( $content{authors} );
    $content{editors} = process_names( $content{editors} );
    return $id, \%content, \@categories;
}

sub process_names {
    my $in = shift;
    my $out;
    for my $name ( split '::', $in ){
        my ($first,$init,$last) = parseName2($name);
        $first =~ s/\.//g if $first;
        $out .= "xx$last" . (defined $first ? "xx$first" : '') . 'xx ';
    }
    return $out;
}

1;

__END__

=head1 NAME

xPapers::AI::FileCollection

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 next 



=head2 parse 



=head2 parse_line 



=head2 process_names 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



