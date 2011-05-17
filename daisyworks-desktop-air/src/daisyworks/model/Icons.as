package daisyworks.model {

	public class Icons {
		[Embed(source="../../assets/images/bluetooth.png")]
		[Bindable]
		public static var BLUETOOTH:Class;
		
		[Embed(source="../../assets/images/control_panel.png")]
		[Bindable]
		public static var CONTROL:Class;
		
		[Embed(source="../../assets/images/dns_setting.png")]
		[Bindable]
		public static var NETWORK:Class;
		
		[Embed(source="../../assets/images/processor.png")]
		[Bindable]
		public static var PROCESSOR:Class;
		
		[Embed(source="../../assets/images/remote.png")]
		[Bindable]
		public static var REMOTE:Class;
		
		[Embed(source="../../assets/images/update.png")]
		[Bindable]
		public static var UPDATE:Class;
		
		[Embed(source="../../assets/images/www_page.png")]
		[Bindable]
		public static var WWW:Class;
		
		[Embed(source="../../assets/images/application_osx_terminal.png")]
		[Bindable]
		public static var TERMINAL:Class;

		public function Icons() {	}
	}
}