use strict;
use warnings;

package xPapers::Note;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('notes');
__PACKAGE__->meta->relationships(
     entry => { type => 'many to one', class => 'xPapers::Entry', column_map => { eId => 'id' } }, 
#     user => { type => 'many to one', class=>'xPapers::User', column_map => { uId => 'id' } }, 
);
__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;

use xPapers::UserMng;

1;

__END__

=head1 NAME

xPapers::Note

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: notes


=head1 FIELDS

=head2 body (text):

=head2 created (datetime):

=head2 eId (varchar):

=head2 id (serial):

=head2 modified (timestamp):

=head2 uId (integer):




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



