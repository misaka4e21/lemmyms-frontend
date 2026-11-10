module Feature.Editor.State exposing (..)

import Api
import Feature.Authoring.State as Authoring
import Lemmy.Domain as Domain
import Remote exposing (Remote(..))


type EditorMode
    = CreateTopic String
    | CreateReply String
    | EditPost String
    | EditComment String


type alias Source =
    { title : String
    , body : String
    , version : String
    }


type alias EditorAttachment =
    { id : String, name : String, reference : String }


type alias EditorState =
    { mode : EditorMode
    , title : String
    , authoring : Authoring.Model
    , format : String
    , version : Maybe String
    , attachments : List EditorAttachment
    , uploading : Bool
    , saving : Bool
    , problem : Maybe Api.Problem
    , conflict : Maybe Source
    }


emptyEditor : EditorMode -> EditorState
emptyEditor mode =
    { mode = mode
    , title = ""
    , authoring = Authoring.init "editor-body" ""
    , format = "markdown"
    , version = Nothing
    , attachments = []
    , uploading = False
    , saving = False
    , problem = Nothing
    , conflict = Nothing
    }


body : EditorState -> String
body editor =
    Authoring.value editor.authoring


sourceAttachments : Source -> List EditorAttachment
sourceAttachments _ =
    []


type alias Model =
    { editor : Maybe EditorState, source : Remote Source }


initial : Model
initial =
    { editor = Nothing, source = NotAsked }
