-- Einstellungen
local BiteMe = {}
BiteMe["Melee"] = {}
BiteMe["Melee"]["Left"] = {
	"ML1", --L1
	"ML2", --L2
	"ML3", --L3
	"ML4",  --L4
	"ML5"  --L5
}
BiteMe["Melee"]["Right"] = {
	"MR1", --R1
	"MR2", --R2
	"MR3", --R3
	"MR4", --R4
	"MR5"  --R5
}
BiteMe["Ranged"] = {}
BiteMe["Ranged"]["Left"] = {
	"RL1", --RL1
	"RL2", --RL2
	"RL3", --RL3
	"RL4", --RL4
	"RL5"  --L5
}
BiteMe["Ranged"]["Right"] = {
	"RR1", --RR1
	"RR2", --RR2
	"RR3", --RR3
	"RR4", --RR4
	"RR5"  --RR5
}
local Prefix = "BiteME: " -- Pröfix für z.B. die Whispers
local reordered = false

-- alle unsere Combatlog Daten
local timestamp, type, srcGUID, srcName, srcFlgs, dstGUID, dstName, dstFlgs, spellID, spellName

-- Frame bauen
local BiteME = CreateFrame("FRAME", "BiteME")

BiteME:SetScript("OnEvent",
	function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			timestamp, type, srcGUID, srcName, srcFlgs, dstGUID, dstName, dstFlgs = select(1, ...)		
			--  AUREN    
			if type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_APPLIED_DOSE" then
				spellID, spellName = select(9, ...)				
				if spellID == 71473 then  -- Essence of the Blood Queen
					if not reordered then self:BiteOrder() end
					self:Announce()
				end
			end
		elseif event:sub(1,12) == "ZONE_CHANGED" then
			--self:message(format("Zone changed to %q",GetSubZoneText()))
			reordered = false -- wir mißbrauchen das Event zum resetten
			self:CheckZone()
		elseif event == "ADDON_LOADED" then
			self:Initialize()
		end
	end)	
BiteME:RegisterEvent("ADDON_LOADED")

function BiteME:Initialize()	
	self:UnregisterEvent("ADDON_LOADED")
	-- Slashcommands einbinden
	SLASH_BITEME1 = "/biteme"
	SLASH_BITEME2 = "/bm"
	SlashCmdList["BITEME"] = function(msg) self:SlashCommandHandler(msg) end	
	self:message("loaded. Type in /biteme for more Options.")
	-- Zonen tracken
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")	
	self:CheckZone()
end

-- Interpreter der Slashbefehle, hier 0 = reload ui
function BiteME:SlashCommandHandler(arg)
	if arg == "0" then ReloadUI() end	
 	self:Toggle(arg);
end

local subzone = GetSubZoneText()
local difficulty = GetInstanceDifficulty()
function BiteME:CheckZone()
	subzone    = GetSubZoneText()
	difficulty = GetInstanceDifficulty()
	if subzone == "EN" or subzone == "DE"  then
		self:message("Looking for |TInterface\\Icons\\ability_warlock_improvedsoulch:16|tEssence of the Blood Queen!")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else			
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end	
end

function BiteME:BiteOrder()		
	-- Ist der erste gebissene kein Verteiler? Dann verändern wir die Reihenfolgen
	if  dstName ~= BiteMe["Melee"]["Left"][1] or dstName ~= BiteMe["Melee"]["Right"][1] or dstName ~= BiteMe["Ranged"]["Left"][1] or dstName ~= BiteMe["Ranged"]["Right"][1] then
		self:message(format("%s ist kein Verteiler, suche nach anderen", dstName))
		-- Melees links
		for k,v in pairs(BiteMe["Melee"]["Left"]) do
			if v == dstName then					
				table.remove(BiteMe["Melee"]["Left"], k)
				table.insert(BiteMe["Melee"]["Left"], 1 , v)
			end
		end
		-- Melees rechts
		for k,v in pairs(BiteMe["Melee"]["Right"]) do
			if v == dstName then					
				table.remove(BiteMe["Melee"]["Right"],k)
				table.insert(BiteMe["Melee"]["Right"],1,v)
			end
		end
		-- Ranged links
		for k,v in pairs(BiteMe["Ranged"]["Left"]) do
			if v == dstName then
				BiteMe["Ranged"]["Left"][k] = BiteMe["Ranged"]["Left"][1]
				BiteMe["Ranged"]["Left"][1] = dstName
			end
		end
		-- Ranged rechts
		for k,v in pairs(BiteMe["Ranged"]["Right"]) do
			if v == dstName then
				BiteMe["Ranged"]["Right"][k] = BiteMe["Ranged"]["Right"][1]
				BiteMe["Ranged"]["Right"][1] = dstName
			end
		end
	end
	reordered = true
end

-- Funktion für den Button GetTarget4L1
function BiteME:GetTarget4L1(...)
	if UnitName("target") then
		self:channel("Target: "..UnitName("target"))
		BiteMe_InputBox1:Insert(UnitName("target"))
	end
end


-- Funktion für den Button Send Setup. Sendet die Aufstellung an den Raidchat
function BiteME:OnClick()
	self:channel("Aufstellung Melees Blood Queen")
	self:channel(format("Linke Seite: %s, %s, %s, %s, %s",BiteMe["Melee"]["Left"][1],BiteMe["Melee"]["Left"][2],BiteMe["Melee"]["Left"][3],BiteMe["Melee"]["Left"][4],BiteMe["Melee"]["Left"][5]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s, %s",BiteMe["Melee"]["Right"][1],BiteMe["Melee"]["Right"][2],BiteMe["Melee"]["Right"][3],BiteMe["Melee"]["Right"][4],BiteMe["Melee"]["Right"][5]))
	self:channel(format("Verteiler bei den Mes ist %s",BiteMe["Melee"]["Left"][1]))
	self:channel(format("Verteiler bei den Ranged ist %s",BiteMe["Ranged"]["left"][1]))
end

-- Funktion für GetTargetWithID soll später mal alle 18 OnClick Funktionen abdecken. Fehlt: String to Object.
function BiteME:GetTargetWithID(...)
   	id = this:GetID()
	local frame = "BiteMe_InputBox" .. id
	--local frame2 = getGlobal("BiteMe_InputBox" .. id)
	--local frame3 = getObject(frame)
	--local frame4 = BiteMe:getObject(frame)
	--local frame5 = BiteMe:GetNamedObject(frame)
	--frame:Insert(UnitName("target"))
	SendChatMessage(frame, "WHISPER", nil, "Zipzap")

end

-- Funktion für den Button Send Setup. Sendet die Aufstellung an den Raidchat || RangedRechts muss neuen Namen bekommen
function BiteME:SendSetup()
	self:channel("Aufstellung Blood Queen")
	self:channel("Melees:")
	self:channel(format("Linke Seite: %s, %s, %s, %s, %s",BiteMe["Melee"]["Left"][1],BiteMe["Melee"]["Left"][2],BiteMe["Melee"]["Left"][3],BiteMe["Melee"]["Left"][4],BiteMe["Melee"]["Left"][5]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s, %s",BiteMe["Melee"]["Right"][1],BiteMe["Melee"]["Right"][2],BiteMe["Melee"]["Right"][3],BiteMe["Melee"]["Right"][4],BiteMe["Melee"]["Right"][5]))
	self:channel("Ranged:")
	self:channel(format("Linke Seite: %s, %s, %s, %s",BiteMe["Ranged"]["Left"][1],BiteMe["Ranged"]["Left"][2],BiteMe["Ranged"]["Left"][3],BiteMe["Ranged"]["Left"][4]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s",BiteMe["Ranged"]["Right"][1],BiteMe["Ranged"]["Right"][2],BiteMe["Ranged"]["Right"][3],BiteMe["Ranged"]["Right"][4]))
	self:channel(format("Verteiler bei den Melees ist %s",BiteMe["Melee"]["Left"][1]))
	self:channel(format("Verteiler bei den Ranged ist %s",BiteMe["Ranged"]["Left"][1]))
end

-- Funktion für den Button Send Melee Setup. 
function BiteME:SendMelee()
	self:channel("Melees:")
	self:channel(format("Linke Seite: %s, %s, %s, %s, %s",BiteMe["Left"][1],BiteMe["Left"][2],BiteMe["Left"][3],BiteMe["Left"][4],BiteMe["Left"][5]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s, %s",BiteMe["Right"][1],BiteMe["Right"][2],BiteMe["Right"][3],BiteMe["Right"][4],BiteMe["Right"][5]))
end

-- Funktion für den Button Send Ranged Setup.
function BiteME:SendRanged()
	self:channel("Ranged:")
	self:channel(format("Linke Seite: %s, %s, %s, %s",BiteMe["Ranged"]["Left"][1],BiteMe["Ranged"]["Left"][2],BiteMe["Ranged"]["Left"][3],BiteMe["Ranged"]["Left"][4]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s",BiteMe["Ranged"]["Right"][1],BiteMe["Ranged"]["Right"][2],BiteMe["Ranged"]["Right"][3],BiteMe["Ranged"]["Right"][4]))
end

-- Funktion für den Button SendData. Setter Funktionen für die BiteMe Tabelle
function BiteME:SendData()
	-- Melee Linke Seite  
   	if BiteMe_InputBox1:GetText() then    		
		BiteMe["Melee"]["Left"][1] = BiteMe_InputBox1:GetText()
	end
	if BiteMe_InputBox2:GetText() then
		BiteMe["Melee"]["Left"][2] = BiteMe_InputBox2:GetText()
	end
	if BiteMe_InputBox3:GetText() then
		BiteMe["Melee"]["Left"][3] = BiteMe_InputBox3:GetText()
	end
	if BiteMe_InputBox4:GetText() then
		BiteMe["Melee"]["Left"][4] = BiteMe_InputBox4:GetText()		
	end
	if BiteMe_InputBox5:GetText() then
		BiteMe["Melee"]["Left"][5] = BiteMe_InputBox5:GetText()
   	end
	-- Melee Rechte Seite  
   	if BiteMe_InputBox6:GetText() then
    	BiteMe["Melee"]["Right"][1] = BiteMe_InputBox6:GetText()
	end
   	if BiteMe_InputBox7:GetText() then
		BiteMe["Melee"]["Right"][2] = BiteMe_InputBox7:GetText()
	end
	if BiteMe_InputBox8:GetText() then
		BiteMe["Melee"]["Right"][3] = BiteMe_InputBox8:GetText()
	end
	if BiteMe_InputBox9:GetText() then
		BiteMe["Melee"]["Right"][4] = BiteMe_InputBox9:GetText()		
	end
	if BiteMe_InputBox10:GetText() then
		BiteMe["Melee"]["Right"][5] = BiteMe_InputBox10:GetText()
	end
	-- Ranged Linke Seite
	if BiteMe_InputBox11:GetText() then
		BiteMe["Ranged"]["Left"][1] = BiteMe_InputBox11:GetText()
	end
	if BiteMe_InputBox12:GetText() then
		BiteMe["Ranged"]["Left"][2] = BiteMe_InputBox12:GetText()
	end
	if BiteMe_InputBox13:GetText() then
		BiteMe["Ranged"]["Left"][3] = BiteMe_InputBox13:GetText()
	end
	if BiteMe_InputBox14:GetText() then
		BiteMe["Ranged"]["Left"][4] = BiteMe_InputBox14:GetText()
	end
	-- Ranged Rechte Seite
	if BiteMe_InputBox15:GetText() then
		BiteMe["Ranged"]["Right"][1] = BiteMe_InputBox15:GetText()
	end
	if BiteMe_InputBox16:GetText() then
		BiteMe["Ranged"]["Right"][2] = BiteMe_InputBox16:GetText()
	end
	if BiteMe_InputBox17:GetText() then
		BiteMe["Ranged"]["Right"][3] = BiteMe_InputBox17:GetText()
	end
	if BiteMe_InputBox18:GetText() then
		BiteMe["Ranged"]["Right"][4] = BiteMe_InputBox18:GetText()
	end
end

-- Interpreter der Slashbefehle2.
function BiteME:Toggle()
	local frame = getglobal("BiteMe")
	if frame then
		if frame:IsVisible() then
			frame:Hide()
		else
			frame:Show()
		end
	end
end

--  HELPER  ZEUGS
function BiteME:whisper(msg, name)
   if not (msg and name) then return end   
   SendChatMessage(Prefix..msg, "WHISPER", nil, name)
end

function BiteME:channel(msg)
	if msg then		
		SendChatMessage(msg, "OFFICER", nil)
	end	
end

local print,format = print,string.format
function BiteME:message(msg)
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