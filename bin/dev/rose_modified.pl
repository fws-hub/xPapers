use xPapers::Entry;
use xPapers::Affil;
use Data::Dumper;

my $e = xPapers::Entry->get('BOUCIU');
#$e = xPapers::Affil->get(1);

print "oops\n" if $e->fieldModified('title');

$e->title('testxxx');

print "yeah\n" if $e->fieldModified('title');

#print Dumper($e->{__xrdbopriv_modified_columns});
