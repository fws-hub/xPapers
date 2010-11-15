use xPapers::Util;
use xPapers::Entry;
use Test::More;

my @samePersonYes = ( 
    [ [ 'D. Bourget', 'Chalmers D' ], ['David J. R. Bourget','David C Chalmers'] ],
    [ [ 'J wilson' ], ['Jessica WILSON'] ],
    [ [ 'J. Wilson' ], ['Jessica M. WILSON'] ]
);

my @samePersonNo = (
    [ [ 'D. Bourget', 'J Wilson' ], ['D. Chalmers', 'J Wilson'] ],
    [ [ 'D. Bourget', 'J Wilson' ], ['J Wilson'] ]
);

ok( sameAuthors($_->[0],$_->[1]), join(";",@{$_->[0]}) . " = " . join(";",@{$_->[1]})) for @samePersonYes;
ok( !sameAuthors($_->[0],$_->[1]), join(";",@{$_->[0]}) . " != " . join(";",@{$_->[1]})) for @samePersonNo;

my $e1 = new xPapers::Entry;
my $e2 = new xPapers::Entry;
my @authors = ('Bourget, David');
$e1->addAuthors(@authors);
$e2->addAuthors(@authors);
$e1->date(2009);
$e2->date(2009);

# Test numeric difference
$e1->{title} = "Chapter 1 of xyz";
$e2->{title} = "Chapter 2 of xyz";
same($e1,$e2,0);

$e1->{title} = "IV- The first pakladjs lkasdjf ";
$e2->{title} = "X- The first pakladjs lkasdjft ";
same($e1,$e2,0);

$e1->{title} = "Theories of consciousness I";
$e2->{title} = "Theories of consciousness 2";
same($e1,$e2,0);

$e1->{title} = "Theories of consciousness:part I";
$e2->{title} = "Theories of consciousness:part 2";
same($e1,$e2,0);

$e1->{title} = "A book with a bracket (yes? !)";
$e2->{title} = "A book with a bracket";
same($e1,$e2,1);

$e1->{title} = "Coyer and the Enlightenment (Studies on Voltaire)";
$e2->{title} = "Coyer and the Enlightenment";
same($e1,$e2,1);

$e1 = new xPapers::Entry;
$e2 = new xPapers::Entry;
my @authors = ('Abernethy, George L.');
$e1->addAuthors(@authors);
$e2->addAuthors(@authors, 'Langford, Thomas A.');
$e1->date(1968);
$e2->date(1968);

$e1->{title} = "Philosophy of Religion";
$e2->{title} = "Philosophy of Religion: A Book of Readings";
same($e1,$e2,1);

$e1 = new xPapers::Entry;
$e2 = new xPapers::Entry;
my @authors = ('Abbot, Francis Ellingwood');
$e1->addAuthors(@authors);
$e2->addAuthors(@authors);
$e1->date(1890);
$e2->date(2010);

$e1->{title} = "The Way Out of Agnosticism: Or, the Philosophy of Free Religion";
$e2->{title} = "The Way Out of Agnosticism, Or, the Philosophy of Free Religion [Microform]";
same($e1,$e2,1);

$e1->date(2008);
$e2->date(2008);
$e1->{title} = "Market Versus Nature: The Social Phiosophy [I.E. Philosophy] of Friedrich Hayek";
$e2->{title} = "Market Versus Nature: the Social Philosophy of Friedrich Hayek";
same($e1,$e2,1);

$e1->{title} = "The Philosophy of John Norris of Bemerton: (1657-1712)";
$e2->{title} = "The philosophy of John Norris of Bemerton: (1657-1712) (Studien und Materialien zur Geschichte der Philosophie : Kleine Reihe ; Bd. 6)";
same($e1,$e2,1);

$e1->{title} = "The Philosophy of John Norris of Bemerton: (1657-1712)";
$e2->{title} = "The philosophy of John Norris of Bemerton: (1657-1712)";
same($e1,$e2,1);

$e1->{title} = "The Philosophy of John Norris of Bemerton: (1657-1712)";
$e2->{title} = "The philosophy of John Norris of Bemerton: (1657-2000)";
same($e1,$e2,0);

$e1->{title} = "Communitarian International Relations: The Epistemic Foundations of International Relations";
$e2->{title} = "Communitarian International Relations: The Epistemic Foundations of International Relations (New International Relations)";
same($e1,$e2,1);

$e1->{title} = '"What is an Apparatus?" and Other Essays';
$e2->{title} = '"What Is an Apparatus?" and Other Essays (Meridian: Crossing Aesthetics)';
same($e1,$e2,1);

$e1->{title} = 'Clearly not the same kalsdfjl;sdfajdfsa lfdkasjfadslkajsdf lasdfkjaf';
$e2->{title} = 'Clearny same the not .x,zcmnvcx zm,xcvnxvc ,mxcvzn xcvxm,zcvnvxc zvv';
same($e1,$e2,0);

$e1->{title} = "Much Ado About 'Something': Critical Notice of Chalmers, Manley, Wasserman, Metametaphysics.";
$e2->{title} = "Much Ado About 'Something'.";

$e1->deleteAuthors;
$e2->deleteAuthors;
$e1->addAuthor('Wilson, Jessica M.');
$e2->addAuthor('Wilson, J.');
same($e1,$e2,1);

check(
    ['Dummett, Michael'],
    1973,
    'Frege',
    ['Dummett, Michael'],
    1991,
    'Frege: Philosophy of Mathematics',
    0
);

check(
    ['Russell, Bertrand'],
    "2009",
    "Bertrand Russell's Best",
    ['Russell, Bertrand'],
    "2009",
    "Bertrand Russell's Best",
    1
);

#
# Common cases of degraded metadata
#

# missing firstname
check(
    ['Russell, '],
    "2009",
    "Short",
    ['Russell, B'],
    "2009",
    "Short",
    1
);

check(
    ['John Doe, By'],
    2009,
    'The same title',
    ['Doe, John'],
    2009,
    'The same title',
    1
);

#unsplit name
check(
    ['John Doe'],
    2009,
    'The same title',
    ['Doe, John'],
    2009,
    'The same title',
    1
);



sub same {
    my ($e1,$e2,$same) = @_;
    is($e1->same($e2),$same, $e1->toString . ' ' . ($same ? ' == ' : ' != ') . ' ' . $e2->toString);
}

sub check {
    my ($authors1, $date1, $title1, $authors2, $date2, $title2, $yes) = @_;
    my $e1 = xPapers::Entry->new(title=>$title1,date=>$date1);
    $e1->addAuthors(@$authors1);
    my $e2 = xPapers::Entry->new(title=>$title2,date=>$date2);
    $e2->addAuthors(@$authors2);
    return same($e1,$e2,$yes);
}

done_testing;
