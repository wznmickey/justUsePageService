module GameData exposing (..)

import Area exposing (..)
import CPdata exposing (..)
import CRdata exposing (..)
import Dict exposing (Dict)
import HelpText exposing (..)
import Json.Decode exposing (..)
import PureCPdata exposing (..)


type alias GameData =
    { infoCP : Dict String CPdata
    , globalCP : Dict String PureCPdata
    , allCR : Dict String CRdata
    , area : Dict String Area
    , helpText : Dict String HelpText
    }


initGameData : GameData
initGameData =
    let
        newInfoCP =
            initCPdata

        newGlobalCP =
            initPureCPdata

        newAllCR =
            initCRdata

        newArea =
            initArea

        newHelpText =
            initHelpText
    in
    { infoCP = Dict.singleton newInfoCP.name newInfoCP
    , globalCP = Dict.singleton newGlobalCP.name newGlobalCP
    , allCR = Dict.singleton newAllCR.name newAllCR
    , area = Dict.singleton newArea.name newArea
    , helpText = Dict.singleton newHelpText.name newHelpText
    }


dGameData : Decoder GameData
dGameData =
    map5 GameData
        (field
            "CP"
            dCPdata
        )
        (field
            "globalCP"
            decoder_PureCPdata
        )
        (field
            "CR"
            dCRdata
        )
        (field
            "area"
            dArea
        )
        (field
            "helpText"
            dHelpText
        )


getCPdataByName : ( String, Dict String CPdata ) -> CPdata
getCPdataByName ( name, dict ) =
    Maybe.withDefault initCPdata (Dict.get name dict)



{--This part of code can not be compiled. The name and the coding seems not fit. Reserve it for further developing.
changeCP2CR : Int -> Int
changeCP2CR =
    { 
    if CPdata < 10 then
        CPdata = CRdata+1
        CRdata = CRdata-1
    else if CPdata >= 10 then
        CPdata = CRdata+2
        CRdata = CRdata-2
    }
--}
