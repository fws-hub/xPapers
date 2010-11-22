use strict;

use File::Slurp 'slurp';

use xPapers::DB;
use xPapers::CatMng;
use xPapers::Editorship;
use xPapers::User;
use xPapers::Conf;

my $advice=<<END;
To help others access your work, please make sure that each of your publications 1) is in the index; 2) has an associated online copy; 3) has full publication details; 4) has an associated abstract in our database; 5) has associated categories at the leaf level in our database. The leaf categories are the narrowest in the category structure. To add a new item to the index, click 'Submit material' -> 'Submit a book or article' in the top menu. "Open your profile":http://philpapers.org/profile to see the works currently attributed to you. 
END
my $DEBUG = 1;
my $test = $ARGV[0] ? " and userworks.uId=$ARGV[0] " : "";

my $db = xPapers::DB->new;
my $dbh = $db->dbh;
my $sth = $dbh->prepare( 
    "select main.id, title, author_abstract, pub_type, main.catCount, online, draft, uId 
    from main 
    join userworks on main.id = eId
    join users on userworks.uId=users.id
    left join ( cats_me join cats on cats_me.cId = cats.id )
    on cats_me.eId = main.id  and canonical and dfo=edfo
     where ( deleted = 0 or deleted is null ) and 
     ( users.confirmed ) and
     main.catCount > 0 and
     cats_me.id is null
     $test
    "
);
my %list;
$sth->execute;
while( my $entry = $sth->fetchrow_hashref ){
    $entry->{no_leaf} = 1;
    push @{ $list{$entry->{uId}} }, $entry;
}

$sth = $dbh->prepare( 
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
while( my $entry = $sth->fetchrow_hashref ){
    push @{ $list{$entry->{uId}} }, $entry;
}

for my $uId ( keys %list ){
    die unless $uId == 2;
    my $body = "[HELLO]Some of your works on $DEFAULT_SITE->{niceName} appear to have incomplete records. You might want to complete their records, as this will make it easier for others to find your work. A list of records with potential defects is provided below for your convenience.\n\n$advice\n"; 
    my ($major, $other) = generateMessages( $list{$uId} );
    if( %$major ){
        $body .= "*Records with major defects:*\n\n";
        for my $entry ( @{ $list{$uId} } ){
            next if ! $major->{  $entry->{id} };
            $body .= qq|$entry->{title} (["Fix it":$DEFAULT_SITE->{server}/rec/$entry->{id}?edit=1], ["Not mine":$DEFAULT_SITE->{server}/profile/$uId/not_mine.pl?eId=$entry->{id}])\n\n|;
            $body .= join "\n", @{ $entry->{messages} };
            $body .= "\n";
        }
    }
    if( %$other){
        $body .= "\n*Records with minor defects:*\n\n";
        for my $entry ( @{ $list{$uId} } ){
            next if $major->{  $entry->{id} };
            $body .= qq|$entry->{title} (["Fix it":$DEFAULT_SITE->{server}/rec/$entry->{id}?edit=1], ["Not mine":$DEFAULT_SITE->{server}/profile/$uId/not_mine.pl?eId=$entry->{id}])\n\n|;
            $body .= join "\n", @{ $entry->{messages} };
            $body .= "\n";
        }
    }
    $body .= "[BYE]";
    my $email = xPapers::Mail::Message->new;
    $email->uId($uId);
    $email->brief("Some of your works appear to have incomplete records on $DEFAULT_SITE->{niceName}");
    $email->content( $body );
    #TMP
    $email->save;

    print "$body\n\n\n";
}

sub generateMessages {
    my $entries = shift;
    my %major;
    my %other;
    my $bullet = "*";
    for my $entry (@$entries) {
        $entry->{messages} = [];
        if( !$entry->{catCount} ){
            push @{ $entry->{messages} }, "$bullet This item is not in any category. This will make it very hard to find.\n";
            $major{$entry->{id}} = 1;
        } elsif( $entry->{no_leaf} ){
            push @{ $entry->{messages} }, "$bullet This paper is not in any leaf category.\n";
            $other{$entry->{id}} = 1;
        }
        if( $entry->{pub_type} eq 'unknown' ){
            push @{ $entry->{messages} }, "$bullet This item has incomplete publication details (publication status unknown).\n";
            $major{$entry->{id}} = 1;
        }
        if( length( $entry->{author_abstract} ) < 40 ){
            push @{ $entry->{messages} }, "$bullet This item has no abstract.\n";
            $other{$entry->{id}} = 1 if !$major{$entry->{id}};
        }
        if( !$entry->{online} ){
            push @{ $entry->{messages} }, "$bullet This item has no associated link or locally archived copy.\n";
            $other{$entry->{id}} = 1 if !$major{$entry->{id}};
        }
        if( $entry->{pub_type} eq 'manuscript' && !$entry->{draft} ){
            push @{ $entry->{messages} }, "$bullet This item is flagged as a manuscript, but not a draft. Is it really a manuscript you don't intend to publish?\n";
            $other{$entry->{id}} = 1 if !$major{$entry->{id}};
        }
    }
    return \%major, \%other;
}


