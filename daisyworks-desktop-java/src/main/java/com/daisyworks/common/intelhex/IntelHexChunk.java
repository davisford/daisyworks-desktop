package com.daisyworks.common.intelhex;

public class IntelHexChunk
{
  public int address;
  public byte[] data;

  public int getBytesRead()
  {
    return (data.length * 2) + 13;
  }
}
