package xPapers::Render::Struct;

use JSON::XS qw/encode_json/;
use Data::Dumper;
use xPapers::Entry;
use HTML::Entities qw/encode_entities/;
use Encode 'decode';
use xPapers::Util qw/toUTF rmTags capitalize/;

use base xPapers::Render::Text;

sub beginBiblio {
    my $me = shift;
    $me->{biblio} = [];
}

sub endBiblio {
    my $me = shift;
    return encode_json $me->{biblio};
}

sub renderEntry {
    my ($me,$e) = @_;
    $e->load;
    my $e =  {
        authors => [$e->getAuthors],
        title => capitalize($e->title,notSentence=>1),
        year => $e->date,
        id => $e->id,
        type => $e->type,
        categories => [ map { { id => $_->id, name => $_->name } } $e->canonical_categories_o ],
        links => [ $e->getAllLinks ],
        pubInfo => trim(rmTags($me->prepPubInfo($e)))
    };
    push @{$me->{biblio}}, $e;
    $e;
}

sub trim {
    my $in = shift;
    $in =~ s/^\s+//g;
    $in =~ s/\s+/ /g;
    return $in;
}

1;

