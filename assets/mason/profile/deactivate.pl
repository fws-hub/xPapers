<% gh("Deactivate my account") %>
<& ../checkLogin.html, %ARGS &>
%unless ($ARGS{confKey} and $ARGS{confKey} eq $user->pk) {

What will happen:
<ul class="normal">
    <li>You will no longer be able to log in with this email address (<%$user->email%>).</li>
    <li>Your profile will no longer be accessible to the public.</li>
    <li>However, your name will remain associated with any content you may have contributed to <% $s->{niceName} %> , e.g. forum messages. Content you have contributed will not be deleted. </li>
</ul>
Should you wish to restore your account, you can do so by following the registration procedure anew with the same email address.
<p>
If you still want to disable your account, click <a href="?confKey=<%$user->pk%>">here</a>.

%} else {

%$user->confirmed(0);
%$user->setFlag('DISABLED');
%$user->save;
Your account has been deactivated. <p>
You will be forwarded to the home page in five seconds.
<meta http-equiv="refresh" content="5; /users/deactivated.html?logoff=1">


%}

