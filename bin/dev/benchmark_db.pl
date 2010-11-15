use xPapers::Utils::Profiler;
use xPapers::DB;
my $db = xPapers::DB->new;
my $dbh = $db->dbh;
my @queries =  (
    {
        label => 'author search',
        sql => "
        select SQL_CALC_FOUND_ROWS main.id
         from main
           join main_authors on main.id=main_authors.eId
            where    NOT(deleted = '1') and main_authors.lastname = 'Chalmers'
             group by main.id
              order by main.date desc, main.authors asc, main.id asc
               limit 50
        "
    },
    
    {
        label => 'keyword search',
        sql => "select  main.id,  round(match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against('consciousness ')+match(main.authors,main.title) against('consciousness '),1) * if(main.title rlike '.*.*', 2, 1) * if(main.authors like '%;consciousness,%', 2, 1) * if(main.authors like '%;,%', 2, 1) as relevance 
         from main
             where    NOT(deleted = '1') AND
               online = '1' AND
                 pro = '1' and match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against('consciousness ')
                   order by relevance desc, main.id asc
                    limit 50"
    },

    {   
        label => 'search under',
        sql => "select main.id, cme.created as added, cats.dfo, cats.name, cats.id as cId, pLevel ,  round(match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against('consciousness ')+match(main.authors,main.title) against('consciousness '),1) * if(main.title rlike '.*.*', 2, 1) * if(main.authors like '%;consciousness,%', 2, 1) * if(main.authors like '%;,%', 2, 1) as relevance 
            from cats
                join cats_me cme on (cme.cId=cats.id)
                    join main on (cme.eId=main.id)
                        join ancestors on (aId = '135' and ancestors.cId=cats.id)
                             where 
                                     true
                                              and match(main.title,main.authors,main.notes,main.descriptors,main.source,main.author_abstract) against('consciousness ')
                                                      
                                                              and (
                                                                             NOT(deleted = '1') AND
                                                                               online = '1' AND
                                                                                 pro = '1'
                                                                                         )
                                                                                             group by main.id
                                                                                                 order by relevance desc

                                                                                                  limit 50"
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

print "This will take about one minute..\n";
#$dbh->do("reset query cache");
#for my $q (@queries) {
#    my $r = $dbh->prepare($q->{sql});
#    $r->execute; 
#}
initProfiling();
for my $q (@queries) {
    $dbh->do("reset query cache");
    event($q->{label},'start');
    my $r = $dbh->prepare($q->{sql});
    $r->execute; 
    event($q->{label},'end');
}
my $res = summarize();
$res =~ s/<br>/\n/g;
print $res;


