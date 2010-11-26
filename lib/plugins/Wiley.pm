package Wiley;
use base 'xPapers::Harvest::Plugin';

sub check { my ($me, $e, $f) = @_; return UNIVERSAL::isa($f,'xPapers::Harvest::InputFeed') && $f->url =~ /\.wiley\.com/ }
sub process {
    my ($me, $e, $f) = @_; 
    $e->{author_abstract} =~ s/<l type=.+<\/l>//smg;
    my @links = $e->getLinks;
    unshift @links, "http://onlinelibrary.wiley.com/doi/$e->{doi}/abstract";
    $e->deleteLinks;
    $e->addLinks(@links);
    if ($e->{pages} =~ /no/) {
        $e->volume(undef);
        $e->issue(undef);
        $e->pages(undef);
        $e->date('forthcoming');
    }
}

1;
