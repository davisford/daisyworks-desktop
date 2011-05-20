/**
 * 
 */
package com.daisyworks.service;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import javax.bluetooth.BluetoothStateException;
import javax.bluetooth.DataElement;
import javax.bluetooth.DeviceClass;
import javax.bluetooth.DiscoveryAgent;
import javax.bluetooth.DiscoveryListener;
import javax.bluetooth.LocalDevice;
import javax.bluetooth.RemoteDevice;
import javax.bluetooth.ServiceRecord;
import javax.bluetooth.UUID;
import javax.microedition.io.Connector;
import javax.microedition.io.StreamConnection;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.flex.messaging.MessageTemplate;
import org.springframework.flex.remoting.RemotingDestination;
import org.springframework.flex.remoting.RemotingInclude;
import org.springframework.stereotype.Service;

import com.daisyworks.model.Device;

/**
 * Handles all the Bluetooth stuff
 */
@Service
@RemotingDestination(channels = { "my-amf" })
public final class BluetoothService implements DiscoveryListener {

	private static final Logger LOGGER = Logger
			.getLogger(BluetoothService.class);

	// object used for waiting
	private static Object deviceLock = new Object();
	private static Object serviceLock = new Object();

	// map of discovered devices; key = device address
	private final ConcurrentMap<String, RemoteDevice> deviceMap = new ConcurrentHashMap<String, RemoteDevice>();
	// map of service urls; key = device address
	private final ConcurrentMap<String, String> serviceMap = new ConcurrentHashMap<String, String>();
	// map of device address to connection
	private final ConcurrentMap<String, StreamConnection> connectionMap = new ConcurrentHashMap<String, StreamConnection>();
	
	private DeviceDiscoveryResult lastDeviceDiscoveryResult;
	private ServiceDiscoveryResult lastServiceDiscoveryResult;

	// our main entry point into Java Bluetooth
	private DiscoveryAgent agent;
	
	// for reading from the UART
	private BufferedReader reader;
	// for posting to the UART
	private DataOutputStream output;

	// reader background thread that publishes to the AMF channel
	private ConsoleReadThread consoleReadThread;

	// Spring template for AMF pub/sub
	private MessageTemplate template;
	
	private static final UUID[] uuidSet = new UUID[] {
		// new UUID(0x0001), // SDP
		new UUID(0x0003) // RFCOMM
		// new UUID(0x0008), // OBEX
		// new UUID(0x000C), // HTTP
		// new UUID(0x0100) // L2CAP
		// new UUID(0x000F), // BNEP
		// new UUID(0x1101), // Serial Port
		// new UUID(0x1000), // ServiceDiscoveryServerServiceClassID
		// new UUID(0x1001), // BrowseGroupDescriptorServiceClassID
		// new UUID(0x1002), // PublicBrowseGroup
		// new UUID(0x1105), // OBEX Oject Push
		// new UUID(0x1106), // OBEX File Transfer
		// new UUID(0x1115), // PAN
		// new UUID(0x1116), // Network Access Point
		// new UUID(0x1117), // Group Network
	};

	private static int[] attrSet = new int[] { 
		0x0100 // Service name
	};

	/**
	 * Constructor
	 */
	public BluetoothService() {
		LOGGER.debug("Bluetooth Service initialized");
	}

	/**
	 * Spring injected {@link MessageTemplate}
	 * @param template
	 */
	@Autowired
	public void setTemplate(MessageTemplate template) {
		this.template = template;
	}

	/**
	 * Get the Local Device information
	 * 
	 * @return a {@link Device} that represents our local adapter
	 */
	@RemotingInclude
	public Device getLocalDevice() {
		try {
			final LocalDevice localDevice = LocalDevice.getLocalDevice();
			final Device device = new Device(localDevice.getFriendlyName(),
					localDevice.getBluetoothAddress());
			return device;
		} catch (Exception e) {
			LOGGER.error(e);
			throw new BluetoothServiceException(e);
		}
	}

	/**
	 * Discover any Bluetooth devices in range
	 * 
	 * @return a set of discovered {@link Device}s
	 */
	@RemotingInclude
	public Set<Device> findDevices() throws Exception {
		// clear the map
		deviceMap.clear();
		try {
			final LocalDevice localDevice = LocalDevice.getLocalDevice();
			LOGGER.info("Local Bluetooth Name/Addres: "
					+ localDevice.getFriendlyName() + "/"
					+ localDevice.getBluetoothAddress());

			agent = localDevice.getDiscoveryAgent();

			LOGGER.info("Starting Device Inquiry");
			agent.startInquiry(DiscoveryAgent.GIAC, this);
			try {
				synchronized (deviceLock) {
					deviceLock.wait();
				}
			} catch (InterruptedException e) {
				LOGGER.error(e);
				throw new RuntimeException(e);
			}
			LOGGER.debug("Device Inquiry Complete => " + lastDeviceDiscoveryResult);
			if(!DeviceDiscoveryResult.INQUIRY_COMPLETED.equals(lastDeviceDiscoveryResult)) {
				// something went wrong
				throw new BluetoothServiceException(lastDeviceDiscoveryResult.asString());
			}

			if (deviceMap.size() == 0) {
				LOGGER.warn("No Bluetooth devices were found");
				return new HashSet<Device>(0);
			} else {
				LOGGER.info("Discovered " + deviceMap.size() + " devices");
			}
			return toDeviceSet(deviceMap);
		} catch (BluetoothServiceException e) {
			throw e;
		} catch (Exception e) {
			LOGGER.error(e);
			throw new BluetoothServiceException(e);
		}
	}

	/**
	 * Find the RFCOMM service for the given address; the address is cached so when you call
	 * connect, the service URL will be used that this method looked up
	 * @param address the Bluetooth address of the device 
	 * @throws Exception 
	 */
	@RemotingInclude
	public void findServices(final String address) throws Exception {
		LOGGER.info("Searching for services on remote device " + address);
		final RemoteDevice remoteDevice = deviceMap.get(address);
		if (remoteDevice == null) {
			throw new BluetoothServiceException("Unknown device address: " + address);
		}

		synchronized (serviceLock) {
			try {
				agent.searchServices(attrSet, uuidSet, remoteDevice, this);
			} catch (BluetoothStateException e) {
				LOGGER.error(e.getMessage());
				throw new RuntimeException(e);
			} finally {
				try {
					serviceLock.wait();
				} catch (InterruptedException e) {
					LOGGER.error(e.getMessage());
					throw new RuntimeException(e);
				}
				if(!ServiceDiscoveryResult.SERVICE_SEARCH_COMPLETED.equals(lastServiceDiscoveryResult)) {
					throw new BluetoothServiceException(lastServiceDiscoveryResult.asString());
				}
			}
		}
	}

	/**
	 * Connect to the SPP on the given address
	 * 
	 * @param address the Bluetooth address
	 * @throws Exception
	 */
	@RemotingInclude
	public void connectRFComm(String address) throws Exception {
		StreamConnection connection = null;
		if(connectionMap.containsKey(address)) {
			connection = connectionMap.get(address);
		} else {
			connection = (StreamConnection) Connector.open(serviceMap.get(address));
			connectionMap.put(address, connection);
		}
		reader = new BufferedReader(new InputStreamReader((connection.openInputStream())));
		output = connection.openDataOutputStream();
		if (consoleReadThread == null) {
			consoleReadThread = new ConsoleReadThread(reader, template);
		}
		consoleReadThread.start();
	}
	
	/**
	 * Disconnect from the RFComm service
	 * @param address
	 * @throws Exception
	 */
	@SuppressWarnings("deprecation")
	@RemotingInclude
	public void disconnectRFComm(String address)  {
		StreamConnection connection = connectionMap.get(address);
		try {
			// stop the thread
			if(consoleReadThread != null) {
				/*
				 * This is deprecated, but the Bluecove implementation of InputStream
				 * provides no possible way to interrupt a thread that is doing a blocking
				 * read call;  This big hammer approach is the only sane way to deal
				 * with this.
				 */
				consoleReadThread.stop(); 
			}
			if(reader != null) { reader.close(); }
			if(output != null) { output.close(); }
			if(connection != null) { connection.close(); }
			connectionMap.remove(address);
		} catch (Exception e) {
			LOGGER.error(e);
		} finally {
			consoleReadThread = null;
		}
	}

	/**
	 * Sends a command via Bluetooth to the UART to the micro to be processed by
	 * the shell program.
	 * 
	 * @param command
	 *            the command to send
	 * @throws Exception
	 */
	@RemotingInclude
	public void send(String command) throws Exception {
		if (output != null) {
			output.writeBytes(command);
			output.flush();
		}
	}

	/**
	 * Converts the map into a set of {@link Device} objects that can be
	 * serialized easily through AMF.
	 * 
	 * @param map
	 * @return
	 * @throws IOException
	 */
	private Set<Device> toDeviceSet(Map<String, RemoteDevice> map)
			throws IOException {
		Set<Device> set = new HashSet<Device>();
		for (String key : map.keySet()) {
			RemoteDevice rd = map.get(key);
			Device device = new Device(rd.getFriendlyName(false),
					rd.getBluetoothAddress());
			device.setAuthenticated(rd.isAuthenticated());
			device.setEncrypted(rd.isEncrypted());
			device.setTrusted(rd.isTrustedDevice());
			set.add(device);
		}
		return set;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#deviceDiscovered(javax.bluetooth.
	 * RemoteDevice, javax.bluetooth.DeviceClass)
	 */
	@Override
	public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
		LOGGER.info("Device discovered: " + btDevice.getBluetoothAddress());
		deviceMap.put(btDevice.getBluetoothAddress(), btDevice);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#inquiryCompleted(int)
	 */
	@Override
	public void inquiryCompleted(int discType) {
		LOGGER.debug("inquiry completed: "+discType);
		switch (discType) {
		case DiscoveryListener.INQUIRY_COMPLETED:
			lastDeviceDiscoveryResult = DeviceDiscoveryResult.INQUIRY_COMPLETED;
			break;
		case DiscoveryListener.INQUIRY_TERMINATED:
			lastDeviceDiscoveryResult = DeviceDiscoveryResult.INQUIRY_TERMINATED;
			break;
		case DiscoveryListener.INQUIRY_ERROR:
			lastDeviceDiscoveryResult = DeviceDiscoveryResult.INQUIRY_ERROR;
			break;
		default:
			LOGGER.error("\tresponse code: Unknown Response Code =>" + discType);
			lastDeviceDiscoveryResult = DeviceDiscoveryResult.UNKNOWN;
			break;
		}
		synchronized (deviceLock) {
			deviceLock.notify();
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#servicesDiscovered(int,
	 * javax.bluetooth.ServiceRecord[])
	 */
	public void servicesDiscovered(int transID, ServiceRecord[] servRecord) {
		for (int i = 0; i < servRecord.length; i++) {
			String url = servRecord[i].getConnectionURL(
					ServiceRecord.NOAUTHENTICATE_NOENCRYPT, false);
			if (url == null) {
				LOGGER.error("\tService url was null for "
						+ servRecord[i].toString());
			}
			serviceMap.put(servRecord[i].getHostDevice().getBluetoothAddress(),
					url);
			DataElement serviceName = servRecord[i].getAttributeValue(0x0100);
			if (serviceName != null) {
				LOGGER.info("\tService " + serviceName.getValue() + " found "
						+ url);
			} else {
				LOGGER.info("\tService found " + url);
			}
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#serviceSearchCompleted(int, int)
	 */
	public void serviceSearchCompleted(int transID, int respCode) {
		LOGGER.info("Service search complete for transaction " + transID);
		switch (respCode) {
		case DiscoveryListener.SERVICE_SEARCH_COMPLETED:
			lastServiceDiscoveryResult = ServiceDiscoveryResult.SERVICE_SEARCH_COMPLETED;
			break;
		case DiscoveryListener.SERVICE_SEARCH_DEVICE_NOT_REACHABLE:
			lastServiceDiscoveryResult = ServiceDiscoveryResult.SERVICE_SEARCH_DEVICE_NOT_REACHABLE;
			break;
		case DiscoveryListener.SERVICE_SEARCH_ERROR:
			lastServiceDiscoveryResult = ServiceDiscoveryResult.SERVICE_SEARCH_ERROR;
			break;
		case DiscoveryListener.SERVICE_SEARCH_NO_RECORDS:
			lastServiceDiscoveryResult = ServiceDiscoveryResult.SERVICE_SEARCH_NO_RECORDS;
			break;
		case DiscoveryListener.SERVICE_SEARCH_TERMINATED:
			lastServiceDiscoveryResult = ServiceDiscoveryResult.SERVICE_SEARCH_TERMINATED;
			break;
		default:
			LOGGER.error("\tUnknown Response Code: " + respCode);
			lastServiceDiscoveryResult = ServiceDiscoveryResult.UNKNOWN;
		}
		synchronized (serviceLock) {
			serviceLock.notifyAll();
		}
	}

	/**
	 * Background thread for reading from the UART and posting on message bus
	 * for UI
	 */
	private class ConsoleReadThread extends Thread {
		
		private BufferedReader reader;
		private MessageTemplate template;

		public ConsoleReadThread(BufferedReader reader, MessageTemplate template) throws IOException {
			this.reader = reader;
			this.template = template;
		}
		
		/**
		 * {@link BufferedReader#readLine()} and all read methods are blocking I/O that
		 * can't be interrupted.  Even if I wrap it with NIO, the underlying input
		 * stream is of type com.intel.bluetooth.BluetoothRFCommInputStream which can't
		 * be interrupted.  The only way to stop this is to use {@link Thread#stop()}
		 */
		@Override
		public void run() {
			LOGGER.info("Background thread listening for serial port updates  ");
			try {
				while (true) {
					String line = reader.readLine();
					template.send("serialPort", line);
				}		
			} catch (IOException e) {
				LOGGER.error(e);
			} 
		}
	}
}
