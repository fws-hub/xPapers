package xPapers::Link::OPPTools;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( sendDiff );

use strict;
use warnings;

use LWP::Simple;
use URI;

use xPapers::Conf;

sub sendDiff {
    my $diff = shift;
    if( $diff->class eq 'xPapers::Pages::Page' ){
        return sendPageDiff( $diff );
    }
    if( $diff->class eq 'xPapers::Pages::PageAuthor' ){
        return sendAuthorDiff( $diff );
    }
}


sub sendPageDiff {
    my $diff = shift;
    $diff->load;
    my $page = $diff->object;
    return "No page at " . $diff->id . "\n" if !$page;
    my $address = URI->new( $OPP_ADDRESS );
    my $action;
#    if( $diff->type eq 'update' or $diff->type eq 'restore' ){
#        $action = 'add';
#    }
#    elsif( $diff->type eq 'delete' ){
#        $action = 'delete'
#    }
    if( $page->deleted ){
        $action = 'delete';
    }
    else{
        $action = 'add';
    }
    $address->query_form( action => $action, id => $page->url, crawl => $OPP_CRAWL_DEPTH, author=> $page->author->fullname );
    warn $address;
    my $json = get( $address );
    return $json;
}

sub sendAuthorDiff {
    my $diff = shift;
    $diff->load;
    my $author = $diff->object;
    return "No author at " . $diff->id . "\n" if !$author;
    my $address = URI->new( $OPP_ADDRESS );
    my $name = $author->fullname;;
    $name = '' if $author->deleted;
#    if( $diff->type eq 'update' or $diff->type eq 'restore' ){
#        $name = $author->fullname;
#    }
#    elsif( $diff->type eq 'delete' ){
#        $name = '';
#    }
    my $out;
    for my $page ( $author->pages ){
        $address->query_form( action => 'modify', id => $page->url, author => $name );
        warn $address;
        $out .= get( $address );
    }
    return $out;
}


__END__


=head1 NAME

xPapers::Link::OPPTools




=head1 SUBROUTINES

=head2 sendAuthorDiff 



=head2 sendDiff 



=head2 sendPageDiff 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



