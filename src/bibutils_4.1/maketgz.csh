#!/bin/csh -f
#
# $1 = version number
# $2 = postfix
#
#
set programs = ( biblatex2xml bib2xml copac2xml end2xml endx2xml isi2xml med2xml modsclean ris2xml xml2ads xml2bib xml2end xml2isi xml2ris xml2wordbib )

set VERSION = $1
set POSTFIX = $2

if ( ! (-e update) ) mkdir update
if ( -e update/bibutils_${VERSION} ) /bin/rm -r update/bibutils_${VERSION}
mkdir update/bibutils_${VERSION}

foreach p ( $programs )
	cp bin/${p} update/bibutils_${VERSION}/${p}
end

cd update

tar cvf - bibutils_${VERSION} | gzip - > bibutils_${VERSION}${POSTFIX}.tgz

cd ..

rm -r update/bibutils_${VERSION}

