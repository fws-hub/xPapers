use strict;
package xPapers::Harvest::Z3950;

use DateTime;
use Data::Dumper;
use ZOOM;
use Encode;
use File::Path qw(make_path);

use xPapers::Conf qw/ %PATHS $Z3950_SERVER $Z3950_SUBJECT_NAME /;
use xPapers::Util 'file2array';
use xPapers::Harvest::Z3950Prefix;

binmode(STDOUT,":utf8");

my @LCCN_PREFIX = map { $_->prefix } @{ xPapers::Harvest::Z3950PrefixMng->get_objects() };

my $host = $Z3950_SERVER;
my $dir = "$PATHS{LOCAL_BASE}/var/z3950";
make_path($dir);
my %done;

my $startat = "";
my $stopat = "";
my $started = 0;

my $cqf;
sub doyear {

    my $year = shift;
    my $retry = shift || 0;
    my $failedOn = shift;
    my $found = 0;
    my $query;

    eval {

        my $conn = conn();
        
        make_path( "$dir/$year" ) unless -d "$dir/$year";

        for $query (mkqueries($year)) {

            #print "$startat, $started, $query->{l}\n";
            $started = 1 if ($query->{l} eq $startat) and $startat;
            exit if ($query->{l} eq $stopat) and $stopat;
            next unless $started or !$startat;

            next if $done{$query->{l}};
            #next if $query->{l} eq $failedOn;

            $cqf = "$dir/$year/$query->{l}";
            if (-e $cqf) {
                #print "$query->{l} exists.\n";
                next;
            }

            print "Fetching $query->{l} : $query->{q}..\n";
            my $rs = $conn->search(ZOOM::Query::PQF->new($query->{q}));
            $found = $rs->size();

            if (-e $cqf and countrecs($cqf) >= $found - 3*$found/100) {
                print "$query->{l} has not changed.\n";
                $done{$query->{l}} = 1;
                next;
            }

            print "Found $found records.\n";
        
            open F, ">$cqf.tmp";
            binmode(F,":utf8");
            print F "## $query->{q}\n";

            for my $i (0..$found-1) {
                #print decode("utf8",$rs->record($i)->render);
                my $rec = $rs->record($i);
                print F $rec->render();
                #sleep(0.1);
            }

            close F;

            my $new_entries = scalar xPapers::Parse::MARCXML::parse("$cqf.tmp",$year,Amazon=>1,GoogleBooks=>1);
            print "$new_entries new entries\n";

            $done{$query->{l}} = 1;
            $rs->destroy();
            `mv $cqf.tmp $cqf`;
            $cqf = undef;
        }
        
        $conn->destroy();
    }; 
    
    if ($@) {
        die "Non-ZOOM error: $@" if !ref($@);
        print "** ERROR **\n";
        print STDERR "Error (retry=$retry) ", $@->code(), ": ", $@->message();
        print STDERR " (", $@->addinfo(), ")" if $@->addinfo();
        print STDERR "\n";
        if ($retry < 20) {
            #wait 11 min
            sleep(60*11);
            return doyear($year,$retry+1,$query->{l});
        } else {
            die "max errors reached";
        }
    }

    return $found;
}

sub conn {
    my $c = new ZOOM::Connection($host, 0);
    $c->option(preferredRecordSyntax => "xml");
    $c->option("timeout"=>400);
    return $c; 
}

sub countrecs {
    my $c = getFileContent(shift());
    my @m = $c =~ /<record xmlns/gm; 
    return $#m+1;
}

sub mkqueries {
    my $year = shift;
    my @q = (
        {
            l=>"$year.subject.$Z3950_SUBJECT_NAME",
            q=>'@and @attr 1=31 ' . $year . " \@or \@attr 1=27 $Z3950_SUBJECT_NAME \@attr 1=21 $Z3950_SUBJECT_NAME"
        }
    );
    push @q, map { 
        {
            l=> "$year.$_",
#            q=> '@and @attr 1=54 eng @and @attr 1=31 ' . $year . ' @attr 1=16 @attr 5=1 "' . $_ . '"' 
            q=> '@and @attr 1=31 ' . $year . ' @attr 1=16 @attr 5=1 "' . $_ . '"' 
        }
    } @LCCN_PREFIX;
    #push @q, map { "dc.date=$year and bath.lcCallNumber = \"$_*\"" } @LCCN_PREFIX;
    #return @q;
    #return ("bath.lcCallNumber = \"^BF*\" and dc.date = \"2000\"");
    #return ('@and @attr 1=31 2000 @attr 1=16 @attr 4=1 @attr 5=1 "BD"');
    #return ('@and @attr 1=31 2000 @attr 1=13 @attr 4=1 @attr 5=1 "BD"');
    return @q;
}

sub prefixesForRange {
    my( $start, $end ) = @_;

    return $start if $start eq $end;
    my $int_start = int($start);
    my $int_end   = int($end);
    
    if( length( $int_start ) == length( $int_end ) ){
        my $common = 0;
        while( substr( $start, $common, 1 ) eq substr( $end, $common, 1 ) ){
            $common++;
        }
            # not possible that substr( $start, $common, 1 ) > substr( $end, $common, 1 )
        my @prefixes;
        for my $i ( substr( $start, $common, 1 ) .. substr( $end, $common, 1 ) ){
            push @prefixes, substr($start, 0, $common ) . $i;
        }
        return @prefixes;
    }
    if( length( $int_start ) + 1 == length( $int_end ) ){
        if( substr( $start, 0, 1 ) <= substr( $end, 0, 1 ) ){
            return 1 .. 9;
        }
        else{
            return substr( $int_start, 0, 1 ) .. 9, 1 .. substr( $int_end, 0, 1 );
        }
    }
    else{
        return 1 .. 9;
    }
}

sub reducePrefixList {
    my @list = sort @_;
    my $old = shift @list;
    my @result = ( $old );
    while( my $next = shift @list ){
        if( substr( $next, 0, length( $old ) ) ne $old ){
            push @result, $next;
            $old = $next;
        }
    }
    return @result;
}

sub checkSize { 
    my( $conn, $prefix, $year) = @_;
    $year ||= DateTime->now->subtract( years => 2 )->year;
    my $rs = $conn->search(
        ZOOM::Query::PQF->new( '@and @attr 1=31 ' . $year . ' @attr 1=16 @attr 5=1 "' . $prefix . '"' )
    );

=do not remove
    to get all items with a call number of the form B3.x, do: @attr 3=1 @attr 5=1 "B3"
    however this makes the current server crash when combined with a year search..
=cut
    return $rs->size;
}

sub _f {
    my $xml = shift;
    if ($xml =~ /(<datafield tag="050".+?<\/datafield>)/sgmi) {
        print $1 . "\n";
    } else {
        print "Not found\n";
    }
}


sub checkSplit { 
    my( $conn, $prefix, $year) = @_;
    my $year ||= DateTime->now->subtract( years => 2 )->year;
    my $total = checkSize( $conn, $prefix, $year );
    warn "$prefix : $total\n";
    my @extensions = 0 .. 9;
push @extensions, '.';
    my $sum;
    for my $e ( @extensions ){
        my $size = checkSize( $conn, $prefix . $e, $year );
        warn "$prefix$e : $size\n";
        $sum += $size;
    }
    print "sum of extensions: $sum\n";
    return 1 if $sum == $total;
}

1;

__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




