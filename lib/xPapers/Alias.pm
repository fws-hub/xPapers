package xPapers::Alias;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('aliases');
__PACKAGE__->meta->relationships(
    user => {
        type => 'many to one',
        class=>'xPapers::User',
        column_map=> { uId => 'id' }
    },
);

__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


__END__

=head1 NAME

xPapers::Alias

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: aliases


=head1 FIELDS

=head2 firstname (varchar): 



=head2 id (serial): 



=head2 lastname (varchar): 



=head2 name (varchar): 



=head2 uId (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



