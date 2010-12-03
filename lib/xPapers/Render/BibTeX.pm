package xPapers::Render::BibTeX;
use strict;
use xPapers::Render::Records;
use TeX::Encode;
use HTML::Entities qw/decode_entities/;
#use vars qw/@ISA/;
use xPapers::Conf qw/%PATHS/;
#@ISA = qw/xPapers::Render::Records/;
use base qw/xPapers::Render::Records/;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  bless $self, $class;
  return $self;
}

sub listSep { return " and " };

sub quote {
  my ($me,$s) = @_;
#  my $cre = "(?:" . join('|',$me->quoteChars) . ")";
#  $s =~ s/[\r\n]/ /g;
#  $s =~ s/\\/\\\\/g;
#  $s =~ s/($cre)/\\$1/g if $me->quoteChars;
  $s = decode_entities($s);
  return TeX::Encode::encode('latex',$s);
}

sub fieldMap {
    my ($me) = @_;
    my $m = {
        author => "authors",
        title => "title",
        number => "issue",
        volume => "volume",
        year => "date",
        publisher => "publisher",
        pages => "pages",
        school => "school",
        abstract=> "author_abstract",
#        url => "url"

    };
    if ($me->{ctype} eq 'journal') {
        $m->{journal} = "source";
    } elsif ($me->{ctype} =~ /chapter|collection/) {
        $m->{booktitle} = "source";
        $m->{publisher} = "ant_publisher";
        $me->{editor} = "ant_editors",
    } elsif ($me->{ctype} eq 'book') {
    }
    return $m;
}

1;
__END__

=head1 NAME

xPapers::Render::BibTeX

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 fieldMap 



=head2 listSep 



=head2 new 



=head2 quote 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



