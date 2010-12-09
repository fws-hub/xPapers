use strict;
use warnings;

package xPapers::Utils::Lang;

my $DEBUG = 0;
use utf8;
use Text::Aspell;
use List::Util 'first';
use Encode 'decode';
use Unicode::Normalize 'decompose';
use File::Temp 'tempfile';

use xPapers::Query;
use xPapers::Conf '%PATHS';

use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT_OK = qw( splitToWords isLang hasLang checkLang addWordToOur saveOur getSuggestion );

my $SCRIPT = 'Latin';
my %COMMON_MISSPELLINGS = map { $_ => 1 } qw/ ofthe oneï /;
my $DICT_FILE = "$PATHS{LOCAL_BASE}/var/dictionary";

my $orig_speller = Text::Aspell->new;
$orig_speller->set_option('extra-dicts', 'en_GB');
my $our_speller = Text::Aspell->new;
$our_speller->set_option('encoding', "UTF-8");
$our_speller->set_option('extra-dicts',$DICT_FILE);

my %our_words;

sub splitToWords {
    my @words;
    for my $line ( @_ ){
        next if ! defined $line;
        while ($line =~ /((\p{L}\p{M}*|')+)/g) {
            my $word = $1;
            next if length($word) < 2;
            $word =~ s/^'+//;
            $word =~ s/'+$//;
            $word =~ s/'+s//;
            push @words, $word;
        }
    }
    return  @words;
    #split /\P{$SCRIPT}+/, $line;
}


sub checkLang {
    my @words = @_;
    my @recognized_words;
    my @std_words;
    my @fwords;
    my @names;
    for my $word ( @words ){
        my $std = $orig_speller->check( $word );
        if (!$std) {
            if( !$our_speller->check( $word ) ){ 
                if( $word =~ /^\p{Ll}/ ){
                    push @fwords, $word;
                }
                else{
                    push @names, $word;
                }
            } else {
                push @recognized_words, $word;
            }
        } else {
            push @recognized_words, $word;
            push @std_words, $word;
        }
    }
    my %fwords;
    my $fcount = 0;
    for my $word ( @fwords ){
        $fcount++ if !$fwords{$word}++;
    }
    my %rwords;
    my $rcount = 0;
    for my $word ( @recognized_words ){
        $rcount++ if !$rwords{$word}++;
    }
    my $ncount = 0;
    my %nwords;
    for my $word ( @names ) {
        $ncount++ if !$nwords{$word}++; 
    }
    my $scount = 0;
    my %swords;
    for my $word ( @std_words ) {
        $scount++ if !$swords{$word}++; 
    }
    my %unique;
    for my $word ( @words ) {
        $unique{$word} = 0 unless exists $unique{$word};
        $unique{$word}++;
    }

    if( @words > 1 && $DEBUG ){ 
        print "all words: @words\n\n";
        print "standard words: @std_words\n\n";
        print "foreign words: @fwords\n\n";
        print "recognized words: @recognized_words \n\n";
        print "names: @names\n\n";
    }
    return  scalar(@fwords), $fcount, 
            scalar(@recognized_words), $rcount, 
            scalar(@std_words), $scount, 
            scalar(@names), $ncount,
            scalar keys %unique;
}

sub isLang {
    my @words = splitToWords( @_ );
    #$DEBUG = 1 if (grep { $_ eq 'infinitum' } @words );
    for my $word ( @words ){
        if( $COMMON_MISSPELLINGS{$word} ){
            warn "Common misspelling: '$word' in @words\n" if $DEBUG;
            return 0;
        }
    }
    my ($allf, $fcount, $allr, $rcount, $all_std, $std_count, $alln, $ncount, $unique ) = checkLang( @words );
    #$DEBUG = 0;
    #if (grep { $_ eq 'infinitum' } @words ) {
    #    warn "recognized: $rcount, std: $std_count, total: $unique";
    #    warn 'OK'  if ( $std_count / $unique ) >= 0.7;
    #}
    return 0 unless $unique;
    return ( $std_count / $unique ) >= 0.92;
    #$fcount > $FOREIGN_TRESHOLD;
    #return $allf < ( scalar(@words) - $alln )/2;
}

sub hasLang {
    my @words = splitToWords( @_ );
    return 0 if !@words;
    #print "Checking @words\n" if $DEBUG;
    my ($allf, $fcount, $allr, $rcount, $all_std, $std_count, $alln, $ncount, $unique ) = checkLang( @words );
    #warn "Tokens: " . scalar @words;
    #warn "Recognized / total ratio is " . ($rcount/$unique);
    #warn "Dictionary / total ratio is " . ($std_count/$unique);
    #warn "In base dict (words not tokens): " . $std_count;
    return ( ($rcount / $unique >= 0.6) and ( ($std_count / $unique) >= 0.5) );
}

sub addWordToOur {
    my $word = shift;
    if( length( $word ) > 2 ){
        $our_speller->add_to_session($word);
        $our_words{$word}++;
    }
}

sub saveOur {
    my ($fh, $filename) = tempfile();
    close $fh;
    open( $fh, ">:encoding(UTF-8)", $filename );
    for my $word ( keys %our_words ){
        $word =~ s/(\P{ASCII})/remove_accents($1)/eg;
        print $fh "$word\n";
    }
    my $command = "aspell dump master $DICT_FILE >> $filename";
    print "$command\n";
    my $out = `$command`;
    print "$out\n";

    $command = "aspell --encoding=utf-8 --lang=en create master $DICT_FILE < $filename";
    print "$command\n";
    $out = `$command`;
    print "$out\n";
}

sub remove_accents {
    my $letter = shift;
    if( $letter =~ /^\p{InLatin1Supplement}$/ ){
        return $letter;
    }
    else{
        my $str = decompose( $letter );
        $str    =~ s/\P{ASCII}//g;
        return $str;
    }
}

sub getSuggestion {
    my $word = shift;
    return if length($word) < 3;
    my $alt;
    for $alt ( $our_speller->suggest( $word ) ) {
        next unless $alt;
        my $new = decode( 'utf-8', $alt );
        next if $new =~ / |-|'/ && $word !~ / |-|'/;
        return if lc($new) eq lc($word);
        my $qu = xPapers::Query->new(
            filterMode=>'advanced',
            advMode=>'fields',
            all=>$alt
        );
        $qu->prepare;
        $qu->execute;
        next if !$qu->foundRows();
        return($new);
    }
    return;
}

1;

__END__

=head1 NAME

xPapers::Utils::Lang




=head1 SUBROUTINES

=head2 addWordToOur 



=head2 checkLang 



=head2 getSuggestion 



=head2 hasLang 



=head2 isLang 



=head2 remove_accents 



=head2 saveOur 



=head2 splitToWords 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



