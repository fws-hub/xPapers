package xPapers::OAI::EntryOrigin;
use xPapers::Conf;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('entry_origin');
__PACKAGE__->meta->relationships(
    entry => {
        type       => 'one to one',
        class      => 'xPapers::Entry',
        column_map => { eId => 'id' },
    },
);

__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;

package xPapers::OAI::EntryOrigin::Manager;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::OAI::EntryOrigin' }

__PACKAGE__->make_manager_methods('entry_origin');

1;

1;

__END__


=head1 NAME

xPapers::OAI::EntryOrigin

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: entry_origin

This class links the Entry with the OAI repository and set where it's data originated.


=head1 FIELDS

=head2 eId (varchar): 



=head2 repo_id (integer): 



=head2 set_name (varchar): 



=head2 set_spec (varchar): 



=head2 type (varchar): 







=head1 AUTHORS

Zbigniew Lukasiak with contibutions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



