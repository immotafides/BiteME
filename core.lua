-- Einstellungen
local BiteMe = {}
BiteMe["Left"] = {
	"L1", --L1
	"L2", --L2
	"Knopf", --L3
	"L4",  --L4
	"L5"  --L5
}
BiteMe["Right"] = {
	"R1", --R1
	"R2", --R2
	"R3", --R3
	"R4", --R4
	"R5"  --R5
}
local RangedPlayer1 = "RP1"
local RangedPlayer2 = "RP2"
local Prefix = "BiteME: " -- Pröfix für z.B. die Whispers

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
BiteME:RegisterEvent("ADDON_LOADED")

function BiteME:Initialize()	
	self:UnregisterEvent("ADDON_LOADED")
	-- Slashcommands einbinden
	SLASH_BITEME1 = "/biteme"
	SLASH_BITEME2 = "/bm"
	SlashCmdList["BITEME"] = function(msg) self:SlashCommandHandler(msg)	end	
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
		if dstName ~= BiteMe["Left"][1] or dstName ~= BiteME["Right"][1] then
		self:message(format("%s ist kein Verteiler, suche nach anderen", dstName))
			for k,v in pairs(BiteMe["Left"]) do
				if v == dstName then
					self:message("links gefunden")
					table.remove(BiteMe["Left"], k)
					table.insert(BiteMe["Left"], 1 , v)
				end
			end
			for k,v in pairs(BiteME["Right"]) do
				if v == dstName then
					self:message("rechts gefunden")
					table.remove(BiteME["Right"],k)
					table.insert(BiteME["Right"],1,v)
				end
			end
		end		
		-- Ausgabezeugs
		
end

-- Funktion für den Button Send Setup. Sendet die Aufstellung an den Raidchat
function BiteME:OnClick(...)
	self:channel("Aufstellung Mes Blood Queen")
	self:channel(format("Linke Seite: %s, %s, %s, %s, %s",BiteMe["Left"][1],BiteMe["Left"][2],BiteMe["Left"][3],BiteMe["Left"][4],BiteMe["Left"][5]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s, %s",BiteMe["Right"][1],BiteMe["Right"][2],BiteMe["Right"][3],BiteMe["Right"][4],BiteMe["Right"][5]))
	self:channel(format("Verteiler bei den Mes ist %s",BiteMe["Left"][1]))
	self:channel(format("Verteiler bei den Ranged ist %s",RangedPlayer1))
end

-- Funktion für den Button SendData. Setter Funktionen für die BiteMe Tabelle
function BiteMe:SendData(...)
	-- Linke Seite  
   	if ImmotaFrames1_InputBox1:GetText() then    		
		BiteMe["Left"][1] = ImmotaFrames1_InputBox1:GetText()
	end
	if ImmotaFrames1_InputBox2:GetText() then
		BiteMe["Left"][2] = ImmotaFrames1_InputBox2:GetText()
	end
	if ImmotaFrames1_InputBox3:GetText() then
		BiteMe["Left"][3] = ImmotaFrames1_InputBox3:GetText()
	end
	if ImmotaFrames1_InputBox4:GetText() then
		BiteMe["Left"][4] = ImmotaFrames1_InputBox4:GetText()		
	end
	if ImmotaFrames1_InputBox5:GetText() then
		BiteMe["Left"][5] = ImmotaFrames1_InputBox5:GetText()
   	end
	-- Rechte Seite  
   	if ImmotaFrames1_InputBox6:GetText() then
    	BiteMe["Right"][1] = ImmotaFrames1_InputBox6:GetText()
	end
   	if ImmotaFrames1_InputBox7:GetText() then
		BiteMe["Right"][2] = ImmotaFrames1_InputBox7:GetText()
	end
	if ImmotaFrames1_InputBox8:GetText() then
		BiteMe["Right"][3] = ImmotaFrames1_InputBox8:GetText()
	end
	if ImmotaFrames1_InputBox9:GetText() then
		BiteMe["Right"][4] = ImmotaFrames1_InputBox9:GetText()		
	end
	if ImmotaFrames1_InputBox10:GetText() then
		BiteMe["Right"][5] = ImmotaFrames1_InputBox10:GetText()
	end
	-- Ranged
	if ImmotaFrames1_InputBox11:GetText() then
		RangedPlayer1 = ImmotaFrames1_InputBox11:GetText()
	end
	if ImmotaFrames1_InputBox12:GetText() then
		RangedPlayer2 = ImmotaFrames1_InputBox12:GetText()
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