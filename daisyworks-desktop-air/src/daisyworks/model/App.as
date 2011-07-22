package daisyworks.model
{
	import com.adobe.utils.DateUtil;
	
	import daisyworks.config.PlatformUtil;
	
	import flash.utils.Dictionary;
	
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.TextFlow;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class App
	{
		private var _id:Number;
		private var _price:String;
		private var _author:String;
		private var _authorUrl:String;
		private var _categories:ArrayCollection;
		private var _description:TextFlow;
		private var _icons:ArrayCollection;
		private var _name:String;
		private var _released:Date;
		private var _requirements:ArrayCollection;
		private var _software:ArrayCollection;
		
		private var _updateAvailable:Boolean;
		private var _installed:Boolean;
		
		public function App()
		{
		}
		
		public function get id():Number
		{
			return _id;
		}
		
		public function set id(value:Number):void
		{
			_id = value;
		}
		
		public function get price():String
		{
			return _price;
		}
		
		public function set price(value:String):void
		{
			_price = value;
		}
		
		public function get author():String
		{
			return _author;
		}
		
		public function set author(value:String):void
		{
			_author = value;
		}
		
		public function get authorUrl():String
		{
			return _authorUrl;
		}
		
		public function set authorUrl(value:String):void
		{
			_authorUrl = value;
		}
		
		public function get categories():ArrayCollection
		{
			return _categories;
		}
		
		public function set categories(value:ArrayCollection):void
		{
			_categories = value;
		}
		
		public function get description():TextFlow
		{
			return _description;
		}
		
		public function set description(value:TextFlow):void
		{
			_description = value;
		}
		
		public function get icons():ArrayCollection
		{
			return _icons;
		}
		
		public function set icons(value:ArrayCollection):void
		{
			_icons = value;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function set name(value:String):void
		{
			_name = value;
		}
		
		public function get released():Date
		{
			return _released;
		}
		
		public function set released(value:Date):void
		{
			_released = value;
		}
		
		public function get requirements():ArrayCollection
		{
			return _requirements;
		}
		
		public function set requirements(value:ArrayCollection):void
		{
			_requirements = value;
		}
		
		public function get software():ArrayCollection
		{
			return _software;
		}
		
		public function set software(value:ArrayCollection):void
		{
			_software = value;
		}
		
		public function get updateAvailable():Boolean
		{
			return _updateAvailable;
		}
		
		public function set updateAvailable(val:Boolean):void {
			_updateAvailable = val;
		}
		
		public function get installed():Boolean
		{
			return _installed;
		}
		
		public function set installed(val:Boolean):void {
			_installed = val;
		}
		
		public function getIconUrl(size:Number):String {
			for each(var icon:Icon in icons) {
				if(icon.size == size) {
					if(icon.localUrl != null && icon.localUrl.length > 0) { return icon.localUrl; }
					else if(icon.remoteUrl != null && icon.remoteUrl.length > 0) { return icon.remoteUrl; }
				}
			}
			return null;
		}
		
		/**
		 * Compare their ArrayCollection of software components to mine.
		 * if they end up having any component that has a newer version
		 * this returns true
		 */
		public function compare(theirs:ArrayCollection):Boolean {
			for each(var them:Component in theirs) {
				for each(var mine:Component in software) {
					if(mine.compare(them) > 0) {
						return true;
					}
				}
			}
			return false;
		}
		
		public function getFirmware():Component {
			if(software == null || software.length == 0) { return null; }
			for each(var c:Component in software) {
				if(c.type == 'firmware')
					return c;
			}
			return null;
		}
		
		public function getSwf():Component {
			if(software == null || software.length == 0) { return null; }
			for each(var c:Component in software) {
				if(c.type == 'swf')
					return c;
			}
			return null;
		}
		
		public function toXml():XML {
			var xml:XML = <app id='' price=''>
				<author />
				<authorUrl />
				<categories />
				<description />
				<icons />
				<name />
				<released />
				<requirements />
				<software />				
			</app>;
			xml.@id = id;
			xml.@price = price;
			xml.author = author;
			xml.authorUrl = authorUrl;
			for each(var s:String in categories) { 
				var x:XML = <category/>;
				x.appendChild(s);
				xml.categories.appendChild(x);
			}
			xml.description = description.getText();
			for each(var icon:Icon in icons) {
				xml.icons.appendChild(icon.toXml());
			}
			xml.name = name;
			xml.released = DateUtil.toW3CDTF(released);
			for each(var h:Hardware in requirements) {
				xml.requirements.appendChild(h.toXml());
			}
			for each(var c:Component in software) {
				xml.software.appendChild(c.toXml());
			}
			return xml;
		}
		
		public static function fromXmlList(list:XMLList):ArrayCollection {
			var ac:ArrayCollection = new ArrayCollection();
			for each(var node:XML in list) {
				ac.addItem(fromXml(node));
			}
			return ac;
		}
		
		public static function fromXml(node:XML):App {
			var a:App = new App();
			a.id = node.@id;
			a.author = node.author;
			a.authorUrl = node.authorUrl;
			a.categories = categoriesFromXmlList(node.categories.children());
			a.description = PlatformUtil.getTextFlow(node, "description");
			a.icons = getIcons(node);
			a.name = node.name;
			a.price = node.@price;
			a.released = PlatformUtil.getDate(node.released[0]);
			a.requirements = Hardware.fromXmlList(node.requirements.children());
			a.software = Component.fromXmlList(node.software.children());
			return a;
		}
		
		public static function getIcons(node:XML):ArrayCollection {
			var ac:ArrayCollection = new ArrayCollection();
			for each(var xml:XML in node.icons.children()) {
				ac.addItem(Icon.fromXML(xml));
			}
			return ac;
		}
		
		public static function categoriesFromXmlList(list:XMLList):ArrayCollection {
			var ac:ArrayCollection = new ArrayCollection();
			for each(var node:XML in list) {
				ac.addItem(node.text());
			}
			return ac;
		}
		
		

	}
}