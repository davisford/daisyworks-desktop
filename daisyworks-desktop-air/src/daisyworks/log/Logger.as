package daisyworks.log {
		
	import com.adobe.air.logging.FileTarget;
	
	import flash.filesystem.File;
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.LineFormattedTarget;
	import mx.logging.targets.TraceTarget;

	public class Logger {
		private static var instance:Logger=new Logger();
		
		function Logger() {
			if(instance != null) {
				throw new Error("singleton logger can't be instantiated");
			}
			// trace targets
			
			addTarget(new TraceTarget(), ["mx.messaging.*", "mx.rpc.*"], LogEventLevel.ERROR);
			
			// add the file logging target
			var logFile:File = File.applicationStorageDirectory.resolvePath('logs/daisyworks-ui.log');
			var fileTarget:FileTarget = new FileTarget(logFile);
			addTarget(fileTarget, ["daisyworks.*"], LogEventLevel.DEBUG);
			
			addTarget(new TraceTarget(), ["daisyworks.*"], LogEventLevel.DEBUG);
		}
		
		private static function addTarget(target:LineFormattedTarget, filters:Array, level:int):void {
			target.level = level;
			target.includeCategory = true;
			target.includeDate = true;
			target.includeLevel = true;
			target.includeTime = true;
			target.filters = filters;
			Log.addTarget(target);
		}
		
		private function getInternalLog(classRef:Class):ILogger { 
			var className:String =  getQualifiedClassName(classRef).replace("::", ".");
			return Log.getLogger(className);
		}
		
		public static function getLogger(classRef:Class):ILogger {
			return instance.getInternalLog(classRef);
		}
	}
}