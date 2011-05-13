/**
 * 
 */
package com.daisyworks;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URL;

import org.apache.log4j.Logger;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.webapp.WebAppContext;

/**
 * Main entry point for DaisyDesktop WebApp
 * <p>
 * Starts an embedded Jetty instance that handles all AMF service requests
 */
public class MainRunner {
	
	private static final Logger LOGGER = Logger.getLogger(MainRunner.class);
	
	private static final int DEFAULT_PORT = 8080;

	/**
	 * @param args specify arg[0] as port number or else it will try 8080
	 * @throws Exception
	 */
	public static void main(String[] args) throws Exception {
		int port = DEFAULT_PORT;
		
		try {
			try {
				String portStr = System.getProperty("daisyworks.port");
				LOGGER.info("daisyworks.port is set to "+portStr);
				if(portStr != null && !portStr.isEmpty()) {
					port = Integer.parseInt(portStr);
				}
			} catch(Exception e) {
				LOGGER.error("Using default port number b/c port string is not a number: " +DEFAULT_PORT);
				port = DEFAULT_PORT;
			}
			
			Server server = new Server(port);
			
			final URL warUrl = MainRunner.class.getClassLoader().getResource("webapp");
			final String warUrlString = warUrl.toExternalForm();
			LOGGER.info("Starting Jetty on port "+port+": "+warUrlString);
			
			WebAppContext wac = new WebAppContext();
			wac.setWar(warUrlString);
			wac.setContextPath("/daisyworks");
			wac.setResourceBase(warUrlString);
			wac.setDescriptor("/WEB-INF/web.xml");
			wac.setParentLoaderPriority(true);
			
			server.setHandler(wac);
			server.start();
			server.join();
			
		} catch(Exception e) {
			LOGGER.error("failed to launch jetty \n "+getStackTraceAsString(e));
			System.exit(1);
		}
		

	}
	
	public static String getStackTraceAsString(Throwable t) {
		final Writer result = new StringWriter();
		final PrintWriter printWriter = new PrintWriter(result);
		t.printStackTrace(printWriter);
		return result.toString();
	}

}
