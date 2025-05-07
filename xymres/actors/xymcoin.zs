class XYMCoin : Inventory
{
  // These are confirmed coins.
  // Parent's Amount are unconfirmed (incoming).
  int mAmountConfirmed;

  // Wrapper communication.
  bool signals[2];

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
  }

  override bool CanPickup(Actor toucher) {
    let xymcoin = toucher.FindInventory("XYMCoin");
    let amount = xymcoin != null ? xymcoin.Amount : 0;
    // Do not allow picking up while there are coins waiting to be confirmed
    if (amount > 0) return false;
    return true;
  }

  override bool TryPickup(in out actor toucher) {
    // Message the wrapper
    Console.PrintfEx(PRINT_LOG, "Coin collected");
    return super.TryPickup(toucher);
  }

  override void Tick() {
    if (owner && owner.player) {
      let buttons = owner.player.cmd.buttons;
      // Signals back from the wrapper
      if ((buttons & BT_USER1) && !signals[0]) {
        console.printf("Wrapper signal 0: Confirming %d coins. Balance %d -> %d",
        Amount, mAmountConfirmed, mAmountConfirmed + Amount);
        mAmountConfirmed += Amount;
        Amount = 0;
      }
      if ((buttons & BT_USER2) && !signals[1]) {
        console.printf("Wrapper signal 1");
      }
      signals[0] = (buttons & BT_USER1);
      signals[1] = (buttons & BT_USER2);
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
