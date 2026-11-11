module Feature.CommunityManage.State exposing (..)

import Api
import Dict exposing (Dict)
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))
import Set exposing (Set)


type alias ManageState =
    { community : Remote Domain.CommunityView
    , members : Remote (Domain.Page Domain.CommunityModeratorView)
    , managers : Remote (Domain.Page Domain.CommunityModeratorView)
    , memberOffset : Int
    , managerOffset : Int
    , actor : String
    , postId : String
    , contextId : String
    , readPolicy : String
    , postPolicy : String
    , followPolicy : String
    , title : String
    , sidebar : String
    , summary : String
    , nsfw : Bool
    , visibility : String
    , postingRestricted : Bool
    , discussionLanguages : String
    , postUpvotes : String
    , postDownvotes : String
    , commentUpvotes : String
    , commentDownvotes : String
    , followRequests : Remote (Domain.Page Domain.PendingFollowView)
    , followRequestOffset : Int
    , reports : Remote (Domain.Page Domain.ReportView)
    , reportOffset : Int
    , reportNotes : Dict String String
    , reportBusy : Set String
    , modlog : Remote (Domain.Page Domain.ModlogView)
    , modlogOffset : Int
    , banActor : String
    , banReason : String
    , banExpires : String
    , banBusy : Bool
    , banProblem : Maybe Api.Problem
    , tagName : String
    , tagDisplayName : String
    , tagColor : String
    , tagBusy : Bool
    , iconUploading : Bool
    , bannerUploading : Bool
    , problem : Maybe Api.Problem
    }


type ManagePostAction
    = RemoveCommunityPost
    | RestoreCommunityPost
    | HideSitePost
    | UnhideSitePost
    | ImportSitePost
    | AcceptSubmission
    | RejectSubmission
    | BackfillDiscussion


emptyManage : ManageState
emptyManage =
    { community = NotAsked
    , members = NotAsked
    , managers = NotAsked
    , memberOffset = 0
    , managerOffset = 0
    , actor = ""
    , postId = ""
    , contextId = ""
    , readPolicy = "eligible_users"
    , postPolicy = "eligible_users"
    , followPolicy = "open"
    , title = ""
    , sidebar = ""
    , summary = ""
    , nsfw = False
    , visibility = "public"
    , postingRestricted = False
    , discussionLanguages = ""
    , postUpvotes = "all"
    , postDownvotes = "all"
    , commentUpvotes = "all"
    , commentDownvotes = "all"
    , followRequests = NotAsked
    , followRequestOffset = 0
    , reports = NotAsked
    , reportOffset = 0
    , reportNotes = Dict.empty
    , reportBusy = Set.empty
    , modlog = NotAsked
    , modlogOffset = 0
    , banActor = ""
    , banReason = ""
    , banExpires = ""
    , banBusy = False
    , banProblem = Nothing
    , tagName = ""
    , tagDisplayName = ""
    , tagColor = "color_01"
    , tagBusy = False
    , iconUploading = False
    , bannerUploading = False
    , problem = Nothing
    }


normalizeManagePolicies : ManageState -> ManageState
normalizeManagePolicies manage =
    if manage.postPolicy == "eligible_users" && manage.readPolicy == "members" then
        { manage | readPolicy = "eligible_users" }

    else
        manage


manageActionKey : ManagePostAction -> String
manageActionKey action =
    case action of
        RemoveCommunityPost ->
            "remove"

        RestoreCommunityPost ->
            "restore"

        HideSitePost ->
            "hide"

        UnhideSitePost ->
            "unhide"

        ImportSitePost ->
            "import"

        AcceptSubmission ->
            "accept"

        RejectSubmission ->
            "reject"

        BackfillDiscussion ->
            "backfill"


loadedCommunityId : ManageState -> Int
loadedCommunityId manage =
    case manage.community of
        Ready community ->
            community.community.id

        _ ->
            0


type alias Model =
    { manage : Maybe ManageState, busy : Set String }


initial : Model
initial =
    { manage = Nothing, busy = Set.empty }


reset : Model -> Model
reset model =
    { model | manage = Nothing }
