/*
 * newstr_test.c
 *
 * test newstr functions
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "newstr.h"

char progname[] = "newstr_test";
char version[] = "0.1";

int
test_consistency( newstr *s, int numchars, char *fn )
{
	if ( strlen( s->data ) != s->len ) {
		fprintf(stdout,"%s: failed consistancy check found %d, s->len=%ld\n",fn,strlen(s->data),s->len);
		return 1;
	}
	if ( strlen( s->data ) != numchars ) {
		fprintf(stdout,"%s: failed consistancy check found %d, expected %d\n",fn,strlen(s->data),numchars);
		return 1;
	}
	return 0;
}

int
test_addchar( newstr *s )
{
	int failed = 0;
	int numchars = 1000, i;
	newstr_empty( s );
	for (i=0; i<numchars; ++i) {
		newstr_addchar( s, ( i % 64 ) + 64);
	}
	failed += test_consistency( s, numchars, "test_addchar" );
	return failed;
}

int
test_strcat( newstr *s )
{
	int failed = 0;
	int numstrings = 1000, i;
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcat( s, "" );
	}
	failed += test_consistency( s, 0, "test_strcat" );
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcat( s, "1" );
	}
	failed += test_consistency( s, numstrings, "test_strcat" );
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcat( s, "XXOO" );
	}
	failed += test_consistency( s, numstrings*4, "test_strcat" );
	return failed;
}

int
test_strcpy( newstr *s )
{
	int failed = 0;
	int numstrings = 1000, i;
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcpy( s, "" );
	}
	failed += test_consistency( s, 0, "test_strcpy" );
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcpy( s, "1" );
	}
	failed += test_consistency( s, 1, "test_strcpy" );
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcpy( s, "XXOO" );
	}
	failed += test_consistency( s, 4, "test_strcpy" );
	return failed;
}

int
test_segcpy( newstr *s )
{
	int failed = 0;
	int numstrings = 1000, i;
	char segment[]="0123456789";
	char *start=&(segment[2]), *end=&(segment[5]);
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_segcpy( s, start, end );
	}
	failed += test_consistency( s, 3, "test_segcpy" );
	return failed;
}

int
test_segcat( newstr *s )
{
	int failed = 0;
	int numstrings = 1000, i;
	char segment[]="0123456789";
	char *start=&(segment[2]), *end=&(segment[5]);
	newstr_empty( s );
	for ( i=0; i<numstrings; ++i ) {
		newstr_segcat( s, start, end );
	}
	failed = test_consistency( s, 3*numstrings, "test_segcat" );
	return failed;
}

int
test_findreplace( newstr *s )
{
	int failed = 0;
	int numstrings = 1000, i;
	char segment[]="0123456789";
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcpy( s, segment );
		newstr_findreplace( s, "234", "" );
	}
	failed += test_consistency( s, 7, "test_findreplace" );
	for ( i=0; i<numstrings; ++i ) {
		newstr_strcpy( s, segment );
		newstr_findreplace( s, "234", "223344" );
	}
	failed += test_consistency( s, 13, "test_findreplace" );
	return failed;
}

int
main ( int argc, char *argv[] )
{
	int failed = 0;
	int ntest = 1000;
	int i;
	newstr s;
	newstr_init( &s );
	for ( i=0; i<ntest; ++i)
		failed += test_addchar( &s );
	for ( i=0; i<ntest; ++i)
		failed += test_strcat( &s );
	for ( i=0; i<ntest; ++i)
		failed += test_strcpy( &s );
	for ( i=0; i<ntest; ++i)
		failed += test_segcpy( &s );
	for ( i=0; i<ntest; ++i)
		failed += test_segcat( &s );
	for ( i=0; i<ntest; ++i)
		failed += test_findreplace( &s );
	newstr_free( &s );
	if ( !failed ) {
		printf( "%s: PASSED\n", progname );
		return EXIT_SUCCESS;
	} else {
		printf( "%s: FAILED\n", progname );
		return EXIT_FAILURE;
	}
	return EXIT_SUCCESS;
}
