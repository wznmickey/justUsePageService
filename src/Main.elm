module Main exposing (main)

import Area exposing (..)
import Array exposing (..)
import Browser exposing (element)
import Browser.Events exposing (onAnimationFrameDelta, onClick, onKeyDown)
import CPdata exposing (..)
import CPtype exposing (CPtype(..))
import CRdata exposing (CRdata)
import Dict exposing (Dict)
import File exposing (File)
import File.Select as Select
import For exposing (..)
import GameData exposing (GameData, getPureCPdataByName, initGameData)
import HelpText exposing (initHelpText)
import Html exposing (..)
import Html.Attributes as HtmlAttr exposing (..)
import Html.Events as HtmlEvent exposing (..)
import Http
import LoadMod exposing (loadMod)
import Msg exposing (FileStatus(..), Msg(..), State(..))
import PureCPdata exposing (PureCPdata)
import String exposing (..)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Task
import View exposing (..)
import Update exposing (..)
import Json.Decode as Decode
import Html.Attributes

type alias Model =
    { data : GameData
    , state : State
    , modInfo : String
    , loadInfo : String
    , onviewArea : String
    , time : Float
    , onMovingCR : Maybe String
    }


wholeURL : String
wholeURL =
    "../asset/defaultMod.json"


initModel : Model
initModel =
    Model initGameData Start "modInfo" "Init" "init" 0 Nothing


init : () -> ( Model, Cmd Msg )
init result =
    ( initModel
    , Http.get
        { url = wholeURL
        , expect = Http.expectString GotText
        }
    )


view : Model -> Html Msg
view model =
    div
        [ HtmlAttr.style "width" "95vw"
        , HtmlAttr.style "height" "95vh"
        , HtmlAttr.style "left" "0"
        , HtmlAttr.style "top" "0"
        , HtmlAttr.style "text-align" "center"
        ]
        [ Svg.svg
            [ SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            (viewAreas (Dict.values model.data.area) ++ viewCRs (Dict.values model.data.allCR) )
        , viewGlobalData (Dict.values model.data.globalCP) model.data.infoCP
        , view_Areadata model.data.area model.onviewArea
        , disp_Onview model.onviewArea
        , show_PauseInfo
        , show_DeadInfo model
        , button [ HtmlEvent.onClick (Msg.UploadFile FileRequested) ] [ text "Load Mod" ]
        ]
    


-- viewThis : List ( Svg Msg )
-- viewThis =
--        [ Svg.text_  
--         [ SvgAttr.width "100px"
--         , SvgAttr.height "100px"
--         , SvgAttr.x "100px"
--         , SvgAttr.y "100px"
--         , SvgAttr.fill "red"
--         , SvgAttr.stroke "white"
--         , SvgAttr.title "hiiiiiiiiiiii"
--         ]
--         [ text "HIIIIIIIII" ]
--        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    if 
        model.state == End && msg /= Restart then 
        ( model, Cmd.none )
    else if 
    model.state == End && msg == Restart then 
    ( initModel, Cmd.none)
    else 
        if msg == ChangeState then
            ( { model | state = (change_Pause model) }, Cmd.none )
        else if model.state == Start then
            case msg of
            GotText result ->
              case result of
                Ok fullText ->
                 ( { model | modInfo = fullText, data = Tuple.first (loadMod fullText), loadInfo = Tuple.second (loadMod fullText) }, Cmd.none )
                _ ->
                 ( { model | modInfo = "error" }, Cmd.none )

            Clickon (Msg.Area name) ->
                     ( { model | onviewArea = name } |> changeCR name, Cmd.none )

            Clickon (Msg.CR name) ->
                    ( { model | onMovingCR = Just name }, Cmd.none )

            UploadFile fileStatus ->
                case fileStatus of
                FileRequested ->
                    ( model, Cmd.map UploadFile (Select.file [ "text/json" ] FileSelected) )

                FileSelected file ->
                    ( model, Cmd.map UploadFile (Task.perform FileLoaded (File.toString file)) )

                FileLoaded content ->
                    ( { model | modInfo = content, data = Tuple.first (loadMod content), loadInfo = Tuple.second (loadMod content) }, Cmd.none )

            Tick time ->
             let
                newmodel1 =
                    { model | time = model.time + time }

                newmodel2 =
                    { newmodel1 | data = updateData newmodel1.data }
                
                newmodel3=
                    { newmodel2 | state = check_Dead newmodel2 }
             in
                ( newmodel3, Cmd.none )
        
            _ ->
                (model, Cmd.none )
        else    (model, Cmd.none )
            

change_Pause: Model -> State
change_Pause model =
    if model.state == Pause then
        Start
    else if model.state == Start then
        Pause

    else 
        Start



check_Dead : Model -> State
check_Dead model =
 let
    keyVal = getPureCPdataByName ("Citizen trust", model.data.globalCP)
 in
        if keyVal.data <= 0 
            then 
             End 
        else 
            Start


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ onAnimationFrameDelta Tick 
        , onKeyDown (Decode.map keyPress keyCode)
        ]


keyPress : Int -> Msg
keyPress i =
    case i of
        32 ->
            ChangeState
        82 ->
            Restart
        _->
            None


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }





changeCR : String -> Model -> Model
changeCR newArea model =
    case model.onMovingCR of
        Just x ->
            let
                data =
                    model.data

                newData =
                    { data | allCR = moveCR model.data.allCR x newArea }
            in
            { model | data = newData,onMovingCR=Nothing }

        Nothing ->
            model


show_DeadInfo : Model -> Html Msg
show_DeadInfo model = 
     div
        [ style "color" "pink"
        , Html.Attributes.style "font-size" "large"
        , style "width" "20vw"
        ]
        [ if model.state == End then
            text ("Mission Failed! Retry the mission of a terminator! Press R to restart")

          else
            text ("Save the world! Terminator!")
        ]