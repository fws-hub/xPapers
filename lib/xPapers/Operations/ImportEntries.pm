package xPapers::Operations::ImportEntries;
use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->setup
(
    table   => 'batch',

    columns => 
    [
        id        => { type => 'integer', not_null => 1 },
        ticket => { type => 'varchar' },
        uId       => { type => 'integer' },
        cId       => { type => 'integer' },
#        addedCId       => { type => 'integer' },
#        foundCId       => { type => 'integer' },
#        categorizedCId       => { type => 'integer' },
        found  => { type => 'integer',default=>0 },
        notFound  => { type => 'integer',default=>0 },
        categorized  => { type => 'integer',default=>0 },
        inserted  => { type => 'integer',default=>0 },
        errors   => { type => 'text', length => 65535 },
        created   => { type => 'datetime' },
        completed   => { type => 'datetime' },
        checked   => { type => 'integer', default=>0 },
        ok    => { type => 'integer', default=> 1 },
        finished    => { type => 'integer', default=> 0 },
        createMissing    => { type => 'integer', default=> 0 },
        inputFile => { type=>'varchar', length=>255 },
        format => { type => 'varchar', length=>100 },
        msg => { type => 'varchar', length=>255 }
    ],
    relationships=> [
        user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
        cat => { type => 'one to one', class=>'xPapers::Cat', column_map => { cId => 'id' }}, 
#        newItems => { type => 'one to one', class=>'xPapers::Cat', column_map => { addedCId => 'id' }}, 
#        oldItems => { type => 'one to one', class=>'xPapers::Cat', column_map => { foundCId => 'id' }}, 
#        categorizedItems => { type => 'one to one', class=>'xPapers::Cat', column_map => { categorizedCId => 'id' }}, 

    ],

    primary_key_columns => [ 'id' ],
    unique_key => ['ticket']
);

__PACKAGE__->set_my_defaults;

1;

package xPapers::B;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Operations::ImportEntries' }

__PACKAGE__->make_manager_methods('batch');



1;
__END__


=head1 NAME

xPapers::Operations::ImportEntries

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: batch


=head1 FIELDS

=head2 cId (integer): 



=head2 categorized (integer): 



=head2 checked (integer): 



=head2 completed (datetime): 



=head2 createMissing (integer): 



=head2 created (datetime): 



=head2 errors (text): 



=head2 finished (integer): 



=head2 format (varchar): 



=head2 found (integer): 



=head2 id (integer): 



=head2 inputFile (varchar): 



=head2 inserted (integer): 



=head2 msg (varchar): 



=head2 notFound (integer): 



=head2 ok (integer): 



=head2 ticket (varchar): 



=head2 uId (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



