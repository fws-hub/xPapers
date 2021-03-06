/*
 * isi2xml.c
 *
 * Copyright (c) Chris Putnam 2004-8
 *
 * Program and source code released under the GPL
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include "bibutils.h"
#include "tomods.h"
#include "bibprog.h"

char help1[] = "Converts a ISI reference file into MODS XML\n\n";
char help2[] = "isi_file";

int
main( int argc, char *argv[] )
{
	param p;
	bibl_initparams( &p, BIBL_ISIIN, BIBL_MODSOUT, "isi2xml" );
	tomods_processargs( &argc, argv, &p, help1, help2 );
	bibprog( argc, argv, &p );
	bibl_freeparams( &p );
	return EXIT_SUCCESS;
}
