# Tictac

https://tictac.fly.dev/

A mostly complete but still work-in-progress multiplayer tictactoe server.

Things left to do:

- Cleanup game servers after their is nobody left looking at them, using presence
- List of active games on the home screen

Maybe things in the future:

- More pretty
- Ultimate tictactoe

To start the Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Then visit [`localhost:4000`](http://localhost:4000) in your browser.

---

Thanks to dkarter for the [king_of_tokyo](https://github.com/dkarter/king_of_tokyo) repo / [talk on said repo](https://www.youtube.com/watch?v=0UnLZlMr1Ug) for some great initial pointers on the structure of the GenServers / how LiveView fits into the picture.
