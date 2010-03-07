-- Tabellen für die Aufstellung
	BiteMe = {}
	BiteMe["Left"] = {
		"L1", --L1
		"L2", --L2
		"L3", --L3
		"L4", --L4
		"L5"  --L5
	}


	BiteMe["Right"] = {
		"R1", --R1
		"R2", --R2
		"R3", --R3
		"R4", --R4
		"R5"  --R5
	}

-- variablen für die beiden Verteiler der Ranged
	local RangedPlayer1 = "RP1" -- 1. Verteiler der Ranged
	local RangedPlayer2 = "RP2" -- 2. Verteiler der Ranged

-- Ausgabe in Statustext
	function out(msg)
 		DEFAULT_CHAT_FRAME:AddMessage(msg)
 		UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0, 1, 10) 
	end

-- Ausgabe im OffiChat
	function out2offichat(msg)
		if msg then		
			SendChatMessage(msg, "OFFICER", nil)
		end	
	end

-- Ausgabe im Raidchat
	function out2ra(msg)
		if msg then		
			SendChatMessage(msg, "RAID", nil)
		end	
	end

-- Ausgabe im Testchannel, geht bisher nicht
	function out2test(msg)
		if msg then		
			SendChatMessage(msg , "CHANNEL", nil, "Immotatest")
		end	
	end

-- GUI Aufrufen mit /if [n]. Bsp: /if 1 für BiteMELEE
	function ImmotaFrames_OnLoad()
  		out("ImmotaFrames: OnLoad");
  		
		SLASH_IMMOTAFRAMES1 = "/immotaframes";
  		SLASH_IMMOTAFRAMES2 = "/if";
  		
		SlashCmdList["IMMOTAFRAMES"] = function(msg)
		ImmotaFrames_SlashCommandHandler(msg);
		end
	end

-- Funktion für den Button Send Setup. Sendet die Aufstellung an den Raidchat
function ImmotaFrames_OnClick(arg1)
	id = this:GetID()
	out("ImmotaFrames: OnClick: " .. this:GetName() .. " ,ID: " .. id .. " ,Button:" ..arg1)
	out2ra("Aufstellung Melees Blood Queen")
	out2ra("Linke Seite: " .. BiteMe["Left"][1].. ", " .. BiteMe["Left"][2] .. ", ".. BiteMe["Left"][3] .. ", " .. BiteMe["Left"][4].. ", " .. BiteMe["Left"][5])
	out2ra("Rechte Seite: " .. BiteMe["Right"][1].. ", " .. BiteMe["Right"][2] .. ", ".. BiteMe["Right"][3] .. ", " .. BiteMe["Right"][4].. ", " .. BiteMe["Right"][5])
	out2ra("Verteiler bei den Melees ist " .. BiteMe["Left"][1])
	out2ra("Verteiler bei den Ranged ist " .. RangedPlayer1)
	-- out2ra("-->  Hallo Karla :)")
end

-- Funktion für den Button SendData. Sendet die Daten in den Editboxen an die Lua
	function ImmotaFrames_SendData(arg1)
   		id = this:GetID()
   		out("ImmotaFrames: SendData: " .. this:GetName() .. " ,ID: " .. id .. " ,Button:" ..arg1)
-- Linke Seite  
   		if (ImmotaFrames1_InputBox1:GetText()) then
    		out("ImmotaFrames: InputBox1 : " .. ImmotaFrames1_InputBox1:GetText())
		BiteMe["Left"][1] = ImmotaFrames1_InputBox1:GetText()
		end
   		
		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Left"][2] = ImmotaFrames1_InputBox2:GetText()
		end

   		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Left"][3] = ImmotaFrames1_InputBox3:GetText()
		end

   		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Left"][4] = ImmotaFrames1_InputBox4:GetText()		
		end

   		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Left"][5] = ImmotaFrames1_InputBox5:GetText()
   		end

-- Linke Seite  
   		if (ImmotaFrames1_InputBox1:GetText()) then
    		out("ImmotaFrames: InputBox6 : " .. ImmotaFrames1_InputBox6:GetText())
		BiteMe["Right"][1] = ImmotaFrames1_InputBox6:GetText()
		end
   		
		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Right"][2] = ImmotaFrames1_InputBox7:GetText()
		end

   		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Right"][3] = ImmotaFrames1_InputBox8:GetText()
		end

   		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Right"][4] = ImmotaFrames1_InputBox9:GetText()		
		end

   		if (ImmotaFrames1_InputBox1:GetText()) then
		BiteMe["Right"][5] = ImmotaFrames1_InputBox10:GetText()
   		end
-- Ranged
   		if (ImmotaFrames1_InputBox11:GetText()) then
    		out("ImmotaFrames: InputBox11 : " .. ImmotaFrames1_InputBox11:GetText())
		RangedPlayer1 = ImmotaFrames1_InputBox11:GetText()
		end
   		
		if (ImmotaFrames1_InputBox12:GetText()) then
		RangedPlayer2 = ImmotaFrames1_InputBox12:GetText()
		end

	end

-- Interpreter der Slashbefehle, hier 0 = reload ui
	function ImmotaFrames_SlashCommandHandler(msg)
   		out("ImmotaFrames: " .. msg)
		
		if (msg == "0") then
	 	ReloadUI();
		end
 	ImmotaFrames_Toggle(msg);
	end


-- Interpreter der Slashbefehle2. Spricht die einzelnen Frames über deren Nummer an
	function ImmotaFrames_Toggle(num)
   		local frame = getglobal("ImmotaFrames" .. num)
   		if (frame) then
   			if(  frame:IsVisible() ) then
      				frame:Hide();
   			else
      				frame:Show();
   			end
  		 end
	end
