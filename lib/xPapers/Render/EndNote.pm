package xPapers::Render::EndNote;

use vars qw/@ISA @EXPORT @EXPORT_OK/;
use xPapers::Util qw/rmTags/;
use xPapers::Render::Records;

@ISA = qw/xPapers::Render::Records/;
my @stdfields = qw/authors date title source ant_editors ant_publisher publisher volume issue pages author_abstract/;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  bless $self, $class;
  return $self;
}

sub quoteChars {
    return ();
}

sub begin {
    my ($me,$e) = @_;
    my $r;
    $me->{ctype} = $e->{pub_type};
    if ($e->{pub_type} eq 'book' or $e->{pub_type} eq 'thesis') {
        $r .= "\%0 Book\n";
    } elsif ($e->{pub_type} =~ /chapter|collection/) {
        $r .= "\%0 Book Section\n"; 
    } else {
        $r .= "\%0 Journal Article\n";
    }
    return $r;
}

sub end { return "\n"; }

sub fieldMap {
    my ($me,$e) = @_;
    my $m = {
    '%A' => 'authors',
    '%D' => 'date',
    '%T' => 'title',
    '%V' => 'volume',
    '%P' => 'pages',
    '%N' => 'issue',
    '%I' => 'publisher'
    };
    if ($me->{ctype} eq 'journal') {
        $m->{'%J'} = 'source';
    } elsif ($me->{ctype} =~ /chapter|collection/) {
        $m->{'%B'} = 'source';
        $m->{'%I'} = 'ant_publisher';
        $m->{'%E'} = "ant_editors";
    } elsif ($me->{ctype} eq 'book') {
    }
    return $m;
}

sub field {
    my ($me,$field,$value) = @_;
    return unless $value;
    if (ref($value) eq 'ARRAY') {
        return unless $#$value > -1;
        return "$field " . join("$field ", map { $me->quote($_)."\n" } @$value);
    } else {
        return "$field " . $me->quote($value) . "\n"; 
    }
}


__END__


=head1 NAME

xPapers::Render::EndNote




=head1 SUBROUTINES

=head2 begin 



=head2 end 



=head2 field 



=head2 fieldMap 



=head2 new 



=head2 quoteChars 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



