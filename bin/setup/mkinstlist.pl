use xPapers::DB;
use xPapers::Inst;
use xPapers::Util;
use HTML::Entities qw/decode_entities/;
my $db = xPapers::DB->new;
my $h = $db->dbh;
my %codes = (
    edu => "US",
    uk => "GB",
    mil => "US",
    gov => "US"
);
my %bad = map { $_=> 1} qw/org net com biz info/; 
my %adhoc = (
    'University of Toronto, Scarborough' => 'University of Toronto at Scarborough',
    'Community College of Southern Nevada' => 'College of Southern Nevada',
    'Ryerson Polytechnic University' => 'Ryerson University'
);
my $content = getFileContent($ARGV[0],'cp1252');
$content =~ s/^.+?<ol>//;
$content =~ s/<\/ol>.+?//;
my @list = split(/<li>/,$content);
binmode(STDOUT,":utf8");
for my $l (@list) {
    next unless $l =~ /<a href="http:\/\/(.+?)">(.+?)<\/a>/;
    my $dom = $1;
    my $name = $2;
    $name =~ s/\s+$//;
    $name = toUTF(decode_entities($name));
    $name = $adhoc{$name} if $adhoc{$name};
    my $inst = xPapers::I->get_objects(query=>[name=>{like=>$name}]);

    $dom =~ s/^www\.//;
    $dom =~ s/\/.*$//;
    $dom =~ s/:\d+$//;
    next if $dom =~ /\.\d+$/;
    die unless $dom =~ /\.(\w+)$/;
    my $tld = lc $1;
    next if $bad{$tld};
    my $country = $codes{$tld} || uc $tld;
    unless ($#$inst > -1) {
        print "Not found: '$name'\n";
        next;
    }
    if ($#$inst > 0) {
        print "Ambiguous: $name\n";
        next;
    }
    $inst->[0]->country($country);
    $inst->[0]->domain($dom);
    $inst->[0]->save;
    print "$dom -> $country\n";
}


