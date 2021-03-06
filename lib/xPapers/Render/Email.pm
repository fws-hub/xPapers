package xPapers::Render::Email;

use xPapers::Render::HTML;
use xPapers::Util qw/rmTags reverseName/;
use HTML::Entities qw/decode_entities/;
use xPapers::Conf;
our @ISA = qw/xPapers::Render::HTML/;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{noOptions} = 1;
  $self->{fullAbstract} = 1;
  $self->{skipInit} = 1;
  $self->{noMousing} = 1;
  $self->{noRelevance} = 1;
  $self->{showPub} = 1;

  bless $self, $class;
  return $self;
}
#sub beginCategory { };
#sub endCategory { };
sub startBiblio { 

    my ($me,$bib,$p) = @_;
    $p = $bib unless defined $p;
    my $header = strip($p->{header});
    my $data_header = $p->{noDataHeader} ? "" : "FOUND:$p->{found}; HEADER:$header\n";
return <<END
$data_header
<style>
body li div span { font-family: Arial,Verdana; font-size:12px } 
.pub_name { font-style: italic; }
.header_source { font-weight: bold }
.entryList{ margin-bottom: 10px }
.entry { padding-bottom:0px; display:block; margin-left:0px; }
.sh0 { color: #$C2; font-weight:bold; margin-left: auto; margin-right:auto; text-decoration:underline; padding-bottom:10px;; font-weight:bold }
.sh3 { font-size: 11px; font-color:#555; padding-top:4px }
.abstract { font-size: 12px; color: #333 }
.name, .articleTitle { font-weight: bold }
.ghc { margin-bottom:11px; font-size:16px; font-weight:bold }
.pplink { font-size: 12px }
</style>
END
} 

sub renderEntry {
    my $me = shift;
    $me->{showAbstract} = 1;
    $me->{linkNames} = 0;
    my $e = shift;
    $e->{extraOptions} .= '<br>';
    my @xtra;
    if (my $link = $e->firstComputedLink(affiliateLink=>1)) {
        $me->{jsLinks} = 1;
        my $dl = $me->mklnk($link,$e);
        $me->{jsLinks} = 0;
        push @xtra, "<a href=\"$dl\">Direct link</a>";
    }
    if (my $quotes = $me->renderQuotes($e)) {
        push @xtra, $quotes;
    }
    my $xtra = "";
    if (scalar @xtra) {
        $me->{addToEntry} = "&nbsp;&nbsp;<span class='pplink'>(" . join("&nbsp;&nbsp;|&nbsp;&nbsp;",@xtra) . ")</span>";
    }
    return $me->SUPER::renderEntry($e,@_);
}

sub prepTitle {
    my ($me,$e,$links) = @_;
    my $title = $me->cleanTitle($e->title);
    my $link = "$me->{cur}->{site}->{server}/rec/$e->{id}";
	$title = "<a class='articleTitle' href=\"$link\">$title</a>";
    if (grep {$e->{pub_type} eq $_} qw(book thesis)) {
        $title = "<span class='pub_name'>$title</span>";
    } 
    return $title;
}



sub endBiblio { return "\n</body>\n</html>\n" };
sub renderNav {};
sub nothingMsg {};
sub renderNameLit {
    my ($me,$name) = @_;
    my $r = reverseName($name);
    my $l = "<a class='person' href=\"?searchStr=$name&filterMode=authors\">$r</a>";
    return $l;
}

sub strip {
    my $i = shift;
    $i = decode_entities(rmTags($i));
    $i =~ s/\([^\)]+?\)//g;
    return $i;
}




1;

__END__


=head1 NAME

xPapers::Render::Email




=head1 SUBROUTINES

=head2 endBiblio 



=head2 new 



=head2 nothingMsg 



=head2 prepTitle 



=head2 renderEntry 



=head2 renderNameLit 



=head2 renderNav 



=head2 startBiblio 



=head2 strip 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



