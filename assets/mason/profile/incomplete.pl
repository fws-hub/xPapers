<%gh("Incomplete Entries")%> 
<& ..//checkLogin.html, %ARGS &>
<%perl>
use xPapers::EntryMng;
#use Smart::Comments;

my $uId = $user->{id};

my %warnings = xPapers::EntryMng->computeIncompleteWarnings( $uId );

my @major = keys % { $warnings{$uId}{major} };
my @other = keys % { $warnings{$uId}{major} };

if( @major || @other ){
    print "Some of your works appear to have incomplete records<br>";
}
else{
    print "There are no incomplete records about your works";
}

if( @major ){
    print "<h3>Entries with major defects:</h3><ul>\n";
    for my $eId ( @major ){
        print_entry_messages( $warnings{$uId}{entries}{$eId} );
    }
    print "</ul>\n";
}

if( @other ){
    print "<h3>Entries with other defects:</h3><ul>\n";
    for my $eId ( @other ){
        print_entry_messages( $warnings{$uId}{entries}{$eId} );
    }
    print "</ul>\n";
}

sub print_entry_messages {
    my $entry = shift;
    print qq|<li>$entry->{title} (<a href="/rec/$entry->{id}?edit=1">Fix it</a>, <a href="/profile/$uId/not_mine.pl?eId=$entry->{id}">Not mine</a>):\n|;
    print "<ul>\n";
    for my $message ( @{ $entry->{messages} } ){
        $message =~ s/\*//;
        print "<li>$message\n";
    }
    print "</ul>\n";
}

</%perl>

