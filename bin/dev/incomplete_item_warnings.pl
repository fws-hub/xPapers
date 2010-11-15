use strict;

use File::Slurp 'slurp';

use xPapers::DB;
use xPapers::CatMng;
use xPapers::Editorship;
use xPapers::User;
use xPapers::Conf;

my $DEBUG = 1;
my $test = $ARGV[0] ? " and userworks.uId=$ARGV[0] " : "";

my $db = xPapers::DB->new;
my $dbh = $db->dbh;
my $sth = $dbh->prepare( 
    "select main.id, title, author_abstract, pub_type, catCount, online, draft, uId 
    from main 
    join userworks on main.id = eId
    join users on userworks.uId=users.id
     where ( deleted = 0 or deleted is null ) and 
     ( pub_type='unknown' or 
     pub_type = 'manuscript' and ( not draft or draft is null ) or
     not catCount or catCount is null or
     length( author_abstract ) < 40 or author_abstract is null or
     not online or online is null) and
     ( users.confirmed )
     $test
    "
);
$sth->execute;
my %list;
while( my $entry = $sth->fetchrow_hashref ){
    push @{ $list{$entry->{uId}} }, $entry;
}

for my $uId ( keys %list ){
    my $body = "[HELLO]Some of your papers on $DEFAULT_SITE->{niceName} appear to have incomplete records. You might want to complete their records, as this will make it easier for others to find your work.\n"; 
    my ($major, $other) = generateMessages( $list{$uId} );
    if( %$major ){
        $body .= "\nRecords with major defects:\n";
        for my $entry ( @{ $list{$uId} } ){
            next if ! $major->{  $entry->{id} };
            $body .= qq|* "$entry->{title}" (["fix it":$DEFAULT_SITE->{server}/rec/$entry->{id}], ["not mine":$DEFAULT_SITE->{server}/not_mine.pl])\n|;
            $body .= join '', @{ $entry->{messages} };
        }
    }
    if( %$other){
        $body .= "\nOther records with defects:\n";
        for my $entry ( @{ $list{$uId} } ){
            next if $major->{  $entry->{id} };
            $body .= qq|* "$entry->{title}" (["fix it":$DEFAULT_SITE->{server}/rec/$entry->{id}], ["not mine":$DEFAULT_SITE->{server}/not_mine.pl])\n|;
            $body .= join '', @{ $entry->{messages} };
        }
    }
    my $email = xPapers::Mail::Message->new;
    $email->uId($uId);
    $email->brief("Some of your papers appear to have incomplete records");
    $email->content( $body );
    #    $email->save;

    print "$body\n\n\n";
}

sub generateMessages {
    my $entries = shift;
    my %major;
    my %other;

    for my $entry (@$entries) {
        $entry->{messages} = [];
        if( !$entry->{catCount} ){
            push @{ $entry->{messages} }, "** This paper is not in any category. This will make it very hard to find.\n";
            $major{$entry->{id}} = 1;
        }
        if( $entry->{pub_type} eq 'unknown' ){
            push @{ $entry->{messages} }, "** This paper has incomplete publication details (publication status unknown).\n";
            $major{$entry->{id}} = 1;
        }
        if( length( $entry->{author_abstract} ) < 40 ){
            push @{ $entry->{messages} }, "** This paper has no abstract.\n";
            $other{$entry->{id}} = 1 if !$major{$entry->{id}};
        }
        if( !$entry->{online} ){
            push @{ $entry->{messages} }, "** This paper has no associated link or locally archived copy.\n";
            $other{$entry->{id}} = 1 if !$major{$entry->{id}};
        }
        if( $entry->{pub_type} eq 'manuscript' && !$entry->{draft} ){
            push @{ $entry->{messages} }, "** This paper is flagged as a manuscript, but not a draft. Is it really a manuscript?\n";
            $other{$entry->{id}} = 1 if !$major{$entry->{id}};
        }
    }
    return \%major, \%other;
}

