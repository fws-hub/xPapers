
package xPapers::Relations::CatEntry;  
use base qw/xPapers::Object xPapers::Object::Diffable/;

__PACKAGE__->meta->default_load_speculative(0);
__PACKAGE__->meta->setup
(
table   => 'cats_me',
columns =>
    [
        id => {type => 'serial' },
        cId => { type => 'integer', not_null => 1 },
        eId   => { type => 'varchar', length=>32, not_null => 1 },
        rank => { type => 'integer', default=>0 },
        editor => { type => 'integer', default=> 0},
        setAside => { type => 'integer', default=> 0},
        created => { type => 'datetime'  }
    ],

    primary_key_columns   => [ 'id' ],
    unique_key => ['cId','eId'],

#    relationships => [
#        entry => { type => 'one to many', class=>'xPapers::Entry', column_map => {eId => 'id'}},
#        cat => { type => 'one to many', class=>'xPapers::Cat', column_map => {cId=>'id'}},
#    ],

    foreign_keys => [
        entry => { class => 'xPapers::Entry', column_map => { eId => 'id' } },
        cat => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);

sub diffable { return { cId=>1, eId=>1 } };
sub diffable_relationships { return { } };
sub toString {
    my $me= shift;
    return $me->entry->toString;
}

1;

package xPapers::Relations::CE;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Relations::CatEntry' }

__PACKAGE__->make_manager_methods('cats_me');



1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



