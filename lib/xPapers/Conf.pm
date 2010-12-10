package xPapers::Conf;
use DateTime;
use DateTime::TimeZone;
use xPapers::Site;
use POSIX qw/floor/;
our @ISA=qw(Exporter);
our @CONF_VARS=qw(@CONF_VARS $TEST_MODE $LOW_PRICE $SUBJECT $CAT_TRAINING_SET $CAT_TESTING_SET $AUTOCAT_USER $HARVESTER_USER $WEB_HARVESTER_USER $POP_JOURNALS $GLOG $RECAP_KEY $RECAP_PUBKEY $SAFARI_MCAT $WWW_USER $ARCHIVE_PATH $PERL $LAUNCH_DATE %DB_SETTINGS %CACHE_SETTINGS %EXPAND_CAT $PASSWD_SALT %CM %QUOTAS $CACHE_SIZE $CACHE_FILE $DEFAULT_SITE $DEFAULT_SITE_NAME $ELOG %NOLINKH $DEFAULT_LIMIT %PERMS $SMTPHOST %PC %SORTER %FORMATS $READING_LIST_NAME $C1 $C2 $C3 $C4 formatTZ $TEXT_SIZE $TZ_OFFSET $TZ_OFFSET_STR %SOURCE_TYPE_ORDER %PRESETS $TIMEZONE $LOCAL_BASE @SPLIT $SPLIT_EXTRA $MISCLOG $TITLE $EMAIL_SENDER @EDITORS_EMAILS $TABLE $DATABASE $FETCH_LIMIT $CONTENT_LEVEL $MAX_REQS $LAUNCH_DATE $YEAR $FLAG $BACKUP_PATH $BASE_URL %PATHS @SAFE_URLS @SAFE_DOMAINS $SHOWALL %VALID_VALUES %INDEXES $FT_FIELDS_S $FT_FIELDS_R $FT_FIELDS_U %SPECIAL_REQUESTS %SQL %SITES $OAI_SUBJECT_PATTERN $OAI_SUBJECT_PATTERN2 $OAI_ANTI_PATTERN $OAI_METADATA_RIGHTS_REF %ABEBOOKS %AMAZON $IMPORTANT_ACTIONS $START_OF_RECENT $THRESHOLD_ACTIONS $THRESHOLD_PAPERS $TAR $GZIP $MYSQL_BINS $Z3950_SERVER $Z3950_SUBJECT_NAME @MARCXML_KEYWORDS @Z3950_HARVEST_YEARS %MASSMAIL $SPHINX %OAI %FACEBOOK $OPP_ADDRESS $OPP_CRAWL_DEPTH @TIPS $TIPS_FREQ %NOCOPY $ERROR_MESSAGE $CGIBIN $CACHE_GROUP);
our @EXPORT = @CONF_VARS;
our @EXPORT_OK=@EXPORT;

$TEST_MODE = 1; # If set to 1, no mail is sent out

#
# Configuration variables
#

$SPHINX = "/usr/local/sphinx/bin";
$PERL = "/usr/bin/perl -I/home/xpapers/lib";
$TAR = "/bin/tar";
$GZIP = "/bin/gzip";
$MYSQL_BINS = "/usr/local/bin";
$WWW_USER = "www-data";
$CACHE_GROUP = $WWW_USER;
$AUTOCAT_USER = 7;
$HARVESTER_USER = 8;
$WEB_HARVESTER_USER = 9;
$CACHE_PATH = '/dev/shm';
$CACHE_FILE = "/dev/shm/xpapers";
$SUBJECT = 'Philosophy';


%DB_SETTINGS = (
    domain   => 'development',
    type     => 'main',
    driver   => 'mysql',
    database => 'xpapers',
    host     => 'localhost;enable_mysql_utf8=1',
    username => 'xpapers',
    password => 'CHANGEME',
    server_time_zone => 'Europe/London',
);

%CACHE_SETTINGS = (
        num_pages => 51,
        share_file => $CACHE_FILE, 
        init_file=>0,
        unlink_on_exit=>0,
        page_size => "512k",
        root_dir=>$CACHE_PATH
);

$ELOG = '/var/log/handler';
$LOCAL_BASE = '/home/xpapers';
$TABLE = 'main';
$FETCH_LIMIT = 2000;
$DEFAULT_LIMIT = 100;
$CONTENT_LEVEL = 2;
$MAX_REQS = 99999999;
$LAUNCH_DATE = '2007-10-25'; #This is probably not used anymore
$MISCLOG = '';
$PASSKEY = "CHANGEME";
$TEXT_SIZE = 13;
$PASSWD_SALT = "CHANGEME";
$RECAP_KEY = 'CHANGEME';
$RECAP_PUBKEY = 'CHANGEME';
$LOW_PRICE = 30; # what percent counts as a bargain price for affiliate links

$C1 = '666666';
$C2 = '000000'; 
$C3 = '1f5d5d';
$C4 = '1f5d5d';


%CM = ( entries => 'xPapers::Entry', 'categories' => 'xPapers::Cat');

%QUOTAS = (
    Edit => 5000,
    Submit => 50000,
    CatAdd => 20000,
    CatDelete => 300
);
%EXPAND_CAT = map { $_ => 1} qw//;

#
# Time info
#

my @time = localtime(time);
$YEAR = $time[5] + 1900;
$TIMEZONE = "Europe/London";
$LAUNCH_DATE = DateTime->new(time_zone=>$TIMEZONE, year=>2009,month=>1,day=>28,hour=>0,minute=>0,second=>0);
$GMT_OBJ = DateTime::TimeZone->new(name=>$TIMEZONE);
$TZ_OFFSET = $GMT_OBJ->offset_for_datetime(DateTime->now)/60;
$TZ_OFFSET_STR = formatTZ($TZ_OFFSET);

@EDITORS_EMAILS = ('david.bourget@anu.edu.au','chalmers@anu.edu.au');
$EMAIL_SENDER = 'PhilPapers <noreply@philpapers.org>';
#$SMTPHOST = "localhost:587";
$SMTPHOST = "localhost";

$FLAG='';

$GLOG = '/tmp/xpaperslog';

$BASE_URL="/mindpapers/";
$BACKUP_PATH = "$LOCAL_BASE/back";
our %PATHS;

$PATHS{BIBUTILS} = "$LOCAL_BASE/bin/bibutils/";
$PATHS{LOCAL_BASE} = "/home/xpapers";
$PATHS{SEARCH_SCRIPT} = "/common/search.pl";
$PATHS{ADMIN_SCRIPT} = "/admin.pl";
$PATHS{FILE_SCRIPT} = "http://philpapers.org/archive/";
$PATHS{UPLOAD} = "$PATHS{LOCAL_BASE}/var/files/tmp";
$PATHS{ARCHIVE} = "$PATHS{LOCAL_BASE}/var/files/arch";
$PATHS{BACKUP} = "$PATHS{LOCAL_BASE}/back/";
$PATHS{HARVESTER}= "$PATHS{LOCAL_BASE}/var/data/harvester/";

%PERMS = (
    0 => "None",
    10 => "Member",
    30 => "Moderator",
    40 => "Administrator"
);

$NOCOPY{$_} = 1 for qw/dir bigcap cat xsides p noheader jlist preset save saveAs _where where/;

$PC = (
    no => {
        viewingoptions_pub => 1
    }
);

$POP_JOURNALS = 1; # id of most popular journals list

%FORMATS = (
    css => { renderer=>undef, contentType=>'text/css'},
    js => { renderer=>undef, contentType=>'text/javascript' },
    json => { renderer=>'xPapers::Render::JSON', contentType=>'text/javascript' },
    xml => { renderer=>'xPapers::Render::RSS', contentType=>'application/rss+xml', limit=>500 },
    rss => { renderer=>'xPapers::Render::RSS', contentType=>'application/rss+xml', limit=>500 },
    htm => { name=>"Formatted text", renderer=>'xPapers::Render::RichText', contentType=>'text/html',noheader=>1 },
    alert => { name=>"Alert", renderer=>'xPapers::Render::Email', contentType=>'text/html', noHTML=>1, limit=>500 },
    embed => { name=>"Embed", renderer=>'xPapers::Render::Embed', contentType=>'text/html', noHTML=>1, limit=>500 },
    txt => { name=>"Plain text", renderer=>'xPapers::Render::Text', contentType=>'text/plain'},
    bib => { name=>"BibTeX", renderer=>'xPapers::Render::BibTeX', contentType=>'text/plain'},
    zot => { name=>"Zotero", renderer=>'xPapers::Render::EndNote', contentType=>'application/x-endnote-refer'},
    enw => { name=>"EndNote", renderer=>'xPapers::Render::EndNote', contentType=>'application/x-endnote-refer'},
    ris => { name=>"Reference Manager", renderer=>'xPapers::Render::RIS', contentType=>'application/x-Research-Info-Systems'}
);

$READING_LIST_NAME = "My reading list";

%SOURCE_TYPE_ORDER = (
    local => 1,
    web => 2,
    archives => 3,
    journals => 4,
    books => 5,
    other => 6
);

%SORTER = ( 
        firstAuthor => ['first author','authors asc, date desc'],
        pubYear => ['publication year','date desc, authors asc'],
        added => ['addition date','added desc, date desc'],
        relevance => ['relevance','relevance desc'],
        viewings => ['viewings','viewings desc'] 
);
my %alloff = (
        'in_j' => 'off',
        'in_a' => 'off',
        'in_l' => 'off',
        'in_w' => 'off',
        'showAbstract' => 'on',
        'freeOnly' => 'off',
        'publishedOnly' => 'off',
        'filterByAreas' => 'off'
);
$PRESETS{all} =  {
        'in_j' => 'on',
        'in_b' => 'on',
        'in_l' => 'on',
        'in_w' => 'on',
        'showAbstract' => 'on',
        'freeOnly' => 'off',
        'publishedOnly' => 'off',
        'filterByAreas' => 'off'
};
for (qw/books web local journals/) { 
    my %t = %alloff;
    $PRESETS{$_} = \%t;
    $PRESETS{$_}->{"in_" . substr($_,0,1)} = 'on';
}

@SPLIT = (
    {
    #<img class='bookmark' src=\"/raw/bookmark.png\"><span class='ll bookmark' onclick='ppAct(\"bookmark\",{})'>mark this place</span>
        header=>"<span class='header_period'>%s <span style='font-size:smaller'>GMT</span></span>\n",
        idtpl=>"h%s",
        type=>"day",
        fields=>['period','prank'],
        idFields=>['prank'],
        rendConf=>{showPub=>1,extraClass=>''},
        before=>"\n<div class='group'>\n",
        after=>"\n</div>\n",
        extraSelect=> "
            date_format(main.added,'\%b \%D %Y') as period,
            1000000 - to_days(main.added) as prank,
            "
    },
    {
        header=>"<span class='header_source_type'>%s</span>\n",
        idtpl=>"h%s%s",
        idFields=>['prank','rank'],
        type=>"source_type",
        fields=>['source_type'],
        rendConf=>{showPub=>1,extraClass=>''}
    },
    {
        header=>"<span class='header_source'><a class='discreet pub_name' href='http://philpapers.org/asearch.pl?pubn=%s'>%s</a></span><span class='header_source_part2'></span>\n",
        idtpl=>"h%s%s%s",
        extraSelect=>"main.source",
        idFields=>['prank','rank','source'],
        type=>"journal",
        fields=>['source','source'],
        rendConf=>{showPub=>0,extraClass=>''},
        condition=>{field=>'source_type',value=>'__journals'}
    },
    {
        header=>"<div class='header_issue'>%s</div>\n",
        idtpl=>'h%s%s%s%05s%05s',
        idFields=>['prank','rank','source','volume','issue'],
        type=>"issue",
        fields=>['pub_details'],
        rendConf=>{showPub=>0,extraClass=>''},
        condition=>{field=>'source_type',value=>'__journals'}#,value2=>'From online archives'}
    }
);
%NOLINKH = map { $_ => 1 } (
   "Stanford Encyclopedia of Philosophy",
   "Internet Encyclopedia of Philosophy",
   "Social Science Research Network",
   "Philsci Archive",
   "Cogprints",
   "PhOnline"
);
$SPLIT_EXTRA = "
        if((volume = 0 or date = 'forthcoming'), 'forthcoming articles', concat('volume ',volume,', issue ',ifnull(issue,'?'),', ',date)) as pub_details,
        case 
            when pub_type='journal' or pub_type='online collection' then '__journals'
            when type='book' then 'New books'
            when db_src='web' or db_src='archives' or pub_type='manuscript' or pub_type='unknown' then 'Manuscripts'
            else 'Chapters, other' 
        end as source_type,
        case
            when type='book' then 0
            when pub_type='journal'  or pub_type='online collections' then 1
            when db_src='web' or db_src='archives' or pub_type='manuscript' or pub_type='unknown' then 2
            else 3
        end as rank,

        ";




$SHOWALL = 100;

#
# Parameter constraints (used for params passed directly into SQL or file ops)
#

%VALID_VALUES = (
	structure=>'noexpand|flat|default|',
	root=>'[\w\.]*',
	filterMode=>'notauthors|authors|keywords|advanced|admin|notauthor|',
    searchPart=>'[\w!\-\d]*',
	free=>'1|0|',
	published=>'1|0|',
    tabl=>'hypatia|h2n|main[a-z0-9_]*|online|enctest|harvest\d*|',
    'pos'=>'[12]|',
    'dist'=>'source|date|',
    page=>'All|Elsewhere|Published|Manuscript|browse.html|help.html|advanced.html|sources.html|source.html|dist_books\.html|authors\.html|harvest_v\.html|years\.html|dist.html|special\.html|adminm\.html|contributors\.html|faq\.html|bug\.html|suggestion\.html|menu_if\.html|guidelines\.html|impact\.html|offcampus\.html|about\.html|logs\.html|move_flag\.html|',
    crit=>'list_db|online_book|misc|defective|new|duplicate|',
#    field=>join('|',xPapers::Entry->new->meta->column_names) . '|',
#   group=>join('|',xPapers::Entry->new->meta->column_names) . '|',
	noLinks=>'1|',
	noExtras=>'1|',
	noOptions=>'1|',
    latest=>'1|([A-Z]-?)*',
    journals=>'1|([A-Z]-?)*',
    mode=>'boolean|weight|plus|time|',
    search_header=>'search_header.html|search_header2.html|',
    jlist=>'\w+|',
    sort=>'[\w\s]+|',
    tSort=>'relevance|pt asc|pt desc|pc asc|pc desc|latestPostTime desc|postCount desc|ct asc|ct desc|created asc|',
    oType=>'xPapers::Operations::ImportEntries|xPapers::User|xPapers::Cat|xPapers::Journal|xPapers::Entry|xPapers::Group|xPapers::Editorship|xPapers::Forum|xPapers::Thread|xPapers::Post|xPapers::Pages::Page|xPapers::Pages::PageAuthor|xPapers::UserX|'
);
$VALID_VALUES{$_} = '^[\-\d\.]*$|' for qw/sugMode status minRelevance lowRelevance range limit offset start from lId list fId uId aId/;

$FT_FIELDS_A = "authors,ant_editors,date,title,PI_abstract,author_abstract,descriptors,source,notes,publisher,ant_publisher,school";
#$FT_FIELDS_S = "authors,date,title,notes,source,publisher,school,ant_publisher,ant_editors";
$FT_FIELDS_S = "title,authors,notes,descriptors,source,author_abstract";
$FT_FIELDS_U = "title as ft1,authors as ft2,notes as ft3,descriptors as ft4,source as ft5,author_abstract as ft6";
$FT_FIELDS_R = "ft1, ft2, ft3, ft4, ft5, ft6";
%INDEXES = (
    1 => $FT_FIELDS_S,
    2 => "title",
    4 => "title, authors",
    3 => "title, authors, descriptors"
);

#
# Special requests
#

our %SPECIAL_REQUESTS;

#
# Direct SQL requests (admins only)
#
our %SQL = (
	searches_per_day => "select date(time) as date, count(*) as searches  from log_act where action='search' and time >= date_sub(now(),interval 30 day) group by date(time) order by date(time)",
	actions_per_day => "select date(time) as date, count(*) as actions  from log_act where time >= date_sub(now(),interval 30 day) group by date(time) order by date(time)",
    referer_domains => "select count(*) as hits, substring_index(referer,'/',3) as 'referer domain', concat('<a href=\"',referer,'\">',referer,'</a>') as 'sample page' from log_act where referer like 'http://%' group by substring_index(referer,'/',3) order by hits desc" ,
    recent_referer_domains => "select count(*) as hits, substring_index(referer,'/',3) as 'referer domain', concat('<a href=\"',referer,'\">',referer,'</a>') as 'sample page' from log_act where time > date_sub(now(),interval 1 day) and referer like 'http://%' group by substring_index(referer,'/',3) order by hits desc" ,
    pages_per_user_day => "select (select count(*) from log_act where action='browse' or action='search' or action ='page') / (select count(distinct concat(date(time),'-',tracker)) from log_act where action = 'browse' or action = 'search' or action = 'page' limit 5) as 'average pages per user per day'",
    viewings_per_letter => "select substring(authors,0,1) as letter, avg(viewings) as 'average viewings' from main group by substring(authors,0,1) order by letter desc",
);


sub formatTZ {
    my $i = shift;
    return ($i < 0 ? '-' : '+'). sprintf('%02d',abs(floor($i / 60))) . ":" . sprintf('%02d',($i % 60)); 
}


our %MASSMAIL = (
    "Admins" => "select id from users where admin",
    "Editors" => "select distinct uId as id from cats_eterms where start <= now() and isnull(end) and status = 20",
    "Beta Testers" => "select id from users where betaTester"
);

# OAI archives

# The rule is that an item / set is added iff i4 matches the first pattern or (it matches the second pattern and not the anti-pattern)
our $OAI_SUBJECT_PATTERN;
our $OAI_SUBJECT_PATTERN2;
our $OAI_ANTI_PATTERN;
our $OAI_METADATA_RIGHTS_REF;
our %OAI;

# Categorization

our $CAT_TRAINING_SET = 0.95;
our $CAT_TESTING_SET = 0.05;

# Editor finder

our $IMPORTANT_ACTIONS = "'edit'";
our $START_OF_RECENT = DateTime->now->subtract( days => 30 )->ymd;
our $THRESHOLD_ACTIONS = 4;
our $THRESHOLD_PAPERS  = 1;

# Z3950 Harvesting

our $Z3950_SERVER = 'z3950.loc.gov:7090/Voyager';
our $Z3950_SUBJECT_NAME = 'philosophy';
{
    my $year = DateTime->now->year;
    my $end = $year+1;
    my $start = $end - 4;
    our @Z3950_HARVEST_YEARS = $start .. $end;
}

our @MARCXML_KEYWORDS = qw/philosoph phenomenolog ontolog epistemolog ethics/;

our $OPP_CRAWL_DEPTH = 2;

our $TIPS_FREQ = 4;
our @TIPS = (
{ t => "Search results and category listings are restricted by the filters on the right hand side of the page. Not all entries are shown by default.", c => "fil"},
{ t => "Our <a href='/utils/bargains.pl'>Bargain Finder</a> is excellent to find cheap books of interest to you.", c=> "bar" },
{ t => "Want to see the works of a particular author? Search for the author's name using any format you like ('J Smith', 'Smith, John', etc). The 'J Smith' format will work best if we don't know the author's full name.", c => "aut" },
{ t => "Looking for a work in particular? Search for the first author's lastname followed by a word from the title.", c => "wor" },
{ t => "Want to know about the new papers on your favorite topics as they come online? Find a page that <em>would</em> show them were they already in the index, and create an <a href='/profile/myalerts.pl'>alert</a> for this page.", c=> "ale" },
{ t => "Your search is turning up irrelevant results? Try searching inside the relevant research area only (visit the area's page for that).", c=> "ins"}, 
{ t => "Looking for a _SITE_NAME_ user? Search for their name. Their profile will appear at the top of the search results if they have one.", c=> "use" },
{ t => "Want people to find your papers? Boost your Internet presence by creating an account and adding all your works to _SITE_NAME_' index. Make sure to provide abstracts, descriptors, and categories for all your works, and add your credentials to your account.", c=>"pr" },
{ t => "Like to keep up with new work in your area? Try <a href='/help/editors.html'>becoming a category editor</a>. We put powerful tools in your hands and you keep _SITE_NAME_ organized.", c=>"ed" },
{ t => "Do you have a bibliography in BibTeX, Endnote, RIS (etc)? <a href='/utils/batch_import.pl'>Import it</a> into _SITE_NAME_ to use our tools with it. This will also help us increase our coverage.", c=>"bib"},
{ t => "Got a smartphone? Set up RSS feeds for your favorite pages or searches and learn about interesting new papers in the tube / train / subway / metro / bus / morning traffic jam.", c=>'ph'},
{ t => "Is _SITE_NAME_ missing an important feature? <a href='/help/contact.html'>Tell us!</a>", c=>"tell"}
);

$CGIBIN = '/cgi';

# Import from system-specific config

if (-d '/etc/xpapers.d') {
    if (-r '/etc/xpapers.d/main.pl') {
        require '/etc/xpapers.d/main.pl';
    }
}

$DEFAULT_SITE = xPapers::Site->new( LOCAL_BASE => $LOCAL_BASE, %{ $SITES{$DEFAULT_SITE_NAME} } );

$SAFARI_MCAT = $PATHS{LOCAL_BASE} . '/var/dynamic-assets/' . $DEFAULT_SITE->{name} . '/mcats.js';

$ERROR_MESSAGE = <<END;
<h3>Oops, an error has occurred.</h3>
<div>The incident has been logged and we will be looking into it.<br>
__DETAILS__
END


1;

__END__

=head1 NAME

xPapers::Conf

=head1 DESCRIPTION

Defines constants used across the project.  Near the end of the file it also loads the C</etc/xpapers.d/main.pl> file
where it is possible to locally override the constants defined in this file.





=head1 SUBROUTINES

=head2 formatTZ 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



