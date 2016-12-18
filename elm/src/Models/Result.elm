module Models.Result exposing (..)

import Api
import Components.Field as Field
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Encode
import Json.Decode as Jd
import Process
import Models.ResultObject as ResultObject
import Task
import Time


type alias Flags =
    { logframeId : Int
    , csrfToken : String
    }


type alias Model =
    { id : Int
    , logframeId : Int
    , name : Field.Model
    , description : Field.Model
    , order : Int
    }


initModel : ResultObject.Model -> Model
initModel result =
    { id = result.id
    , logframeId = result.log_frame
    , name = Field.initModel "Name" result.name
    , description = Field.initModel "Description" result.description
    , order = result.order
    }


modelToResultObject : Model -> ResultObject.Model
modelToResultObject model =
    ResultObject.Model
        model.id
        (Field.value model.name)
        (Field.value model.description)
        model.order
        0
        -- level
        0
        -- contribution_weighting
        model.logframeId


type Msg
    = UpdateName Field.Msg
    | UpdateDescription Field.Msg
    | Saved Field.Msg
    | NoOp
    | PostResponse Field.Msg (Result Http.Error ResultObject.Model)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    let
        postResult : Model -> Field.Msg -> Cmd Msg
        postResult model_ msgBack =
            let
                resultBody =
                    model_
                        |> modelToResultObject
                        |> ResultObject.encode
                        |> Http.jsonBody

                url =
                    "/api/logframes/"
                        ++ (Basics.toString flags.logframeId)
                        ++ "/results/"
                        ++ toString model_.id
            in
                Api.put flags.csrfToken url resultBody ResultObject.decode
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
