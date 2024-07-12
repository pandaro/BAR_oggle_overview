
--this widget allows you to bind a hotkey to a predefined zoom level, without losing other camera data.
--It is designed for those who use to rotate the camera to keep the view in front but are disoriented by overhead camera.

--you need to add this in your uikey.txt: "bind your_avesome_key	zoom_level_custom 100%"
--now try to go in game and with spring camera you can have a toggleoverview,
--the default behaviour will focus where your mouse is when you back out of overview

function widget:GetInfo()
    return {
        name = "Custom Zoom",
        desc = "Adds a bindable command for custom zoom, so you can zoom to a certain percentage",
        author = "Pandaro",
        version = 0,
        date = "july 2024",
        license = "GNU GPL, v2 or later"
    }
end

local springMaxZoom = nil
local overheadMaxZoom = nil
local oldCameraState = nil
local spTraceScreenRay = Spring.TraceScreenRay
local spGetMouseState = Spring.GetMouseState
local spGetCameraState = Spring.GetCameraState
local spSetCameraState = Spring.SetCameraState
local spGetConfigInt = Spring.GetConfigInt

local function screenToMapPos()
    local mx,my= spGetMouseState() 
    local _, pos = spTraceScreenRay(mx, my, true, false, false, false)
    if not pos then
        return
    end
    return pos
end

local function cameraHandler(orientation,percentage,zoom,transition)
    
    local camstate = spGetCameraState()
    local current_rx
    local pos = screenToMapPos()
    if pos then
        --Spring.Echo(pos[1],pos[3])
        camstate.px = Game.mapSizeX/2
        camstate.pz = Game.mapSizeZ/2
        camstate.rx = 3.1101768
    end                

    
    if not oldCameraState  then
        --Spring.Echo('oldCameraState',oldCameraState)
        oldCameraState = spGetCameraState()
        if not percentage and not orientation then
            camstate.dist = zoom
            --Spring.Echo('set zoom at',zoom)
        elseif not percentage and orientation then
            camstate.dist = camstate.dist + (orientation * zoom )
            --Spring.Echo('add or remove zoom heght',zoom)
        elseif percentage and not orientation then
            camstate.dist = springMaxZoom / 100 * zoom
            --Spring.Echo('set zoom at percentage',zoom)
        elseif percentage and orientation then
            camstate.dist = camstate.dist + (orientation * (springMaxZoom / 100 * zoom))
            --Spring.Echo('add zoom percentage',zoom)
        end
        local cameraSet = spSetCameraState(camstate, transitionTime)
        if cameraSet then
            --Spring.Echo('camera go on overview')
            
            return cameraSet
        else
            return
        end
    end
    --if oldCameraState.rx == 3.1101768 then --here we are in overview so we have to back down
    local pos = screenToMapPos()
    
    if pos then
        oldCameraState.px = pos[1]
        oldCameraState.pz = pos[3]
    end 
    
    local cameraSet = spSetCameraState(oldCameraState, transitionTime)
    if not cameraSet then Spring.Echo('throw an error in zoom_level_custom') return end
    oldCameraState = nil
    --Spring.Echo('update camera state')
    
            
--         return 
    --end
    return cameraSet

end

local function zoomHandler(_, _, args, _, isRepeat)
    -- Do we want to keep triggering zoom if the key is held?
    if isRepeat then return end

    if not args then
        --Spring.Echo("<Camera Zoom> No arguments passed to zoom action, nothing to do")
        return
    end

    local firstChar = string.sub(args, 1, 1)
    local lastChar = string.sub(args, -1, -1)
    --Spring.Echo('firstChar',firstChar,'lastChar',lastChar)
    -- Do we zoom in or out
    local zoomOrientation = firstChar == '-' and -1 or 1
    if firstChar ~= '-' and firstChar ~= '+' then
        zoomOrientation = nil
    end
    --Spring.Echo('zoomOrientation',zoomOrientation)
    -- Eat the orientation char if passed
    local percentage = false
    if lastChar == '%'  then
      percentage = true
      args = string.sub(args,1,-2)
      
    end
    if firstChar == '-' or firstChar == '+' then
      args = string.sub(args,2,-1)
    end
    
    zoom = tonumber(args)


    --- If we actually did what we wanted, return true so other actions do not trigger
    return zoomOrientation,percentage,zoom
end

function widget:Initialize()
    local minZoom = spGetConfigInt("MinimumCameraHeight",300)
    springMaxZoom = math.max(Game.mapSizeX/8,Game.mapSizeZ/8) * Game.squareSize * 1.333
    overheadMaxZoom = 9.5 * math.max(Game.mapSizeX/8,Game.mapSizeZ/8) * Spring.GetConfigFloat('OverheadMaxHeightFactor')
    
    --Spring.Echo('springMaxZoom ',springMaxZoom ,'overheadMaxZoom',overheadMaxZoom)
    widgetHandler:AddAction(
        "zoom_level_custom", 
        function(_, args)
            if args ~= "" then
                
                --Spring.Echo('Custom Zoom',args)
                local zoomOrientation,percentage,zoom = zoomHandler(_,_,args,_,isRepeat)
                local success = cameraHandler(zoomOrientation,percentage,zoom)
                return success
            end
        end,
        nil,
        "tp"
    )
end

function widget:Shutdown()
    widgetHandler:RemoveAction("zoom_level_custom", "tp")
end


