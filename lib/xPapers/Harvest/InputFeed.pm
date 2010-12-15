use strict;
use warnings;

package xPapers::Harvest::InputFeed;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('input_feeds');
__PACKAGE__->overflow_config;
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


package xPapers::Harvest::InputFeedMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Harvest::InputFeed' }

__PACKAGE__->make_manager_methods('input_feeds');

1;

__END__


=head1 NAME

xPapers::Harvest::InputFeed

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: input_feeds


=head1 FIELDS

=head2 db_src (varchar): 



=head2 harvested (varchar): 



=head2 harvested_at (timestamp): 



=head2 id (serial): 



=head2 lastStatus (varchar): 



=head2 name (varchar): 



=head2 pass (varchar): 



=head2 type (varchar): 



=head2 url (varchar): 



=head2 useSince (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



