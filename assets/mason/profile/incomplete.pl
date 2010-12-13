<%gh("Incomplete Entries")%> 
<& ../checkLogin.html, %ARGS &>
<style>
li.incomplete { padding-bottom:5px }
</style>
<input type="button" onclick="refresh()" value="Refresh list"><p>
<%perl>
use xPapers::EntryMng;
#use Smart::Comments;

my $uId = $user->{id};
#$uId = 1;
my %warnings = xPapers::EntryMng->computeIncompleteWarnings( $uId );

my @major = keys % { $warnings{$uId}{major} };
my @other = map { exists $warnings{$uId}{major}{$_} ? () : $_ } keys % { $warnings{$uId}{other} };

if( @major || @other ){
    print "Some of your works appear to have incomplete records:<br>";
}
else{
    print "There are no incomplete records about your works";
}

if( @major ){
    print "<h3>Entries with major defects:</h3>\n";
    for my $eId ( @major ){
        print_entry_messages( $warnings{$uId}{entries}{$eId}, $rend );
    }
}

if( @other ){
    print "<h3>Entries with minor defects:</h3>\n";
    for my $eId ( @other ){
        print_entry_messages( $warnings{$uId}{entries}{$eId}, $rend );
    }
}

sub print_entry_messages {
    my $entry = shift;
    my $obj = xPapers::Entry->get($entry->{id});
    my $rend = shift;
    #print qq|<li id='e$entry->{id}' class='incomplete'>$entry->{title} (<span class='ll' onclick="editEntry2('$entry->{id}')">Edit</span>, <a href="/profile/$uId/not_mine.pl?eId=$entry->{id}">Not mine</a>):\n|;
    my $msg = "";
    for my $message ( @{ $entry->{messages} } ){
        $msg .= "<div style='background-color:#fee'>$message</div>\n";
    }
    #$obj->{extraOptions} = $msg;
    print $rend->renderEntry($obj);
    print "<li>$msg</li>";

}

</%perl>

