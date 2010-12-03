package xPapers::Alias;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('aliases');
__PACKAGE__->meta->relationships(
    user => {
        type => 'many to one',
        class=>'xPapers::User',
        column_map=> { uId => 'id' }
    },
);

__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;


__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



