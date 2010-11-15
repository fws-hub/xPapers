<%perl>
#!/usr/bin/perl -w
use xPapers::OAI::Server;
$NOFOOT = 1;
print xPapers::OAI::Server::response( \%ARGS );
</%perl> 
