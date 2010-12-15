package xPapers::Render::JSON;

use JSON::XS qw/encode_json/;
use Data::Dumper;
use xPapers::Entry;
use HTML::Entities qw/encode_entities/;
use xPapers::Util qw/toUTF/;

use utf8;
use vars qw/@ISA @EXPORT @EXPORT_OK/;
@ISA = qw/xPapers::Render::HTML/;
my %skip = map { $_ => 1 } qw/authors editors added updated title/;

my %chmap = (
'“' => '"',
'”' => '"',
'‘' => "'",
'’' => "'",
' ' => ' ',
);
my $CHR = join("|", keys %chmap);

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{linkNames} = 0;
  bless $self, $class;
  return $self;
}

sub cleanch {
    my $in = shift;
    $in =~ s/($CHR)/$chmap{$1}/ge;
    return $in;
}
sub beginCategory {}
sub endCategory {}
sub startBiblio { 
    my ($me, $junk, $p) = @_;
    $me->{o} = {content=>[],level=>-1,found=>$p->{found}};
    $me->{template} = $me->tpl; 
    $me->{counter} = $me->{cur}->{start};
    if ($me->{showTemplate}) {
        $me->{o}->{template} = $me->{template};
        $me->{tplRendered} = 1;
    }
    # compile field list
    $me->{fields} = {};
    for my $t (@{$me->{template}}) {
        $me->{fields}->{$_} = 1 for @{$t->{fields}},"date";
    }
    return "";
}
sub endBiblio { 
    my $me = shift;
    my $r = encode_json $me->{o};
    #my $char = chr(hex(2029));
    #$r = toUTF($r);
    #$r =~ s/$char//g;
    return $r;
}

sub tpl {
    my $me = shift;
    $me->prepTpl;
    my $t = $me->{template};
    my @r;
    for (my $i=0; $i <= $#$t; $i++) {
        next unless !$t->[$i]->{secureOnly} or $me->{secure};
        next unless !$t->[$i]->{requiresLogin} or $me->{cur}->{user};
        push @r, $t->[$i];
    }
    return \@r; 
}

sub renderHeader {
  my ($me,$id,$cfg,$fieldArray,$level) = @_;
  my $field = $cfg->{type} =~ /day|journal/ ? 1 : 0;
  my $header = $fieldArray->[$field];
  # find the right content[] where to put it
  my $container = $me->{o};
  my $list = $container->{content};
  while ($level - $container->{level} > 1 and $#$list > -1 and exists $list->[-1]->{content}) {
    $container = $list->[-1];
    $list = $container->{content};
  }
  push @$list, {header=>$header,html=>$me->SUPER::renderHeader($id,$cfg,$fieldArray,$level),level=>$level,id=>$id,type=>$cfg->{type},content=>[]};
  return "";
}

sub beforeGroup {}
sub afterGroup {}
sub renderNav {}

sub renderEntry {

  my ($me,$e) = @_;

  my $list = $me->{o}->{content};
  while ($#$list > -1 and exists $list->[-1]->{content}) {
    $list = $list->[-1]->{content};
  }

#    $e->{highlighted}->{author_abstract} = undef;
#    $e->{author_abstract} = undef;
#  if ($e->{highlighted}) {
#      $e->{highlighted}->{$_} = encode_entities(cleanch($e->{highlighted}->{$_})) for qw/title author_abstract/;
#  } else {
#      $e->{$_} = encode_entities(cleanch($e->{$_})) for qw/title author_abstract/;
#  }
  $me->{cur}->{readingList} = $me->{cur}->{user}->reads if 
    !$me->{cur}->{readingList} and
    $me->{cur}->{user} and 
    $me->{cur}->{user}->{readingList};

  $me->moreFields($e);
  $me->prepCit($e);
  my %r;
  #$r{elId} = $me->entryId($e);

  # more fields
  for (keys %{$me->{fields}}) {
    next if ref($e->{$_});
    $r{$_} = $e->{$_} if (exists $e->{$_});
  }

  #special handling
  #$r{title} = $me->capitalize($e->{title});
  #$r{pubInfo} = $me->prepPubInfo($e) if $me->{showPub};
  $r{added} = ref($e->{added}) ? ($e->added->ymd . " " . $e->added->hms) : $e->{added}; 
  $r{updated} = ref($e->{added}) ? $e->{added}->ymd : $e->{added}; 
  $r{authors} = [$e->getAuthors];
  $r{googleBooksQuery} = $e->{googleBooksQuery} ? 1 : 0;
  $r{sortPos} = sprintf("%010d",$me->{counter}++);

  # encode the field subsceptible of containing characters prototype.js doesn't like
#  print STDERR "ABS:$r{author_abstract}\n";

  #$r{ant_editors} = [$e->getEditors];

  push @$list,\%r;

  return "";

}



1;
__END__


=head1 NAME

xPapers::Render::JSON




=head1 SUBROUTINES

=head2 afterGroup 



=head2 beforeGroup 



=head2 beginCategory 



=head2 cleanch 



=head2 endBiblio 



=head2 endCategory 



=head2 new 



=head2 renderEntry 



=head2 renderHeader 



=head2 renderNav 



=head2 startBiblio 



=head2 tpl 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



