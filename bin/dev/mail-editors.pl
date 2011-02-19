use xPapers::Mail::Message;
use xPapers::Mail::Postmaster;
use xPapers::Editorship;
use xPapers::Cat;
use xPapers::Render::HTML;
use xPapers::Util;
use xPapers::Conf;


my $it = xPapers::ES->get_objects_iterator(query=>[start=>{le=>DateTime->now->subtract(years=>1)}]);
my $rend = xPapers::Render::HTML->new;

while (my $e = $it->next) {

    next unless $e->{uId} == 1;
    my $cat = xPapers::Cat->get($e->{cId});
    next unless $cat->{catCount};
    print "Mailing $e->{uId} - $e->{cId}\n";
    my $m = xPapers::Mail::Message->new(
        uId=>$e->uId,
        brief=>"Your editorship of $cat->{name} on PhilPapers",
        sender=>"David Chalmers <chalmers\@anu.edu.au>",
    );

    $e->{niceStart} = $rend->renderDate($e->start);
    $e->{catName} = $cat->name;
    $m->{moreFields} = ['niceStart','catName'];
    $m->{relatedObject} = $e;
    my $file = $DEFAULT_SITE->fullConfFile('msg_tmpl/editors-1year.txt');
    $m->content(getFileContent($file));
    $m->interpolate;
    print $m->content;
    $m->save;
    xPapers::Mail::Postmaster::post($m);


}
