module S3Uploader exposing
    ( PresignedAwsUrl
    , PresignedAwsUrlFields
    , S3Msg(..)
    , S3Uploader
    , gotPresignedUrlMsg
    , init
    , selectFileMsg
    , selectFilesMsg
    , update
    )

import File
import File.Select
import Http
import Http.Xml
import Xml.Decode as XD



{-
     This library's aim is to expose an as simple as possible solution to handle direct upload to S3.
   The goal is to remove all the complexity and to let the user handle only needed cases.
   First, the user can pass a cmd that gives back a presigned url from a server (it has to be server side)
   More on that here : https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html
   Second, the user can pass a cmd that is run after upload. The second parameter function is a function that
   takes a url and a file and does whatever you want to do with this url on s3 and the file uploaded.
   It could be for example to store the url and the mime type as well as the file name to your server.

   It was a real pain to do all that, because you have many things to handle. At first, you need to
   understand the File api, then you have to understand the presigned url api with all the needed parameters.
   Lastly you have to parse the response from S3 which is in Xml.

   And at the end you have to do something with the url given by S3 and the file.
-}


type alias MimeType =
    String


{-| Create the local msg of the S3 uploader. You can use it as following :
type S3Msg = S3 S3Uploader.S3Msg
it's an opaque type so you don't touch too much to it
-}
type S3Msg
    = SelectFile (List MimeType)
    | SelectFiles (List MimeType)
    | GotPresignedUrl (Maybe PresignedAwsUrl)
    | GotUrl File.File (Result Http.Error String)
    | ImageLoaded File.File
    | ImagesLoaded File.File (List File.File)


{-| You need this message to be able to give the program a way to do something after your server sends you back a presigned Url
(Used inside the update function, example is further in the code)
-}
gotPresignedUrlMsg : Maybe PresignedAwsUrl -> S3Msg
gotPresignedUrlMsg =
    GotPresignedUrl


{-| This message to trigger the select popup (to have you select one file)
ex :
Html.button [Html.Events.onClick (S3 (S3Uploader.selectFileMsg
[ "image/png"
, "image/jpg"
, "image/gif"
]
)][B.text "Update photo"]
-}
selectFileMsg : List MimeType -> S3Msg
selectFileMsg mimeTypes =
    SelectFile mimeTypes


{-| This message to trigger the select popup (to have you select one or more files)
ex :
Html.button [Html.Events.onClick (S3 (S3Uploader.selectsFileMsg
[ "image/png"
, "image/jpg"
, "image/gif"
]
)][B.text "Upload gallery"]
-}
selectFilesMsg : List MimeType -> S3Msg
selectFilesMsg mimeTypes =
    SelectFiles mimeTypes


{-| This type is what your server should give you back.
It is mandatory to have all the fieds in order to upload directly to S3
-}
type alias PresignedAwsUrl =
    { url : String
    , fields : PresignedAwsUrlFields
    }


{-| {'url': '<https://noteimages.s3.amazonaws.com/'>,
'fields': {
'key': 'foo.jpg'
, 'AWSAccessKeyId': 'AKIAJQYJYCIAWH6DGHIQ'
, 'policy': 'eyJleHBpcmF0aW9uIjogIjIwMjAtMDUtMDZUMjM6MDI6MzdaIiwgImNvbmRpdGlvbnMiOiBbeyJidWNrZXQiOiAibm90ZWltYWdlcyJ9LCB7ImtleSI6ICJmb28uanBnIn1dfQ=='
, 'signature': 'AKh67mKJ7xDFe8uf1qfH6QRoBS8='}}

    * key3832528868: "development/6780a705-221d-470c-86a3-9a3ccbefb6a1/${filename}"
    * policy3832528868: "eyJleHBpcmF0aW9uIjoiMjAyMC0wNS0wNlQyMDoyMzo0NFoiLCJjb25kaXRpb25zIjpbeyJidWNrZXQiOiJnZXRjb2xsZWN0aXZlLXB1YmxpYy1maWxlcyJ9LFsic3RhcnRzLXdpdGgiLCIka2V5IiwiZGV2ZWxvcG1lbnQvNjc4MGE3MDUtMjIxZC00NzBjLTg2YTMtOWEzY2NiZWZiNmExLyJdLHsic3VjY2Vzc19hY3Rpb25fc3RhdHVzIjoiMjAxIn0seyJ4LWFtei1jcmVkZW50aWFsIjoiQUtJQVVFTElDMkZGTDdIUTNWWkovMjAyMDA1MDYvZXUtd2VzdC0zL3MzL2F3czRfcmVxdWVzdCJ9LHsieC1hbXotYWxnb3JpdGhtIjoiQVdTNC1ITUFDLVNIQTI1NiJ9LHsieC1hbXotZGF0ZSI6IjIwMjAwNTA2VDIwMDg0NFoifV19"
    - success_action_status3832528868: "201"
    - x_amz_algorithm3832528868: "AWS4-HMAC-SHA256"
    * x_amz_credential3832528868: "AKIAUELIC2FFL7HQ3VZJ/20200506/eu-west-3/s3/aws4_request"
    - x_amz_date3832528868: "20200506T200844Z"
    * x_amz_signature3832528868: "43442ea5adcffbd4bead6364fc5fc35c6a482a19db831de9f2953e769f85664b"
    * url3832528868: "https://getcollective-public-files.s3.eu-west-3.amazonaws.com/"

-}


{-| This type is what your server should give you back.
It is mandatory to have all the fields in order to upload directly to S3
-}
type alias PresignedAwsUrlFields =
    { key : String
    , policy : String
    , success_action_status : String
    , x_amz_algorithm : String
    , x_amz_credential : String
    , x_amz_date : String
    , x_amz_signature : String
    }


{-| This type is where we store the files and the uploading files and also the authorized Mime types
-}
type S3Uploader
    = S3Uploader
        { files : List File.File
        , uploadingFiles : List File.File
        }


{-| This function is to initialize your uploader

type alias Model = {s3Uploader = S3Uploader.init
}

-}
init : S3Uploader
init =
    S3Uploader
        { files = []
        , uploadingFiles = []
        }



{-

   example :
    update msg model =
        case msg of
            S3 msg_ ->
                S3Uploader.update
                    S3
                    msg_
                    model.s3Uploader
                    (\numberOfUrls ->
                        generatePresignedUrls numberOfUrls (S3Uploader.gotPresignedUrlMsg << getPresignedUrl)
                    )
                    (\( url, file ) ->
                        saveAvatarCmd
                            { url = url
                            , filename = file |> File.name
                            , mimetype = file |> File.mime
                            }
                    )
                    |> Tuple.mapFirst (\s3Uploader -> { model | s3Uploader = s3Uploader })

-}


{-| this is the heart of the uploader : the update function. You have to call it
the S3Msg wrapper with special lambda functions in it
-}
update : (S3Msg -> msg) -> S3Msg -> S3Uploader -> (Int -> Cmd S3Msg) -> (( String, File.File ) -> Cmd msg) -> ( S3Uploader, Cmd msg )
update wrapper msg ((S3Uploader s3UploaderD) as s3Uploader) urlToGeneratePresignedUrls doWithUrlAndFile =
    case msg of
        SelectFile authorizedMimeTypes ->
            ( s3Uploader
            , Cmd.map wrapper (File.Select.file authorizedMimeTypes ImageLoaded)
            )

        SelectFiles authorizedMimeTypes ->
            ( s3Uploader
            , Cmd.map wrapper (File.Select.files authorizedMimeTypes ImagesLoaded)
            )

        ImageLoaded file ->
            let
                newFiles =
                    [ file ]
            in
            ( S3Uploader { s3UploaderD | files = newFiles }, Cmd.map wrapper (urlToGeneratePresignedUrls (List.length newFiles)) )

        ImagesLoaded file files ->
            let
                newFiles =
                    file :: files
            in
            ( S3Uploader { s3UploaderD | files = newFiles }, Cmd.map wrapper (urlToGeneratePresignedUrls (List.length newFiles)) )

        GotPresignedUrl resultUrl ->
            resultUrl
                |> Maybe.map
                    (\url ->
                        case s3UploaderD.files of
                            [] ->
                                ( s3Uploader, Cmd.none )

                            f :: queue ->
                                ( S3Uploader { s3UploaderD | uploadingFiles = f :: s3UploaderD.uploadingFiles, files = queue }
                                , Cmd.map wrapper (uploadFileToS3 url f)
                                )
                    )
                |> Maybe.withDefault ( s3Uploader, Cmd.none )

        GotUrl file resultUrl ->
            case resultUrl of
                Ok url ->
                    ( S3Uploader { s3UploaderD | uploadingFiles = s3UploaderD.uploadingFiles |> List.filter (\f -> f /= file) }
                    , doWithUrlAndFile ( url, file )
                    )

                Err err ->
                    ( s3Uploader, Cmd.none )


uploadFileToS3 : PresignedAwsUrl -> File.File -> Cmd S3Msg
uploadFileToS3 url file =
    Http.post
        { url = url.url
        , body =
            Http.multipartBody
                [ Http.stringPart "key" url.fields.key
                , Http.stringPart "policy" url.fields.policy
                , Http.stringPart "content-type" (File.mime file)
                , Http.stringPart "success_action_status" url.fields.success_action_status
                , Http.stringPart "x_amz_algorithm" url.fields.x_amz_algorithm
                , Http.stringPart "x_amz_credential" url.fields.x_amz_credential
                , Http.stringPart "x_amz_date" url.fields.x_amz_date
                , Http.stringPart "x_amz_signature" url.fields.x_amz_signature
                , Http.filePart "file" file
                ]
        , expect = Http.Xml.expectXml (GotUrl file) urlDecoder
        }


urlDecoder : XD.Decoder String
urlDecoder =
    XD.path [ "Location" ] (XD.single XD.string)
