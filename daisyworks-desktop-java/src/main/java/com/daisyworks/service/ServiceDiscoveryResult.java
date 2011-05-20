package com.daisyworks.service;

import javax.bluetooth.DiscoveryListener;

public enum ServiceDiscoveryResult {
	SERVICE_SEARCH_COMPLETED(DiscoveryListener.SERVICE_SEARCH_COMPLETED, "Service search completed normally"),
	SERVICE_SEARCH_DEVICE_NOT_REACHABLE(DiscoveryListener.SERVICE_SEARCH_DEVICE_NOT_REACHABLE, "Service search could not be completed because communication with the Remote Device was lost"),
	SERVICE_SEARCH_ERROR(DiscoveryListener.SERVICE_SEARCH_ERROR, "Service search terminated with an error"),
	SERVICE_SEARCH_NO_RECORDS(DiscoveryListener.SERVICE_SEARCH_NO_RECORDS, "Service search completed, but not services were discovered on the device"),
	SERVICE_SEARCH_TERMINATED(DiscoveryListener.SERVICE_SEARCH_TERMINATED, "Service search was terminated pre-maturely by the application"),
	UNKNOWN(-1, "Service search terminated with an unknown status code");
	
	private final int code;
	private final String message;
	
	ServiceDiscoveryResult(final int code, final String message) {
		this.code = code;
		this.message = message;
	}
	
	public int getCode() { return code; }
	public String getMessage() { return message; }
	
	public String asString() {
		return this + " " + message;
	}

}
