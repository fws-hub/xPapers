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
