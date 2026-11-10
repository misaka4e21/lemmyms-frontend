module AccountSource exposing (AccountContentSource(..), fromString)


type AccountContentSource
    = SavedContent
    | ReadContent
    | HiddenContent
    | LikedContent


fromString : String -> Maybe AccountContentSource
fromString value =
    case value of
        "saved" ->
            Just SavedContent

        "read" ->
            Just ReadContent

        "hidden" ->
            Just HiddenContent

        "liked" ->
            Just LikedContent

        _ ->
            Nothing
