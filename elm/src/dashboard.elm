port module Dashboard exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Result as Result
import Models.ResultObject as ResultObject


type alias Model =
    -- The dashboard model comprises
    -- configuration values loaded from the page
    -- a list of results
    -- and an empty result placeholder for input
    { flags : Result.Flags
    , results : List Result.Model
    , placeholder : Result.Model
    }


type Msg
    = NoOp
    | UpdateResult (Maybe Int) Result.Msg
    | UpdatePlaceholder Result.Msg


type alias AptivateData =
    { results : List ResultObject.Model
    , csrf_token : String
    , logframe : { id : Int }
    }


initWithFlags : AptivateData -> ( Model, Cmd Msg )
initWithFlags data =
    let
        flags =
            { csrfToken = data.csrf_token
            , logframeId = data.logframe.id
            }
    in
        { flags = flags
        , results = List.map Result.initModel data.results
        , placeholder = Result.fromScratch flags
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
                    if resultModel.id == id then
                        Result.update model.flags rmsg resultModel
                    else
                        ( resultModel, Cmd.none )

                ( results_, cmds ) =
                    List.unzip (List.map updateResult model.results)
            in
                ( { model | results = results_ }
                , Cmd.map (UpdateResult id) (Cmd.batch cmds)
                )

        UpdatePlaceholder rmsg ->
            let
                ( placeholder_, cmd ) =
                    Result.update model.flags rmsg model.placeholder
            in
                ( { model | placeholder = placeholder_ }
                , Cmd.map UpdatePlaceholder cmd
                )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


renderResults : List Result.Model -> Html Msg
renderResults results =
    let
        renderResult : Result.Model -> Html Msg
        renderResult result =
            Result.render result
                |> Html.map (UpdateResult result.id)
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
