module LemmyFixtures exposing (commentJson, commentViewJson, communityJson, communityViewJson, imageJson, modlogJson, multiCommunityJson, multiCommunityResponseJson, multiCommunityViewJson, myUserJson, notificationJson, personJson, personViewJson, postJson, postViewJson, privateMessageJson, privateMessageReportJson, privateMessageViewJson, reportJson, searchJson, siteJson)


personJson : String
personJson =
    """
    {"id":1,"name":"alice","display_name":"Alice","avatar":null,"banner":null,"bio":"Hi","local":true,"deleted":false,"bot_account":false,"ap_id":"https://forum.test/u/alice","instance_id":1,"post_count":1,"comment_count":2,"published_at":"2026-11-09T00:00:00Z","updated_at":null}
    """


personViewJson : String
personViewJson =
    "{\"person\":"
        ++ personJson
        ++ ",\"is_admin\":false,\"person_actions\":null,\"banned\":false,\"ban_expires_at\":null}"


communityJson : String
communityJson =
    """
    {"id":2,"name":"news","title":"News","sidebar":"Sidebar","summary":"Summary","removed":false,"published_at":"2026-11-09T00:00:00Z","deleted":false,"nsfw":false,"ap_id":"https://forum.test/c/news","local":true,"icon":null,"banner":null,"posting_restricted_to_mods":false,"visibility":"public","subscribers":10,"posts":2,"comments":3,"users_active_day":1,"users_active_week":2,"users_active_month":3,"users_active_half_year":4,"subscribers_local":5,"report_count":0,"unresolved_report_count":0,"post_upvotes":"all","post_downvotes":"all","comment_upvotes":"all","comment_downvotes":"all","instance_id":1,"updated_at":null}
    """


communityActionsJson : String
communityActionsJson =
    """
    {"followed_at":"2026-11-09T00:00:00Z","blocked_at":null,"became_moderator_at":null,"received_ban_at":null,"ban_expires_at":null,"follow_state":"accepted","notifications":null}
    """


communityViewJson : String
communityViewJson =
    "{\"community\":"
        ++ communityJson
        ++ ",\"community_actions\":"
        ++ communityActionsJson
        ++ ",\"can_mod\":false}"


postJson : String
postJson =
    """
    {"id":10,"name":"Title","url":null,"body":"Body","creator_id":1,"community_id":2,"removed":false,"locked":false,"published_at":"2026-11-09T00:00:00Z","updated_at":null,"deleted":false,"nsfw":false,"thumbnail_url":null,"ap_id":"https://forum.test/post/10","local":true,"language_id":1,"featured_community":false,"featured_local":false,"alt_text":null,"comments":1,"score":2,"upvotes":3,"downvotes":1,"report_count":0,"unresolved_report_count":0,"newest_comment_time_at":null}
    """


postActionsJson : String
postActionsJson =
    """
    {"read_at":"2026-11-09T00:00:00Z","read_comments_at":null,"saved_at":"2026-11-09T00:00:00Z","voted_at":"2026-11-09T00:00:00Z","hidden_at":null,"vote_is_upvote":true,"read_comments_amount":0,"notifications":null}
    """


postViewJson : String
postViewJson =
    "{\"post\":"
        ++ postJson
        ++ ",\"creator\":"
        ++ personJson
        ++ ",\"community\":"
        ++ communityJson
        ++ ",\"community_actions\":"
        ++ communityActionsJson
        ++ ",\"post_actions\":"
        ++ postActionsJson
        ++ ",\"creator_is_admin\":false,\"can_mod\":false,\"creator_is_moderator\":false,\"creator_banned_from_community\":false}"


commentJson : String
commentJson =
    """
    {"id":20,"creator_id":1,"post_id":10,"content":"Reply","removed":false,"published_at":"2026-11-09T00:00:00Z","updated_at":null,"deleted":false,"ap_id":"https://forum.test/comment/20","local":true,"path":"0.20","distinguished":false,"language_id":1,"score":0,"upvotes":0,"downvotes":0,"child_count":0,"report_count":0,"unresolved_report_count":0,"locked":false}
    """


commentViewJson : String
commentViewJson =
    "{\"comment\":"
        ++ commentJson
        ++ ",\"creator\":"
        ++ personJson
        ++ ",\"post\":"
        ++ postJson
        ++ ",\"community\":"
        ++ communityJson
        ++ ",\"community_actions\":"
        ++ communityActionsJson
        ++ ",\"comment_actions\":{\"voted_at\":null,\"saved_at\":null,\"vote_is_upvote\":null},\"creator_is_admin\":false,\"can_mod\":false}"


localUserJson : String
localUserJson =
    """
    {"id":1,"person_id":1,"email":"alice@example.test","show_nsfw":false,"blur_nsfw":false,"theme":"browser","default_post_sort_type":"active","default_listing_type":"local","interface_language":"browser","show_avatars":true,"show_bot_accounts":true,"show_read_posts":true,"email_verified":true,"accepted_application":true,"admin":false,"post_listing_mode":"list","default_comment_sort_type":"hot","show_score":true,"show_upvotes":true,"show_downvotes":"show","local_site_id":1}
    """


myUserJson : String
myUserJson =
    "{\"local_user_view\":{\"local_user\":"
        ++ localUserJson
        ++ ",\"person\":"
        ++ personJson
        ++ ",\"banned\":false,\"ban_expires_at\":null},\"follows\":[],\"moderates\":[],\"multi_community_follows\":[],\"community_blocks\":[],\"instance_communities_blocks\":[],\"instance_persons_blocks\":[],\"person_blocks\":[],\"keyword_blocks\":[],\"discussion_languages\":[]}"


siteJson : String
siteJson =
    """
    {"site_view":{"site":{"id":1,"name":"Forum","sidebar":null,"summary":null,"icon":null,"banner":null,"content_warning":null,"ap_id":"https://forum.test/","instance_id":1,"published_at":"2026-11-09T00:00:00Z"},"local_site":{"id":1,"site_id":1,"site_setup":true,"community_creation_admin_only":false,"email_verification_required":false,"private_instance":false,"registration_mode":"open","federation_enabled":true,"default_post_listing_type":"local","default_post_sort_type":"active","default_comment_sort_type":"hot","default_post_upvotes":"all","default_post_downvotes":"all","default_comment_upvotes":"all","default_comment_downvotes":"all","default_theme":"browser","legal_information":null,"hostname":"forum.test"}},"admins":[],"version":"1.0.0-beta.3","tagline":null,"my_feed_token":null,"captcha_enabled":false}
    """


searchJson : String
searchJson =
    "{\"resolve\":null,\"comments\":[],\"posts\":["
        ++ postViewJson
        ++ "],\"communities\":["
        ++ communityViewJson
        ++ "],\"persons\":[],\"multi_communities\":[],\"prev_page\":null,\"next_page\":\"next-cursor\"}"


imageJson : String
imageJson =
    "{\"image_url\":\"https://forum.test/pictrs/image/abc.png\",\"filename\":\"abc.png\"}"


notificationJson : String
notificationJson =
    "{\"notification\":{\"id\":1,\"recipient_id\":1,\"comment_id\":20,\"read\":false,\"published_at\":\"2026-11-09T00:00:00Z\",\"kind\":\"reply\",\"post_id\":10,\"private_message_id\":null,\"modlog_id\":null,\"creator_id\":1},\"data\":{\"type_\":\"comment\",\"comment\":"
        ++ commentJson
        ++ ",\"creator\":"
        ++ personJson
        ++ ",\"post\":"
        ++ postJson
        ++ ",\"community\":"
        ++ communityJson
        ++ ",\"comment_actions\":{\"voted_at\":null,\"saved_at\":null,\"vote_is_upvote\":null},\"creator_is_admin\":false,\"can_mod\":false}}"


reportJson : String
reportJson =
    "{\"items\":[{\"type_\":\"post\",\"post_report\":{\"id\":7,\"creator_id\":1,\"post_id\":10,\"original_post_name\":\"Title\",\"original_post_url\":null,\"original_post_body\":\"Body\",\"reason\":\"spam\",\"resolved\":false,\"resolver_id\":null,\"published_at\":\"2026-11-09T00:00:00Z\",\"updated_at\":null,\"violates_instance_rules\":false,\"conclusion\":null},\"post\":"
        ++ postJson
        ++ ",\"community\":"
        ++ communityJson
        ++ ",\"creator\":"
        ++ personJson
        ++ ",\"resolver\":null,\"post_creator\":"
        ++ personJson
        ++ ",\"creator_is_admin\":false,\"creator_is_moderator\":false,\"creator_banned\":false,\"creator_banned_from_community\":false}],\"next_page\":null,\"prev_page\":null}"


privateMessageJson : String
privateMessageJson =
    """
    {"id":30,"creator_id":1,"recipient_id":2,"content":"Hello there","deleted":false,"published_at":"2026-11-09T00:00:00Z","updated_at":null,"ap_id":"https://forum.test/private_message/30","local":true,"removed":false,"deleted_by_recipient":false,"origin_local_site_id":1}
    """


privateMessageViewJson : String
privateMessageViewJson =
    "{\"private_message\":"
        ++ privateMessageJson
        ++ ",\"creator\":"
        ++ personJson
        ++ ",\"recipient\":"
        ++ personJson
        ++ "}"


multiCommunityJson : String
multiCommunityJson =
    """
    {"id":5,"creator_id":1,"instance_id":1,"name":"tech","title":"Tech","summary":"Grouped technology feeds","local":true,"deleted":false,"ap_id":"https://forum.test/m/tech","last_refreshed_at":"2026-11-09T00:00:00Z","following_url":"https://forum.test/m/tech/following","published_at":"2026-11-09T00:00:00Z","updated_at":null,"subscribers":3,"subscribers_local":2,"communities":1,"sidebar":"Tech sidebar","origin_local_site_id":1}
    """


multiCommunityViewJson : String
multiCommunityViewJson =
    "{\"multi\":"
        ++ multiCommunityJson
        ++ ",\"follow_state\":\"accepted\",\"owner\":"
        ++ personJson
        ++ "}"


multiCommunityResponseJson : String
multiCommunityResponseJson =
    "{\"multi_community_view\":"
        ++ multiCommunityViewJson
        ++ ",\"communities\":["
        ++ communityViewJson
        ++ "]}"


privateMessageReportJson : String
privateMessageReportJson =
    "{\"items\":[{\"type_\":\"private_message\",\"private_message_report\":{\"id\":9,\"creator_id\":2,\"private_message_id\":30,\"original_pm_text\":\"Hello there\",\"reason\":\"spam\",\"resolved\":false,\"resolver_id\":null,\"published_at\":\"2026-11-09T00:00:00Z\",\"updated_at\":null,\"conclusion\":null},\"private_message\":"
        ++ privateMessageJson
        ++ ",\"creator\":"
        ++ personJson
        ++ ",\"private_message_creator\":"
        ++ personJson
        ++ ",\"resolver\":null}]}"


modlogJson : String
modlogJson =
    "{\"items\":[{\"modlog\":{\"id\":3,\"kind\":\"mod_ban_from_community\",\"is_revert\":false,\"reason\":\"spam\",\"expires_at\":null,\"published_at\":\"2026-11-09T00:00:00Z\",\"bulk_action_parent_id\":null,\"child_count\":0},\"moderator\":"
        ++ personJson
        ++ ",\"target_community\":"
        ++ communityJson
        ++ "}],\"next_page\":null,\"prev_page\":null}"
