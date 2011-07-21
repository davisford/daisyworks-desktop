/**
 * 
 */
package com.daisyworks.service;

import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

import org.apache.log4j.Logger;
import org.springframework.flex.remoting.RemotingDestination;
import org.springframework.flex.remoting.RemotingInclude;
import org.springframework.stereotype.Service;

@Service
@RemotingDestination(channels = { "my-amf" })
public class WatchdogService {
	
	private Timer timer = new Timer();
	private Date currentTimestamp = new Date();
	
	private static final Long PERIOD = 20 * 1000L;
	private static final Logger LOGGER = Logger.getLogger(WatchdogService.class);
	
	public WatchdogService() {
		LOGGER.debug("Watchdog initialized");
		timer.schedule(new TimerTask(){
			@Override
			public void run() {			
				final Date now = new Date();
				final Long diff = now.getTime() - currentTimestamp.getTime();
				//LOGGER.debug("running watchdog timer, last ping was at:" + currentTimestamp + " " + diff/1000 + " seconds ago" );
				if(diff >= PERIOD) {
					LOGGER.error("Last ping from UI was "+currentTimestamp+" haven't received ping in "+diff/1000+"s so I'm quitting");
					//System.exit(1);
				}
			}}, 0, PERIOD);
	}
	
	@RemotingInclude
	public String ping(Long timestamp) {
		currentTimestamp = new Date(timestamp);
		return "pong";
	}
	
	@RemotingInclude
	public void exit() {
		System.exit(1);
	}

}
