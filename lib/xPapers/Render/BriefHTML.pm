package xPapers::Render::BriefHTML;
use xPapers::Entry;

use base 'xPapers::Render::HTML';

sub new {
      my ($class,$self) = @_;
      my ($class) = @_;
      my $self = $class->SUPER::new();
      $self->{noOptions} = 1;
      bless $self, $class;
      return $self;
}


test();
sub test {

    my $e = xPapers::Entry->get('BOUQLI');
    my $r = xPapers::Render::BriefHTML->new;
    print "now.\n";
    print $r->renderEntry($e) . "\n";

}


1;
