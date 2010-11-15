<& ../header.html, subtitle=>"Env" &>

<%perl>
print gh("Environment variables");

print "$_: $ENV{$_}<br>" for sort keys %ENV;

</%perl>
