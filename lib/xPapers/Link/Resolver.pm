use strict;
use warnings;

package xPapers::Link::Resolver;

use xPapers::Conf;
use URI::OpenURL;
use xPapers::Inst;
use URI;

use base qw/xPapers::Object/;

__PACKAGE__->meta->table('resolvers');
__PACKAGE__->meta->relationships(
    inst => {
        type       => 'many to one',
        class      => 'xPapers::Inst',
        column_map => { iId => 'id' },
    },
);

__PACKAGE__->meta->auto_initialize;


sub link_for_entry {
    my( $self, $entry ) = @_;
    $self->link_for_entry_old( $entry );
}

#DB: this is actually fine in spite of the name
sub link_for_entry_old {
    my( $self, $entry ) = @_;
    my $uri = URI->new( $self->url );

    my %args;
    $args{id} = $entry->doi if defined $entry->doi && length $entry->doi;
    my ( $author ) = $entry->getAuthors;
    my @names = split ',\s*', $author;
    $args{aulast} = $names[0];
    $args{aufirst} = $names[1];
    $args{aufirst} =~ s/(\s+.*)//;
    $args{date} = $entry->date if $entry->date =~ /^\d+\s*$/;

    if( $entry->type eq 'book' ){
        $args{title} = $entry->title if $entry->title;
        $args{isbn} = $entry->isbn if $entry->isbn;
    }
    elsif ( $entry->type eq 'chapter' ){
        $args{atitle} = $entry->title if $entry->title;
        $args{title} = $entry->source if $entry->source;
        my ( $author ) = $entry->getEditors || $entry->getAuthors;
        my @names = split ',\s*', $author;
        $args{aulast} = $names[0];
        $args{aufirst} = $names[1];
        $args{aufirst} =~ s/(\s+.*)//;
    }
    else{    # not all entries have type
        $args{issue} = $entry->issue if defined $entry->issue;
        $args{volume} = $entry->volume if defined $entry->volume;
        $args{issn} = $entry->issn if $entry->issn;
        $args{atitle} = $entry->title if $entry->title;
        $args{title} = $entry->source if $entry->source;
    }
    $uri->query_form( %args );
    return $uri;
}



sub link_for_entry_new {
    my( $self, $entry ) = @_;
    my $uri = URI::OpenURL->new( $self->url );

    if( defined $entry->doi && length $entry->doi ){
        $uri->referent( id => $entry->doi );
    }
    else{
        $uri->referent();
    }

    my %args;
    my ( $author ) = $entry->getAuthors;
    my @names = split ',\s*', $author;
    $args{aulast} = $names[0];
    $args{aufirst} = $names[1];
    $args{aufirst} =~ s/(\s+.*)//;
    $args{date} = $entry->date if $entry->date =~ /^\d+\s*$/;


    if( $entry->type eq 'book' ){
        $args{btitle} = $entry->title if $entry->title;
        $args{isbn} = $entry->isbn if $entry->isbn;
        $uri->book( %args );
    }
    elsif( $entry->type eq 'article' ){
        $args{issue} = $entry->issue if defined $entry->issue;
        $args{volume} = $entry->volume if defined $entry->volume;
        $args{issn} = $entry->issn if $entry->issn;
        $args{atitle} = $entry->title if $entry->title;
        $args{jtitle} = $entry->source if $entry->source;
        $uri->journal( %args );
    }
    return $uri;
}


__PACKAGE__->set_my_defaults;

package xPapers::Link::ResolverMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Link::Resolver' }

__PACKAGE__->make_manager_methods('resolvers');

1;

__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



