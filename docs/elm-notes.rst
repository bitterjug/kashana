
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

I wonder if we need a module to define the types for Result, and separate 
modules to define different views on results. E.g. the dashboard result view.

States for fields and models
----------------------------

Js version has editing state.  And elm version has saving state: awaiting
response from server. Js version also appears to have this state, because it
has separate css. What's the intersection of these two states? Can you edit
an element which is awaiting a server response, and what does that mean 
for the pending request? 

Can you cancel or ignore a previous update request when you make a new one?
Perhaps not, since it's already sent on the wire. We can only respond to what
the server sends us.

And in a sense when we update a single field, we are really awaiting all the
fields from the server, since any or all of them might have changed if someone
else edited the same resource at the same time we did. Should we grey out all 
fields on the Result while we await the servers response, in case any of them
changed?

I mean what happens to the state of a field that we're editing (in edit state) 
when an updated Response comes in from the server with a different value for
that field than the one we started editing? Which wins? 

- Server wins, and the app discards our  edits to date 
- We win and the app discards or ignores the new value from the server
- Neither, and the app reports the situation as an error (new version of this
  field is available...)

Here's the problem broken down:

- Edit a field and press Enter, the field changes to "saving" (shows crosshatch)
- Before the server responds (slow server, simulate by Control-zedding the
  server process) re-edit the field. Save new result. Still shows saving.
- Server wakes up (fg server process).
- First response from server, app updates the field to normal styling -- no 
  crosshatching.
Oops! We lost integrity of the updating status
- Second server response arrives. Okay, we update the field contents but there
  was no indicator that we were still awaiting this response.

Do we need to send a token, or hash, with each edit to say what we're awaiting?
Like a sliding window protocol, we're awaiting an Ack for edit 36, etc.?


What is the model for Result
-----------------------------

In my toy model of Kashana the model for Result comprises only and all its
component fields. In Elm I'm feeling like I want to keep a copy of the record
that corresponds to the js object we get from the server, and keep it in sync
with the contents of the fields. This kinda similar to how the input field
stores the value and the input value as separate values. That might be 
necessary, in fact, while we're waiting for server reply, but won't we end
up with lots of duplicated state that way?

2016-07-10
---------

I just wired up the Field model into the kashana app.

- [ ] The field's initial value doesn't seem to be getting initialized properly
  from the model.  Although it shows the word Goal when you load the page, that
  doesn't seem to be the default value to return to

- [x]  Maybe the problem is with the escape key not doing reset properly. Need
  to look into that.

  - Looks like Escape no longer gets registered as a keystroke, though it did
    in the original input component.  But it does take the focus out of the
    input. Now we don't know if it was defocused by an escape or because we
    clicked outside.

  - IS this because of the html we're rendering the thing with? Where does the escape go?

  - IT was just bloody Vimium stealing the escape key. Create exclusion rule for it.

- [ ] The top level wiring applies all changes to results to all elements of
  the results list. That needs to be fixed to treat individual elements
  separately, and have a placeholder for new entries.


Build
-----

elm-make src/dashboard.elm  --output build/dashboard.js

http://127.0.0.1:8000/dashboard-elm/test/
