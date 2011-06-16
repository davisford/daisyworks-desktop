package daisyworks.event
{
	import daisyworks.model.App;
	import daisyworks.model.Component;
	
	import flash.events.Event;
	import flash.filesystem.File;
	
	import org.swizframework.utils.async.AsynchronousEvent;
	
	public class AppDownloadEvent extends AsynchronousEvent
	{
		
		public static const DOWNLOAD:String = "AppDownloadEvent.DOWNLOAD";
		public var app:App;
		public var component:Component;
		public var file:File;
		
		public function AppDownloadEvent(type:String, app:App, component:Component, file:File)
		{
			this.app = app;
			this.component = component;
			this.file = file;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new AppDownloadEvent(type, app, component, file);
		}
	}
}