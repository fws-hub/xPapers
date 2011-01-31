use strict;

use File::Slurp 'slurp';

use xPapers::Conf;
use xPapers::EntryMng;
use xPapers::Mail::Message;

my $advice=<<END;
To help others access your work, please make sure that each of your publications 1) is in the index; 2) has an associated online copy; 3) has full publication details; 4) has an associated abstract in our database; 5) has associated categories at the leaf level in our database. The leaf categories are the narrowest in the category structure. To add a new item to the index, click 'Submit material' -> 'Submit a book or article' in the top menu. "Open your profile":http://philpapers.org/profile to see the works currently attributed to you. You can edit any index entry on the site by clicking the small 'edit' link under it. 
END

my %warnings = xPapers::EntryMng->computeIncompleteWarnings( $ARGV[0] );
my $count = 0;
for my $uId ( keys %warnings ){
    #die unless $uId == 1;
    next unless $uId >= 10000;
    $count++;
    my $body = "[HELLO]Some of your works on $DEFAULT_SITE->{niceName} appear to have incomplete records. You might want to complete their records, as this will make it easier for others to find them. A list of records with potential defects is provided below for your convenience. You can also view a dynamically updated version of this list \"here\":$DEFAULT_SITE->{server}/profile/$uId/incomplete.pl \n\n$advice\n"; 
    my @major = keys % { $warnings{$uId}{major} };
    my @other = map { exists $warnings{$uId}{major}{$_} ? () : $_ } keys % { $warnings{$uId}{other} };
    if( @major ){
        $body .= "*Records with major defects:*\n\n";
        for my $eId ( @major  ){
            my $entry = $warnings{$uId}{entries}{$eId};
            $body .= qq|$entry->{title} (["Fix it":$DEFAULT_SITE->{server}/rec/$entry->{id}?edit=1], ["Not mine":$DEFAULT_SITE->{server}/profile/$uId/not_mine.pl?eId=$entry->{id}])\n\n|;
            $body .= join "\n", map { "* $_" } @{ $entry->{messages} };
            $body .= "\n";
        }
    }
    if( @other ){
        $body .= "*Records with minor defects:*\n\n";
        for my $eId ( @other ){
            my $entry = $warnings{$uId}{entries}{$eId};
            $body .= qq|$entry->{title} (["Fix it":$DEFAULT_SITE->{server}/rec/$entry->{id}?edit=1], ["Not mine":$DEFAULT_SITE->{server}/profile/$uId/not_mine.pl?eId=$entry->{id}])\n\n|;
            $body .= join "\n", map { "* $_" } @{ $entry->{messages} };
            $body .= "\n";
        }
    }
    $body .= "[BYE]";
    my $email = xPapers::Mail::Message->new;
    $email->uId($uId);
    $email->brief("Some of your works appear to have incomplete records on $DEFAULT_SITE->{niceName}");
    $email->content( $body );
    $email->save;
    print "Notifying $uId\n";

    #print "$body\n\n\n";
}
print "$count sent.\n";


