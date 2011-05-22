/**
 * 
 */
package com.daisyworks.model;

/**
 * Represents a DTO for {@link javax.bluetooth.RemoteDevice} that
 * we can serialize over AMF to Flex.
 */
public class Device {
	
	private String name;
	private String address;
	private boolean authenticated;
	private boolean encrypted;
	private boolean trusted;
	
	public Device() {}
	
	public Device(String name, String address) {
		this.name = name; this.address = address;
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getAddress() {
		return address;
	}
	public void setAddress(String address) {
		this.address = address;
	}
	public boolean isAuthenticated() {
		return authenticated;
	}
	public void setAuthenticated(boolean authenticated) {
		this.authenticated = authenticated;
	}
	public boolean isEncrypted() {
		return encrypted;
	}
	public void setEncrypted(boolean encrypted) {
		this.encrypted = encrypted;
	}
	public boolean isTrusted() {
		return trusted;
	}
	public void setTrusted(boolean trusted) {
		this.trusted = trusted;
	}
	
	@Override
	public String toString() {
		return name + "/" + address;
	}

}
