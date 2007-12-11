CCFLAGS=-Wall -Iinclude -std=c99
LDFLAGS=-lutil

ifeq ($(DEBUG),1)
  CCFLAGS+=-ggdb -DDEBUG
endif

CCFLAGS+=$(shell pkg-config --cflags glib-2.0)
LDFLAGS+=$(shell pkg-config --libs   glib-2.0)

CFILES=$(wildcard src/*.c)
OFILES=$(CFILES:.c=.o)
HFILES=$(wildcard src/*.h include/*.h)

TEST_CFILES=$(wildcard t/*.c)
TEST_OFILES=$(TEST_CFILES:.c=.o)

LIBPIECES=ecma48 parser state input pen mode
DEBUGS=debug-passthrough debug-pangoterm

all: $(DEBUGS)

debug-%: debug-%.c libecma48.so
	gcc -o $@ $^ $(CCFLAGS) $(LDFLAGS)

debug-pangoterm: debug-pangoterm.c libecma48.so
	gcc -o $@ $^ $(CCFLAGS) $(shell pkg-config --cflags --libs gtk+-2.0) $(LDFLAGS)

libecma48.so: $(addprefix src/, $(addsuffix .o, $(LIBPIECES)))
	gcc -shared -o $@ $^ $(LDFLAGS)

src/%.o: src/%.c $(HFILES)
	gcc -fPIC -o $@ -c $< $(CCFLAGS)

t/%.o: t/%.c
	gcc -c -o $@ $< $(CCFLAGS)

t/test.o: t/test.c t/extern.h t/suites.h
	gcc -c -o $@ $< $(CCFLAGS)

t/extern.h: t
	t/test.c.sh

t/test: libecma48.so $(TEST_OFILES)
	t/test.c.sh
	gcc -o $@ $^ $(CCFLAGS) $(LDFLAGS) -lcunit

.PHONY: test
test: libecma48.so t/test
	LD_LIBRARY_PATH=. t/test

.PHONY: clean
clean:
	rm -f $(DEBUGS) $(OFILES) $(TEST_OFILES) libecma48.so
