<%perl>
return unless $SECURE;

my $e = xPapers::Entry->get($ARGS{id});
jserror("Entry not found") unless $e;
my $d = xPapers::Diff->new;
$d->delete_object($e);
$d->uId($user->id);
$d->accept;
</%perl>
