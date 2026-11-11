module Feature.AccountSettings exposing (Model, Msg(..), Outcome, initial, load, update, view)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import File exposing (File)
import Generated.I18n as Translations
import Html exposing (Html, a, bdi, button, code, div, fieldset, form, h2, h3, img, input, label, legend, li, option, p, section, select, text, textarea, time, ul)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import List
import Ports exposing (closeDialog, download, focus, openDialog, setTheme)
import Remote exposing (Remote(..))
import Task
import Ui.Feedback exposing (loginRequired, viewFormProblem)
import Ui.Layout exposing (pageHeading)
import Url


type alias SettingsForm =
    { displayName : String
    , email : String
    , matrixUserId : String
    , bio : String
    , botAccount : Bool
    , avatarUrl : String
    , bannerUrl : String
    , theme : String
    , interfaceLanguage : String
    , defaultListingType : String
    , postListingMode : String
    , defaultPostSortType : String
    , defaultCommentSortType : String
    , defaultPostTimeRange : String
    , defaultItemsPerPage : String
    , showNsfw : Bool
    , blurNsfw : Bool
    , showAvatars : Bool
    , showMedia : Bool
    , showBotAccounts : Bool
    , showReadPosts : Bool
    , openLinksInNewTab : Bool
    , infiniteScrollEnabled : Bool
    , animatedImagesEnabled : Bool
    , collapseBotComments : Bool
    , autoMarkFetchedPostsAsRead : Bool
    , hidePostsWithMedia : Bool
    , sendNotificationsToEmail : Bool
    , privateMessagesEnabled : Bool
    , discussionLanguages : String
    , blockingKeywords : String
    , showScore : Bool
    , showUpvotes : Bool
    , showDownvotes : String
    , showUpvotePercentage : Bool
    , showPersonVotes : Bool
    , totpEnabled : Bool
    }


type TotpState
    = TotpIdle
    | TotpSetup String
    | TotpBusy
    | TotpFailed Api.Problem


type alias DeleteState =
    { password : String
    , deleteContent : Bool
    , busy : Bool
    , problem : Maybe Api.Problem
    }


type alias Model =
    { form : Maybe SettingsForm
    , loading : Bool
    , problem : Maybe Api.Problem
    , saving : Bool
    , avatarUploading : Bool
    , bannerUploading : Bool
    , totp : TotpState
    , totpToken : String
    , logins : Remote (List Domain.LoginToken)
    , deleteDialog : Maybe DeleteState
    , backupBusy : Bool
    , backupProblem : Maybe Api.Problem
    , importName : String
    , invites : Remote (Domain.Page Domain.Invitation)
    , inviteMaxUses : String
    , inviteExpires : String
    , inviteBusy : Bool
    , inviteProblem : Maybe Api.Problem
    }


initial : Model
initial =
    { form = Nothing
    , loading = False
    , problem = Nothing
    , saving = False
    , avatarUploading = False
    , bannerUploading = False
    , totp = TotpIdle
    , totpToken = ""
    , logins = NotAsked
    , deleteDialog = Nothing
    , backupBusy = False
    , backupProblem = Nothing
    , importName = ""
    , invites = NotAsked
    , inviteMaxUses = ""
    , inviteExpires = ""
    , inviteBusy = False
    , inviteProblem = Nothing
    }


type Msg
    = Loaded Api.Response
    | FieldChanged String String
    | ToggleChanged String Bool
    | Save
    | Saved Api.Response
    | AvatarSelected (Maybe File)
    | BannerSelected (Maybe File)
    | ClearAvatar
    | ClearBanner
    | ImageSaved Api.Response
    | TotpGenerate
    | TotpGenerated Api.Response
    | TotpTokenChanged String
    | TotpEnable
    | TotpDisable
    | TotpSaved Bool Api.Response
    | TotpCancelled
    | LoginsLoaded Api.Response
    | OpenDelete
    | CloseDelete
    | DeletePasswordChanged String
    | DeleteContentChanged Bool
    | DeleteAccount
    | AccountDeleted Api.Response
    | ExportSettings
    | ExportData
    | SettingsExported Api.Response
    | DataExported Api.Response
    | ImportSelected (Maybe File)
    | ImportRead (Result String String)
    | Imported Api.Response
    | InvitesLoaded Api.Response
    | InviteMaxUsesChanged String
    | InviteExpiresChanged String
    | CreateInvite
    | InviteCreated Api.Response
    | RevokeInvite String
    | InviteRevoked Api.Response


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem, deleted : Bool }


load : ( Model, Cmd Msg )
load =
    ( { initial | loading = True, logins = Loading, invites = Loading }
    , Cmd.batch
        [ Api.get "/account" Loaded
        , Api.get "/account/login/list" LoginsLoaded
        , Api.get "/account/invite/list?limit=20" InvitesLoaded
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg, Outcome )
update message model =
    let
        keep next command =
            ( next, command, { flash = NoFlash, sessionProblem = Nothing, deleted = False } )
    in
    case message of
        Loaded response ->
            case Api.decodeResponse Domain.myUserInfo response of
                Ok user ->
                    let
                        form =
                            formFrom user
                    in
                    keep
                        { model | form = Just form, loading = False, problem = Nothing }
                        (setTheme form.theme)

                Err problem ->
                    ( { model | loading = False, problem = Just problem }
                    , Cmd.none
                    , { flash = NoFlash, sessionProblem = sessionProblem problem, deleted = False }
                    )

        FieldChanged name value ->
            keep { model | form = Maybe.map (setField name value) model.form } Cmd.none

        ToggleChanged name value ->
            keep { model | form = Maybe.map (setToggle name value) model.form } Cmd.none

        Save ->
            case model.form of
                Just form ->
                    if model.saving then
                        keep model Cmd.none

                    else
                        ( { model | saving = True, problem = Nothing }
                        , Api.send "" "PUT" "/account/settings/save" (Encode.encode 0 (saveBody form)) Saved
                        , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
                        )

                Nothing ->
                    keep model Cmd.none

        Saved response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | saving = False, problem = Nothing }
                    , Api.get "/account" Loaded
                    , { flash = FlashSaved, sessionProblem = Nothing, deleted = False }
                    )

                Err problem ->
                    ( { model | saving = False, problem = Just problem }
                    , Cmd.none
                    , { flash = FlashProblem problem
                      , sessionProblem = sessionProblem problem
                      , deleted = False
                      }
                    )

        AvatarSelected (Just file) ->
            ( { model | avatarUploading = True }
            , Api.uploadTo "/account/avatar" file ImageSaved
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        BannerSelected (Just file) ->
            ( { model | bannerUploading = True }
            , Api.uploadTo "/account/banner" file ImageSaved
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        AvatarSelected Nothing ->
            keep model Cmd.none

        BannerSelected Nothing ->
            keep model Cmd.none

        ClearAvatar ->
            ( { model | avatarUploading = True }
            , Api.send "" "DELETE" "/account/avatar" "" ImageSaved
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        ClearBanner ->
            ( { model | bannerUploading = True }
            , Api.send "" "DELETE" "/account/banner" "" ImageSaved
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        ImageSaved response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | avatarUploading = False, bannerUploading = False }
                    , Api.get "/account" Loaded
                    , { flash = FlashSaved, sessionProblem = Nothing, deleted = False }
                    )

                Err problem ->
                    ( { model | avatarUploading = False, bannerUploading = False }
                    , Cmd.none
                    , { flash = FlashProblem problem
                      , sessionProblem = sessionProblem problem
                      , deleted = False
                      }
                    )

        TotpGenerate ->
            ( { model | totp = TotpBusy }
            , Api.send "" "POST" "/account/auth/totp/generate" "" TotpGenerated
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        TotpGenerated response ->
            case Api.decodeResponse Domain.totpSecretResponse response of
                Ok secret ->
                    ( { model | totp = TotpSetup secret.totpSecretUrl, totpToken = "" }
                    , Cmd.none
                    , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
                    )

                Err problem ->
                    ( { model | totp = TotpFailed problem }
                    , Cmd.none
                    , { flash = FlashProblem problem, sessionProblem = sessionProblem problem, deleted = False }
                    )

        TotpTokenChanged value ->
            keep { model | totpToken = value } Cmd.none

        TotpEnable ->
            ( { model | totp = TotpBusy }
            , Api.send "" "POST" "/account/auth/totp/edit" (Encode.encode 0 (Encode.object [ ( "totp_token", Encode.string model.totpToken ), ( "enabled", Encode.bool True ) ])) (TotpSaved True)
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        TotpDisable ->
            ( { model | totp = TotpBusy }
            , Api.send "" "POST" "/account/auth/totp/edit" (Encode.encode 0 (Encode.object [ ( "totp_token", Encode.string model.totpToken ), ( "enabled", Encode.bool False ) ])) (TotpSaved False)
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        TotpSaved _ response ->
            case Api.decodeResponse Domain.editTotpResponse response of
                Ok result ->
                    ( { model
                        | totp = TotpIdle
                        , totpToken = ""
                        , form = Maybe.map (\form -> { form | totpEnabled = result.enabled }) model.form
                      }
                    , Cmd.none
                    , { flash = FlashSaved, sessionProblem = Nothing, deleted = False }
                    )

                Err problem ->
                    ( { model | totp = TotpFailed problem }
                    , Cmd.none
                    , { flash = FlashProblem problem, sessionProblem = sessionProblem problem, deleted = False }
                    )

        TotpCancelled ->
            keep { model | totp = TotpIdle, totpToken = "" } Cmd.none

        LoginsLoaded response ->
            case Api.decodeResponse Domain.listLoginsResponse response of
                Ok data ->
                    keep { model | logins = Ready data.logins } Cmd.none

                Err problem ->
                    keep { model | logins = Failed problem } Cmd.none

        OpenDelete ->
            ( { model | deleteDialog = Just { password = "", deleteContent = False, busy = False, problem = Nothing } }
            , openDialog "delete-account-dialog"
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        CloseDelete ->
            ( { model | deleteDialog = Nothing }
            , Cmd.batch [ closeDialog "delete-account-dialog", focus "delete-account-button" ]
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        DeletePasswordChanged value ->
            keep { model | deleteDialog = Maybe.map (\state -> { state | password = value, problem = Nothing }) model.deleteDialog } Cmd.none

        DeleteContentChanged value ->
            keep { model | deleteDialog = Maybe.map (\state -> { state | deleteContent = value }) model.deleteDialog } Cmd.none

        DeleteAccount ->
            case model.deleteDialog of
                Just state ->
                    ( { model | deleteDialog = Just { state | busy = True, problem = Nothing } }
                    , Api.send "" "DELETE" "/account" (Encode.encode 0 (Encode.object [ ( "password", Encode.string state.password ), ( "delete_content", Encode.bool state.deleteContent ) ])) AccountDeleted
                    , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
                    )

                Nothing ->
                    keep model Cmd.none

        AccountDeleted response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | deleteDialog = Nothing }, closeDialog "delete-account-dialog", { flash = FlashSaved, sessionProblem = Nothing, deleted = True } )

                Err problem ->
                    ( { model | deleteDialog = Maybe.map (\state -> { state | busy = False, problem = Just problem }) model.deleteDialog }
                    , Cmd.none
                    , { flash = FlashProblem problem, sessionProblem = sessionProblem problem, deleted = False }
                    )

        ExportSettings ->
            ( { model | backupBusy = True, backupProblem = Nothing }
            , Api.get "/account/settings/export" SettingsExported
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        ExportData ->
            ( { model | backupBusy = True, backupProblem = Nothing }
            , Api.get "/account/data/export" DataExported
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        SettingsExported response ->
            if response.status >= 200 && response.status < 300 then
                ( { model | backupBusy = False }, download "lemmy-settings.json" response.body, { flash = NoFlash, sessionProblem = Nothing, deleted = False } )

            else
                ( { model | backupBusy = False }, Cmd.none, { flash = FlashProblem (problemFrom response), sessionProblem = Nothing, deleted = False } )

        DataExported response ->
            if response.status >= 200 && response.status < 300 then
                ( { model | backupBusy = False }, download "lemmy-data.json" response.body, { flash = NoFlash, sessionProblem = Nothing, deleted = False } )

            else
                ( { model | backupBusy = False }, Cmd.none, { flash = FlashProblem (problemFrom response), sessionProblem = Nothing, deleted = False } )

        ImportSelected (Just file) ->
            ( { model | backupBusy = True, importName = File.name file, backupProblem = Nothing }
            , File.toString file |> Task.attempt ImportRead
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        ImportSelected Nothing ->
            keep model Cmd.none

        ImportRead result ->
            case result of
                Ok content ->
                    case Decode.decodeString Decode.value content of
                        Ok _ ->
                            ( model
                            , Api.send "" "POST" "/account/settings/import" content Imported
                            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
                            )

                        Err _ ->
                            ( { model | backupBusy = False, backupProblem = Just { status = 400, detail = "invalid_json" } }
                            , Cmd.none
                            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
                            )

                Err _ ->
                    ( { model | backupBusy = False, backupProblem = Just { status = 400, detail = "read_failed" } }
                    , Cmd.none
                    , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
                    )

        Imported response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | backupBusy = False, backupProblem = Nothing }
                    , Api.get "/account" Loaded
                    , { flash = FlashSaved, sessionProblem = Nothing, deleted = False }
                    )

                Err problem ->
                    ( { model | backupBusy = False, backupProblem = Just problem }
                    , Cmd.none
                    , { flash = FlashProblem problem, sessionProblem = sessionProblem problem, deleted = False }
                    )

        InvitesLoaded response ->
            case Api.decodeResponse (Domain.page Domain.invitation) response of
                Ok page ->
                    keep { model | invites = Ready page } Cmd.none

                Err problem ->
                    keep { model | invites = Failed problem } Cmd.none

        InviteMaxUsesChanged value ->
            keep { model | inviteMaxUses = value } Cmd.none

        InviteExpiresChanged value ->
            keep { model | inviteExpires = value } Cmd.none

        CreateInvite ->
            ( { model | inviteBusy = True, inviteProblem = Nothing }
            , Api.send "" "POST" "/account/invite" (Encode.encode 0 (Encode.object (inviteBody model))) InviteCreated
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        InviteCreated response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( { model | inviteBusy = False, inviteMaxUses = "", inviteExpires = "", inviteProblem = Nothing }
                    , Api.get "/account/invite/list?limit=20" InvitesLoaded
                    , { flash = FlashSaved, sessionProblem = Nothing, deleted = False }
                    )

                Err problem ->
                    ( { model | inviteBusy = False, inviteProblem = Just problem }
                    , Cmd.none
                    , { flash = FlashProblem problem, sessionProblem = sessionProblem problem, deleted = False }
                    )

        RevokeInvite tokenValue ->
            ( model
            , Api.send "" "DELETE" "/account/invite" (Encode.encode 0 (Encode.object [ ( "token", Encode.string tokenValue ) ])) InviteRevoked
            , { flash = NoFlash, sessionProblem = Nothing, deleted = False }
            )

        InviteRevoked response ->
            case Api.decodeUnit response of
                Ok () ->
                    ( model, Api.get "/account/invite/list?limit=20" InvitesLoaded, { flash = FlashSaved, sessionProblem = Nothing, deleted = False } )

                Err problem ->
                    ( model, Cmd.none, { flash = FlashProblem problem, sessionProblem = sessionProblem problem, deleted = False } )


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


problemFrom : Api.Response -> Api.Problem
problemFrom response =
    { status = response.status, detail = response.body }


formFrom : Domain.MyUserInfo -> SettingsForm
formFrom user =
    let
        local =
            user.localUserView.localUser

        person =
            user.localUserView.person
    in
    { displayName = Maybe.withDefault "" person.displayName
    , email = Maybe.withDefault "" local.email
    , matrixUserId = Maybe.withDefault "" person.matrixUserId
    , bio = Maybe.withDefault "" person.bio
    , botAccount = person.botAccount
    , avatarUrl = Maybe.withDefault "" person.avatar
    , bannerUrl = Maybe.withDefault "" person.banner
    , theme = local.theme
    , interfaceLanguage = local.interfaceLanguage
    , defaultListingType = local.defaultListingType
    , postListingMode = local.postListingMode
    , defaultPostSortType = local.defaultPostSortType
    , defaultCommentSortType = local.defaultCommentSortType
    , defaultPostTimeRange = Maybe.withDefault "" (Maybe.map String.fromInt local.defaultPostTimeRangeSeconds)
    , defaultItemsPerPage = String.fromInt local.defaultItemsPerPage
    , showNsfw = local.showNsfw
    , blurNsfw = local.blurNsfw
    , showAvatars = local.showAvatars
    , showMedia = local.showMedia
    , showBotAccounts = local.showBotAccounts
    , showReadPosts = local.showReadPosts
    , openLinksInNewTab = local.openLinksInNewTab
    , infiniteScrollEnabled = local.infiniteScrollEnabled
    , animatedImagesEnabled = local.animatedImagesEnabled
    , collapseBotComments = local.collapseBotComments
    , autoMarkFetchedPostsAsRead = local.autoMarkFetchedPostsAsRead
    , hidePostsWithMedia = local.hidePostsWithMedia
    , sendNotificationsToEmail = local.sendNotificationsToEmail
    , privateMessagesEnabled = local.privateMessagesEnabled
    , discussionLanguages = String.join "," (List.map String.fromInt user.discussionLanguages)
    , blockingKeywords = String.join "\n" user.keywordBlocks
    , showScore = local.showScore
    , showUpvotes = local.showUpvotes
    , showDownvotes = local.showDownvotes
    , showUpvotePercentage = local.showUpvotePercentage
    , showPersonVotes = local.showPersonVotes
    , totpEnabled = local.totp2faEnabled
    }


setField : String -> String -> SettingsForm -> SettingsForm
setField name value form =
    case name of
        "display_name" ->
            { form | displayName = value }

        "email" ->
            { form | email = value }

        "matrix_user_id" ->
            { form | matrixUserId = value }

        "bio" ->
            { form | bio = value }

        "theme" ->
            { form | theme = value }

        "interface_language" ->
            { form | interfaceLanguage = value }

        "default_listing_type" ->
            { form | defaultListingType = value }

        "post_listing_mode" ->
            { form | postListingMode = value }

        "default_post_sort_type" ->
            { form | defaultPostSortType = value }

        "default_comment_sort_type" ->
            { form | defaultCommentSortType = value }

        "default_post_time_range_seconds" ->
            { form | defaultPostTimeRange = value }

        "default_items_per_page" ->
            { form | defaultItemsPerPage = value }

        "discussion_languages" ->
            { form | discussionLanguages = value }

        "blocking_keywords" ->
            { form | blockingKeywords = value }

        "show_downvotes" ->
            { form | showDownvotes = value }

        _ ->
            form


setToggle : String -> Bool -> SettingsForm -> SettingsForm
setToggle name value form =
    case name of
        "bot_account" ->
            { form | botAccount = value }

        "show_nsfw" ->
            { form | showNsfw = value }

        "blur_nsfw" ->
            { form | blurNsfw = value }

        "show_avatars" ->
            { form | showAvatars = value }

        "show_media" ->
            { form | showMedia = value }

        "show_bot_accounts" ->
            { form | showBotAccounts = value }

        "show_read_posts" ->
            { form | showReadPosts = value }

        "open_links_in_new_tab" ->
            { form | openLinksInNewTab = value }

        "infinite_scroll_enabled" ->
            { form | infiniteScrollEnabled = value }

        "animated_images_enabled" ->
            { form | animatedImagesEnabled = value }

        "collapse_bot_comments" ->
            { form | collapseBotComments = value }

        "auto_mark_fetched_posts_as_read" ->
            { form | autoMarkFetchedPostsAsRead = value }

        "hide_posts_with_media" ->
            { form | hidePostsWithMedia = value }

        "send_notifications_to_email" ->
            { form | sendNotificationsToEmail = value }

        "private_messages_enabled" ->
            { form | privateMessagesEnabled = value }

        "show_score" ->
            { form | showScore = value }

        "show_upvotes" ->
            { form | showUpvotes = value }

        "show_upvote_percentage" ->
            { form | showUpvotePercentage = value }

        "show_person_votes" ->
            { form | showPersonVotes = value }

        _ ->
            form


saveBody : SettingsForm -> Encode.Value
saveBody form =
    Encode.object
        [ ( "display_name", nullableString form.displayName )
        , ( "email", nullableString form.email )
        , ( "matrix_user_id", nullableString form.matrixUserId )
        , ( "bio", nullableString form.bio )
        , ( "bot_account", Encode.bool form.botAccount )
        , ( "theme", Encode.string form.theme )
        , ( "interface_language", Encode.string form.interfaceLanguage )
        , ( "default_listing_type", Encode.string form.defaultListingType )
        , ( "post_listing_mode", Encode.string form.postListingMode )
        , ( "default_post_sort_type", Encode.string form.defaultPostSortType )
        , ( "default_comment_sort_type", Encode.string form.defaultCommentSortType )
        , ( "default_post_time_range_seconds", nullableInt form.defaultPostTimeRange )
        , ( "default_items_per_page", Encode.int (String.toInt form.defaultItemsPerPage |> Maybe.withDefault 20) )
        , ( "show_nsfw", Encode.bool form.showNsfw )
        , ( "blur_nsfw", Encode.bool form.blurNsfw )
        , ( "show_avatars", Encode.bool form.showAvatars )
        , ( "show_media", Encode.bool form.showMedia )
        , ( "show_bot_accounts", Encode.bool form.showBotAccounts )
        , ( "show_read_posts", Encode.bool form.showReadPosts )
        , ( "open_links_in_new_tab", Encode.bool form.openLinksInNewTab )
        , ( "infinite_scroll_enabled", Encode.bool form.infiniteScrollEnabled )
        , ( "animated_images_enabled", Encode.bool form.animatedImagesEnabled )
        , ( "collapse_bot_comments", Encode.bool form.collapseBotComments )
        , ( "auto_mark_fetched_posts_as_read", Encode.bool form.autoMarkFetchedPostsAsRead )
        , ( "hide_posts_with_media", Encode.bool form.hidePostsWithMedia )
        , ( "send_notifications_to_email", Encode.bool form.sendNotificationsToEmail )
        , ( "private_messages_enabled", Encode.bool form.privateMessagesEnabled )
        , ( "discussion_languages", Encode.list Encode.int (parseIds form.discussionLanguages) )
        , ( "blocking_keywords", Encode.list Encode.string (keywordList form.blockingKeywords) )
        , ( "show_score", Encode.bool form.showScore )
        , ( "show_upvotes", Encode.bool form.showUpvotes )
        , ( "show_downvotes", Encode.string form.showDownvotes )
        , ( "show_upvote_percentage", Encode.bool form.showUpvotePercentage )
        , ( "show_person_votes", Encode.bool form.showPersonVotes )
        ]


nullableString : String -> Encode.Value
nullableString value =
    if String.isEmpty (String.trim value) then
        Encode.null

    else
        Encode.string value


nullableInt : String -> Encode.Value
nullableInt value =
    case String.toInt (String.trim value) of
        Just number ->
            Encode.int number

        Nothing ->
            Encode.null


parseIds : String -> List Int
parseIds value =
    value
        |> String.split ","
        |> List.filterMap (String.trim >> String.toInt)


keywordList : String -> List String
keywordList value =
    value
        |> String.split "\n"
        |> List.map String.trim
        |> List.filter (not << String.isEmpty)


inviteBody : Model -> List ( String, Encode.Value )
inviteBody model =
    [ ( "max_uses"
      , case String.toInt (String.trim model.inviteMaxUses) of
            Just number ->
                Encode.int number

            Nothing ->
                Encode.null
      )
    , ( "expires_at"
      , if String.isEmpty (String.trim model.inviteExpires) then
            Encode.null

        else
            Encode.string (String.trim model.inviteExpires)
      )
    ]


view : Active -> AuthState -> Model -> Html Msg
view active auth model =
    pageHeading (Translations.accountSettings active.texts)
        (case auth of
            Authenticated _ ->
                case model.form of
                    Nothing ->
                        if model.loading then
                            p [ A.class "muted", A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]

                        else
                            viewFormProblem active.texts model.problem

                    Just settings ->
                        div [ A.class "stack" ]
                            [ form [ Events.onSubmit Save, A.class "stack" ]
                                [ identitySection active settings
                                , appearanceSection active settings
                                , contentSection active settings
                                , notificationsSection active settings
                                , languagesSection active settings
                                , votesSection active settings
                                , viewFormProblem active.texts model.problem
                                , button [ A.type_ "submit", A.class "filled-button", A.disabled model.saving ]
                                    [ text (Translations.saveChanges active.texts) ]
                                ]
                            , securitySection active model
                            , backupSection active model
                            , invitationsSection active model
                            ]

            CheckingSession ->
                p [ A.class "muted", A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]

            Anonymous ->
                loginRequired active.texts
        )


identitySection : Active -> SettingsForm -> Html Msg
identitySection active form =
    fieldset [ A.class "card form-stack" ]
        [ legend [] [ text (Translations.identitySection active.texts) ]
        , textField active "display-name" Translations.displayName form.displayName (FieldChanged "display_name")
        , textField active "account-email" Translations.email form.email (FieldChanged "email")
        , textField active "matrix-user-id" Translations.matrixId form.matrixUserId (FieldChanged "matrix_user_id")
        , div []
            [ label [ A.for "account-bio" ] [ text (Translations.biography active.texts) ]
            , textarea
                [ A.id "account-bio"
                , A.value form.bio
                , Events.onInput (FieldChanged "bio")
                ]
                []
            ]
        , checkboxField active "bot-account" Translations.botAccount form.botAccount (ToggleChanged "bot_account")
        , div [ A.class "settings-images" ]
            [ imageControl active "account-avatar" Translations.avatar form.avatarUrl AvatarSelected ClearAvatar
            , imageControl active "account-banner" Translations.banner form.bannerUrl BannerSelected ClearBanner
            ]
        ]


imageControl : Active -> String -> (Translations.I18n -> String) -> String -> (Maybe File -> Msg) -> Msg -> Html Msg
imageControl active identifier labelFor url selected clear =
    div []
        [ label [ A.for identifier ] [ text (labelFor active.texts) ]
        , if String.isEmpty url then
            text ""

          else
            img [ A.src url, A.alt "", A.class "avatar", A.attribute "referrerpolicy" "no-referrer" ] []
        , input
            [ A.id identifier
            , A.type_ "file"
            , A.attribute "accept" "image/*"
            , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map selected)
            ]
            []
        , button [ A.type_ "button", A.class "text-button", Events.onClick clear ]
            [ text (Translations.removeAvatar active.texts) ]
        ]


appearanceSection : Active -> SettingsForm -> Html Msg
appearanceSection active form =
    fieldset [ A.class "card form-stack" ]
        [ legend [] [ text (Translations.appearanceSection active.texts) ]
        , selectField active
            "account-theme"
            Translations.themeLabel
            form.theme
            (FieldChanged "theme")
            [ ( "browser", Translations.themeBrowser active.texts )
            , ( "dark", Translations.themeDark active.texts )
            ]
        , textField active "account-language" Translations.languageLabel form.interfaceLanguage (FieldChanged "interface_language")
        , selectField active
            "account-listing"
            Translations.listingType
            form.defaultListingType
            (FieldChanged "default_listing_type")
            [ ( "all", Translations.listingAll active.texts )
            , ( "local", Translations.listingLocal active.texts )
            , ( "subscribed", Translations.listingSubscribed active.texts )
            , ( "moderator_view", Translations.listingModerator active.texts )
            , ( "suggested", Translations.listingSuggested active.texts )
            ]
        , selectField active
            "account-layout"
            Translations.postLayout
            form.postListingMode
            (FieldChanged "post_listing_mode")
            [ ( "list", Translations.layoutList active.texts )
            , ( "card", Translations.layoutCard active.texts )
            , ( "small_card", Translations.layoutSmallCard active.texts )
            ]
        , selectField active
            "account-post-sort"
            Translations.postSort
            form.defaultPostSortType
            (FieldChanged "default_post_sort_type")
            [ ( "active", Translations.sortActive active.texts )
            , ( "hot", Translations.sortHot active.texts )
            , ( "new", Translations.sortNew active.texts )
            , ( "old", Translations.sortOld active.texts )
            , ( "top", Translations.sortTop active.texts )
            , ( "most_comments", Translations.sortMostComments active.texts )
            , ( "new_comments", Translations.sortNewComments active.texts )
            , ( "controversial", Translations.sortControversial active.texts )
            , ( "scaled", Translations.sortScaled active.texts )
            ]
        , selectField active
            "account-comment-sort"
            Translations.defaultCommentSort
            form.defaultCommentSortType
            (FieldChanged "default_comment_sort_type")
            [ ( "hot", Translations.sortHot active.texts )
            , ( "top", Translations.sortTop active.texts )
            , ( "new", Translations.sortNew active.texts )
            , ( "old", Translations.sortOld active.texts )
            , ( "controversial", Translations.sortControversial active.texts )
            ]
        , textField active "account-time-range" Translations.defaultTimeRange form.defaultPostTimeRange (FieldChanged "default_post_time_range_seconds")
        , textField active "account-page-size" Translations.itemsPerPage form.defaultItemsPerPage (FieldChanged "default_items_per_page")
        ]


contentSection : Active -> SettingsForm -> Html Msg
contentSection active form =
    fieldset [ A.class "card form-stack" ]
        [ legend [] [ text (Translations.contentSection active.texts) ]
        , checkboxField active "show-nsfw" Translations.showNsfw form.showNsfw (ToggleChanged "show_nsfw")
        , checkboxField active "blur-nsfw" Translations.blurNsfw form.blurNsfw (ToggleChanged "blur_nsfw")
        , checkboxField active "show-avatars" Translations.showAvatars form.showAvatars (ToggleChanged "show_avatars")
        , checkboxField active "show-media" Translations.showMedia form.showMedia (ToggleChanged "show_media")
        , checkboxField active "show-bots" Translations.showBotAccounts form.showBotAccounts (ToggleChanged "show_bot_accounts")
        , checkboxField active "show-read" Translations.showReadPosts form.showReadPosts (ToggleChanged "show_read_posts")
        , checkboxField active "open-new-tab" Translations.openLinksNewTab form.openLinksInNewTab (ToggleChanged "open_links_in_new_tab")
        , checkboxField active "infinite-scroll" Translations.infiniteScroll form.infiniteScrollEnabled (ToggleChanged "infinite_scroll_enabled")
        , checkboxField active "animated-images" Translations.animatedImages form.animatedImagesEnabled (ToggleChanged "animated_images_enabled")
        , checkboxField active "collapse-bots" Translations.collapseBotComments form.collapseBotComments (ToggleChanged "collapse_bot_comments")
        , checkboxField active "auto-read" Translations.autoMarkRead form.autoMarkFetchedPostsAsRead (ToggleChanged "auto_mark_fetched_posts_as_read")
        , checkboxField active "hide-media" Translations.hidePostsWithMedia form.hidePostsWithMedia (ToggleChanged "hide_posts_with_media")
        ]


notificationsSection : Active -> SettingsForm -> Html Msg
notificationsSection active form =
    fieldset [ A.class "card form-stack" ]
        [ legend [] [ text (Translations.notificationsSection active.texts) ]
        , checkboxField active "email-notifications" Translations.sendEmailNotifications form.sendNotificationsToEmail (ToggleChanged "send_notifications_to_email")
        , checkboxField active "private-messages" Translations.privateMessagesEnabled form.privateMessagesEnabled (ToggleChanged "private_messages_enabled")
        ]


languagesSection : Active -> SettingsForm -> Html Msg
languagesSection active form =
    fieldset [ A.class "card form-stack" ]
        [ legend [] [ text (Translations.languagesSection active.texts) ]
        , div []
            [ label [ A.for "discussion-languages" ] [ text (Translations.discussionLanguages active.texts) ]
            , input [ A.id "discussion-languages", A.type_ "text", A.value form.discussionLanguages, Events.onInput (FieldChanged "discussion_languages") ] []
            ]
        , div []
            [ label [ A.for "blocking-keywords" ] [ text (Translations.blockingKeywords active.texts) ]
            , textarea [ A.id "blocking-keywords", A.value form.blockingKeywords, Events.onInput (FieldChanged "blocking_keywords") ] []
            ]
        ]


votesSection : Active -> SettingsForm -> Html Msg
votesSection active form =
    fieldset [ A.class "card form-stack" ]
        [ legend [] [ text (Translations.votesSection active.texts) ]
        , checkboxField active "show-score" Translations.showScore form.showScore (ToggleChanged "show_score")
        , checkboxField active "show-upvotes" Translations.showUpvotes form.showUpvotes (ToggleChanged "show_upvotes")
        , selectField active
            "show-downvotes"
            Translations.showDownvotes
            form.showDownvotes
            (FieldChanged "show_downvotes")
            [ ( "show", Translations.voteShow active.texts )
            , ( "show_for_others", Translations.voteShowOthers active.texts )
            , ( "hide", Translations.voteHide active.texts )
            ]
        , checkboxField active "show-upvote-percentage" Translations.showUpvotePercentage form.showUpvotePercentage (ToggleChanged "show_upvote_percentage")
        , checkboxField active "show-person-votes" Translations.showPersonVotes form.showPersonVotes (ToggleChanged "show_person_votes")
        ]


securitySection : Active -> Model -> Html Msg
securitySection active model =
    section [ A.class "card form-stack" ]
        [ h2 [] [ text (Translations.securitySection active.texts) ]
        , case model.form of
            Just form ->
                p [ A.class "metadata" ]
                    [ text
                        (Translations.totp active.texts
                            ++ ": "
                            ++ (if form.totpEnabled then
                                    Translations.totpEnabled active.texts

                                else
                                    Translations.totpDisabled active.texts
                               )
                        )
                    ]

            Nothing ->
                text ""
        , case model.totp of
            TotpSetup uri ->
                div [ A.class "stack" ]
                    [ p [ A.class "muted" ] [ text (Translations.totpSecretHelp active.texts) ]
                    , code [ A.class "secret-uri" ] [ text uri ]
                    , textField active "totp-token" Translations.totpToken model.totpToken TotpTokenChanged
                    , div [ A.class "actions" ]
                        [ button [ A.type_ "button", A.class "filled-button", Events.onClick TotpEnable ] [ text (Translations.totpEnable active.texts) ]
                        , button [ A.type_ "button", A.class "text-button", Events.onClick TotpCancelled ] [ text (Translations.cancel active.texts) ]
                        ]
                    ]

            TotpFailed problem ->
                div [ A.class "stack" ]
                    [ viewFormProblem active.texts (Just problem)
                    , button [ A.type_ "button", A.class "outlined-button", Events.onClick TotpGenerate ] [ text (Translations.retryLabel active.texts) ]
                    ]

            _ ->
                if Maybe.map .totpEnabled model.form == Just True then
                    div [ A.class "stack" ]
                        [ textField active "totp-disable-token" Translations.totpToken model.totpToken TotpTokenChanged
                        , button [ A.type_ "button", A.class "outlined-button", Events.onClick TotpDisable ] [ text (Translations.totpDisable active.texts) ]
                        ]

                else
                    button [ A.type_ "button", A.class "outlined-button", Events.onClick TotpGenerate ]
                        [ text (Translations.totpGenerate active.texts) ]
        , h3 [] [ text (Translations.loginHistory active.texts) ]
        , case model.logins of
            Ready logins ->
                if List.isEmpty logins then
                    p [ A.class "muted" ] [ text (Translations.noLogins active.texts) ]

                else
                    ul [ A.class "roster-list" ]
                        (List.map
                            (\login ->
                                li []
                                    [ time [ A.datetime login.publishedAt, A.attribute "data-commune-time" "" ] [ text login.publishedAt ]
                                    , text " · "
                                    , text (Maybe.withDefault "" login.ip)
                                    , text " · "
                                    , text (Maybe.withDefault "" login.userAgent)
                                    ]
                            )
                            logins
                        )

            Failed problem ->
                viewFormProblem active.texts (Just problem)

            _ ->
                p [ A.class "muted", A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]
        , a [ A.href "/settings/password" ] [ text (Translations.changePasswordTitle active.texts) ]
        , button [ A.id "delete-account-button", A.type_ "button", A.class "danger-button", Events.onClick OpenDelete ]
            [ text (Translations.deleteAccount active.texts) ]
        , case model.deleteDialog of
            Just state ->
                Html.node "dialog"
                    [ A.id "delete-account-dialog"
                    , A.class "confirmation"
                    , A.attribute "aria-labelledby" "delete-account-title"
                    , Events.on "close" (Decode.succeed CloseDelete)
                    , Events.on "cancel" (Decode.succeed CloseDelete)
                    ]
                    [ div [ A.class "form-stack" ]
                        [ h2 [ A.id "delete-account-title" ] [ text (Translations.deleteAccount active.texts) ]
                        , p [ A.attribute "role" "alert" ] [ text (Translations.deleteAccountHelp active.texts) ]
                        , textField active "delete-password" Translations.currentPassword state.password DeletePasswordChanged
                        , checkboxField active "delete-content" Translations.deleteContent state.deleteContent DeleteContentChanged
                        , viewFormProblem active.texts state.problem
                        , div [ A.class "dialog-actions" ]
                            [ button [ A.type_ "button", A.class "text-button", Events.onClick CloseDelete ] [ text (Translations.cancel active.texts) ]
                            , button [ A.type_ "button", A.class "danger-button", A.disabled state.busy, Events.onClick DeleteAccount ] [ text (Translations.deleteAccount active.texts) ]
                            ]
                        ]
                    ]

            Nothing ->
                text ""
        ]


backupSection : Active -> Model -> Html Msg
backupSection active model =
    section [ A.class "card form-stack" ]
        [ h2 [] [ text (Translations.backupSection active.texts) ]
        , p [ A.class "muted" ] [ text (Translations.backupHelp active.texts) ]
        , div [ A.class "actions" ]
            [ button [ A.type_ "button", A.class "outlined-button", A.disabled model.backupBusy, Events.onClick ExportSettings ] [ text (Translations.exportSettings active.texts) ]
            , button [ A.type_ "button", A.class "outlined-button", A.disabled model.backupBusy, Events.onClick ExportData ] [ text (Translations.exportData active.texts) ]
            ]
        , div []
            [ label [ A.for "settings-import" ] [ text (Translations.importSettings active.texts) ]
            , input
                [ A.id "settings-import"
                , A.type_ "file"
                , A.attribute "accept" "application/json,.json"
                , Events.on "change" (Decode.maybe (Decode.at [ "target", "files", "0" ] File.decoder) |> Decode.map ImportSelected)
                ]
                []
            , if String.isEmpty model.importName then
                text ""

              else
                p [ A.class "metadata" ] [ text model.importName ]
            ]
        , viewFormProblem active.texts model.backupProblem
        ]


invitationsSection : Active -> Model -> Html Msg
invitationsSection active model =
    section [ A.class "card form-stack" ]
        [ h2 [] [ text (Translations.invitationsSection active.texts) ]
        , case model.invites of
            Ready page ->
                if List.isEmpty page.items then
                    p [ A.class "muted" ] [ text (Translations.noInvites active.texts) ]

                else
                    ul [ A.class "roster-list" ]
                        (List.map
                            (\invite ->
                                li []
                                    [ bdi [] [ text invite.token ]
                                    , text " · "
                                    , text (Translations.uses active.texts ++ ": " ++ String.fromInt invite.usesCount ++ "/" ++ Maybe.withDefault "∞" (Maybe.map String.fromInt invite.maxUses))
                                    , text " · "
                                    , text (Translations.expires active.texts ++ ": " ++ Maybe.withDefault "" invite.expiresAt)
                                    , button [ A.type_ "button", A.class "text-button danger-text", Events.onClick (RevokeInvite invite.token) ]
                                        [ text (Translations.revoke active.texts) ]
                                    ]
                            )
                            page.items
                        )

            Failed problem ->
                viewFormProblem active.texts (Just problem)

            _ ->
                p [ A.class "muted", A.attribute "role" "status" ] [ text (Translations.loadingMessage active.texts) ]
        , textField active "invite-max-uses" Translations.inviteMaxUses model.inviteMaxUses InviteMaxUsesChanged
        , textField active "invite-expires" Translations.inviteExpires model.inviteExpires InviteExpiresChanged
        , viewFormProblem active.texts model.inviteProblem
        , button [ A.type_ "button", A.class "outlined-button", A.disabled model.inviteBusy, Events.onClick CreateInvite ]
            [ text (Translations.createInvite active.texts) ]
        ]


textField : Active -> String -> (Translations.I18n -> String) -> String -> (String -> Msg) -> Html Msg
textField active identifier labelFor value changed =
    div []
        [ label [ A.for identifier ] [ text (labelFor active.texts) ]
        , input [ A.id identifier, A.type_ "text", A.value value, Events.onInput changed ] []
        ]


selectField : Active -> String -> (Translations.I18n -> String) -> String -> (String -> Msg) -> List ( String, String ) -> Html Msg
selectField active identifier labelFor value changed options =
    div []
        [ label [ A.for identifier ] [ text (labelFor active.texts) ]
        , select
            [ A.id identifier
            , Events.on "change" (Decode.map changed (Decode.at [ "target", "value" ] Decode.string))
            ]
            (List.map (\( itemValue, itemLabel ) -> option [ A.value itemValue, A.selected (itemValue == value) ] [ text itemLabel ]) options)
        ]


checkboxField : Active -> String -> (Translations.I18n -> String) -> Bool -> (Bool -> Msg) -> Html Msg
checkboxField active identifier labelFor checked changed =
    label []
        [ input [ A.id identifier, A.type_ "checkbox", A.checked checked, Events.onCheck changed ] []
        , text (" " ++ labelFor active.texts)
        ]
