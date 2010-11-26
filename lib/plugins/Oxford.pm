package Oxford;
use base 'xPapers::Harvest::Plugin';

sub check { my ($me, $e, $f) = @_; return UNIVERSAL::isa($f,'xPapers::Harvest::InputFeed') && $f->url =~ /oxfordjournals.org/ }
sub process {
    my ($me, $e, $f) = @_; 
    $e->{author_abstract} =~ s/<l type=.+<\/l>//smg;
    # we are being given invalid DOIs..
    $e->{doi} = undef if $e->source =~ /Analysis/;
}

1;
