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


type alias ID =
    Int


type alias Flags =
    { logframeId : Int
    , csrfToken : String
    }


type alias Model =
    ( ID, ResultFields )


type alias ResultFields =
    { logframeId : Int
    , name : Field.Model
    , description : Field.Model
    , order : Int
    }


hasId : ID -> Model -> Bool
hasId id ( modelId, _ ) =
    modelId == id


fromResultObject : ResultObject.Model -> ResultFields
fromResultObject result =
    { logframeId = result.log_frame
    , name = Field.initModel "Name" result.name
    , description = Field.initModel "Description" result.description
    , order = result.order
    }


fromScratch : Flags -> ResultFields
fromScratch flags =
    { logframeId = flags.logframeId
    , name = Field.initModel "Name" ""
    , description = Field.initModel "Description" ""
    , order = 0
    }


initModel : ResultObject.Model -> Model
initModel result =
    ( result.id, fromResultObject result )


modelToResultObject : Model -> ResultObject.Model
modelToResultObject ( id, result ) =
    ResultObject.Model
        id
        (Field.value result.name)
        (Field.value result.description)
        result.order
        0
        -- level
        0
        -- contribution_weighting
        result.logframeId


type Msg
    = UpdateName Field.Msg
    | UpdateDescription Field.Msg
    | Saved Field.Msg
    | NoOp
    | PostResponse Field.Msg (Result Http.Error ResultObject.Model)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg ( id, result ) =
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
                        ++ toString id
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
                ( id, result ) ! []

            UpdateName fieldMsg ->
                let
                    ( name_, maybeFieldMsg ) =
                        Field.update_ fieldMsg result.name

                    result_ =
                        { result | name = name_ }

                    cmd =
                        maybeFieldMsg
                            |> Maybe.map (postResult ( id, result_ ))
                            >> Maybe.withDefault Cmd.none
                in
                    ( ( id, result_ ), cmd )

            UpdateDescription fieldMsg ->
                let
                    ( description_, maybeFieldMsg ) =
                        Field.update_ fieldMsg result.description

                    result_ =
                        { result | description = description_ }

                    cmd =
                        maybeFieldMsg
                            |> Maybe.map (postResult ( id, result_ ))
                            >> Maybe.withDefault Cmd.none
                in
                    ( ( id, result_ ), cmd )

            PostResponse fieldMsg (Ok resultObject) ->
                let
                    _ =
                        Debug.log "saved" result

                    ( name_, nameCmd ) =
                        Field.update fieldMsg result.name

                    ( description_, descCmd ) =
                        Field.update fieldMsg result.description
                in
                    ( id
                    , { result
                        | name = name_
                        , description = description_
                      }
                    )
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
                    ( id, result ) ! []

            Saved fieldMsg ->
                -- Ignores the resultObject for the time being, we'll need it
                -- when we're saving the placeholder in future
                -- TODO: see note in docs about using a dict as the underlying model
                let
                    _ =
                        Debug.log "saved" result

                    ( name_, nameCmd ) =
                        Field.update fieldMsg result.name

                    ( description_, descCmd ) =
                        Field.update fieldMsg result.description
                in
                    ( id
                    , { result
                        | name = name_
                        , description = description_
                      }
                    )
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
render ( id, result ) =
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
