<%perl>
use xPapers::Util qw/dquote/;
$user->anonymousFollowing(0);
$user->alertFollowed(1);
$user->save(modified_only=>1);
my $text = dquote( $m->scomp('/followx/firstTimeText.html') );
$text =~ s/\n/ /g;
</%perl>

<script type="text/javascript">
watchForSymbol(
{
symbol:"xpa_yui_loaded",
onSuccess: function() {
    window.doFollowing = function(value){
            d.hide();
% if( $ARGS{eId} ){
            ppAct('updateFollowX', { eId: '<% $ARGS{eId} %>' } , function(msg) {
                $('msg-<% $ARGS{eId} %>').update().insert( msg );
            });
% }
% elsif( $ARGS{fuId} ){
            ppAct('updateFollowXUser', { fuId: '<% $ARGS{fuId} %>' } , function(msg) {
                $('followXUser_' + <% $ARGS{fuId} %>).removeClassName('ll');
                $('followXUser_' + <% $ARGS{fuId} %>).update().insert( msg );
            });
% }
        return true;
    };

    var conf =  { 
        width: "520px",
        modal: true,
        fixedcenter: true,
        visible: false,
        draggable: false,
        close: true,
        text: "<% $text %>",
        zIndex:9999,
        buttons: [ 
                { text:" OK ",  handler:function() { doFollowing() } },
            ]
    };
    var d = new YAHOO.widget.SimpleDialog("firstfollow",conf);
    d.setHeader("<% $s->{niceName} %> Social - Important information");
    d.render("container");
    d.show();
}});

</script>
