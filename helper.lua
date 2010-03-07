--  HELPER  ZEUGS
function BiteMELEE:whisper(msg, name)
   if not (msg and name) then return end   
   SendChatMessage(Prefix..msg, "WHISPER", nil, name)
end

function BiteMELEE:channel(msg)
	if msg then		
		SendChatMessage(msg, "OFFICER", nil)
	end	
end

local print,format = print,string.format
function BiteMELEE:message(msg)
	if msg then		
		print(format("|cffff0033"..Prefix.."|r%s",msg))
	end
end

--  Chat-Filter
function filterOutgoing(self, event, ...)
	local msg = ...
	if not msg and self then
		return filterOutgoing(nil, nil, self, event)
	end
	-- wir gucken ob der anfang der msg gleich unserem Prefix ist
	return msg:sub(1, Prefix:len()) == Prefix, ...	
end
-- Filter muss noch registriert werden
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutgoing)