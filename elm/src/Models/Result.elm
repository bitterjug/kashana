module Models.Result exposing (..)

import Components.Field as Field
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Encode
import Json.Decode as Jd
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


safePost : String -> String -> Http.Body -> Jd.Decoder a -> Http.Request a
safePost token url body decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-CSRFToken" token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
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
    | PostResponse Field.Msg (Result Http.Error ResultObject)


postResponseDecoder : Jd.Decoder ResultObject
postResponseDecoder =
    Jd.map7 ResultObject
        (Jd.field "id" Jd.int)
        (Jd.field "name" Jd.string)
        (Jd.field "description" Jd.string)
        (Jd.field "order" Jd.int)
        (Jd.field "level" Jd.int)
        (Jd.field "contribution_weighting" Jd.int)
        (Jd.field "log_frame" Jd.int)



{-
      The http request will use Http.post:

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
        postResult : Field.Msg -> Cmd Msg
        postResult msgBack =
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
                Http.post url resultBody postResponseDecoder
                    |> Http.send (PostResponse msgBack)

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
                    |> Maybe.map postResult
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

            PostResponse fieldMsg (Ok resultObject) ->
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

            PostResponse _ (Err httpError) ->
                -- For the time being, just log the error
                -- TODO: handle this properly by setting the error flag
                -- on all fields awaiting confirmation
                let
                    _ =
                        Debug.log "Error:" httpError
                in
                    model ! []

            Saved fieldMsg ->
                -- Ignores the resultObject for the time being, we'll need it
                -- when we're saving the placeholder in future
                -- TODO: see note in docs about using a dict as the underlying model
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
