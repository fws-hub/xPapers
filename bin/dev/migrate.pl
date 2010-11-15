$|=1;
my $start_at = $ARGV[0] || 0;
my $src_host = '128.86.176.176';
my $src_path = '/home/dbourget/.ppbackups/xpapers';
my $mysql = '/usr/local/mysql';
my $count = 1;

run("scp $src_host:$src_path/back/tables.sql.gz /tmp/");
run("scp $src_host:$src_path/back/files.tar.gz /tmp/");
chdir('/tmp/');
run("tar xzf files.tar.gz");

run("sudo rm -rf /home/xpapers/var/files");
run("sudo rm -rf /home/xpapers/var/.applied-sql-patches");
run("sudo mv /tmp/home/data/xpapers-archive /home/xpapers/var/files");

run("sudo chown -R www-data.www-data /home/xpapers/var");
run("gunzip /tmp/tables.sql.gz");

#run("sudo $mysql/bin/mysqladmin drop db");
run("sudo $mysql/bin/mysqladmin create pp");
run("sudo $mysql/bin/mysql pp < /tmp/tables.sql");
chdir('/home/xpapers');
run("perl -Ilib bin/setup/apply-sql-patches.pl 0 1.0");
run("perl -Ilib bin/dev/flush_cache.pl");
run("sudo /usr/xpapers/sphinx/bin/indexer --all --rotate");
run("perl -Ilib bin/routine/compile-journals.pl");
run("perl -Ilib bin/dev/mkaliases.pl");

sub run {
	return unless $count++ >= $start_at;

	my $cmd = shift;
	print ($count -1) . ": $cmd\n";

 	print `$cmd`;	
}
