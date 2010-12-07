<%gh("Incomplete Entries")%> 
<& ..//checkLogin.html, %ARGS &>
<%perl>
use xPapers::EntryMng;
#use Smart::Comments;

my $uId;# = $user->{id};
$uId = 1;

my %warnings = ( 1 => { major => { 1 => 1, 2 => 1 }, minor => { 3 => 1 }, entries => { 1 => { messages => [ 'aaa', 'bbb' ] } , 2 => { messages => [ 'aaa' ] } , 3 => { messages => [ 'ccc' ] } } } );

#xPapers::EntryMng->computeIncompleteWarnings( $uId );

my @major = keys % { $warnings{$uId}{major} };
if( @major ){
    print "Major defects:<ul>\n";
    for my $eId ( @major ){
        print "<li>$eId:<ul>\n";
        for my $message ( @{ $warnings{$uId}{entries}{$eId}{messages} } ){
            $message =~ s/\*//;
            print "<li>$message\n";
        }
        print "</ul>\n";
    }
    print "</ul>\n";
}

my @other = keys % { $warnings{$uId}{major} };
if( @other ){
    print "\nOther defects:<ul>\n";
    for my $eId ( @other ){
        print "<li>$eId:<ul>\n";
        for my $message ( @{ $warnings{$uId}{entries}{$eId}{messages} } ){
            $message =~ s/\*/<li>/;
            print $message;
        }
        print "</ul>\n";
    }
    print "</ul>\n";
}

</%perl>

