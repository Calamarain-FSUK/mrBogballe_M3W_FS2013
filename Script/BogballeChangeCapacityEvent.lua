BogballeChangeCapacityEvent = {};
BogballeChangeCapacityEvent_mt = Class(BogballeChangeCapacityEvent, Event);

InitEventClass(BogballeChangeCapacityEvent, "BogballeChangeCapacityEvent");

function BogballeChangeCapacityEvent:emptyNew()
    local self = Event:new(BogballeChangeCapacityEvent_mt);
    self.className="BogballeChangeCapacityEvent";
    return self;
end;

function BogballeChangeCapacityEvent:new(vehicle, increaseCapacity)
    local self = BogballeChangeCapacityEvent:emptyNew()
    self.vehicle = vehicle;
    self.increaseCapacity = increaseCapacity;
    return self;
end;

function BogballeChangeCapacityEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
    self.increaseCapacity = streamReadBool(streamId);
    self.vehicle = networkGetObject(id);
    self:run(connection);
end;

function BogballeChangeCapacityEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));   
    streamWriteBool(streamId, self.increaseCapacity);   
end;

function BogballeChangeCapacityEvent:run(connection)
    self.vehicle:changeCapacity(self.increaseCapacity, true);
    if not connection:getIsServer() then
        g_server:broadcastEvent(BogballeChangeCapacityEvent:new(self.vehicle, self.increaseCapacity), nil, connection, self.object);
    end;
end;

function BogballeChangeCapacityEvent.sendEvent(vehicle, increaseCapacity, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BogballeChangeCapacityEvent:new(vehicle, increaseCapacity), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(BogballeChangeCapacityEvent:new(vehicle, increaseCapacity));
        end;
    end;
end;