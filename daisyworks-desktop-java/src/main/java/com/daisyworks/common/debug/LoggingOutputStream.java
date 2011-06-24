package com.daisyworks.common.debug;

import java.io.FilterOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import com.daisyworks.common.stk500.STK500Logger;
import com.daisyworks.common.stk500.STKUtil;

public class LoggingOutputStream extends FilterOutputStream
{
  public LoggingOutputStream (final OutputStream out)
  {
    super(out);
  }

  @Override
  public void write (final int b) throws IOException
  {
    out.write(b);
    STK500Logger.log("Wrote byte : " + STKUtil.toHex(b));
  }

  @Override
  public void write (final byte[] b) throws IOException
  {
    write(b, 0, b.length);
  }

  @Override
  public void write (final byte[] b, final int off, final int len) throws IOException
  {
    STK500Logger.log("Wrote bytes: " + STKUtil.toHex(b, off, len));
    out.write(b, off, len);
  }
}