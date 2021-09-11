module Main exposing (Model, Msg(..), Todo, init, main, subscriptions, todosDecoder, todosEncoder, update, view, viewForm, viewHeader, viewList)

import Browser
import Css exposing (..)
import Css.Animations exposing (custom, keyframes, property)
import Css.Transitions exposing (transition)
import Html.Styled as Styled
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (onInput, onSubmit)
import Json.Decode as D
import Json.Encode as E
import Ports
import String exposing (String)
import Task
import Time



-- MAIN


main =
    Browser.element
        { init = init
        , view = view >> Styled.toUnstyled
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Todo =
    { title : String
    , date : Time.Posix
    }


type alias Model =
    { zone : Time.Zone
    , time : Time.Posix
    , todos : List Todo
    , userInput : String
    }


init : D.Value -> ( Model, Cmd Msg )
init flags =
    ( { zone = Time.utc
      , time = Time.millisToPosix 0
      , todos = todosDecoder flags
      , userInput = "test"
      }
    , Task.perform AdjustTimeZone Time.here
    )


todosDecoder : D.Value -> List Todo
todosDecoder flags =
    let
        decoder =
            D.list <|
                D.map2 Todo
                    (D.field "title" D.string)
                    (D.field "date" <|
                        D.map (\val -> Time.millisToPosix val) D.int
                    )

        result =
            D.decodeValue decoder flags
    in
    case result of
        Ok todos ->
            todos

        Err _ ->
            []



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone
    | Add String
    | Input String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( { model | time = newTime }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )

        Add input ->
            let
                newModel =
                    { model | todos = Todo input model.time :: model.todos }
            in
            ( newModel
            , Ports.save (todosEncoder newModel.todos)
            )

        Input input ->
            ( { model | userInput = input }
            , Cmd.none
            )


todosEncoder : List Todo -> E.Value
todosEncoder todos =
    E.list
        E.object
        (todos
            |> List.map
                (\todo ->
                    [ ( "title", E.string todo.title )
                    , ( "date", E.int (Time.posixToMillis todo.date) )
                    ]
                )
        )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1000 Tick



-- VIEW


view : Model -> Styled.Html Msg
view model =
    let
        zeroPadding =
            String.right 2

        hour =
            zeroPadding <| "0" ++ String.fromInt (Time.toHour model.zone model.time)

        minute =
            zeroPadding <| "0" ++ String.fromInt (Time.toMinute model.zone model.time)

        second =
            zeroPadding <| "0" ++ String.fromInt (Time.toSecond model.zone model.time)
    in
    Styled.div
        [ css
            [ backgroundColor (hex "#f5f5f5")
            , backgroundImage (linearGradient2 toTopLeft (stop <| hex "#f5f5f5") (stop <| hex "#35495E") [])
            , overflow hidden
            ]
        ]
        [ Styled.div
            [ css
                [ boxSizing borderBox
                , minHeight (vh 100)
                , margin2 (px 0) auto
                , paddingTop (px 50)
                , paddingBottom (px 50)
                , width (vw 70)
                , displayFlex
                , flexDirection column
                , alignItems center
                ]
            ]
            ([ viewHeader (hour ++ ":" ++ minute ++ ":" ++ second)
             , viewForm model.userInput
             ]
                ++ viewList model.todos
            )
        ]


viewHeader : String -> Styled.Html Msg
viewHeader time =
    Styled.header
        []
        [ Styled.h1
            [ css
                [ color (hex "fff")
                , fontSize (px 30)
                ]
            ]
            [ Styled.text "elm-todos" ]
        , Styled.p
            [ css
                [ color (hex "fff")
                , fontSize (px 100)
                , lineHeight (px 100)
                , marginTop (px 30)
                ]
            ]
            [ Styled.text time ]
        ]


viewForm : String -> Styled.Html Msg
viewForm input =
    Styled.form
        [ onSubmit (Add input)
        , css
            [ marginTop (px 30)
            , color (hex "ccc")
            , fontSize (px 16)
            , lineHeight (px 16)
            ]
        ]
        [ Styled.p [] [ Styled.text "Write your new Todo." ]
        , Styled.input
            [ onInput Input
            , value input
            , css
                [ backgroundColor transparent
                , borderBottom3 (px 1) solid (hex "fff")
                , color (hex "fff")
                , fontSize (px 20)
                , lineHeight (px 20)
                , padding (px 10)
                , width (px 500)
                ]
            ]
            []
        ]


viewList : List Todo -> List (Styled.Html Msg)
viewList todos =
    case todos of
        [] ->
            []

        _ ->
            [ Styled.div
                [ css
                    [ marginTop (px 30)
                    ]
                ]
                [ Styled.ul
                    []
                  <|
                    (todos
                        |> List.map
                            (\todo ->
                                Styled.li
                                    [ css
                                        [ boxSizing borderBox
                                        , backgroundColor (hex "fff")
                                        , borderRadius (px 3)
                                        , boxShadow4 (px 0) (px 4) (px 24) (rgba 0 0 0 0.15)
                                        , color (hex "aaa")
                                        , fontSize (px 20)
                                        , padding (px 20)
                                        , width (px 500)
                                        , marginTop (px 20)
                                        , transform (translateY (px 0))
                                        , transition
                                            [ Css.Transitions.boxShadow 500
                                            , Css.Transitions.transform 500
                                            ]
                                        , firstChild
                                            [ marginTop (px 0)
                                            ]
                                        , hover
                                            [ boxShadow4 (px 0) (px 4) (px 48) (rgba 0 0 0 0.3)
                                            , transform (translateY (px -3))
                                            ]
                                        ]
                                    ]
                                    [ Styled.text todo.title ]
                            )
                    )
                ]
            ]
