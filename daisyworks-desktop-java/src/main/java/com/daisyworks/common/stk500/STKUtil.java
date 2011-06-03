package com.daisyworks.common.stk500;

public class STKUtil
{
  public static void sleep(final long time, final String errorMsg) throws STK500Exception
  {
    try
    {
      Thread.sleep(time);
    }
    catch(InterruptedException ie)
    {
      Thread.currentThread().interrupt();
      throw new STK500Exception(errorMsg, ie);
    }
  }

  public static String toHex(final int i)
  {
    return Integer.toHexString((i & 0x000000FF));
  }

  public static String toHex(final byte[] b)
  {
    return toHex(b, 0, b.length);
  }

  public static String toHex(final byte[] b,
                             final int offset,
                             final int length)
  {
    StringBuilder buf = new StringBuilder();
    buf.append("[");
    if (b != null && b.length > offset)
    {
      buf.append(toHex(b[offset]));
      final int end = Math.min(b.length, offset + length);
      for (int i = offset + 1; i < end; i++)
      {
        buf.append(", ");
        buf.append(toHex(b[i]));
      }
    }
    buf.append("]");
    return buf.toString();
  }

}
