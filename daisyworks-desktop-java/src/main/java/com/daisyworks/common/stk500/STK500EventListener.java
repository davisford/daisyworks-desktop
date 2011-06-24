package com.daisyworks.common.stk500;

public interface STK500EventListener
{
  void notify(STK500Event event, int progress);
  void notify(STK500Event event);
}
