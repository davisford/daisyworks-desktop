package com.daisyworks.common.stk500;

public class STK500Exception extends RuntimeException
{
  private static final long serialVersionUID = 1L;

  public STK500Exception (final String message, final Throwable cause)
  {
    super(message, cause);
  }

  public STK500Exception (final String message)
  {
    super(message);
  }
}
