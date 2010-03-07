-- Einstellungen
local BiteMe = {}
BiteMe[1] = {
	"L1", --L1
	"L2", --L2
	"Knopf", --L3
	"L4",  --L4
	"L5"  --L5
}
BiteMe[2] = {
	"R1", --R1
	"R2", --R2
	"R3", --R3
	"R4", --R4
	"R5"  --R5
}
local RangedPlayer = "RP1"
local RangedPlayer = "RP2"
local Prefix = "BiteME: " -- Pröfix für z.B. die Whispers

-- alle unsere Combatlog Daten
local timestamp, type, srcGUID, srcName, srcFlgs, dstGUID, dstName, dstFlgs, spellID, spellName

-- Frame bauen
local BiteMELEE = CreateFrame("FRAME", "BiteMELEE")

BiteMELEE:SetScript("OnEvent",
	function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			timestamp, type, srcGUID, srcName, srcFlgs, dstGUID, dstName, dstFlgs = select(1, ...)		
			--  AUREN    
			if type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_APPLIED_DOSE" then
				spellID, spellName = select(9, ...)				
				if spellID == 71473 then  -- Essence of the Blood Queen			
					self:BiteOrder()
					self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				end
			end
		elseif event:sub(1,12) == "ZONE_CHANGED" then
			--self:message(format("Zone changed to %q",GetSubZoneText()))
			self:CheckZone()
		elseif event == "ADDON_LOADED" then
			self:Initialize()
		end
	end)	
BiteMELEE:RegisterEvent("ADDON_LOADED")

function BiteMELEE:Initialize()	
	self:UnregisterEvent("ADDON_LOADED")
	-- Slashcommands einbinden
	SLASH_BITEMELEE1 = "/bitemelee"
	SLASH_BITEMELEE2 = "/bm"
	SlashCmdList["BITEMELEE"] = function(msg) self:SlashCommandHandler(msg)	end	
	self:message("loaded. Type in /bitemelee for more Options.")
	-- Zonen tracken
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")	
	self:CheckZone()
end

-- Interpreter der Slashbefehle, hier 0 = reload ui
function ImmotaFrames_SlashCommandHandler(msg)
	if msg == "0" then ReloadUI() end	
 	self:ToggleFrame(msg);
end

local subzone    = GetSubZoneText()
local difficulty = GetInstanceDifficulty()
function BiteMELEE:CheckZone()
	subzone    = GetSubZoneText()
	difficulty = GetInstanceDifficulty()
	if subzone == "EN" or subzone == "DE"  then
		self:message("Looking for |TInterface\\Icons\\ability_warlock_improvedsoulleech:16|tEssence of the Blood Queen!")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else			
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end	
end

function BiteMELEE:BiteOrder()	
		if dstName ~= BiteMe[1][1] or dstName ~= BiteMe[2][1] then
		self:message(format("%s ist kein Verteiler, suche nach anderen", dstName))
			for k,v in pairs(BiteMe[1]) do
				if v == dstName then
					self:message("links gefunden")
					table.remove(BiteMe[1], k)
					table.insert(BiteMe[1], 1 , v)
				end
			end
			for k,v in pairs(BiteMe[2]) do
				if v == dstName then
					self:message("rechts gefunden")
					table.remove(BiteMe[2],k)
					table.insert(BiteMe[2],1,v)
				end
			end
		end		
		-- Ausgabe in einen chan
		self:channel(format("(Links) %s %s %s %s",BiteMe[1][1],BiteMe[1][2],BiteMe[1][3],BiteMe[1][4]))
		self:channel(format("(Rechts) %s %s %s %s",BiteMe[2][1],BiteMe[2][2],BiteMe[2][3],BiteMe[2][4]))		
		-- BEISPIEL
		--self:whisper("TEXT","PLAYER")
		--format("%s %s %s %s",var1,var2,var3,var4) -> "bla1 bla2 bla3 bla4"
end

-- Funktion für den Button Send Setup. Sendet die Aufstellung an den Raidchat
function BiteMELEE:OnClick(arg)
	id = this:GetID()
	out("ImmotaFrames: OnClick: " .. this:GetName() .. " ,ID: " .. id .. " ,Button:" ..arg1)
	out2ra("Aufstellung Melees Blood Queen")
	out2ra("Linke Seite: " .. BiteMe["Left"][1].. ", " .. BiteMe["Left"][2] .. ", ".. BiteMe["Left"][3] .. ", " .. BiteMe["Left"][4].. ", " .. BiteMe["Left"][5])
	out2ra("Rechte Seite: " .. BiteMe["Right"][1].. ", " .. BiteMe["Right"][2] .. ", ".. BiteMe["Right"][3] .. ", " .. BiteMe["Right"][4].. ", " .. BiteMe["Right"][5])
	out2ra("Verteiler bei den Melees ist " .. BiteMe["Left"][1])
	out2ra("Verteiler bei den Ranged ist " .. RangedPlayer1)
	-- out2ra("-->  Hallo Karla :)")
end

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