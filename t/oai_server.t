use strict;
use warnings;
use Test::More;

use File::Slurp 'slurp';
use String::Random qw(random_regex random_string);
use Storable qw/freeze thaw/;

use xPapers::OAI::Server;
use xPapers::Entry;

$xPapers::OAI::Server::LIMIT = 9;

my $gen = XML::Generator->new( pretty => 2, escape => 'always' );

ok( xPapers::OAI::Server::rights( $gen ), 'rights tag generated' );

like( xPapers::OAI::Server::response( 
        { 
            verb => 'GetRecord',
            identifier => $xPapers::OAI::Server::ID_PREFIX . 'KAWAAA',
            metadataPrefix => 'oai_dc' 
        }
    ),
    qr/<dc:description>My central thesis/,
    'Record public'
);

like( xPapers::OAI::Server::response( 
        { 
            verb => 'GetRecord',
            identifier => $xPapers::OAI::Server::ID_PREFIX . 'AALTEO',
            metadataPrefix => 'oai_dc' 
        }
    ),
    qr/idDoesNotExist/,
    'No public'
);

like( 
    xPapers::OAI::Server::response( 
    { 
        verb => 'GetRecord',
        identifier => $xPapers::OAI::Server::ID_PREFIX . 'AALTEO',
        metadataPrefix => 'aaa' 
    }),
    qr/cannotDisseminateFormat/,
    'Cannot Disseminate Format Error'
);

like( 
    xPapers::OAI::Server::response( 
        {
            verb => 'GetRecord', 
            identifier => '000092', 
            metadataPrefix => 'oai_dc' 
        },
    ), 
    qr/idDoesNotExist/,
    'No Entry error'
);


ok xPapers::OAI::Server::response( { verb => 'Identify' } );

ok xPapers::OAI::Server::response( { verb => 'ListMetadataFormats' } );

my $new_token = xPapers::OAI::Server::encode_args( { offset => $xPapers::OAI::Server::LIMIT, from => '2000-01-01' } );
my $token     = xPapers::OAI::Server::encode_args( { offset => 1, from => '2000-01-01' } );
like( xPapers::OAI::Server::response( { 
            verb => 'ListIdentifiers', 
            resumptionToken => $token,
        } 
    ),
    qr/<request.*<ListIdentifiers>.*resumptionToken>\Q$new_token\E</s,
    'ListIdentifiers'
);

like( xPapers::OAI::Server::response( {
            verb => 'ListRecords',
            resumptionToken => $token,
        }
    ),
    qr/<ListRecords>/,
    'ListRecords'
);

like( xPapers::OAI::Server::response( {
            verb => 'ListRecords',
            resumptionToken => 'aaa',
        }
    ),
    qr/<error code="badResumptionToken"/,
    'badResumptionToken'
);

like( xPapers::OAI::Server::response( {
            verb => 'ListRecords',
            from => '2100-01-01'
        }
    ),
    qr/<error code="noRecordsMatch"/,
    'noRecordsMatch'
);

like( xPapers::OAI::Server::response( {
            verb => 'ListRecords',
            until => '1990-01-01'
        }
    ),
    qr/<error code="noRecordsMatch"/,
    'noRecordsMatch'
);

$new_token = xPapers::OAI::Server::encode_args( { offset => $xPapers::OAI::Server::LIMIT - 1, set => 'test' } );
like( xPapers::OAI::Server::response( {
            verb => 'ListRecords',
            set => 'test',
        }
    ),
    qr/<ListRecords>.*<resumptionToken>$new_token</s,
    'ListRecords'
);

# my $gen = XML::Generator->new( pretty => 2, escape => 'always' );
# my $entry = xPapers::EntryMng->get_objects_iterator()->next;
# $entry->title( '<>' );
# like( xPapers::OAI::Server::entry_to_xml( $gen, $entry ), qr{<dc:title>&lt;&gt;</dc:title>}, 'Escapes' );

done_testing;

