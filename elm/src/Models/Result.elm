module Models.Result exposing (..)

import Components.Field as Field
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Encode
import Process
import Task
import Time


type alias Model =
    { id : Int
    , logframeId : Int
    , name : Field.Model
    , description : Field.Model
    }


type alias ResultObject =
    -- Type of the Aptivate.results objects used to initialize the app
    { id : Int
    , name : String
    , description : String
    , order :
        Int
        -- parent: null,
    , level : Int
    , contribution_weighting :
        Int
        -- "risk_rating": null,
        -- "rating": null,
    , log_frame :
        Int
        -- "indicators": [],
        -- activities: List ActivityId
        -- "assumptions": []
    }


initModel : ResultObject -> Model
initModel result =
    { id = result.id
    , logframeId = result.log_frame
    , name = Field.initModel "Name" result.name
    , description = Field.initModel "Description" result.description
    }


modelToResultObject : Model -> ResultObject
modelToResultObject model =
    ResultObject
        model.id
        (Field.value model.name)
        (Field.value model.description)
        0
        -- order
        0
        -- level
        0
        -- contribution_weighting
        model.logframeId


resultToValueList : ResultObject -> List ( String, Json.Encode.Value )
resultToValueList result =
    [ ( "id", Json.Encode.int result.id )
    , ( "name", Json.Encode.string result.name )
    , ( "description", Json.Encode.string result.description )
      -- skip a bit, brother
    , ( "log_frame", Json.Encode.int result.log_frame )
    ]


type Msg
    = UpdateName Field.Msg
    | UpdateDescription Field.Msg
    | Saved Field.Msg
    | NoOp



{-
      The http request will use Http.post:

      post : Decoder value -> String -> Body -> Task Error value

      The post task will return either Http.Error or our decoded Json value.
      And wehave to turn both these into Cmd

      - The Error should trigger some sort of UI report -- does Kashana do this
        or fail silently?

      - The value should just confirm that the save has happened okay.

      - In the case where we're saving a Result for the first time, we might
        need to get the id generated by the server.

       So, we need:
       - The url for the post to results: url
       - [ ] A type to talk about the stuf that comes back from the server
       in response to a successful post message.

               type PostResponse =
                   ...

       - [ ] A Json decoder for whatever comes back from the API. Turns out this
       is the same: Json description of the whole Result object. So we need to
       work out how to decode records in Json.
       According to [the docs](https://guide.elm-lang.org/interop/json.html)
       it looks like the newer version of Json.Decode has better tools for
       all this than I currently do in 0.17. /sadface/ So upgrading to 0.18
       is becoming next priority.

       postResponseDecoder =
           Json.Decoder PostResponse

        See Jsontest.Jt

       - [ ] New case in the Msg for handling the result of the POST. The Jason
         payload shold be decoded into a ResultObject. Or the Post might fail
         with an http error:

           , ...
           , PostResponse Field.Msg (Result Http.Error ResultObject)


           The handler case for this will switch on success or failure and act
           accordingly. For success it will forward the field.Msg to the appropriate
           field: effectively the same as Saved does at the moment.

           We're going to change our `Task.perform` into a `Task.attempt`.
           At the moment, the fake request returns no data.  So there is
           nothing to handle other than the fact that a post has been made, and
           Im assuming that it has been successful.  Thus below we find:

               |> Task.perform  (always (Saved msgBack))
                                ^^^^^^^^^^^^^^^^^^^^^^^^
           Which ignores any parameter and just returns the Saved msgBack
           message, which will pass on msgBack to the field.

           When we get someting back from the server, we may need to
           process the returned data at least to extract the id.

           <task>
               |> Task.attempt  (PostResponse msgBack)

       - [x] A way to turn a Request object into Json string to serve as the body
       (payload) of the post request:  resultBody

   -- And then we write something like:

   postResult : Model -> Field.Msg -> Cmd.Msg
   postRes model msgBack =
       let
           url =
               "/api/logframes/"
                   ++ (Basics.toString model.logframeId)
                   ++ "/results"

           resultBody =
               model
                   |> modelToResultObject
                   |> resultToValueList
                   |> Json.Encode.object
                   |> Http.jsonBody
       in
           Http.post postResponseDecoder url resultBody
               |> Task.attempt (PostResponse msgBack)


-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        saveResult : Field.Msg -> Cmd Msg
        saveResult msgBack =
            Process.sleep Time.second
                |> Task.perform (always (Saved msgBack))

        updateField : Field.Msg -> Field.Model -> ( Field.Model, Cmd Msg )
        updateField msg field =
            -- Update a field. Using update', if the stored value changed,
            -- we get back a Just msg (as maybeFieldMsg) to send to the field
            -- when we've processed the change (i.e. saved it to the server);
            -- otherwise Nothing.  We turn maybeFieldMsg into the Cmd side
            -- effect: Cmd.none for Nothing, saveReslt msg for the other case.
            let
                ( fieldUpd, maybeFieldMsg ) =
                    Field.update_ msg field
            in
                ( fieldUpd
                , maybeFieldMsg
                    |> Maybe.map saveResult
                    >> Maybe.withDefault Cmd.none
                )
    in
        case msg of
            NoOp ->
                model ! []

            UpdateName fieldMsg ->
                let
                    ( name_, cmd ) =
                        updateField fieldMsg model.name
                in
                    ( { model | name = name_ }, cmd )

            UpdateDescription fieldMsg ->
                let
                    ( description_, cmd ) =
                        updateField fieldMsg model.description
                in
                    ( { model | description = description_ }, cmd )

            Saved fieldMsg ->
                -- simulate http request with sleep
                -- needs the whole model which I'm just logging for the moment
                -- TODO: we're calling saved on all fields. MAybe we can get
                -- away with doing that only for the field that changed?
                -- TODO: We shouldn't really update all these fields, only the
                -- ones we know to have changed. Now, how do w do that?
                let
                    _ =
                        Debug.log "saved" model

                    ( name_, nameCmd ) =
                        Field.update fieldMsg model.name

                    ( description_, descCmd ) =
                        Field.update fieldMsg model.description
                in
                    { model
                        | name = name_
                        , description = description_
                    }
                        ! [ Cmd.map UpdateName nameCmd
                          , Cmd.map UpdateDescription descCmd
                          ]


renderName : Field.Renderer
renderName atts value =
    let
        classes =
            classList
                [ ( "heading", True )
                , ( "editable", True )
                ]
    in
        h2 (classes :: atts) [ text value ]


renderDescription : Field.Renderer
renderDescription atts value =
    div ((class "editable") :: atts) [ text value ]


render : Model -> Html Msg
render result =
    div [ class "overview-main" ]
        [ div [ class "result-tree" ]
            [ div [ class "result-overview level-1" ]
                [ table [ class "result-overview-table" ]
                    [ tbody []
                        [ tr []
                            [ td
                                [ classList
                                    [ ( "overview-minmax", True )
                                    , ( "unselectable", True )
                                    ]
                                ]
                                [ span [ class "toggle-triangle" ] [ text "▶" ]
                                ]
                            , td [ class "overview-title" ]
                                [ div
                                    [ classList
                                        [ ( "ribbon", True )
                                        , ( "ribbon-result", True )
                                        ]
                                    ]
                                    [ Html.map UpdateName <|
                                        Field.view renderName result.name
                                    ]
                                ]
                            , td [ class "overview-manage" ]
                                [ a [ href ".", class "edit-result" ]
                                    [ text "Edit" ]
                                , a [ href ".", class "monitor-result" ]
                                    [ text "Monitor" ]
                                ]
                            , td [ class "overview-description" ]
                                [ Html.map UpdateDescription <|
                                    Field.view renderDescription result.description
                                ]
                            , td [ class "overview-rating" ]
                                [ div [ class "result-rating" ]
                                    [ div
                                        [ classList
                                            [ ( "display-rating-value", True )
                                            , ( "notrated", True )
                                            ]
                                        ]
                                        []
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
