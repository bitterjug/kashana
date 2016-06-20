port module Dashboard exposing (..)

import Html exposing (h1, div, text, Html)
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


renderResults : List Result -> Html Msg
renderResults results =
    div []
        (results
            |> List.map (\r -> r.id |> toString |> text)
        )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Dashboard" ]
        , renderResults model.results
        ]


main =
    App.programWithFlags
        { init = initWithFlags
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
