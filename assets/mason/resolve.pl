<%perl>
    $NOFOOT=1;
    my $e = xPapers::Entry->get($q->param('id'));
    notfound() unless $e;
    my @links = $e->getAllLinks;
    if (@links == 0) {
        notfound();
    }
    my $link = shift @links;
    our @COOKIES_OUT;

    my $free = 0;

    if ($link =~ /jstor.org/i) {
        $link =~ s/&gt;/>/i;
        $link =~ s/&lt;/</i; 
        $link =~ s/&quot;/"/g;
    }


    if ($freeChecker->free($link)) {
        redirect($s,$q,$link,302);
        writeLog($root->dbh,$q,$tracker,"go","",$s);
    } else {
        
        if (!$user->{id}) {
             writeLog($root->dbh,$q,$tracker,"go","",$s);
             redirect($s,$q,$link);    
        } else {

            # use reverse proxy if available
            if (my $proxy = $q->cookie('ez-server')) {
                redirect($s,$q,$s->{server}."/go.pl?u=$link&id=$e->{id}");    
            } 

            # otherwise use open url if available 
            elsif (my $resolver = $user->resolver) {
                $link = $resolver->link_for_entry($e);
                writeLog($root->dbh,$q,$tracker,"go","",$s);
                redirect($s,$q,$link);    
            } 

            elsif ($ARGS{nowarning}) {
                 writeLog($root->dbh,$q,$tracker,"go","",$s);
                 redirect($s,$q,$link);    
            }
            
            else {
                 writeLog($root->dbh,$q,$tracker,"go","",$s);
                 redirect($s,$q,$link);    
                #$m->comp("bits/no_proxy.html",link=>$link,entry=>$e);
            }
       
        }

    }

    


</%perl>
