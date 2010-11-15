use xPapers::User;
use xPapers::Mail::Message;
use xPapers::DB;

my $msg = "[HELLO]Thanks for volunteering to edit a $DEFAULT_SITE->{niceName} category. This is to let you know that we will be processing applications in about three weeks from now. Please bear with us as we get things ready.[BYE]"; 

my $h = xPapers::DB->new->dbh;
my $s = $h->prepare("select distinct uId from cats_eterms");
$s->execute;

while (my $r = $s->fetchrow_hashref) {
    my $n = xPapers::Mail::Message->new(
        uId=>$r->{uId},
        content=>$msg,
        brief=>"Your application for an editorship"
    );
    $n->interpolate( $DEFAULT_SITE->{niceName} );
    $n->save;
}
