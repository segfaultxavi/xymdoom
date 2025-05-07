class XYMCoin : Inventory
{
  // These are confirmed coins.
  // Parent's Amount are unconfirmed (incoming).
  int mAmountConfirmed;

  // Wrapper communication.
  bool mSignals[2];

  // To avoid flooding the console
  int mLastPrintTime;

  Default {
    Inventory.MaxAmount 999;
    Inventory.PickupMessage "You got a coin!";
    +NOGRAVITY
    +FLOATBOB
    Scale 0.25;
    FloatBobStrength 0.25;
  }

  override void BeginPlay() {
    Super.BeginPlay();
    mAmountConfirmed = 0;
    mLastPrintTime = -1000;
  }

  override bool CanPickup(Actor toucher) {
    let xymcoin = toucher.FindInventory("XYMCoin");
    let amount = xymcoin != null ? xymcoin.Amount : 0;
    // Do not allow picking up while there are coins waiting to be confirmed
    if (amount > 0) {
      if (level.time - mLastPrintTime >= 35) {
        Console.Printf("Can't pickup more coins until previous ones arrive");
        mLastPrintTime = level.time;
      }
      return false;
    }
    return true;
  }

  override bool TryPickup(in out actor toucher) {
    // Message the wrapper
    Console.PrintfEx(PRINT_LOG, "Collected %d coins", 1);
    return super.TryPickup(toucher);
  }

  override void Tick() {
    if (owner && owner.player) {
      let buttons = owner.player.cmd.buttons;
      // Signals back from the wrapper
      if ((buttons & BT_USER1) && !mSignals[0]) {
        mAmountConfirmed += Amount;
        Amount = 0;
      }
      if ((buttons & BT_USER2) && !mSignals[1]) {
        console.printf("Wrapper signal 1");
      }
      mSignals[0] = (buttons & BT_USER1);
      mSignals[1] = (buttons & BT_USER2);
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
