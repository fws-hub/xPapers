package xPapers::JournalList;
use xPapers::Conf;
use xPapers::Util 'quote';
use base qw/xPapers::Object/;
use strict;
my $main_table = 'main';

__PACKAGE__->meta->table('main_jlists');
__PACKAGE__->meta->relationships(
      user => {
        type => 'many to one',
        class=>'xPapers::User',
        column_map=> { jlOwner => 'id' }
      },
      journals => {
        type => 'many to many', 
        map_class=>'xPapers::Relations::JournalInList', 
        map_from=>'list',
        map_to=>'journal',
        methods=>['add_on_save','find','count','get_set_on_save']
      },
);
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

sub get {
    my ($me,$id) = @_;
    $me->new(jlId=>$id)->load_speculative;
}

sub reset {
    my ($me) = @_;
    $me->dbh->do("delete from ${main_table}_jlm where jlId='".quote($me->jlId)."'");
}

sub add {
    my ($me,$j) = @_;
    $me->dbh->do("insert into ${main_table}_jlm set jlId='".quote($me->jlId)."', jId='$j'"); 
}

use xPapers::JournalListMng;

1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



