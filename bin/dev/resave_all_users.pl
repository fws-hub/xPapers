use xPapers::UserMng;
my $it = xPapers::UserMng->get_objects_iterator();
while (my $e = $it->next) {
    $e->firstname($e->firstname);
    die unless $e->fieldModified('firstname');
    $e->save;
}
