package xPapers::Parse::RIS;
use xPapers::Entry;
use xPapers::Util;

sub parse {
    my $c = shift;
    my @res;
    my %r;
    my $started = 0;
    for my $line (split(/[\r\n]/,$c)) {
        next unless $line =~ /\w/;
        if ($line =~ /^(PT|TY)\b/) {
            my $e = parseStruct(\%r);
            push @res,$e if $e and $e->title;
            %r = ();
        }
        $line = rmTags($line);
        if ($line =~ /^([A-Z][A-Z0-9]{1,2})\s+-\s(.*)$/) {
            $tag = $1;
            # this is a list field
            if (defined $r{$tag}) {
                unless (ref($r{$tag}) eq 'ARRAY') {
                    #print "listying $tag\n";
                    my @list;
                    push @list,$r{$tag}; 
                    $r{$tag} = \@list;
                }
                #print "$tag => $2\n";
                push @{$r{$tag}}, $2;
            } else {
                $r{$tag} = $2;
            }
        } 
        # looks like we're continuing previous field 
        else {
            #die "extending $tag";
            $r{$tag} .= " $line";
        }
    }
    my $e = parseStruct(\%r);
    push @res,$e if $e and $e->title;
    return @res;
}


sub parseStruct {
    my %r = %{shift()};
    #print Dumper($r{AU});
    #print Dumper(\%r);

    my $entry = xPapers::Entry->new;

    my @au = ref($r{AU}) ? @{$r{AU}} : $r{AU};
    $entry->setAuthors(map { composeName(parseName($_)) } @au);
    $entry->title($r{TI});
    $entry->source($r{JT}|$r{JO});
    $entry->pub_type('journal');
    $entry->type('article');
    $entry->author_abstract($r{AB}) if $r{AB};
    if ($r{VL} and $r{IP}) {
        $entry->volume($r{VL});
        $entry->issue($r{IP});
        $entry->pages($r{PG});
        if ($r->{DP} =~ /^(\d\d\d\d)/) {
            $entry->date($1);
        } else {
            if ($r{DP} =~ /^(\d{4,4})/) {
                $entry->date($1);
            } else {
                die "No date found";
            }
        }
    } elsif ($r{VL} and $r{IS}) {
        $entry->volume($r{VL});
        $entry->issue($r{IS});
        $entry->pages("$r{SP} - $r{EP}");
    } else {
        $entry->date('forthcoming');
    }
    if ($r{M1} =~ /ArticleType: ([^\s]+)/) {
        if ($1 eq 'book-review') {
            $entry->review(1);
        } elsif ($1 eq 'misc') {
            return undef;
        }
    }
    if ($r{AID} =~ /^(.+)\s*\[doi\]/) {
        $entry->doi($1);
    }
    $entry->addLink($r{UR});

    return $entry;
}

1;
=examples

encode:

PT - JOURNAL ARTICLE

AU  - Green, Mitchell

AU  - Williams, John

TI  - Moore’s Paradox, Truth and Accuracy

JT  - Acta Analytica

DP  - 2010 Oct 26

DEP - 20101026

PB  - Springer Netherlands

IS  - 1874-6349 (Electronic)

IS  - 0353-5150 (Linking)

AB  - G. E. Moore famously observed that to assert ‘I went to the pictures last Tuesday but I do not believe that I did’ would be ‘absurd’. Moore calls it a ‘paradox’ that this absurdity persists despite the fact that what I say about myself might be true. Krista Lawlor and John Perry have proposed an explanation of the absurdity that confines itself to semantic notions while eschewing pragmatic ones. We argue that this explanation faces four objections. We give a better explanation of the absurdity both in assertion and in belief that avoids our four objections.

AD  - Department of Philosophy, University of Virginia, 120 Cocke Hall, Charlottesville, VA 22904-4780, USA

PG  - 1-13

UR  - http://dx.doi.org/10.1007/s12136-010-0110-0

AID - 10.1007/s12136-010-0110-0 [doi]


TY  - JOUR
JO  - Hypatia
TI  - Review: [untitled]
VL  - 20
IS  - 2
PB  - Blackwell Publishing on behalf of Hypatia, Inc.
SN  - 08875367
UR  - http://www.jstor.org/stable/3811176
AU  - Bergoffen, Debra
T3  - 
Y1  - 2005/04/01
SP  - 202
EP  - 207
CR  - Copyright &#169; 2005 Hypatia, Inc.
M1  - ArticleType: book-review / Issue Title: Contemporary Feminist Philosophy in German / Full publication date: Spring, 2005 / Copyright © 2005 Hypatia, Inc.
ER  - 


=cut
