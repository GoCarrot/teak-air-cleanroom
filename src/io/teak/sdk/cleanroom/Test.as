package io.teak.sdk.cleanroom
{
	public class Test
	{
		private var onDeepLinkCalled:Boolean = false;
		private var onRewardCalled:Boolean = false;
		private var onLaunchCalled:Boolean = false;

		public var Status:int = 0;
		public var VerifyReward:Object = null;
		public var VerifyDeepLink:String = null;

		public var AutoBackground:Boolean = true;

		public var Name:String;
		public var CreativeId:String;

		public function Test(name:String, creativeId:String, verifyDeepLink:String = null, verifyReward:Object = null)
		{
			this.Name = name;
			this.CreativeId = creativeId;
			this.VerifyDeepLink = verifyDeepLink;
			this.VerifyReward = verifyReward
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
			if(this.VerifyDeepLink && parameters.data !== this.VerifyDeepLink)
			{
				this.Status = 2;
			}

			Prepare();
			this.onDeepLinkCalled = true;
			return CheckStatus();
		}

		public function OnReward(parameters:Object):Boolean
		{
			if(!parameters.teakRewardId || parameters.teakRewardId === "") {
				this.Status = 2;
			}

			if(!parameters.teakCreativeName || parameters.teakCreativeName !== this.CreativeId)
			{
				this.Status = 2;
			}
			else if (this.VerifyReward && JSON.stringify(this.VerifyReward) !== JSON.stringify(parameters.reward))
			{
				this.Status = 2;
			}

			Prepare();
			this.onRewardCalled = true;
			return CheckStatus();
		}

		public function OnLaunchedFromNotification(parameters:Object):Boolean
		{
			if(!parameters.teakCreativeName || parameters.teakCreativeName != this.CreativeId)
			{
				this.Status = 2;
			}
			else if(this.VerifyReward && !parameters.incentivized)
			{
				this.Status = 2;
			}

			Prepare();
			this.onLaunchCalled = true;
			return CheckStatus();
		}
	}
}
