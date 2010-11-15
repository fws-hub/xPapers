
<%method header>
    <script type="text/javascript">
    function adjustOptions(el,id) {
        var opt = new Hash();
        opt.set("dichotomy-"+id,false);
        opt.set("yesno-"+id,false);
        opt.set("multichoice-"+id,false);
        opt.set("showOther-"+id,false);
        if (el.value != 'open') 
            opt.set(el.value+"-"+id,true);
        if (el.value == 'dichotomy') {
            opt.set("multichoice-"+id,true);
        }
        if (el.value != 'open' && el.value != 'multichoice') {
            opt.set("showOther-"+id,true);
        }
        showSelected(opt);
    }
    function validateObjectForm(f) {
        return true;
    }
    </script>
</%method>


<%perl>

$NOFOOT = 1;
my $qu;
my $poll;
if ($ARGS{id} and !$ARGS{__obj}) {
    $qu = xPapers::Polls::Question->get($ARGS{id});
    jserror("Question not found") unless $qu;
    $poll = $qu->poll;
} elsif ($ARGS{__obj}) {
    $qu = $ARGS{__obj};
} else {
    $qu = xPapers::Polls::Question->new;
}

if ($ARGS{poId}) {
    $poll = xPapers::Polls::Poll->get($ARGS{poId});
}
jserror("Not allowed") unless !$poll or $poll->owner == $user->id;

# DELETE
if ($ARGS{c} eq 'delete') {
    
    $qu->delete;

# SHOW
} elsif ($ARGS{c} eq 'show') {

    $m->notes("objlist_userank",1);
    </%perl>
    <div style="float:right">
        <img src="<% $s->rawFile( '/icons/go-up.png' ) %>" onclick="moveUp(<%$qu->id%>)"><br>
        <img src="<% $s->rawFile( '/icons/go-down.png' ) %>" onclick="moveDown(<%$qu->id%>)"><br>
    </div>
    <%perl>
  $m->comp("../../polls/ask.pl",__obj=>$qu);

# EDIT    
} elsif ($ARGS{c} eq 'edit') {

    my @answers = map { $_->value } grep { !$_->other } $qu->answers;
    my @others =  map { $_->value } grep { $_->other } $qu->answers;
    my @yesno_others = @others;

    unless ($qu->id) {
        push @others, ("Accept both", "Reject both", "Reject the question", "Agnostic", "Ignorant", "No fact of the matter", "Undecided");
        push @yesno_others, ("Reject the question", "Agnostic", "Ignorant", "No fact of the matter", "Undecided");
    }

    </%perl>

    <script type="text/javascript">
        YAHOO.util.Event.onDOMReady(function() {
            adjustOptions($('qtype<%$qu->id%>'),<%$qu->id||"''"%>);
        });
    </script>

    <table>
    <tr>
    <td width="120" valign="top">Question type:</td>
    <td>
    <select id="qtype<%$qu->id%>" name="type" onchange="adjustOptions(this,<%$qu->id||"''"%>)">
    <%perl>
        print opt($_,$_,$qu->type) for qw/yesno dichotomy multichoice open/;
    </%perl>
    </select>
    </td>
    </tr>
    <tr>
    <td width="120" valign="top">Question text:</td>
    <td>
    <textarea cols="50" rows="3" name="question"><%$qu->question%></textarea><p>
    </td>
    </tr>

    <tr id='showOther-<%$qu->id%>' style='display:none'>
    <td>
        Other options:
    </td>
    <td>
        <input type="checkbox" name="showOtherOptions" <%$qu->showOtherOptions?'checked':''%>> show other option choices ("other" will remain a choice)
    </td>
    </tr>

    <tr id='multichoice-<%$qu->id%>' style='display:none'>
    <td width="120" valign="top">Primary answer choices:</td>
    <td>
    <% mkDynList("answers",\@answers,"<div>_CONTENT_</div>","div", sub {
        my $val = shift;
        return "_OPTIONS_<input id=\"answers_COUNT_in\" class=\"namefield\" type=\"text\" style=\"width:340px\" name=\"answers_COUNT_\" value=\"$val\">",
    }, "")
    %>
    <input type="button" onclick="window.addToList('answers')" value="Add answer">
    </td>
    </tr>

    <tr id='dichotomy-<%$qu->id%>' style='display:none'>
    <td valign="top">Other answers allowed:</td>
    <td>
    <% mkDynList("others",\@others,"<div>_CONTENT_</div>","div", sub {
        my $val = shift;
        return "_OPTIONS_<input id=\"others_COUNT_in\" class=\"namefield\" type=\"text\" style=\"width:340px\" name=\"others_COUNT_\" value=\"$val\">",
    }, "")
    %>
    <input type="button" onclick="window.addToList('others')" value="Add other answer">
    </td>
    </tr>

    <tr id='yesno-<%$qu->id%>' style='display:none'>
    <td valign="top">Other answers allowed besides yes/no:</td>
    <td>
    <% mkDynList("yesno-others",\@yesno_others,"<div>_CONTENT_</div>","div", sub {
        my $val = shift;
        return "_OPTIONS_<input id=\"yesno-others_COUNT_in\" class=\"namefield\" type=\"text\" style=\"width:340px\" name=\"yesno-others_COUNT_\" value=\"$val\">",
    }, "")
    %>
    <input type="button" onclick="window.addToList('yesno-others')" value="Add other answer">
    </td>
    </tr>

    </table>

    <%perl>

# SAVE
} elsif ($ARGS{c} eq 'save') {

    my $origId = $qu->{id};
    $qu->loadUserFields(\%ARGS);
    jserror("You must specify the question's text.") unless $qu->question;

    # determine rank for new questions
    unless ($qu->id) {
        my $ques = xPapers::Polls::QuestionMng->get_objects_count(query=>[poId=>$poll->id]);
        $qu->rank($ques);
    }

    $qu->save;
    $qu->dbh->do("delete from answer_opts where qId=$qu->{id}");
    my @answers = fields2array('answers',$q,'<answers??>',50);
    for (@answers) {
        next unless /\w/;
        xPapers::Polls::AnswerOption->new(qId=>$qu->id,value=>$_,other=>0)->save;
    }
    if ($qu->type eq 'dichotomy' or $qu->type eq 'yesno') {
        my $other_field = $qu->type eq 'dichotomy' ? 'others' : 'yesno-others';
        my @others;
        if ($qu->showOtherOptions) {
            @others = fields2array($other_field,$q,"<$other_field??>",50);
        } else {
            @others = ("Other");
        }
        for (@others) {
            next unless /\w/;
            xPapers::Polls::AnswerOption->new(qId=>$qu->id,value=>$_,other=>1)->save;
        }
        if ($qu->type eq 'yesno' and !$origId) {
            xPapers::Polls::AnswerOption->new(qId=>$qu->id,value=>'Yes',other=>0)->save;
            xPapers::Polls::AnswerOption->new(qId=>$qu->id,value=>'No',other=>0)->save;
        }
    }
    $m->comp("question.pl",__obj=>$qu,c=>'show');

# MOVE UP
} elsif ($ARGS{c} eq 'up') {
    # we do this instead of asking for a specific rank because of a bug with params of value 0
    my $oa = xPapers::Polls::QuestionMng->get_objects(query=>[poId=>$qu->poId,rank=>{lt=>$qu->rank}],sort_by=>"rank desc");
    $oa = $oa->[0];
    jserror("Cannot move item") unless $oa;
    $oa->rank($oa->rank+1);
    $oa->save;
    $qu->rank($qu->rank-1);
    $qu->save;
} 

# MOVE DOWN
elsif ($ARGS{c} eq 'down') {
    my $oa = xPapers::Polls::QuestionMng->get_objects(query=>[poId=>$qu->poId,rank=>{gt=>$qu->rank}],sort_by=>"rank asc");
    $oa = $oa->[0];
    return unless $oa;
    $oa->rank($oa->rank-1);
    $oa->save;
    $qu->rank($qu->rank+1);
    $qu->save;
}

$m->notes("oId",$qu->id) if $qu;
$m->notes("obj",$qu);

</%perl>


