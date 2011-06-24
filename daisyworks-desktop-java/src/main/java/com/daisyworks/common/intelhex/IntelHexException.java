package com.daisyworks.common.intelhex;

public class IntelHexException extends RuntimeException
{
  private static final long serialVersionUID = 1L;

  public IntelHexException (final String message, final Throwable cause)
  {
    super(message, cause);
  }

  public IntelHexException (final String message)
  {
    super(message);
  }
}
