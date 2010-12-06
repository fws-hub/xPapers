#! /usr/bin/perl

use strict;
use warnings;

use lib '/home/xpapers/lib';
use xPapers::Conf;

use CGI;
use IO::File;
use String::Random qw(random_regex random_string);

use Data::Dumper::HTML 'dumper_html';

my $upload_id = $ENV{PATH_INFO};
$upload_id =~ s{^/}{};
#FIXME hardcoded path
my $tmp_file = "/home/xpapers/var/files/tmp/$upload_id";
my $fh = IO::File->new;
if( $upload_id ){
    unlink $tmp_file . '.finished' if -f $tmp_file . '.finished';
    open $fh, '>', $tmp_file or die "Cannot write to $tmp_file : $!";
    open my $size_fh, '>', $tmp_file . '.size' or die "Cannot write to ${tmp_file}.size : $!";
    print $size_fh $ENV{CONTENT_LENGTH};
}

my $q = CGI->new( \&hook, $fh, undef );

print $q->header;

if( $q->request_method eq 'GET' ){ 
    my $upload_id = random_regex('\w\w\w\w\w\w\w\w\w\w');
    while(<DATA>){
        s/_SITE_/$DEFAULT_SITE->{name}/g;
        s/upload_id_value/$upload_id/;
        s/progress_bar_colour/$C4/;
        print;
    }
}
else{
    open my $tmp_fh, '>', $tmp_file . '.finished' or die "Cannot write to ${tmp_file}.finished : $!";
    close $tmp_fh;
    close $fh;
    my $extension = $q->param( 'file' );
    $extension =~ s/.*\.(\w*)/$1/;
    if( $extension ){
        rename $tmp_file, "$tmp_file.$extension" or die "Cannot rename $tmp_file to $tmp_file.$extension : $!";
        $upload_id = "$upload_id.$extension";
    }

    print "
    <html>
    <head>
    <script>
    // parent.parent.document.getElementById('mainFormSubmit').disabled=false;
    var upIdField = parent.parent.document.getElementById('upsession');
    upIdField.value = '$upload_id'; 
    parent.\$('progressBar').style.width = '150px';
    parent.\$('progressBar').innerHTML  = 'File uploaded';
    parent.\$('uploadSpeed').innerHTML = '';
    parent.parent.\$('uploadInProgress').value = '0';
    </script>
    </head>
    <body></body>
    </html>";
}

sub hook {
    my ($filename, $buffer, $bytes_read, $fh) = @_;
    print $fh substr($buffer, 0, $bytes_read);
    $fh->flush();
}


__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<meta http-equiv="content-language" content="en">
<link rel="stylesheet" type="text/css" href="/dynamic-assets/_SITE_/style.css">

<script type='text/javascript' src='/dynamic-assets/_SITE_/xpapers.js'></script>

<style>
.progressBox {
  width: 150px;
  height: 18px;
  background-color: #cccccc;
  border:black 1px solid;
}
.progressBar {
  width: 0; 
  height: 18px;
  background-color: #progress_bar_colour;

  color:white;
  text-align:center;
  vertical-align:middle;
  font-size:12px;
}

</style>

<script>
var start;

function uploadStart() { 
  $('progressBar').style.width = '0px';
  $('progressBar').innerHTML = '';
  $('uploadSpeed').innerHTML = '';
  parent.$('uploadInProgress').value = '1';
  parent.$('fileActionReplace').checked = true;
  $('uploadForm').submit();
  var d = new Date();
  start = d.getTime();
  updateProgress();  
}

function updateProgress() {
  simpleReq("/action.pl", {upId:'upload_id_value',c:'uploadProgress'}, function(r) {
        var v = r.split(" ");
        var procent = 150 * v[0];
        $('progressBar').style.width = procent + 'px';
        var d = new Date();
        var elapsed = d.getTime() - start;
        if( v.length > 1 && elapsed > 0 ){
          $('uploadSpeed').innerHTML = 'upload speed: ' + Math.floor( ( v[1] / elapsed ) * ( 1000/1024 ) ) + 'KB/s';
        }
        if( v[0] < 1 ){
          window.setTimeout("updateProgress()", 4000);
        }
  });
}


</script>
</head>

<form id="uploadForm" method="post" action="/cgi/upload.pl/upload_id_value" enctype="multipart/form-data" target="form1_iframe">
<div>

<table>
<tr>
<td valign="top">
    File: <input type="file" name="file" onChange="uploadStart()">
</td>
<td valign="top">
    <div class="progressBox">
        <div class="progressBar" id="progressBar"></div>
    </div>
    <span class="hint" id="uploadSpeed"></span>
</td>
</tr>
</table>

</div>
</form>

<iframe frameborder=0 style="border:none" name="form1_iframe" id="form1_iframe" src="/assets/raw/blank.html" class="loader"></iframe> 

