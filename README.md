This is a very limited example of how to use the new MultiplayerAPI class to have both client and server(s) running in the same Godot instance.

The file `scene/combo.tscn` demostrate how to have 4 independent RPC managers.

The file `scene/standalone.tscn` demostrate how you the same game logic can be use with the global RPC manager instead.

This way, you can make a simple scene to test your game networking without having to run multiple instances, but still ship the game with a single instance if you like without changing a single line of code.

Check out `script/custom_multiplayer.gd` for an explaination on how to create this magic.

There is much more cool stuff in the new MultiplayerAPI, but it's still in a process of stabilization. We will add more feature to this demo in the future.

Support Us
====

Like our work? [Buy our game](https://store.steampowered.com/app/679100/Aequitas_Orbis/), follow us on [twitter](https://twitter.com/aequitasorbis)
