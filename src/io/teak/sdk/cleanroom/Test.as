package io.teak.sdk.cleanroom
{
	public class Test
	{
		private var onDeepLinkCalled:Boolean = false;
		private var onRewardCalled:Boolean = false;
		private var onLaunchCalled:Boolean = false;

		public var Status:int = 0;
		public var VerifyReward:String = null;
		public var VerifyDeepLink:String = null;

		public var AutoBackground:Boolean = true;

		public var Name:String;
		public var CreativeId:String;

		public function Test(name:String, creativeId:String, verifyDeepLink:String = null)
		{
			this.Name = name;
			this.CreativeId = creativeId;
			this.VerifyDeepLink = verifyDeepLink;
		}

		protected function Prepare():void
		{
			if(!this.VerifyReward) onRewardCalled = true;
			if(!this.VerifyDeepLink) onDeepLinkCalled = true;
		}

		protected function CheckStatus():Boolean
		{
			if(onLaunchCalled && onDeepLinkCalled && onRewardCalled)
			{
				if(this.Status == 0) this.Status = 1;
				return true;
			}
			return false;
		}

		public function OnDeepLink(parameters:Object):Boolean
		{
			if(this.VerifyDeepLink && parameters.data != this.VerifyDeepLink)
			{
				this.Status = 2;
			}

			Prepare();
			onDeepLinkCalled = true;
			return CheckStatus();
		}

		public function OnReward(parameters:Object):Boolean
		{
			Prepare();
			onRewardCalled = true;
			return CheckStatus();
		}

		public function OnLaunchedFromNotification(parameters:Object):Boolean
		{
			Prepare();
			onLaunchCalled = true;
			return CheckStatus();
		}
	}
}
