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
    -- Create a Model instance from a ResultObject
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
            -- Update a field. Using update', if the stored value changed,
            -- we get back a Just msg (as msg_) to send the field when we've
            -- processed the change (i.e. saved it to the server);
            -- otherwise Nothing.  We turn msg_ into the Cmd side effect:
            -- Cmd.none for Nothing, saveReslt msg for the other case.
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
                -- TODO: we're calling saved on all fields. MAybe we can get
                -- away with doing that only for the field that changed?
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


renderDescription : Field.Renderer
renderDescription atts value =
    div [ class "editable" ] [ text value ]


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
                                    [ App.map UpdateName <|
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
                                [ App.map UpdateDescription <|
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
