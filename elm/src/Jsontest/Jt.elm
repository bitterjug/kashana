module Jsontest.Jt exposing (..)

import Models.Result as Result
import Json.Decode as Jd


json : String
json =
    "{\"id\":1,\"name\":\"Goal\",\"description\":\"jdklkjaslkjasdasdsa<br><br>\",\"order\":1,\"parent\":null,\"level\":1,\"contribution_weighting\":0,\"risk_rating\":null,\"rating\":null,\"log_frame\":1,\"indicators\":[],\"activities\":[],\"assumptions\":[]}"


d : Jd.Decoder Result.ResultObject
d =
    Jd.map7 Result.ResultObject
        (Jd.field "id" Jd.int)
        (Jd.field "name" Jd.string)
        (Jd.field "description" Jd.string)
        (Jd.field "order" Jd.int)
        (Jd.field "level" Jd.int)
        (Jd.field "contribution_weighting" Jd.int)
        (Jd.field "log_frame" Jd.int)
