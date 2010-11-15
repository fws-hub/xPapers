<%perl>
if( $SECURE ){
    print "<span='admin' style='padding:0'>";
    my @options;
    push @options, 'partial' if $ARGS{type} eq 'complete';
    push @options, 'excluded' if $ARGS{type} eq 'complete' || $ARGS{type} eq 'partial';
    for my $new_type ( @options ){
        my $text = $new_type eq 'partial' ? 'Downgrade' : 'Exclude';
       </%perl>
        <span class='ll' onclick='admAct("downgradeSet",{repo_id:"<%$ARGS{repo_id}%>",set_spec:"<%$ARGS{set_spec}%>",type:"<%$new_type%>"}, function(content) { if($("setEntryList") ){ $("setEntryList").update(content) }; if( $("dwgI<%$ARGS{set_spec}%>") ){ $("dwgI<%$ARGS{set_spec}%>").update("<% $text %>d") } })'><% $text %></span>
       <%perl>
    }
    print "</span>";
}
</%perl>
