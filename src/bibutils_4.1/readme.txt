
                              COMPILING BIBUTILS.

Step 1.  Configure the makefile by running the configure script.

The configure script attempts to auto-identify your operating system
and does a reasonable job for a number of platforms (including x86 Linux,
versions of MacOSX, some BSDs, Sun Solaris, and SGI IRIX).  It's not a 
full-fledged configure script via the autoconf system, but is more than 
sufficient for Bibutils.

Unlike a lot of programs, Bibutils is written in very vanilla ANSI C
with no external dependencies (other than the core C libraries themselves),
so the biggest difference between platforms is generally how they
handle library generation.  If your platform is not recognized, please
e-mail me the output of 'uname -a' and I'll work on adding it.

To configure the makefile, simply run:

% configure

or alternatively

% csh -f configure


Bibutils Configuration
----------------------

Configured Makefile to operating system Linux_x86.
    If auto-identification of operating system failed, please
    e-mail cdputnam@ucsd.edu with the system type and output of
    the command: uname -a

Set installation directory to /usr/local/bin.
    To modify install directory type: configure --install-dir DIR
    where DIR is the desired directory.

To compile,          type: make
To install,          type: make install
To make tgz package, type: make package
To make deb package, type: make deb


Step 2.  Make the package with make

% make

Step 3.  Install the package

% make install


