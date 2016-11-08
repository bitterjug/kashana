module Components.Field exposing (Model, Msg, Renderer, initModel, view, update, update')

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onInput, keyCode, onClick, onBlur)
import Json.Decode as Json


-- Model


type FeedbackState
    = InProgress
    | Success
    | Error
    | Normal


type alias Model =
    { name :
        String
        -- name, used for placeholder
    , value :
        String
        -- current stored value
    , input :
        String
        -- new value being entered
    , feedback :
        FeedbackState
    , editing :
        Bool
        -- focussed for editing
    }


initModel : String -> String -> Model
initModel name value =
    { name = name
    , value = value
    , input = value
    , feedback = Normal
    , editing = False
    }



-- View


enter =
    13


escape =
    27


keyMsg : List ( Int, Msg ) -> Int -> Msg
keyMsg mapping keycode =
    Dict.fromList mapping
        |> Dict.get keycode
        |> Maybe.withDefault NoOp


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" <| Json.map tagger keyCode


type alias Renderer =
    List (Attribute Msg) -> String -> Html Msg


view : Renderer -> Model -> Html Msg
view displayView model =
    let
        highlightStyle : Attribute Msg
        highlightStyle =
            classList
                [ ( "in-progress", model.feedback == InProgress )
                , ( "success", model.feedback == Error )
                , ( "error", model.feedback == Success )
                ]

        display : Html Msg
        display =
            displayView [ highlightStyle, onClick Focus ] <|
                if model.value == "" then
                    model.name
                else
                    model.value

        edit : Html Msg
        edit =
            input
                [ type' "text"
                , highlightStyle
                , placeholder model.name
                , value model.input
                , autofocus True
                , name model.name
                , onInput UpdateInput
                , onBlur Latch
                , onKeyDown <|
                    keyMsg
                        [ ( enter, Latch )
                        , ( escape, Reset )
                        ]
                ]
                []
    in
        if model.editing then
            edit
        else
            display



-- Messages


type Msg
    = NoOp
    | UpdateInput String
    | Latch
    | Reset
    | Saved
    | Focus


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        UpdateInput s ->
            { model | input = s }

        Latch ->
            { model
                | value = model.input
                , editing = False
            }

        Reset ->
            { model
                | input = model.value
                , editing = False
            }

        Focus ->
            { model | editing = True }

        Saved ->
            -- Now we need to return a Cmd from this update function so that
            -- we can set the timer to remove the success class from this field.
            -- That's going to impact the design of update' below.
            { model | feedback = Success }


update' : Msg -> Model -> ( Model, Maybe Msg )
update' msg model =
    -- Do a normal update but also check if the stored field value has changed.
    -- If it has, return Just Saved as the second element -- the Msg to send
    -- us back when the value change has been processed (e.g. saved to a server)
    -- Otherwise return Nothing -- no message.
    let
        model' =
            update msg model
    in
        if model.value /= model'.value then
            ( { model' | feedback = InProgress }, Just Saved )
        else
            ( model', Nothing )
