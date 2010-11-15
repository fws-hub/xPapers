<& ../header.html &>
<%perl>
my $offset = $ARGS{offset} || 0;
$m->flush_buffer;
my $i = xPapers::EntryMng->get_objects_iterator(query=>[
    db_src=>'lib',pub_type=>'book','!googleBooksQuery'=>undef
],limit=>2000,offset=>$offset); 
#['date','cn_class','cn_num','cn_alpha']

while (my $e = $i->next) {
    $rend->{addToEntry} = " Call: $e->{cn_full}, ISBN:". join(",",$e->isbn);
    print $rend->renderEntry($e);
    if ($e->hasChapters) {
        print "<li><blockquote>";
            print $rend->renderEntry($_) for $e->chapters;
        print "</li></blockquote>";

    }
}

</%perl>
