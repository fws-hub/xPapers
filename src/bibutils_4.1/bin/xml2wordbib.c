/*
 * xml2wordbib.c
 *
 * Copyright 2007-8 C. Putnam
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include "bibutils.h"
#include "args.h"
#include "bibprog.h"

void
help( char *progname )
{
	args_tellversion( progname );
        fprintf(stderr,"Converts a MODS XML bibliogrphy into Word2007 format bibliography\n\n");

        fprintf( stderr, "usage: %s xml_file > word_file\n\n", progname );
        fprintf( stderr, "  xml_file can be replaced with file list or omitted to use as a filter\n\n" );
        fprintf( stderr, "  -h, --help     display this help\n" );
	fprintf( stderr, "  -s, --single-refperfile one reference per output file\n");
        fprintf( stderr, "  --verbose      for verbose output\n" );
        fprintf( stderr, "  --debug        for debug output\n" );
        fprintf( stderr, "  -v, --version  display version\n\n" );

        fprintf( stderr, "http://www.scripps.edu/~cdputnam/software/bibutils for more details\n\n" );
}

void
process_args( int *argc, char *argv[], param *p )
{
	int i, j, subtract;
	i = 1;
	while ( i < *argc ) {
		subtract = 0;
		if ( args_match( argv[i], "-h", "--help" ) ) {
			help( p->progname );
			exit( EXIT_SUCCESS );
		} else if ( args_match( argv[i], "-v", "--version" ) ) {
			args_tellversion( p->progname );
			exit( EXIT_SUCCESS );
		} else if ( args_match( argv[i], "-s", "--single-refperfile")){
			p->singlerefperfile = 1;
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
	bibl_initparams( &p, BIBL_MODSIN, BIBL_WORD2007OUT, "xml2wordbib" );
	process_charsets( &argc, argv, &p, 1, 1 );
	process_args( &argc, argv, &p );
	bibprog( argc, argv, &p );
	bibl_freeparams( &p );
	return EXIT_SUCCESS;
}
