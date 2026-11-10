module App.Interaction exposing (applyPost)

import App.State exposing (Model)
import Feature.Search as Search exposing (SearchResult(..))
import Lemmy.Domain as Domain
import List
import Remote exposing (Remote(..))


applyPost : Domain.PostView -> Model -> Model
applyPost post model =
    let
        transform candidate =
            if candidate.post.id == post.post.id then
                post

            else
                candidate

        page remote =
            Remote.map (\data -> { data | items = List.map transform data.items }) remote

        searchState =
            model.searchPage.search
    in
    { model
        | posts =
            (\postsState ->
                { postsState
                    | post = Remote.map transform model.posts.post
                }
            )
                model.posts
        , feed = (\feedState -> { feedState | topics = page model.feed.topics }) model.feed
        , communityPage = (\communityPageState -> { communityPageState | communityTopics = page model.communityPage.communityTopics }) model.communityPage
        , accountContent = (\state -> { state | posts = page model.accountContent.posts }) model.accountContent
        , searchPage =
            (\searchPageState ->
                { searchPageState
                    | search =
                        case model.searchPage.search.results of
                            Ready (PostSearch data) ->
                                { searchState | results = Ready (PostSearch { data | items = List.map transform data.items }) }

                            _ ->
                                model.searchPage.search
                }
            )
                model.searchPage
    }
