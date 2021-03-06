package daisyworks.model { 
	
	import com.adobe.air.preferences.Preference;
	
	import flash.events.IEventDispatcher;

	public class Preferences {
		
		public static const JAVA_PATH:String = "java";
		public static const JETTY_PORT:String = "jetty_port";
		public static const HEIGHT:String = "height";
		public static const WIDTH:String = "width";
		public static const CACHED_DEVICE_LOOKUP:String = "cachedDeviceLookup";
		public static const AUTO_CHECK_FOR_UPDATES:String = "autoCheckForUpdates";

		private var _prefs:Preference
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;

		public function Preferences() {
			_prefs=new Preference("daisywork-prefs.dat");
			_prefs.load();
		}

		public function setValue(name:String, value:*, encrypted:Boolean=false):void {
			_prefs.setValue(name, value, encrypted);
		}

		public function getValue(name:String, defaultValue:*=null):* {
			return _prefs.getValue(name, defaultValue);
		}

		public function deleteValue(name:String):void {
			_prefs.deleteValue(name);
		}

		public function save():void {
			_prefs.save();
		}
	}
}