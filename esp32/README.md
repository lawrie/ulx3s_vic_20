# ESP32 OSD


# LOAD *.prg files

ESP32 "osd.py" and "ld_vic20.py" have some "knowledge base"
to auto-load single-part PRG files by reading PRG header,
patching ROM, issuing COLD RESET, loading data to RAM, 
patching RAM pointers to look as if "LOAD" command was done,
and auto-typing "RUN".

If address is 0xA000, PRG is assumed to have ROM cartridge
content, then WARM RESET is issued immediately after loading.
VIC-20 ROM starts cartrdige ROM after boot if its reset
vector is autodetected.

PRG file contains 2-byte header which is (low,high) byte of
starting address, followed by data until EOF.
PRG may have header to load from any address,
but most single-part PRG files have one of the typical
header values:

    0x1001 unexpanded
    0x0401 3k expanded
    0x1201 8k expanded or more
    0xA000 cadtridge

If there's raw cartridge ROM file file without PRG header,
then file length is usually exactly 4096 or 8192 bytes and
starts with this (from byte 4 it has 5 "magic" bytes)

    0x** 0x** 0x** 0x** 0x41 0x30 0xc3 0xc2 0xcd 0x**

then it can be converted to PRG by prepending 0xA000 header:

    echo -ne "\x00\xA0" > a000.prg
    cat a000.prg quikman-rom.a0 > quikman-rom.prg

kernal ROM can be converted to PRG in similar way

    echo -ne "\x00\xE0" > e000.prg
    cat e000.prg kernal.901486-07.bin > kernal.901486-07.prg

# LOAD *.vsf file

VSF is VICE eumulator snapshot file.

On PC Install "vice" emulator

    apt-get install vice

get some ROM for
[VIC20](http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/vic20/index.html)
and 
[1571 floppy](http://www.zimmers.net/anonftp/pub/cbm/firmware/drives/new/1571/index.html)

Run vic20 emulator

    xvic

Run in emulator something for
[unexpanded VIC20](http://www.zimmers.net/anonftp/pub/cbm/vic20/games/unexpanded/index.html)
or
[VIC20 with 16K expansion](http://www.zimmers.net/anonftp/pub/cbm/vic20/games/16k/index.html)

Save emulator state as VSF file, try if it loads back and let's go to ESP32

# on ESP32

patch ROM to make unexpanded machine:
unexpanedd screen starts at 0x1E00
expanded screen starts at 0x1000

change range of RAM test routine to test only 3.5K:

    spiram.poke(0xFDAC,bytearray([0x10]))
    spiram.poke(0xFDC7,bytearray([0xFF]))

return to normal

    spiram.poke(0xFDAC,bytearray([0x04]))
    spiram.poke(0xFDC7,bytearray([0x21]))
