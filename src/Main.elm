module Main exposing (Model, Msg(..), Todo, init, isOldTodo, main, subscriptions, todosDecode, todosEncode, update, view, viewForm, viewHeader, viewList)

import Browser
import Css exposing (..)
import Css.Animations exposing (custom, keyframes, property)
import Css.Transitions exposing (transition)
import Html.Styled as Styled
import Html.Styled.Attributes exposing (css, placeholder, src, value)
import Html.Styled.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as D
import Json.Encode as E
import List exposing (filter)
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
    ( Model Time.utc (Time.millisToPosix 0) (todosDecode flags) "test"
    , Task.perform AdjustTimeZone Time.here
    )


todosDecode : D.Value -> List Todo
todosDecode flags =
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
    | Delete Time.Posix
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
                    { model | todos = Todo input model.time :: model.todos, userInput = "" }
            in
            ( newModel
            , Ports.save (todosEncode newModel.todos)
            )

        Delete date ->
            let
                newModel =
                    { model | todos = filter (isOldTodo date) model.todos }
            in
            ( newModel
            , Ports.save (todosEncode newModel.todos)
            )

        Input input ->
            ( { model | userInput = input }
            , Cmd.none
            )


isOldTodo : Time.Posix -> Todo -> Bool
isOldTodo time todo =
    todo.date /= time


todosEncode : List Todo -> E.Value
todosEncode todos =
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

        timeView =
            if model.time == Time.millisToPosix 0 then
                "--:--:--"

            else
                hour ++ ":" ++ minute ++ ":" ++ second
    in
    Styled.div
        [ css
            [ backgroundColor (hex "#7F7FD5")
            , backgroundImage (linearGradient2 toTopLeft (stop <| hex "#4776E6") (stop <| hex "#8E54E9") [])
            , overflow hidden
            ]
        ]
        [ Styled.div
            [ css
                [ boxSizing borderBox
                , minHeight (vh 100)
                , margin2 (px 0) auto
                , paddingTop (px 50)
                , width (px 1080)
                ]
            ]
            ([ viewHeader timeView
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
            [ Styled.text "ElmTodo" ]
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
                    [ css
                        [ displayFlex
                        , flexWrap wrap
                        , marginTop (px -20)
                        , marginLeft (px -20)
                        ]
                    ]
                  <|
                    (todos
                        |> List.map
                            (\todo ->
                                Styled.li
                                    [ css
                                        [ boxSizing borderBox
                                        , displayFlex
                                        , alignItems center
                                        , justifyContent spaceBetween
                                        , backgroundColor (hex "fff")
                                        , borderRadius (px 3)
                                        , boxShadow4 (px 0) (px 4) (px 24) (rgba 0 0 0 0.15)
                                        , color (hex "aaa")
                                        , fontSize (px 25)
                                        , padding3 (px 40) (px 20) (px 20)
                                        , height (px 200)
                                        , width (px 200)
                                        , marginTop (px 20)
                                        , marginLeft (px 20)
                                        , position relative
                                        , transform (translateY (px 0))
                                        , transition
                                            [ Css.Transitions.boxShadow 500
                                            , Css.Transitions.transform 500
                                            ]
                                        , hover
                                            [ boxShadow4 (px 0) (px 4) (px 48) (rgba 0 0 0 0.3)
                                            , transform (translateY (px -3))
                                            ]
                                        ]
                                    ]
                                    [ Styled.text todo.title
                                    , Styled.button
                                        [ onClick (Delete todo.date)
                                        , css
                                            [ position absolute
                                            , top (px 20)
                                            , right (px 20)
                                            ]
                                        ]
                                        [ Styled.img
                                            [ src "image/icon.png"
                                            , css
                                                [ width (px 20)
                                                ]
                                            ]
                                            []
                                        ]
                                    ]
                            )
                    )
                ]
            ]
