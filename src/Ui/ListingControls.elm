module Ui.ListingControls exposing (Config, view)

import Generated.I18n as Translations
import Html exposing (Html, div, label, option, select, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Decode


type alias Config msg =
    { listing : String
    , sort : String
    , timeRange : String
    , viewMode : String
    , listingChanged : String -> msg
    , sortChanged : String -> msg
    , timeRangeChanged : String -> msg
    , viewModeChanged : String -> msg
    }


view : Translations.I18n -> Config msg -> Html msg
view texts config =
    div [ A.class "listing-controls card" ]
        [ field "listing-type" (Translations.listingType texts) config.listing config.listingChanged (listingOptions texts)
        , field "listing-sort" (Translations.postSort texts) config.sort config.sortChanged (sortOptions texts)
        , field "listing-time" (Translations.timeRange texts) config.timeRange config.timeRangeChanged (timeOptions texts)
        , field "listing-view" (Translations.postLayout texts) config.viewMode config.viewModeChanged (viewOptions texts)
        ]


field : String -> String -> String -> (String -> msg) -> List ( String, String ) -> Html msg
field identifier labelText selected changed options =
    div []
        [ label [ A.for identifier ] [ text labelText ]
        , select
            [ A.id identifier
            , Events.on "change" (Decode.map changed (Decode.at [ "target", "value" ] Decode.string))
            ]
            (List.map
                (\( value, itemLabel ) ->
                    option [ A.value value, A.selected (value == selected) ] [ text itemLabel ]
                )
                options
            )
        ]


listingOptions : Translations.I18n -> List ( String, String )
listingOptions texts =
    [ ( "all", Translations.listingAll texts )
    , ( "local", Translations.listingLocal texts )
    , ( "subscribed", Translations.listingSubscribed texts )
    , ( "moderator_view", Translations.listingModerator texts )
    , ( "suggested", Translations.listingSuggested texts )
    ]


sortOptions : Translations.I18n -> List ( String, String )
sortOptions texts =
    [ ( "active", Translations.sortActive texts )
    , ( "hot", Translations.sortHot texts )
    , ( "new", Translations.sortNew texts )
    , ( "old", Translations.sortOld texts )
    , ( "top", Translations.sortTop texts )
    , ( "most_comments", Translations.sortMostComments texts )
    , ( "new_comments", Translations.sortNewComments texts )
    , ( "controversial", Translations.sortControversial texts )
    , ( "scaled", Translations.sortScaled texts )
    ]


timeOptions : Translations.I18n -> List ( String, String )
timeOptions texts =
    [ ( "", Translations.timeAll texts )
    , ( "3600", Translations.timeHour texts )
    , ( "86400", Translations.timeDay texts )
    , ( "604800", Translations.timeWeek texts )
    , ( "2592000", Translations.timeMonth texts )
    , ( "31536000", Translations.timeYear texts )
    ]


viewOptions : Translations.I18n -> List ( String, String )
viewOptions texts =
    [ ( "list", Translations.layoutList texts )
    , ( "card", Translations.layoutCard texts )
    , ( "small_card", Translations.layoutSmallCard texts )
    ]
