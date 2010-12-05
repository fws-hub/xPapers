use strict;
use warnings;
package xPapers::Harvest::Feeds;

use LWP::UserAgent;
use XML::LibXML;
use XML::RSS::LibXML;
#use XML::RSS::FromAtom; this pkg doesn't work
#use XML::Atom::Syndication;
#use XML::RSS;
use URI;
use File::Slurp 'slurp';
use DateTime;
use DateTime::Format::MySQL;
use Try::Tiny;

use xPapers::Link::HarvestJournal;
use xPapers::Entry;
use xPapers::Conf '$HARVESTER_USER','%PATHS';
use xPapers::Util qw/cleanAll parseAuthors rmTags/;
use Data::Dumper;

use Moose;

use xPapers::Harvest::InputFeed;
use xPapers::Harvest::PluginMng;

has feed => ( is => 'ro', isa => 'xPapers::Harvest::InputFeed', required => 1 );

has startOfHarvesting => ( is => 'ro', isa => 'DateTime', default => sub { DateTime->now() } );
has rss => ( is => 'ro', lazy_build => 1 );
has pluginMng => ( is => 'ro', lazy_build => 1 );

sub _build_pluginMng {
    my $self = shift;
    my $mng = xPapers::Harvest::PluginMng->new;
    $mng->init;
    return $mng;
}

sub _build_rss {
    my $self = shift;
    my $rss = XML::RSS::LibXML->new;
    my $content = $self->content;

    if( $content ){
        
        # clean up leading whitespace
        $content =~ s/^[\n\r\s]+//sm;

        # check for missing default namespace 
        $content =~ m/<rdf:RDF(.*?)>/s;
        my $nss = $1;
        if( $nss !~ /xmlns="/ ){
            $content =~ s{<rdf:RDF}{<rdf:RDF xmlns="http://purl.org/rss/1.0/"};
        }

        try{
            $rss->parse( $content );
        }
        catch{
            warn "Bad RSS: $_";
            $self->feed->lastStatus( 'Bad RSS' );
        }
    }
    return $rss;
}

has since => ( is => 'rw', lazy_build => 1 );
sub _build_since {
    my $self = shift;
    return DateTime->now->subtract( hours => $self->feed->useSince  ) if $self->feed->useSince;
    return;
}

has url => ( is => 'ro', lazy_build => 1,);
sub _build_url {
    my $self = shift;
    my $url = URI->new( $self->feed->url );
    my %params;
    $params{pass} = $self->feed->pass if $self->feed->pass;
    $params{since} = DateTime::Format::MySQL->format_datetime( $self->since ) if defined $self->since;
    $url->query_form( %params );
    return $url;
}

has user_agent => ( is => 'ro', isa => 'LWP::UserAgent', default => sub { 
    LWP::UserAgent->new(
        agent => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30618; .NET4.0C)',
        cookie_jar => {}
    )
} );

has content => ( is => 'ro', lazy_build => 1 );
sub _build_content {
    my $self = shift;
    # warn "Getting: " .$self->url;
    my $response = $self->user_agent->get( $self->url );
    my $feed = $self->feed;
    $feed->lastStatus( $response->code );
    if( $response->is_success ){
        return $response->decoded_content;
    } else {
        warn "HTTP request failed with code " . $response->code;
       $self->feed->lastStatus( 'Bad HTTP request: ' . $response->code );

    }
    return;
}

sub harvest {
    my $self = shift;
    my @entries;
    my $sequence = 0;
    if( $self->rss && ref $self->rss->{items} eq 'ARRAY' ){
        foreach my $item (@{ $self->rss->{items} }) {
            my $entry = $self->entry_from_item( $item, $sequence++, $self->rss->channel );
            push @entries, $entry if $entry;
        }
    } else {
        die "Error parsing RSS for feed #" . $self->feed->id;
    }
    my $harvested = $sequence . ', ' .  $self->feed->harvested;
    $self->feed->harvested( $harvested );
    $self->feed->harvested_at( DateTime->now );
    return @entries;
}


# DEPRECATED
sub entries_from_rss {
    my ( $self, $content ) = @_;
    $self->rss->parse( $content );
    my $sequence = 0;
    my @entries;
    foreach my $item (@{ $self->rss->{items} }) {
        print "\n" x 2;
        print "*" x 40;
        print "\n";
        my $entry = $self->entry_from_item( $item, $sequence++ );
        if ($entry) {
            push @entries, $entry;
            #print Dumper( $entry->as_tree ) if $entry;
        }
    }
    return @entries;
}

sub entry_from_item {
    my( $self, $item, $sequence ) = @_;

    my %prism;
    if( $self->rss()->{channel}{prism} ){
        %prism = %{ $self->rss()->{channel}{prism} };
    }
    if( $item->{prism} ){
        %prism = ( %prism, %{ $item->{prism} } );
    }

    my $entry = xPapers::Entry->new();
    $entry->title( $item->{title} );
    #warn $entry->title;
    #print Dumper(\%prism);
    $entry->type( 'article' );
    if( $prism{publicationName} ){
        $entry->source( $prism{publicationName} );
    } elsif ( $self->feed->type eq 'journal' and $self->rss->{channel}{title}) {
        $entry->source($self->rss->{channel}{title});
    } elsif ($self->feed->type eq 'journal') { 
        my $source = $item->{dc}{source}; 
        if( $source ){
            $source =~ s/, Vol.*//;
            $entry->source( $source );
        }
    }
    if (ref($item->{dc}) and $item->{dc}{creator}) {
        my @authors = _to_list( $item->{dc}{creator} );
        if ($#authors==0 and $authors[0] =~ /,.+,|;/) {
            $entry->addAuthors(parseAuthors($authors[0]));
        } else {
            $entry->addAuthors( parseAuthors(join(";", @authors)) );
        }
    } elsif ($item->{authors}) {
        $entry->addAuthors(parseAuthors($item->{authors}));
    }


    #return unless $entry->firstAuthor =~ /Douven/;

    if( defined $prism{startingPage} ){
        my $end = $prism{endingPage} || '';
        $entry->pages( $prism{startingPage} . '-' . $end );
    }
    if( defined $prism{volume} ){
        $entry->volume( $prism{volume} );
    } 
    my $default_date = $self->feed->type eq 'journal' ? 'forthcoming' : 'unknown';
    $entry->pub_type( ($entry->source ||  $self->feed->type eq 'journal') ? 'journal' : 'unknown' );
    if(my $date = $item->{dcterms}{created} || $item->{dc}{date} || $self->rss->channel->{dc}{date} || $self->rss->channel->{copyright} ){
        if ($date =~ /(\d{4})/) {
            $entry->date( $1 );
        } else {
            $entry->date( $default_date  );
        }
    }
    else{
        $entry->date( $default_date );
    }

    if( defined $prism{number} ){
        $entry->issue( $prism{number} );
    } 
    if (defined $prism{doi} ){
        $entry->doi( $prism{doi} );
    } 
    # try to extract a DOI. we don't know how they are going to be encoded.
    # yes, not very elegant..
    elsif ($item->{dc}->{identifier}) {
        my $text = Dumper([_to_list($item->{dc}->{identifier})]);
        if ($text =~ /doi(?::|\/)([\w\/\.]+)/i) {
            $entry->doi($1);
        }
    }
    $entry->db_src( $self->feed->db_src );

    # A PP extension..
    if ( $item->{'pp'} ) {
        my $i = 0;
        while ($i < 100 and $item->{'pp'}->{"link$i"}) {
            $entry->addLink($item->{'pp'}->{"link$i"});
            $i++;
        }
    }

   if( $item->{'link'} ){
        $entry->addLink( $item->{'link'} );
    }
    else{
        warn 'no link';
        warn Dumper( $item );
    }
    $entry->pubHarvest( 1 );
    $entry->author_abstract( $item->{description} );

    #return undef unless $entry->toString =~ /Zahavi/;

    $self->pluginMng->applyAll($entry, $self->feed, { rss => $self->rss });

    # Only now we remove the tags, because some plugins rely on html formatting.
    $entry->{author_abstract} =~ s/\s+/ /g;
    $entry->author_abstract( rmTags($entry->author_abstract) );

    { 
        no warnings; 
        $entry->source_id( join '/', ( 'feed:/', $self->feed->id, $entry->doi || $item->{'link'} ) );
    }

    cleanAll( $entry );
    #print "pub:$entry->{pub_type}\n";
    #warn "volume:$entry->{volume}\n";
    #warn "date:$entry->{date}\n";
    die "No source for feed " . $self->feed->name unless $entry->{source} or $self->feed->type eq 'archive';
    return $entry;
}

sub _to_list {
    my $x = shift;
    return @$x if ref($x) eq 'ARRAY';
    return $x;
}

no Moose;
1;

__END__

=head1 NAME

xPapers::Harvest::Feeds

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<Moose::Object>



=head1 ATTRIBUTES

=head2 content 



=head2 feed 



=head2 pluginMng 



=head2 rss 



=head2 since 



=head2 startOfHarvesting 



=head2 url 



=head2 user_agent 



=head1 METHODS

=head2 entries_from_rss 



=head2 entry_from_item 



=head2 harvest 




=head1 DIAGNOSTICS

=head1 AUTHORS

Zbigniew Lukasiak with contributions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



