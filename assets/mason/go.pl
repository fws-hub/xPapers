<%perl>

    my $link = $q->param('u');
    my $proxy;
    our @COOKIES_OUT;

    my $free = 0;

    if ($link =~ /jstor.org/i) {
        $link =~ s/&gt;/>/i;
        $link =~ s/&lt;/</i; 
        $link =~ s/&quot;/"/g;
    }

    if ($q->param('openurl')) {

        $m->comp("checkLogin.html",%ARGS);
        my $e = xPapers::Entry->get($q->param('id'));
        notfound($q) unless $e;
        my $resolver = $user->resolver;
        $link = $resolver->link_for_entry($e);

    } elsif ($q->param('aid')) {
        my $id = $q->param('aid');
        $id =~ s!^/*!!g;
        my $e = xPapers::Entry->get($id);
        notfound($q) unless $e;
        if (!(-r "$PATHS{LOCAL_BASE}/var/files/arch/$e->{file}")) {
            # try another link
            $link = $e->firstLink;
            if (!$link) {
                notfound($q);
            }
        } else {
            $link = "$s->{server}/archive/$e->{file}";
            $free = 1;
        }
    } else {
        $proxy = $q->cookie('ez-server');
    }

    # Add proxy if necessary
    if (!$free and !$freeChecker->free($link) and $proxy) {

        # hack
        $link =~ s/links\.jstor\.org/www.jstor.org/;
        
        my ($prot, $s,$page) = ($link =~ /(^\w{2,6}:\/\/|^)([^\/]+)(\/.*)/);
        $proxy =~ s/^\.//;
        $link = "$prot$s.$proxy$page";

    }
    writeLog($root->dbh,$q,$tracker,"go","",$s);
    redirect($s,$q,$link,302);


</%perl>
