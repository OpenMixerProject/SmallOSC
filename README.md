# SmallOSC

SmallOSC is a minimal [Open Sound Control](http://opensoundcontrol.org/) (OSC) library written in C. The typical use case is to parse a raw buffer received directly from a socket. Given the limited nature of the library it also tends to be quite fast. It doesn't hold on to much state and it doesn't do much error checking. If you have a good idea of what OSC packets you will receive and need to process them quickly, this library might be for you.

# TinyOSC

SmallOSC was forked from [tinyosc](https://github.com/mhroth/tinyosc) on 18.06.2026.

The goals:

- implement the fixes distributed over all the various forks and put them into one repository
- use it in OpenMixerControl

## Supported Features
Due to its *tiny* or *small* nature, SmallOSC does not support all standard OSC features. Currently it supports:
* message parsing
* message writing
* bundle parsing
* bundle writing
* timetag
* ~~matching~~
* Types
  * `b`: binary blob
  * `f`: float
  * `d`: double
  * `i`: int32
  * `h`: int64
  * `s`: string
  * `m`: midi
  * `t`: timetag
  * `T`: true
  * `F`: false
  * `I`: infinitum
  * `N`: nil

## Code Example
### Reading Messages
```C
#include "smallosc.h"

tosc_message osc; // declare the SmallOSC structure
char buffer[1024]; // declare a buffer into which to read the socket contents
int len = 0; // the number of bytes read from the socket

while ((len = READ_BYTES_FROM_SOCKET(buffer)) > 0) {
  // parse the buffer contents (the raw OSC bytes)
  // a return value of 0 indicates no error
  if (!tosc_readMessage(&osc, buffer, len)) {
    printf("Received OSC message: [%i bytes] %s %s ",
        len, // the number of bytes in the OSC message
        tosc_getAddress(&osc), // the OSC address string, e.g. "/button1"
        tosc_getFormat(&osc)); // the OSC format string, e.g. "f"
    for (int i = 0; osc.format[i] != '\0'; i++) {
      switch (osc.format[i]) {
        case 'f': printf("%g ", tosc_getNextFloat(&osc)); break;
        case 'i': printf("%i ", tosc_getNextInt32(&osc)); break;
        // returns NULL if the buffer length is exceeded
        case 's': printf("%s ", tosc_getNextString(&osc)); break;
        default: continue;
      }
    }
    printf("\n");
  }
}
```

### Writing Messages
```C
// declare a buffer for writing the OSC packet into
char buffer[1024];

// write the OSC packet to the buffer
// returns the number of bytes written to the buffer, negative on error
// note that tosc_write will clear the entire buffer before writing to it
int len = tosc_writeMessage(
    buffer, sizeof(buffer),
    "/ping", // the address
    "fsi",   // the format; 'f':32-bit float, 's':ascii string, 'i':32-bit integer
    1.0f, "hello", 2);

// send the data out of the socket
send(socket_fd, buffer, len, 0);
```

### Reading Bundles
Here is an example of the kind of message processing loop that you might have around a socket. The buffer should first be inspected to see if it contains a bundle or not, at which point messages are parsed independently along with an optional timetag.

```C
void receive(char *buffer, int len) {
  // see if the buffer contains a bundle or an individual message
  if (tosc_isBundle(buffer)) {
    tosc_bundle bundle;
    tosc_parseBundle(&bundle, buffer, len);
    const uint64_t timetag = tosc_getTimetag(&bundle);
    tosc_message osc;
    while (tosc_getNextMessage(&bundle, &osc)) {
      tosc_printMessage(&osc);
    }
  } else {
    tosc_printOscBuffer(buffer, len);
  }
}
```

### Writing Bundles
```C
char buffer[1024];

tosc_bundle bundle;
tosc_writeBundle(&bundle, buffer, sizeof(buffer));
tosc_writeNextMessage(&bundle, "/ping", "fsi", 1.0f, "hello", 3);
tosc_writeNextMessage(&bundle, "/pong", "TTF");
// etc.

send(buffer, tosc_getBundleLength(&bundle));
```

### main.c
A small example program is included in `main.c`. Build it using the included shell script `build.sh`, and run it with `smallosc`. The program simply opens a UDP socket on port 9000 and prints out received OSC messages. Press Ctrl+C to stop. Try it with any OSC client, such as TouchOSC. This program is also an example for how SmallOSC is expected to be used.

#### Sample Output
```
Starting write tests:
[56 bytes] /address fsibTFNI 1 hello world -1 [8]001080F0011181F1 true false nil inf
done.
smallosc is now listening on port 9000.
Press Ctrl+C to stop.
```

## License
SmallOSC is published under the [ISC license](http://opensource.org/licenses/ISC). Please see the `LICENSE` file included in this repository.
