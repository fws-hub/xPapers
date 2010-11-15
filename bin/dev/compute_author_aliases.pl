use strict;

use Encode 'decode';

use xPapers::DB;
use xPapers::Prop;
use xPapers::Util qw/ calcWeakenings normalizeNameWhitespace/;

binmode STDOUT,":utf8";
my $DEBUG = 0;

my $db = xPapers::DB->new;
my $dbh = $db->dbh;
xPapers::DB->exec("drop table if exists author_aliases_tmp");
xPapers::DB->exec("create table author_aliases_tmp as select * from author_aliases limit 0");
xPapers::DB->exec("alter table author_aliases_tmp change id id int unsigned auto_increment primary key ");
xPapers::DB->exec("alter table author_aliases_tmp add index( name )");
xPapers::DB->exec("alter table author_aliases_tmp add index( alias )");

my $sth;

my %seen_names;
$sth = $dbh->prepare("select name, firstname, lastname, eId, source_id from main_authors join main on eId = main.id"); 
# and eId = 'CRACII'");
 my $alias_sth = $dbh->prepare("INSERT INTO author_aliases_tmp( name, alias ) VALUES(?, ?)");
 $sth->execute;
 while( my $author = $sth->fetchrow_hashref ){
     $author->{$_} = decode( 'utf8', $author->{$_} ) for keys %$author;
     next if $seen_names{ $author->{name} }++;
     my ( $warnings, @weakenings ) = calcWeakenings( $author->{firstname}, $author->{lastname} );
     for my $warning ( @$warnings ){
         warn "$author->{eId} ($author->{source_id}) $author->{firstname} | $author->{lastname}: $warning\n" if $DEBUG;
     }
     for my $weakening ( @weakenings ){
         my $aname = normalizeNameWhitespace( $author->{name} );
         $alias_sth->execute( $aname, "$weakening->{lastname}, $weakening->{firstname}" );
     }
 }

print "Computing weakenings done\n";

my $alias_sth = $dbh->prepare("INSERT INTO author_aliases_tmp( name, alias, is_strengthening ) VALUES(?, ?, ?)");
my $check_hash;
$sth = $dbh->prepare("select name from author_aliases_tmp"); # where id = 543716");
$sth->execute;
my $i;
AUTHOR:
while( my $author = $sth->fetchrow_hashref ){
    my $aname = decode( 'utf8', $author->{name} );
    my $eId   = decode( 'utf8', $author->{eId} );
    print "checked for strengthenings $i names\n" if !( $i++ % 50000);
    next if $check_hash->{$eId}{$aname}++;
    my $potentials = $dbh->selectall_arrayref( 
        "select distinct name from author_aliases_tmp where alias = ? and not name = ? and not name like '%&%' ",
        { Slice => {} },
        $aname, $aname,
    );
    my $maxname = '';
    for my $potential( @$potentials ){
        my $pname = decode( 'utf8', $potential->{name} );
        $potential->{name} = $pname;
        $maxname = $pname if length($pname) > length($maxname);
    }
    for my $potential( @$potentials ){
        next if $potential->{name} eq $maxname;
        my $check = $dbh->selectall_arrayref( 
            'select * from author_aliases_tmp where name = ? and alias = ?',
            { Slice => {} },
            $maxname, $potential->{name},
        );
        if( !@$check ){
            next AUTHOR;
        }
    }
    my %seen;
    for my $potential( @$potentials ){
        my $pname = $potential->{name};
        next if length( $pname ) <= length( $aname );
        next if $seen{$pname}++;
        next if $aname eq $pname;
        print "Adding strengthening $eId| $aname |to| $pname\n" if $DEBUG;
        $alias_sth->execute( $aname, $pname, 1 );
    }
}

print "Computing strengthenings done\n";

xPapers::DB->exec("drop table if exists author_aliases");
xPapers::DB->exec("rename table author_aliases_tmp to author_aliases");

