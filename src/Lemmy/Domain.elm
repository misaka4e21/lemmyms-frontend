module Lemmy.Domain exposing (..)

import Json.Decode as D exposing (Decoder)
import Lemmy.CommentTree as CommentTree


type alias Id =
    Int


type alias Page a =
    { items : List a, nextPage : Maybe String, prevPage : Maybe String }


type VoteMode
    = AllVotes
    | LocalVotes
    | SubscribedVotes
    | DisabledVotes


type RegistrationMode
    = OpenRegistration
    | RequireApplication
    | RequireInvitation
    | ClosedRegistration


type CommunityVisibility
    = PublicCommunity
    | UnlistedCommunity
    | LocalOnlyPublicCommunity
    | LocalOnlyPrivateCommunity
    | PrivateCommunity
    | UnknownVisibility String


type FollowState
    = AcceptedFollow
    | PendingFollow
    | ApprovalRequiredFollow
    | DeniedFollow
    | UnknownFollowState String


type NotificationKind
    = MentionNotification
    | ReplyNotification
    | SubscribedNotification
    | PrivateMessageNotification
    | ModActionNotification
    | UnknownNotificationKind String


type NotificationData
    = NotificationComment CommentView
    | NotificationPost PostView
    | NotificationPrivateMessage PrivateMessage
    | NotificationModAction ModlogView


type ResolveObject
    = ResolvedPost PostView
    | ResolvedComment CommentView
    | ResolvedPerson PersonView
    | ResolvedCommunity CommunityView


type alias Site =
    { id : Id
    , name : String
    , sidebar : Maybe String
    , summary : Maybe String
    , icon : Maybe String
    , banner : Maybe String
    , contentWarning : Maybe String
    , apId : String
    , instanceId : Id
    , publishedAt : String
    , updatedAt : Maybe String
    }


type alias LocalSite =
    { id : Id
    , siteId : Id
    , siteSetup : Bool
    , communityCreationAdminOnly : Bool
    , emailVerificationRequired : Bool
    , applicationQuestion : Maybe String
    , privateInstance : Bool
    , registrationMode : RegistrationMode
    , federationEnabled : Bool
    , defaultPostListingType : String
    , defaultPostSortType : String
    , defaultCommentSortType : String
    , defaultPostUpvotes : VoteMode
    , defaultPostDownvotes : VoteMode
    , defaultCommentUpvotes : VoteMode
    , defaultCommentDownvotes : VoteMode
    , defaultTheme : String
    , legalInformation : Maybe String
    , hostname : String
    }


type alias SiteView =
    { site : Site, localSite : LocalSite }


type alias Tagline =
    { id : Id, content : String, publishedAt : String, updatedAt : Maybe String }


type alias GetSiteResponse =
    { siteView : SiteView
    , admins : List PersonView
    , version : String
    , tagline : Maybe Tagline
    , myFeedToken : Maybe String
    , captchaEnabled : Bool
    }


type alias Instance =
    { id : Id
    , domain : String
    , software : Maybe String
    , version : Maybe String
    , publishedAt : String
    , updatedAt : Maybe String
    }


type alias Person =
    { id : Id
    , name : String
    , displayName : Maybe String
    , avatar : Maybe String
    , banner : Maybe String
    , bio : Maybe String
    , local : Bool
    , deleted : Bool
    , botAccount : Bool
    , matrixUserId : Maybe String
    , apId : String
    , instanceId : Id
    , postCount : Int
    , commentCount : Int
    , publishedAt : String
    , updatedAt : Maybe String
    }


type alias PersonActions =
    { blockedAt : Maybe String
    , notedAt : Maybe String
    , note : Maybe String
    , votedAt : Maybe String
    , upvotes : Maybe Int
    , downvotes : Maybe Int
    , followedAt : Maybe String
    , followPending : Maybe Bool
    }


type alias PersonView =
    { person : Person
    , isAdmin : Bool
    , personActions : Maybe PersonActions
    , banned : Bool
    , banExpiresAt : Maybe String
    }


type alias Community =
    { id : Id
    , name : String
    , title : Maybe String
    , sidebar : Maybe String
    , summary : Maybe String
    , removed : Bool
    , deleted : Bool
    , nsfw : Bool
    , apId : String
    , local : Bool
    , icon : Maybe String
    , banner : Maybe String
    , postingRestrictedToMods : Bool
    , visibility : CommunityVisibility
    , subscribers : Int
    , posts : Int
    , comments : Int
    , usersActiveDay : Int
    , usersActiveWeek : Int
    , usersActiveMonth : Int
    , usersActiveHalfYear : Int
    , subscribersLocal : Int
    , reportCount : Int
    , unresolvedReportCount : Int
    , postUpvotes : VoteMode
    , postDownvotes : VoteMode
    , commentUpvotes : VoteMode
    , commentDownvotes : VoteMode
    , instanceId : Id
    , publishedAt : String
    , updatedAt : Maybe String
    }


type alias CommunityActions =
    { followedAt : Maybe String
    , blockedAt : Maybe String
    , becameModeratorAt : Maybe String
    , receivedBanAt : Maybe String
    , banExpiresAt : Maybe String
    , followState : Maybe FollowState
    , notifications : Maybe String
    }


type alias CommunityView =
    { community : Community
    , communityActions : Maybe CommunityActions
    , canMod : Bool
    , tags : List CommunityTag
    }


type alias CommunityTag =
    { id : Id
    , name : String
    , displayName : Maybe String
    , summary : Maybe String
    , communityId : Id
    , color : String
    , deleted : Bool
    }


type alias CommunityResponse =
    { communityView : CommunityView
    , moderators : List CommunityModeratorView
    , discussionLanguages : List Id
    }


type alias CommunityFollowerView =
    { community : Community, follower : Person }


type alias CommunityModeratorView =
    { community : Community, moderator : Person }


type alias PendingFollowView =
    { person : Person
    , community : Community
    , isNewInstance : Bool
    , followState : Maybe FollowState
    }


type alias Post =
    { id : Id
    , name : String
    , url : Maybe String
    , body : Maybe String
    , creatorId : Id
    , communityId : Id
    , removed : Bool
    , locked : Bool
    , publishedAt : String
    , updatedAt : Maybe String
    , deleted : Bool
    , nsfw : Bool
    , thumbnailUrl : Maybe String
    , apId : String
    , local : Bool
    , languageId : Id
    , featuredCommunity : Bool
    , featuredLocal : Bool
    , altText : Maybe String
    , comments : Int
    , score : Int
    , upvotes : Int
    , downvotes : Int
    , reportCount : Int
    , unresolvedReportCount : Int
    , newestCommentTimeAt : Maybe String
    }


type alias PostActions =
    { readAt : Maybe String
    , readCommentsAt : Maybe String
    , savedAt : Maybe String
    , votedAt : Maybe String
    , hiddenAt : Maybe String
    , voteIsUpvote : Maybe Bool
    , readCommentsAmount : Maybe Int
    , notifications : Maybe String
    }


type alias PostView =
    { post : Post
    , creator : Person
    , community : Community
    , communityActions : Maybe CommunityActions
    , personActions : Maybe PersonActions
    , postActions : Maybe PostActions
    , creatorIsAdmin : Bool
    , canMod : Bool
    , creatorIsModerator : Bool
    , creatorBannedFromCommunity : Bool
    , tags : List CommunityTag
    }


type alias Comment =
    { id : Id
    , creatorId : Id
    , postId : Id
    , content : String
    , removed : Bool
    , publishedAt : String
    , updatedAt : Maybe String
    , deleted : Bool
    , apId : String
    , local : Bool
    , path : String
    , distinguished : Bool
    , languageId : Id
    , score : Int
    , upvotes : Int
    , downvotes : Int
    , childCount : Int
    , reportCount : Int
    , unresolvedReportCount : Int
    , locked : Bool
    }


type alias CommentActions =
    { votedAt : Maybe String
    , savedAt : Maybe String
    , voteIsUpvote : Maybe Bool
    }


type alias CommentView =
    { comment : Comment
    , creator : Person
    , post : Post
    , community : Community
    , communityActions : Maybe CommunityActions
    , personActions : Maybe PersonActions
    , commentActions : Maybe CommentActions
    , creatorIsAdmin : Bool
    , canMod : Bool
    , tags : List CommunityTag
    }


type alias VoteView =
    { creator : Person
    , creatorBanned : Bool
    , creatorBannedFromCommunity : Bool
    , isUpvote : Bool
    }


type PersonContentItem
    = PersonPost PostView
    | PersonComment CommentView


type alias LocalUser =
    { id : Id
    , personId : Id
    , email : Maybe String
    , showNsfw : Bool
    , blurNsfw : Bool
    , theme : String
    , defaultPostSortType : String
    , defaultListingType : String
    , interfaceLanguage : String
    , showAvatars : Bool
    , showBotAccounts : Bool
    , showReadPosts : Bool
    , emailVerified : Bool
    , acceptedApplication : Bool
    , admin : Bool
    , postListingMode : String
    , defaultCommentSortType : String
    , showScore : Bool
    , showUpvotes : Bool
    , showDownvotes : String
    , sendNotificationsToEmail : Bool
    , openLinksInNewTab : Bool
    , infiniteScrollEnabled : Bool
    , totp2faEnabled : Bool
    , animatedImagesEnabled : Bool
    , collapseBotComments : Bool
    , privateMessagesEnabled : Bool
    , autoMarkFetchedPostsAsRead : Bool
    , hidePostsWithMedia : Bool
    , defaultPostTimeRangeSeconds : Maybe Int
    , showUpvotePercentage : Bool
    , showPersonVotes : Bool
    , defaultItemsPerPage : Int
    , showMedia : Bool
    , lastDonationNotificationAt : Maybe String
    , localSiteId : Id
    }


type alias GenerateTotpSecretResponse =
    { totpSecretUrl : String }


type alias EditTotpResponse =
    { enabled : Bool }


type alias LoginToken =
    { userId : Id
    , publishedAt : String
    , ip : Maybe String
    , userAgent : Maybe String
    }


type alias ListLoginsResponse =
    { logins : List LoginToken }


type alias Invitation =
    { token : String
    , maxUses : Maybe Int
    , usesCount : Int
    , expiresAt : Maybe String
    , publishedAt : String
    }


type alias Captcha =
    { png : String
    , wav : String
    , uuid : String
    }


type alias GetCaptchaResponse =
    { ok : Maybe Captcha }


type alias LoginResponse =
    { jwt : Maybe String
    , registrationCreated : Bool
    , verifyEmailSent : Bool
    }


type alias SiteRegistration =
    { mode : RegistrationMode
    , applicationQuestion : Maybe String
    , captchaEnabled : Bool
    }


type alias LocalUserView =
    { localUser : LocalUser
    , person : Person
    , banned : Bool
    , banExpiresAt : Maybe String
    }


type alias MyUserInfo =
    { localUserView : LocalUserView
    , follows : List CommunityFollowerView
    , moderates : List CommunityModeratorView
    , communityBlocks : List Community
    , instanceCommunitiesBlocks : List Instance
    , instancePersonsBlocks : List Instance
    , personBlocks : List Person
    , keywordBlocks : List String
    , discussionLanguages : List Id
    }


type alias SearchResponse =
    { resolve : Maybe ResolveObject
    , comments : List CommentView
    , posts : List PostView
    , communities : List CommunityView
    , persons : List PersonView
    , prevPage : Maybe String
    , nextPage : Maybe String
    }


type alias Notification =
    { id : Id
    , recipientId : Id
    , commentId : Maybe Id
    , read : Bool
    , publishedAt : String
    , kind : NotificationKind
    , postId : Maybe Id
    , privateMessageId : Maybe Id
    , modlogId : Maybe Id
    , creatorId : Id
    }


type alias NotificationView =
    { notification : Notification, data : NotificationData }


type alias PrivateMessage =
    { id : Id }


type alias PostReport =
    { id : Id
    , creatorId : Id
    , postId : Id
    , originalPostName : String
    , originalPostUrl : Maybe String
    , originalPostBody : Maybe String
    , reason : String
    , resolved : Bool
    , resolverId : Maybe Id
    , publishedAt : String
    , updatedAt : Maybe String
    , violatesInstanceRules : Bool
    , conclusion : Maybe String
    }


type alias CommentReport =
    { id : Id
    , creatorId : Id
    , commentId : Id
    , originalCommentText : String
    , reason : String
    , resolved : Bool
    , resolverId : Maybe Id
    , publishedAt : String
    , updatedAt : Maybe String
    , violatesInstanceRules : Bool
    , conclusion : Maybe String
    }


type alias CommunityReport =
    { id : Id
    , creatorId : Id
    , communityId : Id
    , originalCommunityName : String
    , originalCommunityTitle : Maybe String
    , originalCommunitySummary : Maybe String
    , originalCommunitySidebar : Maybe String
    , originalCommunityIcon : Maybe String
    , originalCommunityBanner : Maybe String
    , reason : String
    , resolved : Bool
    , resolverId : Maybe Id
    , publishedAt : String
    , updatedAt : Maybe String
    , conclusion : Maybe String
    }


type ReportView
    = PostReportView PostReport Post Community Person (Maybe Person)
    | CommentReportView CommentReport Comment Post Community Person (Maybe Person)
    | CommunityReportView CommunityReport Community Person (Maybe Person)
    | PrivateMessageReportView Id String Bool (Maybe String) String Person (Maybe Person)


type alias Modlog =
    { id : Id
    , kind : String
    , isRevert : Bool
    , reason : Maybe String
    , expiresAt : Maybe String
    , publishedAt : String
    , bulkActionParentId : Maybe Id
    , childCount : Int
    }


type alias ModlogView =
    { modlog : Modlog
    , moderator : Maybe Person
    , targetPerson : Maybe Person
    , targetInstance : Maybe Instance
    , targetCommunity : Maybe Community
    , targetPost : Maybe Post
    , targetComment : Maybe Comment
    }


type alias ImageUpload =
    { imageUrl : String, filename : String }


and : Decoder a -> Decoder (a -> b) -> Decoder b
and =
    D.map2 (|>)


maybeField : String -> Decoder a -> Decoder (Maybe a)
maybeField name decoder =
    D.oneOf
        [ D.field name (D.nullable decoder)
        , D.succeed Nothing
        ]


defaultField : String -> a -> Decoder a -> Decoder a
defaultField name fallback decoder =
    D.oneOf
        [ D.field name decoder
        , D.succeed fallback
        ]


identifier : Decoder Id
identifier =
    D.int


page : Decoder a -> Decoder (Page a)
page item =
    D.map3 Page
        (D.field "items" (D.list item))
        (maybeField "next_page" D.string)
        (maybeField "prev_page" D.string)


voteMode : Decoder VoteMode
voteMode =
    D.string
        |> D.andThen
            (\value ->
                case value of
                    "all" ->
                        D.succeed AllVotes

                    "local" ->
                        D.succeed LocalVotes

                    "subscribed" ->
                        D.succeed SubscribedVotes

                    "disable" ->
                        D.succeed DisabledVotes

                    _ ->
                        D.fail ("Unknown vote mode: " ++ value)
            )


registrationMode : Decoder RegistrationMode
registrationMode =
    D.string
        |> D.andThen
            (\value ->
                case value of
                    "open" ->
                        D.succeed OpenRegistration

                    "require_application" ->
                        D.succeed RequireApplication

                    "require_invitation" ->
                        D.succeed RequireInvitation

                    "closed" ->
                        D.succeed ClosedRegistration

                    _ ->
                        D.fail ("Unknown registration mode: " ++ value)
            )


communityVisibility : Decoder CommunityVisibility
communityVisibility =
    D.string
        |> D.andThen
            (\value ->
                case value of
                    "public" ->
                        D.succeed PublicCommunity

                    "unlisted" ->
                        D.succeed UnlistedCommunity

                    "local_only_public" ->
                        D.succeed LocalOnlyPublicCommunity

                    "local_only_private" ->
                        D.succeed LocalOnlyPrivateCommunity

                    "private" ->
                        D.succeed PrivateCommunity

                    other ->
                        D.succeed (UnknownVisibility other)
            )


followState : Decoder FollowState
followState =
    D.string
        |> D.andThen
            (\value ->
                case value of
                    "accepted" ->
                        D.succeed AcceptedFollow

                    "pending" ->
                        D.succeed PendingFollow

                    "approval_required" ->
                        D.succeed ApprovalRequiredFollow

                    "denied" ->
                        D.succeed DeniedFollow

                    other ->
                        D.succeed (UnknownFollowState other)
            )


notificationKind : Decoder NotificationKind
notificationKind =
    D.string
        |> D.andThen
            (\value ->
                case value of
                    "mention" ->
                        D.succeed MentionNotification

                    "reply" ->
                        D.succeed ReplyNotification

                    "subscribed" ->
                        D.succeed SubscribedNotification

                    "private_message" ->
                        D.succeed PrivateMessageNotification

                    "mod_action" ->
                        D.succeed ModActionNotification

                    other ->
                        D.succeed (UnknownNotificationKind other)
            )


site : Decoder Site
site =
    D.succeed Site
        |> and (D.field "id" identifier)
        |> and (D.field "name" D.string)
        |> and (maybeField "sidebar" D.string)
        |> and (maybeField "summary" D.string)
        |> and (maybeField "icon" D.string)
        |> and (maybeField "banner" D.string)
        |> and (maybeField "content_warning" D.string)
        |> and (D.field "ap_id" D.string)
        |> and (D.field "instance_id" identifier)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)


localSite : Decoder LocalSite
localSite =
    D.succeed LocalSite
        |> and (D.field "id" identifier)
        |> and (D.field "site_id" identifier)
        |> and (D.field "site_setup" D.bool)
        |> and (D.field "community_creation_admin_only" D.bool)
        |> and (D.field "email_verification_required" D.bool)
        |> and (maybeField "application_question" D.string)
        |> and (D.field "private_instance" D.bool)
        |> and (D.field "registration_mode" registrationMode)
        |> and (D.field "federation_enabled" D.bool)
        |> and (D.field "default_post_listing_type" D.string)
        |> and (D.field "default_post_sort_type" D.string)
        |> and (D.field "default_comment_sort_type" D.string)
        |> and (D.field "default_post_upvotes" voteMode)
        |> and (D.field "default_post_downvotes" voteMode)
        |> and (D.field "default_comment_upvotes" voteMode)
        |> and (D.field "default_comment_downvotes" voteMode)
        |> and (D.field "default_theme" D.string)
        |> and (maybeField "legal_information" D.string)
        |> and (D.field "hostname" D.string)


siteView : Decoder SiteView
siteView =
    D.map2 SiteView
        (D.field "site" site)
        (D.field "local_site" localSite)


tagline : Decoder Tagline
tagline =
    D.map4 Tagline
        (D.field "id" identifier)
        (D.field "content" D.string)
        (D.field "published_at" D.string)
        (maybeField "updated_at" D.string)


getSiteResponse : Decoder GetSiteResponse
getSiteResponse =
    D.succeed GetSiteResponse
        |> and (D.field "site_view" siteView)
        |> and (defaultField "admins" [] (D.list personView))
        |> and (D.field "version" D.string)
        |> and (maybeField "tagline" tagline)
        |> and (maybeField "my_feed_token" D.string)
        |> and (defaultField "captcha_enabled" False D.bool)


instance : Decoder Instance
instance =
    D.map6 Instance
        (D.field "id" identifier)
        (D.field "domain" D.string)
        (maybeField "software" D.string)
        (maybeField "version" D.string)
        (D.field "published_at" D.string)
        (maybeField "updated_at" D.string)


person : Decoder Person
person =
    D.succeed Person
        |> and (D.field "id" identifier)
        |> and (D.field "name" D.string)
        |> and (maybeField "display_name" D.string)
        |> and (maybeField "avatar" D.string)
        |> and (maybeField "banner" D.string)
        |> and (maybeField "bio" D.string)
        |> and (defaultField "local" False D.bool)
        |> and (defaultField "deleted" False D.bool)
        |> and (defaultField "bot_account" False D.bool)
        |> and (maybeField "matrix_user_id" D.string)
        |> and (D.field "ap_id" D.string)
        |> and (D.field "instance_id" identifier)
        |> and (defaultField "post_count" 0 D.int)
        |> and (defaultField "comment_count" 0 D.int)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)


personActions : Decoder PersonActions
personActions =
    D.succeed PersonActions
        |> and (maybeField "blocked_at" D.string)
        |> and (maybeField "noted_at" D.string)
        |> and (maybeField "note" D.string)
        |> and (maybeField "voted_at" D.string)
        |> and (maybeField "upvotes" D.int)
        |> and (maybeField "downvotes" D.int)
        |> and (maybeField "followed_at" D.string)
        |> and (maybeField "follow_pending" D.bool)


personView : Decoder PersonView
personView =
    D.succeed PersonView
        |> and (D.field "person" person)
        |> and (defaultField "is_admin" False D.bool)
        |> and (maybeField "person_actions" personActions)
        |> and (defaultField "banned" False D.bool)
        |> and (maybeField "ban_expires_at" D.string)


ownPersonView : Decoder PersonView
ownPersonView =
    myUserInfo
        |> D.map
            (\user ->
                { person = user.localUserView.person
                , isAdmin = user.localUserView.localUser.admin
                , personActions = Nothing
                , banned = user.localUserView.banned
                , banExpiresAt = user.localUserView.banExpiresAt
                }
            )


community : Decoder Community
community =
    D.succeed Community
        |> and (D.field "id" identifier)
        |> and (D.field "name" D.string)
        |> and (maybeField "title" D.string)
        |> and (maybeField "sidebar" D.string)
        |> and (maybeField "summary" D.string)
        |> and (defaultField "removed" False D.bool)
        |> and (defaultField "deleted" False D.bool)
        |> and (defaultField "nsfw" False D.bool)
        |> and (D.field "ap_id" D.string)
        |> and (defaultField "local" False D.bool)
        |> and (maybeField "icon" D.string)
        |> and (maybeField "banner" D.string)
        |> and (defaultField "posting_restricted_to_mods" False D.bool)
        |> and (D.field "visibility" communityVisibility)
        |> and (defaultField "subscribers" 0 D.int)
        |> and (defaultField "posts" 0 D.int)
        |> and (defaultField "comments" 0 D.int)
        |> and (defaultField "users_active_day" 0 D.int)
        |> and (defaultField "users_active_week" 0 D.int)
        |> and (defaultField "users_active_month" 0 D.int)
        |> and (defaultField "users_active_half_year" 0 D.int)
        |> and (defaultField "subscribers_local" 0 D.int)
        |> and (defaultField "report_count" 0 D.int)
        |> and (defaultField "unresolved_report_count" 0 D.int)
        |> and (D.field "post_upvotes" voteMode)
        |> and (D.field "post_downvotes" voteMode)
        |> and (D.field "comment_upvotes" voteMode)
        |> and (D.field "comment_downvotes" voteMode)
        |> and (D.field "instance_id" identifier)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)


communityActions : Decoder CommunityActions
communityActions =
    D.succeed CommunityActions
        |> and (maybeField "followed_at" D.string)
        |> and (maybeField "blocked_at" D.string)
        |> and (maybeField "became_moderator_at" D.string)
        |> and (maybeField "received_ban_at" D.string)
        |> and (maybeField "ban_expires_at" D.string)
        |> and (maybeField "follow_state" followState)
        |> and (maybeField "notifications" D.string)


communityView : Decoder CommunityView
communityView =
    D.succeed CommunityView
        |> and (D.field "community" community)
        |> and (maybeField "community_actions" communityActions)
        |> and (defaultField "can_mod" False D.bool)
        |> and (defaultField "tags" [] (D.list communityTag))


communityTag : Decoder CommunityTag
communityTag =
    D.succeed CommunityTag
        |> and (D.field "id" identifier)
        |> and (D.field "name" D.string)
        |> and (maybeField "display_name" D.string)
        |> and (maybeField "summary" D.string)
        |> and (D.field "community_id" identifier)
        |> and (defaultField "color" "" D.string)
        |> and (defaultField "deleted" False D.bool)


communityResponse : Decoder CommunityResponse
communityResponse =
    D.map3 CommunityResponse
        (D.field "community_view" communityView)
        (defaultField "moderators" [] (D.list communityModeratorView))
        (defaultField "discussion_languages" [] (D.list identifier))


communityFollowerView : Decoder CommunityFollowerView
communityFollowerView =
    D.map2 CommunityFollowerView
        (D.field "community" community)
        (D.field "follower" person)


communityModeratorView : Decoder CommunityModeratorView
communityModeratorView =
    D.map2 CommunityModeratorView
        (D.field "community" community)
        (D.field "moderator" person)


pendingFollow : Decoder PendingFollowView
pendingFollow =
    D.map4 PendingFollowView
        (D.field "person" person)
        (D.field "community" community)
        (defaultField "is_new_instance" False D.bool)
        (maybeField "follow_state" followState)


post : Decoder Post
post =
    D.succeed Post
        |> and (D.field "id" identifier)
        |> and (D.field "name" D.string)
        |> and (maybeField "url" D.string)
        |> and (maybeField "body" D.string)
        |> and (D.field "creator_id" identifier)
        |> and (D.field "community_id" identifier)
        |> and (defaultField "removed" False D.bool)
        |> and (defaultField "locked" False D.bool)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)
        |> and (defaultField "deleted" False D.bool)
        |> and (defaultField "nsfw" False D.bool)
        |> and (maybeField "thumbnail_url" D.string)
        |> and (D.field "ap_id" D.string)
        |> and (defaultField "local" False D.bool)
        |> and (D.field "language_id" identifier)
        |> and (defaultField "featured_community" False D.bool)
        |> and (defaultField "featured_local" False D.bool)
        |> and (maybeField "alt_text" D.string)
        |> and (defaultField "comments" 0 D.int)
        |> and (defaultField "score" 0 D.int)
        |> and (defaultField "upvotes" 0 D.int)
        |> and (defaultField "downvotes" 0 D.int)
        |> and (defaultField "report_count" 0 D.int)
        |> and (defaultField "unresolved_report_count" 0 D.int)
        |> and (maybeField "newest_comment_time_at" D.string)


postActions : Decoder PostActions
postActions =
    D.succeed PostActions
        |> and (maybeField "read_at" D.string)
        |> and (maybeField "read_comments_at" D.string)
        |> and (maybeField "saved_at" D.string)
        |> and (maybeField "voted_at" D.string)
        |> and (maybeField "hidden_at" D.string)
        |> and (maybeField "vote_is_upvote" D.bool)
        |> and (maybeField "read_comments_amount" D.int)
        |> and (maybeField "notifications" D.string)


postView : Decoder PostView
postView =
    D.succeed PostView
        |> and (D.field "post" post)
        |> and (D.field "creator" person)
        |> and (D.field "community" community)
        |> and (maybeField "community_actions" communityActions)
        |> and (maybeField "person_actions" personActions)
        |> and (maybeField "post_actions" postActions)
        |> and (defaultField "creator_is_admin" False D.bool)
        |> and (defaultField "can_mod" False D.bool)
        |> and (defaultField "creator_is_moderator" False D.bool)
        |> and (defaultField "creator_banned_from_community" False D.bool)
        |> and (defaultField "tags" [] (D.list communityTag))


comment : Decoder Comment
comment =
    D.succeed Comment
        |> and (D.field "id" identifier)
        |> and (D.field "creator_id" identifier)
        |> and (D.field "post_id" identifier)
        |> and (D.field "content" D.string)
        |> and (defaultField "removed" False D.bool)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)
        |> and (defaultField "deleted" False D.bool)
        |> and (D.field "ap_id" D.string)
        |> and (defaultField "local" False D.bool)
        |> and (D.field "path" D.string)
        |> and (defaultField "distinguished" False D.bool)
        |> and (D.field "language_id" identifier)
        |> and (defaultField "score" 0 D.int)
        |> and (defaultField "upvotes" 0 D.int)
        |> and (defaultField "downvotes" 0 D.int)
        |> and (defaultField "child_count" 0 D.int)
        |> and (defaultField "report_count" 0 D.int)
        |> and (defaultField "unresolved_report_count" 0 D.int)
        |> and (defaultField "locked" False D.bool)


commentActions : Decoder CommentActions
commentActions =
    D.succeed CommentActions
        |> and (maybeField "voted_at" D.string)
        |> and (maybeField "saved_at" D.string)
        |> and (maybeField "vote_is_upvote" D.bool)


commentView : Decoder CommentView
commentView =
    D.succeed CommentView
        |> and (D.field "comment" comment)
        |> and (D.field "creator" person)
        |> and (D.field "post" post)
        |> and (D.field "community" community)
        |> and (maybeField "community_actions" communityActions)
        |> and (maybeField "person_actions" personActions)
        |> and (maybeField "comment_actions" commentActions)
        |> and (defaultField "creator_is_admin" False D.bool)
        |> and (defaultField "can_mod" False D.bool)
        |> and (defaultField "tags" [] (D.list communityTag))


voteView : Decoder VoteView
voteView =
    D.succeed VoteView
        |> and (D.field "creator" person)
        |> and (defaultField "creator_banned" False D.bool)
        |> and (defaultField "creator_banned_from_community" False D.bool)
        |> and (D.field "is_upvote" D.bool)


personContentPage : Decoder (Page PersonContentItem)
personContentPage =
    D.succeed
        (\items nextPage prevPage ->
            { items = items, nextPage = nextPage, prevPage = prevPage }
        )
        |> and (D.field "items" (D.list personContentItem))
        |> and (maybeField "next_page" D.string)
        |> and (maybeField "prev_page" D.string)


personContentItem : Decoder PersonContentItem
personContentItem =
    D.field "type_" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "post" ->
                        D.map PersonPost postView

                    "comment" ->
                        D.map PersonComment commentView

                    other ->
                        D.fail ("Unsupported person content type: " ++ other)
            )


totpSecretResponse : Decoder GenerateTotpSecretResponse
totpSecretResponse =
    D.map GenerateTotpSecretResponse (D.field "totp_secret_url" D.string)


editTotpResponse : Decoder EditTotpResponse
editTotpResponse =
    D.map EditTotpResponse (D.field "enabled" D.bool)


loginToken : Decoder LoginToken
loginToken =
    D.succeed LoginToken
        |> and (D.field "user_id" identifier)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "ip" D.string)
        |> and (maybeField "user_agent" D.string)


listLoginsResponse : Decoder ListLoginsResponse
listLoginsResponse =
    D.map ListLoginsResponse (D.field "logins" (D.list loginToken))


invitation : Decoder Invitation
invitation =
    D.succeed Invitation
        |> and (D.field "token" D.string)
        |> and (maybeField "max_uses" D.int)
        |> and (defaultField "uses_count" 0 D.int)
        |> and (maybeField "expires_at" D.string)
        |> and (D.field "published_at" D.string)


captcha : Decoder Captcha
captcha =
    D.map3 Captcha
        (D.field "png" D.string)
        (D.field "wav" D.string)
        (D.field "uuid" D.string)


getCaptchaResponse : Decoder GetCaptchaResponse
getCaptchaResponse =
    D.map GetCaptchaResponse (maybeField "ok" captcha)


loginResponse : Decoder LoginResponse
loginResponse =
    D.succeed LoginResponse
        |> and (maybeField "jwt" D.string)
        |> and (defaultField "registration_created" False D.bool)
        |> and (defaultField "verify_email_sent" False D.bool)


threadedPage : Decoder (Page (CommentTree.Threaded CommentView))
threadedPage =
    page commentView
        |> D.map
            (\pageValue ->
                { items =
                    CommentTree.build
                        (\view -> view.comment.id)
                        (\view -> view.comment.path)
                        (\view -> view.comment.childCount)
                        pageValue.items
                , nextPage = pageValue.nextPage
                , prevPage = pageValue.prevPage
                }
            )


localUser : Decoder LocalUser
localUser =
    D.succeed LocalUser
        |> and (D.field "id" identifier)
        |> and (D.field "person_id" identifier)
        |> and (maybeField "email" D.string)
        |> and (defaultField "show_nsfw" False D.bool)
        |> and (defaultField "blur_nsfw" False D.bool)
        |> and (defaultField "theme" "browser" D.string)
        |> and (defaultField "default_post_sort_type" "active" D.string)
        |> and (defaultField "default_listing_type" "local" D.string)
        |> and (defaultField "interface_language" "browser" D.string)
        |> and (defaultField "show_avatars" True D.bool)
        |> and (defaultField "show_bot_accounts" True D.bool)
        |> and (defaultField "show_read_posts" True D.bool)
        |> and (defaultField "email_verified" False D.bool)
        |> and (defaultField "accepted_application" True D.bool)
        |> and (defaultField "admin" False D.bool)
        |> and (defaultField "post_listing_mode" "list" D.string)
        |> and (defaultField "default_comment_sort_type" "hot" D.string)
        |> and (defaultField "show_score" True D.bool)
        |> and (defaultField "show_upvotes" True D.bool)
        |> and (defaultField "show_downvotes" "show" D.string)
        |> and (defaultField "send_notifications_to_email" False D.bool)
        |> and (defaultField "open_links_in_new_tab" False D.bool)
        |> and (defaultField "infinite_scroll_enabled" False D.bool)
        |> and (defaultField "totp_2fa_enabled" False D.bool)
        |> and (defaultField "animated_images_enabled" True D.bool)
        |> and (defaultField "collapse_bot_comments" False D.bool)
        |> and (defaultField "private_messages_enabled" True D.bool)
        |> and (defaultField "auto_mark_fetched_posts_as_read" False D.bool)
        |> and (defaultField "hide_posts_with_media" False D.bool)
        |> and (maybeField "default_post_time_range_seconds" D.int)
        |> and (defaultField "show_upvote_percentage" False D.bool)
        |> and (defaultField "show_person_votes" False D.bool)
        |> and (defaultField "default_items_per_page" 20 D.int)
        |> and (defaultField "show_media" True D.bool)
        |> and (maybeField "last_donation_notification_at" D.string)
        |> and (D.field "local_site_id" identifier)


localUserView : Decoder LocalUserView
localUserView =
    D.map4 LocalUserView
        (D.field "local_user" localUser)
        (D.field "person" person)
        (defaultField "banned" False D.bool)
        (maybeField "ban_expires_at" D.string)


myUserInfo : Decoder MyUserInfo
myUserInfo =
    D.succeed MyUserInfo
        |> and (D.field "local_user_view" localUserView)
        |> and (defaultField "follows" [] (D.list communityFollowerView))
        |> and (defaultField "moderates" [] (D.list communityModeratorView))
        |> and (defaultField "community_blocks" [] (D.list community))
        |> and (defaultField "instance_communities_blocks" [] (D.list instance))
        |> and (defaultField "instance_persons_blocks" [] (D.list instance))
        |> and (defaultField "person_blocks" [] (D.list person))
        |> and (defaultField "keyword_blocks" [] (D.list D.string))
        |> and (defaultField "discussion_languages" [] (D.list identifier))


resolveObject : Decoder ResolveObject
resolveObject =
    D.field "type_" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "post" ->
                        D.map ResolvedPost postView

                    "comment" ->
                        D.map ResolvedComment commentView

                    "person" ->
                        D.map ResolvedPerson personView

                    "community" ->
                        D.map ResolvedCommunity communityView

                    other ->
                        D.fail ("Unsupported resolve type: " ++ other)
            )


searchResponse : Decoder SearchResponse
searchResponse =
    D.succeed SearchResponse
        |> and (maybeField "resolve" resolveObject)
        |> and (defaultField "comments" [] (D.list commentView))
        |> and (defaultField "posts" [] (D.list postView))
        |> and (defaultField "communities" [] (D.list communityView))
        |> and (defaultField "persons" [] (D.list personView))
        |> and (maybeField "prev_page" D.string)
        |> and (maybeField "next_page" D.string)


notification : Decoder Notification
notification =
    D.succeed Notification
        |> and (D.field "id" identifier)
        |> and (D.field "recipient_id" identifier)
        |> and (maybeField "comment_id" identifier)
        |> and (defaultField "read" False D.bool)
        |> and (D.field "published_at" D.string)
        |> and (D.field "kind" notificationKind)
        |> and (maybeField "post_id" identifier)
        |> and (maybeField "private_message_id" identifier)
        |> and (maybeField "modlog_id" identifier)
        |> and (D.field "creator_id" identifier)


privateMessage : Decoder PrivateMessage
privateMessage =
    D.map PrivateMessage (D.field "id" identifier)


notificationData : Decoder NotificationData
notificationData =
    D.field "type_" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "comment" ->
                        D.map NotificationComment commentView

                    "post" ->
                        D.map NotificationPost postView

                    "private_message" ->
                        D.map NotificationPrivateMessage privateMessage

                    "mod_action" ->
                        D.map NotificationModAction modlogView

                    other ->
                        D.fail ("Unsupported notification data: " ++ other)
            )


notificationView : Decoder NotificationView
notificationView =
    D.map2 NotificationView
        (D.field "notification" notification)
        (D.field "data" notificationData)


postReport : Decoder PostReport
postReport =
    D.succeed PostReport
        |> and (D.field "id" identifier)
        |> and (D.field "creator_id" identifier)
        |> and (D.field "post_id" identifier)
        |> and (D.field "original_post_name" D.string)
        |> and (maybeField "original_post_url" D.string)
        |> and (maybeField "original_post_body" D.string)
        |> and (D.field "reason" D.string)
        |> and (defaultField "resolved" False D.bool)
        |> and (maybeField "resolver_id" identifier)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)
        |> and (defaultField "violates_instance_rules" False D.bool)
        |> and (maybeField "conclusion" D.string)


commentReport : Decoder CommentReport
commentReport =
    D.succeed CommentReport
        |> and (D.field "id" identifier)
        |> and (D.field "creator_id" identifier)
        |> and (D.field "comment_id" identifier)
        |> and (D.field "original_comment_text" D.string)
        |> and (D.field "reason" D.string)
        |> and (defaultField "resolved" False D.bool)
        |> and (maybeField "resolver_id" identifier)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)
        |> and (defaultField "violates_instance_rules" False D.bool)
        |> and (maybeField "conclusion" D.string)


communityReport : Decoder CommunityReport
communityReport =
    D.succeed CommunityReport
        |> and (D.field "id" identifier)
        |> and (D.field "creator_id" identifier)
        |> and (D.field "community_id" identifier)
        |> and (D.field "original_community_name" D.string)
        |> and (maybeField "original_community_title" D.string)
        |> and (maybeField "original_community_summary" D.string)
        |> and (maybeField "original_community_sidebar" D.string)
        |> and (maybeField "original_community_icon" D.string)
        |> and (maybeField "original_community_banner" D.string)
        |> and (D.field "reason" D.string)
        |> and (defaultField "resolved" False D.bool)
        |> and (maybeField "resolver_id" identifier)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "updated_at" D.string)
        |> and (maybeField "conclusion" D.string)


reportView : Decoder ReportView
reportView =
    D.field "type_" D.string
        |> D.andThen
            (\kind ->
                case kind of
                    "post" ->
                        D.map5
                            (\reportValue postValue communityValue creatorValue resolverValue ->
                                PostReportView reportValue postValue communityValue creatorValue resolverValue
                            )
                            (D.field "post_report" postReport)
                            (D.field "post" post)
                            (D.field "community" community)
                            (D.field "creator" person)
                            (maybeField "resolver" person)

                    "comment" ->
                        D.map6
                            (\reportValue commentValue postValue communityValue creatorValue resolverValue ->
                                CommentReportView reportValue commentValue postValue communityValue creatorValue resolverValue
                            )
                            (D.field "comment_report" commentReport)
                            (D.field "comment" comment)
                            (D.field "post" post)
                            (D.field "community" community)
                            (D.field "creator" person)
                            (maybeField "resolver" person)

                    "community" ->
                        D.map4
                            (\reportValue communityValue creatorValue resolverValue ->
                                CommunityReportView reportValue communityValue creatorValue resolverValue
                            )
                            (D.field "community_report" communityReport)
                            (D.field "community" community)
                            (D.field "creator" person)
                            (maybeField "resolver" person)

                    "private_message" ->
                        D.map7
                            (\reportId reason resolvedValue conclusionValue publishedAt creatorValue resolverValue ->
                                PrivateMessageReportView reportId reason resolvedValue conclusionValue publishedAt creatorValue resolverValue
                            )
                            (D.field "private_message_report" (D.field "id" identifier))
                            (D.field "private_message_report" (D.field "reason" D.string))
                            (D.field "private_message_report" (defaultField "resolved" False D.bool))
                            (D.field "private_message_report" (maybeField "conclusion" D.string))
                            (D.field "private_message_report" (D.field "published_at" D.string))
                            (D.field "creator" person)
                            (maybeField "resolver" person)

                    other ->
                        D.fail ("Unsupported report type: " ++ other)
            )


modlog : Decoder Modlog
modlog =
    D.succeed Modlog
        |> and (D.field "id" identifier)
        |> and (D.field "kind" D.string)
        |> and (defaultField "is_revert" False D.bool)
        |> and (maybeField "reason" D.string)
        |> and (maybeField "expires_at" D.string)
        |> and (D.field "published_at" D.string)
        |> and (maybeField "bulk_action_parent_id" identifier)
        |> and (defaultField "child_count" 0 D.int)


modlogView : Decoder ModlogView
modlogView =
    D.succeed ModlogView
        |> and (D.field "modlog" modlog)
        |> and (maybeField "moderator" person)
        |> and (maybeField "target_person" person)
        |> and (maybeField "target_instance" instance)
        |> and (maybeField "target_community" community)
        |> and (maybeField "target_post" post)
        |> and (maybeField "target_comment" comment)


imageUpload : Decoder ImageUpload
imageUpload =
    D.map2 ImageUpload
        (D.field "image_url" D.string)
        (D.field "filename" D.string)


acctOf : Person -> String
acctOf value =
    value.name ++ "@" ++ hostOf value.apId


displayNameOf : Person -> String
displayNameOf value =
    Maybe.withDefault value.name value.displayName


avatarOf : Person -> String
avatarOf value =
    Maybe.withDefault "" value.avatar


personName : MyUserInfo -> String
personName user =
    user.localUserView.person.name


personApId : MyUserInfo -> String
personApId user =
    user.localUserView.person.apId


isAdmin : MyUserInfo -> Bool
isAdmin user =
    user.localUserView.localUser.admin


hostOf : String -> String
hostOf value =
    value
        |> String.split "/"
        |> List.filter (not << String.isEmpty)
        |> List.drop 1
        |> List.head
        |> Maybe.withDefault value
