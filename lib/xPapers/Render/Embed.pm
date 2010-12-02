package xPapers::Render::Embed;

use xPapers::Render::HTML;
use xPapers::Util qw/rmTags reverseName dquote/;
use HTML::Entities qw/decode_entities encode_entities/;
use xPapers::Conf;
our @ISA = qw/xPapers::Render::HTML/;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{noOptions} = 1;
  $self->{fullAbstract} = 1;
  $self->{noMousing} = 1;
  $self->{jsLinks} = 1;
  $self->{noDate} = 1;

  bless $self, $class;
  return $self;
}

sub startBiblio { 

    my $me = shift;

    if ($me->{cur}->{personalBiblio}) {
        my $user = $me->{cur}->{user};
        $me->{cur}->{events} = "";

        die "Must be logged in to use Embed renderer" unless $user;

        # Initialize aliases
        my %aliases = map { +"$_->{lastname}, $_->{firstname}" => 1 } $user->aliases;

        $me->{aliases} = \%aliases;
    }
    #use Data::Dumper;
    #print Dumper($me->{aliases});
    return "var xpapers_embed_buffer = '';\n" 

};

sub endBiblio { 
    my $me = shift;
    my $refresh = $me->{cur}->{personalBiblio} ? "&nbsp;&nbsp;|&nbsp;&nbsp;<a href='$me->{cur}->{site}->{server}/profile/$me->{cur}->{user}->{id}/myworks.pl?refresh=1'>Refresh</a>" : "";
    return <<END;
function xpapers_embed_init() {
    if (arguments.callee.done) return;
    arguments.callee.done = true;
    var el = document.getElementById('xpapers_gadget');
    if (el) {
        el.innerHTML = xpapers_embed_buffer + "<div style='font-size:smaller;text-align:right'>powered by <a href='$me->{cur}->{site}->{server}'>$me->{cur}->{site}->{niceName}</a>$refresh";
    } 
}

if (document.addEventListener) {
    document.addEventListener('DOMContentLoaded', xpapers_embed_init, false);
}
(function() {
    /*@cc_on@*/
    try {
        document.body.doScroll('up');
        return xpapers_embed_init();
    } catch(e) {}
    /*@if (false) @*/
    if (/loaded|complete/.test(document.readyState)) return xpapers_embed_init();
    /*@end @*/
    if (!xpapers_embed_init.done) setTimeout(arguments.callee, 30);
})();

if (window.addEventListener) {
    window.addEventListener('load', xpapers_embed_init, false);
} else if (window.attachEvent) {
    window.attachEvent('onload', xpapers_embed_init);
}
//v1.0
END
} 

sub renderEntry {
    my ($me,$e) = @_;
    $me->{showAbstract} = 1;
    $me->{linkNames} = 0;
    $me->{jsLinks} = 0;
    $me->{cur}->{showCategories} = 'off';
    return wrap($me->SUPER::renderEntry($e,@_));
}

sub wrap {
    my $html = shift;
    $html =~ s/[\n\r]+/ /gs;
    $html =~ s/class=("|')/class=\1xpapers_/sg;
    return qq{xpapers_embed_buffer += "} . dquote($html) . qq{";\n};
}

sub renderNav {};
sub nothingMsg {};

sub strip {
    my $i = shift;
    $i = decode_entities(rmTags($i));
    $i =~ s/\([^\)]+?\)//g;
    return $i;
}

sub prepCit {
	my ($me, $e) = @_;

    my $link = "$me->{cur}->{site}->{server}/rec/$e->{id}";
    $e->setDisplayLink($link);

    unless ($me->{cur}->{personalBiblio}) {
        $me->{noDate} = 0;
        my $r = $me->SUPER::prepCit($e);
        if ($e->{date} =~ /\d\d\d\d|forthcoming/) {
            $r .= " $e->{date}.";
        }
        return $r;
    }

    my $title = encode_entities($e->title);
    $title .= "." unless $title =~ /\W$/;
    my $r = "<a class='title' href=\"$link\">$title</a>";
    $r .= "<span class='pubInfo'>" . encode_nontag($me->prepPubInfo($e)); 
    my @coauthors;
    for ($e->getAuthors) {
        push @coauthors, encode_nontag($_) unless $me->{aliases}->{$_};
    }
    if ($e->{date} =~ /\d\d\d\d|forthcoming/) {
        $r .= " $e->{date}.";
    } 
    $r .= " <span class='coauthors'>Co-authored with " . encode_nontag($me->_renderAC(@coauthors)) . ".</span>" if $#coauthors > -1;
#    if ($#coauthors > -1) {
#        $r .= " Co-authored with " . shift @coauthors;
#        while (my $n = shift @coauthors) {
#            $r .= $#coauthors > -1 ? ", " : " and ";
#            $r .= $n;
#        }
#    }
    $r .= "</span>";
    $e->{__entry__} = $r . $me->{addToEntry};
	return;
}

sub encode_nontag {
    my $in = shift;
    $in =~ s/([^'"\<\>\&]+)/encode_entities($1)/ge;
    return $in;
}


1;

__END__

=head1 NAME

xPapers::Render::Embed

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 encode_nontag 



=head2 endBiblio 



=head2 new 



=head2 nothingMsg 



=head2 prepCit 



=head2 renderEntry 



=head2 renderNav 



=head2 startBiblio 



=head2 strip 



=head2 wrap 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



