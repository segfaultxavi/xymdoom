class XYMCoin : Inventory
{
  enum  EXYMState : int {
    State_Command,
    State_Balance
  };

  // Command: int4
  // 0000: Confirm incoming coins
  // 0001: Balance update. Parameters: balance (int8)

  // These are confirmed coins.
  // Parent class' Amount are unconfirmed (incoming).
  int mAmountConfirmed;
  // To avoid flooding the console
  int mLastPrintTime;
  // Ticks before requesting confirmation
  int mConfirmationDelay;
  // Some incoming coins are being confirmed. Can't pick any more up.
  bool mConfirming;

  // Wrapper communication.
  bool mSignals[2];
  int mIncomingValue;
  int mIncomingCount;
  EXYMState mState;

  Default {
    Inventory.MaxAmount 999;
    Inventory.PickupMessage "You got a coin!";
    +FLOATBOB
    Scale 0.25;
    FloatBobStrength 0.25;
  }

  override void BeginPlay() {
    Super.BeginPlay();
    mAmountConfirmed = 0;
    mLastPrintTime = -1000;
    mConfirmationDelay = 0;
    mConfirming = false;
    mState = State_Command;
    mIncomingValue = 0;
    mIncomingCount = 0;
  }

  override bool CanPickup(Actor toucher) {
    // Do not allow picking up while there are coins waiting to be confirmed
    let xymcoin = XYMCoin(toucher.FindInventory("XYMCoin"));
    if (xymcoin == null) return true; // Allow picking up the first one
    if (xymcoin.mConfirming && (level.time - mLastPrintTime >= 35)) {
      Console.Printf("Can't pickup more coins until previous ones arrive");
      mLastPrintTime = level.time;
    }
    return !xymcoin.mConfirming;
  }

  override bool TryPickup(in out actor toucher) {
    let xymcoin = XYMCoin(toucher.FindInventory("XYMCoin"));
    if (xymcoin == null) {
      // This is the first collected coin, which will become the inventory manager
      xymcoin = self;
    }
    // Reset the inventory manager coin timer
    xymcoin.mConfirmationDelay = 100;
    return super.TryPickup(toucher);
  }

  void ReceiveBit(int value) {
    mIncomingValue = mIncomingValue * 2 + value;
    mIncomingCount++;
    Console.Printf("Got bit %d. State %d inValue %d inCount %d", value, mState, mIncomingValue, mIncomingCount);
  }

  void HandleCommand(int command) {
    Console.Printf("Received command %d", command);
    switch (command) {
      case 0:
        mAmountConfirmed += Amount;
        Amount = 0;
        mConfirming = false;
        mState = State_Command;
        mIncomingValue = 0;
        mIncomingCount = 0;
        A_StartSound ("dingin", CHAN_AUTO);
        break;
    }
  }

  void HandleComms(int buttons) {
    // Signals from the wrapper
    if ((buttons & BT_USER1) && !mSignals[0]) {
      ReceiveBit(0);
    }
    if ((buttons & BT_USER2) && !mSignals[1]) {
      ReceiveBit(1);
    }
    mSignals[0] = buttons & BT_USER1;
    mSignals[1] = buttons & BT_USER2;

    // Process received bits
    switch (mState) {
      case State_Command:
        if (mIncomingCount == 4) {
          HandleCommand(mIncomingValue);
        }
        break;
      case State_Balance:
        break;
    }
  }

  override void Tick() {
    // Request confirmations
    if (!mConfirming && mConfirmationDelay > 0) {
      mConfirmationDelay--;
      if (mConfirmationDelay == 0) {
        // Message the wrapper
        Console.PrintfEx(PRINT_LOG, "Collected %d coins", Amount);
        A_StartSound ("dingout", CHAN_AUTO);
        mConfirming = true;
      }
    }
    // Wrapper communication
    if (owner && owner.player) {
      HandleComms(owner.player.cmd.buttons);
    }
    super.Tick();
  }

  States
  {
  Spawn:
    XYMC ABCD 6;
    Loop;

  Pickup:
    TNT1 A 0;
    Stop;
  }
}
