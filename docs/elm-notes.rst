
Passing initial values
======================

I made an app with a port and I set it up and send a value to the port
but it only works if I do it from the console after loading the app.
If I run it immediately after loading the page I don't see it, some
sort of race condition?

    app.ports.results.send(Aptivate.data.results)

Maybe I should be pasing these into the embed call like this:
https://github.com/evancz/elm-html-and-js
