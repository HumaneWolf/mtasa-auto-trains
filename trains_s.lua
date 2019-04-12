--- K/V
local baseSpeed = 0.9 -- Normal cruise speed, 1 = 160 kph ish

local breakingDistance = 120 -- How early should it start breaking?
local stationArea = 3 -- Station leeway, since coords are not exact.

local vehicleId = 570 -- Brown Streak Carriage

local tickSpeed = 250 -- Tick every 250 ms
local stationWaitingTime = (1000 / tickSpeed) * 10 -- 20 sec


--- Stations
-- Station order:   Unity,  Linden, Yellow, SF,     Market
local stationsX = { 1733,   2865,   1432,   -1944,  819 }
local stationsY = { -1953,  1292,   2633,   136,    -1369 }
local stationsZ = { 14,     12,     12,     26,     -1 }


--- Trains and train data.
local trains = {}
local trainNextStation = {}
local trainStopped = {}


--- Adding trains
function addTrain(posX, posY, posZ, nextStation)
    local train = createVehicle(vehicleId, posX, posY, posZ)
    setVehicleColor(train, 255, 0, 0,  255, 0, 0)
    setTrainDerailable(train, false)
    setVehicleDamageProof(train, true)
    setVehicleOverrideLights(train, 2)

    table.insert(trains, train)
    table.insert(trainNextStation, nextStation)
    table.insert(trainStopped, -1)
end


--- Utils
function getDistance(ax, ay, az, bx, by, bz)
    return math.abs(math.pow( math.pow((bx - ax), 2) + math.pow((by - ay), 2) + math.pow((bz - az), 2) , 0.5))
end


function getNextStation(stationIndex)
    local count = #stationsX

    if stationIndex == count then
        return 1
    else
        return stationIndex + 1
    end
end


--- Train ticks
function updateSpeed(trainIndex)
    local train = trains[trainIndex]
    local nextStat = trainNextStation[trainIndex]
    x, y, z = getElementPosition(train)
    local dist = getDistance(x, y, z, stationsX[nextStat], stationsY[nextStat], stationsZ[nextStat])

    if dist < stationArea then
        setTrainSpeed(train, 0)
        trainStopped[trainIndex] = 0

    elseif dist < (breakingDistance + stationArea) then
        local speed = (baseSpeed * (dist / (breakingDistance + stationArea))) * -1
        setTrainSpeed(train, speed)

    else
        local speed = getTrainSpeed(train)
        if speed < baseSpeed then
            setTrainSpeed(train, (speed + 0.035) * -1)
        end
    end
end


function updateAtStation(trainIndex)
    trainStopped[trainIndex] = trainStopped[trainIndex] + 1

    if trainStopped[trainIndex] > stationWaitingTime then
        trainNextStation[trainIndex] = getNextStation(trainNextStation[trainIndex])
        trainStopped[trainIndex] = -1
    end
end


function runTick()
    for i,t in ipairs(trains) do
        if trainStopped[i] == -1 then
            updateSpeed(i)
        else
            updateAtStation(i)
        end
    end
end


--- Init
function onResourceStart(resource)
    if resource == getThisResource() then
        -- Spawn trains
        addTrain(1710, -1930, 14, 1)

        -- Start ticks
        setTimer(runTick, tickSpeed, 0)
    end
end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), onResourceStart)
