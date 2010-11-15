%unless ($ARGS{noheader}) {
<& ../header.html, %ARGS,subtitle=>"Changelog" &>
<& style.html &>
<& scripts.html &>
%}
<%perl>
return unless $SECURE;
use Storable qw/dclone/;
$rend->{noOptions} = 0;
$rend->{foundOptions} = undef;
$rend->prepTpl;
$ARGS{class} ||= 'entries';
my $class;
if ($ARGS{oId} and !$ARGS{class}) {
    #hmm
} else {
    $class = $CM{$ARGS{class}};
}
return unless $class;



my $q = [
        'class'=>$class,
        status=>{ge => 10 },
    ]; 
push @$q, "uId" => $ARGS{uId} if $ARGS{uId};
push @$q, "!checked" => 1 unless $ARGS{all};
push @$q, oId => $ARGS{oId} if $ARGS{oId};

if ($ARGS{checkBefore}) {
    my @q2 = @$q;
    push @q2, updated=>{le=>$ARGS{checkBefore}};
    my $diffs = xPapers::D->get_objects( query=>\@q2 );
    for (@$diffs) {
        $_->checked(1);
        $_->save;
    }
    print "<span class='msgOK'>Edits marked as checked prior to $ARGS{checkBefore}</span>";
}

my $x;
if ($ARGS{uId}) {
    my $u = xPapers::User->get($ARGS{uId});
    $x = " for  " . $rend->renderUserC($u);
}
print gh("Changelog$x"); 
</%perl>
<select id='class' onchange="window.location='history.pl?class=' + $F('class')">
% print opt($_,$_,$ARGS{class}) for keys %CM;
</select>
<p>
<%perl>
$ARGS{checked} = 1 unless exists $ARGS{checked};
my $diffs = xPapers::D->get_objects(
    query=>$q,
    sort_by=>'oId,created desc',
    );

my $cid = undef;
my $final = {};
foreach my $d (@$diffs) {
   # $m->comp("../bits/gendiff.html",diff=>$d);
    # reach end of series, print and start new series
    if (!$d->object) {
        print "object not found for $d->{id}\n";
        next;
    }
    if ($cid ne $d->oId) {
        #print "new seris<br>"; 
        finish($final,$ARGS{uId}) if $cid;

        # start new series
        $cid = $d->oId;
        $final->{series} = $m->scomp("../bits/gendiff.html",diff=>$d,compact=>$ARGS{uId}, startTime=>$d->updated,endTime=>$d->updated);
        $final->{e} = $d->object;
        if ($class eq 'xPapers::Cat') { $final->{e}->memberships; }
        $final->{cumul} = fake($d);
        $final->{type} = $d->type;
        $final->{count} = 1;
        $final->{users} = [];
        $final->{endTime} = $d->updated;
        $final->{startTime} = $d->updated;
    } 
    # one more in series, cumulate 
    else {
        #print "continue seris<br>";
        $final->{series} .= $m->scomp("../bits/gendiff.html",diff=>$d,compact=>$ARGS{uId},deleted=>$final->{type} eq 'delete', startTime=>$d->updated,endTime=>$final->{endTime});

        # restored < update -> update
        # update < add -> add
        # add < delete -> restored
        # delete < add -> delete
        # delete < update -> delete
        if ($d->type eq 'update' and $final->{type} eq 'restore') { $final->{type} = 'update' }
        elsif ($d->type eq 'add' and $final->{type} eq 'update') { $final->{type} = 'add' }
        elsif ($d->type eq 'delete' and $final->{type} eq 'add') { $final->{type} = 'restore' }
        $final->{startTime} = $d->updated;
        $final->{count}++;
#        unless ($d->type eq 'delete') {
            #print "<pre>" . Dumper($final->{cumul}->{diff}) . "</pre>";
            #print "<pre>" . Dumper(fake($d)->{diff}) . "</pre>";
            #print "<hr>";
            #print $d->type;
            #print "<hr>";
            $final->{cumul} = fake($d)->followedBy($final->{cumul}); 
            #print "<pre>" . Dumper($final->{cumul}->{diff}) . "</pre>";
#        }
    }
    push @{$final->{users}}, $rend->renderUserC($d->user,1);

#$m->comp("../bits/gendiff.html",diff=>$_) for @$diffs;

}
if ($final->{e}) {
    finish($final,$ARGS{uId});
} else {
    print "There are currently no unchecked edits for this class.";
}

print <<END;
<div class="centered buttons">
<input type="button" value="Mark all as checked" onclick="window.location='history.pl?checkBefore=$TIME&class=$ARGS{class}'">
</div>
END

sub fake {
    my $d = shift;
    return $d if $d->type eq 'update' or $d->type eq 'delete';
    if ($d->type eq 'add') {
        my $nd = xPapers::Diff->new;
        my $void = $d->class->new;
        $void->id($d->oId);
        $nd->before($void);
        $nd->after($d->object_back_then);
        #print "<pre>$d->{id}$d->{type}/$d->{oId}/\n" . Dumper($d->object_back_then->as_tree) . "</pre>";
        $nd->compute;
        #print "<pre>" . Dumper($nd->{diff}) . "</pre>";
        return $nd;
    }
    return undef;
}

sub finish {
    my ($final, $uId) = @_;
    my $summary;
    my $class = $final->{e}->meta->class;
    $summary = ( $final->{class} eq 'xPapers::Entry' ? $rend->renderEntry($final->{e}) : $rend->renderObject($final->{e}) ) . "<p>";
    #print "<pre>" . Dumper($final->{cumul}) . "</pre>" if $final->{e}->{id} eq 'BOUQLI';
    $summary .= $m->scomp("../bits/innerdiff.html",diff=>$final->{cumul});
    my $time = $final->{endTime}->ymd . "T" . $final->{endTime}->hms;
    my $stime = $final->{startTime}->ymd . "T" . $final->{startTime}->hms;

    my $css = ($final->{count} > 3 ? "busy" : "");
    my $toggle = $m->scomp("../bits/toggler.html",target=>'sdiff-'.$final->{e}->id,text=>" <span class='$css'>".num($final->{count}, "edit") . "</span>");
    my $users;
    $users = "Users: " . join(", ", @{$final->{users}}) unless $uId;
    my $display = ($uId ? "table-row" : "none");
    print <<END;
    <table class='diffSeries' id='diff-$final->{e}->{id}'>
        <tr>
        <td class='diffSeriesCtl'>
        <span class='diffSeriesType'>$final->{type}</span><br>
        $toggle<br>
        <br><span class='hint'>object #$final->{e}->{id}</span>
        </td>
        <td class='diffSeriesSummary'>
            <div style="float:right;text-align:right">
            <input type='button' onclick='rollback("$final->{e}->{id}","$stime","$time","$class",1)' value="rollback all edits"><br>
            <br>
            <input type='button' style='background-color:#efe' onclick='markChecked("$final->{e}->{id}","$stime","$time","$class")' value="checked">
            </div>
        $summary
        <p>
        $users
        </td>
        </tr>
        <tr id='sdiff-$final->{e}->{id}' style='display:$display'>
        <td></td>
        <td class='diffSeriesDetails'>
            $final->{series}
        </td>
        </tr>
    </table>
END
}


</%perl>
