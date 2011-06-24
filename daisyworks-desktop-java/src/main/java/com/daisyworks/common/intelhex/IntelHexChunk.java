package com.daisyworks.common.intelhex;

public class IntelHexChunk
{
  public int address;
  public byte[] data;
  public int size;

  public int getBytesRead()
  {
    return (size * 2) + 13;
  }
}
