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

__END__

=head1 NAME

xPapers::Link::Affiliate::Quote

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: affiliate_quotes


=head1 FIELDS

=head2 bargain_ratio (integer):

=head2 company (varchar):

=head2 currency (varchar):

=head2 detailsURL (varchar):

=head2 eId (varchar):

=head2 found (timestamp):

=head2 id (bigserial):

=head2 link (varchar):

=head2 link_class (varchar):

=head2 locale (varchar):

=head2 price (numeric):

=head2 state (varchar):

=head2 usd_price (numeric):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



