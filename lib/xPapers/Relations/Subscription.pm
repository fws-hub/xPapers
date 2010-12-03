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



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



