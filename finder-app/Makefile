# Default target

# Native build vars
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -g
TARGET = writer

# source
SRC = writer.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET) 

