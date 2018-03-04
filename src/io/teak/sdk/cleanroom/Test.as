package io.teak.sdk.cleanroom
{
	public class Test
	{
		private var onDeepLinkCalled:Boolean = false;
		private var onRewardCalled:Boolean = false;
		private var onLaunchCalled:Boolean = false;

		public var Status:int = 0;
		public var Error:String = null;
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
				this.Error = "Deep Link: should be '" + this.VerifyDeepLink + "' found: '" + parameters.data + "'";
				this.Status = 2;
			}

			Prepare();
			this.onDeepLinkCalled = true;
			return CheckStatus();
		}

		public function OnReward(parameters:Object):Boolean
		{
			if(!parameters.teakRewardId || parameters.teakRewardId === "") {
				this.Error = "Reward: teakRewardId is null or empty";
				this.Status = 2;
			}

			if(!parameters.teakCreativeName || parameters.teakCreativeName !== this.CreativeId)
			{
				this.Error = "Reward: teakCreativeName mismatch, should be '" + this.CreativeId + "' found: '" + parameters.teakCreativeName + "'";
				this.Status = 2;
			}
			else if (this.VerifyReward && JSON.stringify(this.VerifyReward) !== JSON.stringify(parameters.reward))
			{
				this.Error = "Reward: reward mismatch, should be '" + JSON.stringify(this.VerifyReward) + "' found: '" + JSON.stringify(parameters.reward) + "'";
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
				this.Error = "Notification Launch: teakCreativeName mismatch, should be '" + this.CreativeId + "' found: '" + parameters.teakCreativeName + "'";
				this.Status = 2;
			}
			else if(this.VerifyReward && !parameters.incentivized)
			{
				this.Error = "Notification Launch: 'incentivized' was false, should have been true";
				this.Status = 2;
			}

			Prepare();
			this.onLaunchCalled = true;
			return CheckStatus();
		}
	}
}
