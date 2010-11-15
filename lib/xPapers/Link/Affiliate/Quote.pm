use strict;
use warnings;

package xPapers::Link::Affiliate::Quote;

use xPapers::Conf ;
use xPapers::Util qw/file2hash/;
use base qw/xPapers::Object/;

use Rose::DB::Object::Metadata::UniqueKey;
use IP::Country::Fast;

__PACKAGE__->meta->table('affiliate_quotes');
__PACKAGE__->meta->auto_initialize;


__PACKAGE__->meta->add_unique_key( Rose::DB::Object::Metadata::UniqueKey->new(
        name => 'ecls',
        columns => [ qw/ eId company locale state/ ]
    )
);



1;

