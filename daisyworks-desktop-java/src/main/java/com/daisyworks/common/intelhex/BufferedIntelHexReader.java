package com.daisyworks.common.intelhex;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;

import com.daisyworks.common.stk500.STKUtil;

public class BufferedIntelHexReader extends IntelHEXReader
{
  private int targetChunkSize;
  private final IntelHexChunk chunk;
  private IntelHexChunk nextChunk;
  private int copySize;
  private boolean readDone = false;

  public BufferedIntelHexReader(final Reader in)
  {
    super(in);
    this.chunk = new IntelHexChunk();
  }

  public void setChunkSize(final int targetChunkSize)
  {
    this.targetChunkSize = targetChunkSize;
    this.chunk.data = new byte[targetChunkSize];
  }

  public IntelHexChunk readNextBufferedChunk () throws IOException
  {
    chunk.size = 0;

    if (nextChunk != null)
    {
      final int size = nextChunk.size - copySize;
      System.arraycopy(nextChunk.data, copySize, chunk.data, 0, size);
      chunk.size += size;
    }

    if (readDone)
    {
      return chunk.size > 0 ? chunk : null;
    }

    while (chunk.size < targetChunkSize && null != (nextChunk = readNextChunk()))
    {
      copySize = Math.min(nextChunk.size, targetChunkSize - chunk.size);
      System.arraycopy(nextChunk.data, 0, chunk.data, chunk.size, copySize);
      chunk.size += copySize;
    }

    if (nextChunk == null)
    {
      readDone = true;
    }
    else if (copySize == nextChunk.size)
    {
      nextChunk = null;
    }

    return chunk.size > 0 ? chunk : null;
  }

  public static void main (final String[] args) throws Exception
  {
    BufferedIntelHexReader fileInput = new BufferedIntelHexReader(new BufferedReader(new FileReader("/home/paul/workspace/daisyworks-firmware/shell/tmp/shell.hex")));
    fileInput.setChunkSize(128);
    System.out.println("Start");
    IntelHexChunk chunk;
    while (null != (chunk = fileInput.readNextBufferedChunk()))
    {
      System.out.println(STKUtil.toHex(chunk.data, 0, chunk.size));
    }
  }
}
