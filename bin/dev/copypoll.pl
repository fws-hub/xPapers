use xPapers::Polls::Poll;
use xPapers::Polls::Question;
use xPapers::Polls::AnswerOption;
use xPapers::Polls::Answer;
use xPapers::Polls::PollOptions;
use xPapers::User;

my $orig = xPapers::Polls::Poll->get($ARGV[0]);
my $new = xPapers::Polls::Poll->new;

for my $column ($orig->meta->column_names) {
    next if $column eq 'id';
    $new->$column($orig->$column);
}
$new->save;

for my $opt (@{xPapers::Polls::PollOptionsMng->get_objects(query=>[poId=>$orig->id])}) {
    if ($opt->publish) {
        my $x = xPapers::User->get($opt->uId)->x;
        $x->publishView(1);
        $x->save;
    }
    my $np = xPapers::Polls::PollOptions->new;
    for my $column ($opt->meta->column_names) {
        next if $column eq 'id';
        next if $column eq 'poId';
        $np->$column($opt->$column);
    }
    $np->poId($new->id);
    $np->save;
}


# copy questions, options, answers
for my $qo (@{xPapers::Polls::QuestionMng->get_objects(query=>[poId=>$orig->id])}) {

    print "Cloning question: $qo->{question}\n";
    # the question
    my $qn = xPapers::Polls::Question->new;
    for my $column ($qo->meta->column_names) {
        next if $column eq 'id';
        next if $column eq 'poId';
        $qn->$column($qo->$column);
    }
    $qn->poId($new->id);
    $qn->prototype($qo->id) unless $qn->prototype;
    $qn->save;

    # the options
    my %opt_map;
    for my $oo (@{xPapers::Polls::AnswerOptionsMng->get_objects(query=>[qId=>$qo->id],sort_by=>['follow asc'])}) {
        print "Cloning option: $oo->{value}\n";
        my $on = xPapers::Polls::AnswerOption->new;
        for my $column ($oo->meta->column_names) {
            next if $column eq 'id';
            next if $column eq 'qId';
            $on->$column($oo->$column);
        }
        if ($oo->follow and $opt_map{$oo->follow}) {
            $on->follow($opt_map{$oo->follow});
        }
        $on->qId($qn->id);
        $on->save;
        $opt_map{$oo->id} = $on->id;

        # the answers
        for my $ao (@{xPapers::Polls::AnswerMng->get_objects(query=>[anId=>$oo->id])}) {
            my $an = xPapers::Polls::Answer->new;
            for my $column ($ao->meta->column_names) {
                next if $column eq 'id';
                next if $column eq 'qId';
                next if $column eq 'anId';
                $an->$column($ao->$column);
            }
            $an->qId($qn->id);
            $an->anId($on->id);
            $an->created('now');
            $an->superseded(undef);
            $an->save;
        }
    }
}
print "New id: $new->{id}\n";
