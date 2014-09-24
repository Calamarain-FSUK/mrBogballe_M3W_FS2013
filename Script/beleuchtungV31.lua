--
-- Beleuchtung v3.1
-- Specialization for additional lights
-- Spezialisierung für Zusatzbeleuchtung
-- @author  Sven777b
-- 
-- frei verwendbar - keine erlaubnis nötig  |  free for use - no permission needed.
-- Modifikationen erst nach Rücksprache!    |  modifications only with my permission.
--
-- Hinweis: das kopieren von Sourcecode ist strafbar nach UrhG §2.1

BEL3 = {};
function BEL3.prerequisitesPresent(specializations)
    return true;
end;

function BEL3:load(xmlFile)
	local error = "Error: Beleuchtung V3 - %s (%s)";
	self.setState = SpecializationUtil.callSpecializationsFunction("setState");
	self.deactivate = SpecializationUtil.callSpecializationsFunction("deactivate");
	self.activate = SpecializationUtil.callSpecializationsFunction("activate");
	
	self.B3 = {}; 
	local i = 0; local fin = false;
	while true do
		while true do
			local on = string.format("vehicle.lightsaddon.light(%d)",i);
			local lt = getXMLString(xmlFile, on .. "#type");
			if lt == nil then fin=true; break; end;
			local is = getXMLString(xmlFile, on .. "#index");
			if is == nil then
				print(string.format(error,"kein Index definiert",on));
				i=i+1;
				break;
			end;
			local index = Utils.indexToObject(self.components, is);
			if index == nil or index == 0 then
				print(string.format(error,"Index "..is.." nicht gefunden",on));
				i=i+1;
				break;
			end;
			
			local tl = {};
			tl.na = getXMLString(xmlFile, on .. "#inputName");
			tl.index = index;
			tl.so = Utils.getNoNil(getXMLBool(xmlFile, on .. "#stayOn"),false);
			tl.a = false;
			tl.ht = getXMLString(xmlFile, on .. "#helptext");
			local rl = getXMLString(xmlFile,on.."#real");
			if rl ~= nil then
				tl.rl = Utils.indexToObject(self.components, rl);
			end;
			local fl = getXMLString(xmlFile,on.."#beam");
			if fl ~= nil then
				tl.fl = Utils.indexToObject(self.components, fl);
			end;
			
			if lt == "strobe" then
				local sq = getXMLString(xmlFile, on.."#sequence");
				tl.ls = false;
				tl.ns = 0;
				tl.t = 1;
				if sq ~= nil then
					tl.rnd = false;
					tl.sq = {Utils.getVectorFromString(sq)};
					tl.inv = Utils.getNoNil(getXMLBool(xmlFile, on.."#invert"),false);
					tl.ls = tl.inv;
					tl.ss = 1;
				else
					tl.rnd = true;
					tl.rndnn = Utils.getNoNil(getXMLInt(xmlFile, on.."#minOn"),100);
					tl.rndxn = Utils.getNoNil(getXMLInt(xmlFile, on.."#maxOn"),100);
					tl.rndnf = Utils.getNoNil(getXMLInt(xmlFile, on.."#minOff"),100);
					tl.rndxf = Utils.getNoNil(getXMLInt(xmlFile, on.."#maxOff"),400);
					math.randomseed( os.time() ); math.random();
				end;
			end;
			if self.B3[lt] == nil then
				self.B3[lt] = {};
			end;
			table.insert(self.B3[lt],tl);
			setVisibility(tl.index, false);
			if tl.fl ~= nil then
				setVisibility(tl.fl, false);
			end;
			if tl.rl ~= nil then
				setVisibility(tl.rl, false);
			end;
			i=i+1;
		end;
		if fin then break; end;
	end;
	
	local flwp = getXMLFloat(xmlFile, "vehicle.lightsaddon.fillLevelWarning#percent");
	if flwp ~= nil and self.grainTankCapacity ~= nil then
		self.B3.flw = {};
		self.B3.flw.p = flwp;
		self.B3.flw.a = false;
	end;
	
	self.B3.ab = false;
	if table.getn(self.beaconLights) > 0 then
		local i=0;
		while true do
			local str = string.format("vehicle.beaconLights.beaconLight(%d)#",i);
			if getXMLString(xmlFile, str.."index") == nil then break end;
			local rotNode = getXMLString(xmlFile, str.."rotIndex");
			if rotNode ~= nil then
				self.beaconLights[i+1].rotNode = Utils.indexToObject(self.components, rotNode);
				self.beaconLights[i+1].rotSpeed = self.beaconLights[i+1].speed;
				self.beaconLights[i+1].speed = 0;
				self.B3.ab = true;
			end;
			i=i+1;
		end;
		self.B3.blso = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.beaconLights#stayOn"),false);
	end;
	
	self.B3.sab = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.lightsaddon#strobesAreBeacons"),false);
	if self.B3.sab == true then
		for i=1,table.getn(self.B3.strobe) do
			self.B3.strobe.na = nil;
			self.B3.strobe.ht = nil;
		end;
	end;


	local bsf = getXMLString(xmlFile, "vehicle.lightsaddon.flashers#soundfile");
	if bsf ~= nil then
		self.B3.bss = createSample("flasherSound");
		loadSample(self.B3.bss, Utils.getFilename(bsf,self.baseDirectory), false);
		self.B3.bsl = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon.flashers#lowPitch"),0.8);
		self.B3.bsh = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon.flashers#highPitch"),1.0);
		self.B3.bsv = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon.flashers#volume"),1.0);
	end;
	self.B3.dar = Utils.getNoNil(getXMLBool(xmlFile,"vehicle.lightsaddon.flashers#autoreturn"),false);
	self.B3.art = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon.flashers#tolerance"),0.3);

	local tsf = Utils.getNoNil(getXMLString(xmlFile,"vehicle.lightsaddon.toggleSound#file"),"$dataS2/sounds/switchFlashlight.wav");
	local tsp = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon.toggleSound#pitch"),1.0);
	self.B3.tsv = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon.toggleSound#volume"),1.0);
	self.B3.tss = createSample("tss");
	loadSample(self.B3.tss, Utils.getFilename(tsf,self.baseDirectory), false);
	setSamplePitch(self.B3.tss, tsp);
	
	self.B3.lso = Utils.getNoNil(getXMLBool(xmlFile,"vehicle.lightsaddon#lightsStayOn"),false);
	self.B3.md = Utils.getNoNil(getXMLInt(xmlFile,"vehicle.lightsaddon#modDirection"),1);
	self.B3.bspd   = Utils.getNoNil(getXMLFloat(xmlFile,"vehicle.lightsaddon#blinkSpeed"),0.5) * 1000;
	
	self.B3.atv = nil;
	self.B3.setLA = false;
	self.B3.noRL = false;
	self.B3.wl = false;
	self.B3.blt = 0;
	self.B3.lsa = false;
	self.B3.bls = false;
	self.B3.left = false;
	self.deactivateLightsOnLeave = not self.B3.lso;
	if SpecializationUtil.hasSpecialization(Steerable, self.specializations) then
		self.B3.iSt = true;
	else
		self.B3.iSt = false;
	end;
	self.isSelectable = true;
end;

function BEL3:delete()
	if self.B3.bss ~= nil then
		delete(self.B3.bss);
	end;
	if self.B3.tss ~= nil then
		delete(self.B3.tss);
	end;
end;

function BEL3:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BEL3:keyEvent(unicode, sym, modifier, isDown)
end;

function BEL3:readStream(streamId, connection)
	if self.B3.work ~= nil then
		for i=1,table.getn(self.B3.work) do
			self:setState("work:"..i,streamReadBool(streamId),true);
		end;
	end;
	if self.B3.strobe ~= nil then
		for i=1,table.getn(self.B3.strobe) do
			self:setState("strobe:"..i,streamReadBool(streamId),true);
		end;
	end;
	if self.B3.highbeam ~= nil then
		self:setState("highbeam",streamReadBool(streamId),true);
	end;
	if self.B3.dirLeft ~= nil and self.B3.dirRight ~= nil then
		self:setState("dirLeft",streamReadBool(streamId),true);
		self:setState("dirRight",streamReadBool(streamId),true);
		self:setState("warnlights",streamReadBool(streamId),true);
	end;
	if self.B3.parkLeft ~= nil and self.B3.parkRight ~= nil then
		self:setState("parkLeft",streamReadBool(streamId),true);
		self:setState("parkRight",streamReadBool(streamId),true);
	end;
end;

function BEL3:writeStream(streamId, connection)
	if self.B3.work ~= nil then
		for k,v in pairs(self.B3.work) do
			streamWriteBool(streamId, v.a);
		end;
	end;
	if self.B3.strobe ~= nil then
		for k,v in pairs(self.B3.strobe) do
			streamWriteBool(streamId, v.a);
		end;
	end;
	if self.B3.highbeam ~= nil then
		streamWriteBool(streamId, self.B3.highbeam[1].a);
	end;
	if self.B3.dirLeft ~= nil and self.B3.dirRight ~= nil then
		streamWriteBool(streamId,self.B3.dirLeft[1].a);
		streamWriteBool(streamId,self.B3.dirRight[1].a);
		streamWriteBool(streamId,self.B3.wl);
	end;
	if self.B3.parkLeft ~= nil and self.B3.parkRight ~= nil then
		streamWriteBool(streamId,self.B3.parkLeft[1].a);
		streamWriteBool(streamId,self.B3.parkRight[1].a);
	end;
end;

function BEL3:update(dt)
	local updateState = {};
	if self:getIsActiveForInput(false) and not self:hasInputConflictWithSelection() then
		if self.B3.work ~= nil then
			for i=1,table.getn(self.B3.work) do
				local wl = self.B3.work[i];
				if InputBinding.hasEvent(InputBinding[wl.na]) and InputBinding[wl.na] ~= nil and wl.na ~= nil then
					self:setState("work:"..i,not wl.a);
					if self:getIsActiveForSound() then
						playSample(self.B3.tss, 1, self.B3.tsv, 0);
					end;
				end;
			end;
		end;
		if self.B3.strobe ~= nil then
			for i=1,table.getn(self.B3.strobe) do
				local sl = self.B3.strobe[i];
				if InputBinding.hasEvent(InputBinding[sl.na]) and InputBinding[sl.na] ~= nil and sl.na ~= nil then
					self:setState("strobe:"..i,not sl.a);
					if self:getIsActiveForSound() then
						playSample(self.B3.tss, 1, self.B3.tsv, 0);
					end;
				end;
			end;
		end;
		if self.B3.highbeam ~= nil then
			local hb = self.B3.highbeam[1];
			if InputBinding.isPressed(InputBinding.TOGGLE_LIGHTS) then
				if hb.cnt == nil then
					hb.cnt = 0;
					if not self.lightsActive then
						self.B3.setLA = true;
						self:setLightsVisibility(true);
					end;
				else
					if hb.blk == nil then 
						hb.cnt = hb.cnt + dt;
						self.B3.noRL = not hb.a;
					end;
				end;
				if hb.cnt > 1500 and hb.blk == nil then
					self:setState("highbeam", not hb.a);
					self.B3.setLA = false;
					self.B3.noRL = not hb.a;
					hb.blk = true;
				end;
			else
				if hb.cnt ~= nil and hb.blk == nil then
					if self.B3.setLA then
						hb.a = false;
						self.B3.setLA = false;
						self:setLightsVisibility(false);
						self:setState("highbeam", false);
					else
						self.B3.setLA = false;
					end;
				end;
				hb.cnt = nil;
				hb.blk = nil;
			end;
		end;
		
		if self.B3.dirLeft ~=nil and self.B3.dirRight ~= nil then
			local dl = self.B3.dirLeft[1]; local dr = self.B3.dirRight[1];
			if not self.B3.wl then
				if InputBinding.hasEvent(InputBinding.BEL3LEFT) then
					if self:getIsActiveForSound() then
						playSample(self.B3.tss, 1, self.B3.tsv, 0);
					end;
					self:setState("dirLeft",not dl.a);
					self:setState("dirRight", false);
				end;
				if InputBinding.hasEvent(InputBinding.BEL3RIGHT) then
					if self:getIsActiveForSound() then
						playSample(self.B3.tss, 1, self.B3.tsv, 0);
					end;
					self:setState("dirLeft", false);
					self:setState("dirRight", not dr.a);
				end;
			end;
			if InputBinding.hasEvent(InputBinding.BEL3WARN) then
				if self:getIsActiveForSound() then
					playSample(self.B3.tss, 1, self.B3.tsv, 0);
				end;
				self:setState("warnlights",not self.B3.wl);
				self:setState("dirLeft",self.B3.wl);
				self:setState("dirRight",self.B3.wl);
			end;
		end;
	end;
	
	if self.B3.strobe ~= nil then
		for _,st in ipairs(self.B3.strobe) do
			if st.a then
				if st.t > st.ns then
					st.ls = not st.ls;
					setVisibility(st.index, st.ls);
					st.t = 0;
					if st.rnd then
						if st.ls then
							st.ns = math.random(st.rndnn,st.rndxn);
						else
							st.ns = math.random(st.rndnf,st.rndxf);
						end;
					else
						st.ss = st.ss + 1; 
						if st.ss > table.getn(st.sq) then st.ss = 1; end;
						st.ns = st.sq[st.ss];
					end;
				else
					st.t = st.t + dt;
				end;
			end;
		end;
	end;
	
	if self.isServer and self:getIsActive() then
		if self.B3.brake ~= nil and self.B3.iSt then
			local iB = math.abs(Utils.sign(self.lastAcceleration)+ (-self.movingDirection*self.B3.md)) == 2;
			if self.B3.brake[1].a ~= iB then
				self:setState("brake",iB);
			end;
		end;
		if self.B3.reverse ~= nil then
			local iR = (self.movingDirection*self.B3.md) < 0;
			if self.B3.reverse[1].a ~= iR then 		
				self:setState("reverse",iR);
			end;
		end;
	end;
	
	if self.B3.ab and self.B3.bla then
		for _,bl in ipairs(self.beaconLights) do
			if bl.rotNode ~= nil then
				rotate(bl.rotNode, 0, bl.rotSpeed*dt, 0);
			end;
		end;
	end;
	
end;

function BEL3:updateTick(dt)

	if self.B3.dirLeft ~=nil and self.B3.dirRight ~= nil then
		local dl = self.B3.dirLeft; local dr = self.B3.dirRight;
		if dl[1].a or dr[1].a then
			if self.B3.blt > self.B3.bspd then
				self.B3.bls = not self.B3.bls;
				self.B3.blt = 0;
				if dl[1].a then
					for _,b in pairs(dl) do
						setVisibility(b.index,not self.B3.bls);
					end;
				end;
				if dr[1].a then
					for _,b in pairs(dr) do
						setVisibility(b.index,not self.B3.bls);
					end;
				end;
				--blinkersound
				if self:getIsActiveForSound() and self.B3.bss then
					if self.B3.bls then
						setSamplePitch(self.B3.bss, self.B3.bsl);
					else
						setSamplePitch(self.B3.bss, self.B3.bsh);
					end;
					playSample(self.B3.bss, 1, self.B3.bsv, 0);
				end;
			else
				self.B3.blt = self.B3.blt+dt;
			end;
			if self.B3.dar and not self.B3.wl then
				local rtp = math.abs(self.rotatedTime/self.maxRotTime);
				if not self.B3.lsa then
					if rtp > self.B3.art then
						self.B3.lsa = true;
					end;
				else
					if rtp < self.B3.art then
						self.B3.lsa = false;
						self:setState("dirLeft",false);
						self:setState("dirRight",false);
					end;
				end;
			end;
		else
			self.B3.blt = 0;
			if self.B3.bls == true then
				for _,b in pairs(dl) do
					setVisibility(b.index,false);
				end;
				for _,b in pairs(dr) do
					setVisibility(b.index,false);
				end;
				self.B3.bls = false;
			end;
		end;
	end;
	
	if self.B3.highbeam and self.realLightsActive then
		if self.B3.highbeam[1].a and not self.B3.noRL then
			for _,light in pairs(self.lights) do
				setVisibility(light,false);
			end;
			self.B3.noRL = true;
		elseif not self.B3.highbeam[1].a and self.B3.noRL then
			for _,light in pairs(self.lights) do
				setVisibility(light,true);
			end;
			self.B3.noRL = false;
		end;
	end;

	if self:getIsActive() and not self.B3.iSt and self.B3.atv ~= nil then
		local atvb = false;
		if self.B3.atv.B3 ~= nil then 
			local atv = self.B3.atv.B3;
			if atv.brake ~= nil and self.B3.brake ~= nil then
				atvb = true;
				if self.B3.brake[1].a ~= atv.brake[1].a then
					self:setState("brake",atv.brake[1].a,true);
				end;
			end;
			if atv.reverse ~= nil and self.B3.reverse ~= nil then
				if self.B3.reverse[1].a ~= atv.reverse[1].a then
					self:setState("reverse",atv.reverse[1].a,true);
				end;
			end;
			if self.B3.dirLeft ~=nil and self.B3.dirRight ~= nil then
				if atv.wl ~= self.B3.wl then
					self:setState("warnlights",not self.B3.wl);
					self:setState("dirLeft",self.B3.wl);
					self:setState("dirRight",self.B3.wl);
				else
					if atv.dirLeft ~= nil and atv.dirRight ~= nil then
						if atv.dirLeft[1].a ~= self.B3.dirLeft[1].a or atv.dirRight[1].a ~=  self.B3.dirRight[1].a then
							self:setState("dirLeft", atv.dirLeft[1].a);
							self:setState("dirRight", atv.dirRight[1].a);
						end;
					end;
				end;
			end;
		end;
		if not atvb and self.B3.brake ~= nil then
			local iB = math.abs(Utils.sign(self.B3.atv.lastAcceleration)+ (-self.movingDirection*self.B3.md)) == 2;
			if self.B3.brake[1].a ~= iB then
				self:setState("brake",iB);
			end;
		end;
	end;
	
	if self:getIsActive() then
		if self.B3.flw ~= nil then
			if not self.B3.flw.a then
				if self.grainTankFillLevel > 0 and not self.beaconLightsActive then
					local p = self.grainTankFillLevel * 100 / self.grainTankCapacity;
					if p >= self.B3.flw.p then
						self:setBeaconLightsVisibility(true);
						self.B3.flw.a = true;
					end;
				end;
			else
				if self.beaconLightsActive then
					local p = self.grainTankFillLevel * 100 / self.grainTankCapacity;
					if p < self.B3.flw.p then
						self:setBeaconLightsVisibility(false);
						self.B3.flw.a = false;
					end;
				end;
			end;
		end;

		self.B3.bla = self.beaconLightsActive;
		
		if self.B3.sab and self.B3.strobe ~= nil and self.beaconLightsActive ~= nil then
			if self.B3.strobe[1].a ~= self.beaconLightsActive then
				for i=1,table.getn(self.B3.strobe) do
					self:setState("strobe:"..i, self.beaconLightsActive);
				end;
			end;
		end;

		if self.B3.drl ~= nil then
			if self.B3.drl[1].a == self.lightsActive then
				self:setState("drl", not self.lightsActive);
			end;
		end;

	end;
	
	if self.currentPipeState ~= nil and self.B3.pipe ~= nil then
		if (self.currentPipeState > 1) ~= self.B3.pipe[1].a then
			self:setState("pipe", self.currentPipeState > 1, true);
		end;
	end;
	
	if self.B3.bla and not self.beaconLightsActive then
		self:setBeaconLightsVisibility(true, true);
	end;
	
end;

function BEL3:draw()
	if self.B3.work ~= nil then
		for i=1,table.getn(self.B3.work) do
			local wl = self.B3.work[i];
			if wl.ht ~= nil and wl.na ~= nil then
				g_currentMission:addHelpButtonText(g_i18n:getText(wl.ht), InputBinding[wl.na]);
			end;
		end;
	end;
	if self.B3.strobe ~= nil then
		for i=1,table.getn(self.B3.strobe) do
			local sl = self.B3.strobe[i];
			if sl.ht ~= nil and sl.na ~= nil then
				g_currentMission:addHelpButtonText(g_i18n:getText(sl.ht), InputBinding[sl.na]);
			end;
		end;
	end;
end;

function BEL3:onAttach()
	local atv = self.attacherVehicle;
	self.B3.bbspd = self.B3.bspd;
	while true do 
		if atv.attacherVehicle ~= nil then
			atv = atv.attacherVehicle;
		else 
			break;
		end;
	end;
	self.B3.atv = atv;
	if atv.B3 ~= nil then
		if atv.B3.bspd ~= nil then
			self.B3.bspd = atv.B3.bspd;
		end;
	end;
	if atv.beaconLightsActive then
		self:setBeaconLightsVisibility(atv.beaconLightsActive);
	end;
	self:activate();
end;

function BEL3:onDetach()
	self.B3.atv = nil;
	if self.B3.bbspd ~= nil then
		self.B3.bspd = self.B3.bbspd;
	end;
	self:deactivate();
end;			

function BEL3:onDeactivate()
	self:deactivate();
end;

function BEL3:onLeave()
	self:deactivate();
end;

function BEL3:deactivate()
	if self.B3.left then
		self.B3.left = false;
		return;
	else
		self.B3.left = true;
	end;
	if self.B3.work ~= nil then
		for i=1,table.getn(self.B3.work) do
			local wl = self.B3.work[i];
			local newstate = false;
			if wl.so then
				newstate = wl.a;
			end;
			self:setState("work:"..i,newstate,true);
		end;
	end;
	if self.B3.strobe ~= nil then
		for i=1,table.getn(self.B3.strobe) do
			local sl = self.B3.strobe[i];
			local newstate = false;
			if sl.so then
				newstate = sl.a;
			end;
			self:setState("strobe:"..i,newstate,true);
		end;
	end;

	if self.B3.highbeam ~= nil then
		self:setState("highbeam", false,true);
	end;
	
	if self.B3.flw ~= nil then
		self.B3.flw.a = false;
	end;

	if self.B3.lso then
		--koronas an , licht aus
		local la = self.lightsActive;
		if self.attacherVehicle ~= nil then
			la = self.attacherVehicle.lightsActive;
		end;
		if la then
			self:setLightsVisibility(false);
			if self.B3.parkLeft and self.B3.parkRight then
				self:setState("parkLeft",true);
				self:setState("parkRight",true);
			else
		        for _, corona in pairs(self.lightCoronas) do
		            setVisibility(corona, true);
		        end;
      		end;
    		end;
	end;

	if not self.B3.wl then
		if self.B3.dirLeft and self.B3.dirRight then
			if self.B3.parkLeft and self.B3.parkRight then
				if self.B3.dirLeft[1].a then
					self:setState("parkLeft",true);
				end;
				if self.B3.dirRight[1].a then
					self:setState("parkRight",true);
				end;
			end;
			if self.B3.dirLeft[1].a then
				self:setState("dirLeft",false);
			end;
			if self.B3.dirRight[1].a then
				self:setState("dirRight",false);
			end;
		end;
	end;
	
	if self.B3.brake then
		if self.B3.brake[1].a then
			self:setState("brake",false);
		end;
	end;
	if self.B3.reverse then
		if self.B3.reverse[1].a then
			self:setState("reverse",false);
		end;
	end;

	if self.B3.drl ~= nil then
		if self.B3.drl[1].a then
			self:setState("drl", false);
		end;
	end;

	if self.B3.bla and not self.B3.blso then
		self.B3.bla = false;
	end;
	
end;	

function BEL3:onEnter()
	self:activate();
end;

function BEL3:onActivate()
	self:activate();
end;

function BEL3:activate()
	self.B3.left = false;
	if self.B3.work then
		for i=1,table.getn(self.B3.work) do
			local wl = self.B3.work[i];
			self:setState("work:"..i,wl.a,true);
		end;
	end;
	if self.B3.strobe then
		for i=1,table.getn(self.B3.strobe) do
			local sl = self.B3.strobe[i];
			self:setState("strobe:"..i,sl.a,true);
		end;
	end;
	if self.B3.parkLeft and self.B3.parkRight then
		if self.B3.parkLeft[1].a and self.B3.parkRight[1].a then
			self:setState("parkLeft",false);
			self:setState("parkRight",false);
			self:setLightsVisibility(true);
		end;
	end;
	if self.B3.dirLeft and self.B3.parkLeft then
		if self.B3.parkLeft[1].a then
			self:setState("dirLeft",true);
			self:setState("parkLeft",false);
		end;
	end;
	if self.B3.dirRight and self.B3.parkRight then
		if self.B3.parkRight[1].a then
			self:setState("dirRight",true);
			self:setState("parkRight",false);
		end;
	end;
	if self.lightCoronas ~= nil then
		if getVisibility(self.lightCoronas[1]) == true then
			self:setLightsVisibility(true);
		end;
	end;

	if self.B3.drl ~= nil then
		if self.B3.drl[1].a == false then
			self:setState("drl", true);
		end;
	end;

end;	

function BEL3:setState(object,state,noEventSend)
	if object=="warnlights" then
		self.B3.wl = state;
		SetLightStateEvent.sendEvent(self,object,state,noEventSend);
		return;
	end;
	local o,c = unpack(Utils.splitString(":",object));
	local lt = self.B3[o];
	local cs = 1; local cm = table.getn(lt);
	if c ~= nil then
		cs = tonumber(c); cm = cs;
	end;
	for c=cs,cm do
		local l = lt[c];
		l.a = state;
		setVisibility(l.index,state);
		local rstate = false; 
		local bstate = false;

		local isEntered = self.isEntered;
		if self.B3.atv ~= nil then
			isEntered = self.B3.atv.isEntered;
		end;

		if isEntered == true then
			rstate = state;
		else
			bstate = state;
		end;
		if l.rl ~= nil then
			setVisibility(l.rl,rstate);
		end;
		if l.fl ~= nil then
			setVisibility(l.fl,bstate);
		end;
	end;

	SetLightStateEvent.sendEvent(self,object,state,noEventSend);
end;


SetLightStateEvent = {};
SetLightStateEvent_mt = Class(SetLightStateEvent, Event);

InitEventClass(SetLightStateEvent, "SetLightStateEvent");

function SetLightStateEvent:emptyNew()
    local self = Event:new(SetLightStateEvent_mt);
    self.className="SetLightStateEvent";
    return self;
end;

function SetLightStateEvent:new(object, light, state)
		local self = SetLightStateEvent:emptyNew()
		self.object = object;
		self.light = light;
		self.state = state;
		return self;
end;

function SetLightStateEvent:readStream(streamId, connection)
    self.object = networkGetObject(streamReadInt32(streamId));
		self.light  = streamReadString(streamId);
    self.state = streamReadBool(streamId);
    self:run(connection);
end;

function SetLightStateEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.object));
		streamWriteString(streamId, self.light);
		streamWriteBool(streamId, self.state);
end;

function SetLightStateEvent:run(connection)
	self.object:setState(self.light,self.state, true);
  if not connection:getIsServer() then
      g_server:broadcastEvent(SetLightStateEvent:new(self.object, self.light, self.state), nil, connection, self.object);
  end;	
end;

function SetLightStateEvent.sendEvent(vehicle, light, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetLightStateEvent:new(vehicle, light, state), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(SetLightStateEvent:new(vehicle, light, state));
		end;
	end;
end;

