package xPapers::Pages::PageAuthor;
use Data::Dumper;
use xPapers::Conf;
use base qw/xPapers::Object xPapers::Object::Diffable/;
use strict;

__PACKAGE__->meta->setup
(
  table   => 'pageauthors',

  columns =>
  [
    id                  => { type => 'serial', not_null => 1 },
    opp_id              => { type => 'integer' },
    lastname            => { type => 'varchar', length => 255 },
    firstname           => { type => 'varchar', length => 255 },
    user_id             => { type => 'integer' },
    people_cat          => { type => 'varchar', length => 128 },
    people_descr        => { type => 'text' },
    pro                 => { type => 'integer', default => 0 },
    accepted            => { type => 'integer' },
    deleted             => { type => 'integer', default => 0 },
    created             => { type => 'datetime' }
  ],

  relationships =>
  [
    user => {
      type       => 'one to one',
      class      => 'xPapers::User',
      column_map => { user_id => 'id' },
    },
    areas => {
      type       => 'many to many',
      map_class  => 'xPapers::Relations::PageAuthorArea',
      map_from   => 'pageauthor',
      map_to     => 'area',
    },
    pages => {
      type       => 'one to many',
      class      => 'xPapers::Pages::Page',
      column_map => { id => 'author_id' },
    },
  ],

  primary_key_columns => [ 'id' ],

);

__PACKAGE__->set_my_defaults();

sub diffable {
    return {
        lastname     => 1,
        firstname    => 1,
        user_id      => 1,
        pro          => 1,
        people_cat   => 1,
        people_descr => 1,
        accepted     => 1,
        deleted      => 1,
        opp_id       => 1,
    };
}

sub diffable_relationships {
    return {
	areas     => 1,
    };
}

my %notUserFields = map {$_ => 1} qw/id/;

sub notUserFields {
    return \%notUserFields;
}

sub checkboxes {
    return { pro => 1 }
}

sub fullname {
    return $_[0]->firstname . " " . $_[0]->lastname;
}

sub fullname_r {
    return $_[0]->lastname . ", " . $_[0]->firstname;
}

sub toString {
    return $_[0]->fullname;
}

1;
__END__

=head1 NAME

xPapers::Pages::PageAuthor

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>, L<xPapers::Object::Diffable>

Table: pageauthors


=head1 FIELDS

=head2 accepted (integer): 



=head2 created (datetime): 



=head2 deleted (integer): 



=head2 firstname (varchar): 



=head2 id (serial): 



=head2 lastname (varchar): 



=head2 opp_id (integer): 



=head2 people_cat (varchar): 



=head2 people_descr (text): 



=head2 pro (integer): 



=head2 user_id (integer): 




=head1 METHODS

=head2 checkboxes 



=head2 diffable 



=head2 diffable_relationships 



=head2 fullname 



=head2 fullname_r 



=head2 notUserFields 



=head2 toString 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



