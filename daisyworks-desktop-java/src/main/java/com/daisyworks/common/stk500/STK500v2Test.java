package com.daisyworks.common.stk500;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FilterOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class STK500v2Test
{
  private final CheckSummingOutputStream out;

  private static final byte MESSAGE_START = 27;
  private static final byte TOKEN = 14;
  private byte sequenceNumber = -1;

  private static final byte CMD_SIGN_ON = 1;

  private final byte[] msg = new byte[255];

  public STK500v2Test(final OutputStream out)
  {
    this.out = new CheckSummingOutputStream(out);
  }

  private void sendMessage(final int msgLength) throws Exception
  {
    out.write(MESSAGE_START);
    out.write(++sequenceNumber);
    out.write(msgLength >> 1);
    out.write(msgLength);
    out.write(TOKEN);
    out.write(msg, 0, msgLength);
    out.writeChecksum();
    out.flush();
  }

  public void sendSignOn() throws Exception
  {
    msg[0] = CMD_SIGN_ON;
    sendMessage(1);
  }

  public static void main (final String[] args) throws Exception
  {
    final OutputStream out = new FileOutputStream("/dev/ttyUSB0");
    final InputStream is = new FileInputStream("/dev/ttyUSB0");

    System.out.println(is.read());

    out.write(30);
    out.write(20);
    out.write(30);
    out.write(20);
    out.write(30);
    out.write(20);

    System.out.println(is.read());
    System.out.println(is.read());


    final STK500v2Test test = new STK500v2Test(out);
    test.sendSignOn();

    new Thread()
    {
      @Override
      public void run()
      {
        try
        {
          while (true)
          {
            int read = is.read();
            System.out.println("Next: " + read);
          }
        }
        catch(final Exception e)
        {
          e.printStackTrace();
        }
      }
    }.start();


    Thread.sleep(1000);
    System.exit(-1);
  }

  class CheckSummingOutputStream extends FilterOutputStream
  {
    private byte checksum = 0;

    public CheckSummingOutputStream (final OutputStream out)
    {
      super(out);
    }

    @Override
    public void write (final int b) throws IOException
    {
      checksum ^= b;
      out.write(b);
      System.out.println("Write byte: " + toBinary(b) + "  CheckSum: " + toBinary(checksum));
    }

    @Override
    public void write (final byte[] b) throws IOException
    {
      write(b, 0, b.length);
    }

    @Override
    public void write (final byte[] b, final int off, final int len) throws IOException
    {
      int last = Math.min(b.length, off + len);
      for (int i = off; i < last; i++)
      {
        checksum ^= b[i];
        System.out.println("Write byte: " + toBinary(b[i]) + "  CheckSum: " + toBinary(checksum));
      }
      out.write(b, off, len);
    }

    public void writeChecksum() throws IOException
    {
      out.write(checksum);
      checksum = 0;
    }
  }

  static String toBinary(final int num)
  {
    int cur = num;
    char[] buf = new char[32];
    for (int i = 31; i >= 0; i--)
    {
      buf[i] = cur % 2 == 0 ? '0' : '1';
      cur >>= 1;
    }
    return String.valueOf(buf);
  }
}