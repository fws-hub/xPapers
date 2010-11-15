#ifndef ARGS_H
#define ARGS_H

extern void args_tellversion( char *progname );
extern int args_match( char *check, char *shortarg, char *longarg );
extern void args_encoding( int argc, char *argv[], int i, int *charset,
        unsigned char *utf8, char *progname );
extern int args_charset( char *charset_name, int *charset, 
	unsigned char *utf8 );
extern void process_charsets( int *argc, char *argv[], param *p,
	int use_input, int use_output );

#endif
