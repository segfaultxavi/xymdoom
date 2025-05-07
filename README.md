# XYMDoom

Experiments with Doom and the Symbol blockchain.

Install GZDoom and Doom2. Then update [xymdoom.py](./xymdoom.py#L143) to point to
wherever you installed them.

Then run `python xymdoom.py`, it will launch GZDoom with the right parameters.

**Whenever you pick up an in-game XYM coin, your wallet receives a test XYM!**

Extremely preliminary! Only Windows supported.
Lots and lots of room for improvement. For example:

* You need to wait until a coin is confirmed before you can pick up the next one.
    Coins could be batched, and have multiple transactions in-flight.
