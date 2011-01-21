package xPapers::Citation;
use xPapers::Conf;
use base qw/xPapers::Object/;
use strict;

__PACKAGE__->meta->table('citations');
__PACKAGE__->meta->relationships(
    fromEntry => {
        type       => 'many to one',
        class      => 'xPapers::Entry',
        column_map => { fromeId => 'id' },
    },
    toEntry => {
        type       => 'many to one',
        class      => 'xPapers::Entry',
        column_map => { toeId => 'id' },
    },
);

__PACKAGE__->overflow_config;
__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;


package xPapers::CitationMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::Citation' }

__PACKAGE__->make_manager_methods('citations');

1;


__END__


=head1 NAME

xPapers::Citation

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: citations


=head1 FIELDS

=head2 authors (varchar): 



=head2 date (varchar): 



=head2 doi (varchar): 



=head2 fromeId (varchar): 



=head2 id (serial): 



=head2 issn (varchar): 



=head2 issue (varchar): 



=head2 pages (varchar): 



=head2 source (varchar): 



=head2 title (varchar): 



=head2 toeId (varchar): 



=head2 volume (integer): 



=head2 xml (text): 







=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



