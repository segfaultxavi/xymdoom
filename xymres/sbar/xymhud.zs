class XYMHUD : DoomStatusBar
{
    override void Draw(int state, double TicFrac) {
        Super.Draw(state, TicFrac);

        if (state == HUD_StatusBar) {
            DrawImage("STXYM", (320, 168), DI_ITEM_OFFSETS, 1);
            DrawImage("XYMCA0", (323, 173), DI_ITEM_LEFT_TOP, 1, (14, 14));
            let xymcoin = XYMCoin(CPlayer.mo.FindInventory("XYMCoin"));
            let amount_confirmed = xymcoin != null ? xymcoin.mAmountConfirmed : 0;
            DrawString(mHUDFont, FormatNumber(amount_confirmed, 3), (380, 171), DI_TEXT_ALIGN_RIGHT);
            let amount = xymcoin != null ? xymcoin.Amount : 0;
            DrawString(mIndexFont , FormatNumber(amount,3), (379, 191), DI_TEXT_ALIGN_RIGHT);
        }
    }
}
