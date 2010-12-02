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
__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




