package com.daisyworks.common.stk500;

import java.io.IOException;

public interface AsyncInputStream
{
  /**
   * Returns the next byte read, in the range: 0-255
   * Returns -1 for end of stream
   * Returns -2 for timeout
   *
   * @param timeout How long to wait before
   *
   * @return 0-255 if a value is read in the given timeout, -1 if end-of-stream is reached, -2 if a timeout is reached
   */
  int read(long timeout) throws IOException;
  void interrupt();
}
