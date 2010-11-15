#
# bibutils unit tests MAKEFILE
#

CFLAGS     = -Wall -I ../lib
LIBDIR     = -L../lib
LIBS       = -lbibutils 
PROGS      = newstr_test entities_test utf8_test

all: $(PROGS)

entities_test : entities_test.o
	$(CC) entities_test.o $(LIBDIR) $(LIBS) -o $@

utf8_test : utf8_test.o
	$(CC) utf8_test.o $(LIBDIR) $(LIBS) -o $@

newstr_test : newstr_test.o
	$(CC) newstr_test.o $(LIBDIR) $(LIBS) -o $@

test: entities_test newstr_test
	./newstr_test
	./entities_test
	./utf8_test

clean:
	rm -f *.o core 

realclean:
	rm -f *.o core $(PROGS)
