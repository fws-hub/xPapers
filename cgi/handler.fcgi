#!/usr/bin/perl -X
use lib '/home/xpapers/lib';
use CGI::Fast;                                                                 
use xPapers::Conf;
use xPapers::Utils::CGI qw(checkParams);
use HTML::Mason::CGIHandler;
use File::Spec::Functions qw/ catfile catdir /;
use xPapers::Site;

{                                                                              
    package HTML::Mason::Commands;                                             
    # Imported by components
                                                                               
    @ISA = qw/Exporter/;
    @EXPORT = qw/%b $q/;
    @EXPORT_OK = @EXPORT;

    use Time::HiRes qw/gettimeofday tv_interval/;
    use POSIX qw/floor ceil/;
    use Try::Tiny;
    use xPapers::Entry;
    use xPapers::Util;
    use xPapers::Render::HTML;
    use xPapers::Render::JSON;
    use xPapers::Render::Text;
    use xPapers::Render::RichText;
    use xPapers::Render::BibTeX;
    use xPapers::Render::EndNote;
    use xPapers::Render::RIS;
    use xPapers::Render::RSS;
    use xPapers::Render::Email;
    use xPapers::Render::Embed;
    use xPapers::Link::Free;
    use xPapers::Link::Resolver;
    use xPapers::Link::SherpaRomeo;
    use xPapers::Utils::System;
    use Rose::DateTime::Util qw(:all);
    use Rose::DB::Object::QueryBuilder;
    use JSON::XS qw/encode_json decode_json/;
    use Convert::Base32;
    use DateTime;
    use Number::Format qw(format_number);
    use HTML::Entities;
    use xPapers::Utils::Toolbox;
    use xPapers::Render::Coins;
    use xPapers::Conf;
    use xPapers::Conf::Forums;
    use xPapers::Conf::Cats;
    use xPapers::Conf::Surveys;
    use xPapers::Utils::CGI;
    use xPapers::Diff;
    use xPapers::User;
    use xPapers::UserMng; # User manager
    use xPapers::PostMng; # Post manager
    use xPapers::QueryMng; # Queries
    use xPapers::GroupMng;
    use xPapers::CatMng;
    use xPapers::Query;
    use xPapers::Cat;
    use xPapers::Forum;
    use xPapers::Thread;
    use xPapers::Post;
    use xPapers::Inst;
    use xPapers::Affil;
    use xPapers::Lock;
    use xPapers::Mail::Message;
    use xPapers::Invite;
    use xPapers::Utils::Error;
    use xPapers::Operations::ImportEntries;
    use xPapers::Journal;
    use xPapers::JournalList;
    use xPapers::JournalListMng;
    use xPapers::Alert;
    use xPapers::Feed;
    use xPapers::Operations::UpdateCats;
    use xPapers::Render::GChart;
    use xPapers::LCRange;
    $xPapers::Render::GChart::COLOR = $C2;
    my @cols = ($C2,$C1,$C3);
    push @cols,qw/FF0000 FF8040 FFFF00 00FF00 00FFFF 0000FF 800080 000000/;
    $xPapers::Render::GChart::COLORS = join(",",@cols);
    $xPapers::Render::GChart::TZ = $TIMEZONE;
    use xPapers::Pages::Page;
    use xPapers::Pages::PageMng;
    use xPapers::Pages::PageAuthor;
    use xPapers::Pages::AuthorMng;
    use xPapers::Relations::PageAuthorArea;
    use xPapers::Editorship;
    use xPapers::OAI::Repository;
    use xPapers::OAI::Harvester;
    use xPapers::Polls::Poll;
    use xPapers::Polls::Question;
    use xPapers::Polls::Answer;
    use xPapers::Polls::AnswerOption;
    use xPapers::Polls::PollOptions;
    use HTTP::BrowserDetect;
    use Data::Dumper qw/Dumper/;
    use Storable qw/thaw freeze dclone/;
    use Lingua::EN::Inflect;
    $Storable::canonical = 0;
    use xPapers::Utils::Profiler;

    #$CGI::Fast::DISABLE_UPLOADS;
    #$CGI::DISABLE_UPLOADS;

    our $freeChecker = new xPapers::Link::Free;
    $freeChecker->init(site=>$DEFAULT_SITE);

    our $REQ_LOGGED;
    our %ORIG_ARGS;
    my $s = $DEFAULT_SITE;

    my $hostname = `hostname`;
    chomp $hostname;
    our $domain = $HOSTS{$hostname};

    sub error {
        my $e = shift;
        my $embed = shift;
        our $HTTP_HEADER_SENT = 0;
        our $HEADER_SENT = 0;
        our $user;
        our $AJX;
        if (!$AJX) {
            print STDOUT "Content-type: text/html\n\n";
            $HTTP_HEADER_SENT = 1;
            print STDOUT $m->scomp("/header.html") unless $embed;
            print STDOUT <<END;
                <div id='errcontent'>
                <h2 style='color:#$C1'>Ooops</h2>
                <b>$e</b>
                </div>

END
            print STDOUT $m->scomp("/footer.html") unless $embed;
        } else {
            print STDOUT "Content-type: text/plain\n\n";
            print STDOUT "__PPError: $e\n";
        }
        #$m->flush_buffer;

        my $err = xPapers::Utils::Error->new(
            type=>1, 
            ip=>$ENV{REMOTE_ADDR}, 
            pid=>$$,
            request_uri=>$ENV{REQUEST_URI},
            host=>$ENV{REMOTE_HOST},
            cookies=>$q->raw_cookie(),
            referer=>$ENV{HTTP_REFERER},
            args=>Dumper(\%ORIG_ARGS),
            uId=>$user->{id},
            user_agent=>$ENV{HTTP_USER_AGENT},
            info=>$e
        );
        $err->save;

        $m->abort;
    }

    sub redirect {
        my ($s, $q, $url, $code) = @_;
        $code ||= 307;
        #print $q->header('text/html');
        print STDOUT $q->header(-code=>$code, -location=>$url);
        #print STDERR $q->header('text/html');
        #print STDERR $q->header(-code=>307, -location=>$url);
        $m->flush_buffer;
        $m->abort;
    }

    sub notfound {
        my $q = shift;
        print STDOUT $q->header(-code=>404);
        print STDOUT "<h1>File not found</h1>";
        print STDOUT "The file you requested cannot be found on this server";
        $m->flush_buffer;
        $m->abort;
    }


    sub jserror {
        my $msg = shift;
        our $HTTP_HEADER_SENT;
        print STDOUT "Content-type: text/html\n\n" unless $HTTP_HEADER_SENT;
        $HTTP_HEADER_SENT = 1;
        print STDOUT "__PPError: $msg";
        $m->flush_buffer;
        our $user;
        my $err = xPapers::Utils::Error->new(
            type=>2, 
            ip=>$ENV{REMOTE_ADDR}, 
            pid=>$$,
            request_uri=>$ENV{REQUEST_URI},
            cookies=>$q->raw_cookie(),
            host=>$ENV{REMOTE_HOST},
            referer=>$ENV{HTTP_REFERER},
            args=>Dumper(\%ORIG_ARGS),
            uId=>$user->{id},
            user_agent=>$ENV{HTTP_USER_AGENT},
            info=>$msg
        );
        $err->save;

        $m->abort;
    }

    sub elog {
        open L, ">>$ELOG";
        binmode(L,":utf8");
        print L shift() . "\n";
        close L;
    }

}                                                                              


my %sites;
my %handlers;
for my $site ( keys %SITES ){
    $sites{$site} = xPapers::Site->new(  LOCAL_BASE => $LOCAL_BASE, %{ $SITES{ $site } } );
    $handlers{$site} = HTML::Mason::CGIHandler->new(
        comp_root => $sites{$site}->masonRoots,
        auto_send_headers => 0,
        data_dir => $sites{$site}->masonDataRoot,   
        enable_autoflush=> 0,
        error_mode => 'fatal',               
        error_format => 'html',
        allow_globals => [qw($TOO_BUSY $domain $ac $freeChecker $browser %CACHE $AJX $tz_offset $filters $root @COOKIES_OUT $HTTP_HEADER_SENT $HEADER_SENT $NOOPTIONS $USING_PK $HTML $TIME %SITES $NOFOOT $SECURE $SAFE_PARAMS $PATHS $user $tracker $u $q %b %r %m $s $BROWSER $rend $filter %misc )]
    );             
}
binmode(STDOUT,":utf8");
binmode(STDERR,":utf8");
my $served_reqs = 0;
my $max_reqs = 4000 + rand(2000);
my %ids = ( profile => 'id', browse => 'cId', groups => 'gId', polls => 'poId', pub => 'pub', post => 'pId', feed => 'feed', rec => 'id', archive => 'aid', sep => 'sepId' );
my %special_components = ( polls => 'polls/answer.pl', post => 'bbs/post.pl', feed => 'index.html', rec => 'entry.html', archive => 'go.pl' );

FCGI: while ($q = new CGI::Fast) {

    $s = $sites{$ENV{SITE}} || $sites{$DEFAULT_SITE_NAME};
    
    $REQ_LOGGED = 0;
    $served_reqs++;

    # check CGI params 
    if (!checkParams($q,\%xPapers::Conf::VALID_VALUES)) {
       next FCGI;
    }
    my $path_info = $q->path_info;
    my $new_path;
    for my $root ( @{ $s->masonRoots } ){
        if( -d catdir( $root->[1], $path_info ) && -f catfile( $root->[1], $path_info, 'index.html' ) ){
            $new_path = catfile( $path_info, 'index.html' );
            last;
        }
        elsif( -f catfile( $root->[1] . $path_info ) ){
            $new_path = $path_info;
        }
    }
    $new_path =~ s{^/}{};
    
    if( !$new_path ){
        my @parts = split qr{/}, $path_info ; 
        shift @parts if !length( $parts[0] );
        #warn "parts: >@parts<\n";
        #warn index( $parts[1], '.' );
        #warn $parts[1] =~ /^\d+$/;
        if ($parts[0] eq 's') {
            $new_path="autosense.pl";
            $q->param('searchStr',$parts[1]);
        }
        elsif( $parts[0] eq 'browse' && $parts[1] eq 'all' ){
            $new_path = 'utils/allcats.pl';
            #warn $new_path;
        }
        elsif( $parts[0] eq 'browse' 
            && index( $parts[1], '.' ) == -1 
            && $parts[1] !~ /^\d+$/
        ){
            $q->param( cn => $parts[1] );
            if( ! $parts[2] ){
                $new_path = "$parts[0]/index.html";
            }
            else{
                $new_path = "$parts[0]/$parts[2]";
            }
        }
        elsif( $ids{ $parts[0] } ){
            $q->param( $ids{$parts[0]} => $parts[1] );
            if( $special_components{$parts[0]} ){
                $new_path = $special_components{$parts[0]};
            }
            elsif( $parts[0] eq 'pub' ){
                $new_path = 'asearch.pl';
                if( $parts[2] ){
                    $q->param( year => $parts[2] );
                }
            }
            elsif( $parts[2] ){
                $new_path = "$parts[0]/$parts[2]";
            }
            else{
                $new_path = "$parts[0]/index.html";
            }
        }
        elsif( $parts[0] eq 'journals' ){
            $new_path = "/pubs.pl";
            $q->param( journals => 1 );
        }
        elsif( $parts[0] eq 'pages' && !length( $parts[1] ) ){
            $new_path = "/pages/list.html";
        }
    }
    #warn 'PATH_INFO: ' . $q->path_info . "\n";
    #warn 'SCRIPT_NAME: ' . $q->script_name. "\n";
    #warn 'PATH_TRANSLATED: ' . $q->path_translated . "\n";
    #warn "new_path: $new_path\n";
    #warn 'query params: ' . Dumper( scalar $q->Vars ); use Data::Dumper;
    #warn $ENV{REQUEST_URI};
    $q->path_info( $new_path );

    # hand off to mason
    my $h = $handlers{$ENV{SITE}||$DEFAULT_SITE_NAME};
    $q->{__site__} = $s;
    eval { $h->handle_cgi_object($q) };                                      

    our $user;
    our $HTTP_HEADER_SENT;

    if (my $raw_error = $@) {                                                  
       
        if ($raw_error =~ /could not find component for initial path/) {
                print $q->header(code=>404);
                print "<h1>File not found</h1>";
                print "The file you requested cannot be found on this server";
                next FCGI;
        }
        print $q->header unless $HTTP_HEADER_SENT;
        print "<center><br><br><br><br>";
        my $msg = $ERROR_MESSAGE;
        if ($SECURE) {
           $msg =~ s/__DETAILS__/$raw_error/; 
        } else {
           $msg =~ s/__DETAILS__//;
        }
        print $msg;
        #print "<hr>$raw_error";
        my $err = xPapers::Utils::Error->new(
            type=>10, 
            ip=>$ENV{REMOTE_ADDR}, 
            uId=>$user->{id},
            pid=>$$,
            host=>$ENV{REMOTE_HOST},
            referer=>$ENV{HTTP_REFERER},
            request_uri=>$ENV{REQUEST_URI},
            args=>join("\n", map { "$_: " . $q->param($_) } $q->param ),
            info=>$raw_error,
        );
        $err->save;

    }                                                                          

    exit 0 if $served_reqs >= $max_reqs;

}                                                                              
                                                                               
exit 0;                                                                        

