module Components.Field exposing (Model, value, Msg, Renderer, initModel, view, update, update_)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onInput, keyCode, onClick, onBlur)
import Json.Decode as Json
import Process
import Task
import Time


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


value : Model -> String
value model =
    model.value



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
                , ( "error", model.feedback == Error )
                , ( "success", model.feedback == Success )
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
                [ type_ "text"
                , highlightStyle
                , placeholder model.name
                , Html.Attributes.value model.input
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
      -- Someone's typing
    | UpdateInput String
      -- Save the edited value soewhere
    | Latch
      -- We lost focus without saving
    | Reset
      -- Inform us that the value has been savd somewhere
    | Saved
      -- We receive the focus to edit
    | Focus
      -- Clear the success status
    | Clear


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UpdateInput s ->
            { model | input = s } ! []

        Latch ->
            { model
                | value = model.input
                , editing = False
            }
                ! []

        Reset ->
            { model
                | input = model.value
                , editing = False
            }
                ! []

        Focus ->
            { model | editing = True } ! []

        Saved ->
            -- Now we need to return a Cmd from this update function so that
            -- we can set the timer to remove the success class from this field.
            -- That's going to impact the design of update' below.
            let
                clearSucessFeedback =
                    Process.sleep (2 * Time.second)
                        |> Task.perform (always Clear)

                feedback =
                    case model.feedback of
                        InProgress ->
                            Success

                        _ ->
                            model.feedback
            in
                { model | feedback = feedback } ! [ clearSucessFeedback ]

        Clear ->
            { model | feedback = Normal } ! []


update_ : Msg -> Model -> ( Model, Maybe Msg )
update_ msg model =
    -- Do a normal update but also check if the stored field value has changed.
    -- If it has, return Just Saved as the second element -- the Msg to send
    -- us back when the value change has been processed (e.g. saved to a server)
    -- Otherwise return Nothing -- no message.
    let
        ( model_, cmd ) =
            update msg model
    in
        if model.value /= model_.value then
            ( { model_ | feedback = InProgress }, Just Saved )
        else
            ( model_, Nothing )
