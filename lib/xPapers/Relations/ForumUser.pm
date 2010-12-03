
package xPapers::Relations::ForumUser;  
use base 'xPapers::Object';

__PACKAGE__->meta->setup
(
table   => 'forums_m',
columns =>
    [
        fId => { type => 'integer', not_null => 1 },
        uId => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'fId','uId' ],

    foreign_keys => [
        forum => { class => 'xPapers::Forum', column_map => { fId => 'id' } },
        user => { class => 'xPapers::User', column_map => { uId => 'id' } }
    ],
 
);

__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



