BogballeChangeSprayWidthEvent = {};
BogballeChangeSprayWidthEvent_mt = Class(BogballeChangeSprayWidthEvent, Event);

InitEventClass(BogballeChangeSprayWidthEvent, "BogballeChangeSprayWidthEvent");

function BogballeChangeSprayWidthEvent:emptyNew()
    local self = Event:new(BogballeChangeSprayWidthEvent_mt);
    self.className="BogballeChangeSprayWidthEvent";
    return self;
end;

function BogballeChangeSprayWidthEvent:new(vehicle, increaseWidth)
    local self = BogballeChangeSprayWidthEvent:emptyNew()
    self.vehicle = vehicle;
	self.increaseWidth = increaseWidth;
    return self;
end;

function BogballeChangeSprayWidthEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
	self.increaseWidth = streamReadBool(streamId);
    self.vehicle = networkGetObject(id);
    self:run(connection);
end;

function BogballeChangeSprayWidthEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));	
	streamWriteBool(streamId, self.increaseWidth);	
end;

function BogballeChangeSprayWidthEvent:run(connection)
	self.vehicle:changeSprayWidth(self.increaseWidth, true);
	if not connection:getIsServer() then
		g_server:broadcastEvent(BogballeChangeSprayWidthEvent:new(self.vehicle, self.increaseWidth), nil, connection, self.object);
	end;
end;

function BogballeChangeSprayWidthEvent.sendEvent(vehicle, increaseWidth, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BogballeChangeSprayWidthEvent:new(vehicle, increaseWidth), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(BogballeChangeSprayWidthEvent:new(vehicle, increaseWidth));
		end;
	end;
end;