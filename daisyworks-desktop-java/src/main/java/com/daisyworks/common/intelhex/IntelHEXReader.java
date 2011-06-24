package com.daisyworks.common.intelhex;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FilterReader;
import java.io.IOException;
import java.io.Reader;

import com.daisyworks.common.stk500.STKUtil;

public class IntelHEXReader extends FilterReader
{
  private static final byte[] LOOKUP = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 10, 11, 12, 13, 14, 15, 16 };
  private final IntelHexChunk chunk = new IntelHexChunk();

  public IntelHEXReader (final Reader in)
  {
    super(in);
  }

  /**
   * char  1   : The start of line character ':'
   * chars 2,3: The number of bytes in the data
   * chars 4,5: High byte of the address
   * chars 6,7: low byte of the address
   * chars 8,9: record type
   * chars 10-((bytes in data * 2)+10): data
   * char n, n+1: checksum
   * char n+2,n+3: newline
   *
   * 13 bytes overhead + databytes*2
   *
   * @return
   * @throws IOException
   */
  public IntelHexChunk readNextChunk() throws IOException
  {
    char start = (char)read();

    while (start == 10 || start == 13)
    {
      start = (char)read();
    }

    if (start == -1)
    {
      return null;
    }

    if (start != ':')
    {
      throw new IntelHexException("Line did not start with ':'. Started with '" + (int)start + "' instead.");
    }

    int byteCount = nextByte();

    byte checksumCalculated = (byte)byteCount;

    int addressHigh = nextByte();
    int addressLow = nextByte();
    chunk.address = addressHigh << 8 | addressLow;

    checksumCalculated += addressHigh;
    checksumCalculated += addressLow;

    int recordType = nextByte();
    checksumCalculated += recordType;
    if (recordType == 1) // EOF Marker
    {
      return null;
    }

    if (recordType != 0)
    {
      throw new IntelHexException("Record type '" + recordType + "' not supported");
    }

    if (chunk.data == null || chunk.data.length < byteCount)
    {
      chunk.data = new byte[byteCount];
    }
    chunk.size = byteCount;

    byte dataByte;
    for (int i = 0; i < byteCount; i++)
    {
      dataByte = (byte)nextByte();
      chunk.data[i] = dataByte;
      checksumCalculated += dataByte;
    }

    checksumCalculated = (byte)(0x100 - checksumCalculated);
    byte checkSum = (byte)nextByte();

    if (checkSum != checksumCalculated)
    {
      throw new IntelHexException("Invalid checksum: " + checkSum + ". Expected: " + checksumCalculated);
    }

    return chunk;
  }

  private int nextByte() throws IOException
  {
    final int high = read();
    final int low  = read();
    return ((LOOKUP[high - 48] << 4) | LOOKUP[low - 48]);
  }

//  private static byte hexToByte(final int high, final int low)
//  {
//    return (byte)((LOOKUP[high - 48] << 4) | LOOKUP[low - 48]);
//  }
//
//  private static void printHexArray(final byte[] buf)
//  {
//    System.out.print("[");
//    for (int i = 0; i < buf.length; i++)
//    {
//      if (i > 0)
//      {
//        System.out.print(", ");
//      }
//      String hex = Integer.toHexString(buf[i]);
//      if (hex.length() == 1 )
//      {
//        hex = "0" + hex;
//      }
//      while (hex.length() > 2)
//      {
//        hex = hex.substring(1);
//      }
//      System.out.print(hex);
//    }
//    System.out.print("]");
//  }
//
  public static void main (final String[] args) throws Exception
  {
    IntelHEXReader fileInput = new IntelHEXReader(new BufferedReader(new FileReader("/home/paul/workspace/daisyworks-firmware/shell/tmp/shell.hex")));

    System.out.println("Start");
    IntelHexChunk chunk;
    while (null != (chunk = fileInput.readNextChunk()))
    {
      System.out.println(STKUtil.toHex(chunk.data));
    }
  }

//  public static void main (final String[] args)
//  {
//    int addressHigh = 0x4e;
//    int addressLow = 0x90;
//    int address = addressHigh << 8 | addressLow;
//    System.out.println( "High: " + Integer.toHexString(addressHigh) + " Low: " + Integer.toHexString(addressLow) + " Combined: " + Integer.toHexString(address));
//  }
}
