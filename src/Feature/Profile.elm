module Feature.Profile exposing (Action(..), AvatarChange(..), Config, Model, Msg(..), Outcome, ProfileForm, clearPrivate, emptyProfileForm, initial, loadOwn, loadPublic, pagePublicProfile, pageSettings, profileCard, profileFormFrom, reset, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Feature.Authoring.State as AuthoringState
import Feature.Authoring.Update as Authoring
import Feature.Authoring.View as AuthoringView
import File exposing (File)
import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, div, form, h2, img, input, label, nav, p, section, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Lemmy.Route as Route
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Formatting exposing (boolText)
import Ui.Layout exposing (entityHeading, pageHeading)
import Ui.Pagination exposing (viewPagination)
import Ui.Rich
import Url


type AvatarChange
    = KeepAvatar
    | ClearAvatar
    | ReplaceAvatar String


type alias ProfileForm =
    { displayName : String
    , authoring : AuthoringState.Model
    , avatar : AvatarChange
    , avatarUrl : String
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    }


emptyProfileForm : ProfileForm
emptyProfileForm =
    { displayName = "", authoring = AuthoringState.init "profile-bio" "", avatar = KeepAvatar, avatarUrl = "", uploading = False, saving = False, problem = Nothing }


profileFormFrom : Domain.PersonView -> ProfileForm
profileFormFrom profile =
    { displayName = Domain.displayNameOf profile.person
    , authoring = AuthoringState.init "profile-bio" (Maybe.withDefault "" profile.person.bio)
    , avatar = KeepAvatar
    , avatarUrl = Domain.avatarOf profile.person
    , uploading = False
    , saving = False
    , problem = Nothing
    }


type alias Model =
    { publicProfile : Remote Domain.PersonView
    , ownProfile : Remote Domain.PersonView
    , profileForm : ProfileForm
    , content : Remote ProfileContent
    , contentView : String
    }


type ProfileContent
    = PersonPosts (Domain.Page Domain.PersonContentItem)
    | AccountPosts (Domain.Page Domain.PostView)


initial : Model
initial =
    { publicProfile = NotAsked
    , ownProfile = NotAsked
    , profileForm = emptyProfileForm
    , content = NotAsked
    , contentView = "posts"
    }


type Msg
    = ActionDone Action Api.Response
    | PublicLoaded Api.Response
    | OwnLoaded Api.Response
    | ProfileDisplayNameChanged String
    | ProfileAuthoring Authoring.Msg
    | ProfileClearAvatar
    | ProfileSave
    | AvatarFileSelected (Maybe File)
    | PersonContentLoaded Api.Response
    | AccountContentLoaded Api.Response


type Action
    = ProfileSaveAction
    | UploadAvatarAction


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


type alias Working =
    { publicProfile : Remote Domain.PersonView
    , ownProfile : Remote Domain.PersonView
    , profileForm : ProfileForm
    , content : Remote ProfileContent
    , contentView : String
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message state =
    let
        ( next, command ) =
            updateWorking csrf
                message
                { publicProfile = state.publicProfile
                , ownProfile = state.ownProfile
                , profileForm = state.profileForm
                , content = state.content
                , contentView = state.contentView
                , flash = NoFlash
                , sessionProblem = Nothing
                }
    in
    ( { publicProfile = next.publicProfile
      , ownProfile = next.ownProfile
      , profileForm = next.profileForm
      , content = next.content
      , contentView = next.contentView
      }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem }
    )


updateWorking : String -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf message model =
    case message of
        ProfileDisplayNameChanged value ->
            ( { model | profileForm = (\form -> { form | displayName = value, problem = Nothing }) model.profileForm }, Cmd.none )

        ProfileAuthoring authoringMessage ->
            let
                ( authoring, command, outcome ) =
                    Authoring.update authoringMessage model.profileForm.authoring
            in
            ( { model
                | profileForm =
                    (\form ->
                        { form
                            | authoring = authoring
                            , problem =
                                if outcome.changed then
                                    Nothing

                                else
                                    form.problem
                        }
                    )
                        model.profileForm
              }
            , Cmd.map ProfileAuthoring command
            )

        ProfileClearAvatar ->
            ( { model | profileForm = (\form -> { form | avatar = ClearAvatar, avatarUrl = "", problem = Nothing }) model.profileForm }, Cmd.none )

        ProfileSave ->
            let
                avatar =
                    case model.profileForm.avatar of
                        KeepAvatar ->
                            []

                        ClearAvatar ->
                            [ ( "avatar", Encode.null ) ]

                        ReplaceAvatar id ->
                            [ ( "avatar", Encode.string model.profileForm.avatarUrl ) ]
            in
            ( { model | profileForm = (\form -> { form | saving = True, problem = Nothing }) model.profileForm }
            , Api.send csrf
                "PUT"
                "/account/settings/save"
                (Encode.encode 0
                    (Encode.object
                        ([ ( "display_name", Encode.string model.profileForm.displayName )
                         , ( "bio", Encode.string (AuthoringState.value model.profileForm.authoring) )
                         ]
                            ++ avatar
                        )
                    )
                )
                (ActionDone ProfileSaveAction)
            )

        AvatarFileSelected maybeFile ->
            case maybeFile of
                Just file ->
                    ( { model | profileForm = (\form -> { form | uploading = True, problem = Nothing }) model.profileForm }
                    , Api.upload csrf "avatar" file (ActionDone UploadAvatarAction)
                    )

                Nothing ->
                    ( model, Cmd.none )

        ActionDone action response ->
            case action of
                ProfileSaveAction ->
                    case Api.decodeUnit response of
                        Ok () ->
                            ( { model | profileForm = (\form -> { form | saving = False, problem = Nothing }) model.profileForm, flash = FlashSaved }
                            , Api.get "/account" OwnLoaded
                            )

                        Err problem ->
                            ( { model | profileForm = (\form -> { form | saving = False, problem = Just problem }) model.profileForm }, Cmd.none )

                UploadAvatarAction ->
                    case Api.decodeResponse Domain.imageUpload response of
                        Ok uploaded ->
                            ( { model
                                | profileForm =
                                    (\form ->
                                        { form
                                            | uploading = False
                                            , avatar = ReplaceAvatar uploaded.filename
                                            , avatarUrl = uploaded.imageUrl
                                        }
                                    )
                                        model.profileForm
                                , flash = FlashUploaded
                              }
                            , Cmd.none
                            )

                        Err problem ->
                            ( { model | profileForm = (\form -> { form | uploading = False, problem = Just problem }) model.profileForm }, Cmd.none )

        PublicLoaded response ->
            case Api.decodeResponse (Decode.field "person_view" Domain.personView) response of
                Ok profile ->
                    ( { model | publicProfile = Ready profile }, Cmd.none )

                Err problem ->
                    ( { model
                        | publicProfile = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        PersonContentLoaded response ->
            case Api.decodeResponse Domain.personContentPage response of
                Ok page ->
                    ( { model | content = Ready (PersonPosts page) }, Cmd.none )

                Err problem ->
                    ( { model
                        | content = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        AccountContentLoaded response ->
            case Api.decodeResponse (Domain.page Domain.postView) response of
                Ok page ->
                    ( { model | content = Ready (AccountPosts page) }, Cmd.none )

                Err problem ->
                    ( { model
                        | content = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )

        OwnLoaded response ->
            case Api.decodeResponse Domain.ownPersonView response of
                Ok profile ->
                    ( { model | ownProfile = Ready profile, profileForm = profileFormFrom profile }, Cmd.none )

                Err problem ->
                    ( { model
                        | ownProfile = Failed problem
                        , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    , Cmd.none
                    )


type alias Config msg =
    { retry : msg
    , profileDisplayNameChanged : String -> msg
    , profileAuthoring : Authoring.Msg -> msg
    , profileClearAvatar : msg
    , profileSave : msg
    , avatarFileSelected : Maybe File -> msg
    , postCard : Domain.PostView -> Html msg
    , tabNavigate : String -> msg
    }


type alias ViewModel =
    { publicProfile : Remote Domain.PersonView
    , ownProfile : Remote Domain.PersonView
    , profileForm : ProfileForm
    , auth : AuthState
    , content : Remote ProfileContent
    , contentView : String
    , url : Url.Url
    }


pagePublicProfile : Config msg -> ViewModel -> Active -> String -> Html msg
pagePublicProfile config model active username =
    entityHeading (Translations.profileTitle active.texts)
        (viewRemote config.retry
            active.texts
            model.publicProfile
            (\profile ->
                div [ A.class "stack" ]
                    [ profileCard active profile
                    , messageAction active model.auth profile
                    , profileTabs config model active username
                    , profileContent config model active
                    ]
            )
        )


messageAction : Active -> AuthState -> Domain.PersonView -> Html msg
messageAction active auth profile =
    case auth of
        Authenticated account ->
            if
                account.localUserView.person.id
                    == profile.person.id
                    || not account.localUserView.localUser.privateMessagesEnabled
            then
                text ""

            else
                div [ A.class "actions" ]
                    [ a [ A.class "outlined-button", A.href (Route.path (Route.CreatePrivateMessage profile.person.id)) ]
                        [ text (Translations.sendMessage active.texts) ]
                    ]

        _ ->
            text ""


profileTabs : Config msg -> ViewModel -> Active -> String -> Html msg
profileTabs config model active username =
    let
        current =
            model.contentView

        own =
            case model.auth of
                Authenticated account ->
                    Domain.isOwnProfile account username

                _ ->
                    False

        tab view label =
            a
                [ A.href (profileViewUrl username view)
                , A.class "outlined-button"
                , A.attribute "role" "tab"
                , A.attribute "aria-selected" (boolText (view == current))
                , A.tabindex
                    (if view == current then
                        0

                     else
                        -1
                    )
                , Events.on "keydown"
                    (Decode.field "key" Decode.string
                        |> Decode.andThen
                            (\key ->
                                case key of
                                    "ArrowRight" ->
                                        Decode.succeed (config.tabNavigate (profileViewUrl username (nextView own current)))

                                    "ArrowLeft" ->
                                        Decode.succeed (config.tabNavigate (profileViewUrl username (previousView own current)))

                                    _ ->
                                        Decode.fail "ignore"
                            )
                    )
                ]
                [ text (label active.texts) ]
    in
    nav
        [ A.class "tabs", A.attribute "role" "tablist" ]
        ([ tab "posts" Translations.profilePosts
         , tab "comments" Translations.profileComments
         ]
            ++ (if own then
                    [ tab "saved" Translations.profileSaved
                    , tab "liked" Translations.profileLiked
                    , tab "read" Translations.profileRead
                    , tab "hidden" Translations.profileHidden
                    ]

                else
                    []
               )
        )


profileViews : Bool -> List String
profileViews own =
    if own then
        [ "posts", "comments", "saved", "liked", "read", "hidden" ]

    else
        [ "posts", "comments" ]


nextView : Bool -> String -> String
nextView own current =
    nextInList current (profileViews own)


previousView : Bool -> String -> String
previousView own current =
    nextInList current (List.reverse (profileViews own))


nextInList : String -> List String -> String
nextInList current views =
    case views of
        [] ->
            current

        first :: rest ->
            if first == current then
                Maybe.withDefault current (List.head rest)

            else
                nextInList current rest


profileViewUrl : String -> String -> String
profileViewUrl username view =
    Route.path (Route.Profile username) ++ "?view=" ++ view


profileContent : Config msg -> ViewModel -> Active -> Html msg
profileContent config model active =
    viewRemote config.retry
        active.texts
        model.content
        (\content ->
            case content of
                PersonPosts page ->
                    if List.isEmpty page.items then
                        p [ A.class "empty-state" ] [ text (Translations.noContent active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (personContentItem config) page.items)
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]

                AccountPosts page ->
                    if List.isEmpty page.items then
                        p [ A.class "empty-state" ] [ text (Translations.noContent active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map config.postCard page.items)
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]
        )


personContentItem : Config msg -> Domain.PersonContentItem -> Html msg
personContentItem config item =
    case item of
        Domain.PersonPost post ->
            config.postCard post

        Domain.PersonComment comment ->
            article [ A.class "card" ]
                [ p [ A.class "metadata" ]
                    [ a [ A.href (Route.path (Route.Post comment.post.id (Just comment.comment.id))) ]
                        [ text (Domain.displayNameOf comment.creator) ]
                    ]
                , Markdown.render comment.comment.content
                ]


profileCard : Active -> Domain.PersonView -> Html msg
profileCard active profile =
    let
        displayName =
            Domain.displayNameOf profile.person

        avatar =
            Domain.avatarOf profile.person
    in
    section [ A.class "card profile-card" ]
        [ if String.isEmpty avatar then
            text ""

          else
            img [ A.src avatar, A.alt displayName, A.class "avatar", A.attribute "referrerpolicy" "no-referrer" ] []
        , h2 []
            [ text displayName ]
        , p [ A.class "metadata" ] [ bdi [] [ text profile.person.apId ] ]
        , Markdown.render (Maybe.withDefault "" profile.person.bio)
        , p [ A.class "muted" ] [ text (Translations.publicProfileNote active.texts) ]
        ]


pageSettings : Config msg -> ViewModel -> Active -> Html msg
pageSettings config model active =
    pageHeading (Translations.settingsTitle active.texts)
        (case model.auth of
            Authenticated _ ->
                form [ Events.onSubmit config.profileSave, A.class "card form-stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.publicProfileNote active.texts) ]
                    , div []
                        [ label [ A.for "profile-name" ] [ text (Translations.displayName active.texts) ]
                        , input [ A.id "profile-name", A.type_ "text", A.attribute "autocomplete" "name", A.value model.profileForm.displayName, Events.onInput config.profileDisplayNameChanged ]
                            []
                        ]
                    , AuthoringView.view
                        { id = "profile-bio"
                        , label = Translations.biography active.texts
                        , helpId = "profile-bio-help"
                        , helpText = Translations.biographyHelp active.texts
                        , required = False
                        , toMsg = config.profileAuthoring
                        }
                        active
                        model.profileForm.authoring
                    , div []
                        [ label [ A.for "profile-avatar" ] [ text (Translations.avatar active.texts) ]
                        , if String.isEmpty model.profileForm.avatarUrl then
                            text ""

                          else
                            img [ A.src model.profileForm.avatarUrl, A.alt "", A.class "avatar", A.attribute "referrerpolicy" "no-referrer" ] []
                        , input
                            [ A.id "profile-avatar"
                            , A.type_ "file"
                            , A.attribute "accept" "image/*"
                            , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map config.avatarFileSelected)
                            ]
                            []
                        , button [ A.type_ "button", A.class "text-button", Events.onClick config.profileClearAvatar ]
                            [ text (Translations.removeAvatar active.texts) ]
                        ]
                    , viewFormProblem active.texts model.profileForm.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled (model.profileForm.saving || model.profileForm.uploading) ]
                        [ text (Translations.saveProfile active.texts) ]
                    , a [ A.href (Route.path Route.PasswordSettings) ] [ text (Translations.changePasswordTitle active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )


reset : Model -> Model
reset model =
    { model | publicProfile = NotAsked, ownProfile = NotAsked, content = NotAsked }


clearPrivate : Model -> Model
clearPrivate model =
    { model | ownProfile = NotAsked, profileForm = emptyProfileForm, content = NotAsked }


loadPublic : Url.Url -> String -> String -> Maybe Domain.MyUserInfo -> Model -> ( Model, Cmd Msg )
loadPublic url username requestedView viewer model =
    let
        own =
            case viewer of
                Just account ->
                    Domain.isOwnProfile account username

                Nothing ->
                    False

        view =
            normalizedProfileView own requestedView

        contentCommand =
            if List.member view [ "saved", "liked", "read", "hidden" ] then
                Api.get ("/account/" ++ view ++ "?limit=20" ++ cursorQuery url) AccountContentLoaded

            else
                Api.get
                    ("/person/content?username="
                        ++ Url.percentEncode username
                        ++ "&type_="
                        ++ (if view == "comments" then
                                "comments"

                            else
                                "posts"
                           )
                        ++ "&limit=20"
                        ++ cursorQuery url
                    )
                    PersonContentLoaded
    in
    ( { model | publicProfile = Loading, content = Loading, contentView = view }
    , Cmd.batch
        [ Api.get ("/person?username=" ++ Url.percentEncode username) PublicLoaded
        , contentCommand
        ]
    )


cursorQuery : Url.Url -> String
cursorQuery url =
    case Route.cursor url of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


normalizedProfileView : Bool -> String -> String
normalizedProfileView own value =
    if List.member value [ "posts", "comments" ] then
        value

    else if own && List.member value [ "saved", "liked", "read", "hidden" ] then
        value

    else
        "posts"


loadOwn : Model -> ( Model, Cmd Msg )
loadOwn model =
    ( { model | ownProfile = Loading }, Api.get "/account" OwnLoaded )
