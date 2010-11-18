use strict;
use warnings;

use File::Slurp 'slurp';

use xPapers::DB;
use xPapers::CatMng;
use xPapers::Editorship;
use xPapers::User;
use xPapers::Conf;

my $DEBUG = 1;

my $db = xPapers::DB->new;
my $dbh = $db->dbh;
$dbh->do( "
    update cats_eterms 
    set status = -20 
    where 
        created < DATE_SUB(now(), interval 1 week) 
        and auto = 1 
        and  status = 10
");

my $cat_it = xPapers::CatMng->catsWithNoEditors( minPLevel => 1, maxPLevel => 4 );
print "Got cat iterator\n" if $DEBUG;
my %editorships;
my $i;
while( my $cat = $cat_it->next ){
    $cat = xPapers::Cat->get( 11 );
    last if $i++;
    my @current = $cat->editors;
    my $eds = join(", ", map {$_->fullname} @current);
    $eds ||= 'no editor';
    
    print $cat->id . ' ' . $cat->name . ' ' . $cat->pLevel . " ($eds)\n" if $DEBUG;
    for my $uId ( $cat->findPotentialEditors() ){

        push @{$editorships{$uId}}, $cat;
    }
    print "\n";
}

for my $uId ( keys %editorships ){
    my $email = xPapers::Mail::Message->new;
    $email->uId($uId);
    $email->brief($DEFAULT_SITE->{niceName} . "invitest you to be an editor");
    my $content = slurp( $DEFAULT_SITE->fullConfFile( "msg_tmpl/editor_invite.txt" ) );
    my $cats;
    for my $cat ( @{ $editorships{$uId} } ){
        my $editorship = xPapers::Editorship->new(
            uId => $uId,
            cId => $cat->id,
            auto => 1,
            status => 10,
            created=>'now',
        );
        $editorship->save;
        $cats .= '* "' . $cat->name . '":' . $DEFAULT_SITE->{server} . '/browse/' . $cat->eun;
    }
    $content =~ s/\[CAT\]/$cats/;
    $content =~ s/\[CONFLINK\]/$DEFAULT_SITE->{server}\/utils\/edconfirm.pl/;
    print $content;
    $email->content( $content );
    $email->sender( 'The ' . $DEFAULT_SITE->{niceName} . 'Editors <editors@' . $DEFAULT_SITE->{domain} );
#    $email->save;
    my $user = xPapers::User->get($uId);
    print "  " . $user->fullname . " [$user->{pubRating} items]\n";
    print "Saved invitation email for $uId\n";
}



