package daisyworks.model.presentation
{
	import daisyworks.event.AppEvent;
	import daisyworks.model.App;
	import daisyworks.model.Component;
	
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;

	public class AppPresentationModel
	{
		private var _appStoreApps:ArrayCollection;
		
		private var _installedApps:ArrayCollection;
		
		private var _appStoreDict:Dictionary = new Dictionary(true);
		private var _installedAppDict:Dictionary = new Dictionary(true);
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		public function AppPresentationModel() { }
		
		[PostConstruct]
		public function init():void {
			dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST));
		}
		
		[Bindable]
		public function get appStoreApps():ArrayCollection {
			return _appStoreApps;
		}
		
		public function set appStoreApps(val:ArrayCollection):void {
			this._appStoreApps = val;
		}
		
		[Bindable]
		public function get installedApps():ArrayCollection {
			return _installedApps;
		}
		
		public function set installedApps(val:ArrayCollection):void {
			this._installedApps = val;
		}
		
		[EventHandler(event="AppStoreEvent.RESULTS", properties="results")]
		public function onAppStoreAppsLoaded(val:XMLListCollection):void {
			var ac:ArrayCollection = App.fromXmlList(val.source);
			appStoreApps = mergeState(ac, _installedAppDict);
		}
		
		[EventHandler(event="AppEvent.LIST_RESULTS", properties="list")]
		public function onAppInstallList(val:XMLListCollection):void {
			var ac:ArrayCollection = App.fromXmlList(val.source);
			for each(var app:App in ac) {
				_installedAppDict[app.id] = app;
			}
			installedApps = ac;
			mergeState(appStoreApps, _installedAppDict);
		}
		
		private function mergeState(apps:ArrayCollection, installed:Dictionary):ArrayCollection {
			for each(var app:App in apps) {
				var installedApp:App = installed[app.id];
				if(installedApp) {
					app.installed = true;
					if(installedApp.compare(app.software) == true) {
						// mark for upgrade
						app.updateAvailable = true;
					}
				}
			}
			return apps;
		}
	}
}