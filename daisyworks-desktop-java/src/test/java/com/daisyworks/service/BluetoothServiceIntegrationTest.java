/**
 * 
 */
package com.daisyworks.service;

import static org.junit.Assert.fail;

import java.util.Set;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import com.daisyworks.model.Device;

/**
 * Integration test for {@link BluetoothService}
 */
public class BluetoothServiceIntegrationTest {
	
	private BluetoothService service;

	/**
	 * @throws java.lang.Exception
	 */
	@Before
	public void setUp() throws Exception {
		service = new BluetoothService();
	}

	/**
	 * @throws java.lang.Exception
	 */
	@After
	public void tearDown() throws Exception {
	}

	/**
	 * Test method for {@link com.daisyworks.service.BluetoothService#getLocalDevice()}.
	 */
	@Test
	public void testGetLocalDevice() {
		fail("Not yet implemented");
	}

	/**
	 * Test method for {@link com.daisyworks.service.BluetoothService#findDevices()}.
	 */
	@Test
	public void testFindDevices() {
		try {
			Set<Device> devices = service.findDevices();
			if(devices.size() > 0) {
				service.findServices(devices.iterator().next().getAddress());
			}
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * Test method for {@link com.daisyworks.service.BluetoothService#findServices(java.lang.String)}.
	 */
	@Test
	public void testFindServices() {
		fail("Not yet implemented");
	}

	/**
	 * Test method for {@link com.daisyworks.service.BluetoothService#connectRFComm(java.lang.String)}.
	 */
	@Test
	public void testConnectRFComm() {
		fail("Not yet implemented");
	}

	/**
	 * Test method for {@link com.daisyworks.service.BluetoothService#disconnectRFComm(java.lang.String)}.
	 */
	@Test
	public void testDisconnectRFComm() {
		fail("Not yet implemented");
	}

	/**
	 * Test method for {@link com.daisyworks.service.BluetoothService#send(java.lang.String)}.
	 */
	@Test
	public void testSend() {
		fail("Not yet implemented");
	}

}
