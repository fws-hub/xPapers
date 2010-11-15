use xPapers::User;

my $it = xPapers::UserMng->get_objects_iterator(query=>[mereFirstname=>undef]);
while (my $u = $it->next) {

    $u->save;

}
