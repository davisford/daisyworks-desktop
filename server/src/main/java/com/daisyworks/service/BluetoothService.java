/**
 * 
 */
package com.daisyworks.service;

import java.util.HashSet;
import java.util.Set;

import org.apache.log4j.Logger;
import org.springframework.flex.remoting.RemotingDestination;
import org.springframework.flex.remoting.RemotingInclude;
import org.springframework.stereotype.Service;

/**
 * @author davisford
 *
 */
@Service
@RemotingDestination(channels = {"my-amf"})
public class BluetoothService {

	private static final Logger LOGGER = Logger.getLogger(BluetoothService.class);
	
	public BluetoothService() {
		LOGGER.debug("Bluetooth Service initialized");
	}
	
	@RemotingInclude
	public Set<String> discover() {
		Set<String> devices = new HashSet<String>();
		devices.add("new fake device");
		devices.add("other new fake device");
		return devices;
	}
}
