package xPapers::LCRangeMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::LCRange' }

__PACKAGE__->make_manager_methods('lc_ranges');

our $cache;

sub match {
    my $me = shift;
    my $item = shift;
    my %p = @_;
    $me->prep_cache unless $cache;
    for my $r (@{$cache->{$item->{cn_class}}}) {
        #print "check $item->{cn_class} $item->{cn_num} matched $r->{lc_class} $r->{start}-$r->{end}, $r->{subrange} - $r->{cId}\n" if $r->{start} =~ /418/;
        if (
            (!$p{cId} or $r->{cId}) &&
            ($r->{start} <= $item->{cn_num}) && 
            ($r->{end} >= $item->{cn_num} or $item->{cn_num} =~ /^$r->{end}(\.|$)/) && 
            ($r->{subrange} !~ /[\w\d]/ or $item->{cn_alpha} =~ /^$r->{subrange}/)) {
            #print "$item->{cn_class}$item->{cn_num} matched $r->{lc_class}$r->{start}-$r->{end}\n";
            $r->{hits}++;
            return $r;
        }
    }
    return undef;
}

sub is_excluded {
    my ($me, $item, $keywords) = @_;
    $me->prep_cache() unless $cache;    

    my @mk;
    for my $k (@$keywords) {
        for my $f (qw/title descriptors/) {
            push @mk, $k if $item->{$f} =~ /(\W|^)$k/i;
        }
    }

    unless ($item->{cn_class}) {
        return $me->verdict(\@mk, 1, undef);
    }

    my $r = $me->match($item);

#    for my $k2 (qw/conscious unconscious/) {
    for my $k2 (@{$r->{_xwords}}) {
        for my $f (qw/title/) {
             push @mk, $k2 if $item->{$f} =~ /(\W|^)$k2/i;
        }
    }
    return $me->verdict(
    \@mk, (
        # range found
        $r ? $r->{exclude} : 
        # range not found
        (
            $item->{cn_class} ? 2 : 1 #2 required if CN, 1 otherwise
        )
    ) , $r);
}

sub verdict {
    my ($me, $keywords, $cond, $range) = @_;
    $cond = 2 unless defined $cond;
    return (((($#$keywords+1) < $cond) ? 1 : 0),$cond,$keywords, $range);
}

#__PACKAGE__->prep_cache;
sub prep_cache {
    my ($me) = @_; 
    my $l = $me->get_objects(sort_by=>['lc_class asc','start desc','end-start asc','subrange desc']);
    $cache = {};
    for (@$l) {
        $_->{_xwords} = [split(/\s*;\s*/,$_->{xwords})];
        #print "$_->{lc_class}, $_->{start} - $_->{end}, $_->{subrange}, $_->{cId}\n";
        $cache->{$_->{lc_class}} = [] unless $cache->{$_->{lc_class}};
        push @{$cache->{$_->{lc_class}}}, $_;
    }
}

sub search_list {
    my ($me) = @_;
    my $l = $me->get_objects(sort_by=>['lc_class','subrange','end-start']);
    my %list;
    # check if matched in list. if so, skip. otherwise, add.
}

sub classes {
    my $me = shift;
    my $r = xPapers::DB->exec("select distinct lc_class from lc_ranges");
    my @r;
    while (my $h = $r->fetchrow_hashref) {
        push @r,$h->{lc_class};
    }
    @r;
}

sub class_behavior {
    my $me = shift;
    my $class = shift;
    #print "Check $class\n";
    my $r = xPapers::DB->exec("select description,sum(end-start) as breadth,lc_class,min(exclude)+max(exclude)/2 as score from lc_ranges where lc_class=? group by lc_class",$class);
    my $row = $r->fetchrow_hashref;
    return undef unless $row;
    my $score = $row->{score};
    return undef unless $score;
    print "SETS $class: score = $score\n";
    if ($score == 0 and (length($class) > 1 or $r->{breadth} >= 5000)) {
        return "complete";
    } elsif ($score < 4) {
        return "partial";
    } else {
        return undef;
    }
}

1;
__END__

=head1 NAME

xPapers::LCRangeMng



=head1 METHODS

=head2 class_behavior 



=head2 classes 



=head2 is_excluded 



=head2 match 



=head2 object_class 



=head2 prep_cache 



=head2 search_list 



=head2 verdict 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



