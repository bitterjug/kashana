

What is the model?
------------------

In the backbone version, each field has a ref to the model object and the name
of the attribute for which it is responsible.  And the `field.js` takes
responsibility for saving the model when an field is changed. 

In Elm I've so far given an input field a model comprising only the state it
needs to know about. And it passes "up" information about an updating
effectively changing the field. The "parent" view has responsibility for the
model object (record) and can chose to save, e.g. it could do validation or
cache changes, or enact transactions.

States for fields and models
----------------------------

Can you cancel or ignore a previous update request when you make a new one?
Perhaps not, since it's already sent on the wire. We can only respond to what
the server sends us.

And, in a sense, when we update a single field, we are really awaiting all the
fields from the server, since any or all of them might have changed if someone
else edited the same resource at the same time we did. Should we grey out all 
fields on the Result while we await the servers response, in case any of them
changed?

I mean, what happens to the state of a field that we're editing (in edit state) 
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

Or maybe at least send he field id. At the moment we use cases in the Message
type for updates to any of the fields. But this duplicates the structure of the 
record in the message type which is probably redundant. And in any case we have
a second record which is a version of the original record with the editable
fields replaced with field. How about an abstraction something like a django
form which comprises a dictionary of field names and the corresponding field
object? Then we could probably simplify handling of the update messages AND
the Saved message passing the field name around as an extra parameter. 
- It introduces a new failure case where we get a string that doesn't
  correspond to one of our actual fields. But it might end up with less code.

TODO:
=====

- [x] The field's initial value doesn't seem to be getting initialized properly
  from the model.  Although it shows the word Goal when you load the page, that
  doesn't seem to be the default value to return to

- [x]  Maybe the problem is with the escape key not doing reset properly. Need
  to look into that.

  - Looks like Escape no longer gets registered as a keystroke, though it did
    in the original input component.  But it does take the focus out of the
    input. Now we don't know if it was defocused by an escape or because we
    clicked outside.

  - IS this because of the html we're rendering the thing with? Where does the
    escape go?

  - IT was just bloody Vimium stealing the escape key. Create exclusion rule
    for it.

- [x] There is a state machine problem with escape to reset a field. If you
  edit a field and press escape it puts back the initial value, and renders as
  H2 again, but the colour stays orange as if pending results of the save which
  we didn't actually do. So something is not being reset properly. I suspect the
  problem is that: on Blur does latch which sets saving to true whether or not
  the value has changed. But the effect to do a save, which does Saved only
  gets executed if the value has changed. In fact at the moment the Field
  component has two ways to trigger Latch (onBlur and onKeydown 13) but no way
  to trigger Saved and set saving = False. To do that the client has to call
  its Field.saved function.

  Fixed by moving the logic to test if a field value has changed back inside
  the Field module, where we now only set `saving=True`	if the value changed.
  This has several nice-feeling side-effects on the coupling as the parent
  no longer needs to know the details of Field's Msg type. Or of the fields
  inside its model record. Win win!

- [x] The top level wiring applies all changes to Results to all elements of
  the results list. That needs to be fixed to treat individual Results
  separately, 

- [x] Fix CSRF forgery warning from server

  Need to add token param to Result.update and pass down from dashboard.
  Dashoard gets it from initWithFlags and stores in global scope.

- [x] Upgrade to Elm 0.18 

- [x] Use Http.jsonBody in the post request.

- [x] Make a real POST request to the server when we update a field.
   The http request will use Http.post::

   post : Decoder value -> String -> Body -> Task Error value

  So, we need:
  - [x] The url for the post to results: url
  - [x] A type to talk about the stuf that comes back from the server in
        response to a successful post message. This turns out to be json
        encding of ResltObject, and gets decoced by one of the parameters
        to Post. So we don't need a new type for it.
  - [x] A Json decoder for whatever comes back from the API: postResponseDecoder
  - [x] A way to turn a Request object into Json string to serve as the
        body (payload) of the post request:  resultBody
  - [x] New case in the Msg for handling the result of the POST.
        The Jason payload shold be decoded into a ResultObject.
        Or the Post might fail with an http error: PostResponse
  - [x] New handler in update for PostResponse: The handler case for this
        will switch on success or failure and act accordingly.

- [x] Change the logic of `updateField`. At the moment `postResult` refers to
  the bound `model` from update. (I just refactored that a bit so it gets
  passed in in `updateField`, but its the same problem, its the model before
  the change that we're sending off. We need instead to send the post-change
  model off. So we need to separate the bit of `updateField` that updates the
  field and gets back the `maybeFieldMsg` from the bit that maps `postResult`
  over it to create the `Cmd`.

  Something like::

    let
      (name_, maybeFieldMsg) = Field.update_ msg field
      model_ = { model | name = name_ }
      cmd = maybeFieldMsg 
        |> Maybe.map (postResult model_) 
        >> Maybe.withDefault Cmd.none


- [x] At the moment the post request appears to be creating a new object each
  time. So I think we're doing something wrong with the Result.id. They keep 
  incrementing. Turned out to be because we were using POST. The proper thing
  to do to update an existing object is PUT to its endpoint.
  
- [x] Refactor and pull all the `ResultObject` stuff out into its own module.

- [ ] have a placeholder for new Results. And use POST to create a new object 
  when we are sending the placeholder's contents.

- [ ] The Success class on fields should stay for 2 seconds and then fade.
  Got the timer to remove the tag but it looks a bit sudden, maybe the 
  CSS transitions don't work when you splice in new bits of the DOM like
  Elm's shadow DOM does.

- [ ] Adding the class attributes to do the formatting above broke the default
  classes because now there are 2 sets of `Attribute Msg` being combined
  naively with concatenation, but each contain `className` specifiers that
  aren't being combined. Question with Elm mail list.

- [ ] At present I call the Saved updater on all fields of a Result when the
  (Fake) server confirms it has saved the value successfully. This _might_ be
  necessary ?? But I think we ought really to only be doing the Field.Msg.Saved
  update on the field from which the save Cmd originated.

- [ ] Looks like it might be possible (not sure if desirable) to separate the
  logic for saving the data in a field from the rest of field's behaviour. 
  might make the views messy if the saved field is in a wrapper record.

- There's supposed to be some HTML filtering

Build
-----

elm-make src/dashboard.elm  --output build/dashboard.js

http://127.0.0.1:8000/dashboard-elm/test/
