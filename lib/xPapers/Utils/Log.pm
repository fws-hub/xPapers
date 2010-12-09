package xPapers::Utils::Log;
use IP::Country::Fast;
use POSIX qw/ceil floor/;
use xPapers::Render::HTML;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/country action lookup getcolor showeetry mycmp myjoin/;
our @EXPORT = @EXPORT_OK;
our $cl = IP::Country::Fast->new;
our %MAP = (
    journal => "xPapers::Journal",
    list => "xPapers::Cat",
    forum => "xPapers::Forum",
    thread => "xPapers::Thread",
    profile => "xPapers::User",
    advsearch => "xPapers::Query",
    post => "xPapers::Post",
    newpost => "xPapers::Post"
);
my %dnscache;
my $rend = new xPapers::Render::HTML;
$rend->{noOptions} = 1;
$rend->{showAbstract} = 0;
$rend->{noExtras} = 1;
$rend->{compact} = 1;
$rend->{cel} = "span";
$rend->{entryReady} = 1;

sub country {
    return $cl->inet_atocc(shift());
}

sub action {
    my $h = shift;
    my $col = shift;
    my $r = "<td>";
    if ($h->{action} eq "browse") {

        $r .=uc substr($h->{site},0,1) . ":";
        if ($h->{catId} eq "intro") {
            $r .= "$h->{catId}";
        } elsif ($h->{catId} eq "") {
           $r .= "misc"; 
        } else {
        $r .= "$h->{catId}. $h->{name}";
		}

    } elsif ($h->{action} eq "search") {
            $h->{x} =~ /^.+?:=(.+?)\|.+?:=(.*?)$/;
            $r .= "<a href='/autosense.pl?searchStr=$1'>$1</a>";
    } elsif ($h->{action} eq "go") {
		my $e = xPapers::Entry->get($h->{entryId});
		$r .= showentry($e);
    } elsif ($h->{action} eq "edit") {

            if ($h->{entryId} eq "*NEW*") {
                $r.= "NEW";
            } else {
                my $e = xPapers::Entry->get($h->{entryId});
                $r .= showentry($e);
            }
            $r .= " [<font color='black'>" . myjoin(", ",($h->{name},$h->{email})) . "</font>]" if $h->{name} or $h->{email};
    } elsif ($MAP{$h->{action}}) {  
            my $ent = $MAP{$h->{action}}->get($h->{x});
            if ($ent) {
                $r .= $rend->renderObject($ent);
                #$r .= $ent->toString;
            } else {
                $r .= "Entity not found (deleted?)";
            }
    } elsif ($h->{action} eq 'ajax' and $h->{x} =~ /c:=addToList\|eId:=(.+)\|lId:=(.+)/) {
            $r .= "Add <a href='/rec/$1'>$1</a> to " . $rend->renderCatC(xPapers::Cat->get($2));
    } else {
            $r .= "$h->{x}";
    }
    $r .= " [x$h->{nb}]" if $h->{nb} > 1;
    $r .= "</td>";

    if ($h->{referer}) {
        my $hd = $h->{referer};
        $hd = substr($h->{referer},0,100) . "..." if length($h->{referer}) > 100;
        $r .= "<tr><td colspan=2 bgcolor='$col'><td colspan=5 align=left bgcolor='$col' style='font-size:normal;'>from <a href='$h->{referer}'>$hd</a></td></tr>";
    }
    return $r;
}

sub showentry {
    my $e = shift;
    return "" unless $e;
    return $rend->renderEntry($e);
#    return "" unless $e;
#    return $e->toStringHTML . " [$e->{firstParentNumId}]";
}

sub myjoin {
    my $sep = shift;
    my $r = shift;
    $r .= $_ ? "$sep$_" : "" for @_;
    return $r;
}

sub getcolor {
    our (%colors,$prev_col);

    my $t = shift;
    my @m = qw/7 8 9 A B C D E F/;
    if (!$colors{$t}) {
        do {
            my ($r,$g,$b) = ($m[ceil(rand(8))],$m[ceil(rand(8))],$m[ceil(rand(8))]);
            $colors{$t} = "${r}F${g}F${b}F"; 
        } while ($colors{$t} eq $prev_col);
    }
    $prev_col = $colors{$t};
    return $colors{$t};
}

sub mycmp {
    my ($a,$b) = @_;
    return (($a->{hour} <=> $b->{hour}) != 0) ? ($a->{hour} <=> $b->{hour}) :
           (($a->{tracker} cmp $b->{tracker}) != 0) ? ($a->{tracker} cmp $b->{tracker}) :
           ($a->{time} cmp $b->{time});
#    my $v =  substr($a->{time}, 0, 5) cmp substr($b->{time}, 0, 5);
#    return $v unless $v == 0;
#    return $a->{tracker} cmp $b->{tracker} unless $a->{tracker} eq $b->{tracker};
#    return $a->{time} cmp $b->{time};
}

sub lookup {
    my $ip = shift;
    return $ip unless $ip=~/\d+\.\d+\.\d+\.\d+/;
    my $sig = $SIG{ALRM};
    $SIG{ALRM} = sub {die "timeout"};
    unless (exists $dnscache{$ip}) {
        my @h = eval {
            alarm(0.1);
            my @i = gethostbyaddr(pack('C4',split('\.',$ip)),2);
            alarm(0);
            @i;
        };
        $dnscache{$ip} = $h[0] || undef;
        $SIG{ARLM} = $sig;
        return $h[0] . " - $ip";
    }
    $SIG{ALRM} = $sig;
    return $dnscache{$ip} || $ip;
}
1;
__END__

=head1 NAME

xPapers::Utils::Log




=head1 SUBROUTINES

=head2 action 



=head2 country 



=head2 getcolor 



=head2 lookup 



=head2 mycmp 



=head2 myjoin 



=head2 showentry 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



