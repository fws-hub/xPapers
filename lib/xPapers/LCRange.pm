package xPapers::LCRange;
use base qw/xPapers::Object/;
use strict;

#__PACKAGE__->meta->table('lc_ranges');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
table   => 'lc_ranges',

columns => 
[
    id          => { type => 'integer', not_null => 1 },
    lc_class    => { type => 'varchar', default => '', length => 2, not_null => 1 },
    start       => { type => 'float', precision => 32 },
    end         => { type => 'float', precision => 32 },
    subrange    => { type => 'varchar', length => 10 },
    description => { type => 'varchar', length => 255 },
    exclude     => { type => 'integer', default => '0' },
    xwords      => { type => 'varchar', length => 255 },
    cId         => { type => 'integer' },

],

primary_key_columns => [ 'id' ],

);

__PACKAGE__->set_my_defaults;

use xPapers::LCRangeMng;

1;



__END__

=head1 NAME

xPapers::LCRange

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: lc_ranges


=head1 FIELDS

=head2 cId (integer): 



=head2 description (varchar): 



=head2 end (float): 



=head2 exclude (integer): 



=head2 id (integer): 



=head2 lc_class (varchar): 



=head2 start (float): 



=head2 subrange (varchar): 



=head2 xwords (varchar): 






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



