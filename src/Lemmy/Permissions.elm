module Lemmy.Permissions exposing (canDeleteComment, canDeletePost, canEditComment, canEditPost, canFollow, canManageCommunity, canModerateComment, canModeratePost, canPost, isAdmin, isCreator, isFollowing, isModeratorOf, viewerId)

import Lemmy.Domain exposing (..)


viewerId : MyUserInfo -> Int
viewerId user =
    user.localUserView.person.id


isAdmin : MyUserInfo -> Bool
isAdmin user =
    user.localUserView.localUser.admin


isCreator : MyUserInfo -> Int -> Bool
isCreator user authorId =
    viewerId user == authorId


isModeratorOf : MyUserInfo -> Int -> Bool
isModeratorOf user communityId =
    List.any (\entry -> entry.community.id == communityId) user.moderates


isFollowing : CommunityView -> Bool
isFollowing view =
    case view.communityActions of
        Just actions ->
            actions.followState == Just AcceptedFollow || actions.followedAt /= Nothing

        Nothing ->
            False


canFollow : Maybe MyUserInfo -> CommunityView -> Bool
canFollow viewer view =
    case viewer of
        Nothing ->
            False

        Just user ->
            not (isFollowing view)
                && not (hasBlockedCommunity user view.community.id)
                && not view.community.deleted
                && not view.community.removed


canManageCommunity : Maybe MyUserInfo -> CommunityView -> Bool
canManageCommunity viewer view =
    case viewer of
        Nothing ->
            False

        Just user ->
            isAdmin user || view.canMod || isModeratorOf user view.community.id


canPost : Maybe MyUserInfo -> CommunityView -> Bool
canPost viewer view =
    case viewer of
        Nothing ->
            False

        Just user ->
            not user.localUserView.banned
                && not view.community.deleted
                && not view.community.removed
                && not (hasCommunityBan view.community.id view.communityActions)
                && (isAdmin user
                        || (if view.community.postingRestrictedToMods then
                                view.canMod || isModeratorOf user view.community.id

                            else
                                canReadCommunity user view
                           )
                   )


canReadCommunity : MyUserInfo -> CommunityView -> Bool
canReadCommunity user view =
    case view.community.visibility of
        PrivateCommunity ->
            isFollowing view || isAdmin user || view.canMod

        LocalOnlyPrivateCommunity ->
            True

        _ ->
            True


canEditPost : Maybe MyUserInfo -> PostView -> Bool
canEditPost viewer postView =
    case viewer of
        Nothing ->
            False

        Just user ->
            isCreator user postView.post.creatorId || isAdmin user || postView.canMod


canDeletePost : Maybe MyUserInfo -> PostView -> Bool
canDeletePost viewer postView =
    case viewer of
        Nothing ->
            False

        Just user ->
            isCreator user postView.post.creatorId


canModeratePost : Maybe MyUserInfo -> PostView -> Bool
canModeratePost viewer postView =
    case viewer of
        Nothing ->
            False

        Just user ->
            isAdmin user || postView.canMod


canEditComment : Maybe MyUserInfo -> CommentView -> Bool
canEditComment viewer commentView =
    case viewer of
        Nothing ->
            False

        Just user ->
            isCreator user commentView.comment.creatorId || isAdmin user || commentView.canMod


canDeleteComment : Maybe MyUserInfo -> CommentView -> Bool
canDeleteComment viewer commentView =
    case viewer of
        Nothing ->
            False

        Just user ->
            isCreator user commentView.comment.creatorId


canModerateComment : Maybe MyUserInfo -> CommentView -> Bool
canModerateComment viewer commentView =
    case viewer of
        Nothing ->
            False

        Just user ->
            isAdmin user || commentView.canMod


hasBlockedCommunity : MyUserInfo -> Int -> Bool
hasBlockedCommunity user communityId =
    List.any (\community -> community.id == communityId) user.communityBlocks


hasCommunityBan : Int -> Maybe CommunityActions -> Bool
hasCommunityBan communityId actions =
    case actions of
        Just value ->
            value.receivedBanAt /= Nothing

        Nothing ->
            False
