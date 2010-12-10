package xPapers::Render::Records;
#use xPapers::Render::LinearRenderer;

use strict;
#use vars qw/@ISA @EXPORT @EXPORT_OK/;
use xPapers::Render::HTML;
use xPapers::Util qw/capitalize rmTags lastname/;
use Unicode::Normalize 'decompose';
use TeX::Encode;
use HTML::Entities;
#@ISA = /xPapers::Render::HTML/;
use base qw/xPapers::Render::HTML/;

sub new {
    my $class = shift;
    my $me = $class->SUPER::new();
    $me->{used} = {};
    bless $me, $class;
    return $me;
}

sub quote {
  my ($me,$s) = @_;
  my $cre = "(?:" . join('|',$me->quoteChars) . ")";
  $s =~ s/[\r\n]/ /g;
  $s =~ s/\\/\\\\/g;
  $s =~ s/($cre)/\\$1/g if $me->quoteChars;
  decode_entities($s);
  return $s;
}

sub quoteChars {
    my $me = shift;
    return ('"');
}

sub renderEntry {
    my ($me,$e) = @_;
    $me->{fields} = [];
    return $me->begin($e) . $me->fields($e) . $me->end($e);
}

sub begin {
    my ($me,$e) = @_;
    my $r;
    $e->{date} = ($e->{date} =~ /^(\d\d\d\d|forthcoming)$/) ? "$e->{date}" : "";
    my @links = $me->prepLinks($e);
    if ($#links > -1) {
        $e->{url} = $links[0];
    }

    $me->{ctype} = $e->{pub_type};
    if ($e->{pub_type} eq 'journal') {
        $r .= '@article{';
    } elsif ($e->{pub_type} eq 'book') {
        $r .= '@book{';
    } elsif ($e->{pub_type} =~ /collection|chapter/) {
        $r .= '@incollection{'; 
    } elsif ($e->{pub_type} eq 'thesis') {
        $r .= 'phdthesis{';
    } else {
        $r .= '@unpublished{';
    }
    #my ($fw) = ( $e->{title} =~ /^(\w+)/ );
    #$fw = lc $fw;
    my $d = ($e->{date} || 'Manuscript');
    $d =~ s/^(\w)(.+)$/uc($1) . $2/e;
    my $id_base = decompose(lastname($e->firstAuthor));
    $id_base =~ s/[^a-zA-Z0-9\-]//g;
    $id_base .= $d;
    my $id = $id_base;
#    my @add = ('b'..'z');
#    unshift @add,'';
#    my $c = 0;
#    do {
#        $id = "$id_base$add[$c]";
#        $c++;
#    } while ($me->{used}->{$id}); 
#    $me->{used}->{$id} = 1;
    $r .= "$id-$e->{id},\n";
    return $r;
}

sub fields {
    my ($me,$e) = @_;
    my @r;
    my $map = $me->fieldMap;
    foreach my $f (keys %$map) {
       my $value = $e->{$map->{$f} || $f};
       $value = capitalize( $value ) if $f eq 'title';
       push @r, $me->field($f, $value);
    }
    return join( ",\n", @r ) . "\n";
}

sub end {
    my ($me,$e) = @_;
    return "}\n";
}


sub fieldMap {
    my @stdfields = qw/authors date title source ant_editors ant_publisher publisher volume issue pages author_abstract/;
    my %m;
    $m{$_} = $_ for @stdfields;
    return \%m;
}

sub field {
    my ($me,$field,$value) = @_;
    return unless $value;
    if ($field =~ /^(author|editor)$/) {
        return "\t$field = {" .$me->quote( join($me->listSep, 
                                    map { 
                                        join(" ", reverse split(/\s*,\s*/,$_)) 
                                    } 
                                    @$value 
                               ) ) . "}"; 
    } elsif (ref($value) eq 'ARRAY') {
        return "\t$field = {" . join($me->listSep, map { $me->quote($_) } @$value) . "}";
    } else {
        return "\t$field = {" . $me->quote($value) . "}"; 
    }
}

sub listSep {
    my ($me) = @_;
    return "; ";
}

sub init { };
sub beginCategory { };
sub endCategory { };
sub startBiblio { };
sub endBiblio { };
sub headerId { };
sub renderHeader {};
sub beforeGroup {};
sub afterGroup {};
sub entryId { my ($me,$e) = @_; return $e->id };
sub renderNav {};
sub afterEntry {};
sub nothingMsg {};
sub renderCat {};


1;
__END__

=head1 NAME

xPapers::Render::Records




=head1 SUBROUTINES

=head2 afterEntry 



=head2 afterGroup 



=head2 beforeGroup 



=head2 begin 



=head2 beginCategory 



=head2 end 



=head2 endBiblio 



=head2 endCategory 



=head2 entryId 



=head2 field 



=head2 fieldMap 



=head2 fields 



=head2 headerId 



=head2 init 



=head2 listSep 



=head2 new 



=head2 nothingMsg 



=head2 quote 



=head2 quoteChars 



=head2 renderCat 



=head2 renderEntry 



=head2 renderHeader 



=head2 renderNav 



=head2 startBiblio 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



