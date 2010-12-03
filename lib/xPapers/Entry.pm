=head1 NAME

xPapers::Entry - represents a bibliographic entry

=head1 SYNOPSIS

	my $entry = xPapers::Entry->new;
	$entry->type('article');
	$entry->pub_type('journal');
	$entry->title('Article Title');
	$entry->source('Some Journal');
	$entry->volume(300);
	$entry->issue(4);
	$entry->pages('1-23');
	$entry->date(2010);
	$entry->addAuthor('Doe, John');
	$entry->addLink('http://...');

=head1 DESCRIPTIONS

This Rose class represents a bibliographic entry. Most xPapers applications and utilities depend on this class.

=head2 Class methods

B<new()>

Create a new, empty instance.

=head2 Accessor methods 

B<type(string)>

Sets/return the entry type, which is really its format. The only two valid types are 'article' and 'book'.

B<pub_type(string)>

Sets/return the publication type. Valid values are 'journal' (published or forthcoming in a journal article), 'chapter' (published or forthcoming in a collection), 'book' (published or forthcoming as a book), 'online collection', 'manuscript','unknown'.

B<date(string)>

Set/return the publication year, or, if not published (yet), one of 'manuscript', 'draft', or 'forthcoming'. A reprinted work can have a two-part date such as '1805/2010', where the first part is the original publication year and the second part the new publication year. Most xPapers utilities assume that the most recent edition is described by the other field.  

B<addAuthor(string)>

Add an author. The first argument should be an author's name in the C<Smith, John> format. Correctly formated names can be obtained using the parseAuthors routine in xPapers::Util. 


=cut



package xPapers::Entry;
use base qw/xPapers::Object::Cached xPapers::Object::Diffable xPapers::Object::WithDBCache xPapers::Object::Lockable/;
use xPapers::Object::Cached;
use Data::Dumper;
use Encode;
#use xPapers::Util qw/parseName parseName2 quote sameEntry file2array cleanAll rmDiacritics/;
use xPapers::Util;
use xPapers::Object;
use HTML::Entities qw/decode_entities/;
use xPapers::Conf qw/$DEFAULT_SITE %SOURCE_TYPE_ORDER $TIMEZONE %INDEXES %PATHS $AUTOCAT_USER/;
use xPapers::Link::Affiliate::QuoteMng;
use xPapers::ToDelete;

my @AUTO_FIELDS = qw/pubHarvest status harvest_id online_book misc added deleted free defective duplicate viewings canon_url source_id db_src enriched citations citationsLink notes serial/;


__PACKAGE__->meta->setup
(
  table   => 'main',

  pre_init_hook => sub { 
      my $meta = shift; 
      for my $column ( $meta->columns ) {
          next if !( $column->isa( 'Rose::DB::Object::Metadata::Column::Scalar' ) );
          $column->overflow( 'truncate' );
      }
  },
  make_methods=> [preserve_existing=>1],
  columns => 
  [
    id                 => { type => 'varchar', length => 32, not_null => 1 },
    serial             => { type => 'serial' },
    authors            => { type => 'varchar', length => 2000 },
    ant_editors        => { type => 'varchar', length => 2000 },
    book               => { type => 'varchar', length=> 24 },
    links              => { type => 'varchar', length => 20000 },
    hasChapters        => { type => 'integer' },
    ant_date           => { type => 'varchar', length => 16 },
    ant_publisher      => { type => 'varchar', length => 255 },
    citations          => { type => 'float', precision => 32 },
    citationsLink      => { type => 'varchar', length => 255 },
    catCount           => { type => 'integer', default=>0 },
    date               => { type => 'varchar', length => 16, default=>'unknown' },
    dateRP             => { type => 'varchar', length => 16 },
    descriptors        => { type => 'varchar', length => 1000 },
    edited             => { type => 'integer' },
    etal               => { type => 'integer' },
    extra              => { type => 'varchar', length => 255 },
    issn               => { type => 'varchar', length => 64 }, # we don't really have that.
    isbn               => { type => 'array', dimensions=>1 },
    lccn               => { type => 'array', dimensions=>1 },
    issue              => { type => 'varchar', length => 32 },
    notes              => { type => 'varchar', length => 1000 },
    pages              => { type => 'varchar', length => 32 },
    pub_type           => { type => 'varchar', length => 32 },
    publisher          => { type => 'varchar', length => 2000 },
    replyto            => { type => 'varchar', length => 2000 },
    reprint            => { type => 'varchar', length => 2000 },
    school             => { type => 'varchar', length => 2000 },
    source             => { type => 'varchar', length => 2000 },
    title              => { type => 'varchar', length => 2000 },
    type               => { type => 'varchar', length => 16 },
    updated            => { type => 'datetime' },
    volume             => { type => 'integer' },
    db_src             => { type => 'varchar', default => 'user', length => 10 },
    review             => { type => 'integer', default => '0' },
    reviewed_title     => { type => 'array' },
    source_id          => { type => 'varchar', length => 255 },
    doi                => { type => 'varchar', length => 255 },
    author_abstract    => { type => 'text', length => 65535 },
    deleted            => { type => 'integer', default => '0' },
    defective          => { type => 'integer', default => '0' },
    source_subjects    => { type => 'varchar', length => 255 },
    online             => { type => 'integer', default => '0' },
    free               => { type => 'integer', default => 1 },
    published          => { type => 'integer', default => '0' },
    originalId         => { type => 'varchar', length => 12 },
    duplicate          => { type => 'integer', default => '0' },
    duplicateOf        => { type => 'varchar', length => 24 },
    added              => { type => 'datetime', default=>'now' },
    viewings           => { type => 'integer', default => '0' },
    online_book        => { type => 'integer', default => '0' },
    sites              => { type => 'set', values => [ 'pp', 'mp', 'opc' ] },
    pubHarvest         => { type => 'integer', default => '0' },
    file               => { type => 'varchar', length => 255 },
    addToList          => { type => 'integer', default => '0' },
    postCount          => { type => 'integer', default => '0' },
    fId                => { type=> 'integer' },
    draft              => { type => 'integer' },
    pro                => { type => 'integer' },
    forcePro           => { type => 'integer', default => '0' },
    cn_class           => { type => 'varchar', length => 4 },
    cn_num             => { type => 'float', precision=>32 },
    cn_alpha           => { type => 'varchar', length => 20 },
    cn_full            => { type => 'varchar', length=> 64 },
    lang               => { type => 'char', length=> 3 },
    googleBooksQuery   => { type => 'varchar', length=> 1000 },
    flags              => { type => 'set', values=> ['GS','GB','HIDE','GETPDF'] },
    cacheId            => { type => 'integer' }
  ],

    relationships =>
    [
      categories => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::CatEntry', 
        map_from=>'entry',
        map_to=>'cat',
        methods=>['add_on_save','find','count','get_set_on_save']
      },
      chapters => {
        type => 'one to many',
        class=>'xPapers::Entry',
        column_map=> { id => 'book' }
      },
      memberships => {
        type => 'one to many',
        class=>'xPapers::Relations::CatEntry',
        column_map=> { id => 'eId' }
     },
    forum => { type => 'one to one', class=>'xPapers::Forum', column_map => { fId => 'id' }}, 

      review_of => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::ReviewOf', 
        map_from=>'reviewer',
        map_to=>'reviewed',
        methods=>['add_on_save','find','count','get_set_on_save']
      },
    ],



  unique_key => ['serial'],
  primary_key_columns => [ 'id' ],

);

# setup triggers to handle text format for authors, editors, links
our %sp = ( authors => qr/;/, ant_editors => qr/;/, links => qr/\|\|\|/);
our %spt = ( authors => ';', ant_editors => ';', links => '|||');
sub value_separators { return \%sp; }

our %userFields;
$userFields{$_} = 1 for qw(doi authors title date ant_editors ant_date source volume issue pages edited author_abstract descriptors links school file publisher ant_publisher pub_type online free published draft cn_full deleted);

sub new {
    my $class = shift;
    my $o = $class->SUPER::new(@_);
    $o->toarrays;
    return $o;
}

# This class has a specially optimized get method 
sub get { 
    my ($me,$id) = @_;
    if (!$id) {
        $me->elog("ERROR: get called without id");
        return undef;
    }
    my $e;
    if (ref($id)) {
        $e = $me->SUPER::new($id);
    } else {
        $e = $me->SUPER::new(id=>$id);
    }
    return $e->load;
}


sub userFields { return \%userFields };
sub diffable { return \%userFields };
sub diffable_relationships { return { memberships => 1 } };

sub remember {
    my $me = shift;
    return unless $me->{serial};
    $me->SUPER::remember(@_);
}

sub toString {
    my $me = shift;
    my $t = join("; ", $me->getAuthors) . ": " . $me->title;
    if (length($t) >78) {
        return substr($t,0,78) . "..";
    } else {
        return $t;
    }
}

sub bestLink {
    my $me = shift;
    if ($me->{file}) {
      return "$PATHS{FILE_SCRIPT}$me->{id}";
    }
    my @links = sort { slinks($a,$b) } $me->getLinks; 
    return $#links > -1 ? $links[0] : undef;

}

sub slinks {
    my ($a,$b) = @_;
    $a =~ /\.pdf$/i ?
        ( $b =~ /\.pdf$/i ? 0 : -1 ) :
        ( $b =~ /\.pdf$/i ? 1 : 0 );
}

sub setDisplayLink {
    my ($e,$link) = @_;
    $e->{displayLink} = $link;
}

sub getAllLinks {
    my ($e,%args) = @_;
    if ($e->{displayLink}) {
        return ($e->{displayLink});
    }
    return @{$e->{__computedLinks}} if exists $e->{__computedLinks};
    my @links = $e->getLinks;
    if ($e->{file}) {
        unshift @links, "$DEFAULT_SITE->{server}/archive/$e->{id}";
    }
    if ($e->{googleBooksQuery}) {
        unshift @links, "http://books.google.com/books?id=" . $e->googleBooksId . "&printsec=front_cover";
    }
    if( length $e->{doi} ){
        push @links, "http://dx.doi.org/" . $e->{doi};
    }
    if ($args{affiliateLink}) {
        my @quotes = $e->getQuotes($args{user});
        push @links,$quotes[0]->{detailsURL} if scalar @quotes;
    }
    $e->{__computedLinks} = \@links;
    return @links;
}


sub same {
    return sameEntry(@_);
}

sub clearCatsCache {
    my $me = shift;
    delete $me->cache->{public_cats};
    delete $me->cache->{publicCatsHTML};
    $me->save_cache;
}

sub publicCats {
    my ($me,$dontSaveCache) = @_;
    unless ($me->cache->{public_cats}) { 
        my $sth = $me->dbh->prepare_cached("select cats.id from cats_me join cats on (cats_me.cId=cats.id and cats_me.eId=?) where cats.canonical");
        $sth->execute($me->id);
        my @cats;
        while (my $h = $sth->fetchrow_hashref) {
            push @cats, $h->{id};
        }
        $me->cache->{public_cats} = \@cats;
        $me->save_cache unless $dontSaveCache;
    }
   return map { xPapers::Cat->get($_) } @{$me->cache->{public_cats}};
}

sub publicCatsHTML {
    my $me = shift;
    unless (defined $me->cache->{publicCatsHTML}) {
        my @cats = sort { $a->name cmp $b->name } $me->publicCats(1);
        if ($#cats> -1) {
            my $r = "";
            for (@cats) {
                $r .= "<div><a class='catName' href='/browse/" . $_->uName . "' rel='section'>" . $_->name . "</a>";
                my $area = $_->pArea;
                if ($area and $area->{id} != $_->{id}) {
                    $r .= "<span class='catIn'> in </span><a class='catArea href='/browse/" . $area->uName . "' rel='section'>" . $area->name . "</a>";
                }
                $r .= "</div>";
            }
            $me->cache->{publicCatsHTML} = $r;
        } else {
            $me->cache->{publicCatsHTML} = "";
        }
        $me->save_cache;
    }
    return $me->cache->{publicCatsHTML};
}

sub ancestorIds {
    my $me = shift;
    my $sth = $me->dbh->prepare("select distinct aId from cats_me c join ancestors a on (c.eId=? and c.cId=a.cId)");
    $sth->execute($me->id);
    my @r;
    while (my $h = $sth->fetchrow_hashref) {
        push @r,$h->{aId};
    }
    return @r;
}

sub similar {
    my $me = shift;
    my $all = shift;
    my $limit = $all ? '' : ' limit 10';
    my $sth = $me->dbh->prepare_cached("select eId2 from relations where type='similarity' and eId1=?$limit");
    my @sim;
    $sth->execute($me->id);
    while (my $h = $sth->fetchrow_hashref) {
        my $e = xPapers::Entry->get($h->{eId2});
        push @sim,$e if $e;
    }
    return @sim;
}

sub calcSimilar {
    my $me = shift;
    my $q = xPapers::EntryMng->similar($me);
    $me->dbh->do("delete from relations where type='similarity' and eId1='$me->{id}'");
    while (my $e = $q->next) { 
        #print $e->toString . "\n";
        $me->dbh->do("insert into relations set type='similarity', eId1='$me->{id}',eId2='$e->{id}'") 
    };
}


sub downloads {
    my $me = shift;
    my $sth = $me->dbh->prepare("select viewings as nb from main where id= ?");
    $sth->execute($me->id);
    return $sth->fetchrow_hashref->{nb};
}

sub digest {
    my $me = shift;
    return $me->toString . "\n" . $me->author_abstract;
}

sub forall {
    my ($field, $func) = @_;
    my $a = $me->{$field};
    return unless ref($a) eq 'ARRAY';
    for (my $i = 0; $i <= $#$a; $i++) {
        $a->[$i] = &$func($a->[$i]);
    }
    $me->{$field} = $a;
}
sub googleBooksId {
    my $me = shift;
    return $me->googleBooksQuery =~ m!/([^/]+)$! ? $1 : undef;
}

sub syncSites {
    my ($me, $siteMap) = @_;
    $me->syncSite($_,$siteMap->{$_}) for keys %$siteMap;
}

sub syncSite {
    my ($me, $site, $catid) = @_;
    for ($me->publicCats) {
        if ($_->hasAncestor($catid)) {
            $me->addSite($site);
            return 1;
        } 
    }
    $me->removeSite($site);
    return 0;
}

sub forum_o {
    my $me = shift;
    return $me->fId ? $me->forum : $me->openForum;
}

sub openForum {
    my $me = shift;
    my $forum = xPapers::Forum->new;
    $forum->eId($me->id);
    $forum->save;
    $me->fId($forum->id);
    $me->save;
    return $forum;
}

sub journalInList {
    my ($me,$lId) = @_;
    return 0 unless $me->pub_type eq 'journal';
    my $sth = $me->dbh->prepare("select count(*) as nb from main_jlm join main_journals on (main_jlm.jlId = ? and main_jlm.jId = main_journals.id) join main on (main.id = ? and main.source = main_journals.name)");
    $sth->execute($lId,$me->{id});
    my $v = $sth->fetchrow_hashref->{nb};
    return $v;
}

sub calcPro {
    my $me = shift;
    return $me->pro if $me->forcePro;
    # a paper is pro iff one of its authors is a pro user or has a pro name
    for ($me->getAuthors) {
        my $users = xPapers::UserMng->getByName($_);
        for my $u (@$users) {
            if ($u->pro) {
                $me->pro(1);
                $me->save;
                return 1;
            } else {
            }
        }
        if (xPapers::UserMng->proName($_)) {
            $me->pro(1);
            $me->save;
            return 1;
        }
    }
    $me->pro(0);
    $me->save;
    return 0;
}

#sub calcPublished {
#	my $me = shift;
#    my @published = qw/book journal chapter thesis/;
#    push @published,'online collection';
#	$me->published( grep {$me->{pub_type} eq $_} @published );
#    return $me->published;
#}

#sub load {
#    my $i = $_[0];
#    #print STDERR "\n\nloading $i->{id}\n";
#    return shift->SUPER::load(@_);
#}
      
#sub load {
#    if ($i = shift->SUPER::load(@_)) {
#        #$i->toarrays;
#        #$i->decode_fields;
#        return $i;
#    } else { return 0 };
#}

#sub as_tree {
#    my ($me) = @_;
#
#}

sub canonical_categories_o {
    my $me = shift;
    return grep { $_->{canonical} } $me->categories_o;
}

sub categories_o {
    my $me = shift;
    if (!$me->cache->{categories}) {
        my @cats = $me->categories;
        $me->cache->{categories} = [ 
            map {$_->id} @cats
            ]; 
        $me->save_cache;
        return @cats;

    }
    return map { xPapers::Cat->new(id=>$_)->load_speculative } @{$me->cache->{categories}}
}

sub userAuthors {
    my $me = shift;
    my @res;
    for ($me->getAuthors) {
        my ($f,$l) = parseName($_);
        push @res, @{ xPapers::UserMng->get_objects(
            query=>['lastname' => { like => "$l%" }, firstname=> {like =>"$f%"}]
        ) };
    }
    return @res;
}

sub fromHash {
    my $h = shift;
    bless $h, "xPapers::Entry";
    $h->decode_fields;
    $h->toarrays;
    return $h;
}

sub calcPublished {
    my $me = shift;
    $me->published( ! ( $me->{pub_type} =~ /manuscript/ or $me->{pub_type} =~ /unknown/ ) );
    return $me->published;
}

sub update_author_index {

    my $me = shift;
    if ($me->{id}) {
        $me->dbh->do("delete from main_authors where eId='$me->{id}'");
    }
    my $good = 0;
    if ($me->{pub_type} eq 'journal' and $me->source) {
        my $j = xPapers::Journal->getByName($me->source);
        $good = ($j->popular ? 1 : 0) if $j;
    }
    foreach my $a (map { normalizeNameWhitespace($_) } $me->getAuthors) {
        my ($f,$i,$l,$s) = map { quote($_) } parseName2($a);
        my $ff = $i ? "$f $i" : $f;
        #XXX citations don't work at the moment
        my $q = "insert into main_authors set eId='$me->{id}', name = '" . quote($a) . "', year='" . quote($me->date) . "', good_journal=$good, firstname='$ff', lastname='$l', mereFirstname='$f', citations = '$e->{citations}'";
        #$me->elog("query",$q);
        $me->dbh->do($q);
        $me->addAuthorAliases( $a );
    }

}

sub addAuthorAliases {
    my( $self, $name ) = @_;
    my $sth = $self->dbh->prepare( "select * from author_aliases where name = ? limit 1" );
    $sth->execute( $name );
    return if $sth->fetchrow_arrayref;
    my ($f,$i,$l,$s) = parseName2($name);
    my ( $warnings, @weakenings ) = calcWeakenings( $f, $l );
    my $alias_sth = $self->dbh->prepare("INSERT INTO author_aliases( name, alias, is_strengthening ) VALUES(?, ?, ?)");
    for my $weakening ( @weakenings ){
        $alias_sth->execute( $name, "$weakening->{lastname}, $weakening->{firstname}", 0 );
    }

    my $potentials = $self->dbh->selectall_arrayref( 
        "select distinct name from author_aliases where alias = ? and not name = ? and not name like '%&%' ",
        { Slice => {} },
        $name, $name,
    );
    my $maxname = '';
    for my $potential( @$potentials ){
        my $pname = decode( 'utf8', $potential->{name} );
        $potential->{name} = $pname;
        $maxname = $pname if length($pname) > length($maxname);
    }
    for my $potential( @$potentials ){
        next if $potential->{name} eq $maxname;
        my $check = $self->dbh->selectall_arrayref( 
            'select * from author_aliases where name = ? and alias = ?',
            { Slice => {} },
            $maxname, $potential->{name},
        );
        if( !@$check ){
            return;
        }
    }
    my %seen;
    for my $potential( @$potentials ){
        my $pname = $potential->{name};
        next if length( $pname ) <= length( $name );
        next if $seen{$pname}++;
        next if $name eq $pname;
        # warn "Adding strengthening $eId| $name |to| $pname\n";
        $alias_sth->execute( $name, $pname, 1 );
    }
}




sub insert {
    my $i = $_[0];
    $i->pre_save;
    $i->SUPER::insert(@_);
    # reload to get serial
    $i->load;
    $i->post_save;
    $i->update_author_index;
    delete $i->{__authors_modified__};
    return $i;
}

sub update {
    my $i = $_[0];

    $i->pre_save;
    #use Data::Dumper;
    #print Dumper($i->{__xrdbopriv_modified_columns});
    #warn "mod: $authorsModified";
    $i->SUPER::update(@_);
    $i->post_save;
    $i->update_author_index if $i->{__authors_modified__};
    delete $i->{__authors_modified__};
    return $i;
}

sub pre_save {
    my $i = shift;

    die "not savable" if $i->{__not_savable};
    $i->online(($i->{file} || $i->firstLink || $i->googleBooksQuery || length($i->{doi})) ? 1 : 0);
    $i->updated('now');
    $i->pro(1) unless $i->db_src eq 'user' or $i->db_src eq 'archives';
    $i->published($i->calcPublished);
    if (!$i->{id}) {
        $i->setKey;
    }
    $i->fromarrays;
    return $i;
}

sub post_save {
    my $i = shift;
    $i->toarrays;
    return $i;
}

sub new_from_deflated_tree {
    my ($package,$tree) = @_;
    fromarrays($tree);
    my $obj = Rose::DB::Object::Helpers::new_from_deflated_tree($package,$tree);
    toarrays($tree,"nodecode");
    $obj->toarrays;
    return $obj;
}

sub setKey {
    my $i = $_[0];
    my $prefix = $_[1];

    my @a = split (',',$i->{authors}[0]);
    my @words = split(' ',$i->{title});
    my $titleabr = '';
    for (my $i = 0; $i <= 2; $i++) {
    	last if ($i > $#words);
    	$words[$i] =~ s/[^a-zA-Z_]//ig; # remove non-word characters like ':'
     	$titleabr .= uc substr($words[$i],0,1);
    }
    my $n = $a[0];
    $n =~ s/[^a-zA-Z_]//ig;
    my $nid = $prefix . uc substr($n,0, 3,'') . $titleabr;

    # append a number if necessary
    # no conflict
    if (!$i->keyExists($nid)) {
        $i->{id} = $nid;
    } 
    
    # conflict, find a suitable number to add
    else {
        my $add = 2;
        my $post = "$nid-2";
        while ($i->keyExists($post)) {
            $post = $nid . "-" . $add;
            $add++;
        }
        $i->{id} = $post;
    }
    $i->dbh->do("insert into main_ids set id = '$i->{id}'") unless $i->{__space};
}

sub keyExists {
    my ($me,$id) = @_;
    my $sth = $me->dbh->prepare("select id from main_ids where id like '$id'");
    $sth->execute;
    my $sth2 = $me->dbh->prepare("select id from " . $me->meta->table . " where id like '$id'");
    $sth2->execute;
    return (!$me->{__space} and $sth->fetchrow_hashref) || $sth2->fetchrow_hashref;
}

sub addSite {
    my ($me,$site) = @_;
    #return $me->SUPER::addSite($site) unless ref($me->{sites}) or !$me->{sites};
    my @current = $me->sites;
    return if grep { $_ eq $site } @current;
    push @current, $site;
    $me->sites(@current);
}

sub removeSite {
    my ($me, $site) = @_;
    return unless $me->{sites};
    my @n = grep { $_ ne $site } $me->sites;
    $me->sites(@n);
}

sub absorb {
    my ($me,$from) = @_;

    # absord all basic info
    $me->completeWith($from);

    # absorb local file
    $me->file($from->file) unless $me->file;

    # absorb forum
    if ($from->fId) {
        my $f = $from->forum;
        # if only the source has a forum
        if (!$me->fId) {
            $me->fId($from->fId);
            $f->eId($me->id); 
            $f->save;
        } 
        # if both have a forum. then move all the threads. 
        else {
            my $df = $me->forum;
            for my $t ($f->threads) {
                $t->fId($df->id);
                $t->save;
            }
            $df->clear_cache;
            $f->clear_cache;
        }
    }

    # absorb categories
    # we absorb even private cats
    for my $c ($from->categories) {
        my $d = $c->addEntry($me,$AUTOCAT_USER);
        $d->save if $d;
    }

    # viewings
    $me->{viewings} += $from->{viewings};

    # added date becomes earliest of the two
    $me->added($from->added) if ($me->added->subtract_datetime($from->added)->is_positive);

    $me->save;

}


sub fromarrays {
    my $i = $_[0];
    #warn "from arrays called on $i, $i->{id}";
    for my $f (keys %sp) {
        next if ref($i->{$f}) ne 'ARRAY';
        #warn "* field: $f";
        $i->{$f} =  ((';' =~ $sp{$f}) ? ";" : "") . join($spt{$f},@{$i->{$f}});
        # we want the field to be marked as modified if dealing with blessed object
        $i->$f($i->$f) if UNIVERSAL::isa($i,'xPapers::Entry');
    }
}

sub toarrays {
    my $i = $_[0];
    my $nodec = $_[1]; 
    #warn "to arrays called on $i, $i->{id}";
    #warn "from cache? $i->{__in_cache}";
    for my $f (keys %sp) {
        next if ref($i->{$f}) eq 'ARRAY';
        #warn "converting $f to array";
        my $val = $i->{$f};
        #warn "value is $val";
        $val = substr($val,1,length($i->{$f})) if ';' =~ $sp{$f};
        my @a;

        unless ($nodec or !$val or utf8::is_utf8($val)) {
            $val = decode("utf8",$val);
        }

        @a = split($sp{$f},$val);
        $i->{$f} = \@a;
    }
}

# import an old-style entry object
sub fromLegacy {
    my ($me, $e) = @_;
    for my $k ($me->meta->column_names) {
#        print "doing $k\n";
        # old arrays are copied (they get special handling in new class), other fields use accessors
        if (ref($e->{$k}) eq 'ARRAY') {
            $me->{$k} = $e->{$k};
        } else {
            eval {
            $me->$k($e->{$k});
            };
            if ($@) {
                print "Warning: (e $e->{id}) $@";
            }
        }
    }
    $me->published($e->published);
    $me->{id} = undef;
    $me;
}

sub decode_fields {
    my $i = shift;
    for my $f ($i->meta->column_names) {
        # dont decode arrays and other objects
        next if !$i->{$f} or utf8::is_utf8($i->{$f}) or $sp{$f} or ref($i->{$f});
        $i->{$f} = decode("utf8",$i->{$f});
    }
}

sub authors_string {
    my $self = shift;
    my @authors;
    for my $author ( $self->getAuthors ){
        my @names = split ',\s*', $author;
        push @authors, "$names[1] $names[0]";
    }
    my $last_one = pop @authors;
    my $result = join( ', ', @authors );
    $result .= ' and ' if $result;
    $result .= $last_one;
    return $result;
}
    
    
sub hasGoodTitle {
    my $self = shift;
    my $regexes = file2array( $DEFAULT_SITE->fullConfFile( 'exclusions/titles.txt' ) );
    for my $rx ( @$regexes ){
        return 0 if $self->title =~ /$rx/;
    }
    return 1;
}

sub commitFile {
    my ($me,$path) = @_;
    # change symlink for file
    if ($me->{file}) {
        $me->{file} =~ /\.([^\.]*?)$/;
        my $ext = $1;
        my $eid = $me->id;
        unlink "$path/$eid.$ext";
        #print "Error: ln -s $path/$me->{file} $path/$eid.$ext";
        `ln -s $path/$me->{file} $path/$eid.$ext`;
    } else {
         unlink "$path/$eid.$ext";
    }
}

sub userModified {

    my ($e, $field) = @_; 
    unless (defined $e->{__diff_cache}) {
        $e->{__diff_cache} = [ map { $_->load } @{xPapers::D->get_objects(query=>[oId=>$e->id,class=>'xPapers::Entry',or=>[uId=>{le=>2}, uId=>{gt=>10}],status=>{ge=>0},type=>'update'])} ];
    }
    for my $d (@{$e->{__diff_cache}}) {
        return 1 if exists $d->{diff}->{$field};
    }
    return 0;

}

sub completeWith {

    my ($e, $source,$mode) = @_;

    my $better = $source->betterThan($e);
    my $sameSource = (length $e->{source_id} && ($e->{source_id} eq $source->{source_id})) ? 1 : 0;
    my $changed = 0;
    #warn substr($e->{source_id},0,10);
    #$sameSource = 1 if substr($e->{source_id},0,10) eq substr($source->{source_id},0,10);

    #warn "Entry: " . $e->toString;
    #warn "Source: " . $source->toString;
    #warn "Entry is better: $better";
    #warn "Entry source_id: " . $e->source_id;
    #warn "Source source_id: " . $source->source_id;
    #warn "Same source: $sameSource";
    #warn "Source authors: " . join('; ',$source->getAuthors); 


   	foreach my $k (keys(%$e),keys(%$source)) {
        next if $k =~ /^__/; # private stuff
   		next if grep {$k eq $_} qw(sites authors ant_editors containers links id citations relations updated duplicateOf viewings);
        next if grep {$k eq $_} @AUTO_FIELDS;
        next if $e->{$k} eq $source->{$k};
        #warn "date" if $k eq 'date';
        if ($mode eq 'reverse') {
			$e->{$k} = $source->{$k};
            $changed = 1;
        } else {
            next unless $source->{$k};
            # if it's the same source, we will update the fields that have not been user-modified. except for LOC items which can have source_id clashes (#FIXME!)
            if ($better || !$e->{$k} || ( $sameSource and !$e->userModified($k) and $e->source_id !~ /^loc/) ) {
                $e->{$k} = $source->{$k}; 
                $changed = 1;
            } 

		}
   	}

    #warn "my date: $e->{date}";

    # overwrite bad abstracts with good ones
    if (!$e->{author_abstract} or length($e->{author_abstract}) < 40 and length($source->{author_abstract}) > 40) {
        $e->{author_abstract} = $source->{author_abstract};
        $changed = 1;
    }

    if ($mode ne "non-basic") {

	    # add new links
	    foreach my $nl ($source->getLinks) {
            next if grep {$nl eq $_} $e->getLinks;
	        $e->addLink($nl);
            $changed = 1;
	    }

        # if same source, not used modified, overwrite a number of fields
        if ($sameSource and !$e->userModified('authors')) {
            $e->deleteAuthors;
            $e->addAuthors($source->getAuthors);
        }
        if ($sameSource and !$e->userModified('ant_editors')) {
            $e->deleteEditors;
            $e->addEditors($source->getEditors);
        }


        # take authors if "UNKNOWN". 
        if ($e->firstAuthor =~ /UNKNOWN/i or !$e->firstAuthor) {
            $e->{authors} = [];
            $e->addAuthors($source->getAuthors);
            $changed = 1;
        }

	    # add editors
        my @eds = $e->getEditors;
        if ($#eds == -1) {
            $e->addEditor($_) for $source->getEditors;
            my @neds = $e->getEditors;
            $changed = 1 if $#neds > -1;
        } else {
            my @neds = $source->getEditors;
            if ($#neds > -1 and $better) {
                $e->{ant_editors} = []; 
                $e->addEditor($_) for $source->getEditors;
                $changed = 1;
            }
        }
        
        # add isbns and lccns
        for my $f (qw/isbn lccn/) {
            next unless $e->{$f}; # check right kind of object
            for my $n ($source->$f) {
                unless (grep { $_ eq $n } @{$e->{$f}}) {
                    push @{$e->{$f}}, $n;
                    $changed = 1;
                }
            }
        }

        # add up citations
=old
        if (!$me->{nocit}) {
            $e->{citationsLink} = $source->{citationsLink};
            if ($me->{seen}->{$e->id}) {
                $e->{citations} += $source->{citations};
            } else {
                # reset citations if first time run
                $e->{citations} = $source->{citations} if $source->{citations};
            }
            $me->{seen}->{$e->id} = 1;
        }
=cut
	}
    return $changed;


}

=old
sub addSite {
    my ($me,$site) = @_;
    return if $me->{sites} =~ /$site/;
    my @s = split(",",$me->{sites});
    push @s,$site;
    $me->{sites} = join(",",@s);
}

sub removeSite {
    my ($me, $site) = @_;
    $me->{sites} =~ s/$site,// or
    $me->{Sites} =~ s/,?$site//;
}
=cut

sub archive {
    my $me = shift;
    if ($me->{source_id} =~ /^(.*)\/\//) {
        return $1;
    } else {
        return undef;
    }
}

sub betterThan {
    my ($me,$o) = @_;
    $me->calcPublished;
    $o->calcPublished;
    if (0) {
        print "me: " . $me->toString . " $me->{pub_type}, $me->{source}, $me->{source_id}\n";
        print "o: " . $o->toString . " $o->{source_id}\n";
        print "me->published = " . $me->published . "\n";
        print "me->bad = " . $me->bad . "\n";
        print "o->published = " . $o->published . "\n";
        print "o->bad = " . $o->bad . "\n";
    }
    return 0 if $me->bad and !$o->bad;
    return 1 if !$me->bad and $o->bad;
#    return 1 if $me->bad and $o->bad and $me->{source_id} eq $o->{source_id};
    return $me->published ? (
                !$o->published ? 1 :
                (
                  ($me->{date} =~ /^\d\d\d\d$/ and $o->{date} !~ /^\d\d\d\d/ ? 1 : 0)
                  or
                  ($me->{pages} !~ /no/ and $o->{pages} =~ /no/)
                )
            ) : 0;
}

sub bad {
    my $me = shift;
    return 1 if !$me->{pub_type} or $me->{defective} or grep { $_ eq $me->{pub_type} } qw/generic unknown manuscript/ or $me->date eq 'unknown';
}

# if id field defined, not automatically calculated id
sub gotAutoId {
	return $self->{id} ? 0 : 1;
}

sub id2 {
	my $self = shift;
	my @a1 = split (',',$self->{authors}[0]);
	return "AU:$a1[0]|TI:$self->{title}";
}


sub addAuthors {
	my $self = shift;
	while (my $a = shift) {
        $self->addAuthor($a);
	}
}

sub setAuthors {
    my $self = shift;
    $self->deleteAuthors;
    $self->addAuthors(@_);
}


sub addAuthor {
	my $self = shift;
	my $a = shift;
	$a =~ s/\s*$//; #remove trailing spaces
#    return if grep {$a eq $_} @{$self->{authors}};
    push @{$self->{authors}}, $a;
    $self->{__authors_modified__} = 1;
}

sub deleteAuthors {
    my $self = shift;
    $self->{authors} = [];
    $self->{__authors_modified__} = 1;
}

sub getAuthors {
	my $self = shift;
	return @{$self->{authors}}
}

sub firstAuthor {
 	my $self = shift;
 	my @a = $self->getAuthors;
	if ($#a > -1) {
	 	return $a[0];
	} else {
     	return undef;
	}
}

sub addEditors {
	my $self = shift;
	while (my $a = shift) {
		$a =~ s/\s*$//; #remove trailing spaces
     	push @{$self->{ant_editors}}, $a;
	}
}

sub addEditor {
	my $self = shift;
	my $a = shift;
    push @{$self->{ant_editors}}, $a;
}


sub getEditors {
	my $self = shift;
	return @{$self->{ant_editors}}
}
sub deleteEditors {
    my $self = shift;
    $self->{ant_editors} = [];
}
sub addLinks {
	my $self = shift;
	while (my $a = shift) {
        $self->addLink($a);
	}
}

sub addLink {
	my $self = shift;
	my $a = shift;
    return unless $a =~ /^(https?|ftp)/;
    # hack to handle jstor's invalid urls
    if ($a =~ /jstor.org/) {
        $a =~ s/&lt;/</g;
        $a =~ s/&gt;/>/g;
    }
    push @{$self->{links}}, $a unless grep {$a eq $_} $self->getLinks;
}

sub getLinks {
	my $self = shift;
	return @{$self->{links}}
}

sub deleteLink {
 	my $self=shift;
 	my $n = shift;
 	splice(@{$self->{links}}, $n, 1);
}
sub deleteLinkMatch {
    my $self = shift;
    my $n = shift;
    my @links = $self->getLinks;
    for (0..$#links) {
        $self->deleteLink($_) if $links[$_] eq $n;
    }
}

sub deleteLinks {
    my $self = shift;
    $self->{links} = [];
}

sub firstLink {
	my $self = shift;
	return ${$self->{links}}[0];
}

sub firstComputedLink {
    my $self = shift;
    my @all = $self->getAllLinks(@_);
    return $#all > -1 ? $all[0] : undef;
}

sub getQuotes {
    my ($e,$user) = @_;
    return @{$e->{__quotes}} if exists $e->{__quotes};
    #warn "USER 3 is $user->{id}";
    my @quotes = xPapers::Link::Affiliate::QuoteMng->chooseQuotes(
        eId => $e->id,
        user => $user,
        ip => $ENV{REMOTE_ADDR}
    );
#        print Dumper(\@quotes);use Data::Dumper;
    $e->{__quotes} = \@quotes;
    return @quotes;
}

sub toString {
 	my $self = shift;
    my $first = 1;
    my $r = "";
    foreach my $a ($self->getAuthors) {
        $r .= "; " unless $first;
        $r .= $a;
        $first = 0;
    }
    $r .= " ($self->{date}). ";
    $r .= qq("$self->{title}");
	return $r;
}

sub augment {
    my $e = shift;
    if ($e->{pub_type} eq 'journal') {
        $e->{typeofwork} = $e->{review} ? 'book review' : 'article';
        $e->{pub_in} = 'journal';
        $e->{pub_status} = ($e->{date} eq 'forthcoming' ? 'forthcoming' : 'published');
    }
    elsif ($e->{pub_type} eq 'chapter') {
        $e->{typeofwork} = 'article';
        $e->{pub_in} = 'collection';
        $e->{pub_status} = ($e->{date} eq 'forthcoming' ? 'forthcoming' : 'published');
    }
    elsif ($e->{pub_type} eq 'online collection') {
        $e->{typeofwork} = 'article';
        $e->{pub_in} = 'online collection';
        $e->{pub_status} = ($e->{date} eq 'forthcoming' ? 'forthcoming' : 'published');
    }
    elsif ($e->{pub_type} eq 'online manuscript' or $e->{pub_type} eq 'manuscript') {
        $e->{typeofwork} = $e->{type} ? $e->{type} : 'article';
        if ($e->{draft}) {
            $e->{pub_status} = 'draft';
        } else {
            $e->{pub_status} = 'unpublished';
        }
        $e->{source} = undef;
        $e->{date} = undef;
        $e->{volume} = undef;
    }
    elsif ($e->{pub_type} eq 'thesis') {
        $e->{typeofwork} = 'dissertation';
        $e->{pub_status} = 'unpublished';
    }
    elsif ($e->{pub_type} eq 'book') {
        $e->{typeofwork} = 'book';
        $e->{pub_status} = ($e->{date} eq 'forthcoming' ? 'forthcoming' : 'published');
        $e->{pub_in} = undef;
    }
    elsif ($e->{pub_type} eq 'unknown') {
        $e->{typeofwork} = $e->{type} || 'article';
        $e->{pub_status} = $e->{pub_type};
        $e->{source} = undef;
        $e->{date} = undef;
        $e->{volume} = undef;
    }


}

sub popularity { 1 };

sub hardDelete {
    my $self = shift;
    my $toDelete = xPapers::ToDelete->new( id => $self->id );
    $toDelete->load;
    $toDelete->save;
    $self->deleted(1);
    $self->save;
}


__PACKAGE__->set_my_defaults;
use xPapers::EntryMng;
1;



__END__

=head1 NAME

xPapers::Entry

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>, L<xPapers::Object::Diffable>, L<xPapers::Object::WithDBCache>, L<xPapers::Object::Lockable>

Table: main


=head1 FIELDS

=head2 addToList (integer): 



=head2 added (datetime): 



=head2 ant_date (varchar): 



=head2 ant_editors (varchar): 



=head2 ant_publisher (varchar): 



=head2 author_abstract (text): 



=head2 authors (varchar): 



=head2 book (varchar): 



=head2 cacheId (integer): 



=head2 catCount (integer): 



=head2 citations (float): 



=head2 citationsLink (varchar): 



=head2 cn_alpha (varchar): 



=head2 cn_class (varchar): 



=head2 cn_full (varchar): 



=head2 cn_num (float): 



=head2 date (varchar): 



=head2 dateRP (varchar): 



=head2 db_src (varchar): 



=head2 defective (integer): 



=head2 deleted (integer): 



=head2 descriptors (varchar): 



=head2 doi (varchar): 



=head2 draft (integer): 



=head2 duplicate (integer): 



=head2 duplicateOf (varchar): 



=head2 edited (integer): 



=head2 etal (integer): 



=head2 extra (varchar): 



=head2 fId (integer): 



=head2 file (varchar): 



=head2 flags (SET): 



=head2 forcePro (integer): 



=head2 free (integer): 



=head2 googleBooksQuery (varchar): 



=head2 hasChapters (integer): 



=head2 id (varchar): 



=head2 isbn (ARRAY): 



=head2 issn (varchar): 



=head2 issue (varchar): 



=head2 lang (character): 



=head2 lccn (ARRAY): 



=head2 links (varchar): 



=head2 notes (varchar): 



=head2 online (integer): 



=head2 online_book (integer): 



=head2 originalId (varchar): 



=head2 pages (varchar): 



=head2 postCount (integer): 



=head2 pro (integer): 



=head2 pubHarvest (integer): 



=head2 pub_type (varchar): 



=head2 published (integer): 



=head2 publisher (varchar): 



=head2 replyto (varchar): 



=head2 reprint (varchar): 



=head2 review (integer): 



=head2 reviewed_title (ARRAY): 



=head2 school (varchar): 



=head2 serial (serial): 



=head2 sites (SET): 



=head2 source (varchar): 



=head2 source_id (varchar): 



=head2 source_subjects (varchar): 



=head2 title (varchar): 



=head2 type (varchar): 



=head2 updated (datetime): 



=head2 viewings (integer): 



=head2 volume (integer): 




=head1 METHODS

=head2 absorb 



=head2 addAuthor 



=head2 addAuthorAliases 



=head2 addAuthors 



=head2 addEditor 



=head2 addEditors 



=head2 addLink 



=head2 addLinks 



=head2 addSite 



=head2 ancestorIds 



=head2 archive 



=head2 augment 



=head2 authors_string 



=head2 bad 



=head2 bestLink 



=head2 betterThan 



=head2 calcPro 



=head2 calcPublished 



=head2 calcSimilar 



=head2 canonical_categories_o 



=head2 categories_o 



=head2 clearCatsCache 



=head2 commitFile 



=head2 completeWith 



=head2 decode_fields 



=head2 deleteAuthors 



=head2 deleteEditors 



=head2 deleteLink 



=head2 deleteLinkMatch 



=head2 deleteLinks 



=head2 diffable 



=head2 diffable_relationships 



=head2 digest 



=head2 downloads 



=head2 firstAuthor 



=head2 firstComputedLink 



=head2 firstLink 



=head2 forall 



=head2 forum_o 



=head2 fromHash 



=head2 fromLegacy 



=head2 fromarrays 



=head2 get 



=head2 getAllLinks 



=head2 getAuthors 



=head2 getEditors 



=head2 getLinks 



=head2 getQuotes 



=head2 googleBooksId 



=head2 gotAutoId 



=head2 hardDelete 



=head2 hasGoodTitle 



=head2 id2 



=head2 insert 



=head2 journalInList 



=head2 keyExists 



=head2 new 



=head2 new_from_deflated_tree 



=head2 openForum 



=head2 popularity 



=head2 post_save 



=head2 pre_save 



=head2 publicCats 



=head2 publicCatsHTML 



=head2 remember 



=head2 removeSite 



=head2 same 



=head2 setAuthors 



=head2 setDisplayLink 



=head2 setKey 



=head2 similar 



=head2 slinks 



=head2 syncSite 



=head2 syncSites 



=head2 toString 



=head2 toarrays 



=head2 update 



=head2 update_author_index 



=head2 userAuthors 



=head2 userFields 



=head2 userModified 



=head2 value_separators 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



