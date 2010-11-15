use xPapers::Thread;

my $it = xPapers::ThreadMng->get_objects_iterator();
while (my $t = $it->next) {

    my @posts = sort { $a->submitted->epoch <=> $b->submitted->epoch } $t->posts;
    if ($#posts > -1) {
        $t->postCount($#posts+1);
        $t->latestPostId($posts[-1]->id);
        $t->latestPostTime($posts[-1]->submitted);
        $t->save;
    }

}
