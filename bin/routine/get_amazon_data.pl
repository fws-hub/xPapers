use strict;
use warnings;

use File::Path 'make_path';
use File::Slurp 'write_file';
use Try::Tiny;
use Encode 'encode';
use DateTime;

use xPapers::Utils::System;
use xPapers::EntryMng;
use xPapers::Conf '%AMAZON';
use xPapers::Link::Affiliate::Amazon;
use xPapers::Link::Affiliate::Quote;
use xPapers::Util;

unique(1,'get_amazon_data.pl');

make_path($AMAZON{data_dir});

my $quota_duration = 60 * 60; # quota window in seconds. normally one hour. you probably don't need to change that.
my $request_quota = 2000; #max requests per hour. you can increase that if you're selling. see amazon's doc.
my $min_sleep = 0.4; #minimal sleep time between requests. might want to lower if your quota is high. but you don't need to, quotas are handled nicely even if min_sleep =0;
my $last_mark = time();
my $requests = 0;

my $q = [ '!deleted' => 1, '!isbn' => undef, '!isbn' => '', ];
if ($ARGV[0]) {
    if ($ARGV[0] eq 'recent') {
        push @$q, 'added' => { gt => DateTime->now->subtract(days=>1) }
    } else {
        push @$q, 'id' => $ARGV[0];
    }
}

my $entry_it = xPapers::EntryMng->get_objects_iterator( query => $q );

    
my $done = 0;
while( my $entry = $entry_it->next ){
    my @isbns = grep { defined } $entry->isbn;
    next if !@isbns;
    check_quota();
    xPapers::Link::Affiliate::Amazon->mkQuotes($entry);
    #warn $entry->id . "\n";
    $done++;
}

warn "No items processed" unless $done;

sub check_quota {
    if (time() - $last_mark > $quota_duration) {
        print "$requests requests performed over the past quota window. We're good.\n";
        $last_mark = time();
        $requests = 1;
    } else {
        if ($requests >= $request_quota-1) {
            my $sec = $quota_duration - (time() - $last_mark)+5;
            print "We're going to go over quota. Sleeping for $sec seconds.\n";
            sleep($sec);
            check_quota();
        } else {
            $requests++;
            sleep($min_sleep);
        }
    }
}

1;
