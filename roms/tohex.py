for i in range(0x8000):
    print("".join("%02x" % 0x00))

with open("characters.rom", "rb") as f:
    byte = f.read(1)
    while byte != b"":
        print("".join("%02x" % ord(byte)))
        byte = f.read(1)

for i in range(0x3000):
    print("".join("%02x" % 0x00))

with open("basic.rom", "rb") as f:
    byte = f.read(1)
    while byte != b"":
        print("".join("%02x" % ord(byte)))
        byte = f.read(1)

with open("kernal.rom", "rb") as f:
    byte = f.read(1)
    while byte != b"":
        print("".join("%02x" % ord(byte)))
        byte = f.read(1)

