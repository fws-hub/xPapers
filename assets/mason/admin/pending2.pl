<& ../header.html, %ARGS,subtitle=>"Pending changes" &>
<& style.html &>

<script type="text/javascript">
    function acceptDiff(dId) {
        admAct("acceptPagesDiff",{dId:dId},function(r) {
            $('diff-'+dId).hide();
        });
    }

    function rejectDiff(dId,msg) {
        admAct("rejectDiff",{dId:dId,msg:msg},function() {
            $('diff-'+dId).hide();
        });
    }

</script>


<% gh("Pending changes to tracked pages") %>

<table style="min-width:800px;">

<%perl>
return unless $SECURE;
use xPapers::Pages::Page;
use xPapers::Pages::PageAuthor;
use Data::Dumper;
my $diffs = xPapers::D->get_objects(
    query => [
        class => ['xPapers::Pages::Page', 'xPapers::Pages::PageAuthor'],
        and => [ status => {lt => 1} , status => { gt => -1 } ], # = 0 doesn't seem to work..
    ],
    sort_by => 'id asc',
);

for my $diff (@$diffs) {
    show_diff($diff);
}

sub show_diff {
    my $diff = shift;
    $diff->load;
    my $user = $diff->uId ? $diff->user->fullname . "<span class='hint'> (" . $diff->user->id . ")</span>"  : "Guest";
    my $ob = $diff->object;
    my $time = $diff->created->ymd.' '.$diff->created->hms;
    my $author = $ob->{author_id} ? xPapers::Pages::PageAuthor->get($ob->{author_id}) : $ob;
    my $title = "$author->{firstname} $author->{lastname}";
    if ($ob->{author_id}) {
        $title .= $ob->{url} ? ": page $ob->{url}" : ": New Page";
    }
    $title = "New Author" if $title eq ' ';
    print <<EOD;
      <tr id="diff-$diff->{id}">
      <td style="vertical-align:top">
        $user<br>
        <!--span class='diffType'>$diff->{type}</span><br-->
        <span class='hint'>$time</span><br>
        <span class='hint'>diff #$diff->{id}</span><br>
      </td>
      <td style="vertical-align:top; background:#eee; padding:5px 10px">
        <b>$title</b><br>
EOD
    if ($diff->type eq 'update') {
        innerdiff($diff->{diff});
    }
    print <<EOD;
      </td>
      <td style="vertical-align:top">
        <input type='button' onclick='acceptDiff("$diff->{id}")' value="Accept"><br><br>
        <input type='button' onclick='rejectDiff("$diff->{id}")' value="Reject"><br>
      </td>
      </tr>
EOD
}

sub innerdiff {
    my $d = shift;
        print "<table class='diffScalar'>\n";
        for my $k (keys %$d) {
            print "<tr>\n"
                 ."<td class='diffFieldName'>$k</td>";
            my $val = $k eq 'url' ? 
                        "<a href=\"$d->{$k}->{after}\">$d->{$k}->{after}</a>" :
                        $d->{$k}->{after};
            if ($d->{$k}->{type} eq 'scalar') {
                print "<td class='diffFieldValue'>$d->{$k}->{before}</td>"
                     ."<td class='diffArrow'>&gt;</td>"
                     ."<td class='diffFieldValue'> $val</td>";
            }
            elsif ($d->{$k}->{type} eq 'array') {
                print "<td class='diffFieldValue' colspan='3'>";
                my $icon = "<span class='diffArrow'>+</span> ";
                print join "", map { $icon.$_->{name}.'<br>' } @{$d->{$k}->{to_add}};
                $icon = "<span class='diffArrow' style='color:red'>&ndash;</span> ";
                print join "", map { $icon.$_->{name}.'<br>' } @{$d->{$k}->{to_delete}};
                print "</td>\n";
            }
            print "</tr>\n";
        }
        print "</table>\n";
}

</%perl>

</table>


