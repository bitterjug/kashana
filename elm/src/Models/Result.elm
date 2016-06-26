module Models.Result exposing (..)

import Components.Field as Field
import Html exposing (..)
import Html.Attributes exposing (..)
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


type Msg
    = UpdateName Field.Msg
    | UpdateDescription Field.Msg
    | Saved
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        saveResult : Cmd Msg
        saveResult =
            -- simulate http request with sleep
            -- needs the whole model which I'm just logging for the moment
            let
                _ =
                    Debug.log "saving" model
            in
                Process.sleep Time.second
                    |> Task.perform (always NoOp) (always Saved)

        updateField : Field.Msg -> Field.Model -> ( Field.Model, Cmd Msg )
        updateField msg field =
            -- Update a field and, if its stored value changed, save the Result
            let
                field' =
                    Field.update msg field
            in
                ( field'
                , if field'.value /= field.value then
                    saveResult
                  else
                    Cmd.none
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

            Saved ->
                { model
                    | name = Field.saved model.name
                    , description = Field.saved model.description
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


render : Model -> Html Field.Msg
render result =
    -- we don't have an Msg type in this module yet,
    -- so I'm using msg as a type variable to say
    -- that rener returns Html of 'some msg type'
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
                                    [ Field.view renderName result.name ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
