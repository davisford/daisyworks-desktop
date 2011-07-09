package com.daisyworks.common.debug;

import java.io.IOException;

import com.daisyworks.common.stk500.AsyncInputStream;
import com.daisyworks.common.stk500.STK500Logger;
import com.daisyworks.common.stk500.STKUtil;

public class LoggingAsyncInputStream implements AsyncInputStream
{
  private final AsyncInputStream in;

  public LoggingAsyncInputStream (final AsyncInputStream in)
  {
    this.in = in;
  }

  @Override
  public int read(final long timeout) throws IOException
  {
    int read = in.read(timeout);
    STK500Logger.log("Read byte: " + STKUtil.toHex(read));
    return read;
  }

  @Override
  public void interrupt ()
  {
    in.interrupt();
  }
}