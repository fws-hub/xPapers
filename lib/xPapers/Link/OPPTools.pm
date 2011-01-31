package xPapers::Link::OPPTools;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( sendDiff );

use strict;
use warnings;

use LWP::Simple;
use URI;
use JSON::XS 'decode_json';

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
    return {status=>0,msg=>"No page at " . $diff->id} if !$page;
    my $address = URI->new( $OPP_ADDRESS || 'http://localhost/cgi/opp/update.pl' );
    my $action;
#    if( $diff->type eq 'update' or $diff->type eq 'restore' ){
#        $action = 'add';
#    }
#    elsif( $diff->type eq 'delete' ){
#        $action = 'delete'
#    }
    my $query = {
     crawl => $OPP_CRAWL_DEPTH, 
     author=> $page->author->fullname
    };

    if( $page->deleted ){
        $query->{action} = 'delete';
        $query->{id} = $page->url;
    } elsif( $diff->type eq 'add' or !$diff->{url}->{before} ) {
        $query->{action} = 'add';
        $query->{id} = $page->url;
    }
    else{
        $query->{action} = 'modify';
        $query->{url} = $page->url;
        $query->{id} = $diff->{diff}->{url}->{before};
    }
    #print Dumper($query); use Data::Dumper;
    $address->query_form( %$query );
    return decode_json get( $address );
}

sub sendAuthorDiff {
    my $diff = shift;
    $diff->load;

    return {status=>1,msg=>"trivially satisfied (intercepted by xPapers::Link::OPPTools)"} if 
        $diff->type eq 'add' or !($diff->type eq 'delete' or $diff->{diff}->{firstname} or $diff->{diff}->{lastname}); # we don't need to do those.

    my $author = $diff->object;
    return {status=>0,msg=>"No author at " . $diff->id} if !$author;

    my $address = URI->new( $OPP_ADDRESS || 'http://localhost/cgi/opp/update.pl' );
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
        next unless $page->url;
        $address->query_form( action => $diff->type eq 'update' ? 'modify' : 'delete', id => $page->url, author => $name );
        warn $address;
        $out = decode_json get( $address );
        return $out unless $out->{status};
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



