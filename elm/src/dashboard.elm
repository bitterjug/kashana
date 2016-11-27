port module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as App
import Models.Result as Result


type alias ID =
    Int


type alias Model =
    -- The dashboard model comprises a list of results
    { results : List ( ID, Result.Model )
    , nextId : ID
    }


type Msg
    = NoOp
    | UpdateResult ID Result.Msg


type alias AptivateData =
    { results : List Result.ResultObject
    , logframe : { id : Int, name : String }
    }


initWithFlags : AptivateData -> ( Model, Cmd Msg )
initWithFlags data =
    { results =
        List.indexedMap (,) <|
            List.map Result.initModel data.results
    , nextId = List.length data.results
    }
        ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UpdateResult id rmsg ->
            let
                updateResult ( id', result ) =
                    if id' == id then
                        let
                            ( result', cmd ) =
                                Result.update rmsg result
                        in
                            ( ( id', result' ), cmd )
                    else
                        ( ( id', result ), Cmd.none )

                ( results', cmds ) =
                    List.unzip (List.map updateResult model.results)
            in
                ( { model | results = results' }
                , Cmd.map (UpdateResult id) (Cmd.batch cmds)
                )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


renderResults : List ( ID, Result.Model ) -> Html Msg
renderResults results =
    let
        renderResult : ( ID, Result.Model ) -> Html Msg
        renderResult ( n, r ) =
            Result.render r
                |> App.map (UpdateResult n)
    in
        div [] <|
            List.map (renderResult) results


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
