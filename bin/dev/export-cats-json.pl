use xPapers::DB;
use JSON::XS 'encode_json';

my $r = xPapers::DB->exec("select cats1.name,cats1.id, group_concat(cats_m.pId),cats1.ppId from cats cats1 join cats_m on cats1.id=cats_m.cId join cats cats2 on (cats_m.pId=cats2.id and (cats2.canonical or cats2.id=1)) where cats1.canonical or cats1.id=1 group by cats1.id");
print encode_json $r->fetchall_arrayref;
