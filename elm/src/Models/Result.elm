module Models.Result exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
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


render : Model -> Html msg
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
