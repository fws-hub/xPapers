<& ../header.html, subtitle=>"Copy category content" &>
<%perl>
my $cat = $ARGS{__cat__};
</%perl>
<% gh("Copy content from a category") %>
This tool allows you to import the contents of an existing listing or category into another list or category.
<p>
<b>Target category: <%$cat->name%>

