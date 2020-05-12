#!/usr/bin/env python3

# in-place fix a PRG file which won't run correctly, like
# UNDEF'D STATEMENT ERROR

# It is assumed that PRG file should contain a linked list of code lines,
# BASIC code is not relocatable - if the code doesn't match with loading
# address, pointers will also not match.
# Instead of loading to a "correct" address, we will fix the code to match
# with current loading address.

# Each line in a correct BASIC code should start with
# pointer to the next line, until last line which has
# NULL pointer. Each BASIC line is not longer than 256 bytes.

# If first pointer is pointing backwards or forwards > 256 bytes,
# then this program will reduce them by a modulo 256 offset

# TODO file should be

from struct import pack,unpack

class prgfixer:

  def __init__(self, filename):
    self.r=open(filename,"rb+")

  def verify_correction(self, correction):
    word=bytearray(2)
    self.r.seek(0,0)
    self.r.readinto(word)
    loadaddr=unpack("<H",word)[0]
    nextline=loadaddr
    prevline=nextline
    lines=0
    success=True
    while nextline:
      self.r.seek(2+nextline-loadaddr,0)
      self.r.readinto(word)
      nextline2=unpack("<H",word)[0]
      if nextline2:
        if nextline2+correction <= nextline or nextline2+correction > nextline+255:
          success=False
          break
        nextline2=nextline2+correction
      prevline=nextline
      nextline=nextline2
      lines+=1
    return lines

  def do_correct(self, correction):
    word=bytearray(2)
    self.r.seek(0,0)
    self.r.readinto(word)
    loadaddr=unpack("<H",word)[0]
    nextline=loadaddr
    while nextline:
      self.r.seek(2+nextline-loadaddr,0)
      self.r.readinto(word)
      nextline2=unpack("<H",word)[0]
      if correction:
       if(nextline2-nextline > 256):
        self.r.seek(2+nextline-loadaddr,0)
        nextline2+=correction
        wordfix=pack("<H",nextline2)
        self.r.write(wordfix)
      nextline=nextline2

  def fix(self):
    correction=0
    word=bytearray(2)
    self.r.readinto(word)
    loadaddr=unpack("<H",word)[0]
    nextline=loadaddr
    self.r.seek(2+nextline-loadaddr,0)
    self.r.readinto(word)
    nextline2=unpack("<H",word)[0]
    if(nextline2 > nextline + 256):
      correction=-((nextline2-nextline)&0xFF00)
    if(nextline2 < nextline):
      correction=  (nextline2-nextline)&0xFF00
    lines=self.verify_correction(correction)
    if lines>1:
      print("correction %d verify OK (%d lines)" % (correction,lines))
      self.do_correct(correction)
    else:
      print("correction %d varify WRONG (%d lines)" % (correction,lines))

a=prgfixer("chomper_man.prg").fix()
