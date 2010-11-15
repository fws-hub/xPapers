<& header.html, title=>"Edit" &>
<p>
<h2>Edit</h2>
<%perl>
use xPapers::Render::JSOptionsRenderer;
my %a = %ARGS;
my $SECURE = 0;
my $new;

# decode utf8 params
foreach my $k ($q->param) {
    $q->param($k,Encode::decode_utf8($q->param($k)));
}

# Check if we have an incomplete submission for addition
my $badSubmit = 0;
my $incoming;
if ($q->param('write')) {
    my $or = new JSOptionsRenderer;
    my @text_fields = qw(title type pub_type date publisher source ant_date ant_publisher volume issue pages school reply-to contributor contributor_email ed_comment status originalId);
    my $e = new Entry;
    foreach my $k (@text_fields) {
        $e->{$k} = $q->param($k); 
    }
    my @links_in = split(/[\r\n]+/,$q->param('links')); 
    for (my $i=0; $i<=$#links_in; $i++) {
        $links_in[$i] = "http://".$links_in[$i] unless $links_in[$i] =~ /^(http|ftp|https):\/\//i;
    }
    $e->addLinks(@links_in);
    $e->addAuthors(parseAuthors($q->param('authors')));
    $e->addEditors(parseAuthors($q->param('ant_editors')));
    $e->{edited} = $q->param('edited') ? '1' : '0';
    my %cath = $or->parseForm($q,"category"); 
    # clean numbers from cat name
    $cath{0} =~ s/\d(\.\d+)?\w?\.\s//g;
    my $c = $b->getCategory($cath{0});
    $e->{containers} = [$c];

    # set id
    if ($q->param('id')) { 
        $e->{id} = $q->param('id');
    }

    # adjust date with pub_type
    $e->{date} = "manuscript" if $e->{pub_type} eq "manuscript";
    $e->{date} = lc $e->{date};
    $e->{ant_date} = $e->{date} if $e->{pub_type} eq "chapter";

    my $rel = $q->param('relations_txt');
    $rel =~ s/[\r\n]+/,/gs;
    $rel =~ s/\s+($|,)/$1/g;
    $rel =~ s/[,\s]+$//;
    $e->{relations} = text2relations($rel,$e->id);
    $incoming = $e;
    $badSubmit = isIncomplete($e);

}

# Open / create for editing or re-editing
$new = 0;
if (!$q->param('write') or $badSubmit) {
    my $e;
    if (!$badSubmit) {
        if (!$q->param('id') or !($e=xPapers::Entry-\>get($q->param('id')))) {
            $e = new Entry;
            $e->{pub_type} = 'journal';
            push @{$e->{containers}},$b->getCategoryById($q->param('catId'));
            $new = 1;
        }
    } else {
        $e = $incoming;
        $new = !$q->param('id');
        print "<span class='error'>The entry you submitted appears incomplete. Please complete it.</span><br><br>";
#        print "<span class='error'>The entry you submitted appears incomplete. Please complete it.</span> (<a href='javascript:editorHelp()'>Help!</a>)<br><br>";
    }

    edit($PATHS, $e,$new,$SECURE);
    return;
} 


# Save / create


# Prepare renderer
my $rend = new xPapers::Renderer::HTML;
$rend->{flat} = $q->param('flat');
$rend->{compact} = 1 if $q->cookie('listing_type') eq 'compact';
foreach (keys %PATHS) {
    $rend->{$_} = $PATHS{$_};
}
$rend->{refresh} = 1;
$rend->{bib} = $b;
$rend->init;
$rend->{cid} = $q->param('slot');
$rend->{forceCid} = 1;
my %pa;
foreach (@PASS_ON) {
    $pa{$_} = $q->param($_);
    $rend->{$_} = $q->param($_);
}
$rend->{params} = \%pa;
my $e = $incoming;
$rend->{editMode} = 1;
$rend->{sugMode} = 0 unless $b->{table} =~ /_sug$/;

# Save/ add
if ($q->param('id') and $q->param('id') ne '') { 
    #print "1";
    #exit;
#    print "top.document.getElementById('" . $q->param('edit_element') . "').style.display = 'none';";
    print '<script language="JavaScript">';
    print "var ed_el = top.document.getElementById('" . $q->param('edit_element') . "');";
    print "ed_el.style.display = 'none';";
    if ($SECURE) {
        $b->completeAuto($e);
        $b->updateEntry($e);
        # Send Javascript to update main window
        my $nc = "'" . quote($rend->renderEntry($e,0)) . "'";
        my $id = $e->id;
        print "var c = top.document.getElementById('" . $q->param('slot') . '_entry' . "');";
        print "c.innerHTML = $nc;";
#        print $nc;
#        print "alert('Processing');";
        #print "c.style.display = 'block';";
    } else {
        $b->completeAuto($e);
        $b->setTable($TABLE . "_sug");
        $e->{status} = 1;
        $e->{originalId} = $e->id;
        $b->addEntry($e,$e->{added});
        print "alert('Thank you for your suggestion. It should be processed shortly.');";
        # Get extra suggestion params
    }
    print "</script>";

} else {
    #print "2";
    #exit;
    # if standalone mode
        print "<b>Thank you for your suggestion. It should be processed shortly.</b><br><br>";
        print "You may now <a target='_top' href='$PATHS{SEARCH_SCRIPT}?page=suggestion.html'>suggest another entry</a> or <a target='_top' href='$PATHS{SEARCH_SCRIPT}'>return to the table of contents</a>";

}

#writeLog($con,$q,$tracker,"edit");

sub make_select {
	
	my $selected = shift;
	my $default = shift;
	my $t = shift;
	my @options =@$t;
	my $r = "";
	foreach my $o (@options) {
		$r .= "<option name='$o' ";
		$r .= ($selected eq $o or (!$selected and $default eq $o)) ? " selected " : "";
		$r .= ">$o</option>\n";
	}
	return $r;
}


sub edit {
my ($PATHS,$e,$new,$SECURE) = @_;
my @authors = $e->getAuthors();
my @editors = $e->getEditors();
my @links = $e->getLinks();
</%perl>

<html>

<body onload="initDynamicOptionLists();">
<form name="edit" method=POST onsubmit="<% !$q->param('sugMode') ? "if (this.contributor) { createCookie('contributor',this.contributor.value);createCookie('contributor_email',this.contributor_email.value)}; true" : ""%>" action="<%$SECURE ? $PATHS->{EDIT_SCRIPT} : $PATHS->{EDIT_SCRIPT_UNSAFE}%>">



<input type=hidden name=write value=1>
<input type=hidden name=slot value="<% $q->param('slot') %>">
<input type=hidden name=catId value="<% $q->param('catId') %>">
<input type=hidden name=edit_element value="<% $q->param('edit_element') %>">
<input type=hidden name=id value="<% $new ? '' : $e->id %>">
<input type=hidden name=added value="<% $e->{added} %>">
<input type=hidden name=tabl value="<% $TABLE %>">
<input type=hidden name=compact value="<% $q->param('compact') %>">
<input type=hidden name=sugMode value="<% $q->param('sugMode') %>">
<input type=hidden name=editMode value="<% $q->param('editMode') %>">
<input type=hidden name=status value="<% $q->param('status') %>">
<input type=hidden name=originalId value="<% $e->{originalId} %>">
<input type=hidden name=flat value="<% $q->param('flat') %>">

<div id='all_pub_info' class='inset'>


<!-- AUTHORS -->
<h3>Authors</h3>
<table cellpading=0 border=0 cellspacing=0>
<td>
<% mkDynList("authors",\@authors,"<div>_CONTENT_</div>","div", sub {
    my ($first,$initials,$last,$suffix) = parseName2(shift());
    return " <table style='display:inline' border='0' cellpadding='0' cellspacing='0'> <tr> <td width='170'> <input type='text' name='authors_firstname_COUNT_' size=20 value='$first'> </td> <td width='50'> <input type='text' name='authors_initials_COUNT_' size=3 value='$initials'> </td> <td width='170'> <input type='text' name='authors_lastname_COUNT_' size=20 value='$last'> </td> <td width='50'> <input type='text' name='authors_suffix_COUNT_' size=3 value='$suffix'> </td> </tr> </table> ",
}, ",")
%>
<table border="0" cellspacing="0" cellpadding="0"><tr style='color:grey'><td width='170' style='font-size:x-small;vertical-align:top'>firstname</td><td width='50' style='font-size:x-small;vertical-align:top'>initials</td><td width='170' style='font-size:x-small;vertical-align:top'>lastname</td><td width='50' style='font-size:x-small;vertical-align:top'>suffix</td></table>
<div align="left">
<input type="button" onclick="addToList('authors')" value="Add author">
</div>
</td>
</table>

<!-- TITLE -->
<p>
<h3>Title</h3>
<input name="title" type="text" size=60 id="title" value="<%perl> $e->{title} =~ s/\"/&quot;/g; print $e->{title};</%perl>"><br>
<span class='editor_note' style='font-size:smaller'>Note: article titles should only have beginnings of sentences capitalized. Books should be Capitalized in This Kind of Way</span><br>

<!-- PUB INFO -->
<h3>Type</h3>
<table cellpadding="0" cellspacing="0" border=0>

<tr>
<td>
Type of work: 
</td>
<td>
<select id='typeofwork' name="typeofwork" onChange="
   	adjustSel('thesis_inf', new Array('dissertation'), selectVal(this));	
   	adjustSel('source_inf', new Array('article'), selectVal(this));	
   	adjustSel('publisher_inf', new Array('book'), selectVal(this));	
   	adjustSel('pub_status_inf', new Array('article','book'), selectVal(this));	
    adjustPubIn();
 "> 
    <% make_select($e->{typeofwork},$e->{typeofwork},["article","book","dissertation"]) %>
</select>
</td>
</tr>

<tr class='tr' id='pub_status_inf' style="display:<% $e->{typeofwork} ne 'dissertation' ? 'table-row' : 'none'%>">
<td>
Publication status: 
</td>
<td>
<select id="pub_status" name="pub_status" onChange="
    adjustSel('date_inf',new Array('published'),selectVal(this));
   	adjustSel('pub_details', new Array('published','forthcoming'), selectVal(this));	
    adjustPubIn();
	">
    <% make_select($e->{pub_type},$e->{pub_type},['published','forthcoming','unpublished']) %> 
</select>
</td>
</tr>

<tr class='tr' id='pub_in_inf' style='display:<% $e->{pub_status} ne 'unpublished' and $e->{typeofwork} eq 'article' ? 'table-row' : 'none'%>'>
<td>
    In: 
</td>
<td>
    <select name='pub_in' onChange="
         adjustSel('chapter_inf',new Array('collection'),selectVal(this));
         adjustSel('journal_inf',new Array('journal'),selectVal(this));
">
    <% make_select($e->{pub_in},$e->{pub_in},['journal','collection','online collection']) %>
    </select>
</td>
</tr>

</table>

<div id="details_inf" style='display:<% $e->{pub_status} ne 'unpublished'%>'>
<h3>Publication details</h3>

<div id='thesis_inf' style='display:<% $e->{pub_type} eq 'thesis' ? 'inline' : 'none' %>'>
University: <input name="school" type="text" size="30" value="<% $e->{school} %>"><br>
</div>

<div id='date_inf' style='display:<% ($e->{pub_status} eq 'published')? "inline" : "none"%>'> 
    Year:
    <input name="date" type="text" size="8" value="<% $e->{date} %>"><br>
</div>


<!-- PUB_DETAILS -->

<div id="pub_details" style='display:<% $e->{pub_type} eq 'forthcoming' or $e->{pub_type} eq 'published'%>'>


<div id='publisher_inf' style='display:<% $e->{pub_status} ne 'unpublished' and $e->{typeofwork} eq 'book' ? 'inline' : 'none'%>'>
Publisher:<input name="publisher" type="text" size="18" value="<% $e->{publisher} %>"> 
<input type="checkbox" value="1" name="edited" <%$e->{edited} ? "checked" : ""%>> edited book<br>
</div>


<div id='source_inf' style='display:<% ((grep {$e->{pub_type} eq $_} qw(journal generic chapter local presentation)) ? 'inline' : 'none') %>'>
Journal name / collection title: <input name="source" type="text" size="40" value="<% $e->{source} %>">
<br>

<div id='journal_inf' style='display:<% ((grep {$e->{pub_type} eq $_} qw(journal local)) ? 'inline' : 'none') %>'>
Vol.:<input name="volume" type="text" size="3" value="<% $e->{volume} %>"> 
Issue:<input name="issue" type="text" size="3" value="<% $e->{issue} %>"> 
Pages:<input name="pages" type="text" size="3" value="<% $e->{pages} %>"><br>
</div>
<div id='chapter_inf' style='display:<% $e->{pub_type} eq 'chapter' ? 'inline' : 'none' %>'>
Editor(s):<input name="ant_editors" type="text" size="35" value="<% join(';',$e->getEditors) %>">
Publisher:<input name="ant_publisher" type="text" size="18" value="<% $e->{ant_publisher} %>"><br>
</div>

</div> <!-- source_inf -->
</div> <!-- pub_details-->
</div> <!-- details_inf-->

<br>

<!-- LINKS -->

<h3>Links</h3>
Include the "http://" part:<br>
<% mkDynList("links",\@links,"<div>_CONTENT_</div>","div", sub {
    my $val = shift;
    return "<input type='text' name='links_COUNT_' size=80 value='$val'>",
}, "")
%>
<input type="button" onclick="addToList('links')" value="Add link">

<!-- abstract -->
<br><br>
Abstract:<br> <textarea cols=90 rows=2 scroll=1 name=author_abstract id=author_abstract><%$e->{author_abstract}%></textarea>

<%perl> 
    my $or = new JSOptionsRenderer; 
    $or->{noJump} =1; 
    $or->{depthLimit} = 9; 
    $or->{selectStyle} = 'width:220px'; 
    print "<br>Section:<br>" . $or->renderBiblio($b) . $or->makeOptions("category",0,join(" :: ",$e->firstParent->fullDescAscendancy));
</%perl>

<br>
</div>
</div>

<div id='relations' style="display:none">
Relations<br>
<textarea name="relations_txt" cols=120 rows=8>
    <%perl>
    my $r = "";
    foreach my $rel (keys %{$e->{relations}}) {
        foreach my $relata (@{$e->{relations}->{$rel}}) {
            if ($rel =~ /^<>(.+)/) {
                $r .= $relata . ";" . $e->id . ";$1\n";
            } else {
                $r .= $e->id . ";$relata;$rel\n";
            }
        }
    }
    print $r;
    </%perl>
</textarea>
</div>
<br>
<%perl>if (!$SECURE or $q->param('sugMode')) {</%perl>

Your name (optional): <input type="text" size=30 name="contributor" value="<%$e->{contributor} ? $e->{contributor} : ($q->cookie('contributor') ne "undefined" ? $q->cookie('contributor') : '')%>"> <br>

Email (optional): <input type="text" size=30 name="contributor_email" value="<%($e->{contributor_email} ? $e->{contributor_email} : ($q->cookie('contributor_email') ne "undefined" ? $q->cookie('contributor_email') : ''))%>"><br>

Comment to editor (optional):<input type="text" size="93" name="ed_comment" value="<%$e->{ed_comment}%>">

<div style="text-align:left">
<br>
<input type=submit value="Submit"> 
&nbsp;&nbsp;&nbsp;&nbsp; 
<input style="display:<%$SECURE?'inline':'none'%>" id ='btn_view_relations' type=button value="View relations .." onclick="window.window.hide('all_pub_info');window.show('relations');window.hide('btn_view_relations');window.show('btn_view_pub_info')">
<input style="display:none" id ='btn_view_pub_info' type=button value="View pub info .." onclick="window.show('all_pub_info');window.hide('relations');window.hide('btn_view_pub_info');window.show('btn_view_relations')">
</div>
<script language="JavaScript">
//    window.resizeTo('100','600');
   // top.parent.rows = "*,300,10";
</script>
</form>
</body>
</html>

<%perl>
}

}

sub mkDynList {
    my ($id,$items,$container,$type,$lineMaker,$default) = @_;
    my $count = 0;   
    $lineMaker = sub {
        return "<input type='text' size='90' name='${id}_COUNT_' value='$_[0]'>";
    } unless $lineMaker;
    my $addLink = "<a href='javascript:addToList(\"$id\");'>Add ..</a>";
    my $removeLink = "<a style='vertical-align:top' href='javascript:" . 'deleteFromList(\"' . $id . '\",_COUNT_);' . "'>delete</a>";
    my $c = "";
    # Add lines..
    for my $i (0..$#$items) {
        my $r = $removeLink;
        $r =~ s/\\"/"/g;#hack
        $r =~ s/_COUNT_/$i/;
        $c .= "<$type id='c_${id}_$i'>" . &$lineMaker($items->[$i]) . " $r</$type>\n";
        $count++;
    }
    # Last line
#    $c .= "<$type>$addLink</$type>\n";
    $container =~ s/_CONTENT_/$c/;
    print $container;
    print "<input type='hidden' name='${id}_max' value='$count'>\n";
    </%perl>
        <script language="Javascript">
            dynListLine['<%$id%>'] = "<%&$lineMaker($default) . " $removeLink"%>";
            dynListCount['<%$id%>'] = <%$count%>-1;
            dynListType['<%$id%>'] = "<%$type%>";
        </script>
    <%perl>
    "";
}

</%perl>
