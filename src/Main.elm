module Main exposing (main)

{- This is a starter app which presents a text label, text field, and a button.
   What you enter in the text field is echoed in the label.  When you press the
   button, the text in the label is reverse.
-}

import Browser
import Cmd.Extra exposing (withCmd, withCmds, withNoCmd)
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (placeholder, style, type_)
import Html.Events exposing (onClick, onInput)
import Http
import S3Uploader exposing (S3Msg(..))


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { message : String
    }


type Msg
    = NoOp
    | Input String
    | ReverseText
    | S3 S3Msg


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { message = "App started"
      }
    , Cmd.none
    )


subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Input str ->
            ( { model | message = str }, Cmd.none )

        ReverseText ->
            ( { model | message = model.message |> String.reverse |> String.toLower }, Cmd.none )

        S3 s3Msg ->
            case s3Msg of
                SelectFile mimetypeList ->
                    model |> withNoCmd

                SelectFiles mimetypeList ->
                  model |> withNoCmd

                GotUrl file result ->
                  model |> withNoCmd

                GotPresignedUrl maybePresignUrl ->
                  model |> withNoCmd

                ImageLoaded file ->
                  model |> withNoCmd

                ImagesLoaded file fileList ->
                  model |> withNoCmd






-- VIEW


view : Model -> Html Msg
view model =
    div mainStyle
        [ div innerStyle
            [ label "Skeleton App"
            , messageDisplay model
            , sampleInput model
            , sampleButton model
            ]
        ]


showIf condition element =
    if condition then
        element

    else
        text ""



{- Outputs -}


label str =
    div [ style "margin-bottom" "10px", style "font-weight" "bold" ]
        [ text str ]


messageDisplay model =
    div [ style "margin-bottom" "10px" ]
        [ text model.message ]



{- Inputs -}


sampleInput model =
    div [ style "margin-bottom" "10px" ]
        [ input [ type_ "text", placeholder "Enter text here", onInput Input ] [] ]



{- Controls -}


seletFileButton model =
    div [ style "margin-bottom" "0px" ]
        [ button [ onClick ReverseText ] [ text "Select file" ] ]


sampleButton model =
    div [ style "margin-bottom" "0px" ]
        [ button [ onClick ReverseText ] [ text "Reverse" ] ]



{- Style -}


mainStyle =
    [ style "margin" "15px"
    , style "margin-top" "20px"
    , style "background-color" "#eee"
    , style "width" "240px"
    ]


innerStyle =
    [ style "padding" "15px" ]
