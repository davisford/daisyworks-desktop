package daisyworks.model
{
	import mx.collections.ArrayCollection;

	[Bindable]
	public class App
	{
		private var _name:String;
		private var _description:String;
		private var _version:Number;
		private var _requirements:String;
		private var _installed:Boolean;
		private var _installUrl:String;
		private var _imageUrl:String;
		private var _released:Date;
		
		public function App()
		{

		}

		public function get name():String
		{
			return _name;
		}

		public function set name(value:String):void
		{
			_name = value;
		}

		public function get description():String
		{
			return _description;
		}

		public function set description(value:String):void
		{
			_description = value;
		}

		public function get version():Number
		{
			return _version;
		}

		public function set version(value:Number):void
		{
			_version = value;
		}

		public function get requirements():String
		{
			return _requirements;
		}

		public function set requirements(value:String):void
		{
			_requirements = value;
		}

		public function get installed():Boolean
		{
			return _installed;
		}

		public function set installed(value:Boolean):void
		{
			_installed = value;
		}

		public function get installUrl():String
		{
			return _installUrl;
		}

		public function set installUrl(value:String):void
		{
			_installUrl = value;
		}

		public function get imageUrl():String
		{
			return _imageUrl;
		}

		public function set imageUrl(value:String):void
		{
			_imageUrl = value;
		}
		
		public function get released():Date
		{
			return _released;
		}
		
		public function set released(value:Date):void
		{
			_released = value;
		}

		public static function fromXMLList(xmlList:XMLList):ArrayCollection {
			for each(var xml:XML in xmlList) {
				var app:App = new App();
				app.name = xml.name;
				app.description = xml.description;
				app.imageUrl = xml.imageUrl;
				app.installed = xml.installed;
				app.installUrl = xml.installUrl;
				app.released = Date(xml.released);
				app.requirements = xml.requirements;
				app.version = xml.version;
			}
		}

	}
}