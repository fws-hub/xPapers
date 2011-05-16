<& ../header.html, subtitle=>'My Journals' &>
<%perl>
# check if got a list, create one if not
my $list;
$list = xPapers::JournalList->get($user->mysources);
unless ($list) {
       $list = xPapers::JournalList->new(jlName=>'My sources',jlOwner=>$user->id); 
       $list->save;
       $user->mysources($list->jlId);
       $user->save;
}
# check entitled to edit
return unless $list->{jlOwner} eq $user->{id} or $SECURE;

print gh($list->{jlName} eq 'My sources' ? 'My Journals' : $list->{jlName});
</%perl>

<div class="explMsg">This page allows you to choose which journals you will see on the <a href="/recent">New items</a> page. Once you have made your list, go to New items and select "my journals" as the filter option in the right-hand-side option boxes. </div>

<%perl>
# update list if necessary

if ($ARGS{do} eq "reset" or $ARGS{do} eq "update") {
    $list->reset;
}

if ($ARGS{do} eq "update") {
    $user->alertJournals($ARGS{alertJournals});
    $user->save;
    foreach my $k (keys %ARGS) {
        next unless $k =~ s/^__s//;
        $list->add($k);
    }
    print "<br><b><font color='green'>List saved.</font></b>";  
}

# show list 
my $have = $list->journals;
my %have = map { $_->name => 1 } @$have; 
my $it = xPapers::JournalMng->get_objects_iterator(sort_by=>['name']);
my $bts = '<input type="submit" name="Save" value="Save"> <input type="button" name="Reset list" value="Reset" onClick="if (confirm(\'Are you sure you want to unselect all journals from your list?\')) {window.location=\'myjournals.pl?do=reset\'}">';

</%perl>

<p>
<form name='lform' id='lform' style='display:inline' action='myjournals.pl' method=POST>
<input type="hidden" name="do" value="update">
<input type="hidden" name="listId" value="<%$list->{jlId}%>">
<% $bts %>
<p>
<span style="border:1px dotted #ccc;padding:2px">
<input type="checkbox" name="alertJournals" value="1" <%$user->alertJournals ? "checked" : ""%>> Send me a regular digest of new articles in my journals. (See <a href="/profile/myalerts.pl">My Alerts</a> for more settings.)
</span>
<p>
<b>Available journals</b>
<%perl>
my $a =1;
while (my $j = $it->next) {
#    $j->load;
   next unless $j->{browsable} or $j->{archive};
   next if $j->{name} eq $s->{niceName} and $j->{archive};
   print "<br>" if $a and !$j->{archive};
   my $in = $have{$j->{name}};
   print qq{<input type="checkbox" name="__s$j->{id}" value="__s$j->{id}" } . ($in ? "checked" : "") . ">" . ($j->{archive} ? "$j->{name}" : $j->{name}) . "<br>";    
   $a = 0 unless $j->{archive};
}
</%perl>
<p>
<% $bts %>
</form>
