module Models.Result exposing (..)

import Components.Field as Field
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as App
import Process
import Task
import Time


type alias Model =
    { name : Field.Model
    , description : Field.Model
    }


type alias ResultObject =
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
    { name = Field.initModel "Name" result.name
    , description = Field.initModel "Description" result.description
    }


type Msg
    = UpdateName Field.Msg
    | UpdateDescription Field.Msg
    | Saved Field.Msg
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        saveResult : Field.Msg -> Cmd Msg
        saveResult msg' =
            Process.sleep Time.second
                |> Task.perform (always NoOp) (always (Saved msg'))

        updateField : Field.Msg -> Field.Model -> ( Field.Model, Cmd Msg )
        updateField msg field =
            -- Update a field and, if its stored value changed, save the Result
            let
                ( field', msg_ ) =
                    Field.update' msg field
            in
                ( field'
                , msg_ |> Maybe.map saveResult >> Maybe.withDefault Cmd.none
                )
    in
        case msg of
            NoOp ->
                model ! []

            UpdateName msg' ->
                let
                    ( name', cmd ) =
                        updateField msg' model.name
                in
                    ( { model | name = name' }, cmd )

            UpdateDescription msg' ->
                let
                    ( description', cmd ) =
                        updateField msg' model.description
                in
                    ( { model | description = description' }, cmd )

            Saved msg' ->
                -- simulate http request with sleep
                -- needs the whole model which I'm just logging for the moment
                let
                    model' =
                        Debug.log "saved" model
                in
                    { model'
                        | name = Field.update msg' model.name
                        , description = Field.update msg' model.description
                    }
                        ! []


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
                                    [ App.map UpdateName <| Field.view renderName result.name ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
