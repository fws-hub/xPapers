<%perl>

#my $user = $u->sauth($q->param('id'),$q->param('sid'));
return "" unless $user->{id}; 
$user->{proxy} = $ARGS{proxy};
$user->{offCampusMethod} = 'proxy';
$user->save;
print "Done!";
</%perl>
