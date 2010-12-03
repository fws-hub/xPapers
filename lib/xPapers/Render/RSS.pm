package xPapers::Render::RSS;
use xPapers::Render::Text;

use xPapers::Util qw/rmTags decodeHTMLEntities/;
use HTML::Entities;
use XML::RSS;

@ISA = qw/xPapers::Render::Text/;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{compactAuthors} = 1;
  bless $self, $class;
  return $self;
}

sub startBiblio {
    my ($me,$bib,$p) = @_;
    $me->{x} = new XML::RSS (version => '1.0');
    my $x = $me->{x};
    $p = $bib if !defined $p;
    $x->channel(
        title => $me->s->{niceName} . ($p->{header} ? (": " . a($p->{header})) : ""),
        link => $me->s->{server},
        syn => {
            updatePeriod => 'daily',
            updateFrequency => 1,
            updateBase => '2008-07-01T00:00+00:00',
        },
        taxo => [
            'http://www.dmoz.org/Reference/Bibliography/'
        ]
    );
    return "";
}

sub renderEntry {
    my ($me,$e) = @_;
    #<meta xmlns="http://www.w3.org/1999/xhtml"
    #   name="robots" content="noindex" />
    #
    $me->startBiblio unless $me->{x};
    $me->{jsLinks} = 1;
    $me->{x}->add_item(
        title => p($me->renderAuthors($e->getAuthors)) . ": " . p($e->{title}), 
        link => p("$me->{cur}->{site}->{server}/rec/$e->{id}"),
        description => d($e->{source} and $e->{date} =~ /\d\d\d\d|forthcoming/ ? 
                            $me->prepPubInfo($e)." $e->{date}<br>" : "") .  
                       ($me->{showAbstract} ? d($e->{author_abstract}) : "") . 
                       $me->renderQuotes($e) .
                       ($e->firstLink? "<div>(<a href=\"" . $me->mklnk($e->firstLink,$e) . "\">direct link</a>)</div>" : "") 
                       ,
        taxo => []
    );
    return "";
}

sub renderQuotes {
    my $me = shift;
    # disabled
    return "";
    my $quotes = $me->SUPER::renderQuotes(@_); 
    return "" unless $quotes;
    return "<p>$quotes</p>";
}

sub endBiblio {
    my $me = shift;
    #use Data::Dumper;
    #return Dumper($me->{x});
    my $res = $me->{x}->as_string;
    #$res =~ s/\n//gs;
    return $res;

}

sub a {
    my $i = p(shift());
    $i =~ s/\([^\)]+?\)//g;
    return $i;
}

sub p {
    my $i = shift;
    $i = d(rmTags($i));
    return $i || '';
}

sub d {
    my $i = shift;
    $i = decodeHTMLEntities(rmTags($i));
    return $i || '';
}

sub np {
    my $i = shift;
    while ($i =~ s/\s+\(.+?\)\s*//g) {};
    return $i;
}
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



