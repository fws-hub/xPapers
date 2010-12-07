<& '../header.html', subtitle=>"Follow people" &>
<& ../checkLogin.html, %ARGS &>
<%perl>
if( !defined( $user->anonymousFollowing ) ){
    $m->comp("../followx/firstTimeDialog.pl");
}
error("Not allowed") unless $ARGS{__same};

</%perl>
<script type="text/javascript">
    var j = 0;
    function authorSelected(name) {
        if( name == '' ){
            return;
        }
        ppAct('followName', {name: name, j: j} , function(msg) {
                $('added_followers').innerHTML = $('added_followers').innerHTML + "\n" + msg;
                $('so_far').style.display = 'inline';
                $('none_added').style.display = 'none';
                $('auc-theElementId').value = '';
                j++;
            }
        );
    }

    function unfollowName(i, j, name) {
        if (!checklogin()) {
            window.location='/inoff.html?feature=1&after='+escape(window.location);
            return;
        }
        var el = $('follow-li-' + i + '-' + j);
        ppAct('unfollowName', {name:name} , function(r) {
                if (el) { el.hide() }
            }
        );
        return true;
    }
</script>
<%gh("Following new people")%> 
<& 'social_banner.html' &>
<& '../checkLogin.html', %ARGS &>
There are several ways to follow people on <% $s->{niceName} %>:
<ol>
<li>You can <a href="facebook.html">import your Facebook friends</a>. Even if you have thousands of friends we will only show you those that have papers in <% $s->{niceName} %> by default, so in most cases there's no need handpick who you follow. Importing your Facebook friends is not going to remove existing people from your list.</li>
<li>You can opt to follow the authors of a given book or article by clicking 'follow the authors' under it.</li>
<li>You can follow an individual <% $s->{niceName} %> user by clicking 'follow this person' on their profile.</li>
<li>Finally, you can type in the names of people you would like to follow below.</li>
</ol>
<& ../bits/author_select.html,callback=>"authorSelected",buttonCaption=>"Add" &>
<p>
Tip: it's best to pick the most complete names (i.e. with full given names) whenever possible, because <% $s->{niceName} %> will follow all the 'weakenings' of the names you enter. For example, David Donald William Cameron is better than David Cameron.
<div id="so_far" style="display:none" >
So far, you have added the following people:
<ul id="added_followers">
</ul>
</div>
<div id="none_added">
No one added yet.
</div>
</p>


