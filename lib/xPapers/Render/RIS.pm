package xPapers::Render::RIS;

use vars qw/@ISA @EXPORT @EXPORT_OK/;
use xPapers::Util qw/rmTags/;
use xPapers::Render::EndNote;

@ISA = qw/xPapers::Render::EndNote/;

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
    if ($e->{pub_type} eq 'book') {
        $r .= "TY - BOOK\n";
    } elsif ($e->{pub_type} eq 'thesis') {
        $r .= "TY - THES\n";
    } elsif ($e->{pub_type} =~ /chapter|collection/) {
        $r .= "TY - CHAP\n";
    } else {
        $r .= "TY - JOUR\n";
    }
    return $r;
}

sub end { return "ER - \n\n"; }

sub fieldMap {
    my ($me,$e) = @_;
    my $m = {
    'AU -' => 'authors',
    'PY -' => 'date',
    'TI -' => 'title',
    'VL -' => 'volume',
    'IS -' => 'issue',
    'PB -' => 'publisher',
    };
    if ($me->{ctype} eq 'journal') {
        $m->{'JA -'} = 'source';
    } elsif ($me->{ctype} =~ /chapter|collection/) {
        $m->{'ED -'} = 'ant_editors';
        $m->{'T2 -'} = 'source';
        $m->{'PB -'} = 'ant_publisher';
    } elsif ($me->{ctype} eq 'book') {
    }
    return $m;
}


__END__


=head1 NAME

xPapers::Render::RIS




=head1 SUBROUTINES

=head2 begin 



=head2 end 



=head2 fieldMap 



=head2 new 



=head2 quoteChars 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



