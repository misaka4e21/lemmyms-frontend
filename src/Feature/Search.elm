module Feature.Search exposing (Config, Model, Msg(..), Outcome, SearchState, emptySearch, initial, load, pageSearch, update)

import Api
import App.Context exposing (Active)
import Generated.I18n as Translations
import Html exposing (Html, button, div, form, h2, input, label, option, p, section, select, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import List
import Remote exposing (Remote(..))
import Ui.CommunityCard exposing (communityCard)
import Ui.Feedback exposing (viewRemote)
import Ui.Layout exposing (pageHeading)
import Ui.Pagination exposing (viewPagination)
import Url exposing (Url)
import Url.Builder as Builder


type alias SearchState =
    { kind : String
    , query : String
    , results : Remote Domain.SearchResponse
    }


emptySearch : SearchState
emptySearch =
    { kind = "posts", query = "", results = NotAsked }


type alias Model =
    { search : SearchState }


initial : Model
initial =
    { search = emptySearch }


type Msg
    = SearchKindChanged String
    | SearchQueryChanged String
    | SearchSubmitted
    | Loaded Api.Response


type alias Outcome =
    { navigation : Maybe String, sessionProblem : Maybe Api.Problem }


update : Msg -> Model -> ( Model, Cmd Msg, Outcome )
update message model =
    let
        keep next navigation problem =
            ( next, Cmd.none, { navigation = navigation, sessionProblem = problem } )
    in
    case message of
        SearchKindChanged kind ->
            keep { search = (\search -> { search | kind = allowedKind kind }) model.search } Nothing Nothing

        SearchQueryChanged query ->
            keep { search = (\search -> { search | query = query }) model.search } Nothing Nothing

        SearchSubmitted ->
            let
                query =
                    String.trim model.search.query
            in
            if String.isEmpty query then
                keep { search = (\search -> { search | results = NotAsked }) model.search } Nothing Nothing

            else
                keep model
                    (Just
                        ("/search"
                            ++ Builder.toQuery
                                [ Builder.string "kind" model.search.kind
                                , Builder.string "q" query
                                ]
                        )
                    )
                    Nothing

        Loaded response ->
            case Api.decodeResponse Domain.searchResponse response of
                Ok results ->
                    keep { search = (\search -> { search | results = Ready results }) model.search } Nothing Nothing

                Err problem ->
                    keep { search = (\search -> { search | results = Failed problem }) model.search }
                        Nothing
                        (if problem.status == 401 then
                            Just problem

                         else
                            Nothing
                        )


load : Url -> ( Model, Cmd Msg )
load url =
    let
        kind =
            allowedKind (Route.query "kind" url)

        query =
            Route.query "q" url

        empty =
            String.isEmpty (String.trim query)
    in
    ( { search =
            { kind = kind
            , query = query
            , results =
                if empty then
                    NotAsked

                else
                    Loading
            }
      }
    , if empty then
        Cmd.none

      else
        Api.get (searchApiPath kind query (Route.cursor url)) Loaded
    )


searchApiPath : String -> String -> Maybe String -> String
searchApiPath kind query cursorValue =
    "/search"
        ++ Builder.toQuery
            ([ Builder.string "type_" (searchType kind)
             , Builder.string "search_term" query
             , Builder.string "limit" "20"
             ]
                ++ (if kind == "url" then
                        [ Builder.string "post_url_only" "true" ]

                    else
                        []
                   )
                ++ (case cursorValue of
                        Just cursor ->
                            [ Builder.string "page_cursor" cursor ]

                        Nothing ->
                            []
                   )
            )


searchType : String -> String
searchType kind =
    if kind == "url" then
        "posts"

    else
        kind


allowedKind : String -> String
allowedKind value =
    if List.member value [ "all", "posts", "comments", "communities", "users", "url" ] then
        value

    else
        "posts"


type alias Config msg =
    { retry : msg
    , searchKindChanged : String -> msg
    , searchQueryChanged : String -> msg
    , searchSubmitted : msg
    , postCard : Domain.PostView -> Html msg
    , commentCard : Domain.CommentView -> Html msg
    , personCard : Domain.PersonView -> Html msg
    }


type alias ViewModel =
    { search : SearchState
    , url : Url
    }


pageSearch : Config msg -> ViewModel -> Active -> Html msg
pageSearch config model active =
    pageHeading (Translations.searchTitle active.texts)
        (section [ A.class "primary-column" ]
            [ form [ Events.onSubmit config.searchSubmitted, A.class "card form-stack" ]
                [ p [ A.class "muted" ] [ text (Translations.searchIntro active.texts) ]
                , div []
                    [ label [ A.for "search-kind" ] [ text (Translations.searchType active.texts) ]
                    , select [ A.id "search-kind", Events.on "change" (Decode.map config.searchKindChanged (Decode.at [ "target", "value" ] Decode.string)) ]
                        [ kindOption active "all" Translations.searchAll model.search.kind
                        , kindOption active "posts" Translations.searchPosts model.search.kind
                        , kindOption active "comments" Translations.searchComments model.search.kind
                        , kindOption active "communities" Translations.searchCommunities model.search.kind
                        , kindOption active "users" Translations.searchUsers model.search.kind
                        , kindOption active "url" Translations.searchUrl model.search.kind
                        ]
                    ]
                , div []
                    [ label [ A.for "search-query" ] [ text (Translations.searchQuery active.texts) ]
                    , input [ A.id "search-query", A.type_ "search", A.required True, A.value model.search.query, Events.onInput config.searchQueryChanged ]
                        []
                    ]
                , button [ A.type_ "submit", A.class "filled-button" ] [ text (Translations.searchSubmit active.texts) ]
                ]
            , viewRemote config.retry
                active.texts
                model.search.results
                (\results ->
                    if resultCount results == 0 then
                        p [ A.class "empty-state" ] [ text (Translations.noContent active.texts) ]

                    else
                        div [ A.class "stack" ]
                            [ resolvedView config active results.resolve
                            , postResults config active model.search.kind results
                            , commentResults config active model.search.kind results
                            , communityResults active model.search.kind results
                            , personResults config active model.search.kind results
                            , viewPagination active.texts model.url results.prevPage results.nextPage
                            ]
                )
            ]
        )


kindOption : Active -> String -> (Translations.I18n -> String) -> String -> Html msg
kindOption active value labelFor selected =
    option [ A.value value, A.selected (value == selected) ] [ text (labelFor active.texts) ]


resultCount : Domain.SearchResponse -> Int
resultCount results =
    List.length results.posts
        + List.length results.comments
        + List.length results.communities
        + List.length results.persons
        + (case results.resolve of
            Just _ ->
                1

            Nothing ->
                0
          )


resolvedView : Config msg -> Active -> Maybe Domain.ResolveObject -> Html msg
resolvedView config active resolved =
    case resolved of
        Nothing ->
            text ""

        Just value ->
            section [ A.class "stack" ]
                [ h2 [] [ text (Translations.resolvedResult active.texts) ]
                , case value of
                    Domain.ResolvedPost post ->
                        config.postCard post

                    Domain.ResolvedComment comment ->
                        config.commentCard comment

                    Domain.ResolvedPerson person ->
                        config.personCard person

                    Domain.ResolvedCommunity community ->
                        communityCard active.texts community
                ]


postResults : Config msg -> Active -> String -> Domain.SearchResponse -> Html msg
postResults config active kind results =
    if not (List.member kind [ "all", "posts", "url" ]) || List.isEmpty results.posts then
        text ""

    else
        section [ A.class "stack" ]
            [ h2 [] [ text (Translations.searchPosts active.texts) ]
            , div [ A.class "stack" ] (List.map config.postCard results.posts)
            ]


commentResults : Config msg -> Active -> String -> Domain.SearchResponse -> Html msg
commentResults config active kind results =
    if not (List.member kind [ "all", "comments" ]) || List.isEmpty results.comments then
        text ""

    else
        section [ A.class "stack" ]
            [ h2 [] [ text (Translations.searchComments active.texts) ]
            , div [ A.class "stack" ] (List.map config.commentCard results.comments)
            ]


communityResults : Active -> String -> Domain.SearchResponse -> Html msg
communityResults active kind results =
    if not (List.member kind [ "all", "communities" ]) || List.isEmpty results.communities then
        text ""

    else
        section [ A.class "stack" ]
            [ h2 [] [ text (Translations.searchCommunities active.texts) ]
            , div [ A.class "stack" ] (List.map (communityCard active.texts) results.communities)
            ]


personResults : Config msg -> Active -> String -> Domain.SearchResponse -> Html msg
personResults config active kind results =
    if not (List.member kind [ "all", "users" ]) || List.isEmpty results.persons then
        text ""

    else
        section [ A.class "stack" ]
            [ h2 [] [ text (Translations.searchUsers active.texts) ]
            , div [ A.class "stack" ] (List.map config.personCard results.persons)
            ]
