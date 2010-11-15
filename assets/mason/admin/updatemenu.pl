<%perl>
# we make sure we have the no-user menu
if (!$ARGS{stdmenu}) {
    htmlRedirect("/admin/updatemenu.pl?stdmenu=1");
} else {
    print "Anonymous user menu loaded. Your menu will come back once you leave this page.";
}
</%perl>
<& ../header.html, subtitle=>"Update JS menu",%ARGS &>
<% gh("Update menu") %>
<form id='myform' action="/admin.pl">
<input type="hidden" name="c" value="updateMenu">
<textarea id='menuhtml' name='menuhtml' cols=100 rows=20></textarea>
<br>
<input type="button" value="Grab and update" onclick="
$('menuhtml').value=$('menuanchor').innerHTML;
formReq($('myform'));
alert('Done');
">
<form>
