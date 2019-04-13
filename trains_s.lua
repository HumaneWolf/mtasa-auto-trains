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


--- Adding stuff
function addTrain(posX, posY, posZ, nextStation)
    local train = createVehicle(vehicleId, posX, posY, posZ, 0, 0, 0)
    setVehicleColor(train, 255, 0, 0,  255, 0, 0)
    setTrainDerailable(train, false)
    setVehicleDamageProof(train, true)
    setVehicleOverrideLights(train, 2)

    table.insert(trains, train)
    table.insert(trainNextStation, nextStation)
    table.insert(trainStopped, -1)

    return train, index
end


function addSingleUseTrain(posX, posY, posZ, nextStation)
    local train, index = addTrain(posX, posY, posZ, nextStation)
    
    function trainLeft(player)
        destroyElement(train)
        table.remove(trains, index)
        table.remove(trainNextStation, index)
        table.remove(trainStopped, index)
    end
    addEventHandler('onVehicleExit', train, trainLeft)

    return train
end


function addStartPoint(x, y, z, tx, ty, tz, station)
    local marker = createMarker(x, y, z, 'cylinder', 1, 255, 255, 255, 150)
    local nextStat = getNextStation(station)

    createBlipAttachedTo(marker, 41, 2,  0, 0, 0, 255,  0, 1500)

    -- Add a handler to create a train and teleport the player.
    function startPointHit(element, dimensionMatch)
        if dimensionMatch and getElementType(element) == 'player' then
            local train = addSingleUseTrain(tx, ty, tz, nextStat)
            warpPedIntoVehicle(element, train)
        end
    end
    addEventHandler('onMarkerHit', marker, startPointHit)
end


--- Utils
function getDistance(ax, ay, az, bx, by, bz)
    return math.abs(getDistanceBetweenPoints3D(ax, ay, az, bx, by, bz))
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
        setElementFrozen(train, true)

    elseif dist < (breakingDistance + stationArea) then
        local speed = (baseSpeed * (dist / (breakingDistance + stationArea))) * -1
        setTrainSpeed(train, speed)

    else
        local speed = getTrainSpeed(train)
        if speed < baseSpeed then
            setTrainSpeed(train, (speed + 0.035) * -1)
        else 
            setTrainSpeed(train, baseSpeed * -1)
        end
    end
end


function updateAtStation(trainIndex)
    trainStopped[trainIndex] = trainStopped[trainIndex] + 1

    if trainStopped[trainIndex] > stationWaitingTime then
        trainNextStation[trainIndex] = getNextStation(trainNextStation[trainIndex])
        trainStopped[trainIndex] = -1
        setElementFrozen(trains[trainIndex], false)
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
        -- Add start points
        addStartPoint(1757, -1944, 13, 1719, -1940, 14, 1) -- Unity
        addStartPoint(2857, 1314.5, 11, 2857, 1314.5, 11, 2) -- Linden
        addStartPoint(1437, 2621, 11, 1437, 2621, 11, 3) -- Yellow
        addStartPoint(-1972, 118, 27, -1936, 187, 27, 4) -- San Fierro
        addStartPoint(826.5, -1353.6, 13, 819, -1363, 0, 5) -- Market

        -- Start ticks
        setTimer(runTick, tickSpeed, 0)
    end
end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), onResourceStart)
