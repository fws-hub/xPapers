use xPapers::Conf;
my $rsync = '/usr/bin/rsync';
my $ssh ='ssh -l dbourget -i /home/dbourget/.ssh/id_rsa';

`$rsync -avz -e '$ssh' bb:$PATHS{LOCAL_BASE}/var/files/arch/* $PATHS{LOCAL_BASE}/var/files/arch`;
#`sudo chown www-data.xpapers $PATHS{LOCAL_BASE}/var/files/arch/*`;
#`sudo chmod 775 $PATHS{LOCAL_BASE}/var/files/arch/*`;
