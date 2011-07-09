package com.daisyworks.common.stk500;

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.atomic.AtomicBoolean;

public class AsyncInputStreamThread extends Thread implements AsyncInputStream
{
  private final AtomicBoolean isRunning = new AtomicBoolean(false);
  private final InputStream in;
  private IOException ioException;

  private final int[] buf = new int[128];
  private int readPosition = 0;
  private int writePosition = 0;
  private int length = 0;

  public AsyncInputStreamThread(final InputStream in)
  {
    this.in = in;
  }

  @Override
  public void run()
  {
    isRunning.set(true);
    try
    {
      runInner();
    }
    finally
    {
      isRunning.set(false);
    }
  }

  public void runInner()
  {

    int next = 0;
    while (true)
    {
      synchronized(buf)
      {
        while (length == buf.length)
        {
          try
          {
            buf.wait();
          }
          catch(final InterruptedException ie)
          {
            Thread.currentThread().interrupt();
            return;
          }
        }
      }

      try
      {
        next = in.read();
      }
      catch(final IOException ioe)
      {
        ioException = ioe;
        return;
      }

      synchronized(buf)
      {
        length++;
        buf[writePosition] = next;
        writePosition++;
        if (writePosition == buf.length)
        {
          writePosition = 0;
        }
        buf.notifyAll();
      }

      if (next == -1)
      {
        return;
      }
    }
  }

  private boolean waitForData(final long timeout) throws IOException
  {
    long start = System.currentTimeMillis();
    boolean first = false;
    while (length == 0)
    {
      long now = 0;
      if (!first)
      {
        now = System.currentTimeMillis();
        if (now - timeout >= start)
        {
          return false;
        }
      }

      try
      {
        buf.wait(first ? timeout : timeout - (now - start));
      }
      catch(final InterruptedException ie)
      {
        Thread.currentThread().interrupt();
        throw new IOException("Interrupted while reading", ie);
      }
    }
    return true;
  }

  @Override
  public int read (final long timeout) throws IOException
  {
    synchronized(buf)
    {
      if (length == 0)
      {
        if (ioException != null)
        {
          throw ioException;
        }

        if (!waitForData(timeout))
        {
          return -2;
        }
      }

      int result = buf[readPosition];
      length--;
      readPosition++;
      if (readPosition == buf.length)
      {
        readPosition = 0;
      }
      buf.notifyAll();

      return result;
    }
  }

  public boolean isRunning()
  {
    return isRunning.get();
  }
}
