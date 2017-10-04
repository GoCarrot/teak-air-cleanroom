package io.teak.sdk.cleanroom
{
	import feathers.core.ITextRenderer;
	import feathers.controls.Label;
	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextCallout;
	import feathers.controls.text.TextBlockTextRenderer;

	import feathers.layout.VerticalAlign;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.layout.VerticalLayoutData;

	import feathers.themes.MetalWorksMobileTheme;

	import starling.display.Sprite;
	import starling.events.Event;

	import flash.net.SharedObject;

	// Import the Teak SDK
	import io.teak.sdk.*;

CONFIG::use_air_to_register_notifications {
	// --- These are the imports needed to request notification permissions ---
	import flash.notifications.NotificationStyle;
	import flash.notifications.RemoteNotifier;
	import flash.notifications.RemoteNotifierSubscribeOptions;
	// ------------------------------------------------------------------------
}
	public class Main extends Sprite
	{
		public function Main()
		{
			// Set up the UI when this Sprite is added to the stage
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

			// Register a deep link route
			var scope:Main = this;
			Teak.instance.registerRoute("/test/:data", "Test", "Deep link for semi-automated tests", function(parameters:Object):void {
				if(currentTestIndex > -1 && tests[currentTestIndex].OnDeepLink(parameters))
				{
					advanceTests();
				}
			});

			// Set the user id
			teakIdentifyUser();

			// Add Teak event listeners
			Teak.instance.addEventListener(TeakEvent.LAUNCHED_FROM_NOTIFICATION, launchedFromNotificationHandler);
			Teak.instance.addEventListener(TeakEvent.ON_REWARD, rewardHandler);
			Teak.instance.addEventListener(TeakEvent.NOTIFICATION_SCHEDULED, notificationScheduledHandler);
			Teak.instance.addEventListener(TeakEvent.NOTIFICATION_CANCELED, notificationCanceledHandler);

CONFIG::use_air_to_register_notifications {
				// Configure the permissions for notifications
				var preferredStyles:Vector.<String> = new Vector.<String>();
				var subscribeOptions:RemoteNotifierSubscribeOptions = new RemoteNotifierSubscribeOptions();
				var remoteNot:RemoteNotifier = new RemoteNotifier();

				preferredStyles.push(NotificationStyle.ALERT, NotificationStyle.BADGE, NotificationStyle.SOUND );
				subscribeOptions.notificationStyles = preferredStyles;

				// Request notification permissions on iOS with the popup
				remoteNot.subscribe(subscribeOptions);
}
CONFIG::use_teak_to_register_notifications {

				Teak.instance.registerForNotifications();
}
		}

		private function rewardHandler(e:TeakEvent):void
		{
			TextCallout.show("Reward:\n" + JSON.stringify(e.data), currentTestButton);

			switch (e.data['status'] as String) {
				case "grant_reward": {
					// The user has been issued this reward by Teak
				}
				break;

				case "self_click": {
					// The user has attempted to claim a reward from their own social post
				}
				break;

				case "already_clicked": {
					// The user has already been issued this reward
				}
				break;

				case "too_many_clicks": {
					// The reward has already been claimed its maximum number of times globally
				}
				break;

				case "exceed_max_clicks_for_day": {
					// The user has already claimed their maximum number of rewards of this type for the day
				}
				break;

				case "expired": {
					// This reward has expired and is no longer valid
				}
				break;

				case "invalid_post": {
					//Teak does not recognize this reward id
				}
				break;

				if(currentTestIndex > -1 && tests[currentTestIndex].OnReward(e.data))
				{
					advanceTests();
				}
			}
		}

		private function launchedFromNotificationHandler(e:TeakEvent):void
		{
			if(currentTestIndex > -1 && tests[currentTestIndex].OnLaunchedFromNotification(e.data))
			{
				advanceTests();
			}
		}

		private function notificationScheduledHandler(e:TeakEvent):void
		{
			TextCallout.show("Notification Scheduled:\n" + JSON.stringify(e.data), currentTestButton);

			if(tests[currentTestIndex].AutoBackground)
			{
				// TODO: ANE for this
			}
		}

		private function notificationCanceledHandler(e:TeakEvent):void
		{
			TextCallout.show("Notification Canceled:\n" + JSON.stringify(e.data), currentTestButton);
		}

		private function teakIdentifyUser():void
		{
			// Get or create a unique user id
			var so:SharedObject = SharedObject.getLocal("teakExampleApp");
			if (!so.data.hasOwnProperty('userId')) {
				var chars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  				var num_chars:Number = chars.length - 1;
  				var uid:String = "";
 
  				for (var i:Number = 0; i < 10; i++) {
  					uid += chars.charAt(Math.floor(Math.random() * num_chars));
  				}
  
				so.data['userId'] = uid;
				so.flush();
			}
			Teak.instance.identifyUser(so.data['userId']);
		}

		protected var currentTestButton:Button;
		protected var container:LayoutGroup;
		protected var layoutData:VerticalLayoutData;

		// This is called when the Sprite is added to the stage, and sets up the UI
		protected function addedToStageHandler(event:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

			new MetalWorksMobileTheme();

			setupTestUI();
		}

		protected function setupTestUI():void
		{
			// UI Layout
			var layout:VerticalLayout = new VerticalLayout();
			layout.padding = 5;
			layout.gap = 5;
			layout.horizontalAlign = HorizontalAlign.CENTER;
			layout.verticalAlign = VerticalAlign.TOP;

			if(container) this.removeChild(container);

			container = new LayoutGroup();
			container.layout = layout;
			container.width = this.stage.stageWidth;
			this.addChild(container);

			layoutData = new VerticalLayoutData();
			layoutData.percentWidth = 100;

			// Teak Version label
			var label:Label = new Label();
			label.text = JSON.stringify(Teak.instance.version);
			label.layoutData = layoutData;
			label.wordWrap = true;
			container.addChild(label);

			advanceTests();
		}

		protected function advanceTests():void
		{
			if(currentTestButton)
			{
				container.removeChild(currentTestButton);

				var emoji:String = tests[currentTestIndex].Status == 1 ? "☑" : "☒"

				var label:Label = new Label();
				label.text = emoji + " " + tests[currentTestIndex].Name;
				label.layoutData = layoutData;
				label.wordWrap = true;
				label.textRendererFactory = function():ITextRenderer
				{
					return new TextBlockTextRenderer();
				};
				container.addChild(label);
			}

			currentTestIndex++;
			if(currentTestIndex < tests.length)
			{
				currentTestButton = new Button();
				currentTestButton.label = tests[currentTestIndex].Name;
				currentTestButton.height = 50;
				currentTestButton.layoutData = layoutData;
				currentTestButton.addEventListener(Event.TRIGGERED, function(event:Event):void {
					Teak.instance.scheduleNotification(tests[currentTestIndex].CreativeId, tests[currentTestIndex].Name, 5.0);
				});

				container.addChild(currentTestButton);
				currentTestButton.validate();
			}
			else
			{
				currentTestButton = new Button();
				currentTestButton.label = "Reset Tests"
				currentTestButton.height = 50;
				currentTestButton.layoutData = layoutData;
				currentTestButton.addEventListener(Event.TRIGGERED, function(event:Event):void {
					currentTestIndex = -1;
					currentTestButton = null;
					setupTestUI();
				});

				container.addChild(currentTestButton);
				currentTestButton.validate();
			}
		}

		protected var currentTestIndex:int = -1;
		protected var tests:Array = [
			new Test("Simple Notification", "test_none"),
			new Test("Deep Link", "test_deeplink", "link-only"),
			new Test("Reward", "test_reward"),
			new Test("Reward + Deep Link", "test_rewarddeeplink", "with-reward")
		];
	}
}
