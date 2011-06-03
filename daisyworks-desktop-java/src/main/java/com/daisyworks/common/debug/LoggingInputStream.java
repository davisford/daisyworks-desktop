package com.daisyworks.common.debug;

import java.io.FilterInputStream;
import java.io.IOException;
import java.io.InputStream;

import com.daisyworks.common.stk500.STKUtil;

public class LoggingInputStream extends FilterInputStream
{
  public LoggingInputStream (final InputStream in)
  {
    super(in);
  }

  @Override
  public int read () throws IOException
  {
    int read = super.read();
    System.out.println("Read byte: " + STKUtil.toHex(read));
    return read;
  }
}