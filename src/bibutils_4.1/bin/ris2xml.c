/*
 * ris2xml.c
 *
 * Copyright (c) Chris Putnam 2003-8
 *
 * Program and source code released under the GPL
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include "bibutils.h"
#include "tomods.h"
#include "bibprog.h"

char help1[] = "Converts a RIS reference file into MODS XML";
char help2[] = "ris_file";

int 
main( int argc, char *argv[] )
{
	param p;
	bibl_initparams( &p, BIBL_RISIN, BIBL_MODSOUT, "ris2xml" );
	tomods_processargs( &argc, argv, &p, help1, help2 );
	bibprog( argc, argv, &p );
	bibl_freeparams( &p );
	return EXIT_SUCCESS;
}
