/*
 * args.c
 *
 * Copyright (c) 2004-8
 *
 * Program and source code released under the GPL
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include "newstr_conv.h"
#include "bibutils.h"
#include "args.h"

void
args_tellversion( char *progname )
{
	char bibutils_version[] = CURR_VERSION;
	char bibutils_date[] = CURR_DATE;
	fprintf( stderr, "%s, ", progname );
	fprintf( stderr, "bibutils suite version %s date %s\n", 
		bibutils_version, bibutils_date );
}

int
args_match( char *check, char *shortarg, char *longarg )
{
	if ( shortarg && !strcmp( check, shortarg ) ) return 1;
	if ( longarg  && !strcmp( check, longarg  ) ) return 1;
	return 0;
}

void
args_encoding( int argc, char *argv[], int i, int *charset, 
	unsigned char *utf8, char *progname )
{
	if ( i+1 >= argc ) {
		fprintf( stderr, "%s: error -i (--input-encoding) takes "
				"the argument of the character set type\n",
				progname );
		list_charsets( stderr );
		exit( EXIT_FAILURE );
	} else {
		if ( !args_charset( argv[i+1], charset, utf8 ) ) {
			fprintf( stderr, "%s: character encoding lookup "
					"failed.\n", progname );
			list_charsets( stderr );
		}
	}
}

int
args_charset( char *charset_name, int *charset, unsigned char *utf8 )
{
	if ( !strcasecmp( charset_name, "unicode" ) || 
	     !strcasecmp( charset_name, "utf8" ) ) {
		*charset = BIBL_CHARSET_UNICODE;
		*utf8 = 1;
	} else if ( !strcasecmp( charset_name, "gb18030" ) ) {
		*charset = BIBL_CHARSET_GB18030;
		*utf8 = 0;
	} else {
		*charset = get_charset( charset_name );
		*utf8 = 0;
	}
	if ( *charset == BIBL_CHARSET_UNKNOWN ) return 0;
	else return 1;
}

/* Must process charset info first so switches are order independent */
void
process_charsets( int *argc, char *argv[], param *p,
	int use_input, int use_output )
{
	int i, j, subtract;
	i = 1;
	while ( i<*argc ) {
		subtract = 0;
		if ( use_input && args_match( argv[i], "-i", "--input-encoding" ) ) {
			args_encoding( *argc, argv, i, &(p->charsetin), 
					&(p->utf8in), p->progname );
			p->charsetin_src = BIBL_SRC_USER;
			subtract = 2;
		} else if ( use_output && args_match( argv[i], "-o", "--output-encoding" ) ) {
			args_encoding( *argc, argv, i, &(p->charsetout),
					&(p->utf8out), p->progname );
			if ( p->charsetout==BIBL_CHARSET_UNICODE )
				p->utf8bom = 1;
			if ( p->charsetout==BIBL_CHARSET_GB18030 )
				p->latexout = 0;
			p->charsetout_src = BIBL_SRC_USER;
			subtract = 2;
		}
		if ( subtract ) {
			for ( j=i+subtract; j<*argc; ++j )
				argv[j-subtract] = argv[j];
			*argc -= subtract;
		} else i++;
	}
}

