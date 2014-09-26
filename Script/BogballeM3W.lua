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
--              v2.1 - Updated for FS2013 & Fixed capacity setting issue
--

BogballeM3W = {};

function BogballeM3W.prerequisitesPresent(specializations)
    --Check that we have the 'Fillable' specialization, otherwise
    --we can't contain any fertiliser to spread.
    return SpecializationUtil.hasSpecialization(Fillable, specializations);
end;

function BogballeM3W:load(xmlFile)

    self.changeSprayWidth = SpecializationUtil.callSpecializationsFunction("changeSprayWidth");
    self.changeCapacity = SpecializationUtil.callSpecializationsFunction("changeCapacity");
    self.changeLiterPerHa = SpecializationUtil.callSpecializationsFunction("changeLiterPerHa");

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
        step.addCapacity = Utils.getNoNil(getXMLFloat(xmlFile, name .. "#addCapacity"), 0);
        step.y = Utils.getNoNil(getXMLFloat(xmlFile, name .. "#y"), 0);
        table.insert(self.steps, step);
    end;
    self.currentStep = 3;

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

function BogballeM3W:readStream(streamId, connection)
    local currentStep = streamReadInt8(streamId);
    local areaWidth = streamReadInt8(streamId);  
    self.settings.literPerHa.current = streamReadInt16(streamId);
    self.settings.literPerHa.current = Utils.clamp(self.settings.literPerHa.current, self.settings.literPerHa.min, self.settings.literPerHa.max);
    
    local maxStep = self.currentStep;
    for i=currentStep, maxStep - 1 do
        self:changeCapacity(currentStep >= self.currentStep, true);
    end;
    local currentState = self.currentAreaWidth < areaWidth;
    while self.currentAreaWidth ~= areaWidth do 
        self:changeSprayWidth(self.currentAreaWidth < areaWidth, true);
        if self.currentAreaWidth >= self.settings.maxAreaWidth or self.currentAreaWidth <= self.settings.minAreaWidth or currentState ~= (self.currentAreaWidth < areaWidth) then
            break;
        end;
    end;
end;

function BogballeM3W:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.currentStep);
    streamWriteInt8(streamId, self.currentAreaWidth);
    streamWriteInt16(streamId, self.settings.literPerHa.current);   
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
                self:changeSprayWidth(true);
            end;
            if InputBinding.hasEvent(InputBinding.bogballe_Decrease_SprayWidth) then
                self:changeSprayWidth(false);
            end;
            if InputBinding.hasEvent(InputBinding.bogballe_Increase_Capacity) then
                self:changeCapacity(true);
            end;
            if InputBinding.hasEvent(InputBinding.bogballe_Decrease_Capacity) then
                self:changeCapacity(false);
            end;
            if InputBinding.hasEvent(InputBinding.bogballe_Increase_Usage) then
                self:changeLiterPerHa(true);
            end;
            if InputBinding.hasEvent(InputBinding.bogballe_Decrease_Usage) then
                self:changeLiterPerHa(false);
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

function BogballeM3W:changeSprayWidth(increaseWidth, noEventSend) -- boolean

    local stepWidth = self.settings.step;
    local changeDirection = 1;
    local oldWidth = self.currentAreaWidth;
    if not increaseWidth then
        changeDirection = -1;
    end;    
    self.currentAreaWidth = self.currentAreaWidth + (stepWidth * changeDirection);
    if self.currentAreaWidth >= self.settings.maxAreaWidth then
        self.currentAreaWidth = self.settings.maxAreaWidth;
    end;
    if self.currentAreaWidth <= self.settings.minAreaWidth then
        self.currentAreaWidth = self.settings.minAreaWidth;     
    end;
    
    if self.currentAreaWidth ~= oldWidth then
        BogballeChangeSprayWidthEvent.sendEvent(self, increaseWidth, noEventSend);
        
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

function BogballeM3W:changeLiterPerHa(increaseLiter, noEventSend) -- boolean
    --If boolean true is supplied to this function, increase the rate by one step
    --otherwise reduce it by one step.    
    local step = self.settings.literPerHa.amt;
    local direction = 1;
    if not increaseLiter then
        direction = -1;
    end;
    --save the current setting for comparison later
    local oldLiterPerHa = self.settings.literPerHa.current;
    --Calculate our new spread rate
    self.settings.literPerHa.current = Utils.clamp(self.settings.literPerHa.current + (direction * step), self.settings.literPerHa.min, self.settings.literPerHa.max);
    if oldLiterPerHa ~= self.settings.literPerHa.current then
        BogballeChangeLiterPerHaEvent.sendEvent(self, increaseLiter, noEventSend);
    end;    
end;

function BogballeM3W:changeCapacity(increaseCapacity, noEventSend) -- boolean
    --If boolean true is supplied to this function, increase the capacity by one step
    --otherwise reduce it by one step.  If we try to reduce by a step but still contain 
    --too much fertiliser, then do nothing.
    
    --################  DEBUG PRINTOUT ONLY  ############################
    --################  DEBUG PRINTOUT ONLY  ############################
    print("Current Step     = "..self.currentStep);
    print("Current Capacity = "..self.capacity);
    --###################################################################
    --###################################################################
    
    --Default to increasing capacity by one step
    local direction = 1;
    
    --Save the current step in case we need it later
    local oldStep = self.currentStep;
    
    --Check if we want to increase capacity, if not then set to -1 to decrease by one step
    if not increaseCapacity then
        direction = -1;
    end;
    print("direction = "..direction);
    --Change the current step value
    self.currentStep = self.currentStep + (1*direction);
    
    --If we try to increase past the maximum step value,
    --set the current step to the maximum step value
    if self.currentStep > table.getn(self.steps) then
        self.currentStep = table.getn(self.steps);
    end;    
    
    --If we try to increase past the minimum step value, (always zero),
    --set the current step to zero.
    if self.currentStep < 0 then
        self.currentStep = 0;
    end;
    
    --If the new step is less than we started with then
    --calculate the new capacity.
    if self.currentStep < oldStep then
        local newCapacity = self.capacity - self.steps[oldStep].addCapacity;
        print("starting capacity = "..self.capacity);
        print("newcapacity       = "..newCapacity);
        --If the new capacity is less than the current fill level we can't be reduced
        --so set the 'new' step value back to what we started with
        if self.fillLevel > newCapacity then
            self.currentStep = oldStep;
        end;
    
    --################  DEBUG PRINTOUT ONLY  ############################
    --################  DEBUG PRINTOUT ONLY  ############################
    else
        local newCapacity = self.capacity + self.steps[oldStep].addCapacity;
        print("starting capacity = "..self.capacity);
        print("newcapacity       = "..newCapacity);
    --###################################################################
    --###################################################################
    end;

    --If something has changed we need to update things
    if oldStep ~= self.currentStep then
    
        --Send the capacity change to other players
        BogballeChangeCapacityEvent.sendEvent(self, increaseCapacity, noEventSend);
        
        if increaseCapacity then
            --We are adding here so set the new capacity
            self.capacity = self.capacity + self.steps[self.currentStep].addCapacity;
            --and show the appropriate shape within the .i3D
            setVisibility(self.steps[self.currentStep].index, true);
            print("self.capacity = "..self.capacity);
        else
            --We are reducing so set the new capacity
            self.capacity = self.capacity - self.steps[oldStep].addCapacity;
            --and hide the old shape from the previous step
            setVisibility(self.steps[oldStep].index, false);
            print("self.capacity = "..self.capacity);
        end;
        
        --change the fillplane animation to suit the new capacity
        local newYMax = self.originalMaxY;
        if self.currentStep ~= 3 then
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
        print("self.capacity = "..self.capacity);
    end;
    print("finishing self.capacity = "..self.capacity);
    --The moreRealistic engine uses a different variable for the capacity...
    self.realBaseCapacity = self.capacity;
    self:setFillLevel(self.fillLevel, self.currentFillType);
end;

function BogballeM3W:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)    
    if not resetVehicles then
        --retrieve our settings from the vehicle.xml entry
        local currentStep = Utils.getNoNil(getXMLInt(xmlFile, key.."#currentStep"), self.currentStep);
        local areaWidth = Utils.getNoNil(getXMLInt(xmlFile, key.."#sprayWidth"), self.currentAreaWidth);         
        self.settings.literPerHa.current = Utils.getNoNil(getXMLFloat(xmlFile, key.."#literPerHa"), self.settings.literPerHa.current);
        self.settings.literPerHa.current = Utils.clamp(self.settings.literPerHa.current, self.settings.literPerHa.min, self.settings.literPerHa.max);
        
        --Check if we need to change the capacity from the default
        local maxStep = self.currentStep;
        for i=currentStep, maxStep - 1 do
            self:changeCapacity(currentStep >= self.currentStep, true);
        end;
        
        --Check if we need to change the spread width from the default
        local currentState = self.currentAreaWidth < areaWidth;
        while self.currentAreaWidth ~= areaWidth do 
            self:changeSprayWidth(self.currentAreaWidth < areaWidth, true);
            if self.currentAreaWidth >= self.settings.maxAreaWidth or self.currentAreaWidth <= self.settings.minAreaWidth or currentState ~= (self.currentAreaWidth < areaWidth) then
                break;
            end;
        end;
    end; 
    return BaseMission.VEHICLE_LOAD_OK;
end;

function BogballeM3W:getSaveAttributesAndNodes(nodeIdent)
    --Save our current settings to the appropriate vehicle.xml entry
    local attributes = 'currentStep="'..tostring(self.currentStep)..'" sprayWidth="' .. tostring(self.currentAreaWidth) .. '" literPerHa="' .. tostring(self.settings.literPerHa.current) ..'"';
    return attributes, nil;
end;