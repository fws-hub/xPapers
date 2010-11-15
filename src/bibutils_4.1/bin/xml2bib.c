/*
 * xml2bib.c
 *
 * Copyright (c) Chris Putnam 2003-8
 *
 * Program and source code released under the GPL
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include "bibtexout.h"
#include "bibutils.h"
#include "args.h"
#include "bibprog.h"

void
help( char *progname )
{
	args_tellversion( progname );
	fprintf( stderr, "Converts the MODS XML intermediate reference file "
			"into Bibtex\n\n");

	fprintf(stderr,"usage: %s xml_file > bibtex_file\n\n",progname);
        fprintf(stderr,"  xml_file can be replaced with file list or omitted to use as a filter\n\n");

	fprintf(stderr,"  -h, --help         display this help\n");
	fprintf(stderr,"  -v, --version      display version\n");
	fprintf(stderr,"  -fc, --finalcomma  add final comman to bibtex output\n");
	fprintf(stderr,"  -sd, --singledash  use only one dash '-' instead of two '--' for page range\n" );
	fprintf(stderr,"  -b, -brackets      use brackets, not quotation marks surrounding data\n");
	fprintf(stderr,"  -w, --whitespace   use beautifying whitespace to output\n");
	fprintf(stderr,"  -sk, --strictkey   use only alphanumeric characters for bibtex key\n");
	fprintf(stderr,"                     (overly strict, but may be useful for other bibtex readers\n");
	fprintf(stderr,"  -nl, --no-latex    do not use latex encodings, but put characters in directly\n");
	fprintf(stderr,"  -nb, --no-bom      do not write Byte Order Mark in UTF8 output\n");
	fprintf(stderr,"  -s, --single-refperfile\n");
	fprintf(stderr,"                     one reference per output file\n");
	fprintf(stderr,"  --verbose          for verbose\n" );
	fprintf(stderr,"  --debug            for debug output\n" );
	fprintf(stderr,"\n");

	fprintf(stderr,"Citation codes generated from <REFNUM> tag.   See \n");
	fprintf(stderr,"http://www.scripps.edu/~cdputnam/software/bibutils for more details\n\n");
}

void
process_args( int *argc, char *argv[], param *p )
{
	int i, j, subtract;
	i = 1;
	while ( i<*argc ) {
		subtract = 0;
		if ( args_match( argv[i], "-h", "--help" ) ) {
			help( p->progname );
			exit( EXIT_SUCCESS );
		} else if ( args_match( argv[i], "-v", "--version" ) ) {
			args_tellversion( p->progname );
			exit( EXIT_SUCCESS );
		} else if ( args_match( argv[i], "-fc", "--finalcomma" ) ) {
			p->format_opts |= BIBOUT_FINALCOMMA;
			subtract = 1;
		} else if ( args_match( argv[i], "-s", "--single-refperfile" )){
			p->singlerefperfile = 1;
			subtract = 1;
		} else if ( args_match( argv[i], "-sd", "--singledash" ) ) {
			p->format_opts |= BIBOUT_SINGLEDASH;
			subtract = 1;
		} else if ( args_match( argv[i], "-b", "--brackets" ) ) {
			p->format_opts |= BIBOUT_BRACKETS;
			subtract = 1;
		} else if ( args_match( argv[i], "-w", "--whitespace" ) ) {
			p->format_opts |= BIBOUT_WHITESPACE;
			subtract = 1;
		} else if ( args_match( argv[i], "-sk", "--strictkey" ) ) {
			p->format_opts |= BIBOUT_STRICTKEY;
			subtract = 1;
		} else if ( args_match( argv[i], "-U", "--uppercase" ) ) {
			p->format_opts |= BIBOUT_UPPERCASE;
			subtract = 1;
		} else if ( args_match( argv[i], "-nl", "--no-latex" ) ) {
			p->latexout = 0;
			subtract = 1;
		} else if ( args_match( argv[i], "-nb", "--no-bom" ) ) {
			p->utf8bom = 0;
			subtract = 1;
		} else if ( args_match( argv[i], "--verbose", "" ) ) {
			p->verbose = 1;
			subtract = 1;
		} else if ( args_match( argv[i], "--debug", "" ) ) {
			p->verbose = 3;
			subtract = 1;
		}
		if ( subtract ) {
			for ( j=i+subtract; j<*argc; ++j )
				argv[j-subtract] = argv[j];
			*argc -= subtract;
		} else i++;
	}
}

int 
main( int argc, char *argv[] )
{
	param p;
	bibl_initparams( &p, BIBL_MODSIN, BIBL_BIBTEXOUT, "xml2bib" );
	process_charsets( &argc, argv, &p, 1, 1 );
	process_args( &argc, argv, &p );
	bibprog( argc, argv, &p );
	bibl_freeparams( &p );
	return EXIT_SUCCESS;
}


