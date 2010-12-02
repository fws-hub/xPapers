package xPapers::Query;
use xPapers::Util qw/quote parseName2 rmDiacritics/;
use xPapers::Object;
use xPapers::Conf;
use xPapers::Utils::Profiler;
use HTML::Entities;
use Encode qw/decode is_utf8/;
use strict;

use base qw/xPapers::Object/;

my %WEIGHTS = ( e => 3, g => 1, p => 0.5, n=> -1 );
my @SPHINX_OPERATORS = qw'& | ( ) + - ~ " @ ^ $ </'; 
my $SPHINX_OPQ = join('', map { '' . $_} @SPHINX_OPERATORS);
my $SPHINX_OPRE = qr/[\Q$SPHINX_OPQ\E]/;

__PACKAGE__->meta->setup
(
  table   => 'queries',

  columns => 
  [
    id            => { type => 'serial', not_null => 1 },
    name          => { type => 'varchar', length => 100 },
    mode          => { type => 'varchar', length => 20 },
    searchStr     => { type => 'text', length => 65535 },
    minYear       => { type => 'integer' },
    maxYear       => { type => 'integer' },
    minRelevance  => { type => 'float', precision => 32 },
    owner         => { type => 'integer' },
    inter         => { type => 'integer' },
    freeOnly      => { type => 'varchar', length => 5 },
    proOnly       => { type => 'varchar', length => 5 },
    onlineOnly    => { type => 'varchar', length => 5 },
    publishedOnly => { type => 'varchar', length => 5 },
    draftsOnly    => { type => 'integer', default=> 0},
    filterMode    => { type => 'varchar', length => 20 },
    advMode       => { type => 'varchar', length=> 10,default=>"fields" },
    executed      => { type => 'datetime' },
    interval      => { type => 'integer' },
# for fuzzy:
    w_a           => { type => 'text', length => 65535 },
    w_e           => { type => 'text', length => 65535 },
    w_g           => { type => 'text', length => 65535 },
    w_p           => { type => 'text', length => 65535 },
    w_n           => { type => 'text', length => 65535 },
    w_ez          => { type => 'text', length=>65535 }, #for natural language search
    w_ezn         => { type => 'text', length=>65535 }, #for natural language search
    w_ezn2        => { type => 'text', length=>65535 }, #for natural language search
    appendMSets   => { type => 'integer', default=>0 },
# for fields-based (sphinx):
    all           => { type => 'text', length => 2000 },
    exact         => { type => 'text', length => 2000 },
    without       => { type => 'text', length => 2000 },
    atleast       => { type => 'text', length => 2000 },
    extended      => { type => 'text', length => 2000 },
    authors       => { type => 'text', length => 2000 },
    publication   => { type => 'text', length => 2000 },

    examplar      => { type => 'integer' },
    system        => { type => 'integer', default=>0 },
    trawler       => { type => 'integer', default=>0 }
  ],

  foreign_keys => [
        user => { class => 'xPapers::User', key_columns => { owner => 'id' } },
        trawlerCat => { class=>'xPapers::Cat', key_columns => { trawler=>'id' } }
  ],
  unique_key => ['name','owner'],
    
  primary_key_columns => [ 'id' ],

);

my %notUserFields = ( id => 1, executed => 1, owner=>1);

sub notUserFields { return \%notUserFields; }
sub checkboxes { return { appendMSets => 1 } }

__PACKAGE__->set_my_defaults;

sub toString {
    my $me = shift;
    return "Name: $me->{name}, owner: " . $me->user->fullname;
}
sub loadForm {
    my ($me,$args) = @_;
    $args->{$_} = decode_entities($args->{$_}) for keys %$args;
    $me->loadUserFields($args);
    $me->{since} = $args->{since} if $args->{since};
    return "Invalid relevance parameter" unless !$args->{minRelevance} or
                                                $args->{minRelevance} =~ /^\d+$/;
    return undef;
}

sub save {
    my $i = $_[0];
    $i->clear_owner_cache;
    shift()->SUPER::save(@_);
}
sub delete {
    my $i = $_[0];
    $i->clear_owner_cache;
    shift()->SUPER::delete(@_);
}
sub saveForm {
    my ($user, $args) = @_;
    my $q;
    if (!$args->{fId}) {
        $q = xPapers::Query->new(owner=>$user->id, name=>$args->{name});
        if ($q->load_speculative) {
            return (undef,"You already have a filter with name `$args->{name}`");
        }
        $q->owner($user->id);
        $user->clear_cache;
    } else {
        $q = xPapers::Query->new(id=>$args->{fId})->load_speculative;        
        return (undef, "Filter id unknown:$args->{fId}") unless $q;
    }
    $q->loadForm($args);
    $q->save;
    return ($q, "");
}

sub foundRows {
    my $me = shift;
    return $me->{found};
}

sub execute {
    my ($me) = @_;
    my $q = $me->sql;
    $q .= "\n order by $me->{order}" if $me->{order};
    $q .= "\n limit " . ($me->{cfg}->{limit} || $DEFAULT_LIMIT);
    $q .= "\n offset $me->{cfg}->{start}" if $me->{cfg}->{start};
    if ($me->{debug}) {
        print "<pre>$q</pre>";
        $me->{debug}->flush_buffer;
        #return;
    }
    eval {
        $me->{sth} = $me->dbh->prepare($q);
        event('run query','start');
        $me->{sth}->execute;
        event('run query','end');
    };
    if ($@) {
        die "Database error with query = $q" unless $me->{dontDieOnError};
        $me->{error} = $@;
        return 0;
    } 
    my $s2 = $me->dbh->prepare("select found_rows() as f");
    $s2->execute;
    $me->{found} =  $s2->fetchrow_hashref->{f};
    return 1;
}

sub sql {
    my $me = shift;
    return $me->{sql_manual} if $me->{sql_manual};
    my $q;
    my $U = $me->{cfg}->{union};
    if ($U) {
        if ($U == 1) {
            $q = "(select SQL_CALC_FOUND_ROWS $me->{table}.id";
            $q .= ",authors as authors, date as date, added as added, viewings as viewings";
        } 
        
        # here we are making the sql for a list unionized with a search 
        else {
            die "that's a bug here.." unless $me->{cfg}->{list};

            if ($me->{cfg}->{list}->linkedFilter->{filterMode} eq 'advanced') {
                $me->{extraSelect} = $FT_FIELDS_S;
            }
            $q = "(select $me->{table}.id";
            $q .= ",authors as authors$U, date as date$U, added as added$U, viewings as viewings$U";
        }

        $me->{load} = 1;
    } else {
        $q = "select SQL_CALC_FOUND_ROWS $me->{table}.id";
        $me->{load} = 1;
    }
    $q .= ",$me->{extraSelect}" if $me->{extraSelect};
    $q .= "\n from $me->{table}";
    $q .= "\n $me->{joins}" if $me->{joins};
    $q .= "\n where $me->{where}";
    $q .= "\n group by main.id";
    $q .= "\n having $me->{having}" if $me->{having};
    $q .= ")" if $me->{cfg}->{union};
    $q .= "\n union " . $me->{cfg}->{unionWith}->sql if $me->{cfg}->{unionWith};
    #warn $q;
    return $q;
}

sub next {
    my ($me) = @_;
    event('next','start');
    return undef if $me->{finished};
    if (my $h = $me->{sth}->fetchrow_hashref) {
        my $e;
        $me->{row} = $h;
        if ($h->{id}) {
            $e = xPapers::Entry->get($h->{id});
        } else {
            $e = xPapers::Entry->new(id=>"%",title=>"dummy entry") unless $me->{__dummy};
        }
        if ($me->{cfg} and $me->{cfg}->{inject}) {
            $e->{$_} ||= $h->{$_} for keys %$h;
            #$e->{added} = $h->{added} if $h->{added};
            $e->{$_} = cdec($e->{$_}) for qw/foundSource/;
        }
        event('next','end');
        return $e;
    } else {
        $me->{finished} = 1;
    }
    event('next','end');
    return undef;
}

sub cdec {
    my $in = shift;
    #return $in if is_utf8($in);
    return decode("utf8",$in);
}

sub prepFilter {
    my ($me, $filter) = @_;
    $me->{where} = Rose::DB::Object::QueryBuilder::build_where_clause(
        db=>$me->db,
        query=>$filter,
        tables=>['main'],
        #['id','added','sites','deleted','draft','free','pro','published','online','pub_type'] 
        columns=>{main => [xPapers::Entry->meta->column_names]},
        classes=>{main=>'xPapers::Entry'},
        table_aliases=>0,
        query_is_sql=>0
        );
    if ($me->{interval} and $me->{interval} =~ /^\d+$/) {
        my $inter = $me->{interval};
        return ('','Period too long') unless $inter <= 200 or $me->{filterMode} eq 'advanced';
        $me->{where} .= " and added > date_sub(now(),interval $inter day)";
    }
    $me->{where} ||= "true";
    $me->{where} .= " and main.added >= '" . quote($me->{since}) . "'" if $me->{since};
    return $me->{where};
}

# in this mode, we only fill in a param for the basic filters
sub preparePureSQL {
    my ($me, $sql, $filters, $cfg) = @_;
    my $where = $me->prepFilter($filters);
    #print $where;
    #print $sql;
    $me->{sql_manual} = sprintf($sql,$where);
    $me->{cfg} = $cfg;
}

# in this mode we are given most sql clauses readymade
sub prepareSQL {
    my ($me,%args) = @_;

    $me->dbh->do("set time_zone = 'GMT'") if $args{useGMT};
    $me->{table} = xPapers::Entry->meta->table;
    $me->{$_} = $args{$_} for qw/extraSelect order offset limit having/;
    $me->{cfg}->{$_} = $args{$_} for qw/start limit order inject/;
    $me->prepFilter($args{filter}) if $args{filter};
    $me->{where} .= $args{where};
    $me->{joins} = $args{'join'};

    my $joins; 
    if ($args{in}) {
        $me->{joins} .= "join cats_me incme on (main.id = incme.eId and incme.cId)
                        join primary_ancestors incpa on (incpa.cId = incme.cId and incpa.aId=$args{in}) 
        "; 
    } 
    if ($args{multiAdd}) {
        $me->{joins} .= " left join $me->{table}_added on $me->{table}.id = $me->{table}_added.id";
        #$me->{table} = "$me->{table}_added";
        if ($args{jlist}) {
            my $jlist = quote($args{jlist});
            $me->{joins} .= "  
                     left join $me->{table}_journals on $me->{table}.source = $me->{table}_journals.name
                     left join $me->{table}_jlm on ($me->{table}_journals.id = jId and jlId='$jlist')";
            $me->{where} .= " and if ( $me->{table}.pub_type = 'journal', not isnull(jlId), 1)";
            $me->{where} .= " and if ( $me->{table}_added.source = 'archives', $me->{table}_added.extra in ( 
               select name from main_journals join main_jlm on main_journals.id = jId and jlId='$jlist' where archive
            ), 1)";
        } 
    } else {
        if ($args{jlist}) {
            my $jlist = quote($args{jlist});
            $me->{joins} .= "  
                     left join $me->{table}_journals on $me->{table}.source = $me->{table}_journals.name
                     left join $me->{table}_jlm on ($me->{table}_journals.id = jId and jlId='$jlist')";
            $me->{where} .= " and if ( $me->{table}.pub_type = 'journal', not isnull(jlId), 1)";
        } else { 
            #$me->{joins} = " "
        }
    }

    if ($args{areaUser}) {
        $args{areaUser} = quote($args{areaUser});
        $me->{joins} .= " left join cats_me on ($me->{table}.id = cats_me.eId) 
                          left join primary_ancestors on (cats_me.cId = primary_ancestors.cId)
                          left join areas_m on (areas_m.mId = '$args{areaUser}' and 
                                primary_ancestors.aId = areas_m.aId)"; 
        $me->{where} .= " and not isnull(areas_m.aId)";
    }
    $me->dbh->do("set time_zone = '$TIMEZONE'") if $args{useGMT};

}


sub prepare {
    my ($me, $cfg) = @_;
    return if $me->{prepared};
    $me->{cfg} = $cfg;
    $me->basicWhere;
    $me->{table} = xPapers::Entry->meta->table;
    $me->prepFilter($cfg->{filter}) if $cfg->{filter};
    my $where = $me->{where} || " true ";
    unless ($me->{advMode} eq 'fields') {
        $where .= " and if(published, date = 'forthcoming' or date >= '" . quote($me->{minYear}) . "',1)" if $me->{minYear};
        $where .= " and date <= '" . quote($me->{maxYear}) . "'" if $me->{maxYear};
        $where .= " and if(published, date = 'forthcoming' or date >= '" . quote($me->{from}) . "',1)" if $me->{from};
    }
    if ($me->{filterMode} eq "list") {
        $me->{joins} = "join cats_me on (main.id = cats_me.eId and cats_me.cId=" . $cfg->{list}->id . ")";
    } elsif ($me->{filterMode} eq "advanced") {
        my $ftf = $cfg->{union} ? $FT_FIELDS_R : ($cfg->{index} || $FT_FIELDS_S);
        my ($select,$m,$qs);
        $qs = "";

        if ($me->{advMode} eq 'fields') {
            
             my ($s_where,$s_select,$s_join) = $me->ftQuery(
                $me->{all},
                filters=>$cfg->{filter},
                exact =>$me->{exact},
                atleast => $me->{atleast},
                without => $me->{without},
                minYear => $me->{minYear},
                maxYear => $me->{maxYear},
                authors => $me->{authors},
                extended => $me->{extended},
                publication => $me->{publication},
                interval => $me->{interval}
             );   
             $where .= " and $s_where ";
             $select .= " $s_select ";
             $me->{joins} .= " $s_join ";


        } elsif ($me->{advMode} eq 'normal') {

             my $qi = "";
             if ($me->appendMSets) {
                $qi = "$me->{w_ezn} $me->{w_ezn2}";
             }
             $qi = $me->ftstrn("$qi $me->{w_ez}"); 

             my $bool = "";
             if ($cfg->{booleanOK}) {
                $bool = " in boolean mode" if $qi =~ /\"|\+|\*/;
             } else {
                $qi =~ s/"|\+|\*//g;
             }
             $qs = "(match (authors,title) against('$qi') + match($ftf) against ('$qi'))";

             $select = $cfg->{union} ? $FT_FIELDS_U : " round( $qs, 1 ) as relevance ";
             $where .= " and match (". ($cfg->{index} || $FT_FIELDS_S) .") against ('$qi'$bool)";
             if ($me->{w_ezn} =~ /\w/) {
                my $qi2 =  $me->ftstrn($me->{w_ezn});
                $where .= " and match(". ($cfg->{index} || $FT_FIELDS_S) . ") against('$qi2' in boolean mode)";
             }
             if ($me->{w_ezn2} =~ /\w/) {
                my $qi3 =  $me->ftstrn($me->{w_ezn2});
                $where .= " and match(". ($cfg->{index} || $FT_FIELDS_S) . ") against('$qi3' in boolean mode)";
             }
           
        } else {
            for my $k (qw/e g p n/) {

                next unless $me->{"w_$k"};
                my $qi = quote($me->{"w_$k"});
                $qi =~ s/&quot;/"/gi;
                $qs .= " + " if $qs;
                $qs .= "$WEIGHTS{$k} * ( match (title) against ('$qi' in boolean mode) 
                        + match ($ftf) against ('$qi' in boolean mode)  
                        )";
            }

            $m = " + match($ftf) against ('+(".quote(cjoin(' ',$me->{w_a})).")' in boolean mode)" if $me->{w_a};

            $select = $cfg->{union} ? $FT_FIELDS_U : " round( $qs$m, 1 ) as relevance ";

            my $qs2;
            if ($me->{w_a}) {
                $qs2 = cjoin(" +",$me->{w_a});
            } else {
                $qs2 .= " " . cjoin(" ", $me->{"w_$_"}) for qw/e g p/;
            }
            $where .= " and match (". ($cfg->{index} || $FT_FIELDS_S) .") against ('$qs2' in boolean mode)";
        }

        if ($cfg->{lowRelevance}) {
            $me->{joins} .= "left join cats_me on (main.id = cats_me.eId and cats_me.cId=$cfg->{lowRelevance})"; 
            $where .= " and isnull(cats_me.cId)";
            $me->{having} = "relevance < $me->{minRelevance}";
        } else {
            $me->{having} = ($me->{cfg}->{union} ? "($qs$m)" : "relevance") ." >= $me->{minRelevance}" if $me->{minRelevance};
            if ($cfg->{in}) {
                $me->{joins} .= "join cats_me on (main.id = cats_me.eId and cats_me.cId)
                                join ancestors pa on (pa.cId = cats_me.cId and pa.aId=$cfg->{in}) 
                "; 
            } elsif ($cfg->{notIn}) {
                $me->{joins} .= "left join cats_me on (main.id = cats_me.eId and cats_me.cId)
                                left join ancestors pa on (pa.cId = cats_me.cId and pa.aId=$cfg->{notIn}) 
                "; 
                $me->{having} .= " and " if $me->{having};
                $me->{having} .= " count(pa.cId)=0";
            }
        }
        #$me->{order} = 'relevance desc, date desc';
        $me->{extraSelect} = $select;

    } elsif ($me->{filterMode} eq 'authors') {
        my ($au_where,$au_join) = $me->authorQuery($me->{searchStr});
        $where .= " and $au_where";
        $me->{joins} .= " " . $au_join;
    } elsif ($me->{filterMode} eq 'user') {
        $me->{joins} .= "
        join main_authors on main_authors.eId=main.id
        join aliases on (aliases.uId= $me->{owner} and aliases.firstname=main_authors.firstname and aliases.lastname=main_authors.lastname)
        ";
    } elsif ($me->{filterMode} eq 'group') {
        $me->{joins} .= "
        join users on (main.authors like concat('%;',users.lastname,', ', users.firstname,'%'))
        join groups_m on (groups_m.gId='" .quote($me->{searchStr}) . "' and groups_m.uId = users.id)
        ";
    }

    $me->{where} = $where;

    #if ($cfg->{user}->{id}) {
    #    if (my $rl = $cfg->{user}->reads) {
    #        my $id = $rl->id;
    #        $me->{joins} .= " left join cats_me as rl on (rl.cId = $id and rl.eId=main.id)";  
    #        $me->{extraSelect} .= "," if $me->{extraSelect};
    #        $me->{extraSelect} .= "rl.eId as toRead";
    #    }
    #}

    if ($cfg->{exclusions}) {
        #use Data::Dumper;
        #print Dumper($ex);
        my $ex = $cfg->{exclusions};
        $me->{joins} .= " left join cats_me as ex on (ex.cId = $ex->{id} and ex.eId=main.id)";
        $me->{where} .= " and isnull(ex.eId)";
    }

    $me->{order} =  ($SORTER{$cfg->{sort}} ? $SORTER{$cfg->{sort}}->[1] : undef) unless $me->{order}; 
    $me->{prepared} = 1;

}

sub ftstrn {
    my ($me, $s) = @_;
    $s =~ s/&quot;/"/gi;
    # separate out the quoted strings
    my @quoted;
    while ($s =~ s/"([^"]*?)"//) { push @quoted, $1 }
    # deal with isms
    $s =~ s/(^|\W)([\w\-]+)(ism|ist|ists)(\s|$)/ $2ism $2ist $2ists /g;

    $s =~ s/(\w+)-(\w+)/"$1 $2"/g;
    $s = "$s " . join(" ", map {'"' . $_ . '"'} @quoted);
    return quote($s);
}

sub authorQuery {
    my ($me,$s,$strict,$year) = @_;

    my ($f,$i,$l,$s) = parseName2($s);

    my $where = "main_authors.lastname like '" . quote($l) . "'";

    if ($f) {
        $where .= " and main_authors.firstname like '" . quote($f);
        if ($i) {
            $where .= " $i";
        }
        # in strict mode, "David J. Chalmers" does not match "David Chalmers"
        if ($strict) {
        } else {
            $where =~ s/\.\s*$//;
            $where .= '%';
        }
        $where .= "'";
    }
    $where .= " and main_authors.year = '" . quote($year) . "'" if $year;
    $where .= " and not main.deleted";
    return ($where," join main_authors on main.id=main_authors.eId");
}

sub ftQuote {
    my $s = shift;
 
    # decode double quotes and <
    $s =~ s/&quot;/"/gi;
    $s =~ s/&lt;/</gi;

    $s =~ s/;/ /g;
    $s =~ s/(\w)-/$1 /g;

    $s = quote($s);

    # remove diacritics
    $s = rmDiacritics($s);

    return $s;   
}

sub ftQuery {
    my ($me,$s,%args) = @_;

    $s = ftQuote($s);

#    $s =~ s/\@abstract/\@author_abstract/g;

    #print "ft query: $s\n";
    return $s if ($args{test_sub});

#    unless (!$s or $s =~ /\&|\||\(|\+|(\b\-)|\~|\"|\(|\@/) {
#    }

    # sorting defaults to relevance
    my $sort = ";sort=extended:\@weight desc";

    if ($args{sort}) {
        if ($args{sort} eq 'viewings') {
            $sort = ";sort=extended:viewings_att desc";
        } elsif ($args{sort} eq 'firstAuthor') {
            $sort = ";sort=extended:authors_att asc";
        } elsif ($args{sort} eq 'added') {
            $sort = ";sort=extended:added_att desc";
        } elsif ($args{sort} eq 'pubYear') {
            $sort = ";sort=extended:date_att desc";
        }
    }

    my $att_filters ="";
    my $f = $args{filters};
    my $x = 0;
    while ($x < $#$f) {
        if ($f->[$x] eq 'pro') {
            $att_filters .= ";filter=pro_att,1";
            splice(@$f,$x,2);
        } elsif ($f->[$x] eq 'free') {
            $att_filters .= ";filter=free_att,1";
            splice(@$f,$x,2);
        } elsif ($f->[$x] eq 'online') {
            $att_filters .= ";filter=online_att,1";
            splice(@$f,$x,2);
        } elsif ($f->[$x] eq 'published') {
            $att_filters .= ";filter=published_att,1";
            splice(@$f,$x,2);
        } elsif ($f->[$x] eq '!deleted') {
            splice(@$f,$x,2);
        } else {
            $x+=2;
        }
    }

    if ($args{minYear} || $args{maxYear}) {
        my $min = ftQuote($args{minYear}) || 0;
        my $max = ftQuote($args{maxYear}) || 10000;
        $att_filters .= ";range=date_att,$min,$max";
    }

    if ($args{interval}) {
        my $l = time() - ($args{interval} * 24 * 60 * 60);
        my $max = time() + 100000000;
        $att_filters .= ";range=added_att,$l,$max";
    }

    if ($args{exact}) {
        $s .= ' "' . ftQuote($args{exact}) . '"';
    }

    if ($args{atleast}) {
        my $t = $args{atleast};
        $t =~ s/[\r\n]+/ /sg;
        $s .= 
            ' (' . 
            join("|",
                map { ftQuote($_) }
                split(/\s+/,$t)
            ) .
            ')';

    }

    if ($args{without}) {
        my $t = $args{without};
        $t =~ s/[\r\n]+/ /sg;
        $s .= 
            ' -(' . 
            join("|",
                map { ftQuote($_) }
                split(/\s+/,$t)
            ) .
            ')';
    }

    if ($args{extended}) {
        $s .= " (" . ftQuote($args{extended}) . ")";
    }

    if ($args{authors}) {
        $s .= " \@authors " . ftQuote($args{authors});
    }

    if ($args{publication}) {
        $s .= " \@source " . ftQuote($args{publication});
    }


    # basic fulltext match
    # field order in sphinx conf is authors, title, descriptors, abstract

    my $mode = ( $s =~ $SPHINX_OPRE ) ? 'extended2' : 'any';
    $mode = 'any' if $args{force_mode_any};

    my $limit = $args{limit} || 1000;
    my $sphinx = "query='$s$sort$att_filters;mode=$mode;maxmatches=$limit;ranker=proximity_bm25;limit=$limit;index=main_idx,main_idx_stemmed;indexweights=main_idx,4,main_idx_stemmed,1;weights=3,2,1,1'";


#    return ($sphinx, " round(sphinx_main.weight/1000,1) as relevance "," join sphinx_main on sphinx_main.id=main.serial");

    
    # returns: where part, select part, join part
    return ($sphinx, " round(sphinx_main.weight/10,1) as relevance "," join sphinx_main on sphinx_main.id=main.serial");
#    $s =~ s/(\b\w)/+$1/g;
#    return ($sphinx, " sphinx_main.weight * if(match(authors,title) against('$s' in boolean mode),2,1) as relevance "," join sphinx_main on sphinx_main.id=main.serial");

}

sub basicWhere {
    my ($me,$site) = @_;
    return;
}
=old absicwhere
    $site ||= 'pp';
    my $where = "not(deleted=1)";
    if ($me->{interval} and $me->{interval} =~ /^\d+$/) {
        my $inter = $me->{interval};
        return ('','Period too long') unless $inter <= 200 or $me->{filterMode} eq 'advanced';
        $where .= " and added > date_sub(now(),interval $inter day)";
    }
    #$where .= " and free=1" if $me->{freeOnly} eq 'on';
    #$where .= " and published=1" if $me->{publishedOnly} eq 'on';
    $where .= " and draft=1" if $me->{draftsOnly};
    $where .= " and main.added >= '" . quote($me->{since}) . "'" if $me->{since};
    $me->{where} = $where;
    return ($where,'');
}
=cut

sub pt {
    my $in = shift;
    $in =~ s/\*(\W|$)/\%$1/g;
    return quote($in);
}

sub tokenize {
    my @r;
    while (my $s = shift) {
       push @r, split(/\s+/,$s); 
    }
    return @r;
}

sub cjoin {
    my ($sep,$a) = @_;
    my $r;
    for my $q ($a =~ /\((.+?)\)/g) {
        my $nq = $q;
        $nq =~ s/[\s\n\r]+/__S__/g;
        $a =~ s/\Q$q\E/$nq/;
    }
    for my $q ($a =~ /"(.+?)"/g) {
        my $nq = $q;
        $nq =~ s/[\s\n\r]/__S__/g;
        $a =~ s/\Q$q\E/$nq/;
    }
    for my $w ( split(/[\s\n\r]/,$a) ) {
        next unless $w =~ /\w/;
        $w =~ s/__S__/ /g;
        $r .= $sep; # if $r;
        $r .= quote($w);
    }
    return $r;
}


sub test {

    my $q = xPapers::Query->new(id=>274)->load;
    print $q->mode;

}
1;
__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




