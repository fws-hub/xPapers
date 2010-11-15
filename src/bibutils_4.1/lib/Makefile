#CC = gcc -Wall 
#RANLIB = echo

BIB_OBJS = bbl.o fields.o list.o name.o title.o reftypes.o

SIMPLE_OBJS   = is_ws.o is_doi.o strsearch.o charsets.o
NEWSTR_OBJS   = newstr.o newstr_conv.o entities.o latex.o utf8.o gb18030.o
CONTAIN_OBJS  = fields.o list.o xml.o xml_encoding.o
INPUT_OBJS    = bibtexin.o bibtextypes.o \
		biblatexin.o bltypes.o \
		copacin.o copactypes.o \
		endin.o endtypes.o \
		endxmlin.o \
		isiin.o isitypes.o \
		medin.o \
		modsin.o modstypes.o marc.o \
		risin.o ristypes.o \
		reftypes.o
OUTPUT_OBJS   = bibtexout.o endout.o isiout.o modsout.o risout.o wordout.o \
		adsout.o
BIBUTILS_OBJS = $(SIMPLE_OBJS) $(NEWSTR_OBJS) $(CONTAIN_OBJS) \
	$(INPUT_OBJS) $(OUTPUT_OBJS) name.o title.o bibl.o serialno.o bibutils.o

all:  libbibutils.a

libbibutils.a: $(BIBUTILS_OBJS)
	ar -cr libbibutils.a $(BIBUTILS_OBJS)
	$(RANLIB) libbibutils.a

clean: 
	/bin/rm -f *.o core

realclean:
	/bin/rm -f *.o *.a core

test:
