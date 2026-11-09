module Lemmy.CommentTree exposing (Threaded(..), build, depth, flatten)

import Dict exposing (Dict)
import Set exposing (Set)


type Threaded a
    = Threaded
        { value : a
        , children : List (Threaded a)
        , depth : Int
        , childCount : Int
        }


type alias Node a =
    { value : a
    , path : List Int
    , childCount : Int
    , children : List Int
    }


build : (a -> Int) -> (a -> String) -> (a -> Int) -> List a -> List (Threaded a)
build key path childCount items =
    let
        nodes =
            List.map
                (\item ->
                    { value = item
                    , path = parsePath (path item)
                    , childCount = childCount item
                    , children = []
                    }
                )
                items

        keyed =
            List.foldl (\item dict -> Dict.insert (key item.value) item dict) Dict.empty nodes

        withChildren =
            List.foldl
                (\item dict ->
                    case parentId (key item.value) item.path of
                        Just parent ->
                            if parent == key item.value || not (Dict.member parent dict) then
                                dict

                            else
                                Dict.update parent
                                    (Maybe.map (\node -> { node | children = node.children ++ [ key item.value ] }))
                                    dict

                        Nothing ->
                            dict
                )
                keyed
                nodes

        roots =
            List.filterMap
                (\item ->
                    case parentId (key item.value) item.path of
                        Just parent ->
                            if parent /= key item.value && Dict.member parent withChildren then
                                Nothing

                            else
                                Just (key item.value)

                        Nothing ->
                            Just (key item.value)
                )
                nodes
    in
    List.filterMap (thread 1 Set.empty withChildren) roots


parsePath : String -> List Int
parsePath value =
    value
        |> String.split "."
        |> List.filterMap String.toInt


parentId : Int -> List Int -> Maybe Int
parentId self path =
    case List.reverse path of
        _ :: parent :: _ ->
            if parent == 0 then
                Nothing

            else
                Just parent

        _ ->
            Nothing


thread : Int -> Set Int -> Dict Int (Node a) -> Int -> Maybe (Threaded a)
thread level visited nodes key =
    if Set.member key visited then
        Nothing

    else
        Dict.get key nodes
            |> Maybe.map
                (\node ->
                    Threaded
                        { value = node.value
                        , children =
                            List.filterMap
                                (thread (level + 1) (Set.insert key visited) nodes)
                                node.children
                        , depth = level
                        , childCount = node.childCount
                        }
                )


flatten : List (Threaded a) -> List a
flatten threads =
    List.concatMap
        (\(Threaded node) -> node.value :: flatten node.children)
        threads


depth : Threaded a -> Int
depth (Threaded node) =
    node.depth
