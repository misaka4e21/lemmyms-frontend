module Ui.CommunityCard exposing (communityCard)

import Generated.I18n as Translations
import Html exposing (Html, a, article, h2, p, span, text)
import Html.Attributes as A
import Lemmy.Domain as Domain
import Lemmy.Route as Route
import Ui.Formatting exposing (communityPolicySummary, postingPolicyLabel, visibilityLabel)


communityCard : Translations.I18n -> Domain.CommunityView -> Html msg
communityCard texts view =
    let
        community =
            view.community

        description =
            case community.summary of
                Just summary ->
                    summary

                Nothing ->
                    Maybe.withDefault "" community.sidebar
    in
    article [ A.class "card" ]
        [ h2 [] [ a [ A.href (Route.path (Route.Community community.name)) ] [ text (Maybe.withDefault community.name community.title) ] ]
        , if String.isEmpty description then
            text ""

          else
            p [ A.dir "auto" ] [ text description ]
        , p [ A.class "metadata" ]
            [ text
                (communityPolicySummary texts (visibilityText community.visibility) community.postingRestrictedToMods)
            ]
        , p [ A.class "chips" ]
            [ span [ A.class "chip" ] [ text (visibilityLabel texts (visibilityText community.visibility)) ]
            , case postingPolicyLabel texts community.postingRestrictedToMods of
                Just labelText ->
                    span [ A.class "chip" ] [ text labelText ]

                Nothing ->
                    text ""
            ]
        ]


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
