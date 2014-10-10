--
-- BogballeM3W
-- Specialization for BogballeM3W
--
-- @author:     Manuel Leithner
-- @updater:    Jonathan McComb (Calamarain)
-- @date:       25/10/10
-- @modified:   26/09/14
-- @version:    v2.1
-- @history:    v1.0 - initial implementation
--              v2.0 - Converted to LS2011
--              v2.1 - Updated for FS2013 & Fixed capacity setting issue with MoreRealistic Engine
--              v2.x - Refactored
--

BogballeM3W = {};

function BogballeM3W.prerequisitesPresent(specializations)
    --Check that we have the 'Fillable' specialization, otherwise
    --we can't contain any fertiliser to spread.
    return SpecializationUtil.hasSpecialization(Fillable, specializations);
end;

function BogballeM3W:load(xmlFile)

    self.attacherOptions = {};
    self.attacherOptions.pallet = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.attacherJoint#pallet"));
    self.attacherOptions.frame = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.attacherJoint#frame"));
    self.attacherOptions.upY = getXMLFloat(xmlFile, "vehicle.attacherJoint#upY");
    self.attacherOptions.downY = getXMLFloat(xmlFile, "vehicle.attacherJoint#downY");
    self.attacherOptions.scale = 1;
    
    local settings = {};
    settings.literPerHa = {};
    settings.literPerHa.price = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.settings.literPerHa#price"), 1);
    settings.literPerHa.min = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.settings.literPerHa#min"), 100);
    settings.literPerHa.max = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.settings.literPerHa#max"), 600);
    settings.literPerHa.multiplier = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.settings.literPerHa#multiplier"), 6);
    settings.literPerHa.default = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.settings.literPerHa#current"), 350);
    settings.literPerHa.amt = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.settings.literPerHa#amt"), 10);
    settings.literPerHa.current = settings.literPerHa.default;
    settings.minAreaWidth = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.settings.area#minAreaWidth"), 12);
    settings.maxAreaWidth = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.settings.area#maxAreaWidth"), 42);
    settings.step = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.settings.area#step"), 3);
    self.currentAreaWidth = settings.maxAreaWidth;
    self.settings = settings;
    
    self.spinners = {};
    local count = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.spinners#count"), 0);
    for i=1, count do
        local spinner = {};
        local name = string.format("vehicle.spinners.spinner" .. "%d", i);
        spinner.node = Utils.indexToObject(self.components, getXMLString(xmlFile, name .. "#index"));
        spinner.direction = Utils.getNoNil(getXMLInt(xmlFile, name .. "#direction"), 1);
        table.insert(self.spinners, spinner);
    end;

    local fillType = Fillable.fillTypeIntToName[Fillable.FILLTYPE_FERTILIZER];
    local curve = self.fillPlanes[fillType].nodes[1].animCurve;
    self.originalMaxY = curve.keyframes[table.getn(curve.keyframes)].y;
    self.steps = {};
    local stepsCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.settings.steps#count"), 0);
    for i=1, stepsCount do
        local step = {};
        local name = string.format("vehicle.settings.steps.step" .. "%d", i);
        step.index = Utils.indexToObject(self.components, getXMLString(xmlFile, name .. "#index"));
        step.y = Utils.getNoNil(getXMLFloat(xmlFile, name .. "#y"), 0);
        step.maxCapacity = Utils.getNoNil(getXMLFloat(xmlFile, name .. "#maxCapacity"), 0);
        table.insert(self.steps, step);
    end;
    self.currentStep = 3;
    self.baseCapacity = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.baseCapacity#value"), 1600);
    local numCuttingAreasBow = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreasBow#count"), 0);
    self.cuttingAreasBow = {};
    for i=1, numCuttingAreasBow do
        self.cuttingAreasBow[i] = {};
        local areanamei = string.format("vehicle.cuttingAreasBow.cuttingArea%d", i);
        self.cuttingAreasBow[i].start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"));
        self.cuttingAreasBow[i].width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"));
        self.cuttingAreasBow[i].height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"));
        self.cuttingAreasBow[i].minStartX = getXMLFloat(xmlFile, areanamei .. "#minStartX");    
        self.cuttingAreasBow[i].minHeightX = getXMLFloat(xmlFile, areanamei .. "#minHeightX");
        self.cuttingAreasBow[i].minHeightZ = getXMLFloat(xmlFile, areanamei .. "#minHeightZ");
        local x,y,z = getTranslation(self.cuttingAreasBow[i].start);
        self.cuttingAreasBow[i].maxStartX = x;
        x,y,z = getTranslation(self.cuttingAreasBow[i].height);
        self.cuttingAreasBow[i].maxHeightX = x;
        self.cuttingAreasBow[i].maxHeightZ = z;
    end;    
end;

function BogballeM3W:delete()
end;

function BogballeM3W:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.currentStep);
    streamWriteInt8(streamId, self.currentAreaWidth);
    streamWriteInt16(streamId, self.settings.literPerHa.current);   
end;

function BogballeM3W:readStream(streamId, connection)
    local currentStep   = streamReadInt8(streamId);
    local areaWidth     = streamReadInt8(streamId);  
    local literPerHa    = streamReadInt16(streamId);
    --
    BogballeM3W.setLiterPerHa(self, literPerHa,  true);
    BogballeM3W.setCapacity(  self, currentStep, true);
    BogballeM3W.setSprayWidth(self, areaWidth,   true);
end;

function BogballeM3W:mouseEvent(posX, posY, isDown, isUp, button)
--unused function
end;

function BogballeM3W:keyEvent(unicode, sym, modifier, isDown)   
--unused function
end;

function BogballeM3W:update(dt)
    --Check if we are the active vehicle
    if self:getIsActive() then
        --if we are active, we can respond to keypress events
        if self:getIsActiveForInput() then
            if InputBinding.hasEvent(InputBinding.bogballe_Increase_SprayWidth) then
                BogballeM3W.setSprayWidth(self, self.currentAreaWidth + self.settings.step);
            elseif InputBinding.hasEvent(InputBinding.bogballe_Decrease_SprayWidth) then
                BogballeM3W.setSprayWidth(self, self.currentAreaWidth - self.settings.step);
            elseif InputBinding.hasEvent(InputBinding.bogballe_Increase_Capacity) then
                BogballeM3W.setCapacity(  self, self.currentStep + 1);
            elseif InputBinding.hasEvent(InputBinding.bogballe_Decrease_Capacity) then
                BogballeM3W.setCapacity(  self, self.currentStep - 1);
            elseif InputBinding.hasEvent(InputBinding.bogballe_Increase_Usage) then
                BogballeM3W.setLiterPerHa(self, self.settings.literPerHa.current + self.settings.literPerHa.amt);
            elseif InputBinding.hasEvent(InputBinding.bogballe_Decrease_Usage) then
                BogballeM3W.setLiterPerHa(self, self.settings.literPerHa.current - self.settings.literPerHa.amt);
            end;
        end;

        if self.attachingFinished then
            local implement = self.attacherVehicle:getImplementByObject(self);
            if implement ~= nil then
                local joint = self.attacherVehicle.attacherJoints[implement.jointDescIndex];
                
                --We only need to scale the top arm if it exists - prevents errors when
                --used with the Case Steiger, as its 3-point linkage is one unit that rises 
                --and all rotation/scaling happens further back in the Steiger vehicle
                if topArm ~= nil then
                    self.attacherOptions.scale = joint.topArm.zScale;
                end;
                setJointFrame(joint.jointIndex, 0, self.attacherJoint.node);
                self.attachingFinished = false;         
            end;        
        end;
        
        if self.attacherVehicle ~= nil then
            local lx,ly,lz = localDirectionToWorld(self.attacherVehicle.rootNode, 0, 0, -1*self.attacherOptions.scale);
            local x, y, z = worldDirectionToLocal(getParent(self.attacherOptions.frame), lx,ly,lz);
            setDirection(self.attacherOptions.frame, x, y, z, 0, 1, 0);     
        end;        
    end;
end;

function BogballeM3W:updateTick(dt)
    if self:getIsActive() then  
        if self.isTurnedOn then
            --Calculate our spread rate
            local literPercentage = self.settings.literPerHa.current / self.settings.literPerHa.default;
            local widthPercentage = self.currentAreaWidth / self.settings.maxAreaWidth;
            local speedPercentage = math.max(1, ((self.lastSpeed * 3600) / 15));
            self.sprayLitersPerSecond[self.currentFillType] = self.settings.literPerHa.multiplier * literPercentage * widthPercentage * speedPercentage;
            
            --Make the spinners rotate
            for k,spinner in pairs(self.spinners) do
                rotate(spinner.node, 0, (-0.016 * spinner.direction)*dt, 0);
            end;
            
            --If we aren't going too fast update the spread area
            if self.speedViolationTimer > 0 then
                -- create the stylish spreader bow with best performance
                for k,cuttingArea in pairs(self.cuttingAreasBow) do
                    if self:getIsAreaActive(cuttingArea) then
                        local x,y,z = getWorldTranslation(cuttingArea.start);
                        local x1,y1,z1 = getWorldTranslation(cuttingArea.width);
                        local x2,y2,z2 = getWorldTranslation(cuttingArea.height);
                        Utils.updateSprayArea(x, z, x1, z1, x2, z2);
                    end;
                end;
            end;
        end;
    end;    
end;

function BogballeM3W:draw()
    --Create temporary variables to store the keybindings
    local increasew = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Increase_SprayWidth);
    local decreasew = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Decrease_SprayWidth);
    local increaseu = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Increase_Usage);
    local decreaseu = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Decrease_Usage);
    local increasec = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Increase_Capacity);
    local decreasec = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Decrease_Capacity);
    
    --Show our keybindings and descriptions in the HelpBox
    g_currentMission:addExtraPrintText(string.format(g_i18n:getText("bogballe_workingWidth"), self.currentAreaWidth, decreasew, increasew));
    g_currentMission:addExtraPrintText(string.format(g_i18n:getText("bogballe_literPerHa"), self.settings.literPerHa.current, decreaseu, increaseu));
    g_currentMission:addExtraPrintText(string.format(g_i18n:getText("bogballe_capacity"), decreasec, increasec));   
end;

function BogballeM3W:onAttach()
    -- When we get attached to a vehicle, hide the storage pallet that we were sitting on.
    setVisibility(self.attacherOptions.pallet, false);
    local x,y,z = getTranslation(self.attacherOptions.frame);
    setTranslation(self.attacherOptions.frame, x, self.attacherOptions.downY, z);
    setTranslation(self.attacherJoint.node, x, self.attacherOptions.downY, z);
    self.attachingFinished = true;
end;

function BogballeM3W:onDetach()
    -- When we get detached, make the pallet visible again so that have something to sit on
    setVisibility(self.attacherOptions.pallet, true);
    local x,y,z = getTranslation(self.attacherOptions.frame);
    setTranslation(self.attacherOptions.frame, x, self.attacherOptions.upY, z);
    setTranslation(self.attacherJoint.node, x, self.attacherOptions.upY, z);
    setRotation(self.attacherOptions.frame,0,0,0);
end;

function BogballeM3W:setSprayWidth(newSprayWidth, noEventSend)
    newSprayWidth = Utils.clamp(newSprayWidth, self.settings.minAreaWidth, self.settings.maxAreaWidth)
    
    if self.currentAreaWidth ~= newSprayWidth then
        BogballeUpdateAttrsEvent.sendEvent(self, self.currentStep, newSprayWidth, self.settings.literPerHa.current, noEventSend)
        --
        self.currentAreaWidth = newSprayWidth
        local percentage = (self.currentAreaWidth - self.settings.minAreaWidth) / (self.settings.maxAreaWidth - self.settings.minAreaWidth);
        for k,cuttingArea in pairs(self.cuttingAreasBow) do 
            local minStartX = cuttingArea.minStartX;
            if minStartX == nil then
                minStartX = self.cuttingAreasBow[k-1].minHeightX;
            end;
        
            local x,y,z;
            local currentHeightX
            if cuttingArea.minStartX ~= nil then
                x,y,z = getTranslation(cuttingArea.start);
                currentHeightX = (cuttingArea.maxStartX - cuttingArea.minStartX) * percentage + cuttingArea.minStartX;
                setTranslation(cuttingArea.start,  currentHeightX, y, z);
            end;
        
            local area = cuttingArea.start;
            if cuttingArea.minStartX == nil then
                area = self.cuttingAreasBow[k-1].start;
            end;            
            x,y,z = getTranslation(area);
            setTranslation(cuttingArea.width,  0, 0, z);

            local currentHeightX = (cuttingArea.maxHeightX - cuttingArea.minHeightX) * percentage + cuttingArea.minHeightX;
            local currentHeightZ = (cuttingArea.maxHeightZ - cuttingArea.minHeightZ) * percentage + cuttingArea.minHeightZ;
            setTranslation(cuttingArea.height,  currentHeightX, 0, currentHeightZ);
        end;
        
        local cuttingArea = self.cuttingAreas[1];
        setTranslation(cuttingArea.start,   self.currentAreaWidth/2, 0, 0);
        setTranslation(cuttingArea.width,  -self.currentAreaWidth/2, 0, 0);
        setTranslation(cuttingArea.height,  self.currentAreaWidth/2, 0, -1);        
    end;
end;

function BogballeM3W:setLiterPerHa(newLiterPerHa, noEventSend)
    newLiterPerHa = Utils.clamp(newLiterPerHa, self.settings.literPerHa.min, self.settings.literPerHa.max);
    
    if self.settings.literPerHa.current ~= newLiterPerHa then
        BogballeUpdateAttrsEvent.sendEvent(self, self.currentStep, self.currentAreaWidth, newLiterPerHa, noEventSend)
        --
        self.settings.literPerHa.current = newLiterPerHa
    end
end

function BogballeM3W:setCapacity(newCapacityStep, noEventSend)
    newCapacityStep = Utils.clamp(newCapacityStep, 1, table.getn(self.steps))

    if self.currentStep ~= newCapacityStep then
        BogballeUpdateAttrsEvent.sendEvent(self, newCapacityStep, self.currentAreaWidth, self.settings.literPerHa.current, noEventSend)

        -- Only allow change, when there is still room to contain the current fillLevel.
        local currentFillLevel = Utils.getNoNil(self.fillLevel,0);
        if currentFillLevel <= self.steps[newCapacityStep].maxCapacity then
            self.currentStep = newCapacityStep

            -- Update 3D-model's visibility
            for i=1,table.getn(self.steps) do
                setVisibility(self.steps[i].index, i <= self.currentStep)
            end
            
            --
            self.capacity           = self.steps[self.currentStep].maxCapacity;
            self.realBaseCapacity   = self.steps[self.currentStep].maxCapacity;
            
            --change the fillplane animation to suit the new hopper shape
            local newYMax = self.originalMaxY;
            if self.currentStep < table.getn(self.steps) then
                newYMax = self.steps[self.currentStep+1].y;
            end;
                   
            local fillType = Fillable.fillTypeIntToName[Fillable.FILLTYPE_FERTILIZER];
            local minY = self.fillPlanes[fillType].nodes[1].animCurve.keyframes[1].y;
            for _, node in pairs(self.fillPlanes[fillType].nodes) do
                node.animCurve.keyframes[table.getn(node.animCurve.keyframes)].y = newYMax;
                for _,frame in pairs(node.animCurve.keyframes) do
                    frame.time = (frame.y - minY) / (newYMax - minY);
                end;    
            end;
        end
    end
end

function BogballeM3W:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)    
    if not resetVehicles then
        --retrieve our settings from the vehicle.xml entry
        local currentStep = Utils.getNoNil(getXMLInt(xmlFile, key.."#currentStep"), self.currentStep);
        local areaWidth   = Utils.getNoNil(getXMLInt(xmlFile, key.."#sprayWidth"), self.currentAreaWidth);         
        local literPerHa  = Utils.getNoNil(getXMLFloat(xmlFile, key.."#literPerHa"), self.settings.literPerHa.current);
        --
        BogballeM3W.setLiterPerHa(self, literPerHa,  true);
        BogballeM3W.setCapacity(self,   currentStep, true);
        BogballeM3W.setSprayWidth(self, areaWidth,   true);
    end; 
    return BaseMission.VEHICLE_LOAD_OK;
end;

function BogballeM3W:getSaveAttributesAndNodes(nodeIdent)
    --Save our current settings to the appropriate vehicle.xml entry
    local attributes = 'currentStep="'..tostring(self.currentStep)..'" sprayWidth="' .. tostring(self.currentAreaWidth) .. '" literPerHa="' .. tostring(self.settings.literPerHa.current) ..'"';
    return attributes, nil;
end;


----------
----------

BogballeUpdateAttrsEvent = {};
BogballeUpdateAttrsEvent_mt = Class(BogballeUpdateAttrsEvent, Event);

InitEventClass(BogballeUpdateAttrsEvent, "BogballeUpdateAttrsEvent");

function BogballeUpdateAttrsEvent:emptyNew()
    local self = Event:new(BogballeUpdateAttrsEvent_mt);
    self.className="BogballeUpdateAttrsEvent";
    return self;
end;

function BogballeUpdateAttrsEvent:new(vehicle, newCapacityStep, newSprayWidth, newLiterPerHa)
    local self = BogballeUpdateAttrsEvent:emptyNew()
    self.vehicle            = vehicle;
    self.newCapacityStep    = newCapacityStep;
    self.newSprayWidth      = newSprayWidth;
    self.newLiterPerHa      = newLiterPerHa;
    return self;
end;

function BogballeUpdateAttrsEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));   
    streamWriteInt8(streamId,  self.newCapacityStep);
    streamWriteInt8(streamId,  self.newSprayWidth);
    streamWriteInt16(streamId, self.newLiterPerHa);
end;

function BogballeUpdateAttrsEvent:readStream(streamId, connection)
    self.vehicle            = networkGetObject(streamReadInt32(streamId));
    self.newCapacityStep    = streamReadInt8(streamId);
    self.newSprayWidth      = streamReadInt8(streamId);
    self.newLiterPerHa      = streamReadInt16(streamId);
    --
    self:run(connection);
end;

function BogballeUpdateAttrsEvent:run(connection)
    if self.vehicle ~= nil then
        BogballeM3W.setCapacity(  self.vehicle, self.newCapacityStep, true);
        BogballeM3W.setSprayWidth(self.vehicle, self.newSprayWidth,   true);
        BogballeM3W.setLiterPerHa(self.vehicle, self.newLiterPerHa,   true);
        --
        if not connection:getIsServer() then
            g_server:broadcastEvent(BogballeUpdateAttrsEvent:new(self.vehicle, self.newCapacityStep, self.newSprayWidth, self.newLiterPerHa), nil, connection, self.vehicle);
        end;
    end
end;

function BogballeUpdateAttrsEvent.sendEvent(vehicle, newCapacityStep, newSprayWidth, newLiterPerHa, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BogballeUpdateAttrsEvent:new(vehicle, newCapacityStep, newSprayWidth, newLiterPerHa), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(BogballeUpdateAttrsEvent:new(vehicle, newCapacityStep, newSprayWidth, newLiterPerHa));
        end;
    end;
end;
