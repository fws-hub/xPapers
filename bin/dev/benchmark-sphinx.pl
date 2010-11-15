use xPapers::Utils::Profiler;
use xPapers::DB;
our $embed;
my @queries =  (
    {
        label => 'author search',
        sql => "
        select SQL_CALC_FOUND_ROWS main.id from main join main_authors on main.id=main_authors.eId where NOT(deleted = '1') AND online = '1' AND pro = '1' and main_authors.lastname = 'Chalmers' and not main.deleted group by main.id order by main.date desc, main.authors asc, main.id asc limit 50
        "
    },
    
    {
        label => 'keyword search',
        sql => "
       select SQL_CALC_FOUND_ROWS main.id, round(sphinx_main.weight/1000,1) as relevance from main join sphinx_main on sphinx_main.id=main.serial where true and query='consciousness;sort=extended:\@weight desc;filter=pro_att,1;filter=online_att,1;mode=extended2;maxmatches=1000;limit=1000;indexweights=main_idx,4,main_idx_stemmed,1;weights=3,2,1,1' group by main.id order by relevance desc, main.id asc limit 50 
        "
    },

    {   
        label => 'search under',
        sql => "
select SQL_CALC_FOUND_ROWS main.id, cme.created as added, cats.dfo, cats.name, cats.id as cId, pLevel , round(sphinx_main.weight/1000,1) as relevance from cats join cats_me cme on (cme.cId=cats.id) join main on (cme.eId=main.id) join sphinx_main on sphinx_main.id=main.serial join ancestors on (aId = '135' and ancestors.cId=cats.id) where true and query='consciousness;sort=extended:\@weight desc;filter=pro_att,1;filter=online_att,1;mode=extended2;maxmatches=1000;limit=1000;indexweights=main_idx,4,main_idx_stemmed,1;weights=3,2,1,1' and ( true ) group by main.id order by relevance desc limit 50

"
    },

    {   
        label => 'search under big',
        sql => "
select SQL_CALC_FOUND_ROWS main.id, cme.created as added, cats.dfo, cats.name, cats.id as cId, pLevel , round(sphinx_main.weight/1000,1) as relevance from cats join cats_me cme on (cme.cId=cats.id) join main on (cme.eId=main.id) join sphinx_main on sphinx_main.id=main.serial join ancestors on (aId = '16' and ancestors.cId=cats.id) where true and query='consciousness;sort=extended:\@weight desc;filter=pro_att,1;filter=online_att,1;mode=extended2;maxmatches=1000;limit=1000;indexweights=main_idx,4,main_idx_stemmed,1;weights=3,2,1,1' and ( true ) group by main.id order by relevance desc limit 50

"
    },


    {
        label => 'my works',
        sql => "
        (select SQL_CALC_FOUND_ROWS main.id,authors as authors, date as date, added as added, viewings as viewings from main join main_authors on main_authors.eId=main.id join aliases on (aliases.uId= 2 and aliases.firstname=main_authors.firstname and aliases.lastname=main_authors.lastname) left join cats_me as ex on (ex.cId = 1418 and ex.eId=main.id) where NOT(deleted = '1') and isnull(ex.eId) group by main.id) union (select main.id,authors as authors2, date as date2, added as added2, viewings as viewings2 from main join cats_me on (main.id = cats_me.eId and cats_me.cId=1405) where NOT(deleted = '1') group by main.id) order by date desc, authors asc limit 300
        "
    },

    {
        label => 'advanced (sphinx)',
        sql => "

        select SQL_CALC_FOUND_ROWS main.id, round(sphinx_main.weight/1000,1) as relevance from main join sphinx_main on sphinx_main.id=main.serial where NOT(deleted = '1') AND online = '1' AND pro = '1' and query='\"consciousness\" \@authors chalmers;sort=extended:\@weight desc;filter=pro_att,1;filter=online_att,1;mode=extended2;maxmatches=1000;limit=1000;indexweights=main_idx,4,main_idx_stemmed,1;weights=3,2,1,1' group by main.id order by relevance desc limit 100

        "
    },

    { 
        label => 'advanced (normal)',
        sql => "
       select main.id, round( (match (main.authors,main.title) against('theory   ') + match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against ('theory   ')), 1 ) as relevance 
        from main
          where    NOT(deleted = '1') and match (main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against ('theory   ') and match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against('theory ' in boolean mode)
           group by main.id
            order by relevance desc
             limit 100"
    },

    {
        label => 'advanced (more)',
        sql => qq{ 
        select SQL_CALC_FOUND_ROWS main.id, round( 3 * ( match (main.title) against ('representationalis*
        representationism
        intentionalis*' in boolean mode) 
                                + match (main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against ('representationalis*
                                representationism
                                intentionalis*' in boolean mode)  
                                                        ) + 1 * ( match (main.title) against ('transparen*
                                                        diaphanous*
                                                        disjunctivis*  
                                                        "content of experience"  
                                                        "content of consciousness" 
                                                        "content of perception"
                                                        "content of perceptual"
                                                        "phenomenal content"
                                                        "representational character" "intentional structure"
                                                        "representational theory"
                                                        hallucina* 
                                                        illusion*' in boolean mode) 
                                                                                + match (main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against ('transparen*
                                                                                diaphanous*
                                                                                disjunctivis*  
                                                                                "content of experience"  
                                                                                "content of consciousness" 
                                                                                "content of perception"
                                                                                "content of perceptual"
                                                                                "phenomenal content"
                                                                                "representational character" "intentional structure"
                                                                                "representational theory"
                                                                                hallucina* 
                                                                                illusion*' in boolean mode)  
                                                                                                        ) + -1 * ( match (main.title) against ('"higher-order"
                                                                                                        HOT
                                                                                                        HOP
                                                                                                        justif*
                                                                                                        nonconceptual
                                                                                                        "non-conceptual"' in boolean mode) 
                                                                                                                                + match (main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against ('"higher-order"
                                                                                                                                HOT
                                                                                                                                HOP
                                                                                                                                justif*
                                                                                                                                nonconceptual
                                                                                                                                "non-conceptual"' in boolean mode)  
                                                                                                                                                        ) + match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against ('+( (percept* qualia experienc* phenomenal* conscious* sensory senses sensation* pain*) (represent* content* transparen* diaphanous* intentional*))' in boolean mode), 1 ) as relevance 
                                                                                                                                                         from main
  where    NOT(deleted = '1') AND
                                                                                                                                                             online = '1' AND
                                                                                                                                                               pro = '1' and match (main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against (' +(percept* qualia experienc* phenomenal* conscious* sensory senses sensation* pain*) +(represent* content* transparen* diaphanous* intentional*)' in boolean mode)
                                                                                                                                                                group by main.id
                                                                                                                                                                 having relevance >= 4
                                                                                                                                                                  order by relevance desc
                                                                                                                                                                   limit 100
        }
    }

);

if ($ARGV[0] eq 'run') { 
    xPapers::DB->exec("reset query cache");
    initProfiling();
    run_queries(1);
}

sub run_queries {

    my $alone = shift;
    my $prev_stats;
    $prev_stats = mysql_stat() if $alone;

    my $db = xPapers::DB->new;
    my $dbh = $db->dbh;
    $dbh->do("reset query cache");

    for my $q (@queries) {

        initProfiling() if $alone;
        event($q->{label},'start');
        my $sth = $dbh->prepare($q->{sql});
        $sth->execute;
        #warn foundRows($db->dbh);
        event($q->{label},'end');

        if ($alone) {
            my $stats = mysql_stat();

            print "-" x 50 . "\n";
            my $res = summarize();
            $res =~ s/<br>/\n/g;
            print $res;

            for my $k (sort keys %$stats) {
                next if $stats->{$k} eq $prev_stats->{$k};
                next unless grep { $k =~ $_ } qw/Slow Created/;
                printf("%40s: %s (%s)\n",$k,$stats->{$k},$stats->{$k} - $prev_stats->{$k});
            }
            $prev_stats = $stats;
        }

    }
}

sub mysql_stat {
    my $t = `mysqladmin extended-status`;
    my @lines = split(/\n/,$t);
    shift @lines;
    pop @lines;
    my %r;
    for (@lines) {
        $r{$1} = $2 if /\s*(\w.+?)\s*\|\s*(\d+)\s*\|/;
    }
    return \%r;
}

1;
