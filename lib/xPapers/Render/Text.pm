package xPapers::Render::Text;

use base qw/xPapers::Render::RichText/;
use xPapers::Util qw/rmTags/;

sub renderEntry {
    my ($me,$e) = @_;
    my $t = $me->SUPER::renderEntry($e);
    $t =~ s/<br>/\n/g;
    $t = rmTags($t);
    $t =~ s/ +/ /g;
    $t =~ s/ ([\.\?])/$1/g;
    return $t;
}

sub startBiblio { };


1;
__END__

=head1 NAME

xPapers::Render::Text




=head1 SUBROUTINES

=head2 renderEntry 



=head2 startBiblio 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



