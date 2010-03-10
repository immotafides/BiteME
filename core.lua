-- Einstellungen
local BiteMe = {}
BiteMe["Melee"] = {}
BiteMe["Melee"]["Left"] = {
	"ML1", --L1
	"ML2", --L2
	"ML3", --L3
	"ML4", --L4
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
	"RL5"  --RL5
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

-- funktionale Listen
local tmp = BiteMe
local Vamires = {}
local DeadVampires = {}
local NextTargets = {}
local CurrentTargets = {}

-- Kram zum tracken der Runden
local FrenziedPlayers = {} -- Tabelle in der die Spieler reingeschrieben werden
local lastFrenziedTimestamp = time() -- Zeitstempel zum resetten der Liste
local frenzied_delta = 20 -- Sekunden die zwischen den Frenzied Debuff maximal liegen dürfen
local round = 0
local numFrenzied = 2 ^ round -- Anzahl der aktuell zu erwartenden  Bisse

-- alle unsere Combatlog Daten
local timestamp, type, srcGUID, srcName, srcFlgs, dstGUID, dstName, dstFlgs, spellID, spellName

-- Frame bauen
local BiteME = CreateFrame("FRAME", "BiteME")

BiteME:SetScript("OnEvent",
	function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			timestamp, type, srcGUID, srcName, srcFlgs, dstGUID, dstName, dstFlgs = select(1, ...)
			--  AUREN    
			if type == "SELL_AURA_REMOVED" then
				spellID, spellName = select(9, ...)				
				if spellID == 70877 and not reordered then -- Frenzied Bloodthirsts
					self:AnnounceNextTargets()
				end
			elseif type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_APPLIED_DOSE" then
				spellID, spellName = select(9, ...)				
				if spellID == 71473 then
					if not reordered then -- Essence of the Blood Queen
						self:BiteReorder()
						self:SetNextTargets()
						self:AnnounceNextTargets()
					end
					table.insert(Vampires, dstName)
				elseif spellID == 70923 then -- Uncontrollable Frenzy
					self:SomeoneDied() -- kommt aufs Gleiche raus :)
					self:AnnounceNextTargets()
				end
			elseif type == "UNIT_DIED" then
				self:SomeoneDied()
			end
		elseif event:sub(1,12) == "ZONE_CHANGED" then
			--self:message(format("Zone changed to %q",GetSubZoneText()))
			self:Reset() -- wir mißbrauchen das Event zum resetten
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

-- Handler der Slashbefehle
function BiteME:SlashCommandHandler(arg)
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

-- Funktion zum Resetten der Listen
function BiteME:Reset()
	-- niemand wird gebissen
	BittenPlayers = wipe(BittenPlayers)
	-- Liste wurde noch nicht sortiert
	reordered = false	
end

function BiteME:BiteReorder()
	-- Arbeitsliste
	tmp = BiteMe
	-- Flag setzen
	reordered = true
	-- Ist der erste gebissene kein Verteiler? Dann verändern wir die Reihenfolgen
	if  dstName ~= tmp["Melee"]["Left"][1] or dstName ~= tmp["Melee"]["Right"][1] or dstName ~= tmp["Ranged"]["Left"][1] or dstName ~= tmp["Ranged"]["Right"][1] then
		self:message(format("%s ist kein Verteiler, suche nach anderen", dstName))
		-- Melees links
		for k,v in pairs(tmp["Melee"]["Left"]) do
			if v == dstName then					
				table.remove(tmp["Melee"]["Left"], k)
				table.insert(tmp["Melee"]["Left"], 1 , v)				
			end
		end
		-- Melees rechts
		for k,v in pairs(tmp["Melee"]["Right"]) do
			if v == dstName then					
				table.remove(tmp["Melee"]["Right"],k)
				table.insert(tmp["Melee"]["Right"],1,v)				
			end
		end
		-- Ranged links
		for k,v in pairs(tmp["Ranged"]["Left"]) do
			if v == dstName then
				tmp["Ranged"]["Left"][k] = tmp["Ranged"]["Left"][1]
				tmp["Ranged"]["Left"][1] = dstName				
			end
		end
		-- Ranged rechts
		for k,v in pairs(tmp["Ranged"]["Right"]) do
			if v == dstName then
				tmp["Ranged"]["Right"][k] = tmp["Ranged"]["Right"][1]
				tmp["Ranged"]["Right"][1] = dstName				
			end
		end
	end	
end

-- Funktion für die wirkliche Bissreihenfolge
function BiteME:SetNextTargets()
	-- Linker Melee Verteiler zuerst gebissen
	if dstName == tmp["Melee"]["Left"][1] then
		-- Ziele setzen
		NextTargets[tmp["Melee"]["Left"][1]] = {
			tmp["Ranged"]["Left"][1],
			tmp["Melee"]["Right"][1]
		}
		NextTargets[tmp["Melee"]["Right"][1]] = {
			nil,
			nil
		}
	-- Rechter Melee Verteiler zuerst gebissen
	elseif dstName == tmp["Melee"]["Right"][1] then
		-- Ziele setzen
		NextTargets[tmp["Melee"]["Left"][1]] = {
			nil,
			nil
		}
		NextTargets[tmp["Melee"]["Right"][1]] = {
			tmp["Ranged"]["Left"][1],
			tmp["Melee"]["Left"][1]
		}
	-- Ein Ranged hat den ersten Biss bekommen
	else
		NextTargets[tmp["Melee"]["Left"][1]] = {
			nil,
			nil
		}
		NextTargets[tmp["Melee"]["Right"][1]] = {
			nil,
			nil
		}
	end
	-- die letzten beiden Bisse noch
	table.insert(NextTargets[tmp["Melee"]["Left"][1]],3,tmp["Melee"]["Left"][2])
	table.insert(NextTargets[tmp["Melee"]["Left"][1]],4,tmp["Melee"]["Left"][4])
	table.insert(NextTargets[tmp["Melee"]["Right"][1]],3,tmp["Melee"]["Right"][2])
	table.insert(NextTargets[tmp["Melee"]["Right"][1]],4,tmp["Melee"]["Right"][4])
	
	-- das Ganze nochmal für die Ranged Verteiler	
	-- Linker Ranged Verteiler zuerst gebissen
	if dstName == tmp["Ranged"]["Left"][1] then
		-- Ziele setzen
		NextTargets[tmp["Ranged"]["Left"][1]] = {
			tmp["Melee"]["Left"][1],
			tmp["Ranged"]["Right"][1]
		}
		NextTargets[tmp["Ranged"]["Right"][1]] = {
			nil,
			nil
		}
	-- Rechter Ranged Verteiler zuerst gebissen
	elseif dstName == tmp["Ranged"]["Right"][1] then
		-- Ziele setzen
		NextTargets[tmp["Ranged"]["Left"][1]] = {
			nil,
			nil
		}
		NextTargets[tmp["Ranged"]["Right"][1]] = {
			tmp["Melee"]["Left"][1],
			tmp["Ranged"]["Left"][1]
		}
	-- Ein Ranged hat den ersten Biss bekommen
	else
		NextTargets[tmp["Ranged"]["Left"][1]] = {
			nil,
			nil
		}
		NextTargets[tmp["Ranged"]["Right"][1]] = {
			nil,
			nil
		}
	end
	-- die letzten beiden Bisse noch
	table.insert(NextTargets[tmp["Ranged"]["Left"][1]],3,tmp["Ranged"]["Left"][3])
	table.insert(NextTargets[tmp["Ranged"]["Left"][1]],4,tmp["Ranged"]["Left"][2])
	table.insert(NextTargets[tmp["Ranged"]["Right"][1]],3,tmp["Ranged"]["Right"][3])
	table.insert(NextTargets[tmp["Ranged"]["Right"][1]],4,tmp["Ranged"]["Right"][2])
	
	-- und die restlichen  Bisse
	NextTargets[tmp["Melee"]["Left"][2]] =  {nil, nil, nil, tmp["Melee"]["Left"][1]}
	NextTargets[tmp["Melee"]["Left"][3]] =  {nil, nil, nil, nil}
	NextTargets[tmp["Melee"]["Left"][4]] =  {nil, nil, nil, nil}
	
	NextTargets[tmp["Melee"]["Right"][2]] = {nil, nil, nil, tmp["Melee"]["Right"][1]}
	NextTargets[tmp["Melee"]["Right"][3]] = {nil, nil, nil, nil}
	NextTargets[tmp["Melee"]["Right"][4]] = {nil, nil, nil, nil}
	
	NextTargets[tmp["Ranged"]["Left"][2]] =  {nil, nil, nil, nil}
	NextTargets[tmp["Ranged"]["Left"][3]] =  {nil, nil, nil, tmp["Ranged"]["Left"][4]}
	NextTargets[tmp["Ranged"]["Left"][4]] =  {nil, nil, nil, nil}
	
	NextTargets[tmp["Ranged"]["Right"][2]] = {nil, nil, nil, nil}
	NextTargets[tmp["Ranged"]["Right"][3]] = {nil, nil, nil, tmp["Ranged"]["Right"][4]}
	NextTargets[tmp["Ranged"]["Right"][4]] = {nil, nil, nil, nil}
end

function BiteME:AnnounceNextTargets()
	-- Reset der Beacons
	if #FrenziedVampires > numFrenzied - #DeadVampires or difftime(time(),lastFrenziedTimestamp) > frenzied_delta then
		FrenziedVampires = wipe(FrenziedVampires)
		round = round + 1
		numFrenzied = 2 ^ round
	end	
	-- Zeit setzen
	lastFrenziedTimestamp = time()
	-- Die Tabelle der Reihenfolge mit Namen der Spieler befüllen		
	table.insert(FrenziedVampires, dstName)
	-- sobald wir alle Beacons gesammelt haben
	if #FrenziedVampires == numFrenzied then
		-- wir löschen alle Raidicons aus der Runde davor
		for _,target in pairs(CurrentTargets) do
			SetRaidTarget(target,0)
		end
		-- löschen die Tabelle
		CurrentTargets = wipe(CurrentTargets)
		-- und füllen Sie neu
		for name,targets in pairs(NextTargets) do
			if #targets then
				if targets[1] ~= nil then
					CurrentTargets[name] = targets[1]
				end
				table.remove(NextTargets[k][1])
			end
		end
		-- whispern die neuen Targets und setzen die Raidicons
		local n = 0
		for name,target in pairs(CurrentTargets) do
			n = n + 1 -- Index
			SetRaidTarget(target,n)
			self:whisper(format("nächstes Ziel ist {rt%u}%s",n,target),name)
		end
	end
end

function BiteME:SomeoneDied()
	for i,name in pairs(Vampires) do
		if name == dstname then
			table.remove(Vampires,i)
			table.insert(DeadVampires,name)
		end
	end
end

-- Funktion für den Button Send Setup. Sendet die Aufstellung an den Raidchat || RangedRechts muss neuen Namen bekommen
function BiteME:SendSetup()
	self:channel("Aufstellung Blood Queen")
	self:SendMelee()
	self:SendRanged()
	self:channel(format("Verteiler bei den Melees ist %q",tmp["Melee"]["Left"][1]))
	self:channel(format("Verteiler bei den Ranged ist %q",tmp["Ranged"]["Left"][1]))
end

-- Funktion für den Button Send Melee Setup. 
function BiteME:SendMelee()
	self:channel("*** Melees ***")
	self:channel(format("Linke Seite: %s, %s, %s, %s, %s",tmp["Melee"]["Left"][1],tmp["Melee"]["Left"][2],tmp["Melee"]["Left"][3],tmp["Melee"]["Left"][4],tmp["Melee"]["Left"][5]))
	self:channel(format("Rechte Seite: %s, %s, %s, %s, %s",tmp["Melee"]["Right"][1],tmp["Melee"]["Right"][2],tmp["Melee"]["Right"][3],tmp["Melee"]["Right"][4],tmp["Melee"]["Right"][5]))
end

-- Funktion für den Button Send Ranged Setup.
function BiteME:SendRanged()
	self:channel("*** Ranged ***")
	self:channel(format("Linke Seite: %s (Verteiler), %s (oben), %s (mitte), %s (unten)",tmp["Ranged"]["Left"][1],tmp["Ranged"]["Left"][2],tmp["Ranged"]["Left"][3],tmp["Ranged"]["Left"][4]))
	self:channel(format("Rechte Seite: %s (Verteiler), %s (oben), %s (mitte), %s (unten)",tmp["Ranged"]["Right"][1],tmp["Ranged"]["Right"][2],tmp["Ranged"]["Right"][3],tmp["Ranged"]["Right"][4]))
end

-- GUI Helper Funktionen
-- Frame toggle
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

-- Funktion für GetTargetWithID
function BiteME:GetTargetWithID(...)
	if UnitName("target") then
		local editbox = getglobal("BiteMe_InputBox"..this:GetID())
		editbox:SetText(UnitName("target"))
		editbox:SetFocus()
	end
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