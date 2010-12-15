package xPapers::Relations::Subscription;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'posts_sub',
columns =>
    [
        user_id => { type => 'integer', not_null => 1 },
        thread_id => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'user_id', 'thread_id' ],

    foreign_keys => [
        user => { class => 'xPapers::User', column_map => { user_id => 'id' } },
        thread => { class => 'xPapers::Thread', column_map => { thread_id => 'id' } }
    ],
 
);


__END__


=head1 NAME

xPapers::Relations::Subscription

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: posts_sub


=head1 FIELDS

=head2 thread_id (integer): 



=head2 user_id (integer): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



