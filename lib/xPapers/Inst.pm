package xPapers::Inst;
use base qw/xPapers::Object/;
use strict;

#__PACKAGE__->meta->table('areas');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');


__PACKAGE__->meta->setup
(
    table   => 'insts',

    columns => 
    [
        id   => { type => 'serial', not_null => 1 },
        name => { type => 'varchar', length => 255 },
        domain => { type => 'varchar', length => 255 },
        country => { type => 'varchar', length=> 2},
        phdName => { type => 'varchar', default=>'PhD' }
    ],
    relationships=> [
        users => { 
            type => 'many to many', 
            map_class=>'xPapers::Relations::InstUser', 
            map_from=>'inst',
            map_to=>'user'
        },
    ],


    primary_key_columns => [ 'id' ],
);

sub proxies {
    my $me = shift;
    my $sth =  $me->dbh->prepare("select proxy,count(*) as nb from users join affils_m on uId=users.id join affils on aId=affils.id where iId=$me->{id} and length(proxy)>4 group by proxy order by nb desc");
    $sth->execute;
    my @list;
    while (my $h = $sth->fetchrow_hashref) {
        push @list,$h;
    }
    return @list;
}

sub redirectors {
    my $me = shift;
    my $sth =  $me->dbh->prepare("
        select 
        offCampusMethod,
        case offCampusMethod when 'proxy' then proxy when 'openurl' then resolver else null end as redirector,
        count(*) as nb 
        from users join affils_m on uId=users.id join affils on aId=affils.id 
        where iId=$me->{id}
        group by redirector order by nb desc
        "
    );
    # don't know why but I cannot use 'redirector' in the where clause (zby)

    $sth->execute;
    my @list;
    while (my $h = $sth->fetchrow_hashref) {
        next if length( $h->{redirector} ) <= 4;
        push @list,$h;
    }
    return @list;
}

__PACKAGE__->set_my_defaults;

package xPapers::I;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Inst' }

__PACKAGE__->make_manager_methods('insts');



1;

__END__

=head1 NAME

xPapers::Inst

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: insts


=head1 FIELDS

=head2 country (varchar):

=head2 domain (varchar):

=head2 id (serial):

=head2 name (varchar):

=head2 phdName (varchar):


=head1 METHODS

=head2 proxies 



=head2 redirectors 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



