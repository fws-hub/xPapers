/*
 * modsclean.c
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include "bibutils.h"
#include "tomods.h"
#include "bibprog.h"

int
main( int argc, char *argv[] )
{
	param p;
	bibl_initparams( &p, BIBL_MODSIN, BIBL_MODSOUT, "modsclean" );
	tomods_processargs( &argc, argv, &p, "", "" );
	bibprog( argc, argv, &p );
	bibl_freeparams( &p );
	return EXIT_SUCCESS;
}
