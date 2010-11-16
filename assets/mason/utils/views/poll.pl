<%method header>
%#  we need to prime the datapicker class with this...
    <div style="display:none">
    <& "../../bits/datepicker.html",field=>"__dummy"&>
    </div>

    <script type="text/javascript">
    function validateObjectForm(f) {
        if (!f['cId'].value || f['cId'].value == '0') {
           if (!confirm("You have not associated this poll with a category.\nUnless you have been instructed by the administrator to do so, probably no one will find it. \nAre you sure you want to continue?")) {
                return false;

           } {
                return true;
           }
        }
        return true;
    }
    </script>
</%method>

<%perl>

# standard object loading code
my $po;
if ($ARGS{id} and !$ARGS{__obj}) {
    $po = xPapers::Polls::Poll->get($ARGS{id});
    jserror("Poll not found") unless $po;
} elsif ($ARGS{__obj}) {
    $po = $ARGS{__obj};
} else {
    $po = xPapers::Polls::Poll->new;
}

jserror("Not allowed") unless !$po->{id} or $po->owner == $user->id or $SECURE;

# DELETE
if ($ARGS{c} eq 'delete') {
    
    $po->delete;

# SHOW
} elsif ($ARGS{c} eq 'show') {

    </%perl>
    <table>
    <tr>
    <td valign="top">
    Name:
    </td>
    <td>
    <a href="/polls/<%$po->id%>"><b><%$po->name%></b></a>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Topic:
    </td>
    <td>
    <% $po->cId ? $rend->renderCatC(xPapers::Cat->get($po->cId)) : "<em>None selected</em>" %>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Opens on:
    </td>
    <td>
    <%$rend->renderTime($po->open)%>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Closes on:
    </td>
    <td>
    <%$rend->renderTime($po->close)%>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Description:
    </td>
    <td>
    <%$po->description%>
    </td>
    </tr>

    <tr>
    <td valign="top">Questions</td>
    <td>
    <%perl>
        my $questions = $po->questions;
        print num($#$questions+1,"question");
        print " (randomized)" if $po->randomize;
    </%perl>
    <br>
    <a href="/polls/editq.pl?poId=<%$po->{id}%>">View / edit questions</a> | <a href="/polls/answer.pl?poId=<%$po->id%>">Take this poll</a> |
    <a href="/polls/results.pl?poId=<%$po->{id}%>">View results</a>
    </td>
    </tr>

    </table>

    <%perl>
       
# EDIT
} elsif ($ARGS{c} eq 'edit') {

    </%perl>


    <table>
    <tr>
    <td valign="top">
    Name:
    </td>
    <td>
     <input type="text" name="name" width="50" value="<%dquote($po->name)%>"><br>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Topic
    </td>
    <td>
    <script type="text/javascript">
    function setcup(id) {
        $('cId').value=id;
        injectCat(id,'selectedCat','');
    }
%   $m->comp("../../search/catcomplete.js",%ARGS, action=>"setcup(%s)",suffix=>"i");
    </script>

    <span id='selectedCat'><% $po->cId ? $rend->renderCatC(xPapers::Cat->get($po->cId)) : "<em>None selected</em>" %></span><br>
    <div class='catac' style='display:block;padding-bottom:0px;padding-left:0px;'> 
        <input style='border:1px solid #eee;width:190px;' id="catacpi"  name="catacpi" type="text" onfocus="if(this.value == 'Find a category by name') { this.value='' }" value="Find a category by name"> 
        <input id="cId" name="cId" type="hidden" value="<%$po->cId%>">
        <input id="add-idpi" name="add-idpi" type="hidden"> 
        <div class="yui-skin-sam" id="auc-conpi" style="width:420px"></div>
    </div>

    </td>
    </tr>

    <tr>
    <td valign="top">
    Opens on:
    </td>
    <td>
     <& ../../bits/datepicker.html, field=>"open",value=>($po->open ? $po->open : "") &><br>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Closes on:
    </td>
    <td>
     <& ../../bits/datepicker.html, field=>"close",value=>($po->close ? $po->close : "") &> 
    </td>
    </tr>

    <tr>
    <td valign="top">
    Description:
    </td>
    <td>
    <textarea cols="50" rows="3" name="description"><%$po->description%></textarea><p>
    </td>
    </tr>

    <tr>
    <td valign="top">
    Other options:
    </td>
    <td>
    <input type="checkbox" name="randomize" <%$po->randomize?"checked":""%>> randomize questions
    </td>
    </tr>

    </table>

    <%perl>

# SAVE
} elsif ($ARGS{c} eq 'save') {

    error("Not allowed") unless !($po->owner) or $po->owner == $user->{id};
    $po->loadUserFields(\%ARGS);
    # put timezone on dates, put in proper format
    my %dates;
    for (qw/open close/) {
        my ($year,$month,$day) = ($ARGS{$_} =~ /(\d\d\d\d)-(\d\d)-(\d\d)/);
        jserror("Invalid date: $ARGS{$_}") unless $year; 
        $month =~ s/^0//;
        $day =~ s/^0//;
        my $d = DateTime->new(
            time_zone=>$rend->{tz_offset}, # we get that from renderer because it knows the user's timezone 
            year=>$year,
            month=>$month,
            day=>$day
        );
        # now convert to server timezone
        $d->set_time_zone($TIMEZONE);
        #$root->elog("val:: " . $d->iso8601);
        #my $sth = $root->dbh->prepare('select @@session.time_zone');
        #$sth->execute;
        #jserror(Dumper($sth->fetchrow_hashref->{'@@session.time_zone'}));
        jserror("Invalid date: $ARGS{$_}") unless $d;
        $po->$_($d->iso8601);
        $dates{$_} = $d;
    }

    $po->owner($user->{id});

    jserror("Close date must be in the future.") unless laterThan($dates{close},$TIME);
    jserror("Open date must be before close date.") unless laterThan($dates{close},$dates{open});
    jserror("You must specify a name.") unless $po->name;
    jserror("You must provide a description.") unless $po->description;

    $po->save;

    $m->comp("poll.pl",__obj=>$po,c=>'show');
}

$m->notes("oId",$po->id) if $po;

</%perl>


