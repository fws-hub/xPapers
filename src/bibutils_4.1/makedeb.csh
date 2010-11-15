#!/bin/csh -f
#
# $1 = version number
# $2 = postfix
#
#
# Build up this directory tree/files
#
# update/debian/
#              /DEBIAN/
#                     control
#                     postinst.bibutils
#                     postrm.bibutils
#              /usr/local/bibutils-${1}/
#                                      programs
#
# Then run dpkg on this to build a .deb package
#

if ( ( $2 != _osx ) && ( $2 != _i386 ) ) exit

set programs = ( biblatex2xml bib2xml copac2xml end2xml endx2xml isi2xml med2xml modsclean ris2xml xml2ads xml2bib xml2end xml2isi xml2ris xml2wordbib )

if ( -e update/debian ) /bin/rm -r update/debian
if ( -e update/bibutils-${1}.deb ) /bin/rm -f update/*.deb
if ( ! (-e update) ) mkdir update
cd update
mkdir -p debian/DEBIAN

set outdir = debian
set pkgdir = debian/DEBIAN

#
# Build control file
#
if ( $2 == _i386 ) set arch = i386
if ( $2 == _osx ) set arch = darwin-powerpc

set cntrl = ${pkgdir}/control
echo $cntrl
echo "Package: bibutils" >! $cntrl
echo "Version:" $1 >> $cntrl
echo "Essential: no" >> $cntrl
echo "Maintainer: Chris Putnam [cdputnam@ucsd.edu]" >> $cntrl
echo "Provides: bibutils" >> $cntrl
echo "Architecture: ${arch}" >> $cntrl
echo "Description: Bibutils converts between bibliography formats" >> $cntrl
echo "             including BibTeX, RIS, Endnote (Refer), ISI," >> $cntrl
echo "             COPAC, and Medline XML using a MODS v3.0 XML intermediate." >> $cntrl

#
# Build post-install script
#
set postinst = ${pkgdir}/postinst.bibutils

echo "#\!/bin/sh" >! $postinst

#
# Build un-install script
#
set postrm = ${pkgdir}/postrm.bibutils

echo "#\!/bin/sh" >! $postrm

#
# Build binaries directory
#
# Fink installs on MacOSX install to /sw/bin
#
if ( $2 == _i386 ) set binarydir = ${outdir}/usr/local/bin
if ( $2 == _osx ) set binarydir = ${outdir}/sw/bin

mkdir -p ${binarydir}

foreach program ( $programs )
	cp ../bin/${program} ${binarydir}/.
end

#
# Build update
#
set path = ( $path /sw/bin ~/src/bibutils/dpkg-1.10.28/main ~/src/bibutils/dpkg-1.10.28/dpkg-deb )
dpkg --build ${outdir}  bibutils-${1}${2}.deb

/bin/rm -r ${outdir}

#   123  0:00    set path = ( $path /home/cdputnam/src/bibutils/dpkg-1.10.28/dpkg-deb )
#   125  0:00    dpkg -c *.deb

