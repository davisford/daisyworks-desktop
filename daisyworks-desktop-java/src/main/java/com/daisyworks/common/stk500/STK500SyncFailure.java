package com.daisyworks.common.stk500;

public class STK500SyncFailure extends STK500Exception
{
  private static final long serialVersionUID = 1L;

  public STK500SyncFailure (final String message, final Throwable cause)
  {
    super(message, cause);
  }

  public STK500SyncFailure (final String message)
  {
    super(message);
  }
}
