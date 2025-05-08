# XYMDoom

Experiments with Doom and the Symbol blockchain.

Install GZDoom and Doom2. Then update [xymdoom.py](./xymdoom.py#L143) to point to
wherever you installed them.

Then run `python xymdoom.py` from the root folder.
It will launch GZDoom and monitor it until you exit the game.

**Whenever you pick up an in-game XYM coin, your wallet receives a test XYM!**

Extremely preliminary! Only Windows supported.
Lots and lots of room for improvement. For example:

* You need to wait until a coin is confirmed before you can pick up the next one.

    Coins could be batched, and have multiple transactions in-flight.

* Supporting other operating systems should be easy, since this is just a Python script.

* Could add command line parameters or a configuration file to provide paths to
    GZDoom and the doom2.wad, the private key of the treasury (where did you think
    the coins come from?), and the address of the wallet that receives them.

* Show current wallet balance and update it periodically.

* Add doors which open by paying.

* Enemies drop coins upon dying.

* A private key is embedded in the code and published on GitHub.
    This is not a recommended best practice.
    It's test currency anyway.

Please don't take this code too seriously :)
