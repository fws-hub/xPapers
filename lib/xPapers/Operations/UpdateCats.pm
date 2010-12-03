package xPapers::Operations::UpdateCats;
use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->setup
(
    table   => 'cat_edits',

    columns => 
    [
        id        => { type => 'integer', not_null => 1 },
        uId       => { type => 'integer' },
        cmds   => { type => 'text', length => 65535 },
        status   => { type => 'varchar', length => 255 },
        created   => { type => 'datetime' }
    ],
    relationships=> [
        user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
    ]
);
__PACKAGE__->set_my_defaults;

__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



