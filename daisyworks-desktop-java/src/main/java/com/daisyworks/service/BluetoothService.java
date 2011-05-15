/**
 * 
 */
package com.daisyworks.service;

import java.util.HashSet;
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

/**
 * Does Bluetooth stuff 
 */
@Service
@RemotingDestination(channels = {"my-amf"})
public class BluetoothService implements DiscoveryListener {

	private static final Logger LOGGER = Logger.getLogger(BluetoothService.class);
	
	// discovery is not re-entrant
	private static Object lock = new Object();
	
	private Set<RemoteDevice> devices = new HashSet<RemoteDevice>();
		
	public BluetoothService() {
		LOGGER.debug("Bluetooth Service initialized");
	}
	
	/**
	 * Poke around the air-waves 
	 * @return
	 */
	@RemotingInclude
	public String discover() {
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
				return e.getMessage();
			}
			LOGGER.info("Device Inquiry Complete");
			
			if(devices.size() == 0) {
				return "No Devices Found -- sux for you";
			}
			
			StringBuilder sb = new StringBuilder();
			for(RemoteDevice d : devices) {
				sb.append("Device:")
				  .append("\taddress="+d.getBluetoothAddress())
				  .append("\tfriendly-name="+d.getFriendlyName(true))
				  .append("\tauthenticated="+d.isAuthenticated())
				  .append("\tencrypted="+d.isEncrypted())
				  .append("\ttrusted="+d.isTrustedDevice());
			}
			return sb.toString();
			
		} catch (Exception e) {
			// FIXME
			LOGGER.error(e);
			return e.getMessage();
		}
	}

	@Override
	public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
		devices.add(btDevice);
		// TODO add DeviceClass info too
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
