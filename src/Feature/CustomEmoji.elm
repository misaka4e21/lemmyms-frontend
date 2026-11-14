module Feature.CustomEmoji exposing (Emoji, Field(..), Form, Model, body, change, decoder, emptyForm, initial, load, page, valid)

import Api
import App.Context exposing (Active)
import App.Session exposing (AuthState(..))
import Generated.I18n as T
import Html exposing (Html, button, div, form, img, input, label, p, section, text)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as D
import Json.Encode as E
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))
import Ui.Feedback exposing (loginRequired, viewFormProblem, viewRemote)
import Ui.Layout exposing (pageHeading)


type alias Emoji =
    { id : Int, shortcode : String, imageUrl : String, altText : String, category : String, keywords : List String }


type alias Form =
    { id : Maybe Int, shortcode : String, imageUrl : String, altText : String, category : String, keywords : String }


type alias Model =
    { items : Remote (List Emoji), form : Form, busy : Bool, problem : Maybe Api.Problem }


type Field
    = Shortcode
    | ImageUrl
    | AltText
    | Category
    | Keywords


emptyForm : Form
emptyForm =
    { id = Nothing, shortcode = "", imageUrl = "", altText = "", category = "", keywords = "" }


initial : Model
initial =
    { items = NotAsked, form = emptyForm, busy = False, problem = Nothing }


decoder : D.Decoder (List Emoji)
decoder =
    D.field "custom_emojis"
        (D.list
            (D.map6 Emoji
                (D.at [ "custom_emoji", "id" ] Domain.identifier)
                (D.at [ "custom_emoji", "shortcode" ] D.string)
                (D.at [ "custom_emoji", "image_url" ] D.string)
                (D.at [ "custom_emoji", "alt_text" ] D.string)
                (D.at [ "custom_emoji", "category" ] D.string)
                (D.field "keywords" (D.list (D.field "keyword" D.string)))
            )
        )


load : AuthState -> (Api.Response -> msg) -> ( Model, Cmd msg )
load auth loaded =
    case auth of
        Authenticated user ->
            if Domain.isAdmin user then
                ( { initial | items = Loading }, Api.get "/custom_emoji/list" loaded )

            else
                ( initial, Cmd.none )

        _ ->
            ( initial, Cmd.none )


change : Field -> String -> Form -> Form
change selectedField value current =
    case selectedField of
        Shortcode ->
            { current | shortcode = value }

        ImageUrl ->
            { current | imageUrl = value }

        AltText ->
            { current | altText = value }

        Category ->
            { current | category = value }

        Keywords ->
            { current | keywords = value }


valid : Form -> Bool
valid current =
    List.all (not << String.isEmpty << String.trim) [ current.shortcode, current.imageUrl, current.altText, current.category ]


body : Form -> String
body current =
    E.object
        ([ ( "shortcode", E.string (String.trim current.shortcode) )
         , ( "image_url", E.string (String.trim current.imageUrl) )
         , ( "alt_text", E.string current.altText )
         , ( "category", E.string (String.trim current.category) )
         , ( "keywords", E.list E.string (String.split "," current.keywords |> List.map String.trim |> List.filter (not << String.isEmpty)) )
         ]
            ++ (case current.id of
                    Just id ->
                        [ ( "id", E.int id ) ]

                    Nothing ->
                        []
               )
        )
        |> E.encode 0


page : { retry : msg, changed : Field -> String -> msg, edit : Emoji -> msg, cancel : msg, submit : msg, delete : Emoji -> msg } -> Active -> AuthState -> Model -> Html msg
page config active auth model =
    pageHeading (T.customEmojis active.texts)
        (case auth of
            Authenticated user ->
                if Domain.isAdmin user then
                    div [ A.class "stack" ]
                        [ form [ A.class "card form-stack", Events.onSubmit config.submit ]
                            [ field active config.changed "emoji-shortcode" T.emojiShortcode Shortcode model.form.shortcode True
                            , field active config.changed "emoji-image-url" T.emojiImageUrl ImageUrl model.form.imageUrl True
                            , field active config.changed "emoji-alt-text" T.emojiAltText AltText model.form.altText True
                            , field active config.changed "emoji-category" T.emojiCategory Category model.form.category True
                            , field active config.changed "emoji-keywords" T.emojiKeywords Keywords model.form.keywords False
                            , viewFormProblem active.texts model.problem
                            , div [ A.class "actions" ]
                                [ button [ A.type_ "submit", A.class "filled-button", A.disabled (model.busy || not (valid model.form)) ]
                                    [ text
                                        (if model.form.id == Nothing then
                                            T.create active.texts

                                         else
                                            T.saveChanges active.texts
                                        )
                                    ]
                                , if model.form.id /= Nothing then
                                    button [ A.type_ "button", Events.onClick config.cancel ] [ text (T.cancel active.texts) ]

                                  else
                                    text ""
                                ]
                            ]
                        , viewRemote config.retry
                            active.texts
                            model.items
                            (\items ->
                                if List.isEmpty items then
                                    p [ A.class "empty-state" ] [ text (T.noContent active.texts) ]

                                else
                                    div [ A.class "stack" ] (List.map (emojiView config active model.busy) items)
                            )
                        ]

                else
                    p [ A.class "field-error", A.attribute "role" "alert" ] [ text (T.forbidden active.texts) ]

            _ ->
                loginRequired active.texts
        )


field : Active -> (Field -> String -> msg) -> String -> (T.I18n -> String) -> Field -> String -> Bool -> Html msg
field active changed identifier labelText kind value required =
    div []
        [ label [ A.for identifier ] [ text (labelText active.texts) ]
        , input [ A.id identifier, A.value value, A.required required, Events.onInput (changed kind) ] []
        ]


emojiView : { a | edit : Emoji -> msg, delete : Emoji -> msg } -> Active -> Bool -> Emoji -> Html msg
emojiView config active busy emoji =
    section [ A.class "card" ]
        [ img [ A.src emoji.imageUrl, A.alt emoji.altText, A.width 32, A.height 32 ] []
        , text (" :" ++ emoji.shortcode ++ ": · " ++ emoji.category)
        , div [ A.class "actions" ]
            [ button [ A.type_ "button", A.disabled busy, Events.onClick (config.edit emoji) ] [ text (T.editEmoji active.texts) ]
            , button [ A.id ("emoji-delete-" ++ String.fromInt emoji.id), A.type_ "button", A.disabled busy, Events.onClick (config.delete emoji) ] [ text (T.deleteEmoji active.texts) ]
            ]
        ]
