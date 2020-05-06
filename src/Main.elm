module Main exposing (main)

{- This is a starter app which presents a text label, text field, and a button.
   What you enter in the text field is echoed in the label.  When you press the
   button, the text in the label is reverse.
-}

import Browser
import Cmd.Extra exposing (withCmd, withCmds, withNoCmd)
import File
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (placeholder, style, type_)
import Html.Events exposing (onClick, onInput)
import Http
import S3Uploader exposing (..)



--  (S3Msg(..), S3Uploader)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { message : String
    , s3Uploader : S3Uploader
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
      , s3Uploader = S3Uploader.init
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

        S3 msg_ ->
            S3Uploader.update
                S3
                msg_
                model.s3Uploader
                (\numberOfUrls ->
                    generatePresignedUrls numberOfUrls (S3Uploader.gotPresignedUrlMsg << parseInsideRes)
                )
                (\( url, file ) ->
                    saveAvatarCmd
                        { url = url
                        , filename = file |> File.name
                        , mimetype = file |> File.mime
                        }
                )
                |> Tuple.mapFirst (\s3Uploader -> { model | s3Uploader = s3Uploader })


generatePresignedUrls : Int -> (Result Http.Error String -> msg) -> Cmd msg
generatePresignedUrls numberOfUrls msg =
    Cmd.batch
        (List.repeat numberOfUrls
            (Http.get
                { url = "http://localhost:8000/?passwd=jollygreengiant!&bucket=noteimages&file=foo.jpg"
                , expect = Http.expectString msg
                }
            )
        )


parseInsideRes : Result Http.Error String -> Maybe PresignedAwsUrl
parseInsideRes =
    -- TODO
    \_ -> Nothing


saveAvatarCmd arg =
    Cmd.none



-- VIEW


view : Model -> Html Msg
view model =
    div mainStyle
        [ div innerStyle
            [ label "S3 Uploader"
            , messageDisplay model
            , selectFileButton model
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


selectFileButton model =
    Html.button
        [ Html.Events.onClick
            (S3
                (S3Uploader.selectFileMsg
                    [ "image/png"
                    , "image/jpg"
                    , "image/gif"
                    ]
                )
            )
        ]
        [ text "Upload gallery" ]



{- Style -}


mainStyle =
    [ style "margin" "15px"
    , style "margin-top" "20px"
    , style "background-color" "#eee"
    , style "width" "240px"
    ]


innerStyle =
    [ style "padding" "15px" ]
