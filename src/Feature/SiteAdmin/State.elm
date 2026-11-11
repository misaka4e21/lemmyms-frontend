module Feature.SiteAdmin.State exposing (..)

import Api
import Dict exposing (Dict)
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))
import Set exposing (Set)


type alias Model =
    { voteSettings : Remote Domain.LocalSite
    , upvotesEnabled : Bool
    , downvotesEnabled : Bool
    , settingsBusy : Bool
    , settingsProblem : Maybe Api.Problem
    , reports : Remote (Domain.Page Domain.ReportView)
    , reportState : String
    , reportCommunity : String
    , reportCursor : Maybe String
    , reportNotes : Dict String String
    , reportBusy : Set String
    , modlog : Remote (Domain.Page Domain.ModlogView)
    , modlogCommunity : String
    , modlogCursor : Maybe String
    , banActor : String
    , banReason : String
    , banExpires : String
    , banBusy : Bool
    , banProblem : Maybe Api.Problem
    }


initial : Model
initial =
    { voteSettings = NotAsked
    , upvotesEnabled = True
    , downvotesEnabled = True
    , settingsBusy = False
    , settingsProblem = Nothing
    , reports = NotAsked
    , reportState = "open"
    , reportCommunity = ""
    , reportCursor = Nothing
    , reportNotes = Dict.empty
    , reportBusy = Set.empty
    , modlog = NotAsked
    , modlogCommunity = ""
    , modlogCursor = Nothing
    , banActor = ""
    , banReason = ""
    , banExpires = ""
    , banBusy = False
    , banProblem = Nothing
    }


reset : Model -> Model
reset _ =
    initial
