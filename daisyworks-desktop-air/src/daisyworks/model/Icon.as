package daisyworks.model
{
	public class Icon
	{
		private var _localUrl:String;
		private var _remoteUrl:String;
		private var _size:Number;
		
		public function Icon()
		{
		}

		public function get size():Number
		{
			return _size;
		}

		public function set size(value:Number):void
		{
			_size = value;
		}

		public function get remoteUrl():String
		{
			return _remoteUrl;
		}

		public function set remoteUrl(value:String):void
		{
			_remoteUrl = value;
		}

		public function get localUrl():String
		{
			return _localUrl;
		}

		public function set localUrl(value:String):void
		{
			_localUrl = value;
		}
		
		public function toXml():XML {
			var xml:XML = <icon />;
			xml.@size = size;
			xml.@path = localUrl;
			xml.appendChild(remoteUrl);
			return xml;
		}
		
		public static function fromXML(xml:XML):Icon {
			var icon:Icon = new Icon();
			icon.size = xml.@size;
			icon.localUrl = xml.@path;
			icon.remoteUrl = xml.toString();
			return icon;
		}

	}
}