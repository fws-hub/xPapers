package xPapers::Invite;
use base qw/xPapers::Object/;
use Text::Textile qw/textile/;

#__PACKAGE__->meta->table('invites');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
    table   => 'invites',

    columns => 
    [
        id        => { type => 'integer', not_null => 1 },
        gId       => { type => 'integer', default => '', not_null => 1 },
        uId       => { type => 'integer', default => '', not_null => 1 },
        status    => { type => 'varchar', default => 'no response', length => 16, not_null => 1 },
        key       => { type => 'varchar', default => '', length => 100, not_null => 1 },
        created   => { type => 'datetime', default => 'now' },
        updated   => { type => 'datetime' },
        rId => { type => 'integer' },
        rEmail => { type => 'varchar'},
    ],
    relationships => [
        sender => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
    ],

    primary_key_columns => [ 'id' ],
);

1;

#
package xPapers::IM;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Invite' }

__PACKAGE__->make_manager_methods('invites');

1;
__END__

=head1 NAME

xPapers::Invite

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: invites


=head1 FIELDS

=head2 created (datetime):

=head2 gId (integer):

=head2 id (integer):

=head2 key (varchar):

=head2 rEmail (varchar):

=head2 rId (integer):

=head2 status (varchar):

=head2 uId (integer):

=head2 updated (datetime):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



