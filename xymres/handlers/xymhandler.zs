class XYMEventHandler : EventHandler {

  // Spawn coins when anything dies
  override void WorldThingDied(WorldEvent e) {
    for (int i=0; i<4; i++) {
      Actor coin = Actor.Spawn("XYMCoin", e.thing.pos);
      if (coin != null) {
        coin.vel = (frandom(-2,2), frandom(-2,2), 8);
      }
    }
  }

  // Give initial XYM coin to act as inventory manager
  override void PlayerEntered (PlayerEvent e) {
    players[e.PlayerNumber].mo.GiveInventory("XYMCoin", 0);
  }

  // Manual handling of XYM doors
  override void WorldLineActivated (WorldEvent e) {
    if (e.ActivationType != SPAC_Use) return;
    let activator = e.Thing;
    let line = e.ActivatedLine;
    if (line.special == 80 && line.args[0] == 1) {
      // Linedefs using the dummy script 1 are XYM doors
      let price = line.args[2];
      let xymcoin = XYMCoin(activator.FindInventory("XYMCoin"));
      if (xymcoin == null) return;
      if (xymcoin.mAmountConfirmed < price) {
        activator.A_Log("Insufficient balance");
        return;
      }
      activator.A_Log("Transaction in progress...");
      line.sidedef[0].SetTexture(Side.Top, line.sidedef[0].GetTexture(Side.Bottom));
      Console.PrintfEx(PRINT_LOG, "Pay %d coins to open door %d",
        line.args[2], line.backsector.GetTag(0));
      xymcoin.mAmountConfirmed -= price;
    }
  }
}
