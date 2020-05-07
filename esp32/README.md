
patch ROM to make unexpanded machine:
unexpanedd screen starts at 0x1E00
expanded screen starts at 0x1000

change range of RAM test routine to test only 3.5K:

spiram.poke(0xFDAC,bytearray([0x10]))
spiram.poke(0xFDC7,bytearray([0xFF]))

return to normal

spiram.poke(0xFDAC,bytearray([0x04]))
spiram.poke(0xFDC7,bytearray([0x10]))
