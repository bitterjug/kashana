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
    { results : Maybe ResultList }


type Msg
    = NoOp
    | InitResults (List Result)


port results : (List Result -> msg) -> Sub msg


init : ( Model, Cmd Msg )
init =
    Model Nothing ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        InitResults results' ->
            { model | results = Just results' } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.results == Nothing then
        results InitResults
    else
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
        , model.results
            |> Maybe.map renderResults
            |> Maybe.withDefault (text "Nothing here")
        ]


main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
