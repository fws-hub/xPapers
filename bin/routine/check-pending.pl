use xPapers::Post;
use xPapers::Diff;
use DateTime;
use xPapers::Mail::Message;
$TEST_MODE = 1;

my $days = 14;
my $cutoff = DateTime->now->subtract(days=>$days);

my $nb_moderated = xPapers::PostMng->get_objects_count(query=>['accepted'=>0,created=>{lt=>$cutoff}]);
xPapers::Mail::MessageMng->notifyAdmin("Your attention might be needed","Please note that there are $nb_moderated messages in the moderation queue which are at least 14 days old") if $nb_moderated >= 5;

my $nb_delete = xPapers::D->get_objects_count(query=>[class=>"xPapers::Entry",type=>"delete",status=>0]);
xPapers::Mail::MessageMng->notifyAdmin("Your attention might be needed","Please note that there are $nb_delete papers in the deletion queue which are at least 14 days old") if $nb_delete >= 5;

my $nb_track = xPapers::D->get_objects_count(query=>[class=>"xPapers::Pages::Page",type=>"update",status=>0]);
xPapers::Mail::MessageMng->notifyAdmin("Your attention might be needed","Please note that there are $nb_track unapproved entries in the page tracking queue which are at least 14 days old") if $nb_track >= 5;

1;
