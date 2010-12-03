package xPapers::Editorship;
use base 'xPapers::Object';
use Rose::DB::Object::Helpers 'as_tree','clone','new_from_deflated_tree';

__PACKAGE__->meta->default_load_speculative(0);
__PACKAGE__->meta->setup
(
table   => 'cats_eterms',
columns =>
    [
        id => { type => 'serial' },
        cId => { type => 'integer', not_null => 1 },
        uId   => { type => 'integer', not_null => 1 },
        created => { type => 'datetime' },
        start => { type => 'datetime' },
        end => { type => 'datetime' },
        renew => { type=>'integer', default=>1 },
        recursive => { type => 'integer', default => 0},
        status => { type => 'integer' , default=> 0},
            # status:
            # 0: new application
            # 10: accepted
            # -10: refused
            # -20: user cancelled
            # 20: user confirmed
        confirmBy => { type => 'datetime' },
        confirmWarnings => { type => 'integer', default => 100 },
        comment   => { type => 'text' },
        current => {type => 'integer', default => 0},
        IO => { type => 'integer' , default=> 0},
        GIO => { type => 'integer' , default=> 0},
        imports => { type => 'integer' , default=> 0},
        checked => { type => 'integer' , default=> 0},
        excluded => { type => 'integer' , default=> 0},
        auto => { type => 'integer', default => 0 },
    ],

    primary_key_columns => ['id'],
    unique_key => ['cId','uId'],

#    relationships => [
#        entry => { type => 'one to many', class=>'xPapers::Entry', column_map => {eId => 'id'}},
#        cat => { type => 'one to many', class=>'xPapers::Cat', column_map => {cId=>'id'}},
#    ],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { uId => 'id' } },
        cat => { class => 'xPapers::Cat', column_map => { cId => 'id' } }
    ],
 
);

__PACKAGE__->set_my_defaults;

1;


package xPapers::ES;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Editorship' }

__PACKAGE__->make_manager_methods('cats_eterms');

1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



