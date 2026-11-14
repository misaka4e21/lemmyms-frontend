module Feature.OAuthProviders exposing (Form, Model, Provider, body, decoder, emptyForm, initial, load, page, valid)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict exposing (Dict)
import Generated.I18n as T
import Html exposing (Html, button, div, form, input, label, p, section, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as D
import Json.Encode as E
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (pageHeading)


type alias Provider =
    { id : Int, fields : Dict String String, flags : Dict String Bool }


type alias Form =
    { id : Maybe Int, fields : Dict String String, flags : Dict String Bool }


type alias Model =
    { items : Remote (List Provider), form : Form, busy : Bool, problem : Maybe Api.Problem }


emptyForm : Form
emptyForm =
    { id = Nothing, fields = Dict.empty, flags = Dict.fromList [ ( "enabled", True ), ( "use_pkce", True ) ] }


initial : Model
initial =
    { items = NotAsked, form = emptyForm, busy = False, problem = Nothing }


textFields : List ( String, T.I18n -> String )
textFields =
    [ ( "display_name", T.oauthName )
    , ( "issuer", T.oauthIssuer )
    , ( "authorization_endpoint", T.oauthAuthorizationEndpoint )
    , ( "token_endpoint", T.oauthTokenEndpoint )
    , ( "userinfo_endpoint", T.oauthUserinfoEndpoint )
    , ( "id_claim", T.oauthIdClaim )
    , ( "client_id", T.oauthClientId )
    , ( "client_secret", T.oauthClientSecret )
    , ( "scopes", T.oauthScopes )
    ]


flagFields : List ( String, T.I18n -> String )
flagFields =
    [ ( "auto_verify_email", T.oauthAutoVerifyEmail )
    , ( "account_linking_enabled", T.oauthAccountLinking )
    , ( "use_pkce", T.oauthUsePkce )
    , ( "enabled", T.oauthEnabled )
    ]


decoder : D.Decoder (List Provider)
decoder =
    D.field "admin_oauth_providers" (D.list providerDecoder)


providerDecoder : D.Decoder Provider
providerDecoder =
    D.map3 Provider
        (D.field "id" Domain.identifier)
        (pairsDecoder D.string (List.map Tuple.first textFields |> List.filter ((/=) "client_secret")))
        (pairsDecoder D.bool (List.map Tuple.first flagFields))


pairsDecoder : D.Decoder a -> List String -> D.Decoder (Dict String a)
pairsDecoder valueDecoder keys =
    List.map (\key -> D.map (Tuple.pair key) (D.field key valueDecoder)) keys
        |> List.foldr (D.map2 (::)) (D.succeed [])
        |> D.map Dict.fromList


load : AuthState -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth loaded =
    case auth of
        Authenticated user ->
            if Domain.isAdmin user then
                ( { initial | items = Loading }, Api.get "/site" loaded )

            else
                ( initial, Cmd.none )

        _ ->
            ( initial, Cmd.none )


valid : Form -> Bool
valid current =
    textFields
        |> List.map Tuple.first
        |> List.filter (\key -> key /= "client_secret" || current.id == Nothing)
        |> List.all (\key -> not (String.isEmpty (String.trim (Dict.get key current.fields |> Maybe.withDefault ""))))


body : Form -> String
body current =
    let
        include key =
            case current.id of
                Nothing ->
                    True

                Just _ ->
                    key
                        /= "issuer"
                        && key
                        /= "client_id"
                        && (key /= "client_secret" || not (String.isEmpty (Dict.get key current.fields |> Maybe.withDefault "")))

        fields =
            textFields
                |> List.map Tuple.first
                |> List.filter include
                |> List.map (\key -> ( key, E.string (Dict.get key current.fields |> Maybe.withDefault "") ))

        flags =
            flagFields
                |> List.map Tuple.first
                |> List.map (\key -> ( key, E.bool (Dict.get key current.flags |> Maybe.withDefault False) ))
    in
    E.object
        (fields
            ++ flags
            ++ (case current.id of
                    Just id ->
                        [ ( "id", E.int id ) ]

                    Nothing ->
                        []
               )
        )
        |> E.encode 0


page : { retry : msg, changed : String -> String -> msg, flagChanged : String -> Bool -> msg, edit : Provider -> msg, cancel : msg, submit : msg, delete : Provider -> msg } -> Active -> AuthState -> Model -> Html msg
page config active auth model =
    pageHeading (T.oauthProviders active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    div [ A.class "stack" ]
                        [ form [ A.class "card form-stack", Events.onSubmit config.submit ]
                            (List.map (textField config active model.form) textFields
                                ++ [ if model.form.id /= Nothing then
                                        p [ A.class "muted" ] [ text (T.oauthSecretUnchanged active.texts) ]

                                     else
                                        text ""
                                   ]
                                ++ List.map (flagField config active model.form) flagFields
                                ++ [ viewFormProblem active.texts model.problem
                                   , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.busy || not (valid model.form)) ]
                                        [ text
                                            (if model.form.id == Nothing then
                                                T.create active.texts

                                             else
                                                T.saveChanges active.texts
                                            )
                                        ]
                                   , if model.form.id /= Nothing then
                                        button [ A.type_ "button", Events.onClick config.cancel ] [ text (T.cancel active.texts) ]

                                     else
                                        text ""
                                   ]
                            )
                        , viewRemote config.retry
                            active.texts
                            model.items
                            (\items ->
                                if List.isEmpty items then
                                    p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                                else
                                    div [ A.class "stack" ] (List.map (providerView config active model.busy) items)
                            )
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


textField : { a | changed : String -> String -> msg } -> Active -> Form -> ( String, T.I18n -> String ) -> Html msg
textField config active current ( key, labelText ) =
    let
        fixed =
            current.id /= Nothing && List.member key [ "issuer", "client_id" ]

        identifier =
            "provider-" ++ key
    in
    div []
        [ label [ A.for identifier ] [ text (labelText active.texts) ]
        , input
            [ A.id identifier
            , A.type_
                (if key == "client_secret" then
                    "password"

                 else
                    "text"
                )
            , A.autocomplete False
            , A.required (key /= "client_secret" || current.id == Nothing)
            , A.disabled fixed
            , A.value (Dict.get key current.fields |> Maybe.withDefault "")
            , Events.onInput (config.changed key)
            ]
            []
        ]


flagField : { a | flagChanged : String -> Bool -> msg } -> Active -> Form -> ( String, T.I18n -> String ) -> Html msg
flagField config active current ( key, labelText ) =
    label []
        [ input [ A.type_ "checkbox", A.checked (Dict.get key current.flags |> Maybe.withDefault False), Events.onCheck (config.flagChanged key) ] []
        , text (labelText active.texts)
        ]


providerView : { a | edit : Provider -> msg, delete : Provider -> msg } -> Active -> Bool -> Provider -> Html msg
providerView config active busy provider =
    section [ A.class "card" ]
        [ p [] [ text (Dict.get "display_name" provider.fields |> Maybe.withDefault "") ]
        , div [ A.class "actions" ]
            [ button [ A.type_ "button", A.disabled busy, Events.onClick (config.edit provider) ] [ text (T.editProvider active.texts) ]
            , button [ A.id ("provider-delete-" ++ String.fromInt provider.id), A.type_ "button", A.disabled busy, Events.onClick (config.delete provider) ] [ text (T.deleteProvider active.texts) ]
            ]
        ]
