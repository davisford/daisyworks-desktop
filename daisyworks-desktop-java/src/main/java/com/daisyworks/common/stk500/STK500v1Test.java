package com.daisyworks.common.stk500;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.RandomAccessFile;

import com.daisyworks.common.intelhex.BufferedIntelHexReader;

public class STK500v1Test
{
  public static void main (final String[] args) throws Exception
  {
    final RandomAccessFile file = new RandomAccessFile("/dev/ttyUSB0", "rwd");
    final FileOutputStream out = new FileOutputStream(file.getFD());
    final FileInputStream in = new FileInputStream(file.getFD());

    //final File testFile = new File("/home/paul/workspace/daisyworks-firmware/shell/tmp/shell.hex");
    final File testFile = new File("/home/paul/tmp/davis-firmware.hex");

    final BufferedIntelHexReader reader =
      new BufferedIntelHexReader(
        new BufferedReader(
          new FileReader(testFile)));

    final STK500EventListener listener = new STK500EventListener()
    {
      @Override
      public void notify (final STK500Event event)
      {
        System.out.println(event);
      }

      @Override
      public void notify (final STK500Event event, final int progress)
      {
        System.out.println(event + ": " + progress + "%");
      }
    };

    AsyncInputStreamThread asyncIn = new AsyncInputStreamThread(in);
    asyncIn.setDaemon(true);
    asyncIn.start();
    try
    {
      final STK500v1 stk500Test = new STK500v1(out, asyncIn, listener);
      stk500Test.updateFirmware(reader, testFile.length());
      reader.close();
    }
    finally
    {
      in.close();
      file.close();
      asyncIn.interrupt();
    }
  }
}
