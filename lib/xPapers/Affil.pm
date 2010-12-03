package xPapers::Affil;
use base qw/xPapers::Object/;
use xPapers::Conf;
use strict;

#__PACKAGE__->meta->table('areas');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');


__PACKAGE__->meta->setup
(
    table   => 'affils',

    columns => 
    [
        id => { type => 'integer', not_null => 1},
        iId   => { type => 'integer', not_null => 1 },
        role => { type => 'varchar', length => 64 },
        rank => { type => 'integer', default => 1},
        year => { type => 'integer' },
        discipline => { type => 'varchar', default=>$SUBJECT },
        inst_manual=>{ type=>'varchar', length => 100 }
    ],
    relationships => [
        inst => { type => 'many to one', class=>'xPapers::Inst', column_map => { iId => 'id' }}, 
    ],

    primary_key_columns => [ 'id' ],
    unique_key => [ 'iId','role','discipline','rank','year','inst_manual' ]
);

__PACKAGE__->set_my_defaults;

sub instName {
    my $me = shift;
    return $me->iId ? $me->inst->name : $me->inst_manual;
}

package xPapers::A;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Affil' }

__PACKAGE__->make_manager_methods('affils');

1;

__END__

=head1 NAME

xPapers::Affil

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: affils


=head1 FIELDS

=head2 discipline (varchar):

=head2 iId (integer):

=head2 id (integer):

=head2 inst_manual (varchar):

=head2 rank (integer):

=head2 role (varchar):

=head2 year (integer):


=head1 METHODS

=head2 instName 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



