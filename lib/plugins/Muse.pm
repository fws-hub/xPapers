package Muse;
use xPapers::Util 'parseAuthors';
use base 'xPapers::Harvest::Plugin';

sub check { my ($me, $e, $f) = @_; return UNIVERSAL::isa($f,'xPapers::Harvest::InputFeed') && $f->url =~ /muse.jhu.edu/ }
sub process {
    my ($me, $e, $f) = @_; 
    if ($e->{author_abstract} =~ s/<p>By (.+?)<\/p>//smg) {
        $e->deleteAuthors;
        $e->addAuthors(parseAuthors($1));
    };
    $e->{author_abstract} =~ s/<a href=.+?>Read More.?<\/a>//;
    if ($e->firstLink =~ /(\d+)\.(\d+)\.[\w\-]+\.html/) {
       $e->volume($1);
       $e->issue($2);
    }
}

1;
