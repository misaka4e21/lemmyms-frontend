module Feature.SiteConfiguration exposing (Model, Snapshot, body, change, decoder, initial, load, page, toggle, valid)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Dict exposing (Dict)
import File exposing (File)
import Generated.I18n as T
import Html exposing (Html, button, div, fieldset, form, img, input, label, legend, option, p, select, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as D
import Json.Encode as E
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))
import Set exposing (Set)
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (pageHeading)


type alias Snapshot =
    { fields : Dict String String, flags : Dict String Bool, icon : Maybe String, banner : Maybe String }


type alias Model =
    { snapshot : Remote Snapshot
    , fields : Dict String String
    , flags : Dict String Bool
    , dirty : Set String
    , busy : Bool
    , imageBusy : Bool
    , problem : Maybe Api.Problem
    , icon : Maybe String
    , banner : Maybe String
    }


initial : Model
initial =
    { snapshot = NotAsked, fields = Dict.empty, flags = Dict.empty, dirty = Set.empty, busy = False, imageBusy = False, problem = Nothing, icon = Nothing, banner = Nothing }


textFields : List ( String, T.I18n -> String, Bool )
textFields =
    [ ( "name", T.siteName, False )
    , ( "summary", T.communitySummary, True )
    , ( "sidebar", T.communitySidebar, True )
    , ( "legal_information", T.legalInformation, True )
    , ( "content_warning", T.siteContentWarning, True )
    , ( "application_question", T.siteApplicationQuestion, True )
    , ( "discussion_languages", T.discussionLanguages, False )
    ]


flagFields : List ( String, T.I18n -> String )
flagFields =
    [ ( "community_creation_admin_only", T.siteCommunityAdminOnly )
    , ( "email_verification_required", T.siteEmailVerification )
    , ( "private_instance", T.sitePrivate )
    , ( "federation_enabled", T.siteFederationEnabled )
    , ( "federation_signed_fetch", T.siteFederationSignedFetch )
    , ( "nsfw_content_disallowed", T.siteDisallowNsfw )
    , ( "oauth_registration", T.siteOauthRegistration )
    ]


rateCategories : List ( String, T.I18n -> String )
rateCategories =
    [ ( "message", T.siteRateMessages )
    , ( "post", T.siteRatePosts )
    , ( "register", T.siteRateRegistration )
    , ( "image", T.siteRateImages )
    , ( "comment", T.siteRateComments )
    , ( "search", T.siteRateSearch )
    , ( "import_user_settings", T.siteRateImports )
    ]


rateKeys : List String
rateKeys =
    rateCategories
        |> List.concatMap (\( category, _ ) -> [ "rate_limit_" ++ category ++ "_max_requests", "rate_limit_" ++ category ++ "_interval_seconds" ])


decoder : D.Decoder Snapshot
decoder =
    D.map4 Snapshot
        (D.map Dict.fromList
            (sequence
                (List.map (\( key, _, _ ) -> D.map (Tuple.pair key) (textValue key)) textFields
                    ++ [ D.map (Tuple.pair "registration_mode") (D.at [ "site_view", "local_site", "registration_mode" ] D.string) ]
                    ++ List.map (\key -> D.map (Tuple.pair key << String.fromInt) (D.at [ "site_view", "local_site_rate_limit", String.dropLeft 11 key ] D.int)) rateKeys
                )
            )
        )
        (D.map Dict.fromList (sequence (List.map (\( key, _ ) -> D.map (Tuple.pair key) (D.at [ "site_view", "local_site", key ] D.bool)) flagFields)))
        (maybeString [ "site_view", "site", "icon" ])
        (maybeString [ "site_view", "site", "banner" ])


sequence : List (D.Decoder a) -> D.Decoder (List a)
sequence =
    List.foldr (D.map2 (::)) (D.succeed [])


maybeString : List String -> D.Decoder (Maybe String)
maybeString path =
    D.oneOf [ D.at path (D.nullable D.string), D.succeed Nothing ]


textValue : String -> D.Decoder String
textValue key =
    if key == "discussion_languages" then
        D.field key (D.list Domain.identifier) |> D.map (List.map String.fromInt >> String.join ", ")

    else
        let
            group =
                if List.member key [ "name", "summary", "sidebar", "content_warning" ] then
                    "site"

                else
                    "local_site"
        in
        maybeString [ "site_view", group, key ] |> D.map (Maybe.withDefault "")


load : AuthState -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth loaded =
    case auth of
        Authenticated user ->
            if Domain.isAdmin user then
                ( { initial | snapshot = Loading }, Api.get "/site" loaded )

            else
                ( initial, Cmd.none )

        _ ->
            ( initial, Cmd.none )


change : String -> String -> Model -> Model
change key value model =
    { model | fields = Dict.insert key value model.fields, dirty = Set.insert key model.dirty, problem = Nothing }


toggle : String -> Bool -> Model -> Model
toggle key value model =
    { model | flags = Dict.insert key value model.flags, dirty = Set.insert key model.dirty, problem = Nothing }


languageIds : String -> Maybe (List Int)
languageIds value =
    if String.isEmpty (String.trim value) then
        Just []

    else
        String.split "," value
            |> List.map
                (String.trim
                    >> String.toInt
                    >> Maybe.andThen
                        (\id ->
                            if id >= 0 && id <= 2147483647 then
                                Just id

                            else
                                Nothing
                        )
                )
            |> List.foldr (Maybe.map2 (::)) (Just [])


validField : Model -> String -> Bool
validField model key =
    let
        value =
            Dict.get key model.fields |> Maybe.withDefault ""
    in
    if key == "name" then
        not (String.isEmpty (String.trim value))

    else if key == "discussion_languages" then
        languageIds value /= Nothing

    else if List.member key rateKeys then
        String.toInt value
            |> Maybe.map
                (\number ->
                    number
                        <= 2147483647
                        && (if String.endsWith "_interval_seconds" key then
                                number > 0

                            else
                                number >= 0
                           )
                )
            |> Maybe.withDefault False

    else
        True


valid : Model -> Bool
valid model =
    Set.toList model.dirty |> List.all (validField model)


validationAttributes : Model -> String -> List (Html.Attribute msg)
validationAttributes model key =
    if Set.member key model.dirty && not (validField model key) then
        [ A.attribute "aria-invalid" "true", A.attribute "aria-describedby" "site-configuration-error" ]

    else
        []


body : Model -> String
body model =
    Set.toList model.dirty
        |> List.filterMap
            (\key ->
                case Dict.get key model.flags of
                    Just value ->
                        Just ( key, E.bool value )

                    Nothing ->
                        Dict.get key model.fields
                            |> Maybe.andThen
                                (\value ->
                                    if key == "discussion_languages" then
                                        languageIds value |> Maybe.map (\ids -> ( key, E.list E.int ids ))

                                    else if List.member key rateKeys then
                                        String.toInt value |> Maybe.map (\number -> ( key, E.int number ))

                                    else
                                        Just ( key, E.string value )
                                )
            )
        |> E.object
        |> E.encode 0


page : { retry : msg, changed : String -> String -> msg, toggled : String -> Bool -> msg, save : msg, imageSelected : String -> Maybe File -> msg, imageRemove : String -> msg } -> Active -> AuthState -> Model -> Html msg
page config active auth model =
    pageHeading (T.siteConfiguration active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    viewRemote config.retry
                        active.texts
                        model.snapshot
                        (\_ -> configurationView config active model)

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


configurationView : { a | changed : String -> String -> msg, toggled : String -> Bool -> msg, save : msg, imageSelected : String -> Maybe File -> msg, imageRemove : String -> msg } -> Active -> Model -> Html msg
configurationView config active model =
    div [ A.class "stack" ]
        [ if model.busy || model.imageBusy then
            p [ A.class "loading-state", A.attribute "role" "status" ] [ text (T.loadingMessage active.texts) ]

          else
            text ""
        , form [ A.class "form-stack", Events.onSubmit config.save ]
            [ fieldset [ A.class "card form-stack", A.disabled model.busy ]
                (legend [] [ text (T.siteConfiguration active.texts) ]
                    :: List.map (textField config active model) textFields
                )
            , fieldset [ A.class "card form-stack", A.disabled model.busy ]
                ([ legend [] [ text (T.siteRegistrationMode active.texts) ]
                 , label [ A.for "site-registration-mode" ] [ text (T.siteRegistrationMode active.texts) ]
                 , select [ A.id "site-registration-mode", Events.onInput (config.changed "registration_mode") ]
                    (List.map (registrationOption active (fieldValue "registration_mode" model)) [ "open", "closed", "require_application", "require_invitation" ])
                 ]
                    ++ List.map (flagField config active model) flagFields
                )
            , fieldset [ A.class "card form-stack", A.disabled model.busy ]
                (legend [] [ text (T.siteRateLimits active.texts) ]
                    :: List.concatMap (rateFields config active model) rateCategories
                )
            , if not (valid model) then
                p [ A.id "site-configuration-error", A.class "field-error", A.attribute "role" "alert" ] [ text (T.invalidInput active.texts) ]

              else
                text ""
            , viewFormProblem active.texts model.problem
            , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.busy || Set.isEmpty model.dirty || not (valid model)) ] [ text (T.saveChanges active.texts) ]
            ]
        , fieldset [ A.class "card form-stack" ]
            [ legend [] [ text (T.showMedia active.texts) ]
            , imageField config active model "icon" model.icon T.uploadIcon T.siteRemoveIcon
            , imageField config active model "banner" model.banner T.uploadBanner T.siteRemoveBanner
            ]
        ]


fieldValue : String -> Model -> String
fieldValue key model =
    Dict.get key model.fields |> Maybe.withDefault ""


textField : { a | changed : String -> String -> msg } -> Active -> Model -> ( String, T.I18n -> String, Bool ) -> Html msg
textField config active model ( key, labelText, multiline ) =
    let
        identifier =
            "site-config-" ++ key

        attrs =
            [ A.id identifier, A.value (fieldValue key model), Events.onInput (config.changed key) ] ++ validationAttributes model key
    in
    div []
        [ label [ A.for identifier ] [ text (labelText active.texts) ]
        , if multiline then
            textarea attrs []

          else
            input attrs []
        ]


flagField : { a | toggled : String -> Bool -> msg } -> Active -> Model -> ( String, T.I18n -> String ) -> Html msg
flagField config active model ( key, labelText ) =
    label []
        [ input [ A.type_ "checkbox", A.checked (Dict.get key model.flags |> Maybe.withDefault False), Events.onCheck (config.toggled key) ] []
        , text (labelText active.texts)
        ]


registrationOption : Active -> String -> String -> Html msg
registrationOption active selected value =
    option [ A.value value, A.selected (selected == value) ]
        [ text
            (case value of
                "closed" ->
                    T.siteRegistrationClosed active.texts

                "require_application" ->
                    T.siteRegistrationApplication active.texts

                "require_invitation" ->
                    T.siteRegistrationInvitation active.texts

                _ ->
                    T.siteRegistrationOpen active.texts
            )
        ]


rateFields : { a | changed : String -> String -> msg } -> Active -> Model -> ( String, T.I18n -> String ) -> List (Html msg)
rateFields config active model ( category, labelText ) =
    let
        field suffix labelValue =
            let
                key =
                    "rate_limit_" ++ category ++ suffix
            in
            div []
                [ label [ A.for key ] [ text labelValue ]
                , input ([ A.id key, A.type_ "number", A.value (fieldValue key model), Events.onInput (config.changed key) ] ++ validationAttributes model key) []
                ]
    in
    [ field "_max_requests" (T.siteRateRequests (labelText active.texts) active.texts)
    , field "_interval_seconds" (T.siteRateInterval (labelText active.texts) active.texts)
    ]


imageField : { a | imageSelected : String -> Maybe File -> msg, imageRemove : String -> msg } -> Active -> Model -> String -> Maybe String -> (T.I18n -> String) -> (T.I18n -> String) -> Html msg
imageField config active model kind url uploadLabel removeLabel =
    div [ A.class "form-stack" ]
        [ case url of
            Just imageUrl ->
                img [ A.src imageUrl, A.alt (uploadLabel active.texts), A.width 100 ] []

            Nothing ->
                text ""
        , label [ A.for ("site-" ++ kind ++ "-file") ] [ text (uploadLabel active.texts) ]
        , input [ A.id ("site-" ++ kind ++ "-file"), A.type_ "file", A.attribute "accept" "image/*", A.disabled model.imageBusy, Events.on "change" (D.maybe (D.at [ "target", "files", "0" ] File.decoder) |> D.map (config.imageSelected kind)) ] []
        , button [ A.id ("site-remove-" ++ kind), A.type_ "button", A.disabled (model.imageBusy || url == Nothing), Events.onClick (config.imageRemove kind) ] [ text (removeLabel active.texts) ]
        ]
