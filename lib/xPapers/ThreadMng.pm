package xPapers::ThreadMng;

use xPapers::Query;
use xPapers::DB;
use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Thread' }

__PACKAGE__->make_manager_methods('threads');

=doc

Parameters are:
keywords (string)
forums_ids (array ref)
sort

=cut

sub search {
    my ($me, %params) = @_;
    
    my $keywords = "";
    my $filters = "";
    my $sort = "";
    my $db = xPapers::DB->new;
    my $dbh = $db->dbh;

    if ($params{keywords}) {
        $keywords .= xPapers::Query::ftQuote($params{keywords}) . ";mode=extended";
    }
    my $f = $params{forums} || [];
    if ($params{special} eq 'MY' or ($#$f > -1)) {
        $filters .= ";filter=forum_ids," . join(",",@$f);
    }
    my $ex = $params{exclude};
    if ($ex and $#$ex > -1) {
        $filters .= ";!filter=forum_ids," . join(",",@$ex);
    }
    if ($params{special} eq 'PAPERS') {
        $filters .= ";filter=paper_forum,1";
    }
    if ($params{sort}) {
        if ($params{sort} eq 'ct desc') {
            $sort = ";sort=extended:created desc";
        } elsif ($params{sort} eq 'pt desc') {
            $sort = ";sort=extended:latest_post_time desc";
        }
    } else {
        $sort = ";sort=extended:\@weight desc";
    }
    $params{limit} ||= 20;
    $params{start} ||= 0;
    die "Invalid limit/start" unless $params{limit} =~ /^\d+$/ and $params{start} =~ /^\d+$/;

    my $indexes = $params{keywords} ? "index=forums_idx,forums_idx_stemmed;indexweights=forums_idx,4,forums_idx_stemmed,1" : "index=forums_idx";


    my $q = "select SQL_CALC_FOUND_ROWS id from sphinx_forums where query='$keywords$filters$sort;maxmatches=1000;limit=1000;$indexes' limit $params{limit} offset $params{start}";
    #print $q;
    my $res = $dbh->selectcol_arrayref($q);
    if ($DBI::errstr) {
        die $DBI::errstr;
    }
    return {
        results => $res,
        found =>xPapers::DB::foundRows($dbh)
    }
}


1;


