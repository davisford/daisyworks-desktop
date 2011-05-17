package daisyworks.model
{
	[Bindable]
	[RemoteClass(alias="com.daisyworks.model.Device")]
	public class Device
	{
		public var name:String;
		public var address:String;
		public var authenticated:Boolean;
		public var encrypted:Boolean;
		public var trusted:Boolean;
		
		public function Device()
		{
		}
	}
}