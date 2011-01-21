package xPapers::Pages::Page;
use Data::Dumper;
use xPapers::Conf;
use base qw/xPapers::Object xPapers::Object::Diffable/;
use strict;

__PACKAGE__->meta->setup
(
  table   => 'pages',

  columns =>
  [
    id           => { type => 'serial', not_null => 1 },
    url          => { type => 'varchar', length => 255, not_null => 1 },
    title        => { type => 'varchar', length => 255 },
    author_id    => { type => 'integer' },
    accepted     => { type => 'integer' },
    deleted      => { type => 'integer', default => 0 },
  ],

  relationships =>
  [
    author => {
      type       => 'many to one',
      class      => 'xPapers::Pages::PageAuthor',
      column_map => { author_id => 'id' },
    },
  ],

  primary_key_columns => [ 'id' ],

);

__PACKAGE__->set_my_defaults();

sub diffable {
    return {
        url       => 1,
        title     => 1,
        author_id => 1,
        accepted  => 1,
        deleted   => 1,
    };
}

sub diffable_relationships {
    return {};
}

my %notUserFields = map {$_ => 1} qw/id/;

sub notUserFields {
    return \%notUserFields;
}

1;
__END__


=head1 NAME

xPapers::Pages::Page

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>, L<xPapers::Object::Diffable>

Table: pages


=head1 FIELDS

=head2 accepted (integer): 



=head2 author_id (integer): 



=head2 deleted (integer): 



=head2 id (serial): 



=head2 title (varchar): 



=head2 url (varchar): 




=head1 METHODS

=head2 diffable 



=head2 diffable_relationships 



=head2 notUserFields 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



