package daisyworks.model
{
	import com.adobe.utils.DateUtil;
	
	import flashx.textLayout.elements.TextFlow;
	
	import mx.collections.ArrayCollection;
	
	import spark.utils.TextFlowUtil;

	[Bindable]
	public class Component
	{
		private var _type:String;
		private var _path:String;
		private var _notes:TextFlow;
		private var _released:Date;
		private var _url:String;
		private var _version:String;
		
		public function Component()
		{
		}

		public function get notes():TextFlow
		{
			return _notes;
		}

		public function set notes(value:TextFlow):void
		{
			_notes = value;
		}

		public function get path():String
		{
			return _path;
		}

		public function set path(value:String):void
		{
			_path = value;
		}

		public function get type():String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type = value;
		}

		public function get released():Date
		{
			return _released;
		}

		public function set released(value:Date):void
		{
			_released = value;
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
		
		/**
		 * Compare their component to ours
		 * If the types are not equal, returns zero
		 * If the types are equal and our version is newer, returns -1
		 * If the types are equal and versions are equal, returns 0
		 * If the types are equal and our version is older, returns 1
		 */
		public function compare(them:Component):Number {
			if(type != them.type) { return 0; }
			else if(version == them.version) { return 0; }
			else if(version >= them.version) { return -1; }
			else { return 1; }
		}
		
		public function toXml():XML {
			var xml:XML = <component type='' path=''>
				<notes />
				<released />
				<url />
				<version />
			</component>
				xml.@type = type;
				xml.@path = path;
				xml.notes = notes;
				xml.released = DateUtil.toW3CDTF(released);
				xml.version = version;
				return xml;
		}
		
		public static function fromXmlList(list:XMLList):ArrayCollection {
			var ac:ArrayCollection = new ArrayCollection();
			for each(var node:XML in list) {
				ac.addItem(fromXml(node));
			}
			return ac;
		}

		public static function fromXml(node:XML):Component {
			var c:Component = new Component();
			c.notes = App.getTextFlow(node, "notes");
			c.path = node.@path;
			c.released = App.getDate(node.released[0]);
			c.type = node.@type;
			c.url = node.url;
			c.version = node.version;
			return c;
		}
	}
}