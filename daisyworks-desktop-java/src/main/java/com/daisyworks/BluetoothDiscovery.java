package com.daisyworks;

import java.io.IOException;
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
 
 
/**
* Class that discovers all bluetooth devices in the neighbourhood
* and displays their name and bluetooth address.
*/
public class BluetoothDiscovery implements DiscoveryListener{
   
   
    //object used for waiting
    private static Object deviceLock=new Object();
    private static Object serviceLock=new Object();
   
    //vector containing the devices discovered
    private static Set<RemoteDevice> devices=new HashSet<RemoteDevice>();
    private static Set<String> services = new HashSet<String>();
    
    private static final UUID RFCOMM = new UUID(0x0003);
    private static final UUID SERIAL_PORT = new UUID(0x1101);
   
    private static final UUID[] searchUuidSet = new UUID[] { 
    	new UUID(0x0001),	// SDP
    	new UUID(0x0003),	// RFCOMM
    	new UUID(0x0008),	// OBEX
    	new UUID(0x000C),	// HTTP
    	new UUID(0x0100),	// L2CAP
    	new UUID(0x000F),	// BNEP
    	new UUID(0x1101),	// Serial Port
    	new UUID(0x1000),	// ServiceDiscoveryServerServiceClassID
    	new UUID(0x1001),	// BrowseGroupDescriptorServiceClassID
    	new UUID(0x1002),	// PublicBrowseGroup
    	new UUID(0x1105),	// OBEX Oject Push
    	new UUID(0x1106),	// OBEX File Transfer
    	new UUID(0x1115),	// PAN
    	new UUID(0x1116),	// Network Access Point
    	new UUID(0x1117),	// Group Network
    };
    static int[] attrIds =  new int[] { 0x0100 // Service name
    		
    };
   
    //main method of the application
    public static void main(String[] args) throws IOException {
       
        //create an instance of this class
        BluetoothDiscovery bluetoothDeviceDiscovery=new BluetoothDiscovery();
       
        //display local device address and name
        LocalDevice localDevice = LocalDevice.getLocalDevice();
        System.out.println("Address: "+localDevice.getBluetoothAddress());
        System.out.println("Name: "+localDevice.getFriendlyName());
       
        //find devices
        DiscoveryAgent agent = localDevice.getDiscoveryAgent();
      
        System.out.println("Starting device inquiry...");
        agent.startInquiry(DiscoveryAgent.GIAC, bluetoothDeviceDiscovery);
       
        try {
            synchronized(deviceLock){
                deviceLock.wait();
            }
        }
        catch (InterruptedException e) {
            e.printStackTrace();
        }
       
       
        System.out.println("Device Inquiry Completed. ");
       
        //print all devices in vecDevices
        int deviceCount=devices.size();
       
        if(deviceCount <= 0){
            System.out.println("No Devices Found .");
        }
        else{
            //print bluetooth device addresses and names in the format [ No. address (name) ]
            System.out.println("Bluetooth Devices: ");
            for(RemoteDevice remoteDevice : devices) {
            	System.out.println(remoteDevice.getBluetoothAddress()+" ("+remoteDevice.getFriendlyName(false)+")");
            	synchronized(serviceLock) {
            		System.out.println("search services on " + remoteDevice.getBluetoothAddress() +
            				" " + remoteDevice.getFriendlyName(false));
            		agent.searchServices(attrIds, searchUuidSet, remoteDevice, bluetoothDeviceDiscovery);
            		try {
						serviceLock.wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
            	}
            }
        }
       
       
    }//end main
 
    //methods of DiscoveryListener
   
    /**
     * This call back method will be called for each discovered bluetooth devices.
     */
    public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
        System.out.println("Device discovered: "+btDevice.getBluetoothAddress());
        //add the device to the vector
        if(!devices.contains(btDevice)){
            devices.add(btDevice);
        }
    }
 
    public void servicesDiscovered(int transID, ServiceRecord[] servRecord) {
    	System.out.println("SERVICE DISCOVERED!!!!!");
    	for(int i=0; i<servRecord.length; i++) {
    		String url = servRecord[i].getConnectionURL(ServiceRecord.NOAUTHENTICATE_NOENCRYPT, false);
    		if(url == null) {
    			System.err.println("url was null for "+servRecord[i].toString());
    		}
    		services.add(url);
    		DataElement serviceName = servRecord[i].getAttributeValue(0x0100);
    		if(serviceName != null) {
    			System.out.println("service "+serviceName.getValue() + " found " + url);
    		} else {
    			System.out.println("service found " + url);
    		}
    	}
    }
 
    //no need to implement this method since services are not being discovered
    public void serviceSearchCompleted(int transID, int respCode) {
    	synchronized(serviceLock) {
    		serviceLock.notifyAll();
    	}
    	System.out.println("service search complete for transaction "+transID);
    	switch(respCode) {
    	case DiscoveryListener.SERVICE_SEARCH_COMPLETED :
    		System.out.println("\tSERVICE_SEARCH_COMPLETED"); break;
    	case DiscoveryListener.SERVICE_SEARCH_DEVICE_NOT_REACHABLE:
    		System.out.println("\tSERVICE_SEARCH_DEVICE_NOT_REACHABLE"); break;
    	case DiscoveryListener.SERVICE_SEARCH_ERROR:
    		System.out.println("\tSERVICE_SEARCH_ERROR"); break;
    	case DiscoveryListener.SERVICE_SEARCH_NO_RECORDS:
    		System.out.println("\tSERVICE_SEARCH_NO_RECORDS"); break;
    	case DiscoveryListener.SERVICE_SEARCH_TERMINATED:
    		System.out.println("\tSERVICE_SEARCH_TERMINATED"); break;
    	default:
    		System.out.println("\tUnknown Response Code: "+respCode);
    	}
    }
 
   
    /**
     * This callback method will be called when the device discovery is
     * completed.
     */
    public void inquiryCompleted(int discType) {
        synchronized(deviceLock){
            deviceLock.notify();
        }
       
        switch (discType) {
            case DiscoveryListener.INQUIRY_COMPLETED :
                System.out.println("INQUIRY_COMPLETED");
                break;
               
            case DiscoveryListener.INQUIRY_TERMINATED :
                System.out.println("INQUIRY_TERMINATED");
                break;
               
            case DiscoveryListener.INQUIRY_ERROR :
                System.out.println("INQUIRY_ERROR");
                break;
 
            default :
                System.out.println("Unknown Response Code");
                break;
        }
    }//end method
}//end class
