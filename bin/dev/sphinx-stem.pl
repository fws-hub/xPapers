use xPapers::DB;
use xPapers::Entry;

my $keyword = $ARGV[0];

my $r = xPapers::DB->exec(
    "select count(*) as nb from sphinx_main join main on sphinx_main.id=main.serial where query='\@title $keyword;mode=extended;limit=50;indexweights=main_idx,2,main_idx_stemmed,1' and not ( title like '%$keyword%' )
    ");

my $h = $r->fetchrow_hashref->{nb};
if ($h) {
    print "Stemmed. Count = $h.\n";
}
