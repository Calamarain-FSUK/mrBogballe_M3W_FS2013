BogballeChangeLiterPerHaEvent = {};
BogballeChangeLiterPerHaEvent_mt = Class(BogballeChangeLiterPerHaEvent, Event);

InitEventClass(BogballeChangeLiterPerHaEvent, "BogballeChangeLiterPerHaEvent");

function BogballeChangeLiterPerHaEvent:emptyNew()
    local self = Event:new(BogballeChangeLiterPerHaEvent_mt);
    self.className="BogballeChangeLiterPerHaEvent";
    return self;
end;

function BogballeChangeLiterPerHaEvent:new(vehicle, increase)
    local self = BogballeChangeLiterPerHaEvent:emptyNew()
    self.vehicle = vehicle;
	self.increase = increase;
    return self;
end;

function BogballeChangeLiterPerHaEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
	self.increase = streamReadBool(streamId);
    self.vehicle = networkGetObject(id);
    self:run(connection);
end;

function BogballeChangeLiterPerHaEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));	
	streamWriteBool(streamId, self.increase);	
end;

function BogballeChangeLiterPerHaEvent:run(connection)
	self.vehicle:changeLiterPerHa(self.increase, true);
	if not connection:getIsServer() then
		g_server:broadcastEvent(BogballeChangeLiterPerHaEvent:new(self.vehicle, self.increase), nil, connection, self.object);
	end;
end;

function BogballeChangeLiterPerHaEvent.sendEvent(vehicle, increase, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BogballeChangeLiterPerHaEvent:new(vehicle, increase), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(BogballeChangeLiterPerHaEvent:new(vehicle, increase));
		end;
	end;
end;