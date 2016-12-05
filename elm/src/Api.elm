module Api exposing (..)

import Http
import Json.Decode as Jd


safeRequest : String -> String -> String -> Http.Body -> Jd.Decoder a -> Http.Request a
safeRequest requestType token url body decoder =
    Http.request
        { method = requestType
        , headers = [ Http.header "X-CSRFToken" token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }


put : String -> String -> Http.Body -> Jd.Decoder a -> Http.Request a
put =
    safeRequest "PUT"


post : String -> String -> Http.Body -> Jd.Decoder a -> Http.Request a
post =
    safeRequest "POST"
