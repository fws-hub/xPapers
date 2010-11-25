use strict;
use xPapers::DB;
use Devel::Peek;
use Encode;
use xPapers::Conf;
use xPapers::Utils::Lang qw/isLang splitToWords addWordToOur saveOur/;
use utf8;

binmode(STDOUT,":utf8");
binmode(STDERR,":utf8");

my $FREQ_TRESHOLD = 10;
my %FILTER_OUT = map { $_ => 1 } qw/ lsquo rsquo /;

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

my $sth = $dbh->prepare("select id, source, descriptors, title, author_abstract from main where deleted is null or deleted = 0");# and id = 'MORIJO'" );

$sth->execute;
my $i = 0;
my %our_words;
my %isms;
RECORD:
while( my $rec = $sth->fetchrow_hashref ){
    print "$i\n" if !( $i++ % 1000 ) && $ARGV[0] eq '-v';
    for my $key ( keys %$rec ){
        my $val = decode( 'utf-8', $rec->{$key} );
        $val =~ s/\x{2019}/'/g;
        $rec->{$key} = $val;
    }
    my $id = delete $rec->{id};
    if( isLang( $rec->{title}, $rec->{author_abstract} ) ){
        my @words = splitToWords( values %$rec ); 
        my %words;
        for my $word ( @words ){
            next if $FILTER_OUT{$word};
            if ($word =~ /ism$/i) {
                $isms{$word}++;
            }
            next if $words{$word}++;
            if( ! isLang( $word )){
                if( $our_words{$word}++ == $FREQ_TRESHOLD ){
                    #print "new: $word, ";
                    addWordToOur($word);
                }
            }
        }
    }
}

my @selected_isms = grep { $isms{$_} >= 2 } keys %isms;
open F,">$PATHS{LOCAL_BASE}/var/isms.txt";
for my $ism (@selected_isms) {
   my $ist = $ism; 
   $ist =~ s/ism$/ist/i;
   print F "$ism > $ist\n";
}
close F;

#print "\n";
saveOur();

