package com.daisyworks;

import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_DEVICES_LIST;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_BLUECOVE_VERSION;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_DEVICE_ID;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_FEATURE_L2CAP;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_FEATURE_SERVICE_ATTRIBUTES;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_FEATURE_SET_DEVICE_SERVICE_CLASSES;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_OPEN_CONNECTIONS;
import static com.intel.bluetooth.BlueCoveLocalDeviceProperties.LOCAL_DEVICE_PROPERTY_STACK;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.HashSet;
import java.util.Set;

import javax.bluetooth.DataElement;
import javax.bluetooth.DeviceClass;
import javax.bluetooth.DiscoveryAgent;
import javax.bluetooth.DiscoveryListener;
import javax.bluetooth.LocalDevice;
import javax.bluetooth.RemoteDevice;
import javax.bluetooth.ServiceRecord;
import javax.bluetooth.UUID;
import javax.microedition.io.Connection;
import javax.microedition.io.Connector;
import javax.microedition.io.StreamConnection;

/**
 * Simple static void main tester program to discover devices and services
 */
public class BluetoothDiscovery implements DiscoveryListener {

	// object used for waiting
	private static Object deviceLock = new Object();
	private static Object serviceLock = new Object();

	// vector containing the devices discovered
	private static Set<RemoteDevice> devices = new HashSet<RemoteDevice>();
	private static Set<String> services = new HashSet<String>();

	private static final UUID[] searchUuidSet = new UUID[] {
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
	static int[] attrIds = new int[] { 0x0100 // Service name

	};

	// main method of the application
	public static void main(String[] args) throws IOException {

		// create an instance of this class
		BluetoothDiscovery bluetoothDeviceDiscovery = new BluetoothDiscovery();

		// display local device address and name
		LocalDevice localDevice = LocalDevice.getLocalDevice();
		printLocalStackDebug(localDevice);

		// find devices
		DiscoveryAgent agent = localDevice.getDiscoveryAgent();

		System.out.println("Starting device inquiry...");
		agent.startInquiry(DiscoveryAgent.GIAC, bluetoothDeviceDiscovery);

		try {
			synchronized (deviceLock) {
				deviceLock.wait();
			}
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

		System.out.println("Device Inquiry Completed. ");

		if (devices.size() <= 0) {
			System.out.println("No Devices Found .");
		} else {
			System.out.println("\nBluetooth Devices: ");
			for (RemoteDevice remoteDevice : devices) {
				System.out.println("\t" + remoteDevice.getBluetoothAddress()
						+ " (" + remoteDevice.getFriendlyName(false) + ")");

				synchronized (serviceLock) {

					System.out.println("Search for services on "
							+ remoteDevice.getBluetoothAddress() + "/"
							+ remoteDevice.getFriendlyName(false));

					agent.searchServices(attrIds, searchUuidSet, remoteDevice,
							bluetoothDeviceDiscovery);

					try {
						serviceLock.wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
				if (services.size() > 0) {
					String url = services.iterator().next();
					System.out.println("Trying to connect to " + url);
					Connection connection = Connector.open(url);
					if (connection != null) {
						StreamConnection cxn = (StreamConnection) connection;
						BufferedReader reader = new BufferedReader(
								new InputStreamReader(cxn.openInputStream()));
						DataOutputStream dos = cxn.openDataOutputStream();
						System.out.println("Writing out a daisy command");
						dos.writeUTF("4;\n\r");
						dos.flush();

						for (int i = 0; i < 10; i++) {
							if (reader.ready()) {
								System.out.println("Daisy sed this: "
										+ reader.readLine());
							} else {
								System.out
										.println("Boo we have no bytes to read");
							}

							try {
								dos.writeBytes("6;\n\r");
								dos.flush();
								Thread.sleep(1000);
								dos.writeBytes("7;\n\r");
								dos.flush();
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}

					}
				}
			}
		}

	}// end main

	public static void printLocalStackDebug(LocalDevice device) {
		System.out.println("####### LOCAL DEVICE / STACK INFO #########");
		System.out.println("\tAddress/Name: " + device.getBluetoothAddress()
				+ "/" + device.getFriendlyName());
		DeviceClass dClass = device.getDeviceClass();
		if (dClass != null) {
			System.out.println("\tDeviceMajor/DeviceMinor: "
					+ dClass.getMajorDeviceClass() + "/"
					+ dClass.getMinorDeviceClass());
		}
		System.out.println("\tLocal Adapters: "
				+ LocalDevice.getProperty(LOCAL_DEVICE_DEVICES_LIST));
		System.out.println("\tBlueCove Version: "
				+ LocalDevice
						.getProperty(LOCAL_DEVICE_PROPERTY_BLUECOVE_VERSION));
		System.out.println("\tDoes stack support multiple adapters? "
				+ LocalDevice.getProperty(LOCAL_DEVICE_PROPERTY_DEVICE_ID));
		System.out.println("\tDoes stack support L2CAP: "
				+ LocalDevice.getProperty(LOCAL_DEVICE_PROPERTY_FEATURE_L2CAP));
		System.out
				.println("\tFeature Service Attributes: "
						+ LocalDevice
								.getProperty(LOCAL_DEVICE_PROPERTY_FEATURE_SERVICE_ATTRIBUTES));
		System.out
				.println("\tDevice Service Classes: "
						+ LocalDevice
								.getProperty(LOCAL_DEVICE_PROPERTY_FEATURE_SET_DEVICE_SERVICE_CLASSES));
		System.out.println("\tNumber of open connections: "
				+ LocalDevice
						.getProperty(LOCAL_DEVICE_PROPERTY_OPEN_CONNECTIONS));
		System.out.println("\tBluetooth Stack Implementation: "
				+ LocalDevice.getProperty(LOCAL_DEVICE_PROPERTY_STACK));
		System.out.println("###########################################");
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#deviceDiscovered(javax.bluetooth.
	 * RemoteDevice, javax.bluetooth.DeviceClass)
	 */
	public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
		System.out.println("\tDevice discovered: "
				+ btDevice.getBluetoothAddress());
		// add the device to the vector
		if (!devices.contains(btDevice)) {
			devices.add(btDevice);
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#inquiryCompleted(int)
	 */
	public void inquiryCompleted(int discType) {
		synchronized (deviceLock) {
			deviceLock.notify();
		}

		switch (discType) {
		case DiscoveryListener.INQUIRY_COMPLETED:
			System.out.println("\tresponse code: INQUIRY_COMPLETED");
			break;

		case DiscoveryListener.INQUIRY_TERMINATED:
			System.out.println("\tresponse code: INQUIRY_TERMINATED");
			break;

		case DiscoveryListener.INQUIRY_ERROR:
			System.out.println("\tresponse code: INQUIRY_ERROR");
			break;

		default:
			System.out.println("\tresponse code: Unknown Response Code =>"
					+ discType);
			break;
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
				System.err.println("\tService url was null for "
						+ servRecord[i].toString());
			}
			services.add(url);
			DataElement serviceName = servRecord[i].getAttributeValue(0x0100);
			if (serviceName != null) {
				System.out.println("\tService " + serviceName.getValue()
						+ " found " + url);
			} else {
				System.out.println("\tService found " + url);
			}
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see javax.bluetooth.DiscoveryListener#serviceSearchCompleted(int, int)
	 */
	public void serviceSearchCompleted(int transID, int respCode) {
		synchronized (serviceLock) {
			serviceLock.notifyAll();
		}
		System.out
				.println("Service search complete for transaction " + transID);
		switch (respCode) {
		case DiscoveryListener.SERVICE_SEARCH_COMPLETED:
			System.out.println("\tresponse code: SERVICE_SEARCH_COMPLETED");
			break;
		case DiscoveryListener.SERVICE_SEARCH_DEVICE_NOT_REACHABLE:
			System.out
					.println("\tresponse code: SERVICE_SEARCH_DEVICE_NOT_REACHABLE");
			break;
		case DiscoveryListener.SERVICE_SEARCH_ERROR:
			System.out.println("\tresponse code: SERVICE_SEARCH_ERROR");
			break;
		case DiscoveryListener.SERVICE_SEARCH_NO_RECORDS:
			System.out.println("\tresponse code: SERVICE_SEARCH_NO_RECORDS");
			break;
		case DiscoveryListener.SERVICE_SEARCH_TERMINATED:
			System.out.println("\tresponse code: SERVICE_SEARCH_TERMINATED");
			break;
		default:
			System.out.println("\tUnknown Response Code: " + respCode);
		}
	}

}// end class