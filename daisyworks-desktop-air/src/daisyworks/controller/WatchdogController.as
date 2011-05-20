package daisyworks.controller {
	import com.adobe.utils.StringUtil;
	
	import daisyworks.event.DaisyWorksEvent;
	import daisyworks.log.Logger;
	import daisyworks.model.Preferences;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	
	import mx.logging.ILogger;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;

	/**
	 * Watchdog is meant to continuously heartbeat the Air <=> Java connectivity and take action
	 * if something goes wrong.
	 * TODO: there's no recovery logic here yet.  It just ping/pongs.
	 */
	public class WatchdogController implements IResponder {
		
		private static const LOG:ILogger = Logger.getLogger(WatchdogController);

		// toggled false before we send ping, and toggled true when we receive a response
		private var gotPong:Boolean=true;

		// how often we ping Java with a watchdog message
		private static const INTERVAL:Number=10000;

		// how many failures before we try to restart JVM
		private static const FAIL_COUNT:Number=2;

		// count how many times we failed to contact the JVM
		private var pingFailCount:Number=0;
		
		private var remoteObj:RemoteObject;
		
		private var jvm:NativeProcess = new NativeProcess();
		
		private static const JARFILE:String = "daisyworks-server.jar";
		
		private var debug:Boolean = false;
		
		private static var port:Number;
		
		[Inject]
		public var prefs:Preferences;

		[Dispatcher]
		/**
		 * Injected via Swiz
		 * @default
		 */
		public var dispatcher:IEventDispatcher;
		
		private var timer:Timer;
		private var javaFailed:Boolean = false;

		/**
		 * Constructor
		 */
		public function WatchdogController() {
			
		}
		
		[PostConstruct]
		public function init():void {
			remoteObj = new RemoteObject();
			remoteObj.destination = "watchdogService";
			remoteObj.addEventListener(ResultEvent.RESULT, result);
			remoteObj.addEventListener(FaultEvent.FAULT, fault);
		}

		[EventHandler(event="startWatchdog")]
		/**
		 *
		 */
		public function start():void {
			port = prefs.getValue("port", "8080");
			remoteObj.endpoint = "http://localhost:"+port+"/daisyworks/messagebroker/amf";
			
			// start the JVM
			startJava();

			timer=new Timer(INTERVAL, 0);
			timer.addEventListener("timer", timerHandler);
			timer.start();
		}
		
		[EventHandler(event="shutdownJVM")]
		public function stop():void {
			LOG.info("telling JVM to shut it.");
			jvm.exit(true);
			timer.stop();
		}

		/**
		 * Every <tt>INTERVAL</tt> this code runs.
		 * @param evt
		 */
		private function timerHandler(evt:TimerEvent):void {
			if(javaFailed) {
				timer.stop();
			}
			
			if (!gotPong) {
				pingFailCount++;
			}

			if (pingFailCount >= FAIL_COUNT) {
				pingFailCount=0;
				LOG.error('WATCHDOG: Captain, we lost comms with JVM for the last '+FAIL_COUNT * (INTERVAL / 1000)+' seconds.');
				dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.HTTP_404, PORT_CONFLICT.replace("{port}", port)));
				javaFailed = true;
				stop();
			} else {
				remoteObj.ping(new Date().time);
			}
		}

		/**
		 * Result handler for receiving a message back from Java
		 * @param data
		 */
		public function result(data:Object):void {
			gotPong=true;
		}

		/**
		 * Fault handler when something goes wrong
		 * @param data
		 */
		public function fault(data:Object):void {
			gotPong=false;
			LOG.error("can't talk to watchdog service "+data.message);
		}
		
		private static const TOTAL_JVM_FAILURE:String = 
			"DaisyWorks is not able to communicate with Java.  Please ensure that Java is properly installed. " +
			"Refer to the support documentation at http://daisyworks.com for assistance, and instructions on how to "+
			"validate that Java is properly installed.  You may also try re-installing DaisyWorks as a solution.  If "+
			"the problem persists, please contact support@daisyworks.com.";
		
		private static var PORT_CONFLICT:String = 
			"DaisyWorks is not able to communicate with Java on the specified port {port}.  Please go to Settings and " +
			"re-configure the port.";

		/**
		 * Start the embedded jar file
		 */
		private function startJava():void {
			try {
				// now we have to find the JRE executable
				var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				// the arguments we pass to java
				var args:Vector.<String> = new Vector.<String>();
				resolveJVM(startupInfo, args);
			} catch(e:Error) {
				dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.JVM_START_FAILURE, TOTAL_JVM_FAILURE));
				javaFailed = true;
			}
		}
		
		public function _startJava(startupInfo:NativeProcessStartupInfo, args:Vector.<String>):void {
			try {
				// this is the jar file
				var file:File=File.applicationDirectory;
				file=file.resolvePath(JARFILE);
				
				if(debug) {
					args.push('-Xdebug');
					args.push('-Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=y');
				}
				
				// tell log4j where to write to
				var logPath:String = File.applicationStorageDirectory.nativePath;
				args.push("-Ddaisyworks.log="+logPath);
				
				// tell the JVM which port to listen on
				args.push("-Ddaisyworks.port="+port);
				
				args.push('-jar');
				// the jar file to execute
				args.push(file.nativePath);
				
				startupInfo.arguments = args;
				
				jvm.addEventListener(NativeProcessExitEvent.EXIT, onJvmExit);
				jvm.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onStdioError);
				jvm.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, onStdioError);
				jvm.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onStdioError);
				
				LOG.debug('executing '+startupInfo.arguments.toString());
				jvm.start(startupInfo);
				dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.JVM_STARTED));
			} catch (e:Error) {
				dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.JVM_START_FAILURE, TOTAL_JVM_FAILURE));
				javaFailed = true;
			}	
			
		}
		
		private static var WINDOWS:String = "Windows";
		private static var MAC:String = "Macintosh";
		private static var LINUX:String = "Linux";
		
		/**
		 * Figure out which operating system we are running on
		 */
		private function resolveJVM(startupInfo:NativeProcessStartupInfo, args:Vector.<String>):void {
			var whoami:String = Capabilities.manufacturer.replace("Adobe ","");
			switch(whoami) {
				case WINDOWS:
					resolveWindowsJVM(startupInfo, args);
					break;
				case MAC:
					resolveMacJVM(startupInfo, args);
					break;
				case LINUX:
					resolveLinuxJVM(startupInfo, args);
					break;
				default:
					LOG.error("This application is running on an unsupported operating system: "+whoami);
					throw new Error("This application is running on an unsupported operating system: "+whoami);
			}
		}
		
		/**
		 * We include the JRE as part of the installer for Windows
		 */
		private function resolveWindowsJVM(startupInfo:NativeProcessStartupInfo, args:Vector.<String>):void {
			var file:File=File.applicationDirectory;
			file=file.resolvePath("jre/bin/java.exe");
			startupInfo.executable = file;
			_startJava(startupInfo, args);
		}
		
		/**
		 * There is no re-distributable Mac OS JRE.  We have to count on it being there.
		 * We also have to force it to 32-bit mode for the Bluetooth libraries.
		 */
		private function resolveMacJVM(startupInfo:NativeProcessStartupInfo, args:Vector.<String>):void {
			// we gotta call another native process to tell us where java is
			var suinfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			// this tool on OS 10.5 and higher tells you where JAVA_HOME is; if not on 10.5.x and up, yer screwed
			suinfo.executable = new File("/usr/libexec/java_home");

			var javahome:NativeProcess = new NativeProcess();
			
			javahome.addEventListener(NativeProcessExitEvent.EXIT, function(evt:NativeProcessExitEvent):void {
				LOG.info("Mac OS java_home exited");
			});
			
			javahome.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, function(evt:ProgressEvent):void {
				var outputData:String = javahome.standardOutput.readUTFBytes(javahome.standardOutput.bytesAvailable);
				outputData = com.adobe.utils.StringUtil.trim(outputData) + "/bin/java";
				LOG.debug("Mac OS found java: "+outputData);
				startupInfo.executable = new File(outputData);
				// force 32-bit; must be 32-bit for Bluetooth libraries
				args.push("-d32");
				_startJava(startupInfo, args);
			});
			
			javahome.start(suinfo); 
		}
		
		/**
		 * We include the JRE as part of the installer for Linux
		 */
		private function resolveLinuxJVM(startupInfo:NativeProcessStartupInfo, args:Vector.<String>):void {
			var file:File=File.applicationDirectory;
			file=file.resolvePath("jre/bin/java");
			startupInfo.executable = file;
			_startJava(startupInfo, args);
		}
		
		private function onJvmExit(evt:NativeProcessExitEvent):void {
			LOG.debug('JVM exited with '+evt.exitCode);
		}
		
		private function onStdioError(evt:IOErrorEvent):void {
			LOG.debug('io error' +evt.text);
		}
	}
}