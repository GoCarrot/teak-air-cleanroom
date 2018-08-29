package io.teak.sdk.cleanroom
{
	import feathers.core.ITextRenderer;

	import feathers.controls.Alert;
	import feathers.controls.Label;
	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.controls.TextCallout;
	import feathers.controls.text.TextBlockTextRenderer;

	import feathers.data.ArrayCollection;

	import feathers.layout.VerticalAlign;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.layout.VerticalLayoutData;

	import feathers.themes.MetalWorksMobileTheme;

	import starling.display.Sprite;
	import starling.events.Event;

	import flash.net.SharedObject;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;

CONFIG::test_distriqt {
	import com.distriqt.extension.core.Core;
}
CONFIG::test_distriqt_notif {
	import com.distriqt.extension.pushnotifications.*;
}

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
			// The problem-libraries
CONFIG::test_distriqt {
			Core.init();
}
CONFIG::test_distriqt_notif {
			PushNotifications.init("0765b48cf45ae3a2840bd49201038f50d49c27e0Ry5lvYs1S6dG6ANouiEPMK9Ts0GmJ02HJY32LZjxI39yrOWCPcrqO5RG8kZLxxxK1J2O26RSuMIRp4DmXYWeFokTjuc/zUmjp3JNQiKiqlMu3TBltjwY0CZa+jpeCjir1r2L4TcKKMnuO4sVwDOJ0GjvfPmVpnglxphqoRWP42/MgE0rwGIrP4NEa9QG92PBBK2pAne7YHfQ8XMdH/9gTryj53naH6SuX9LW+mx522XfI3IaHM/0Dc1BRHs2FYr6rpsxNCSYXZQdJZVf7HRLT7IysyoceZWVsen3XlLewro7B3f8KvCESrTZu44s5EcocTyb2d6QrbYFv0PbW+Feag==");
			var service:Service = new Service(Service.DEFAULT);
			service.sandboxMode = true;
			PushNotifications.service.setup(service);
}

			// Set up the UI when this Sprite is added to the stage
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

			// For checking status of notifications
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);

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
			Teak.instance.addEventListener(TeakEvent.LONG_DISTANCE_NOTIFICATION_SCHEDULED, notificationScheduledHandler);
			Teak.instance.addEventListener(TeakEvent.NOTIFICATION_CANCELED, notificationCanceledHandler);
			Teak.instance.addEventListener(TeakEvent.NOTIFICATION_CANCEL_ALL, notificationCancelAllHandler);

CONFIG::use_air_to_register_notifications {
				// Configure the permissions for notifications
				var preferredStyles:Vector.<String> = new Vector.<String>();
				var subscribeOptions:RemoteNotifierSubscribeOptions = new RemoteNotifierSubscribeOptions();
				var remoteNot:RemoteNotifier = new RemoteNotifier();

				preferredStyles.push(NotificationStyle.ALERT, NotificationStyle.BADGE, NotificationStyle.SOUND);
				subscribeOptions.notificationStyles = preferredStyles;

				// Request notification permissions on iOS with the popup
				remoteNot.subscribe(subscribeOptions);
}
CONFIG::use_teak_to_register_notifications {
				//Teak.instance.registerForProvisionalNotifications();
				Teak.instance.registerForNotifications();
}
		}

		private function rewardHandler(e:TeakEvent):void
		{
			Teak.instance.log("Reward:\n" + e.data);

			var payload:Object = JSON.parse(e.data);
			var popupTitle:String = "Reward";
			var popupMessage:String = "";
			switch (payload.status as String) {
				case "grant_reward": {
					// The user has been issued this reward by Teak
					popupTitle = "Reward Granted";
					popupMessage = "You got: ";
					var isFirst:Boolean = true;
					for(var i:String in payload.reward) {
						if(isFirst) {
							isFirst = false;
						} else {
							popupMessage += " and ";
						}
						popupMessage += payload.reward[i] + " " + i;
					}
				}
				break;

				case "self_click": {
					// The user has attempted to claim a reward from their own social post
					popupTitle = "Self Click";
					popupMessage = "The user has attempted to claim a reward from their own social post";
				}
				break;

				case "already_clicked": {
					// The user has already been issued this reward
					popupTitle = "Already Clicked";
					popupMessage = "The user has already been issued this reward";
				}
				break;

				case "too_many_clicks": {
					// The reward has already been claimed its maximum number of times globally
					popupTitle = "Too Many Clicks";
					popupMessage = "The reward has already been claimed its maximum number of times globally";
				}
				break;

				case "exceed_max_clicks_for_day": {
					// The user has already claimed their maximum number of rewards of this type for the day
					popupTitle = "Exceed Max Clicks for Day";
					popupMessage = "The user has already claimed their maximum number of rewards of this type for the day";
				}
				break;

				case "expired": {
					// This reward has expired and is no longer valid
					popupTitle = "Expired";
					popupMessage = "This reward has expired and is no longer valid";
				}
				break;

				case "invalid_post": {
					// Teak does not recognize this reward id
					popupTitle = "Invalid Post";
					popupMessage = "Teak does not recognize this reward id";
				}
				break;
			}

			var alert:Alert = Alert.show(popupMessage, popupTitle, new ArrayCollection(
			[
				{ label: "Ok" }
			]));

			if(currentTestIndex > -1 && tests[currentTestIndex].OnReward(payload))
			{
				advanceTests();
			}
		}

		private function launchedFromNotificationHandler(e:TeakEvent):void
		{
			Teak.instance.log("launchedFromNotificationHandler: " + e.data);
			TextCallout.show("launchedFromNotificationHandler: " + e.data, currentTestButton);
			if(currentTestIndex > -1 && tests[currentTestIndex].OnLaunchedFromNotification(JSON.parse(e.data)))
			{
				advanceTests();
			}
		}

		private function notificationScheduledHandler(e:TeakEvent):void
		{
			TextCallout.show("Notification Scheduled (" + e.status + "):\n" + e.data, currentTestButton);

			if(tests[currentTestIndex].AutoBackground && e.type !== TeakEvent.LONG_DISTANCE_NOTIFICATION_SCHEDULED)
			{
				var request:URLRequest = new URLRequest("https://google.com");
				navigateToURL(request);
			}
		}

		private function notificationCanceledHandler(e:TeakEvent):void
		{
			TextCallout.show("Notification Canceled (" + e.status + "):\n" + e.data, currentTestButton);
		}

		private function notificationCancelAllHandler(e:TeakEvent):void
		{
			TextCallout.show("All Notifications Canceled (" + e.status + "):\n" + e.data, currentTestButton);
		}

		private function randomNonConfusingString(length:int):String
		{
			var chars:String = "abcdefghkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789";
			var num_chars:Number = chars.length - 1;
			var uid:String = "";

			for (var i:Number = 0; i < length; i++) {
				uid += chars.charAt(Math.floor(Math.random() * num_chars));
			}
			return uid;
		}

		private function teakIdentifyUser():void
		{
			var deviceConfiguration:Object = Teak.instance.getDeviceConfiguration();
			var deviceModel:String = deviceConfiguration.deviceModel;
			Teak.instance.identifyUser("air-" + deviceModel.toLowerCase());
		}

		protected var currentTestButton:Button;
		protected var openSettingsButton:Button;
		protected var container:LayoutGroup;
		protected var layoutData:VerticalLayoutData;

		// This is called when the Sprite is added to the stage, and sets up the UI
		protected function addedToStageHandler(event:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

			new MetalWorksMobileTheme();

			setupTestUI();
		}

		protected function enterFrameHandler():void
		{
			if (openSettingsButton) {
				openSettingsButton.isEnabled = !Teak.instance.areNotificationsEnabled();
				openSettingsButton.validate();
			}
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

			var cancelAllButton:Button = new Button();
			cancelAllButton.label = "Cancel All Notifications"
			cancelAllButton.height = 50;
			cancelAllButton.layoutData = layoutData;
			cancelAllButton.addEventListener(Event.TRIGGERED, function(event:Event):void {
				Teak.instance.cancelAllNotifications();
			});

			container.addChild(cancelAllButton);
			cancelAllButton.validate();

			var userProfileTest:Button = new Button();
			userProfileTest.label = "Test User Profile"
			userProfileTest.height = 50;
			userProfileTest.layoutData = layoutData;
			userProfileTest.addEventListener(Event.TRIGGERED, function(event:Event):void {
				Teak.instance.setNumericAttribute("coins", Math.random() * 1000000.0);
				Teak.instance.setStringAttribute("last_slot", randomNonConfusingString(10));
			});

			container.addChild(userProfileTest);
			userProfileTest.validate();

			openSettingsButton = new Button();
			openSettingsButton.label = "Open Settings"
			openSettingsButton.height = 50;
			openSettingsButton.layoutData = layoutData;
			openSettingsButton.isEnabled = !Teak.instance.areNotificationsEnabled();
			openSettingsButton.addEventListener(Event.TRIGGERED, function(event:Event):void {
				Teak.instance.openSettingsAppToThisAppsSettings();
			});

			container.addChild(openSettingsButton);
			openSettingsButton.validate();

			var testExceptionReporting:Button = new Button();
			testExceptionReporting.label = "Test Exception Reporting"
			testExceptionReporting.height = 50;
			testExceptionReporting.layoutData = layoutData;
			testExceptionReporting.addEventListener(Event.TRIGGERED, function(event:Event):void {
				Teak.instance.testExceptionReporting();
			});

			container.addChild(testExceptionReporting);
			testExceptionReporting.validate();

			var testLongDistance:Button = new Button();
			testLongDistance.label = "Test Long Distance"
			testLongDistance.height = 50;
			testLongDistance.layoutData = layoutData;
			testLongDistance.addEventListener(Event.TRIGGERED, function(event:Event):void {
				Teak.instance.scheduleLongDistanceNotification("test_none Local", 5, ["air-ane-lx3", "air-sm-g920t"]);
			});

			container.addChild(testLongDistance);
			testLongDistance.validate();
		}

		protected function advanceTests():void
		{
			if(currentTestButton)
			{
				container.removeChild(currentTestButton);

				var emoji:String = tests[currentTestIndex].Status == 1 ? "☑" : "☒"

				var label:Label = new Label();
				label.text = emoji + " " + tests[currentTestIndex].Name;
				if (tests[currentTestIndex].Status == 2) {
					label.text += "\n\t" + tests[currentTestIndex].Error;
				}
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
			new Test("Reward", "test_reward", null, {"coins": 1000}),
			new Test("Reward + Deep Link", "test_rewarddeeplink", "with-reward", {"coins": 1000})
		];
	}
}
