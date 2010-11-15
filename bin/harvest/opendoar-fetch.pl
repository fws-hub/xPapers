use strict;
use warnings;

use xPapers::OAI::Repository;
use XML::LibXML;

my $parser = XML::LibXML->new();
my $xml = $parser->load_xml( location => 'http://opendoar.org/api13.php?la=en&show=max' );

for my $r_node ( $xml->findnodes('/OpenDOAR/repositories/repository') ){
    my $handler = $r_node->findnodes('rOaiBaseUrl')->string_value;
    next if ! length $handler;
    my $rid = $r_node->findnodes('@rID')->string_value;
    my $records = xPapers::OAI::Repository::Manager->get_objects( query => [ rid => $rid ] );
    my $record;
    if ( ! scalar @$records ){
        $record = xPapers::OAI::Repository->new;
    }
    else{
        next;# actually, we don't want to overwrite potentially user-corrected data. one day we could merge opendoar updates and our diffs.
        $record = $records->[0];
    }
    $record->rid( $rid );
    $record->name( $r_node->findnodes('rName')->string_value );
    $record->handler( $handler );
    my @langs;
    for my $lang ( $r_node->findnodes('languages/language/lIsoCode')->get_nodelist ){
        push @langs, $lang->string_value;
    }
    $record->languages( \@langs );
    if ( $r_node->findnodes('repositoryType')->string_value eq 'Governmental' ||
         ($r_node->findnodes('repositoryType')->string_value eq 'Disciplinary' &&
        ! grep { $_->string_value =~ /Multidisciplinary|Arts and Humanities General|Philosophy/ } $r_node->findnodes('classes/class/clTitle')
         )
    ){
        $record->deleted(1);
    }
    $record->save;
}

