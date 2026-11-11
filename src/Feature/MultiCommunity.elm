module Feature.MultiCommunity exposing (Config, Model, Msg(..), Outcome, ViewModel, initial, loadCreate, loadDetail, loadDirectory, loadSettings, pageCreate, pageDetail, pageDirectory, pageSettings, update)

import Api
import App.Context exposing (Active)
import App.Feedback exposing (Flash(..))
import App.Session exposing (AuthState(..))
import Feature.Authoring.State as AuthoringState
import Feature.Authoring.Update as Authoring
import Feature.Authoring.View as AuthoringView
import Generated.I18n as Translations
import Html exposing (Html, a, article, bdi, button, div, form, h2, input, label, li, option, p, section, select, span, strong, text, textarea, ul)
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
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (entityHeading, pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)


type alias Form =
    { mode : FormMode
    , name : String
    , title : String
    , summary : String
    , sidebar : AuthoringState.Model
    , deleted : Bool
    , busy : Bool
    , problem : Maybe Api.Problem
    }


type FormMode
    = CreateMode
    | EditMode String


type alias Model =
    { directory : Remote (Domain.Page Domain.MultiCommunityView)
    , detail : Remote Domain.MultiCommunityResponse
    , posts : Remote (Domain.Page Domain.PostView)
    , manageDetail : Remote Domain.MultiCommunityResponse
    , results : Remote (Domain.Page Domain.CommunityView)
    , form : Form
    , listing : String
    , sort : String
    , searchTerm : String
    , postSort : String
    , timeRange : String
    , name : String
    , entrySearch : String
    , entryBusy : Set String
    , entryProblem : Maybe Api.Problem
    }


emptyForm : FormMode -> Form
emptyForm mode =
    { mode = mode
    , name = ""
    , title = ""
    , summary = ""
    , sidebar = AuthoringState.init "multi-community-sidebar" ""
    , deleted = False
    , busy = False
    , problem = Nothing
    }


initial : Model
initial =
    { directory = NotAsked
    , detail = NotAsked
    , posts = NotAsked
    , manageDetail = NotAsked
    , results = NotAsked
    , form = emptyForm CreateMode
    , listing = "local"
    , sort = "subscribers"
    , searchTerm = ""
    , postSort = "active"
    , timeRange = ""
    , name = ""
    , entrySearch = ""
    , entryBusy = Set.empty
    , entryProblem = Nothing
    }


type Msg
    = DirectoryLoaded Api.Response
    | DetailLoaded Api.Response
    | PostsLoaded Api.Response
    | ManageLoaded Api.Response
    | ListingChanged String
    | SortChanged String
    | SearchChanged String
    | SearchSubmitted
    | PostSortChanged String
    | TimeRangeChanged String
    | Follow Bool
    | Followed Api.Response
    | NameChanged String
    | TitleChanged String
    | SummaryChanged String
    | SidebarAuthoring Authoring.Msg
    | Save
    | Saved Api.Response
    | SetDeleted Bool
    | EntrySearchChanged String
    | EntrySearchSubmitted
    | EntryResultsLoaded Api.Response
    | AddEntry Int
    | RemoveEntry Int
    | EntryDone EntryAction Api.Response


type EntryAction
    = AddEntryAction Int
    | RemoveEntryAction Int


type alias Outcome =
    { flash : Flash, sessionProblem : Maybe Api.Problem, navigation : Maybe String }


type alias Working =
    { directory : Remote (Domain.Page Domain.MultiCommunityView)
    , detail : Remote Domain.MultiCommunityResponse
    , posts : Remote (Domain.Page Domain.PostView)
    , manageDetail : Remote Domain.MultiCommunityResponse
    , results : Remote (Domain.Page Domain.CommunityView)
    , form : Form
    , listing : String
    , sort : String
    , searchTerm : String
    , postSort : String
    , timeRange : String
    , name : String
    , entrySearch : String
    , entryBusy : Set String
    , entryProblem : Maybe Api.Problem
    , flash : Flash
    , sessionProblem : Maybe Api.Problem
    , navigation : Maybe String
    }


loadDirectory : Url -> ( Model, Cmd Msg )
loadDirectory url =
    let
        listing =
            allowedListing (Route.query "type" url)

        sort =
            allowedSort (Route.query "sort" url)

        searchTerm =
            Route.query "q" url
    in
    ( { initial | directory = Loading, listing = listing, sort = sort, searchTerm = searchTerm }
    , Api.get (directoryQuery listing sort searchTerm url) DirectoryLoaded
    )


loadDetail : Url -> String -> ( Model, Cmd Msg )
loadDetail url name =
    let
        postSort =
            allowedPostSort (Route.sort "active" url)

        timeRange =
            allowedTimeRange (Route.query "time_range" url)
    in
    ( { initial | detail = Loading, posts = Loading, name = name, postSort = postSort, timeRange = timeRange }
    , Cmd.batch
        [ Api.get (detailQuery name) DetailLoaded
        , Api.get (postsQuery name postSort timeRange url) PostsLoaded
        ]
    )


loadCreate : ( Model, Cmd Msg )
loadCreate =
    ( { initial | form = emptyForm CreateMode }, Cmd.none )


loadSettings : String -> ( Model, Cmd Msg )
loadSettings name =
    ( { initial | manageDetail = Loading, form = emptyForm (EditMode name), name = name }
    , Api.get (detailQuery name) ManageLoaded
    )


update : String -> Url -> Msg -> Model -> ( Model, Cmd Msg, Outcome )
update csrf url message state =
    let
        ( next, command ) =
            updateWorking csrf
                url
                message
                { directory = state.directory
                , detail = state.detail
                , posts = state.posts
                , manageDetail = state.manageDetail
                , results = state.results
                , form = state.form
                , listing = state.listing
                , sort = state.sort
                , searchTerm = state.searchTerm
                , postSort = state.postSort
                , timeRange = state.timeRange
                , name = state.name
                , entrySearch = state.entrySearch
                , entryBusy = state.entryBusy
                , entryProblem = state.entryProblem
                , flash = NoFlash
                , sessionProblem = Nothing
                , navigation = Nothing
                }
    in
    ( { directory = next.directory
      , detail = next.detail
      , posts = next.posts
      , manageDetail = next.manageDetail
      , results = next.results
      , form = next.form
      , listing = next.listing
      , sort = next.sort
      , searchTerm = next.searchTerm
      , postSort = next.postSort
      , timeRange = next.timeRange
      , name = next.name
      , entrySearch = next.entrySearch
      , entryBusy = next.entryBusy
      , entryProblem = next.entryProblem
      }
    , command
    , { flash = next.flash, sessionProblem = next.sessionProblem, navigation = next.navigation }
    )


updateWorking : String -> Url -> Msg -> Working -> ( Working, Cmd Msg )
updateWorking csrf url message model =
    case message of
        DirectoryLoaded response ->
            case Api.decodeResponse (Domain.page Domain.multiCommunityView) response of
                Ok page ->
                    ( { model | directory = Ready page }, Cmd.none )

                Err problem ->
                    ( { model | directory = Failed problem }, Cmd.none )

        DetailLoaded response ->
            case Api.decodeResponse Domain.multiCommunityResponse response of
                Ok detail ->
                    ( { model | detail = Ready detail }, Cmd.none )

                Err problem ->
                    ( { model | detail = Failed problem }, Cmd.none )

        PostsLoaded response ->
            case Api.decodeResponse (Domain.page Domain.postView) response of
                Ok page ->
                    ( { model | posts = Ready page }, Cmd.none )

                Err problem ->
                    ( { model | posts = Failed problem }, Cmd.none )

        ManageLoaded response ->
            case Api.decodeResponse Domain.multiCommunityResponse response of
                Ok detail ->
                    let
                        multi =
                            detail.multiCommunityView.multi

                        form =
                            if String.isEmpty model.form.name then
                                let
                                    current =
                                        model.form
                                in
                                { current
                                    | name = multi.name
                                    , title = Maybe.withDefault "" multi.title
                                    , summary = Maybe.withDefault "" multi.summary
                                    , sidebar = AuthoringState.init "multi-community-sidebar" (Maybe.withDefault "" multi.sidebar)
                                    , deleted = multi.deleted
                                }

                            else
                                model.form
                    in
                    ( { model | manageDetail = Ready detail, form = form }, Cmd.none )

                Err problem ->
                    ( { model | manageDetail = Failed problem }, Cmd.none )

        ListingChanged value ->
            let
                listing =
                    allowedListing value
            in
            ( { model | listing = listing, navigation = Just (directoryUrl listing model.sort model.searchTerm) }, Cmd.none )

        SortChanged value ->
            let
                sort =
                    allowedSort value
            in
            ( { model | sort = sort, navigation = Just (directoryUrl model.listing sort model.searchTerm) }, Cmd.none )

        SearchChanged value ->
            ( { model | searchTerm = value }, Cmd.none )

        SearchSubmitted ->
            ( { model | navigation = Just (directoryUrl model.listing model.sort model.searchTerm) }, Cmd.none )

        PostSortChanged value ->
            let
                sort =
                    allowedPostSort value
            in
            ( { model | postSort = sort, navigation = Just (detailUrl model.name sort model.timeRange) }, Cmd.none )

        TimeRangeChanged value ->
            let
                timeRange =
                    allowedTimeRange value
            in
            ( { model | timeRange = timeRange, navigation = Just (detailUrl model.name model.postSort timeRange) }, Cmd.none )

        Follow follow ->
            case model.detail of
                Ready detail ->
                    ( model
                    , Api.send csrf
                        "POST"
                        "/multi_community/follow"
                        (Encode.encode 0
                            (Encode.object
                                [ ( "multi_community_id", Encode.int detail.multiCommunityView.multi.id )
                                , ( "follow", Encode.bool follow )
                                ]
                            )
                        )
                        Followed
                    )

                _ ->
                    ( model, Cmd.none )

        Followed response ->
            case Api.decodeResponse (Decode.field "multi_community_view" Domain.multiCommunityView) response of
                Ok view ->
                    case model.detail of
                        Ready detail ->
                            ( { model | detail = Ready { detail | multiCommunityView = view }, flash = FlashSaved }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Err problem ->
                    ( { model | flash = FlashProblem problem, sessionProblem = sessionProblem problem }, Cmd.none )

        NameChanged value ->
            ( { model | form = updateForm (setName value) model.form }, Cmd.none )

        TitleChanged value ->
            ( { model | form = updateForm (setTitle value) model.form }, Cmd.none )

        SummaryChanged value ->
            ( { model | form = updateForm (setSummary value) model.form }, Cmd.none )

        SidebarAuthoring authoringMessage ->
            let
                ( authoring, command, _ ) =
                    Authoring.update authoringMessage model.form.sidebar
            in
            ( { model | form = updateForm (setSidebar authoring) model.form }
            , Cmd.map SidebarAuthoring command
            )

        Save ->
            saveRequest csrf model model.form.deleted

        Saved response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        destination =
                            if model.form.deleted then
                                Route.path Route.MultiCommunities

                            else if String.isEmpty model.form.name then
                                Route.path Route.MultiCommunities

                            else
                                Route.path (Route.MultiCommunity model.form.name)
                    in
                    ( { model | flash = FlashSaved, navigation = Just destination }, Cmd.none )

                Err problem ->
                    ( { model
                        | form = updateForm (setProblem problem) model.form
                        , flash = FlashProblem problem
                        , sessionProblem = sessionProblem problem
                      }
                    , Cmd.none
                    )

        SetDeleted deleted ->
            let
                next =
                    { model | form = updateForm (setDeletedValue deleted) model.form }
            in
            saveRequest csrf next deleted

        EntrySearchChanged value ->
            ( { model | entrySearch = value, entryProblem = Nothing }, Cmd.none )

        EntrySearchSubmitted ->
            if String.isEmpty (String.trim model.entrySearch) then
                ( model, Cmd.none )

            else
                ( { model | results = Loading, entryProblem = Nothing }
                , Api.get
                    ("/community/list?type_=all&limit=10&search_term=" ++ Url.percentEncode model.entrySearch)
                    EntryResultsLoaded
                )

        EntryResultsLoaded response ->
            case Api.decodeResponse (Domain.page Domain.communityView) response of
                Ok page ->
                    ( { model | results = Ready page }, Cmd.none )

                Err problem ->
                    ( { model | results = Failed problem, entryProblem = Just problem }, Cmd.none )

        AddEntry communityId ->
            entryRequest csrf model "POST" (AddEntryAction communityId) communityId

        RemoveEntry communityId ->
            entryRequest csrf model "DELETE" (RemoveEntryAction communityId) communityId

        EntryDone action response ->
            case Api.decodeUnit response of
                Ok () ->
                    let
                        key =
                            case action of
                                AddEntryAction id ->
                                    String.fromInt id

                                RemoveEntryAction id ->
                                    String.fromInt id
                    in
                    ( { model
                        | entryBusy = Set.remove key model.entryBusy
                        , entryProblem = Nothing
                        , manageDetail = Loading
                        , flash = FlashSaved
                      }
                    , Api.get (detailQuery model.name) ManageLoaded
                    )

                Err problem ->
                    ( { model | entryBusy = Set.empty, entryProblem = Just problem, flash = FlashProblem problem, sessionProblem = sessionProblem problem }
                    , Cmd.none
                    )


updateForm : (Form -> Form) -> Form -> Form
updateForm change form =
    change form


setName : String -> Form -> Form
setName value form =
    { form | name = value, problem = Nothing }


setTitle : String -> Form -> Form
setTitle value form =
    { form | title = value, problem = Nothing }


setSummary : String -> Form -> Form
setSummary value form =
    { form | summary = value, problem = Nothing }


setSidebar : AuthoringState.Model -> Form -> Form
setSidebar value form =
    { form | sidebar = value, problem = Nothing }


setProblem : Api.Problem -> Form -> Form
setProblem problem form =
    { form | busy = False, problem = Just problem }


setDeletedValue : Bool -> Form -> Form
setDeletedValue deleted form =
    { form | deleted = deleted }


setBusy : Form -> Form
setBusy form =
    { form | busy = True, problem = Nothing }


sessionProblem : Api.Problem -> Maybe Api.Problem
sessionProblem problem =
    if problem.status == 401 then
        Just problem

    else
        Nothing


saveRequest : String -> Working -> Bool -> ( Working, Cmd Msg )
saveRequest csrf model deleted =
    let
        form =
            model.form

        commonFields =
            [ ( "title", maybeString form.title )
            , ( "summary", maybeString form.summary )
            , ( "sidebar", maybeString (AuthoringState.value form.sidebar) )
            ]
    in
    case form.mode of
        CreateMode ->
            ( { model | form = updateForm setBusy form }
            , Api.send csrf
                "POST"
                "/multi_community"
                (Encode.encode 0
                    (Encode.object
                        ([ ( "name", Encode.string form.name ) ] ++ commonFields)
                    )
                )
                Saved
            )

        EditMode _ ->
            case model.manageDetail of
                Ready detail ->
                    ( { model | form = updateForm setBusy form }
                    , Api.send csrf
                        "PUT"
                        "/multi_community"
                        (Encode.encode 0
                            (Encode.object
                                ([ ( "id", Encode.int detail.multiCommunityView.multi.id ) ]
                                    ++ commonFields
                                    ++ [ ( "deleted", Encode.bool deleted ) ]
                                )
                            )
                        )
                        Saved
                    )

                _ ->
                    ( model, Cmd.none )


entryRequest : String -> Working -> String -> EntryAction -> Int -> ( Working, Cmd Msg )
entryRequest csrf model method action communityId =
    case model.manageDetail of
        Ready detail ->
            let
                key =
                    String.fromInt communityId
            in
            ( { model | entryBusy = Set.insert key model.entryBusy, entryProblem = Nothing }
            , Api.send csrf
                method
                "/multi_community/entry"
                (Encode.encode 0
                    (Encode.object
                        [ ( "id", Encode.int detail.multiCommunityView.multi.id )
                        , ( "community_id", Encode.int communityId )
                        ]
                    )
                )
                (EntryDone action)
            )

        _ ->
            ( model, Cmd.none )


maybeString : String -> Encode.Value
maybeString value =
    if String.isEmpty (String.trim value) then
        Encode.null

    else
        Encode.string value


directoryQuery : String -> String -> String -> Url -> String
directoryQuery listing sort searchTerm url =
    "/multi_community/list?type_="
        ++ listing
        ++ "&sort="
        ++ sort
        ++ "&limit=20"
        ++ searchQuery searchTerm
        ++ cursorQuery url


detailQuery : String -> String
detailQuery name =
    "/multi_community?name=" ++ Url.percentEncode name


postsQuery : String -> String -> String -> Url -> String
postsQuery name sort timeRange url =
    "/post/list?type=all&multi_community_name="
        ++ Url.percentEncode name
        ++ "&sort="
        ++ sort
        ++ "&limit=20"
        ++ timeQuery timeRange
        ++ cursorQuery url


searchQuery : String -> String
searchQuery value =
    if String.isEmpty (String.trim value) then
        ""

    else
        "&search_term=" ++ Url.percentEncode value


timeQuery : String -> String
timeQuery value =
    if String.isEmpty value then
        ""

    else
        "&time_range_seconds=" ++ value


cursorQuery : Url -> String
cursorQuery url =
    case Route.cursor url of
        Just cursor ->
            "&page_cursor=" ++ Url.percentEncode cursor

        Nothing ->
            ""


directoryUrl : String -> String -> String -> String
directoryUrl listing sort searchTerm =
    "/multi_communities"
        ++ queryString
            ([ ( "type", listing ), ( "sort", sort ) ]
                ++ (if String.isEmpty (String.trim searchTerm) then
                        []

                    else
                        [ ( "q", searchTerm ) ]
                   )
            )


detailUrl : String -> String -> String -> String
detailUrl name sort timeRange =
    "/m/"
        ++ Url.percentEncode name
        ++ queryString
            ([ ( "sort", sort ) ]
                ++ (if String.isEmpty timeRange then
                        []

                    else
                        [ ( "time_range", timeRange ) ]
                   )
            )


queryString : List ( String, String ) -> String
queryString values =
    if List.isEmpty values then
        ""

    else
        "?" ++ String.join "&" (List.map (\( key, value ) -> key ++ "=" ++ Url.percentEncode value) values)


allowedListing : String -> String
allowedListing value =
    if List.member value [ "all", "local", "subscribed" ] then
        value

    else
        "local"


allowedSort : String -> String
allowedSort value =
    if List.member value [ "new", "old", "name_asc", "name_desc", "communities", "subscribers", "subscribers_local" ] then
        value

    else
        "subscribers"


allowedPostSort : String -> String
allowedPostSort value =
    if List.member value [ "active", "hot", "new", "old", "top", "most_comments", "new_comments", "controversial", "scaled" ] then
        value

    else
        "active"


allowedTimeRange : String -> String
allowedTimeRange value =
    if List.member value [ "", "3600", "86400", "604800", "2592000", "31536000" ] then
        value

    else
        ""


type alias Config msg =
    { retry : msg
    , listingChanged : String -> msg
    , sortChanged : String -> msg
    , searchChanged : String -> msg
    , searchSubmitted : msg
    , postSortChanged : String -> msg
    , timeRangeChanged : String -> msg
    , follow : Bool -> msg
    , nameChanged : String -> msg
    , titleChanged : String -> msg
    , summaryChanged : String -> msg
    , sidebarAuthoring : Authoring.Msg -> msg
    , save : msg
    , setDeleted : Bool -> msg
    , entrySearchChanged : String -> msg
    , entrySearchSubmitted : msg
    , addEntry : Int -> msg
    , removeEntry : Int -> msg
    , postCard : Domain.PostView -> Html msg
    }


type alias ViewModel =
    { auth : AuthState, url : Url }


canManage : AuthState -> Domain.MultiCommunityView -> Bool
canManage auth view =
    case auth of
        Authenticated account ->
            Domain.isAdmin account || account.localUserView.person.id == view.multi.creatorId

        _ ->
            False


pageDirectory : Config msg -> Model -> ViewModel -> Active -> Html msg
pageDirectory config model viewModel active =
    pageHeading (Translations.multiCommunities active.texts)
        (section [ A.class "stack" ]
            [ p [ A.class "muted" ] [ text (Translations.multiCommunitiesIntro active.texts) ]
            , div [ A.class "actions" ]
                [ a [ A.class "filled-button", A.href (Route.path Route.CreateMultiCommunity) ] [ text (Translations.createMultiCommunity active.texts) ]
                ]
            , form [ Events.onSubmit config.searchSubmitted, A.class "card form-stack" ]
                [ label [ A.for "multi-community-search" ] [ text (Translations.multiCommunitySearch active.texts) ]
                , input
                    [ A.id "multi-community-search"
                    , A.type_ "search"
                    , A.value model.searchTerm
                    , Events.onInput config.searchChanged
                    ]
                    []
                , div [ A.class "actions" ]
                    [ selectField "multi-community-listing"
                        (Translations.multiCommunityListing active.texts)
                        model.listing
                        config.listingChanged
                        (listingOptions active)
                    , selectField "multi-community-sort"
                        (Translations.multiCommunitySort active.texts)
                        model.sort
                        config.sortChanged
                        (sortOptions active)
                    , button [ A.type_ "submit", A.class "outlined-button" ] [ text (Translations.searchSubmit active.texts) ]
                    ]
                ]
            , viewRemote config.retry
                active.texts
                model.directory
                (\page ->
                    if List.isEmpty page.items then
                        div [ A.class "stack" ]
                            [ p [ A.class "muted" ] [ text (Translations.noMultiCommunities active.texts) ]
                            , viewPagination active.texts viewModel.url page.prevPage page.nextPage
                            ]

                    else
                        div [ A.class "stack" ]
                            [ div [ A.class "stack" ] (List.map (multiCommunityCard active.texts) page.items)
                            , viewPagination active.texts viewModel.url page.prevPage page.nextPage
                            ]
                )
            ]
        )


pageDetail : Config msg -> Model -> ViewModel -> Active -> String -> Html msg
pageDetail config model viewModel active name =
    entityHeading
        (case model.detail of
            Ready detail ->
                Maybe.withDefault detail.multiCommunityView.multi.name detail.multiCommunityView.multi.title

            _ ->
                Translations.multiCommunities active.texts
        )
        (section [ A.class "primary-column" ]
            [ viewRemote config.retry
                active.texts
                model.detail
                (\detail ->
                    let
                        multiView =
                            detail.multiCommunityView

                        multi =
                            multiView.multi

                        followed =
                            List.member multiView.followState [ Just Domain.AcceptedFollow, Just Domain.PendingFollow, Just Domain.ApprovalRequiredFollow ]

                        management =
                            if canManage viewModel.auth multiView then
                                [ a [ A.class "outlined-button", A.href (Route.path (Route.MultiCommunitySettings multi.name)) ]
                                    [ text (Translations.multiCommunitySettings active.texts) ]
                                ]

                            else
                                []
                    in
                    div [ A.class "stack" ]
                        [ article [ A.class "card" ]
                            [ h2 [] [ text (Maybe.withDefault multi.name multi.title) ]
                            , p [ A.class "metadata" ]
                                [ bdi [] [ text multi.name ]
                                , text " · "
                                , text (Translations.multiCommunitySubscribers active.texts ++ ": " ++ String.fromInt multi.subscribers)
                                , text " · "
                                , text (Translations.multiCommunityCommunities active.texts ++ ": " ++ String.fromInt multi.communities)
                                ]
                            , p []
                                [ strong [] [ text (Translations.multiCommunityOwner active.texts) ]
                                , text " "
                                , a [ A.href (Route.path (Route.Profile (Domain.profileHandle multiView.owner))) ]
                                    [ bdi [] [ text (Domain.displayNameOf multiView.owner) ] ]
                                ]
                            , case multiView.followState of
                                Just Domain.PendingFollow ->
                                    p [ A.class "chip" ] [ text (Translations.multiCommunityFollowPending active.texts) ]

                                Just Domain.AcceptedFollow ->
                                    p [ A.class "chip" ] [ text (Translations.multiCommunityFollowAccepted active.texts) ]

                                _ ->
                                    text ""
                            , div [ A.class "actions" ]
                                (followActions config viewModel active multi followed
                                    ++ management
                                )
                            , Maybe.withDefault "" multi.sidebar |> Markdown.render
                            ]
                        , if List.isEmpty detail.communities then
                            p [ A.class "muted" ] [ text (Translations.noCommunities active.texts) ]

                          else
                            div [ A.class "stack" ] (List.map (communityCard active.texts) detail.communities)
                        ]
                )
            , div [ A.class "card" ]
                [ h2 [] [ text (Translations.multiCommunityFeed active.texts) ]
                , div [ A.class "actions" ]
                    [ selectField "multi-community-post-sort"
                        (Translations.postSort active.texts)
                        model.postSort
                        config.postSortChanged
                        (postSortOptions active)
                    , selectField "multi-community-time"
                        (Translations.timeRange active.texts)
                        model.timeRange
                        config.timeRangeChanged
                        (timeOptions active)
                    ]
                , viewRemote config.retry
                    active.texts
                    model.posts
                    (\page ->
                        if List.isEmpty page.items then
                            div [ A.class "stack" ]
                                [ p [ A.class "muted" ] [ text (Translations.multiCommunityEmpty active.texts) ]
                                , viewPagination active.texts viewModel.url page.prevPage page.nextPage
                                ]

                        else
                            div [ A.class "stack" ]
                                [ div [ A.class "stack" ] (List.map config.postCard page.items)
                                , viewPagination active.texts viewModel.url page.prevPage page.nextPage
                                ]
                    )
                ]
            ]
        )


followActions : Config msg -> ViewModel -> Active -> Domain.MultiCommunity -> Bool -> List (Html msg)
followActions config viewModel active multi followed =
    case viewModel.auth of
        Authenticated _ ->
            [ button
                [ A.class "outlined-button"
                , Events.onClick (config.follow (not followed))
                ]
                [ text
                    (if followed then
                        Translations.multiCommunityUnfollow active.texts

                     else
                        Translations.multiCommunityFollow active.texts
                    )
                ]
            ]

        _ ->
            [ a [ A.class "outlined-button", A.href (Route.path Route.Login) ] [ text (Translations.navLogin active.texts) ] ]


pageCreate : Config msg -> Model -> ViewModel -> Active -> Html msg
pageCreate config model viewModel active =
    pageHeading (Translations.createMultiCommunity active.texts)
        (case viewModel.auth of
            Authenticated _ ->
                form [ Events.onSubmit config.save, A.class "card form-stack" ]
                    [ fieldInput "multi-community-name" (Translations.multiCommunityName active.texts) model.form.name config.nameChanged
                    , fieldInput "multi-community-title" (Translations.multiCommunityTitle active.texts) model.form.title config.titleChanged
                    , fieldInput "multi-community-summary" (Translations.multiCommunitySummary active.texts) model.form.summary config.summaryChanged
                    , AuthoringView.view
                        { id = "multi-community-sidebar"
                        , label = Translations.multiCommunitySidebar active.texts
                        , helpId = "multi-community-sidebar-help"
                        , helpText = Translations.topicBodyHelp active.texts
                        , required = False
                        , toMsg = config.sidebarAuthoring
                        }
                        active
                        model.form.sidebar
                    , viewFormProblem active.texts model.form.problem
                    , button [ A.type_ "submit", A.class "filled-button", A.disabled model.form.busy ] [ text (Translations.create active.texts) ]
                    ]

            _ ->
                loginRequired active.texts
        )


pageSettings : Config msg -> Model -> ViewModel -> Active -> String -> Html msg
pageSettings config model viewModel active name =
    pageHeading (Translations.multiCommunitySettings active.texts)
        (viewRemote config.retry
            active.texts
            model.manageDetail
            (\detail ->
                if not (canManage viewModel.auth detail.multiCommunityView) then
                    section [ A.class "card" ]
                        [ p [ A.class "field-error", A.attribute "role" "alert" ] [ text (Translations.forbidden active.texts) ] ]

                else
                    let
                        multi =
                            detail.multiCommunityView.multi
                    in
                    section [ A.class "stack" ]
                        [ form [ Events.onSubmit config.save, A.class "card form-stack" ]
                            [ p [] [ strong [] [ text (Translations.multiCommunityName active.texts) ], text " ", bdi [] [ text multi.name ] ]
                            , fieldInput "multi-community-title" (Translations.multiCommunityTitle active.texts) model.form.title config.titleChanged
                            , fieldInput "multi-community-summary" (Translations.multiCommunitySummary active.texts) model.form.summary config.summaryChanged
                            , AuthoringView.view
                                { id = "multi-community-sidebar"
                                , label = Translations.multiCommunitySidebar active.texts
                                , helpId = "multi-community-sidebar-help"
                                , helpText = Translations.topicBodyHelp active.texts
                                , required = False
                                , toMsg = config.sidebarAuthoring
                                }
                                active
                                model.form.sidebar
                            , if multi.deleted then
                                p [ A.class "field-error" ] [ text (Translations.multiCommunityDeleted active.texts) ]

                              else
                                text ""
                            , viewFormProblem active.texts model.form.problem
                            , div [ A.class "actions" ]
                                [ button [ A.type_ "submit", A.class "filled-button", A.disabled model.form.busy ] [ text (Translations.saveChanges active.texts) ]
                                , button
                                    [ A.type_ "button"
                                    , A.id "multi-community-delete"
                                    , A.class "outlined-button danger-text"
                                    , A.disabled model.form.busy
                                    , Events.onClick (config.setDeleted (not multi.deleted))
                                    ]
                                    [ text
                                        (if multi.deleted then
                                            Translations.multiCommunityRestore active.texts

                                         else
                                            Translations.multiCommunityDelete active.texts
                                        )
                                    ]
                                ]
                            ]
                        , section [ A.class "card form-stack" ]
                            [ h2 [] [ text (Translations.multiCommunityAddCommunity active.texts) ]
                            , form [ Events.onSubmit config.entrySearchSubmitted, A.class "actions" ]
                                [ label [ A.for "multi-community-entry-search" ] [ text (Translations.multiCommunitySearch active.texts) ]
                                , input
                                    [ A.id "multi-community-entry-search"
                                    , A.type_ "search"
                                    , A.value model.entrySearch
                                    , Events.onInput config.entrySearchChanged
                                    ]
                                    []
                                , button [ A.type_ "submit", A.class "outlined-button" ] [ text (Translations.searchSubmit active.texts) ]
                                ]
                            , entryProblemView active model.entryProblem
                            , viewRemote config.retry
                                active.texts
                                model.results
                                (\page ->
                                    if List.isEmpty page.items then
                                        p [ A.class "muted" ] [ text (Translations.multiCommunityNoResults active.texts) ]

                                    else
                                        ul [ A.class "entry-picker" ]
                                            (List.map
                                                (\communityView ->
                                                    li [ A.class "entry-option" ]
                                                        [ span [] [ bdi [] [ text communityView.community.name ] ]
                                                        , button
                                                            [ A.class "outlined-button"
                                                            , A.disabled (Set.member (String.fromInt communityView.community.id) model.entryBusy)
                                                            , Events.onClick (config.addEntry communityView.community.id)
                                                            ]
                                                            [ text (Translations.multiCommunityAddCommunity active.texts) ]
                                                        ]
                                                )
                                                page.items
                                            )
                                )
                            , if List.isEmpty detail.communities then
                                p [ A.class "muted" ] [ text (Translations.noCommunities active.texts) ]

                              else
                                ul [ A.class "entry-picker" ]
                                    (List.map
                                        (\communityView ->
                                            li [ A.class "entry-option" ]
                                                [ span [] [ bdi [] [ text communityView.community.name ] ]
                                                , button
                                                    [ A.class "text-button"
                                                    , A.disabled (Set.member (String.fromInt communityView.community.id) model.entryBusy)
                                                    , Events.onClick (config.removeEntry communityView.community.id)
                                                    ]
                                                    [ text (Translations.multiCommunityRemoveCommunity active.texts) ]
                                                ]
                                        )
                                        detail.communities
                                    )
                            ]
                        ]
            )
        )


entryProblemView : Active -> Maybe Api.Problem -> Html msg
entryProblemView active problem =
    case problem of
        Just value ->
            if String.contains "multi_community_entry_limit_reached" value.detail then
                p [ A.class "field-error", A.attribute "role" "alert" ] [ text (Translations.multiCommunityEntryLimit active.texts) ]

            else
                viewFormProblem active.texts (Just value)

        Nothing ->
            text ""


fieldInput : String -> String -> String -> (String -> msg) -> Html msg
fieldInput identifier labelText value change =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , input [ A.id identifier, A.type_ "text", A.value value, Events.onInput change ] []
        ]


selectField : String -> String -> String -> (String -> msg) -> List ( String, String ) -> Html msg
selectField identifier labelText value change options =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , select
            [ A.id identifier
            , Events.on "change" (Decode.map change (Decode.at [ "target", "value" ] Decode.string))
            ]
            (List.map (\( optionValue, optionLabel ) -> option [ A.value optionValue, A.selected (value == optionValue) ] [ text optionLabel ]) options)
        ]


listingOptions : Active -> List ( String, String )
listingOptions active =
    [ ( "all", Translations.listingAll active.texts )
    , ( "local", Translations.listingLocal active.texts )
    , ( "subscribed", Translations.listingSubscribed active.texts )
    ]


sortOptions : Active -> List ( String, String )
sortOptions active =
    [ ( "subscribers", Translations.multiCommunitySortSubscribers active.texts )
    , ( "subscribers_local", Translations.multiCommunitySortSubscribersLocal active.texts )
    , ( "communities", Translations.multiCommunitySortCommunities active.texts )
    , ( "new", Translations.multiCommunitySortNew active.texts )
    , ( "old", Translations.multiCommunitySortOld active.texts )
    , ( "name_asc", Translations.multiCommunitySortNameAsc active.texts )
    , ( "name_desc", Translations.multiCommunitySortNameDesc active.texts )
    ]


postSortOptions : Active -> List ( String, String )
postSortOptions active =
    [ ( "active", Translations.sortActive active.texts )
    , ( "hot", Translations.sortHot active.texts )
    , ( "new", Translations.sortNew active.texts )
    , ( "old", Translations.sortOld active.texts )
    , ( "top", Translations.sortTop active.texts )
    , ( "most_comments", Translations.sortMostComments active.texts )
    ]


timeOptions : Active -> List ( String, String )
timeOptions active =
    [ ( "", Translations.timeAll active.texts )
    , ( "3600", Translations.timeHour active.texts )
    , ( "86400", Translations.timeDay active.texts )
    , ( "604800", Translations.timeWeek active.texts )
    , ( "2592000", Translations.timeMonth active.texts )
    , ( "31536000", Translations.timeYear active.texts )
    ]


multiCommunityCard : Translations.I18n -> Domain.MultiCommunityView -> Html msg
multiCommunityCard texts view =
    let
        multi =
            view.multi
    in
    article [ A.class "card" ]
        [ h2 [] [ a [ A.href (Route.path (Route.MultiCommunity multi.name)) ] [ bdi [] [ text (Maybe.withDefault multi.name multi.title) ] ] ]
        , p [ A.class "metadata" ]
            [ bdi [] [ text multi.name ]
            , text " · "
            , text (Translations.multiCommunitySubscribers texts ++ ": " ++ String.fromInt multi.subscribers)
            , text " · "
            , text (Translations.multiCommunityCommunities texts ++ ": " ++ String.fromInt multi.communities)
            ]
        , Maybe.withDefault "" multi.summary |> Markdown.render
        ]
