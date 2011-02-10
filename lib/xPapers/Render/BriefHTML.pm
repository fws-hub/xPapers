package xPapers::Render::BriefHTML;
use xPapers::Entry;
use xPapers::Util;

use base 'xPapers::Render::HTML';

sub new {
      my ($class,$self) = @_;
      my ($class) = @_;
      my $self = $class->SUPER::new();
      $self->{noOptions} = 1;
      bless $self, $class;
      return $self;
}

sub prepTitle {
    my ($me,$e,$links) = @_;
    return unless $e;
    return "<a class='articleTitle' href=\"/rec/$e->{id}\">" . dquote($e->title) . "</a>";
}

test();
sub test {

    my $e = xPapers::Entry->get('BOUQLI');
    my $r = xPapers::Render::BriefHTML->new;
    print "now.\n";
    print $r->renderEntry($e) . "\n";

}


1;
