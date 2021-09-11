port module Ports exposing (..)

import Json.Encode as E


port save : E.Value -> Cmd msg
