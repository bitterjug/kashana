module Models.ResultObject exposing (..)

import Json.Encode as Je
import Json.Decode as Jd
import Maybe.Extra exposing (maybeToList)


type alias Model =
    -- Type of the Aptivate.results objects used to initialize the app
    { id : Maybe Int
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


encode : Model -> Je.Value
encode result =
    Je.object <|
        (result.id
            |> Maybe.map Je.int
            |> Maybe.map ((,) "id")
            |> maybeToList
        )
            ++ [ ( "name", Je.string result.name )
               , ( "description", Je.string result.description )
                 -- skip a bit, brother
               , ( "log_frame", Je.int result.log_frame )
               , ( "order", Je.int result.order )
               ]


decode : Jd.Decoder Model
decode =
    Jd.map7 Model
        (Jd.field "id" (Jd.nullable Jd.int))
        (Jd.field "name" Jd.string)
        (Jd.field "description" Jd.string)
        (Jd.field "order" Jd.int)
        (Jd.field "level" Jd.int)
        (Jd.field "contribution_weighting" Jd.int)
        (Jd.field "log_frame" Jd.int)
