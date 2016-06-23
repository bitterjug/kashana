
Passing initial values
======================

I made an app with a port and I set it up and send a value to the port but it
only works if I do it from the console after loading the app.  If I run it
immediately after loading the page I don't see it, some sort of race condition?

    app.ports.results.send(Aptivate.data.results)

Maybe I should be pasing these into the embed call like this:
https://github.com/evancz/elm-html-and-js

What is the model?
------------------

In the backbone version, each field has a ref to the model object and the name
of the attribute for which it is responsible.  And the `field.js` takes
responsibility for saving the model when an field is changed. 

In Elm Ive so far given an input field a model comprising only the state it
needs to know about. And it passes "up" information about an updating
effectively changing the field. The "parent" view has responsibility for the
model object (record) and can chose to save, e.g. it could do validation or
cache changes, or enact transactions.

In Js the field has an editing state and a not-editing state and it renders
differently for each case. It only renders with an `<input>` element (or
suitable other element) when its in editing mode. And I guess (not verified)
the css works on this assumption.

So I think I want an augmented version of my current Elm input model
that has editing mode as part of its state. 

What to use for the higher level models? 

- There should be a view for a result, that knows about the result object
  (record). This decomposes into fields for the attributes.

- There should probably be a view for the "dashboard" page as a whole, with a
  result view in it.

