port module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Result as Result
import Models.ResultObject as ResultObject


type alias ID =
    Int


type alias Model =
    -- The dashboard model comprises a list of results
    { results : List Result.Model
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
                updateResult resultModel =
                    if resultModel |> Result.hasId id then
                        Result.update model.flags rmsg resultModel
                    else
                        ( resultModel, Cmd.none )

                ( results_, cmds ) =
                    List.unzip (List.map updateResult model.results)
            in
                ( { model | results = results_ }
                , Cmd.map (UpdateResult id) (Cmd.batch cmds)
                )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


renderResults : List Result.Model -> Html Msg
renderResults results =
    let
        renderResult : Result.Model -> Html Msg
        renderResult ( id, r ) =
            Result.render ( id, r )
                |> Html.map (UpdateResult id)
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
