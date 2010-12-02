
package xPapers::Relations::EntryListArea;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'areas_ml',
columns =>
    [
        aId => { type => 'integer', not_null => 1 },
        mId   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'aId', 'mId' ],

    foreign_keys => [
        list => { class => 'xPapers::EntryList', column_map => { mId => 'id' } },
        area => { class => 'xPapers::Area', column_map => { aId => 'id' } }
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




