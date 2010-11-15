/*
 * utf8_test.c
 */
#include <stdio.h>
#include <stdlib.h>
#include "utf8.h"

char progname[] = "utf8_test";

int
test_utf8( void )
{
	char buf[512];
	unsigned int i, j;
	int nc, pos, failed = 0;
	for ( i=0; i<1000000; ++i ) {
		nc = utf8_encode( i, buf );
		buf[ nc ] = '*';
		buf[ nc+1 ] = '\0';
		pos = 0;
		j = utf8_decode( buf, &pos );
		if ( i != j ) {
			printf( "%s: Error test_utf8 mismatch, "
				"send %u got back %u\n", progname, i, j );
			failed = 1;
		}
		if ( buf[pos]!='*' ) {
			printf( "%s: Error test_utf8 bad ending pos, "
				"expect '*', got back '%c'\n", progname,
				buf[pos] );
		}
	}
	return failed;
}


int
main( int argc, char *argv[] )
{
	int failed = 0;
	failed += test_utf8();
	if ( !failed ) {
		printf( "%s: PASSED\n", progname );
		return EXIT_SUCCESS;
	} else {
		printf( "%s: FAILED\n", progname );
		return EXIT_FAILURE;
	}
}
