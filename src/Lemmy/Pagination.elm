module Lemmy.Pagination exposing (Cursor, advance, atStart, hasNext, hasPrevious, initial, next, previous, reset)

import Lemmy.Domain exposing (Page)


type alias Cursor =
    { current : Maybe String
    , next : Maybe String
    , previous : Maybe String
    }


initial : Cursor
initial =
    { current = Nothing, next = Nothing, previous = Nothing }


reset : Cursor
reset =
    initial


advance : Maybe String -> Page a -> Cursor
advance requested page =
    { current = requested, next = page.nextPage, previous = page.prevPage }


next : Cursor -> Maybe String
next cursor =
    cursor.next


previous : Cursor -> Maybe String
previous cursor =
    cursor.previous


hasNext : Cursor -> Bool
hasNext cursor =
    cursor.next /= Nothing


hasPrevious : Cursor -> Bool
hasPrevious cursor =
    cursor.previous /= Nothing


atStart : Cursor -> Bool
atStart cursor =
    cursor.current == Nothing
