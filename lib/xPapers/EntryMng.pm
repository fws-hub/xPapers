package xPapers::EntryMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::Util qw/quote sameEntry/;
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;
use DateTime;

my $OLDIFY_MODE = 0;

sub object_class { 'xPapers::Entry' }

__PACKAGE__->make_manager_methods('main');

sub oldifyMode {
    my ($me, $mode) = @_;
    $OLDIFY_MODE = $mode if defined $mode;
    return $OLDIFY_MODE;
}

sub fuzzyMatch {
	my ($me, $e, $fuzzLimit, $excludeId) = @_;
    $fuzzLimit ||= 20; 
    my $exc = $excludeId ? "not deleted and not id='$e->{id}'" : "true";
    my $where = quote(join(' ',$e->getAuthors)) . " " . quote($e->{title});
    #my $slice = $after_id ? " and id > '$after_id'" : ''; 
    my $res = $me->get_objects (
        clauses=> ["$exc and match(authors,title) against('$where')"],
        limit => $fuzzLimit,
        offset=>0
    );
    return @$res;
}

sub fuzzyFind {
    my ($me, $e, $fuzzLimit,$loose) = @_;
    my @m = $me->fuzzyMatch($e, $fuzzLimit, $loose);
    for (@m) {
        if (sameEntry($e,$_,undef,$loose)) {
            return $_;
        }
    }
    return undef;
}

sub addAdded {
    my ($me,$e,$fid) = @_;
    my $st = srcmap($e->{db_src});
    die "No id for entry " . $e->toString unless $e->id;
    my $extra = "";
#    my $minYear = DateTime->now(time_zone=>$TIMEZONE)->subtract(years=>1)->year;
    my $minYear = DateTime->now(time_zone=>$TIMEZONE)->year;
    if ($st eq 'journals') {
        return unless (
            (
            $e->{date} =~ /^\d\d\d\d$/ and 
            $e->{date} >= $minYear
            ) or
            $e->{date} eq 'forthcoming'
        );
        $extra = quote($e->{source});
    } elsif ($st eq 'archives') {
        $extra = quote($e->{source});
    }
    my $q = "insert into main_added set id='" . quote($fid || $e->id) .  "'," .
            "time=now(),source='$st'," .
            "rank='" . $xPapers::Conf::SOURCE_TYPE_ORDER{$st}."'," .
            "extra='$extra'";
    $e->dbh->do($q);
}

sub addXAdded {
    my ($me,$orig,$new) = @_;
    my $st = srcmap($new->{db_src});
    # check for new source type
    my $q = $new->dbh->prepare("select * from main_added where id=? and source = ?");
    $q->execute($orig->id,$st);
    my $h = $q->fetchrow_hashref;
    if ($h && $h->{id}) { 
        # if already there, but journals and upgraded status, inc added time
        if ($new->{db_src} eq 'direct' and $new->betterThan($orig) and $new->toString ne $orig->toString) {
            my $extra = $st eq 'journals' ? ", extra='".quote($new->{source}) . "'" : "";
            $new->dbh->do("update main_added set time=now()$extra where id='$h->{id}' and source='$st'");
        }
    } else {
        #$me->addAdded($new,$orig->id);
    }

}



sub srcmap {
    my $in = shift;
    return (
            $in eq 'direct' ? 'journals' :
            $in eq 'user' ? 'local' :
            $in eq 'web' ? 'web' :
            $in eq 'archives' ? 'archives' :
            'other'
        );
}


sub addOrUpdate {
    my ($me, $e, $keyp) = @_;

    my @m = $me->fuzzyMatch($e,12);
    my $found = 0;
    my @mod;

    $e->added(DateTime->now->subtract(days=>30)) if $me->oldifyMode;

    #print "\n\ncheck " . $e->toString . "\n";
    for my $m (@m) {
        #print "comp " . $m->toString . "\n";

        if (sameEntry($m,$e)) {
            #print "mpub: $m->{published}\n";
            #print "epub: $e->{published}\n";
            #print "BT: " . $e->betterThan($m);
            $m->completeWith($e);
            #print "after: " . $m->toString . "\n";
            $m->save;
            $found = 1;
            #this is deprecated
            push @mod,$m;
        }
    }
    #print "found:$found\n";
    return @mod if $found;

    $e->setKey($keyp);
    $e->save;
    return ();
}

sub addOrDiff {
    my ($me, $e, $uId, $undelete) = @_;

    my @m = $me->fuzzyMatch($e,12);
    my $found = 0;
    my @mod;

    #print "AddOrDiff: " . $e->toString . "\n";

    for my $m (@m) {
        if (sameEntry($m,$e)) {
            $found = 1;
            my $diff = xPapers::Diff->new;
            $diff->before($m);
            if ($m->{deleted}) {
                if ($undelete) {
                    $m->deleted(0);
                } else {
                    next;
                }
            }

            #warn "match: $m->{id} " . $m->toString;
            $m->completeWith($e);
            #warn "\n\nDELETED\n\n" if $m->{deleted};

            $diff->after($m);
            $diff->uId($uId||0);
            $diff->compute;

            #use Data::Dumper;
            #print Dumper($diff->{diff});

            $diff->accept unless $diff->is_null;
            push @mod,$diff;
        }
    }

    return @mod if $found;

    $e->added(DateTime->now->subtract(days=>30)) if $me->oldifyMode;

    my $diff = xPapers::Diff->new;
    $diff->uId($uId||0);
    $diff->create_object($e); 
    $diff->accept;
    $e = $diff->object;
    return ($diff);
}

sub diffStatus {
    my ($me,@list) = @_;
    if (!@list) {
        return "Found deleted";
    } elsif (grep {$_->{type} eq 'update'} @list) {
        return "Found"; 
    } elsif (grep {$_->{type} eq 'add'} @list) {
        return "Added";
    } else {
        return "Unknown (?!)";
    }
}

sub similar {
    my ($me, $e, $q) = @_;
    $q ||= [];
    push @$q, '!deleted'=>1;
    push @$q, '!id'=>$e->id;
    #push @$q, '!main.id'=>$e->id;
    #use Data::Dumper;
    #print Dumper($q);
    my $t = quote(HTML::Entities::decode_entities(
            ($e->title . " " . $e->descriptors . " ") x 3 . " " . 
            join(" ", $e->getAuthors) . " " . 
            (length($e->author_abstract) >= 40 ? $e->author_abstract : "")
            ));
    $t =~ s/\%/ /g; # do this not to screw the sprintf in preparePureSQL
    my $qu = xPapers::Query->new;
    my $m = "round(match $INDEXES{1} against('$t'),1)";
    $qu->preparePureSQL(
        "select id, $m as relevance from main where $m >= 1 and %s order by relevance desc",
        $q,
        {limit=>10}
    );
    $qu->execute;
    return $qu;
}

sub similar_sphinx {
    my ($me, $e, $q) = @_;
    $q ||= [];
    my $restrict = "not(deleted) and not(main.id='" . quote($e->id) . "')";
    #push @$q, '!main.id'=>$e->id;
    #use Data::Dumper;
    #print Dumper($q);
    my $abs = "";
    if (length($e->author_abstract) >= 40) {
        my @words = split(/\s+/,$e->author_abstract);
        $abs = " bogusbogus " . join(" ", @words[0..16]);
    }
    my $t = quote(HTML::Entities::decode_entities(
            ($e->title . " " . $e->descriptors . " ") x 2 . " bogusbogus " . 
            join(" ", $e->getAuthors) . $abs
            ));
    $t =~ s/\%/ /g; # do this not to screw the sprintf in preparePureSQL
    my $qu = xPapers::Query->new;
    my ($where,$what,$join) = xPapers::Query->ftQuery($t,force_mode_any=>1,limit=>10);
    $qu->preparePureSQL(
        "select main.id, $what from main $join where $where and $restrict and %s ",
        $q,
        {limit=>10}
    );
    #print $qu->sql;
    $qu->execute;
    return $qu;
}

sub authorExists {
    my ($me,$name) = @_;
    return $me->countWorks($name);
}

sub count_all {
    my ($me) = @_;
    return $me->get_objects_count(query=>['!deleted'=>1]);
}

sub count_where {
    my ($me,$where) = @_;
    return $me->get_objects_count(query=>['!deleted'=>1],clauses=>[$where]);
}

sub findWhere {
    my ($me,$what,$where) = @_;
    $where ||= 'true';
    my $r = xPapers::DB->exec("select $what as v from main where $where");
    return $r->fetchrow_hashref->{v};
}

sub countWorks {
    my ($me,$name) = @_;
    my $comma = ($name =~ /,/ ? "" : ',');
    my $where .= " name like '" . quote($name) . "$comma%'";
    my $q = "select count(*) as nb from main_authors where $where";
    my $db = xPapers::DB->new;
    my $u =$db->dbh->prepare($q);
    $u->execute;
    my $h = $u->fetchrow_hashref;
    return $h->{nb};
}




1;
__END__

=head1 NAME

xPapers::EntryMng

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 METHODS

=head2 addAdded 



=head2 addOrDiff 



=head2 addOrUpdate 



=head2 addXAdded 



=head2 authorExists 



=head2 countWorks 



=head2 count_all 



=head2 count_where 



=head2 diffStatus 



=head2 findWhere 



=head2 fuzzyFind 



=head2 fuzzyMatch 



=head2 object_class 



=head2 oldifyMode 



=head2 similar 



=head2 similar_sphinx 



=head2 srcmap 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



