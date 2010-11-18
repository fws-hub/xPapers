# Database connection settings
%DB_SETTINGS = (
    domain   => 'production',
    type     => 'main',
    driver   => 'mysql',
    database => 'db',
    host     => 'localhost;enable_mysql_utf8=1',
    username => 'xpapers',
    password => 'k1w1br0k4r',
    server_time_zone => 'GMT',
);

# Shared memory cache
$CACHE_FILE = '/dev/shm/xpapers';
%CACHE_SETTINGS = (
        num_pages => 51,
        share_file => $CACHE_FILE, 
        init_file=>0,
        unlink_on_exit=>0,
        page_size => "512k",
        root_dir=>"/dev/shm"
);

# Your subject matter
$SUBJECT = 'Philosophy';

# Emails to send messages from the contact form
@EDITORS_EMAILS = ('david.bourget@anu.edu.au','chalmers@anu.edu.au');

# The advertised name and email of the sender for email notices
$EMAIL_SENDER = 'PhilPapers <noreply@philpapers.org>';

# User ids of forum moderators
@MODERATORS = qw/1/;
#$SMTPHOST = "localhost:587";
$SMTPHOST = "localhost";

# Set that to 1 for you system not to send any mail. Use on test machines.
$TEST_MODE = 0;

# For the password crypt function. Any string here. Maybe 5-10 chars long.
$PASSWD_SALT = "0-20~~~~~~~~";

# Domains whose links are considered unlikely to break. You should add any domain from which you have many links here.
# These will be checked less systematically by the link checker, saving a lot of time.
@SAFE_DOMAINS = qw/sagepub.com philosophyonline.org cambridge.org reference-global.com consc.net philpapers.org soton.ac.uk springerlink.com taylorandfrancis.metapress.com informaworld jstor.org books.google.com blackwell-synergy.com wiley.com oxfordjournals inist.fr/;

# Safe URLs used to check if we are connected to the net. 
@SAFE_URLS = ("http://www.google.com","http://www.microsoft.com");

#
# Harvesting settings
#

# Z3950 Harvesting
$Z3950_SERVER = 'z3950.loc.gov:7090/Voyager';
$Z3950_SUBJECT_NAME = 'philosophy';
# Used to determine relevant books
@MARCXML_KEYWORDS = qw/philosoph phenomenolog ontolog epistemolog ethics/;

# The rule is that an item / set is added iff it matches the first pattern or (it matches the second pattern and not the anti-pattern)
$OAI_SUBJECT_PATTERN = qr/(?:\:\s*philosophy\s*$)|metaphysics|epistemology/i;
$OAI_SUBJECT_PATTERN2 = qr/philosophy/i;
$OAI_ANTI_PATTERN = qr/(?:(?<!\sphilosophy of\s)(?:religion|religious|\barts?|\bpoliti|sociology|social science|economics|humanities|\bhistor|\bbiblical|communication|linguistics|language))|(?:(?:Doctor|Master)\s+of\s+Philosophy)/i;


#
# Time settings
# Just change the $TIMEZONE and the rest should be all right
#

$TIMEZONE = "Europe/London";
$LAUNCH_DATE = DateTime->new(time_zone=>$TIMEZONE, year=>2009,month=>1,day=>28,hour=>0,minute=>0,second=>0);
$GMT_OBJ = DateTime::TimeZone->new(name=>$TIMEZONE);
$TZ_OFFSET = $GMT_OBJ->offset_for_datetime(DateTime->now)/60;
$TZ_OFFSET_STR = formatTZ($TZ_OFFSET);

#
# Credentials on third-party sites
#

# Your Facebook App details
%FACEBOOK = (
    APP_ID => "c77437fbbdab367f5d888b26b140a337",
    API_KEY => "148977641796357"
);

# Your ReCAPTCHA credentials
$RECAP_KEY = '6LdDNAMAAAAAAOJ1_JBkyr7g_zTzNcmvG8Y18w9r';
$RECAP_PUBKEY = '6LdDNAMAAAAAAB2nJfM_g7jPAyYR5xmReCTJVvYW';

# Your Amazon Affiliate credentials
%AMAZON = (
    data_dir => "$PATHS{LOCAL_BASE}/var/data/amazon",
    key    => '1CYYSXRPEAM0Q99H1WR2', 
    secret => '5Jl9oCqqQPt3tv9C1xIfxJ2bF2q48i9FPqZll8Jt',
    associate_tag => {
        uk => 'philp-21', # change that too 
        us => 'philp-20',
        ca => 'philp07-20',
    }
);

%ABEBOOKS = (
    clientkey => '060d105b-6d78-4f95-b520-da98c97def75',
    data_dir  => "$PATHS{LOCAL_BASE}/var/data/abebooks",
    locales   => { us => 'USD', uk => 'GBP', ca => 'CAD', au => 'AUD' },
);


#
# Site-specific items
#

my $hostname = `hostname`;
chomp $hostname;
%SITES = (
    philpapers => {
        paths => {
            QUICK_SEARCH_SCRIPT=>'/autosense.pl',
            SEARCH_SCRIPT=>'/asearch.pl',
            EDIT_SCRIPT_UNSAFE=>'/edit.pl',
            EDIT_SCRIPT=>'/edit.pl',
            ITEM_SCRIPT=>'/item.pl',
            DELETE_SCRIPT=>'/delete.pl',
            ENTRY_SCRIPT=>'/entry.pl',
            RESOLVER=>"http://localhost/go.pl"
        },
        #'sites' => { 'in_set' => 'pp' },
        defaultFilter=>['!deleted'=>1],
        root=>1,
        BASE_URL=>'/',
        niceName=>'PhilPapers',
        niceNameP => "PhilPapers'",
        subjectAdj => 'philosophical',
        feedServer => 'feeds.philpapers.org',
        name=>'philpapers',
        domain => $hostname,
        server=>"http://$hostname",
        defaultRenderer=>'xPapers::Render::HTML',
        longSignature => "OUR<br>LONG<br><br>SIGNATURE<br><br>",
    }
);

$DEFAULT_SITE_NAME = 'philpapers';

# Where to point for your license for OAI-PMH data
$OAI_METADATA_RIGHTS_REF = $DEFAULT_SITE->{server} . '/help/terms.html';

#
# Special requests
#

%SPECIAL_REQUESTS = (

    most_cited_sci => {where=>"philosophy=0 and duplicate=0",order=>'citations desc, id',limit=>'100',desc=>"100 most cited works by scientists[ in MindPapers according to Google Scholar]", prefix=>'citations' },
     most_cited_phil => {where=>"philosophy=1 and duplicate=0",order=>'citations desc, id',limit=>'100',desc=>"100 most cited works by philosophers[ in MindPapers according to Google Scholar]", prefix=>'citations' },

    most_cited => {where=>"duplicate=0",order=>'citations desc, id',limit=>'100',desc=>"100 most cited works[ in MindPapers according to Google Scholar]", prefix=>'citations'},

    most_viewed => {where=>'duplicate=0',order=>'viewings desc, authors, date',limit=>'100',desc=>"100 most viewed works",prefix=>'viewings'}
);


# Our colour scheme
$C1 = '666666';
$C2 = '10A010'; 
$C3 = '133d9f';
$C4 = '104bb8';

#print "Extra config loaded.\n";
