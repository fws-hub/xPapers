use strict;
use warnings;

use XML::LibXML;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Archive::Zip::MemberRead;
use File::Find::Rule;
use File::MimeInfo::Simple;
use xPapers::FTPUser;
use File::Slurp 'slurp';

use xPapers::Parse::NLM;

my $parser = xPapers::Parse::NLM->new();

my $it = xPapers::FTPUser::Manager->get_main_iterator();

while( my $ftpu = $it->next ){
warn $ftpu->homedir;
    my $mtime = $ftpu->last_scan_time || 0;
    my @files = File::Find::Rule
        ->file()
        ->mtime( ">$mtime" )
        ->in( $ftpu->homedir );
    for my $file ( @files ){
        my $mimetype = mimetype( $file );
        warn "file: $file, mimetype: $mimetype";
        if( $mimetype eq 'application/zip' ){
            my $zip = Archive::Zip->new( $file ) or die $!;
            my $entry;
            for my $member ( $zip->members ){
                my $contents = $member->contents;
                my $entry;
                eval { $entry = $parser->entryFromXml( $contents, { feed_id => $ftpu->userid } ) };
                #print $entry->toString . "\n" if $entry;
                if( $@ ){
                    warn $@;
                    next;
                }
            }
        }
        elsif( $mimetype eq 'application/xml' ){
            my $contents = slurp( $file );
            eval { 
                my $entry = $parser->entryFromXml( $contents, { feed_id => $ftpu->userid } );
#                warn Dumper( $entry ); use Data::Dumper;
            };
            if( $@ ){
                warn $@;
                next;
            }
        }
    }
    $ftpu->last_scan_time( time );
    $ftpu->save;
}


1;
