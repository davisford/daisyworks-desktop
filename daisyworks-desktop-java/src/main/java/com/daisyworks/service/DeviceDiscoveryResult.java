package com.daisyworks.service;

import javax.bluetooth.DiscoveryListener;

public enum DeviceDiscoveryResult {
	
	INQUIRY_COMPLETED(DiscoveryListener.INQUIRY_COMPLETED, "Device discovery completed successfully"),
	INQUIRY_TERMINATED(DiscoveryListener.INQUIRY_TERMINATED, "Device discovery was terminated pre-maturely by the application"),
	INQUIRY_ERROR(DiscoveryListener.INQUIRY_ERROR, "Device discovery failed to complete normally"),
	UNKNOWN(-1, "Device discovery failed with an unknown termination code");
	
	private final int code;
	private final String message;
	
	DeviceDiscoveryResult(final int code, final String message) {
		this.code = code;
		this.message = message;
	}
	
	public int getCode() { return code; }
	public String getMessage() { return message; }

	public String asString() {
		return this + " " + message;
	}
}
