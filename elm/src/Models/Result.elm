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
    , order : Int
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
    , order = result.order
    }


modelToResultObject : Model -> ResultObject
modelToResultObject model =
    ResultObject
        model.id
        (Field.value model.name)
        (Field.value model.description)
        model.order
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
    , ( "order", Json.Encode.int result.order )
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


update : String -> Msg -> Model -> ( Model, Cmd Msg )
update csrfToken msg model =
    let
        postResult : Model -> Field.Msg -> Cmd Msg
        postResult model_ msgBack =
            let
                url =
                    "/api/logframes/"
                        ++ (Basics.toString model.logframeId)
                        ++ "/results"

                resultBody =
                    model_
                        |> modelToResultObject
                        |> resultToValueList
                        |> Json.Encode.object
                        |> Http.jsonBody
            in
                safePost csrfToken url resultBody postResponseDecoder
                    |> Http.send (PostResponse msgBack)

        saveResult : Field.Msg -> Cmd Msg
        saveResult msgBack =
            Process.sleep Time.second
                |> Task.perform (always (Saved msgBack))
    in
        case msg of
            NoOp ->
                model ! []

            UpdateName fieldMsg ->
                let
                    ( name_, maybeFieldMsg ) =
                        Field.update_ fieldMsg model.name

                    model_ =
                        { model | name = name_ }

                    cmd =
                        maybeFieldMsg
                            |> Maybe.map (postResult model_)
                            >> Maybe.withDefault Cmd.none
                in
                    ( model_, cmd )

            UpdateDescription fieldMsg ->
                let
                    ( description_, maybeFieldMsg ) =
                        Field.update_ fieldMsg model.description

                    model_ =
                        { model | description = description_ }

                    cmd =
                        maybeFieldMsg
                            |> Maybe.map (postResult model_)
                            >> Maybe.withDefault Cmd.none
                in
                    ( model_, cmd )

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
