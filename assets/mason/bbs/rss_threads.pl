<%perl>
my $x = new XML::RSS (version => '1.0');
$x->channel(
    title => $ARGS{title},
    link => $ARGS{link},
    date => DateTime->now->iso8601(), 
    syn => {
        updatePeriod => 'daily',
        updateFrequency => 1,
        updateBase => '1901-01-01T00:00+00:00',
    },
    dc => {
        publisher=>$s->{niceName},
    },
    taxo => [
    ]
);

for my $t (@{$ARGS{__threads__}}) {
    my $fp = $t->firstPost;
    next unless $fp;
    my ($desc,$b) = $fp->body; #$rend->wordSplit($fp->body,100);
    my $subject = $fp->thread->forum->cId ? $fp->thread->forum->category->name : undef;
    $x->add_item(
       title=>$fp->user->fullname . ": " . $fp->subject,
       link=>$rend->postURL($fp),
       description=>$desc . ($b ? "..." : ""),
       dc => {
            creator => $fp->user->fullname,
            subject=> $subject,
            date=> $fp->created->ymd,
            identifier=>"$DEFAULT_SITE->{server}/post/" . $fp->id
       }
    );
}

print $x->as_string;
</%perl>


