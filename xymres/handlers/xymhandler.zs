class XYMEventHandler : EventHandler {

  override void WorldThingDied(WorldEvent e) {
    for (int i=0; i<4; i++) {
      Actor coin = Actor.Spawn("XYMCoin", e.thing.pos);
      if (coin != null) {
        coin.vel = (frandom(-2,2), frandom(-2,2), 8);
      }
    }
  }
}
