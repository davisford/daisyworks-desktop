/**
 * 
 */
package com.daisyworks.service;

import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.bluetooth.BluetoothStateException;
import javax.bluetooth.DataElement;
import javax.bluetooth.DeviceClass;
import javax.bluetooth.DiscoveryAgent;
import javax.bluetooth.DiscoveryListener;
import javax.bluetooth.LocalDevice;
import javax.bluetooth.RemoteDevice;
import javax.bluetooth.ServiceRecord;
import javax.bluetooth.UUID;

import org.apache.log4j.Logger;
import org.springframework.flex.remoting.RemotingDestination;
import org.springframework.flex.remoting.RemotingInclude;
import org.springframework.stereotype.Service;

import com.daisyworks.model.Device;

/**
 * Does Bluetooth stuff 
 */
@Service
@RemotingDestination(channels = {"my-amf"})
public class BluetoothService implements DiscoveryListener {

	private static final Logger LOGGER = Logger.getLogger(BluetoothService.class);
	
    //object used for waiting
    private static Object deviceLock=new Object();
    private static Object serviceLock=new Object();
	
    // map of discovered devices; key = device address
	private Map<String, RemoteDevice> deviceMap = new HashMap<String, RemoteDevice>();
	// map of service urls; key = device address
	private Map<String, String> serviceMap = new HashMap<String, String>();
	
	private DiscoveryAgent agent;
	
	private ServiceDiscoveryThread serviceDiscoveryThread;
	
	/**
	 * Constructor
	 */
	public BluetoothService() {
		LOGGER.debug("Bluetooth Service initialized");
		serviceDiscoveryThread = new ServiceDiscoveryThread(this);
	}
	
	/**
	 * Get the Local Device information
	 * @return
	 */
	@RemotingInclude
	public Device getLocalDevice() {
		try {
			final LocalDevice localDevice = LocalDevice.getLocalDevice();
			final Device device = new Device(localDevice.getFriendlyName(), localDevice.getBluetoothAddress());
			return device;
		} catch(Exception e) {
			LOGGER.error(e);
			throw new RuntimeException(e);
		}
	}
	
	/**
	 * Poke around the air-waves 
	 * @return
	 */
	@RemotingInclude
	public Set<Device> discover() {
		// clear the map
		deviceMap = new HashMap<String, RemoteDevice>();
		try {
			final LocalDevice localDevice = LocalDevice.getLocalDevice();
			LOGGER.info("Local Bluetooth Name/Addres: "+localDevice.getFriendlyName()+"/"+localDevice.getBluetoothAddress());
			
			agent = localDevice.getDiscoveryAgent();
			
			LOGGER.info("Starting Device Inquiry");
			agent.startInquiry(DiscoveryAgent.GIAC, this);
			try {
				synchronized(deviceLock) {deviceLock.wait();}
			} catch(InterruptedException e) {
				// FIXME
				LOGGER.error(e);
				throw new RuntimeException(e);
			}
			LOGGER.info("Device Inquiry Complete");
			
			if(deviceMap.size() == 0) {
				LOGGER.warn("No Bluetooth devices were found");
				return new HashSet<Device>(0);
			} else {
				LOGGER.info("Discovered "+deviceMap.size()+" devices");
			}
			// start service discovery
			serviceDiscoveryThread.run();
			
			return toDeviceSet(deviceMap); 
		} catch (Exception e) {
			// FIXME
			LOGGER.error(e);
			throw new RuntimeException(e);
		}
	}
	
	/**
	 * Converts the map into a set of {@link Device} objects that can be serialized
	 * easily through AMF.
	 * @param map
	 * @return
	 * @throws IOException
	 */
	private Set<Device> toDeviceSet(Map<String, RemoteDevice> map) throws IOException {
		Set<Device> set = new HashSet<Device>();
		for(String key : map.keySet()) {
			RemoteDevice rd = map.get(key);
			Device device = new Device(rd.getFriendlyName(false), rd.getBluetoothAddress());
			device.setAuthenticated(rd.isAuthenticated());
			device.setEncrypted(rd.isEncrypted());
			device.setTrusted(rd.isTrustedDevice());
			set.add(device);
		}
		return set;
	}

	/*
	 * (non-Javadoc)
	 * @see javax.bluetooth.DiscoveryListener#deviceDiscovered(javax.bluetooth.RemoteDevice, javax.bluetooth.DeviceClass)
	 */
	@Override
	public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
		LOGGER.info("Device discovered: "+btDevice.getBluetoothAddress());
		deviceMap.put(btDevice.getBluetoothAddress(), btDevice);
	}

    /*
     * (non-Javadoc)
     * @see javax.bluetooth.DiscoveryListener#inquiryCompleted(int)
     */
	@Override
    public void inquiryCompleted(int discType) {
        synchronized(deviceLock){
            deviceLock.notify();
        }
        switch (discType) {
            case DiscoveryListener.INQUIRY_COMPLETED :
                LOGGER.info("\tresponse code: INQUIRY_COMPLETED");
                break;
               
            case DiscoveryListener.INQUIRY_TERMINATED :
                LOGGER.warn("\tresponse code: INQUIRY_TERMINATED");
                break;
               
            case DiscoveryListener.INQUIRY_ERROR :
                LOGGER.error("\tresponse code: INQUIRY_ERROR");
                break;
 
            default :
                LOGGER.error("\tresponse code: Unknown Response Code =>"+discType);
                break;
        }
    }
	
    /*
     * (non-Javadoc)
     * @see javax.bluetooth.DiscoveryListener#servicesDiscovered(int, javax.bluetooth.ServiceRecord[])
     */
    public void servicesDiscovered(int transID, ServiceRecord[] servRecord) {
    	for(int i=0; i<servRecord.length; i++) {
    		String url = servRecord[i].getConnectionURL(ServiceRecord.NOAUTHENTICATE_NOENCRYPT, false);
    		if(url == null) {
    			LOGGER.error("\tService url was null for "+servRecord[i].toString());
    		}
    		serviceMap.put(servRecord[i].getHostDevice().getBluetoothAddress(), url);
    		DataElement serviceName = servRecord[i].getAttributeValue(0x0100);
    		if(serviceName != null) {
    			LOGGER.info("\tService "+serviceName.getValue() + " found " + url);
    		} else {
    			LOGGER.info("\tService found " + url);
    		}
    	}
    }

    /*
     * (non-Javadoc)
     * @see javax.bluetooth.DiscoveryListener#serviceSearchCompleted(int, int)
     */
    public void serviceSearchCompleted(int transID, int respCode) {
    	synchronized(serviceLock) {
    		serviceLock.notifyAll();
    	}
    	LOGGER.info("Service search complete for transaction "+transID);
    	switch(respCode) {
    	case DiscoveryListener.SERVICE_SEARCH_COMPLETED :
    		LOGGER.info("\tresponse code: SERVICE_SEARCH_COMPLETED"); break;
    	case DiscoveryListener.SERVICE_SEARCH_DEVICE_NOT_REACHABLE:
    		LOGGER.error("\tresponse code: SERVICE_SEARCH_DEVICE_NOT_REACHABLE"); break;
    	case DiscoveryListener.SERVICE_SEARCH_ERROR:
    		LOGGER.error("\tresponse code: SERVICE_SEARCH_ERROR"); break;
    	case DiscoveryListener.SERVICE_SEARCH_NO_RECORDS:
    		LOGGER.error("\tresponse code: SERVICE_SEARCH_NO_RECORDS"); break;
    	case DiscoveryListener.SERVICE_SEARCH_TERMINATED:
    		LOGGER.error("\tresponse code: SERVICE_SEARCH_TERMINATED"); break;
    	default:
    		LOGGER.error("\tUnknown Response Code: "+respCode);
    	}
    }
    
    private static final UUID[] uuidSet = new UUID[] { 
//    	new UUID(0x0001),	// SDP
    	new UUID(0x0003)	// RFCOMM
//    	new UUID(0x0008),	// OBEX
//    	new UUID(0x000C),	// HTTP
//    	new UUID(0x0100)	// L2CAP
//    	new UUID(0x000F),	// BNEP
//    	new UUID(0x1101),	// Serial Port
//    	new UUID(0x1000),	// ServiceDiscoveryServerServiceClassID
//    	new UUID(0x1001),	// BrowseGroupDescriptorServiceClassID
//    	new UUID(0x1002),	// PublicBrowseGroup
//    	new UUID(0x1105),	// OBEX Oject Push
//    	new UUID(0x1106),	// OBEX File Transfer
//    	new UUID(0x1115),	// PAN
//    	new UUID(0x1116),	// Network Access Point
//    	new UUID(0x1117),	// Group Network
    };
    
    private static int[] attrSet =  new int[] { 
    	0x0100 				// Service name	
    };
    
    /**
     * Background thread for discovering services on remote devices
     */
    private class ServiceDiscoveryThread implements Runnable {
    	
    	private DiscoveryListener listener;
    	
        ServiceDiscoveryThread(DiscoveryListener listener) {
    		this.listener = listener;
    	}

		@Override
		public void run() {
			LOGGER.info("Searching for services on "+deviceMap.size()+" devices");
			for(RemoteDevice remoteDevice: deviceMap.values()) {
				synchronized(serviceLock) {
					LOGGER.info("Searching for services on "+remoteDevice.getBluetoothAddress());
					try {
						agent.searchServices(attrSet, uuidSet, remoteDevice, listener);
					} catch (BluetoothStateException e) {
						LOGGER.error(e.getMessage());	// FIXME
					} finally {
						try {
							serviceLock.wait();
						} catch (InterruptedException e) {
							LOGGER.error(e.getMessage()); // FIXME
						}
					}
				}
			}
		}
    	
    }
}
