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

function BogballePlane:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BogballePlane:keyEvent(unicode, sym, modifier, isDown)
end;

function BogballePlane:update(dt)   
    if self.currentStep == 3 then
        if self:getIsActive() and self:getIsActiveForInput() then
            if InputBinding.hasEvent(InputBinding.Bogballe_Plane) then
                self.isOpen = not self.isOpen;
                setVisibility(self.PlaneNodeO, not self.isOpen);
                setVisibility(self.PlaneNodeC, self.isOpen);
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
