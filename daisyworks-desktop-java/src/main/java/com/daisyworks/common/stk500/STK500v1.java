package com.daisyworks.common.stk500;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import com.daisyworks.common.debug.LoggingInputStream;
import com.daisyworks.common.debug.LoggingOutputStream;
import com.daisyworks.common.intelhex.BufferedIntelHexReader;
import com.daisyworks.common.intelhex.IntelHexChunk;

/**
 * Class for communicating with Atmel devices using the STK500 (version 1)
 * protocol.
 *
 * Note: This class is not thread safe.
 *
 * @author Paul Lorenz
 */
public class STK500v1
{
  private static final boolean DEBUG = true;
  private static final int MAX_SYNC_COUNT = 3;

  public static final byte Resp_STK_OK                = 0x10;
  public static final byte Resp_STK_FAILED            = 0x11;
  public static final byte Resp_STK_UNKNOWN           = 0x12;
  public static final byte Resp_STK_NODEVICE          = 0x13;
  public static final byte Resp_STK_INSYNC            = 0x14;
  public static final byte Resp_STK_NOSYNC            = 0x15;
  public static final byte Resp_ADC_CHANNEL_ERROR     = 0x16;
  public static final byte Resp_ADC_MEASURE_OK        = 0x17;
  public static final byte Resp_PWM_CHANNEL_ERROR     = 0x18;
  public static final byte Resp_PWM_ADJUST_OK         = 0x19;

  public static final byte Cmnd_STK_GET_SYNC          = 0x30;
  public static final byte Cmnd_STK_SET_PARAMETER     = 0x40;
  public static final byte Cmnd_STK_GET_PARAMETER     = 0x41;
  public static final byte Cmnd_STK_SET_DEVICE        = 0x42;
  public static final byte Cmnd_SET_DEVICE_EXT        = 0x45;
  public static final byte Cmnd_STK_ENTER_PROGMODE    = 0x50;
  public static final byte Cmnd_STK_LEAVE_PROGMODE    = 0x51;
  public static final byte Cmnd_STK_CHIP_ERASE        = 0x52;
  public static final byte Cmnd_STK_LOAD_ADDRESS      = 0x55;
  public static final byte Cmnd_STK_UNIVERSAL         = 0x56;
  public static final byte Cmnd_STK_PROG_PAGE         = 0x64;
  public static final byte Sync_CRC_EOP               = 0x20;

  public static final int Parm_STK_HW_VER             = 0x80; // immutable
  public static final int Parm_STK_SW_MAJOR           = 0x81; // immutable
  public static final int Parm_STK_SW_MINOR           = 0x82; // immutable

  public static final int Parm_STK_LEDS               = 0x83; // mutable
  public static final int Parm_STK_VTARGET            = 0x84; // mutable
  public static final int Parm_STK_VADJUST            = 0x85; // mutable
  public static final int Parm_STK_OSC_PSCALE         = 0x86; // mutable
  public static final int Parm_STK_OSC_CMATCH         = 0x87; // mutable
  public static final int Parm_STK_RESET_DURATION     = 0x88; // mutable
  public static final int Parm_STK_SCK_DURATION       = 0x89; // mutable

  public static final int Parm_STK_BUFSIZEL           = 0x90; // mutable [0 to 255]
  public static final int Parm_STK_BUFSIZEH           = 0x91; // mutable [0 to 255]
  public static final int Parm_STK_DEVICE             = 0x92; // mutable [0 to 255]
  public static final int Parm_STK_PROGMODE           = 0x93; // mutable P/S
  public static final int Parm_STK_PARAMODE           = 0x94; // mutable T/F
  public static final int Parm_STK_POLLING            = 0x95; // mutable T/F
  public static final int Parm_STK_SELFTIMED          = 0x96; // mutable T/F

  public static final int Param_STK500_TOPCARD_DETECT = 0x98;

  public static final int UNIVERSAL_CMD_DEVICE_SIGNATURE = 0x30;

  private final OutputStream out;
  private final InputStream in;
  private final STK500EventListener eventListener;
  private final byte[] buf = new byte[256];

  public STK500v1(final OutputStream out, final InputStream in, final STK500EventListener eventListener)
  {
    this.out = DEBUG ? new LoggingOutputStream(out) : out;
    this.in  = DEBUG ? new LoggingInputStream(in)   : in;
    this.eventListener = eventListener;
  }

  protected void writeSync() throws IOException
  {
    buf[0] = Cmnd_STK_GET_SYNC;
    buf[1] = Sync_CRC_EOP;
    out.write(buf, 0, 2);
    out.flush();
  }

  protected int readParameter(final int parameter) throws IOException
  {
    buf[0] = Cmnd_STK_GET_PARAMETER;
    buf[1] = (byte)parameter;
    buf[2] = Sync_CRC_EOP;
    return writeWithRead(3, true);
  }

  protected void sync() throws IOException
  {
    eventListener.notify(STK500Event.SYNC_STARTED);
    boolean synced = false;
    int counter = 0;
    int read = 0;

    do
    {
      counter ++;
      writeSync();
      read = in.read();
      if (read == Resp_STK_INSYNC)
      {
        read = in.read();
        synced = read == Resp_STK_OK;
      }
      else
      {
        STKUtil.sleep(100, "Halted sync attempt due to interrupted exception");
      }
    } while (!synced && counter < 100);

    if (!synced)
    {
      throw new STK500SyncFailure("Failed to sync with device");
    }

    eventListener.notify(STK500Event.SYNC_DONE);
  }

  protected void write(final int bufferLength) throws IOException
  {
    int syncCount = 0;
    do
    {
      out.write(buf, 0, bufferLength);
      out.flush();

      if (Resp_STK_INSYNC == in.read() && Resp_STK_OK == in.read())
      {
        return;
      }

      sync();
      syncCount++;
    } while (syncCount < MAX_SYNC_COUNT);
    throw new STK500Exception("Failed to write message. Gave up after " + MAX_SYNC_COUNT + " sync attempts");
  }

  protected int writeWithRead(final int bufferLength, final boolean errorReturnAllowed) throws IOException
  {
    int syncCount = 0;
    do
    {
      out.write(buf, 0, bufferLength);
      out.flush();

      if (Resp_STK_INSYNC == in.read())
      {
        int result = in.read();
        int resultCode = in.read();
        if (resultCode == Resp_STK_OK)
        {
          return result;
        }
        if (errorReturnAllowed && resultCode == Resp_STK_FAILED)
        {
          return -1;
        }
        throw new STK500Exception("Unexpected value '" + Integer.toHexString(resultCode) + "'. Expected STK_OK or STK_FAILED");
      }

      sync();
      syncCount++;
    } while (syncCount < MAX_SYNC_COUNT);
    throw new STK500Exception("Failed to write message. Gave up after " + MAX_SYNC_COUNT + " sync attempts");
  }

  /**
   * Parameter Name | Field Usage
   * -------------------------------------------------------------------------
   * devicecode     | Device code as defined in â€œdevices.hâ€�
   * ------------------------------------------------------------------------
   * revision       | Device revision. Currently not used. Should be set to 0.
   * -------------------------------------------------------------------------
   * progtype       | Defines which Program modes is supported:
   *                |    â€œ0â€� â€“ Both Parallel/High-voltage and Serial mode
   *                |    â€œ1â€� â€“ Only Parallel/High-voltage mode
   * -------------------------------------------------------------------------
   * parmode        | Defines if the device has a full parallel interface or a
   *                | pseudo parallel programming interface:
   *                |    â€œ0â€� â€“ Pseudo parallel interface
   *                |    â€œ1â€� â€“ Full parallel interface
   * -------------------------------------------------------------------------
   * polling        | Defines if polling may be used during SPI access:
   *                |    â€œ0â€� â€“ No polling may be used
   *                |    â€œ1â€� â€“ Polling may be used
   * -------------------------------------------------------------------------
   * selftimed      | Defines if programming instructions are self timed:
   *                |    â€œ0â€� â€“ Not self timed
   *                |    â€œ1â€� â€“ Self timed
   * -------------------------------------------------------------------------
   * lockbytes      | Number of Lock bytes. Currently not used. Should be set
   *                | to actual number of Lock bytes for future compatibility.
   * -------------------------------------------------------------------------
   * fusebytes      | Number of Fuse bytes. Currently not used. Should be set
   *                | to actual number of Fuse bytes for future compatibility.
   * -------------------------------------------------------------------------
   * flashpollval1  | FLASH polling value. See Data Sheet for the device.
   * -------------------------------------------------------------------------
   * flashpollval2  | FLASH polling value. Same as â€œflashpollval1â€�
   * -------------------------------------------------------------------------
   * eeprompollval1 | EEPROM polling value 1 (P1). See data sheet for the
   *                | device.
   * -------------------------------------------------------------------------
   * eeprompollval2 | EEPROM polling value 2 (P2). See data sheet for device.
   * -------------------------------------------------------------------------
   * pagesizehigh   | Page size in bytes for pagemode parts, High Byte of 16-
   *                | bit value.
   * -------------------------------------------------------------------------
   * pagesizelow    | Page size in bytes for pagemode parts, Low Byte of 16-
   *                | bit value.
   * -------------------------------------------------------------------------
   * eepromsizehigh | EEPROM size in bytes, High Byte of 16-bit value.
   * -------------------------------------------------------------------------
   * eepromsizelow  | EEPROM size in bytes, Low Byte of 16-bit value.
   * -------------------------------------------------------------------------
   *  flashsize4    | FLASH size in bytes, byte 4 (High Byte) of 32-bit value.
   * -------------------------------------------------------------------------
   * flashsize3     | FLASH size in bytes, byte 3 of 32-bit value.
   * -------------------------------------------------------------------------
   * flashsize2     | FLASH size in bytes, byte 2 of 32-bit value.
   * -------------------------------------------------------------------------
   * flashsize1     | FLASH size in bytes, byte 1 (Low Byte) of 32-bit value.
   * -------------------------------------------------------------------------
   */
  protected void setDeviceProgrammingParameters() throws IOException
  {
    //                  0      1      2      3      4      5      6      7      8     9       10     11     12     13     14     15     16     17     18     19     20     21
    // avrdude: Send: B [42] . [86] . [00] . [00] . [01] . [01] . [01] . [01] . [03] . [ff] . [ff] . [ff] . [ff] . [00] . [80] . [04] . [00] . [00] . [00] . [80] . [00]   [20]

    buf[0]  = Cmnd_STK_SET_DEVICE;
    buf[1]  = (byte)0x82;   // devicecode          (0x82 is ATmega16)
    buf[2]  = 0;            // revision.
    buf[3]  = 0;            // progtype.
    buf[4]  = 0;            // parmode
    buf[5]  = 1;            // polling
    buf[6]  = 1;            // selftimed
    buf[7]  = 1;            // lockbytes
    buf[8]  = 3;            // fusebytes
    buf[9]  = (byte)0xFF;   // flashpollval1
    buf[10] = (byte)0xFF;   // flashpollval2
    buf[11] = (byte)0xFF;   // eeprompollval1
    buf[12] = 0;            // eeprompollval2
    buf[13] = 0;            // pagesizehigh
    buf[14] = (byte)0xFF;   // pagesizelow
    buf[15] = 4;            // eepromsizehigh
    buf[16] = 0;            // eepromsizelow
    buf[17] = 0;            // flashsize4
    buf[18] = 0;            // flashsize3
    buf[19] = (byte)0x80;   // flashsize2
    buf[20] = 3;            // flashsize1
    buf[21] = Sync_CRC_EOP; // sync
    write(22);
  }

  /**
   * Parameter Name | Field Usage
   * ----------------------------------------------------------------------------------------------------------------
   * commandsize    | Defines how many bytes of additional parameters the command contains. In this case itâ€™s value
   *                | should be 4 (for the eepromsize, signalpagel and signalbs2 parameters). The STK500 may
   *                | accept more parameters in later revisions.
   * ----------------------------------------------------------------------------------------------------------------
   * eeprompagesize | EEPROM page size in bytes.
   * ----------------------------------------------------------------------------------------------------------------
   * signalpagel    | Defines to which port pin the PAGEL signal should be mapped. Example: signalpagel = 0xD7. In
   *                | this case PAGEL should be mapped to PORTD7.
   * ----------------------------------------------------------------------------------------------------------------
   * signalbs2      | Defines to which port pin the BS2 signal should be mapped. See signalpagel.
   * ----------------------------------------------------------------------------------------------------------------
   * ResetDisable   | Defines whether a part has RSTDSBL Fuse (value = 1) or not (value = 0).
   * ----------------------------------------------------------------------------------------------------------------
   */
  protected void setExtendedDeviceProgrammingParameters() throws IOException
  {
    //                  0      1      2      3      4      5      6
    // avrdude: Send: E [45] . [05] . [04] . [d7] . [c2] . [00]   [20]
    buf[0] = Cmnd_SET_DEVICE_EXT;
    buf[1] = 5;
    buf[2] = 4;
    buf[3] = (byte)0xD7;
    buf[4] = (byte)0xC2;
    buf[5] = 0;
    buf[6] = Sync_CRC_EOP;
    write(7);
  }

  protected void enterProgrammingMode() throws IOException
  {
    buf[0] = Cmnd_STK_ENTER_PROGMODE;
    buf[1] = Sync_CRC_EOP;
    write(2);
  }

  protected void leaveProgrammingMode() throws IOException
  {
    buf[0] = Cmnd_STK_LEAVE_PROGMODE;
    buf[1] = Sync_CRC_EOP;
    write(2);
  }

  protected void readDeviceSignature() throws IOException
  {
    buf[0] = Cmnd_STK_UNIVERSAL;
    buf[1] = UNIVERSAL_CMD_DEVICE_SIGNATURE;
    buf[2] = 0;
    buf[3] = 0; // Read byte 0 of the device signature
    buf[4] = 0;
    buf[5] = Sync_CRC_EOP;
    int byte1 = writeWithRead(6, false);

    buf[3] = 1; // Read byte 1 of the device signature
    int byte2 = writeWithRead(6, false);

    buf[3] = 2; // Read byte 2 of the device signature
    int byte3 = writeWithRead(6, false);

    int result = (byte1 << 16) | (byte2 << 8) | byte3;
    System.out.println("Byte: " + STKUtil.toHex(result));
  }

  protected void eraseChip() throws IOException
  {
    buf[0] = Cmnd_STK_CHIP_ERASE;
    buf[1] = Sync_CRC_EOP;
    write(2);
    STKUtil.sleep(50, "Interrupted while waiting for chip erase");
  }

  protected void eraseChipWithUniversal() throws IOException
  {
    buf[0] = Cmnd_STK_UNIVERSAL;
    buf[1] = (byte)0xa0;
    buf[2] = 3;
    buf[3] = (byte)0xfc;
    buf[4] = 0;
    buf[5] = Sync_CRC_EOP;
    writeWithRead(6, false);
    STKUtil.sleep(50, "Interrupted while waiting for chip erase");

    buf[3] = (byte)0xfd;
    writeWithRead(6, false);
    STKUtil.sleep(50, "Interrupted while waiting for chip erase");

    buf[3] = (byte)0xfe;
    writeWithRead(6, false);
    STKUtil.sleep(50, "Interrupted while waiting for chip erase");

    buf[3] = (byte)0xff;
    writeWithRead(6, false);
    STKUtil.sleep(50, "Interrupted while waiting for chip erase");

    buf[1] = (byte)0xac;
    buf[2] = 80;
    buf[3] = 0;
    writeWithRead(6, false);
    STKUtil.sleep(50, "Interrupted while waiting for chip erase");
  }

  /**
   * Address is apparently shifted to drop LSB. Maybe b/c arch is
   * (at minimum) 2-bit aligned, so least significant digit can
   * only be 0 anyway?
   *
   * @param address Address to load to
   * @throws IOException
   */
  protected void loadAddress(final int address) throws IOException
  {
    final int shiftedAddress = address; // address >> 1;
    buf[0] = Cmnd_STK_LOAD_ADDRESS;
    buf[1] = (byte)shiftedAddress;        //LSB
    buf[2] = (byte)(shiftedAddress >> 8); // MSB
    buf[3] = Sync_CRC_EOP;
    write(4);
  }

  protected void setupProgramPage()
  {
    buf[0] = Cmnd_STK_PROG_PAGE;
    buf[1] = 0;          // data block size (high)
    buf[2] = (byte)0x10; // data block size (low)
    buf[3] = 'F';        // Flash (F) or EEPROM (E)
  }

  public void writeProgram(final BufferedIntelHexReader reader,
                           final long filesize)
    throws IOException
  {
    eventListener.notify(STK500Event.FIRMWARE_SEND_START);
    long writeStart = 0;

    IntelHexChunk chunk;

    long elapsed;
    int address = -64;
    long bytesRead = 0;
    int progress = -1;

    // If we don't write in blocks of 128 bytes, it doesn't seem to work
    reader.setChunkSize(128);

    while (null != (chunk = reader.readNextBufferedChunk()))
    {
      address += 64;

      System.arraycopy(chunk.data, 0, buf, 4, chunk.size);

      bytesRead += chunk.getBytesRead();

      if ((elapsed = System.currentTimeMillis() - writeStart) < 5)
      {
        STKUtil.sleep(5 - elapsed, "Interrupted while waiting for page write");
      }

      loadAddress(address);
      setupProgramPage();
      buf[2] = (byte)chunk.size;
      writeStart = System.currentTimeMillis();

      buf[4 + chunk.size] = Sync_CRC_EOP;
      write(chunk.size + 5);
      int newProgress = (int)((bytesRead * 100) / filesize);
      if (progress != newProgress)
      {
        eventListener.notify(STK500Event.FIRMWARE_SEND_UPDATE, newProgress);
        progress = newProgress;
      }
    }

    STKUtil.sleep(5, "Interrupted while waiting for page write");
    if (progress != 100)
    {
      eventListener.notify(STK500Event.FIRMWARE_SEND_UPDATE, 100);
    }

    eventListener.notify(STK500Event.FIRMWARE_SEND_DONE);
  }

  public void updateFirmware(final BufferedIntelHexReader reader,
                             final long filesize)
    throws IOException
  {
    sync();
    sync();
    sync();

    eventListener.notify(STK500Event.PARAMETERS_SET_START);
    setDeviceProgrammingParameters();
    setExtendedDeviceProgrammingParameters();
    eventListener.notify(STK500Event.PARAMETERS_SET_DONE);
    //eraseChipWithUniversal();
    enterProgrammingMode();

    writeProgram(reader, filesize);
    leaveProgrammingMode();
    eventListener.notify(STK500Event.COMPLETE);
  }
}