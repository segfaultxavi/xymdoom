# XYMDoom

Experiments with Doom and the Symbol blockchain:
Whenever you pick up an in-game XYM coin, your wallet receives a test XYM!

## Installation

* Install Python [`requirements.txt`](./requirements.txt).
* Install [GZDoom](https://zdoom.org/downloads) and Doom2.
* Edit [`.env`](./.env) to point to where you installed them.

    The default values work out-of-the-box if you install like this:

    ```text
    DOOM 2\
      doom2\
        DOOM2.WAD
    GZDoom\
      xymdoom\
        xymdoom.py
    ```

    If you leave the `DOOM2_WAD` variable empty, GZDoom will try to locate Doom2.

## Running

Then run `python xymdoom.py` from the root folder of xymdoom.
It will launch GZDoom, monitor its log file, and send keystrokes to it until you exit the game.

**Do not move focus away from GZDoom, or it will stop receiving commands!**

## Next Steps

Extremely preliminary! Only Windows supported.
Lots and lots of room for improvement. For example:

* Supporting other operating systems should be easy, since this is just a Python script.

* Show current wallet balance and update it periodically.

* Add doors which open by paying.

* A private key is published on GitHub. This is not a recommended best practice.
    It's test currency anyway.

Please don't take this code too seriously :)
