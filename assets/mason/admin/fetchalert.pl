<%perl>
my $al = xPapers::Alert->get($ARGS{id});
error("bad alert") unless $al;
if ($al->fetch) {
print "fetch ok:<br>";
print $al->{result};
} else {
print "fetch error<br>";
print $al->url . "<br>";
print $xPapers::UserMng::DIGEST_DEBUG;
print "<hr>";
print $al->{__bad_content};
print "<hr>";
}

</%perl>
