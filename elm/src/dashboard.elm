port module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Result as Result
import Models.ResultObject as ResultObject


type alias ID =
    Int


type alias Model =
    -- The dashboard model comprises a list of results
    { results : List ( ID, Result.Model )
    , flags : Result.Flags
    }


type Msg
    = NoOp
    | UpdateResult ID Result.Msg


type alias AptivateData =
    { results : List ResultObject.Model
    , csrf_token : String
    , logframe : { id : Int }
    }


initWithFlags : AptivateData -> ( Model, Cmd Msg )
initWithFlags data =
    { results =
        List.indexedMap (,) <|
            List.map Result.initModel data.results
    , flags =
        { csrfToken = data.csrf_token
        , logframeId = data.logframe.id
        }
    }
        ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UpdateResult id rmsg ->
            let
                updateResult ( id_, result ) =
                    if id_ == id then
                        let
                            ( result_, cmd ) =
                                Result.update model.flags rmsg result
                        in
                            ( ( id_, result_ ), cmd )
                    else
                        ( ( id_, result ), Cmd.none )

                ( results_, cmds ) =
                    List.unzip (List.map updateResult model.results)
            in
                ( { model | results = results_ }
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
                |> Html.map (UpdateResult n)
    in
        div [] <|
            List.map (renderResult) results


view : Model -> Html Msg
view model =
    div []
        [ (renderResults model.results) ]


main =
    Html.programWithFlags
        { init = initWithFlags
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
