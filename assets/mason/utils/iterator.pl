<%perl>
$m->comp("../header.html");
print gh("Entry iterator");
</%perl>

    Done:
    <did id='done'>0</div>
    <script type="text/javascript">

    var c = 0;
    var bad = false;
    function check(id) {

        simpleReq("/utils/single_entry.pl", {format:"json",run:1,eId:id}, function(r) {
            if (r) {
                try {
                    r.evalJSON();
                } catch (e) {
                    alert(e);
                    bad = true;
                }
                c++;
                $('done').update(c);
            } else {
                alert("finished");
            }
        }
        );

    }



function doiteration() {

<%perl>

my $it = xPapers::EntryMng->get_objects_iterator(query=>['!deleted'=>1],offset=>$ARGS{offset}||0,limit=>340,sort_by=>['added desc']);
while (my $e = $it->next) {
    print "check('$e->{id}');\n"; 
}

</%perl>

}
    </script>
<input type='button' onclick='doiteration()' value='go'>
