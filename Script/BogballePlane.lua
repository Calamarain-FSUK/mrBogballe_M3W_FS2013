--
-- BogballePlane
-- Specialization for Bogballe Plane
--
-- LS-Modsource.com
-- @author  Geri-G
-- @date  22/12/2009
--

BogballePlane = {};

function BogballePlane.prerequisitesPresent(specializations)
    return true;
end;

function BogballePlane:load(xmlFile)
    self.PlaneNodeO = Utils.indexToObject(self.components, getXMLString(xmlFile,"vehicle.Plane#indexOpen"));
    self.PlaneNodeC = Utils.indexToObject(self.components, getXMLString(xmlFile,"vehicle.Plane#indexClose"));
    self.isOpen = true;
    setVisibility(self.PlaneNodeO, not self.isOpen);
    setVisibility(self.PlaneNodeC, self.isOpen);
end;

function BogballePlane:delete()
end;

function BogballePlane:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isOpen);
end;

function BogballePlane:readStream(streamId, connection)
    self.isOpen = streamReadBool(streamId);
    --
    BogballePlane.setPlaneVisible(self, self.isOpen, true);
end;

function BogballePlane:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BogballePlane:keyEvent(unicode, sym, modifier, isDown)
end;

function BogballePlane:setPlaneVisible(newVisibility, noEventSend)   
    BogballePlaneEvent.sendEvent(self, newVisibility, noEventSend)
    --
    self.isOpen = newVisibility;
    setVisibility(self.PlaneNodeO, not self.isOpen);
    setVisibility(self.PlaneNodeC, self.isOpen);
end

function BogballePlane:update(dt)   
    if self.currentStep == 3 then
        if self:getIsActive() and self:getIsActiveForInput() then
            if InputBinding.hasEvent(InputBinding.Bogballe_Plane) then
                BogballePlane.setPlaneVisible(self, not self.isOpen);
            end;
        end;
    end;
end;

function BogballePlane:draw()
    if self.currentStep == 3 then
        --g_currentMission:addExtraPrintText(g_i18n:getText("BogballePlane_1"),InputBinding.Bogballe_Plane);
        g_currentMission:addHelpButtonText(g_i18n:getText("Bogballe_Plane"), InputBinding.Bogballe_Plane);
    end;
end;

function BogballePlane:onAttach(attacherVehicle)
end;

function BogballePlane:onDetach()
end;

function BogballePlane:onLeave()
end;

function BogballePlane:onDeactivate()
end;

function BogballePlane:onDeactivateSounds()
end;

----------
----------

BogballePlaneEvent = {};
BogballePlaneEvent_mt = Class(BogballePlaneEvent, Event);

InitEventClass(BogballePlaneEvent, "BogballePlaneEvent");

function BogballePlaneEvent:emptyNew()
    local self = Event:new(BogballePlaneEvent_mt);
    self.className="BogballePlaneEvent";
    return self;
end;

function BogballePlaneEvent:new(vehicle, isVisible)
    local self = BogballePlaneEvent:emptyNew()
    self.vehicle      = vehicle;
    self.isVisible    = isVisible;
    return self;
end;

function BogballePlaneEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));   
    streamWriteBool(streamId,  self.isVisible);
end;

function BogballePlaneEvent:readStream(streamId, connection)
    self.vehicle      = networkGetObject(streamReadInt32(streamId));
    self.isVisible    = streamReadBool(streamId);
    --
    self:run(connection);
end;

function BogballePlaneEvent:run(connection)
    if self.vehicle ~= nil then
        BogballePlane.setPlaneVisible(self.vehicle, self.isVisible, true);
        --
        if not connection:getIsServer() then
            g_server:broadcastEvent(BogballePlaneEvent:new(self.vehicle, self.isVisible), nil, connection, self.vehicle);
        end;
    end
end;

function BogballePlaneEvent.sendEvent(vehicle, isVisible, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BogballePlaneEvent:new(vehicle, isVisible), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(BogballePlaneEvent:new(vehicle, isVisible));
        end;
    end;
end;
