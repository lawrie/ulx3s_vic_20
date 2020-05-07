# micropython ESP32
# ORAO RAM/ROM snapshot image loader

# AUTHOR=EMARD
# LICENSE=BSD

from struct import unpack

class ld_vic20:
  def __init__(self,spi,cs):
    self.spi=spi
    self.cs=cs
    self.cs.off()

  # LOAD/SAVE and CPU control

  # read from file -> write to SPI RAM
  def load_stream(self, filedata, addr=0, maxlen=0x10000, blocksize=1024):
    block = bytearray(blocksize)
    # Request load
    self.cs.on()
    self.spi.write(bytearray([0,(addr >> 24) & 0xFF, (addr >> 16) & 0xFF, (addr >> 8) & 0xFF, addr & 0xFF]))
    bytes_loaded = 0
    while bytes_loaded < maxlen:
      if filedata.readinto(block):
        self.spi.write(block)
        bytes_loaded += blocksize
      else:
        break
    self.cs.off()

  # read from SPI RAM -> write to file
  def save_stream(self, filedata, addr=0, length=1024, blocksize=1024):
    bytes_saved = 0
    block = bytearray(blocksize)
    # Request save
    self.cs.on()
    self.spi.write(bytearray([1,(addr >> 24) & 0xFF, (addr >> 16) & 0xFF, (addr >> 8) & 0xFF, addr & 0xFF, 0]))
    while bytes_saved < length:
      self.spi.readinto(block)
      filedata.write(block)
      bytes_saved += len(block)
    self.cs.off()

  def ctrl(self,i):
    self.cs.on()
    self.spi.write(bytearray([0, 0xFF, 0xFF, 0xFF, 0xFF, i]))
    self.cs.off()

  def cpu_halt(self):
    self.ctrl(2)

  def cpu_continue(self):
    self.ctrl(0)

  def store_rom(self,length=32):
    self.stored_code=bytearray(length)
    self.cs.on()
    self.spi.write(bytearray([1, 0,0,(self.code_addr>>8)&0xFF,self.code_addr&0xFF, 0]))
    self.spi.readinto(self.stored_code)
    self.cs.off()
    self.stored_vector=bytearray(2)
    self.cs.on()
    self.spi.write(bytearray([1, 0,0,(self.vector_addr>>8)&0xFF,self.vector_addr&0xFF, 0]))
    self.spi.readinto(self.stored_vector)
    self.cs.off()

  def restore_rom(self):
    self.cs.on()
    self.spi.write(bytearray([0, 0,0,(self.code_addr>>8)&0xFF,self.code_addr&0xFF]))
    self.spi.write(self.stored_code)
    self.cs.off()
    self.cs.on()
    self.spi.write(bytearray([0, 0,0,(self.vector_addr>>8)&0xFF,self.vector_addr&0xFF]))
    self.spi.write(self.stored_vector)
    self.cs.off()

  def patch_rom(self,regs):
    # regs   = 0:A 1:X 2:Y 3:P 4:S 5-6:PC
    # overwrite with register restore code
    self.cs.on()
    self.spi.write(bytearray([0, 0,0,(self.vector_addr>>8)&0xFF,self.vector_addr&0xFF, self.code_addr&0xFF, (self.code_addr>>8)&0xFF])) # overwrite reset vector at 0xFFFC
    self.cs.off()
    self.cs.on()
    self.spi.write(bytearray([0, 0,0,(self.code_addr>>8)&0xFF,self.code_addr&0xFF])) # overwrite code
    self.spi.write(bytearray([0x78,0xA2,regs[4],0x9A,0xA2,regs[1],0xA0,regs[2],0xA9,regs[3],0x48,0x28,0xA9,regs[0],0x4C,regs[5],regs[6]]))
    self.cs.off()
    self.cs.on()

  def read_maincpu(self,s,size):
    print("READING MAIN CPU STATE")
    header=bytearray(47)
    s.readinto(header)
    bytes_read=len(header)
    A=header[4]
    X=header[5]
    Y=header[6]
    S=header[7]
    PC=unpack("<H",header[8:10])[0]
    P=header[10]
    print("A=0x%02X X=0x%02X Y=0x%02X S=0x%02X PC=0x%04X P=0x%02X" % (A,X,Y,S,PC,P))
    print("size %d unknown bytes to read %d" % (size, size-bytes_read))
    s.seek(size-bytes_read,1)
    return True

  def read_vic20mem(self,s,size):
    print("READING RAM")
    header=bytearray(4)
    s.readinto(header)
    bytes_read=len(header)
    config=header[0]
    print("config",config)
    if True:
      s.seek(1*1024,1) # 0017-0416 - 1K RAM dump ($0000-03FF)
      s.seek(4*1024,1) # 0417-1416 - 4K RAM dump ($1000-1FFF)
      bytes_read+=5*1024
    if config&1: # 1B17-2816 - 3K RAM dump ($0400-0FFF, if CONFIG bit 0 set)
      print("3K RAM block present at $0400-0FFF")
      s.seek(3*1024,1)
      bytes_read+=3*1024
    if config&2: # 2817-4816 - 8K RAM dump ($2000-3FFF, if CONFIG bit 1 set)
      print("8K RAM block present at $2000-3FFF")
      s.seek(8*1024,1)
      bytes_read+=8*1024
    if config&4: # 4817-6816 - 8K RAM dump ($4000-5FFF, if CONFIG bit 2 set)
      print("8K RAM block present at $4000-5FFF")
      s.seek(8*1024,1)
      bytes_read+=8*1024
    if config&8: # 6817-8816 - 8K RAM dump ($6000-7FFF, if CONFIG bit 3 set)
      print("8K RAM block present at $6000-7FFF")
      s.seek(8*1024,1)
      bytes_read+=8*1024
    if config&16: # 8817-A816 - 8K RAM dump ($A000-BFFF, if CONFIG bit 5 set)
      print("8K RAM block present at $A000-BFFF")
      s.seek(8*1024,1)
      bytes_read+=8*1024
    print("size %d unknown bytes to read %d" % (size, size-bytes_read))
    s.seek(size-bytes_read,1)
    return True

  def read_vic1(self,s,size):
    print("READING COLOR RAM")
    header=bytearray(78)
    s.readinto(header)
    bytes_read=len(header)
    print("size %d unknown bytes to read %d" % (size, size-bytes_read))
    s.seek(size-bytes_read,1)
    return True
  
  def read_vice_module(self,s):
    header=bytearray(0x16)
    if s.readinto(header):
      print("vice module header", header)
      type=header[0:0x10]
      size=unpack("<I",header[0x12:0x16])[0]-0x16
      print("size", size)
      if type[0:9]==bytearray("VIC20MEM\0".encode()):
        return self.read_vic20mem(s,size)
      if type[0:6]==bytearray("VIC-I\0".encode()):
        return self.read_vic1(s,size)
      if type[0:8]==bytearray("MAINCPU\0".encode()):
        return self.read_maincpu(s,size)
      s.seek(size,1)
      return True
    else:
      return False
    #print(cpu)



  def loadvsf(self,filename):
    f=open(filename,"rb")
    header=bytearray(0x25+0x15)
    f.readinto(header)
    machine=header[0x15:0x25]
    expect=bytearray("VIC20\0")
    if machine[0:6]==expect:
      self.cpu_halt()
      while self.read_vice_module(f):
        pass
      self.code_addr=0xE000
      self.vector_addr=0xFFFC
      self.store_rom(32)
      #self.patch_rom(regs)
      self.ctrl(3) # reset and halt
      self.ctrl(1) # only reset
      self.cpu_continue()
      # restore original ROM after image starts
      self.cpu_halt()
      self.restore_rom()
      self.cpu_continue() # release reset
    else:
      print("unrecognized header")
      print("header:", header)
      print("expected:", expect)

  def old_parse(self):
    f=open("scramble.vsf","rb")
    header=bytearray(0x25+0x15)
    f.readinto(header)
    machine=header[0x15:0x25]
    print(machine)
    #print(header)
    while self.read_vice_module(f):
      pass
      

  def old_xyz(self):
    expect=bytearray("ORAO_0AXYPS_PC_ADDR_LEN_DATA\0")
    header=bytearray(len(expect))
    z.readinto(header)
    if header==expect:
      del expect,header
      regs=bytearray(11)
      z.readinto(regs)
      addr=unpack("<H",regs[7:9])[0]
      length=unpack("<H",regs[9:11])[0]
      if length==0:
        length=0x10000
      self.cpu_halt()
      self.load_stream(z,addr,length)
      self.code_addr=0xE000
      self.vector_addr=0xFFFC
      self.store_rom(32)
      self.patch_rom(regs)
      self.ctrl(3) # reset and halt
      self.ctrl(1) # only reset
      self.cpu_continue()
      # restore original ROM after image starts
      self.cpu_halt()
      self.restore_rom()
      self.cpu_continue() # release reset
    else:
      print("unrecognized header")
      print("header:", header)
      print("expected:", expect)
