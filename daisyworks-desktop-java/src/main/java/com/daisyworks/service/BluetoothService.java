/**
 * 
 */
package com.daisyworks.service;

import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.bluetooth.DeviceClass;
import javax.bluetooth.DiscoveryAgent;
import javax.bluetooth.DiscoveryListener;
import javax.bluetooth.LocalDevice;
import javax.bluetooth.RemoteDevice;
import javax.bluetooth.ServiceRecord;

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
	
	// discovery is not re-entrant
	private static Object lock = new Object();
	
	private Map<Device, RemoteDevice> map = new HashMap<Device, RemoteDevice>();
		
	public BluetoothService() {
		LOGGER.debug("Bluetooth Service initialized");
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
		map = new HashMap<Device, RemoteDevice>();
		try {
			final LocalDevice localDevice = LocalDevice.getLocalDevice();
			LOGGER.info("Local Bluetooth Name/Addres: "+localDevice.getFriendlyName()+"/"+localDevice.getBluetoothAddress());
			
			final DiscoveryAgent agent = localDevice.getDiscoveryAgent();
			
			LOGGER.info("Starting Device Inquiry");
			agent.startInquiry(DiscoveryAgent.GIAC, this);
			try {
				synchronized(lock) {lock.wait();}
			} catch(InterruptedException e) {
				// FIXME
				LOGGER.error(e);
				throw new RuntimeException(e);
			}
			LOGGER.info("Device Inquiry Complete");
			
			if(map.size() == 0) {
				LOGGER.warn("No Bluetooth devices were found");
				return new HashSet<Device>(0);
			}
			
			return map.keySet();
			
		} catch (Exception e) {
			// FIXME
			LOGGER.error(e);
			throw new RuntimeException(e);
		}
	}

	@Override
	public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
		try {
			Device device = new Device(btDevice.getFriendlyName(true), btDevice.getBluetoothAddress());
			device.setAuthenticated(btDevice.isAuthenticated());
			device.setEncrypted(btDevice.isEncrypted());
			device.setTrusted(btDevice.isTrustedDevice());
			map.put(device, btDevice);
		} catch (IOException e) {
			// FIXME
			LOGGER.error(e);
		}
	}

	@Override
	public void servicesDiscovered(int transID, ServiceRecord[] servRecord) {
		LOGGER.info("service discovered (TODO print details)");
	}

	@Override
	public void serviceSearchCompleted(int transID, int respCode) {
		LOGGER.info("service search complete (TODO print details)");
	}

	@Override
	public void inquiryCompleted(int discType) {
		synchronized(lock) {
			lock.notify();
		}
		
		switch(discType) {
		case DiscoveryListener.INQUIRY_COMPLETED:
			LOGGER.info("INQUIRY_COMPLETED"); break;
		case DiscoveryListener.INQUIRY_TERMINATED:
			LOGGER.error("INQUIRY_TERMINATED"); break;
		case DiscoveryListener.INQUIRY_ERROR:
			LOGGER.error("INQUIRY_ERROR"); break;
		default:
			LOGGER.error("Unknown Response Code: "+discType);
			break;
		}
	}
}
