port module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as App
import Models.Result as Result


type alias Model =
    -- The dashboard model comprises a list of results
    { results : List Result.Model }


type Msg
    = NoOp


port results : (List Result.Model -> msg) -> Sub msg


initWithFlags : List Result.ResultObject -> ( Model, Cmd Msg )
initWithFlags results =
    { results = List.map Result.initModel results } ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


renderResults : List Result.Model -> Html Msg
renderResults results =
    div []
        <| List.map Result.render results


view : Model -> Html Msg
view model =
    div []
        [ (renderResults model.results) ]


main =
    App.programWithFlags
        { init = initWithFlags
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
