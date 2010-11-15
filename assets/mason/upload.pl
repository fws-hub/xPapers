<%init>
return unless $user->{uId};
use File::Temp;

my $in = $q->upload('userfile');

my $out = File::Temp->new(DIR=>$PATHS{UPLOAD});
$out->unlink_on_destroy(0);

while (<$in>) {
      print $out;
}
my $file = $out->filename;
close($in);
close($out);

# now return 
</%init>

<script language="Javascript">
   var e = $('<%$ARGS{uploadResult}%>');
   e.innerHTML = "Your file has been uploaded successfully and will replace any existing local copy upon approval.<input type='hidden' name='newFile' value='<%$file%>'><input type='button' value='Cancel upload' onClick='javascript:cancelUpload()'>";
</script>
