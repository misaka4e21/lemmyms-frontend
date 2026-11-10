module App.Session exposing (AuthState(..))

import Lemmy.Domain as Domain


type AuthState
    = CheckingSession
    | Anonymous
    | Authenticated Domain.MyUserInfo
