SDKROOT ?= $(shell xcrun --sdk macosx --show-sdk-path)
CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -O2 -isysroot $(SDKROOT)
LDFLAGS ?= -lncurses

BIN := ncdiff
SRC := src/main.c

.PHONY: all clean

all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $@ $(LDFLAGS)

clean:
	rm -f $(BIN)
