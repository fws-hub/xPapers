use xPapers::Conf;
use xPapers::Mail::Message;
use xPapers::Entry;

#xPapers::Mail::MessageMng->notifyAdmin("test mail: " . localtime(), content=>"test");

my $m = xPapers::Mail::Message->new;

$m->{relatedObject} = xPapers::Entry->get('BOUCIU');
$m->content("[REL:id], [REL:title]\n[BYE]");
$m->interpolate;
print $m->content;
