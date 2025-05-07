class XYMCoin : Inventory
{
  // These are confirmed coins.
  // Parent's Amount are unconfirmed (incoming).
  int mAmountConfirmed;

  Default
  {
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

  override bool TryPickup(in out actor toucher)
  {
    Console.PrintfEx(PRINT_LOG, "Coin collected");
    return super.TryPickup(toucher);
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
