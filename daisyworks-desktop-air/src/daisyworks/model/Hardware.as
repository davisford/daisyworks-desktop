package daisyworks.model
{
	import flashx.textLayout.elements.TextFlow;
	
	import daisyworks.config.PlatformUtil;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class Hardware
	{
		private var _name:String;
		private var _model:String;
		private var _url:String;
		private var _version:String;
		private var _instruction:TextFlow;
		
		public function Hardware()
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

		public function get model():String
		{
			return _model;
		}

		public function set model(value:String):void
		{
			_model = value;
		}

		public function get url():String
		{
			return _url;
		}

		public function set url(value:String):void
		{
			_url = value;
		}

		public function get version():String
		{
			return _version;
		}

		public function set version(value:String):void
		{
			_version = value;
		}

		public function get instruction():TextFlow
		{
			return _instruction;
		}

		public function set instruction(value:TextFlow):void
		{
			_instruction = value;
		}
		
		public function toXml():XML {
			var xml:XML = <hardware>
				<name />
				<model />
				<url />
				<version />
				<instruction />
			</hardware>;
			xml.name = name;
			xml.model = model;
			xml.url = url;
			xml.instruction = instruction.getText();
			return xml;
		}
		
		public static function fromXmlList(list:XMLList):ArrayCollection {
			var ac:ArrayCollection = new ArrayCollection();
			for each(var node:XML in list) {
				ac.addItem(fromXml(node));
			}
			return ac;
		}

		public static function fromXml(node:XML):Hardware {
			var h:Hardware = new Hardware();
			h.instruction = PlatformUtil.getTextFlow(node, "instruction");
			h.model = node.model;
			h.name = node.name;
			h.url = node.url;
			h.version = node.version;
			return h;
		}
	}
}