package daisyworks.model.presentation
{
	import daisyworks.event.AppEvent;
	import daisyworks.log.Logger;
	import daisyworks.model.App;
	import daisyworks.model.Component;
	
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.logging.ILogger;

	/**
	 * Presentation model for managing the state of
	 * 
	 * Installed Applications 
     * App Store Applications
	 * 
	 * Such as, the list of currently installed apps, and the list of the last fetched
	 * App Store Apps from the server.  We have to do tricky stuff like compare version numbers
	 * to indicate if Apps have an update available, etc.
	 * 
	 * Various Visual Components bind to this as the presentation model.
	 * 
	 */
	public class AppPresentationModel
	{
		private static const LOG:ILogger = Logger.getLogger(AppPresentationModel);
		
		// holds the collecton of app store apps
		private var _appStoreApps:ArrayCollection;
		
		// holds the collection of installed apps
		private var _installedApps:ArrayCollection;

		// we use a dictionary so we can index quickly when we have to merge sort
		// key=app.id, value=app
		private var _installedAppDict:Dictionary = new Dictionary(true);
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		/**
		 * Constructor
		 */
		public function AppPresentationModel() { }
		
		/**
		 * Called after Swiz has initialized everything
		 */
		[PostConstruct]
		public function init():void {
			// dispatch this to load the list of installed apps
			dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST));
		}
		
		/**
		 * Getter for the collection of App Store Apps
		 */
		[Bindable]
		public function get appStoreApps():ArrayCollection {
			return _appStoreApps;
		}
		
		/**
		 * Setter for the collection of App Store Apps
		 */
		public function set appStoreApps(val:ArrayCollection):void {
			this._appStoreApps = val;
		}
		
		/**
		 * Getter for the collection of Installed Apps
		 */
		[Bindable]
		public function get installedApps():ArrayCollection {
			return _installedApps;
		}
		
		/**
		 * Setter for the collection of Installed Apps
		 */
		public function set installedApps(val:ArrayCollection):void {
			this._installedApps = val;
		}
		
		/**
		 * Handles the event when the AppStore results have been loaded
		 */
		[EventHandler(event="AppStoreEvent.RESULTS", properties="results")]
		public function onAppStoreAppsLoaded(val:XMLListCollection):void {
			// convert the XML to an ArrayCollection of App objects
			var ac:ArrayCollection = App.fromXmlList(val.source);
			// merge the state with installed apps
			appStoreApps = mergeState(ac, _installedAppDict);
		}
		
		/**
		 * Handles the event when the Installed Apps results have been loaded
		 */
		[EventHandler(event="AppEvent.LIST_RESULTS", properties="list")]
		public function onAppInstallList(val:XMLListCollection):void {
			// convert the XML to an ArrayCollection of App objects
			var ac:ArrayCollection = App.fromXmlList(val.source);
			
			// restart with an empty dictionary
			_installedAppDict = new Dictionary(true);
			// add each app to the dictionary so we can index it easily
			for each(var app:App in ac) {
				_installedAppDict[app.id] = app;
			}
			
			// reset the array collection property
			installedApps = ac;
			
			// reset the app store apps by merging state
			appStoreApps = mergeState(appStoreApps, _installedAppDict);
		}
		
		/**
		 * Handles the event when an Installed App was deleted
		 */
		[EventHandler(event="AppEvent.REMOVED", properties="app")]
		public function onAppRemove(app:App):void {
			// remove it from the dictionary
			_installedAppDict[app.id] = null;
			
			// REMEMBER: always delete from arr.length to [0]
			var arr:Array = installedApps.source;
			for(var i:int = arr.length - 1; i >= 0; i--) {
				if(arr[i].id == app.id) {
					installedApps.removeItemAt(i);
				}
			}
						
			// set the state of the app in the app store apps to uninstalled
			for each(var appStoreApp:App in appStoreApps) {
				// find the app that matches id
				if(app.id == appStoreApp.id) {
					// set it to not installed
					appStoreApp.installed = false;
					// break out of the loop
					break;
				}
			}
		}
		
		/**
		 * Merge the state of the App Store Apps with the Installed Apps
		 */
		private function mergeState(apps:ArrayCollection, installed:Dictionary):ArrayCollection {
			// iterate through all the apps in the array collection
			for each(var app:App in apps) {
				
				// find the corresponding installed app (if it exists)
				var installedApp:App = installed[app.id];
				
				if(installedApp) {
					// since we found it, it means it is installed
					app.installed = true;
					
					// check if an update is available
					if(installedApp.compare(app.software) == true) {
						// mark for update
						app.updateAvailable = true;
						installedApp.updateAvailable = true;
					}
				} else {
					// set it to not installed, in case it was already set to installed
					app.installed = false;
				}
			}
			return apps;
		}
	}
}