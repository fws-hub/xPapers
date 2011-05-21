package xPapers::Render::Struct;

use JSON::XS qw/encode_json/;
use Data::Dumper;
use xPapers::Entry;
use HTML::Entities qw/encode_entities/;
use xPapers::Util qw/toUTF/;

use utf8;
use base xPapers::Render::Text;

sub renderEntry {
    my ($me,$e) = @_;

    return {
        authors => [$e->getAuthors]


    }

}


