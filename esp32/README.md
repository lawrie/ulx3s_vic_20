# ESP32 OSD

# on PC

Install "vice" emulator

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
spiram.poke(0xFDC7,bytearray([0x10]))
