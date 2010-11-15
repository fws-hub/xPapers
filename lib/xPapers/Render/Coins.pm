package xPapers::Render::Coins;
use xPapers::Util;

sub make {
    my $e = shift;
    return unless $e->published and $e->{date} =~ /\d\d\d\d/;
    my $c = "ctx_ver=Z39.88-2004&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3A";
    my %h;
    $h{date} = $e->{date};
    if ($e->{pub_type} eq 'journal') {
        $c .= "&amp;journal";
        my ($f, $i, $l, $s) = parseName2($e->firstAuthor);
        $h{aulast} = $l;
        $h{aufirst} = $f;
        $h{genre} = "article";
        $h{atitle} = $e->{title};
        $h{jtitle} = $e->{source};
        $h{volume} = $e->{volume};
        $h{issue} = $e->{issue};
    } elsif ($e->{pub_type} eq 'chapter') {
        $c .= "&amp;book";
        $h{genre} = 'book';
        my @eds = $e->getEditors;
        if ($#eds > -1) {
            my ($f, $i, $l, $s) = parseName2($eds[0]);
            $h{aulast} = $l;
            $h{aufirst} = $f;
        } else {
            my ($f, $i, $l, $s) = parseName2($e->firstAuthor);
            $h{aulast} = $l;
            $h{aufirst} = $f;
        }
        $h{btitle} = $e->{source};
        $h{pub} = $e->{ant_publisher};
    } elsif ($e->{pub_type} eq 'book') {
        $c .= "&amp;book";
        $h{genre} = 'book';
        my ($f, $i, $l, $s) = parseName2($e->firstAuthor);
        $h{aulast} = $l;
        $h{aufirst} = $f;
        $h{btitle} = $e->{title};
        my $isbn = $e->{isbn};
        $h{isbn} = $isbn->[0] if $isbn and $#$isbn > -1;
        $h{pub} = $e->{publisher};
    } else {
        return;
    }
    $c .= "&amp;" . join("&amp;", map { "$_=" . urlEncode($h{$_}) } keys %h);
    return $c;
}

1;
