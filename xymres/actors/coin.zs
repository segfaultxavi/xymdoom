class CCoin : Inventory
{
  Default
  {
    Inventory.MaxAmount 999;
    Inventory.PickupMessage "You got a coin!";
    +NOGRAVITY
    +FLOATBOB
    +INVENTORY.ALWAYSPICKUP
    Scale 0.25;
    FloatBobStrength 0.25;
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
