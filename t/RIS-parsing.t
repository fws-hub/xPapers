use Test::More;
use xPapers::Parse::RIS;
my $input =<<END;
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
END

my @parsed = xPapers::Parse::RIS::parse($input);

is($#parsed,1);
my ($e1,$e2) = @parsed;
is($e1->title,"Moore’s Paradox, Truth and Accuracy");
is($e2->title,"Review: [untitled]");
is($e1->firstAuthor,"Green, Mitchell");
is($e2->volume,20);
is($e2->issue,2);
is($e2->source,"Hypatia");
is($e2->firstAuthor,"Bergoffen, Debra");
is($e2->firstLink,"http://www.jstor.org/stable/3811176");
is($e2->review,1);

done_testing();
