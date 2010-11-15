use strict;
use warnings;

use xPapers::Conf;
use DBI;
use File::Find::Rule;

my $version = '1.0';

my $dsn = "DBI:mysql:database=mysql;host=$DB_SETTINGS{host}";

my $dbh = DBI->connect( $dsn, $DB_SETTINGS{username}, $DB_SETTINGS{password}, { RaiseError => 1 } );

my $rv = $dbh->do( "CREATE DATABASE $DB_SETTINGS{database} CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'" );
if( !defined( $rv ) ){
    die "Cannot create $DB_SETTINGS{database} database: $DBI::errstr\n";
}

for my $file ( 'tables.sql', 'users.sql' ) {
    executeSqlFile( "$LOCAL_BASE/sql/$version/$file" );
}


sub executeSqlFile {
    my $file = shift;
    print "mysql -u $DB_SETTINGS{username} -p*** $DB_SETTINGS{database} < $file\n";
    print `mysql -u $DB_SETTINGS{username} -p$DB_SETTINGS{password} $DB_SETTINGS{database} < $file`;
}

$dsn = "DBI:mysql:database=$DB_SETTINGS{database};host=$DB_SETTINGS{host}";

$dbh = DBI->connect( $dsn, $DB_SETTINGS{username}, $DB_SETTINGS{password}, { RaiseError => 1 } );

executeSql( "INSERT INTO cats ( id, fId, dfo, edfo, pLevel, owner, level, highestLevel, name ) VALUES ( 1, 1, 1, 1, 1, 0, 0, 1, 'All $SUBJECT' )" );
executeSql( "ALTER TABLE cats AUTO_INCREMENT = 2" );

executeSql( "INSERT INTO forums ( id, name, cId ) VALUES ( 1, 'All $SUBJECT', 1 )" );

executeSql( "INSERT INTO forums ( id, name ) VALUES ( 7, '$DEFAULT_SITE->{niceName} News' )" );
executeSql( "ALTER TABLE forums AUTO_INCREMENT = 10" );

executeSql( "insert into main_jlists (jlId, jlOwner, jlName) values (1, 0, 'Most popular')" );

sub executeSql{
    my $query = shift;
    print "$query\n";
    $dbh->do( $query );
}

eval "require xPapers::UserMng";

print "Creating the administrator user\n";
print "First name: ";
chomp( my $firstname = <STDIN> );
print "Last name: ";
chomp( my $lastname = <STDIN> );
print "Email: ";
chomp( my $email = <STDIN> );
print "Password: ";
chomp( my $passwd = <STDIN> );
$passwd = xPapers::UserMng->crypt($passwd);
executeSql( "INSERT INTO users ( id, firstname, lastname, email, passwd, admin, confirmed ) 
    VALUES ( 1, '$firstname', '$lastname', '$email', '$passwd', 1, 1 )" );

