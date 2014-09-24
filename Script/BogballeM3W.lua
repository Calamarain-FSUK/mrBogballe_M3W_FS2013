--
-- BogballeM3W
-- Specialization for BogballeM3W
--
-- @author:  	Manuel Leithner
-- @date:		25/10/10
-- @version:	v2.0
-- @history:	v1.0 - initial implementation
--				v2.0 - Converted to LS2011
--

BogballeM3W = {};

function BogballeM3W.prerequisitesPresent(specializations)
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
end;

function BogballeM3W:keyEvent(unicode, sym, modifier, isDown)	
end;

function BogballeM3W:update(dt)
	if self:getIsActive() then
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
				self.attacherOptions.scale = joint.topArm.zScale;
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
			local literPercentage = self.settings.literPerHa.current / self.settings.literPerHa.default;
			local widthPercentage = self.currentAreaWidth / self.settings.maxAreaWidth;
			local speedPercentage = math.max(1, ((self.lastSpeed * 3600) / 15));
			self.sprayLitersPerSecond[self.currentFillType] = self.settings.literPerHa.multiplier * literPercentage * widthPercentage * speedPercentage;
			
			for k,spinner in pairs(self.spinners) do
				rotate(spinner.node, 0, (-0.016 * spinner.direction)*dt, 0);
			end;
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
	local increasew = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Increase_SprayWidth);
	local decreasew = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Decrease_SprayWidth);
	g_currentMission:addExtraPrintText(string.format(g_i18n:getText("bogballe_workingWidth"), self.currentAreaWidth, decreasew, increasew));
	
	local increaseu = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Increase_Usage);
	local decreaseu = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Decrease_Usage);
	g_currentMission:addExtraPrintText(string.format(g_i18n:getText("bogballe_literPerHa"), self.settings.literPerHa.current, decreaseu, increaseu));
	
	local increasec = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Increase_Capacity);
	local decreasec = InputBinding.getKeyNamesOfDigitalAction(InputBinding.bogballe_Decrease_Capacity);
	g_currentMission:addExtraPrintText(string.format(g_i18n:getText("bogballe_capacity"), decreasec, increasec));	
end;

function BogballeM3W:onAttach()
	setVisibility(self.attacherOptions.pallet, false);
	local x,y,z = getTranslation(self.attacherOptions.frame);
	setTranslation(self.attacherOptions.frame, x, self.attacherOptions.downY, z);
	setTranslation(self.attacherJoint.node, x, self.attacherOptions.downY, z);
	self.attachingFinished = true;
end;

function BogballeM3W:onDetach()
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
	local step = self.settings.literPerHa.amt;
	local direction = 1;
	if not increaseLiter then
		direction = -1;
	end;
	
	local oldLiterPerHa = self.settings.literPerHa.current;
	self.settings.literPerHa.current = Utils.clamp(self.settings.literPerHa.current + (direction * step), self.settings.literPerHa.min, self.settings.literPerHa.max);
	if oldLiterPerHa ~= self.settings.literPerHa.current then
		BogballeChangeLiterPerHaEvent.sendEvent(self, increaseLiter, noEventSend);
	end;	
end;

function BogballeM3W:changeCapacity(increaseCapacity, noEventSend) -- boolean
	
	local direction = 1;
	local oldStep = self.currentStep;	
	if not increaseCapacity then
		direction = -1;
	end;
	self.currentStep = self.currentStep + (1*direction);
	if self.currentStep > table.getn(self.steps) then
		self.currentStep = table.getn(self.steps);
	end;	
	if self.currentStep < 0 then
		self.currentStep = 0;
	end;	
	if self.currentStep < oldStep then
		local newCapacity = self.capacity - self.steps[oldStep].addCapacity;
		if self.fillLevel > newCapacity then
			self.currentStep = oldStep;
		end;
	end;

	if oldStep ~= self.currentStep then
		-- only send event if something has been changed
		BogballeChangeCapacityEvent.sendEvent(self, increaseCapacity, noEventSend);
		if increaseCapacity then
			self.capacity = self.capacity + self.steps[self.currentStep].addCapacity;
			setVisibility(self.steps[self.currentStep].index, true);
		else
			self.capacity = self.capacity - self.steps[oldStep].addCapacity;
			setVisibility(self.steps[oldStep].index, false);
		end;
		
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
	end;
	
	self:setFillLevel(self.fillLevel, self.currentFillType);
end;

function BogballeM3W:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)	
	if not resetVehicles then
		local currentStep = Utils.getNoNil(getXMLInt(xmlFile, key.."#currentStep"), self.currentStep);
		local areaWidth = Utils.getNoNil(getXMLInt(xmlFile, key.."#sprayWidth"), self.currentAreaWidth);		 
		self.settings.literPerHa.current = Utils.getNoNil(getXMLFloat(xmlFile, key.."#literPerHa"), self.settings.literPerHa.current);
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
    return BaseMission.VEHICLE_LOAD_OK;
end;

function BogballeM3W:getSaveAttributesAndNodes(nodeIdent)
	local attributes = 'currentStep="'..tostring(self.currentStep)..'" sprayWidth="' .. tostring(self.currentAreaWidth) .. '" literPerHa="' .. tostring(self.settings.literPerHa.current) ..'"';
	return attributes, nil;
end;