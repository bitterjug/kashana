port module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as App


type alias Result =
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


type alias ResultList =
    List Result


type alias Model =
    { results : ResultList }


type Msg
    = NoOp


port results : (List Result -> msg) -> Sub msg


initWithFlags : List Result -> ( Model, Cmd Msg )
initWithFlags results =
    Model results ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


renderResult : Result -> Html Msg
renderResult result =
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
                                    [ h2
                                        [ classList
                                            [ ( "heading", True )
                                            , ( "editable", True )
                                            ]
                                        ]
                                        [ text result.name ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


renderResults : List Result -> Html Msg
renderResults results =
    div []
        <| List.map renderResult results


view : Model -> Html Msg
view model =
    div []
        [ (renderResults model.results)
        ]


main =
    App.programWithFlags
        { init = initWithFlags
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
