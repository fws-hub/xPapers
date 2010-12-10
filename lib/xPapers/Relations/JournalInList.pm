package xPapers::Relations::JournalInList;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'main_jlm',
columns =>
    [
        jlmId => { type => 'serial' },
        jId   => { type => 'integer', not_null => 1 },
        jlId => { type => 'integer', not_null=>1 },
    ],

primary_key_columns   => [ 'jlmId' ],

foreign_keys => [
    list => { class => 'xPapers::JournalList', column_map => { jlId => 'jlId' } },
    journal => { class => 'xPapers::Journal', column_map => { jId => 'id' } }
],
 
);

1
__END__

=head1 NAME

xPapers::Relations::JournalInList

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: main_jlm


=head1 FIELDS

=head2 jId (integer): 



=head2 jlId (integer): 



=head2 jlmId (serial): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



