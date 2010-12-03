package xPapers::Journal;
use base qw/xPapers::Object::Cached/;
use strict;
use xPapers::Conf qw/$POP_JOURNALS/;
use xPapers::DB;

#__PACKAGE__->meta->table('main_journals');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
    table   => 'main_journals',

    columns => 
    [
	# most fields are updated by a maintenance script

	# this auto-increments
        id           => { type => 'serial', not_null => 1 },
	# the journal name. that should match the result of xPapers::Util::cleanJournal()
        name         => { type => 'varchar', length => 255, not_null => 1 },
	# should we let users browse that journal? sometimes we want to disable this.
        browsable    => { type => 'integer', default => 1 },
	# this store the latest volume in a human-readable form
        maxVol       => { type => 'varchar', length => 255 },
	# this stores the number of entries for this journal
        nb           => { type => 'integer' },
	# same as maxVol, but min
        minVol       => { type => 'varchar', length => 255 },
	# number of entries for this journal obtained through direct harvesting (with db_src=direct) 
        nbHarvest    => { type => 'integer' },
	# total number of volumes
        nbVol        => { type => 'integer' },
        latestVolume => { type => 'integer' },
	# this keeps track of whether we should separate the issues of this journal when browsing. this depends on how many issues there are per volumes and how big they are.
        showIssues   => { type => 'integer', default => '0' },
	# this allows us to store OA archives as if they were journals. a hack.
        archive      => { type => 'integer', default => '0' },
	# associated category id if any. this is used by the autocat script.
        cId          => { type => 'integer' },
        listCount    => { type => 'integer' },
        hide         => { type => 'integer' }
    ],

    primary_key_columns => [ 'name' ],
    unique_key=> ['id']
);
__PACKAGE__->set_my_defaults;

sub popular {
    my $me = shift;
    my $r = xPapers::DB->exec("select count(*) as nb from main_jlm where (main_jlm.jlId = 1 and main_jlm.jId = $me->{id})");
    return $r->fetchrow_hashref->{nb};
}

sub getByName {
    my $pkg = shift;
    return $pkg->new(name=>shift())->load_speculative;
}

use xPapers::JournalMng;

1;


__END__

=head1 NAME

xPapers::Journal

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>

Table: main_journals


=head1 FIELDS

=head2 archive (integer):

=head2 browsable (integer):

=head2 cId (integer):

=head2 hide (integer):

=head2 id (serial):

=head2 latestVolume (integer):

=head2 listCount (integer):

=head2 maxVol (varchar):

=head2 minVol (varchar):

=head2 name (varchar):

=head2 nb (integer):

=head2 nbHarvest (integer):

=head2 nbVol (integer):

=head2 showIssues (integer):


=head1 METHODS

=head2 getByName 



=head2 popular 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



