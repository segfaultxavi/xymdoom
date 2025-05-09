class XYMCoin : Inventory
{
  enum  EXYMState : int {
    // Receiving or waiting for a command
    State_Command,
    // Receiving or waiting for a balance
    State_Balance,
    // Receiving or waiting for a door id
    State_Door_Id,
    // Receiving or waiting for amount of coins to return
    State_Amount_Return,
  };

  enum EXYMCommand : int {
    Command_Confirm = 0, // Confirm incoming coins
    Command_Balance = 1, // Balance update. Parameters: balance (int8)
    Command_Open_Door = 2, // Open door. Parameters: door id (int8)
    Command_Return_Coins = 3 // Return coins to map. Parameters: amount (int8)
  };

  // These are confirmed coins.
  // Parent class' Amount are unconfirmed (incoming).
  int mAmountConfirmed;
  // To avoid flooding the console
  int mLastPrintTime;
  // Ticks before requesting confirmation
  int mConfirmationDelay;
  // Some incoming coins are being confirmed. Can't pick any more up.
  bool mConfirming;
  // Periodically request a balance update
  int mBalanceUpdateDelay;

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
    mBalanceUpdateDelay = 0;
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
    // Reset the inventory manager coin timer, if there's anything to request
    if (Amount > 0)
      xymcoin.mConfirmationDelay = 100;
    return super.TryPickup(toucher);
  }

  void ReceiveBit(int value) {
    mIncomingValue = mIncomingValue * 2 + value;
    mIncomingCount++;
    //Console.Printf("Got bit %d. State %d inValue %d inCount %d", value, mState, mIncomingValue, mIncomingCount);
  }

  void HandleCommand(int command) {
    Console.PrintfEx(PRINT_LOG, "Received command %d", command);
    switch (command) {
      case Command_Confirm:
        mAmountConfirmed += Amount;
        Amount = 0;
        mConfirming = false;
        mState = State_Command;
        A_StartSound ("dingin", CHAN_AUTO);
        break;
      case Command_Balance:
        mState = State_Balance;
        break;
      case Command_Open_Door:
        mState = State_Door_Id;
        break;
      case Command_Return_Coins:
        mState = State_Amount_Return;
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
          let command = mIncomingValue;
          mIncomingValue = 0;
          mIncomingCount = 0;
          HandleCommand(command);
        }
        break;
      case State_Balance:
        if (mIncomingCount == 8) {
          mAmountConfirmed = mIncomingValue;
          Console.PrintfEx(PRINT_LOG, "Balance is %d", mAmountConfirmed);
          mIncomingValue = 0;
          mIncomingCount = 0;
          mState = State_Command;
        }
        break;
      case State_Door_Id:
        if (mIncomingCount == 8) {
          let door_id = mIncomingValue;
          Console.Printf("Opening door");
          // Call script 2 which will open the door (and leave it open)
          ACS_Execute(2, 0, door_id, 0, 0);
          mIncomingValue = 0;
          mIncomingCount = 0;
          mState = State_Command;
        }
        break;
      case State_Amount_Return:
        if (mIncomingCount == 8) {
          // Transaction failed, return coins to the map
          Console.Printf("Transaction error!");
          for (int i=0; i<mIncomingValue; i++) {
            let hor = (owner.player.mo.Angle + frandom(-45, 45)).ToVector(owner.player.mo.Pitch);
            Vector3 vel = (hor.x, hor.y, 1);
            vel *= 4;
            Actor coin = Actor.Spawn("XYMCoin", owner.player.mo.pos + vel);
            if (coin != null) {
              coin.vel = vel;
            }
          }
          Amount = 0;
          mConfirming = false;
          mIncomingValue = 0;
          mIncomingCount = 0;
          mState = State_Command;
        }
        break;
    }
  }

  override void Tick() {
    // Only the inventory manager ticks
    if (!owner || !owner.player) {
      super.Tick();
      return;
    }

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

    // Periodic balance requests, in case it is updated externally
    mBalanceUpdateDelay--;
    if (mBalanceUpdateDelay < 0) {
      mBalanceUpdateDelay = 850; // Every 30s
      Console.PrintfEx(PRINT_LOG, "Balance request");
    }

    // Wrapper communication
    HandleComms(owner.player.cmd.buttons);

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
