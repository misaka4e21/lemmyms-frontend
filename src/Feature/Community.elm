module Feature.Community exposing (Config, Model, Msg(..), Outcome, ViewModel, initial, load, pageCommunities, pageCommunity, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Generated.I18n as Translations
import Html exposing (Html, a, button, div, h2, p, section, span, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Lemmy.Domain as Domain
import Lemmy.Markdown as Markdown
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Set exposing (Set)
import Ui.CommunityCard exposing (communityCard)
import Ui.Feedback exposing (problemText, viewRemote)
import Ui.Formatting exposing (policyLabel)
import Ui.Layout exposing (entityHeading, pageHeading)
import Ui.Pagination exposing (emptyWithPagination, viewPagination)
import Url exposing (Url)


type alias Model =
    { communities : Remote (Domain.Page Domain.CommunityView)
    , community : Remote Domain.CommunityView
    , communityTopics : Remote (Domain.Page Domain.PostView)
    , topicsCursor : Maybe String
    , busy : Set String
    , problem : Maybe Api.Problem
    }


initial : Model
initial =
    { communities = NotAsked, community = NotAsked, communityTopics = NotAsked, topicsCursor = Nothing, busy = Set.empty, problem = Nothing }


type Msg
    = CommunitiesLoaded Api.Response
    | CommunityLoaded Api.Response
    | TopicsLoaded Api.Response
    | ToggleFollow Bool
    | FollowDone Bool Api.Response


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem }


update : String -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf message model =
    case message of
        ToggleFollow following ->
            if Set.member "follow" model.busy then
                ( model, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

            else
                case model.community of
                    Ready community ->
                        ( { model | busy = Set.insert "follow" model.busy, problem = Nothing }
                        , Api.send csrf
                            "POST"
                            "/community/follow"
                            (Encode.encode 0 (Encode.object [ ( "community_id", Encode.int community.community.id ), ( "follow", Encode.bool following ) ]))
                            (FollowDone following)
                        , { flash = NoFlash, sessionProblem = Nothing }
                        )

                    _ ->
                        ( model, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

        FollowDone _ response ->
            case Api.decodeUnit response of
                Ok () ->
                    case model.community of
                        Ready community ->
                            ( { model | busy = Set.remove "follow" model.busy, community = Loading }
                            , Api.get ("/community?id=" ++ String.fromInt community.community.id) CommunityLoaded
                            , { flash = FlashSaved, sessionProblem = Nothing }
                            )

                        _ ->
                            ( { model | busy = Set.remove "follow" model.busy }
                            , Cmd.none
                            , { flash = FlashSaved, sessionProblem = Nothing }
                            )

                Err problem ->
                    ( { model | busy = Set.remove "follow" model.busy, problem = Just problem }
                    , Cmd.none
                    , { flash = FlashProblem problem
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )

        CommunitiesLoaded response ->
            case Api.decodeResponse (Domain.page Domain.communityView) response of
                Ok page ->
                    ( { model | communities = Ready page }, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

                Err problem ->
                    ( { model | communities = Failed problem }
                    , Cmd.none
                    , { flash = NoFlash
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )

        CommunityLoaded response ->
            case Api.decodeResponse (Decode.field "community_view" Domain.communityView) response of
                Ok community ->
                    let
                        ( topics, command ) =
                            if model.communityTopics == Loading then
                                ( Loading
                                , Api.get
                                    ("/post/list?type=local&sort=active&limit=20&community_id="
                                        ++ String.fromInt community.community.id
                                        ++ cursorQueryFrom model.topicsCursor
                                    )
                                    TopicsLoaded
                                )

                            else
                                ( model.communityTopics, Cmd.none )
                    in
                    ( { model | community = Ready community, communityTopics = topics }, command, { flash = NoFlash, sessionProblem = Nothing } )

                Err problem ->
                    ( { model | community = Failed problem, communityTopics = NotAsked }
                    , Cmd.none
                    , { flash = NoFlash
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )

        TopicsLoaded response ->
            case Api.decodeResponse (Domain.page Domain.postView) response of
                Ok page ->
                    ( { model | communityTopics = Ready page }, Cmd.none, { flash = NoFlash, sessionProblem = Nothing } )

                Err problem ->
                    ( { model | communityTopics = Failed problem }
                    , Cmd.none
                    , { flash = NoFlash
                      , sessionProblem =
                            if problem.status == 401 then
                                Just problem

                            else
                                Nothing
                      }
                    )


load : Route.Route -> Url -> Model -> ( Model, Cmd Msg )
load route url model =
    case route of
        Route.Communities ->
            ( { model | communities = Loading }, Api.get ("/community/list?type=local&sort=active_monthly&limit=20" ++ cursorQuery url) CommunitiesLoaded )

        Route.Community name ->
            ( { model | community = Loading, communityTopics = Loading, topicsCursor = Route.cursor url }
            , Api.get ("/community?name=" ++ Url.percentEncode name) CommunityLoaded
            )

        Route.CreatePost (Just id) ->
            ( { model | community = Loading, communityTopics = NotAsked, topicsCursor = Nothing }
            , Api.get ("/community?id=" ++ String.fromInt id) CommunityLoaded
            )

        _ ->
            ( model, Cmd.none )


cursorQuery : Url -> String
cursorQuery url =
    cursorQueryFrom (Route.cursor url)


cursorQueryFrom : Maybe String -> String
cursorQueryFrom cursorValue =
    case cursorValue of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


type alias Config msg =
    { retry : msg
    , postCard : Domain.PostView -> Html msg
    , toggleFollow : Bool -> msg
    , reportCommunity : String -> msg
    }


type alias ViewModel =
    { communities : Remote (Domain.Page Domain.CommunityView)
    , community : Remote Domain.CommunityView
    , communityTopics : Remote (Domain.Page Domain.PostView)
    , busy : Set String
    , problem : Maybe Api.Problem
    , auth : AuthState
    , url : Url
    }


pageCommunities : Config msg -> ViewModel -> Active -> Html msg
pageCommunities config model active =
    pageHeading (Translations.communitiesTitle active.texts)
        (section [ A.class "stack" ]
            [ p [ A.class "muted" ] [ text (Translations.communitiesIntro active.texts) ]
            , viewRemote config.retry
                active.texts
                model.communities
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (communityCard active.texts) page.items)
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]
                )
            ]
        )


pageCommunity : Config msg -> ViewModel -> Active -> String -> Html msg
pageCommunity config model active id =
    entityHeading
        (case model.community of
            Ready community ->
                Maybe.withDefault community.community.name community.community.title

            _ ->
                Translations.communitiesTitle active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote config.retry
                active.texts
                model.community
                (\community ->
                    let
                        value =
                            community.community

                        visibility =
                            visibilityText value.visibility

                        postPolicy =
                            if value.postingRestrictedToMods then
                                "managers"

                            else
                                "eligible_users"

                        description =
                            case value.sidebar of
                                Just sidebar ->
                                    sidebar

                                Nothing ->
                                    Maybe.withDefault "" value.summary
                    in
                    div [ A.class "stack" ]
                        [ p [ A.class "metadata" ]
                            [ text
                                (Translations.policySummary
                                    { read = policyLabel active.texts visibility
                                    , post = policyLabel active.texts postPolicy
                                    }
                                    active.texts
                                )
                            ]
                        , if String.isEmpty description then
                            text ""

                          else
                            Markdown.render description
                        , div [ A.class "actions" ]
                            [ if not value.postingRestrictedToMods || community.canMod then
                                a [ A.class "filled-button", A.href (Route.path (Route.CreatePost (Just value.id))) ]
                                    [ text (Translations.publishTopic active.texts) ]

                              else
                                text ""
                            , if community.canMod then
                                a [ A.class "outlined-button", A.href (Route.path (Route.CommunitySettings value.name)) ]
                                    [ text (Translations.manageTitle active.texts) ]

                              else
                                text ""
                            , followControl config model active community
                            , if canReport model.auth then
                                button
                                    [ A.type_ "button"
                                    , A.class "outlined-button"
                                    , Events.onClick (config.reportCommunity (String.fromInt value.id))
                                    ]
                                    [ text (Translations.reportCommunity active.texts) ]

                              else
                                text ""
                            ]
                        , p [ A.class "metadata" ]
                            [ text (Translations.followPolicy active.texts ++ ": ")
                            , text (followPolicyLabel active.texts (followPolicy value))
                            , text " · "
                            , text (Translations.followers active.texts ++ ": ")
                            , text (String.fromInt value.subscribers)
                            ]
                        , case model.problem of
                            Just problem ->
                                p [ A.class "field-error", A.attribute "role" "alert" ] [ text (problemText active.texts problem) ]

                            Nothing ->
                                text ""
                        ]
                )
            , h2 [] [ text (Translations.latestTitle active.texts) ]
            , viewRemote config.retry
                active.texts
                model.communityTopics
                (\page ->
                    if List.isEmpty page.items then
                        emptyWithPagination active.texts model.url page

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map config.postCard page.items)
                            , viewPagination active.texts model.url page.prevPage page.nextPage
                            ]
                )
            ]
        )


canReport : AuthState -> Bool
canReport auth =
    case auth of
        Authenticated _ ->
            True

        _ ->
            False


followControl : Config msg -> ViewModel -> Active -> Domain.CommunityView -> Html msg
followControl config model active community =
    let
        value =
            community.community

        actions =
            community.communityActions

        state =
            Maybe.andThen .followState actions

        following =
            state == Just Domain.AcceptedFollow || Maybe.andThen .followedAt actions /= Nothing
    in
    if state == Just Domain.PendingFollow || state == Just Domain.ApprovalRequiredFollow then
        span [ A.class "chip" ] [ text (Translations.followPending active.texts) ]

    else if following then
        button
            [ A.type_ "button"
            , A.class "outlined-button"
            , A.disabled (Set.member "follow" model.busy)
            , Events.onClick (config.toggleFollow True)
            ]
            [ text (Translations.unfollow active.texts) ]

    else if not value.deleted && not value.removed then
        button
            [ A.type_ "button"
            , A.class "filled-button"
            , A.disabled (Set.member "follow" model.busy)
            , Events.onClick (config.toggleFollow False)
            ]
            [ text (Translations.follow active.texts) ]

    else
        span [ A.class "chip" ] [ text (followPolicyLabel active.texts (followPolicy value)) ]


followPolicy : Domain.Community -> String
followPolicy value =
    if value.visibility == Domain.PrivateCommunity then
        "approval"

    else
        "open"


visibilityText : Domain.CommunityVisibility -> String
visibilityText visibility =
    case visibility of
        Domain.PublicCommunity ->
            "public"

        Domain.UnlistedCommunity ->
            "unlisted"

        Domain.LocalOnlyPublicCommunity ->
            "local_only_public"

        Domain.LocalOnlyPrivateCommunity ->
            "local_only_private"

        Domain.PrivateCommunity ->
            "private"

        Domain.UnknownVisibility value ->
            value


followPolicyLabel : Translations.I18n -> String -> String
followPolicyLabel texts policy =
    case policy of
        "members" ->
            Translations.followPolicyMembers texts

        "approval" ->
            Translations.followPolicyApproval texts

        "disabled" ->
            Translations.followPolicyDisabled texts

        _ ->
            Translations.followPolicyOpen texts
