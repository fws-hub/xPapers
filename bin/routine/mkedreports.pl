use xPapers::Editorship;
use xPapers::Mail::Message;

my $eds = xPapers::ES->get_objects(query=>['!start'=>undef,'end'=>undef],group_by=>['uId']);

for my $e (@$eds) {
    my $u = $e->user;
    #next unless $u->id == 1;
    my $report = $u->edReport( $DEFAULT_SITE->{server} );
    xPapers::Mail::Message->new(
        uId=>$u->id,
        brief=>"Weekly editor's report",
        content=>"[HELLO]This is your weekly editor's report telling you where attention might be needed in your categories. Log in to \"the editor's panel\":$DEFAULT_SITE->{server}/utils/edpanel.pl to check user edits or categorize entries.\n\n$report"
    )->save;
    #print "User = $u->{id}\n$report\n";
    sleep(2);
}

1;
