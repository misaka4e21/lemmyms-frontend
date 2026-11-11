module Feature.CommunityCreate exposing (CommunityForm, Config, Model, Msg(..), Outcome, emptyCommunityForm, initial, normalizePolicies, pageNewCommunity, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, input, label, option, p, select, text, textarea)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Ui.CommunityPolicy exposing (policyFields)
import Ui.Feedback exposing (loginRequired, viewFormProblem)
import Ui.Layout exposing (pageHeading)


type alias CommunityForm =
    { name : String
    , title : String
    , sidebar : String
    , summary : String
    , nsfw : Bool
    , postingRestricted : Bool
    , discussionLanguages : String
    , postUpvotes : String
    , postDownvotes : String
    , commentUpvotes : String
    , commentDownvotes : String
    , mode : String
    , readPolicy : String
    , postPolicy : String
    , busy : Bool
    , problem : Maybe Api.Problem
    }


emptyCommunityForm : CommunityForm
emptyCommunityForm =
    { name = ""
    , title = ""
    , sidebar = ""
    , summary = ""
    , nsfw = False
    , postingRestricted = False
    , discussionLanguages = ""
    , postUpvotes = "all"
    , postDownvotes = "all"
    , commentUpvotes = "all"
    , commentDownvotes = "all"
    , mode = "public"
    , readPolicy = "eligible_users"
    , postPolicy = "eligible_users"
    , busy = False
    , problem = Nothing
    }


normalizePolicies : CommunityForm -> CommunityForm
normalizePolicies form =
    if form.postPolicy == "eligible_users" && form.readPolicy == "members" then
        { form | readPolicy = "eligible_users" }

    else
        form


setField : String -> String -> CommunityForm -> CommunityForm
setField field value form =
    case field of
        "sidebar" ->
            { form | sidebar = value }

        "summary" ->
            { form | summary = value }

        "nsfw" ->
            { form | nsfw = value == "true" }

        "postingRestricted" ->
            { form | postingRestricted = value == "true" }

        "discussionLanguages" ->
            { form | discussionLanguages = value }

        "postUpvotes" ->
            { form | postUpvotes = value }

        "postDownvotes" ->
            { form | postDownvotes = value }

        "commentUpvotes" ->
            { form | commentUpvotes = value }

        "commentDownvotes" ->
            { form | commentDownvotes = value }

        "visibility" ->
            { form | mode = value }

        _ ->
            form


type alias Model =
    { createCommunity : CommunityForm }


initial : Model
initial =
    { createCommunity = emptyCommunityForm }


type Msg
    = Created Api.Response
    | CommunityNameChanged String
    | CommunityTitleChanged String
    | CommunityFieldChanged String String
    | CommunityModeChanged String
    | CommunityReadChanged String
    | CommunityPostChanged String
    | CommunityCreate


type alias Outcome =
    { flash : Flash, navigation : Maybe String }


type alias Working =
    { createCommunity : CommunityForm, flash : Flash, navigation : Maybe String }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf message { createCommunity = state.createCommunity, flash = NoFlash, navigation = Nothing }
    in
    ( { createCommunity = next.createCommunity }, command, { flash = next.flash, navigation = next.navigation } )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        CommunityNameChanged value ->
            ( { model | createCommunity = (\form -> { form | name = value, problem = Nothing }) model.createCommunity }, Cmd.none )

        CommunityTitleChanged value ->
            ( { model | createCommunity = (\form -> { form | title = value, problem = Nothing }) model.createCommunity }, Cmd.none )

        CommunityFieldChanged field value ->
            ( { model
                | createCommunity =
                    (\form ->
                        let
                            updated =
                                setField field value form
                        in
                        { updated | problem = Nothing }
                    )
                        model.createCommunity
              }
            , Cmd.none
            )

        CommunityModeChanged value ->
            ( { model | createCommunity = (\form -> { form | mode = value, problem = Nothing }) model.createCommunity }, Cmd.none )

        CommunityReadChanged value ->
            ( { model
                | createCommunity =
                    (\form ->
                        { form
                            | readPolicy = value
                            , postPolicy =
                                if value == "members" && form.postPolicy == "eligible_users" then
                                    "members"

                                else
                                    form.postPolicy
                        }
                    )
                        model.createCommunity
              }
            , Cmd.none
            )

        CommunityPostChanged value ->
            ( { model
                | createCommunity =
                    (\form ->
                        { form
                            | postPolicy = value
                            , readPolicy =
                                if value == "eligible_users" && form.readPolicy == "members" then
                                    "eligible_users"

                                else
                                    form.readPolicy
                        }
                    )
                        model.createCommunity
              }
            , Cmd.none
            )

        CommunityCreate ->
            if model.createCommunity.busy then
                ( model, Cmd.none )

            else
                ( { model | createCommunity = (\form -> { form | busy = True, problem = Nothing }) model.createCommunity }
                , Api.send csrf
                    "POST"
                    "/community"
                    (Encode.encode 0
                        (Encode.object
                            [ ( "name", Encode.string model.createCommunity.name )
                            , ( "title", Encode.string model.createCommunity.title )
                            , ( "sidebar", Encode.string model.createCommunity.sidebar )
                            , ( "summary", Encode.string model.createCommunity.summary )
                            , ( "nsfw", Encode.bool model.createCommunity.nsfw )
                            , ( "visibility", Encode.string model.createCommunity.mode )
                            , ( "posting_restricted_to_mods", Encode.bool model.createCommunity.postingRestricted )
                            , ( "discussion_languages", Encode.list Encode.int (parseIds model.createCommunity.discussionLanguages) )
                            , ( "post_upvotes", Encode.string model.createCommunity.postUpvotes )
                            , ( "post_downvotes", Encode.string model.createCommunity.postDownvotes )
                            , ( "comment_upvotes", Encode.string model.createCommunity.commentUpvotes )
                            , ( "comment_downvotes", Encode.string model.createCommunity.commentDownvotes )
                            ]
                        )
                    )
                    Created
                )

        Created response ->
            case Api.decodeResponse (Decode.field "community_view" Domain.communityView) response of
                Ok community ->
                    ( { model | createCommunity = emptyCommunityForm, flash = FlashCreated, navigation = Just (Route.path (Route.Community community.community.name)) }, Cmd.none )

                Err problem ->
                    ( { model | createCommunity = (\form -> { form | busy = False, problem = Just problem }) model.createCommunity }, Cmd.none )


parseIds : String -> List Int
parseIds value =
    value
        |> String.split ","
        |> List.filterMap (String.trim >> String.toInt)


type alias Config msg =
    { retry : msg
    , communityNameChanged : String -> msg
    , communityTitleChanged : String -> msg
    , communityFieldChanged : String -> String -> msg
    , communityModeChanged : String -> msg
    , communityReadChanged : String -> msg
    , communityPostChanged : String -> msg
    , communityCreate : msg
    }


type alias ViewModel =
    { createCommunity : CommunityForm
    , auth : AuthState
    }


pageNewCommunity : Config msg -> ViewModel -> Active -> Html msg
pageNewCommunity config model active =
    pageHeading (Translations.createCommunity active.texts)
        (case model.auth of
            Authenticated _ ->
                form [ Events.onSubmit config.communityCreate, A.class "card form-stack" ]
                    [ div []
                        [ label [ A.for "community-name" ] [ text (Translations.communityName active.texts) ]
                        , input [ A.id "community-name", A.type_ "text", A.required True, A.value model.createCommunity.name, Events.onInput config.communityNameChanged ]
                            []
                        , p [ A.class "muted" ] [ text (Translations.communityNameHelp active.texts) ]
                        ]
                    , div []
                        [ label [ A.for "community-title" ] [ text (Translations.communityTitle active.texts) ]
                        , input [ A.id "community-title", A.type_ "text", A.required True, A.value model.createCommunity.title, Events.onInput config.communityTitleChanged ]
                            []
                        ]
                    , textAreaField "community-sidebar" (Translations.communitySidebar active.texts) model.createCommunity.sidebar "sidebar" config
                    , fieldInput "community-summary" (Translations.communitySummary active.texts) model.createCommunity.summary "summary" config
                    , checkboxField "community-nsfw" (Translations.communityNsfw active.texts) model.createCommunity.nsfw "nsfw" config
                    , selectField "community-visibility"
                        (Translations.communityVisibility active.texts)
                        model.createCommunity.mode
                        "visibility"
                        [ ( "public", Translations.visibilityPublic active.texts )
                        , ( "unlisted", Translations.visibilityUnlisted active.texts )
                        , ( "local_only_public", Translations.visibilityLocalPublic active.texts )
                        , ( "local_only_private", Translations.visibilityLocalPrivate active.texts )
                        , ( "private", Translations.visibilityPrivate active.texts )
                        ]
                        config
                    , checkboxField "community-posting-restricted" (Translations.postingRestricted active.texts) model.createCommunity.postingRestricted "postingRestricted" config
                    , fieldInput "community-languages" (Translations.discussionLanguages active.texts) model.createCommunity.discussionLanguages "discussionLanguages" config
                    , voteSelect "community-post-upvotes" (Translations.postUpvotes active.texts) model.createCommunity.postUpvotes "postUpvotes" config active
                    , voteSelect "community-post-downvotes" (Translations.postDownvotes active.texts) model.createCommunity.postDownvotes "postDownvotes" config active
                    , voteSelect "community-comment-upvotes" (Translations.commentUpvotes active.texts) model.createCommunity.commentUpvotes "commentUpvotes" config active
                    , voteSelect "community-comment-downvotes" (Translations.commentDownvotes active.texts) model.createCommunity.commentDownvotes "commentDownvotes" config active
                    , viewFormProblem active.texts model.createCommunity.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.createCommunity.busy ]
                        [ text (Translations.create active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )


fieldInput : String -> String -> String -> String -> Config msg -> Html msg
fieldInput identifier labelText value field config =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , input [ A.id identifier, A.type_ "text", A.value value, Events.onInput (config.communityFieldChanged field) ] []
        ]


textAreaField : String -> String -> String -> String -> Config msg -> Html msg
textAreaField identifier labelText value field config =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , textarea [ A.id identifier, A.value value, Events.onInput (config.communityFieldChanged field) ] []
        ]


checkboxField : String -> String -> Bool -> String -> Config msg -> Html msg
checkboxField identifier labelText checked field config =
    label [ A.for identifier ]
        [ input
            [ A.id identifier
            , A.type_ "checkbox"
            , A.checked checked
            , Events.onCheck (config.communityFieldChanged field << boolText)
            ]
            []
        , text (" " ++ labelText)
        ]


selectField : String -> String -> String -> String -> List ( String, String ) -> Config msg -> Html msg
selectField identifier labelText value field options config =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , select
            [ A.id identifier
            , Events.on "change" (Decode.map (config.communityFieldChanged field) (Decode.at [ "target", "value" ] Decode.string))
            ]
            (List.map (\( optionValue, optionLabel ) -> option [ A.value optionValue, A.selected (value == optionValue) ] [ text optionLabel ]) options)
        ]


voteSelect : String -> String -> String -> String -> Config msg -> Active -> Html msg
voteSelect identifier labelText value field config active =
    selectField identifier
        labelText
        value
        field
        [ ( "all", Translations.voteAll active.texts )
        , ( "local", Translations.voteLocal active.texts )
        , ( "subscribed", Translations.voteSubscribed active.texts )
        , ( "disable", Translations.voteDisabled active.texts )
        ]
        config


boolText : Bool -> String
boolText value =
    if value then
        "true"

    else
        "false"
