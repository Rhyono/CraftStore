local CS = CraftStoreFixedAndImprovedLongClassName
function CS.STYLE()
  local self = {}
  --                   Axe    Belt    Boot    Bow     Chest   Dager   Glove   Head    Legs    Mace    Shield  Shoul   Staves  Swords
  --                   1      2       3       4       5       6       7       8       9       10      11      12      13      14  
  local itemHeavy =   {43532, 43542,  43538,  43549,  43537,  43535,  43539,  43562,  43540,  43533,  43556,  43541,  43557,  43534} --Heavy Armor cp160
  local itemMedium =  {43532, 43555,  43551,  43549,  43550,  43535,  43552,  43563,  43553,  43533,  43556,  43554,  43557,  43534} --Medium Armor cp160
  local itemRobe =    {43532, 43548,  43544,  43549,  43543,  43535,  43545,  43564,  43546,  43533,  43556,  43547,  43557,  43534} --Light Armor Robe cp160
  local itemJack =    {43532, 43548,  43544,  43549,  44241,  43535,  43545,  43564,  43546,  43533,  43556,  43547,  43557,  43534} --Light Armor Jack cp160
  local previewItems = {itemHeavy, itemMedium, itemRobe, itemJack}
  local item = itemHeavy
  
  local styles = { -- type, achievement id, first motif id, visual id
    [ 1] = {1,1025,16425}, -- Breton
    [ 2] = {1,1025,16427}, -- Redguard
    [ 3] = {1,1025,16426}, -- Orc
    [ 4] = {1,1025,27245}, -- Dark Elf
    [ 5] = {1,1025,27244}, -- Nord
    [ 6] = {1,1025,27246}, -- Argonian
    [ 7] = {1,1025,16424}, -- High Elf
    [ 8] = {1,1025,16428}, -- Wood Elf
    [ 9] = {1,1025,44698}, -- Khajiit
    [11] = {2,1423,74556}, -- Thieves Guild
    [12] = {2,1661,82055}, -- Dark Brotherhood
    [13] = {2,1412,71567}, -- Malacath
    [14] = {2,1144,57573}, -- Dwemer
    [15] = {1,1025,51638}, -- Ancient Elf
    [16] = {2,1660,82088}, -- Order of the Hour 
    [17] = {1,1025,51565}, -- Barbaric
    [19] = {1,1025,51345}, -- Primal
    [20] = {1,1025,51688}, -- Daedric
    [21] = {2,1411,71551}, -- Trinimac
    [22] = {2,1341,69528}, -- Ancient Orc
    [23] = {2,1416,71705}, -- Daggerfall Covenant
    [24] = {2,1414,71721}, -- Ebonheart Pact
    [25] = {2,1415,71689}, -- Aldmeri Dominion
    [26] = {2,1348,64716}, -- Mercenary
    [27] = {2,1714,82007}, -- Celestial
    [28] = {2,1319,64670}, -- Glass
    [29] = {2,1181,57835}, -- Xivkyn
    [30] = {1,1418,71765}, -- Soul Shriven
    [31] = {2,1715,76895}, -- Draugr
    [33] = {2,1318,57591}, -- Akaviri
    [34] = {1,1025,54868}, -- Imperial
    [35] = {2,1713,57606}, -- Yokudan
	[38] = {3,0,132532}, -- Tsaesci
    [39] = {2,1662,82072}, -- Minotaur
    [40] = {2,1798,75229}, --Ebony
    [41] = {2,1422,74540}, -- Abah's Watch
    [42] = {2,1676,73855}, -- Skinchanger
	[43] = {2,1933,73839}, -- Morag Tong
    [44] = {2,1797,71673}, -- Ra Gada
    [45] = {2,1659,74653}, -- Dro-m'Athra
    [46] = {2,1424,76879}, -- Assassin's League
    [47] = {2,1417,71523}, -- Outlaw
	[48] = {2,2022,130011}, -- Redoran
	[49] = {2,2021,129995}, -- Hlaalu
	[50] = {2,1935,121349}, -- Militant Ordinator
	[51] = {2,2023,121333}, -- Telvanni
	[52] = {2,1934,121317}, -- Buoyant Armiger
    [53] = {3,0,96954}, -- Frostcaster
	[54] = {2,1932,124680}, -- Ashlander
	[55] = {2,2120,134740}, -- Worm Cult
	[56] = {2,1796,114968}, --Silken Ring
	[57] = {2,1795,114952}, --Mazzatun
	[58] = {3,0,82053}, -- Grim Harlequin
	[59] = {2,1545,82023}, -- Hollowjack
	[60] = {2,2024,130027}, -- Refabricated
	[61] = {2,2098,132534}, -- Bloodforge
	[62] = {2,2097,132566}, -- Dreadhorn
	[65] = {2,2044,132550}, -- Apostle
	[66] = {2,2045,132582}, -- Ebonshadow
	[69] = {2,2190,134756}, -- Fang Lair
	[70] = {2,2189,134772}, -- Scalecaller
	[71] = {2,2186,137852}, -- Psijic Order
	[72] = {2,2187,137921}, -- Sapiarch
	[73] = {2,2319,140497}, -- Welkynar
	[74] = {2,2188,140445}, -- Dremora
	[75] = {2,2285,140429}, -- Pyandonean
	[77] = {2,2317,140463}, -- Huntsman
	[78] = {2,2318,140479}, -- Silver Dawn
	[79] = {2,2360,142203}, -- Dead-Water
	[80] = {2,2359,142187}, -- Honor Guard
	[81] = {2,2361,142219}, -- Elder Argonian
	[82] = {2,2503,147667}, -- Coldsnap
	[83] = {2,2504,147683}, -- Meridian
	[84] = {2,2505,147699}, -- Anequina
	[85] = {2,2506,147715}, -- Pellitine
	[86] = {2,2507,147731}, -- Sunspire
	[89] = {2,2629,156574}, -- Stags of Z'en
	[92] = {2,2630,156556}, -- Dragonguard
	[93] = {2,2628,156591}, -- Moongrave Fane
	[94] = {2,2748,156609}, -- New Moon	
	[95] = {2,2750,156628}, -- Shield of Senchal	
	[97] = {2,2747,157518}, -- Icereach Coven
	[98] = {2,2749,158292}, -- Pyre Watch
	--[99] = {2,?,?}, -- Swordthane
	[100] = {2,2757,160494}, -- Blackreach Vanguard
	[101] = {2,2761,160543}, -- Greymoor
	[102] = {2,2762,160560}, -- Sea Giant
	[103] = {2,2763,160577}, -- Ancestral Nord
	[104] = {2,2773,160594}, -- Ancestral High Elf
	[105] = {2,2776,160611}, -- Ancestral Orc
	[106] = {2,2849,166973}, -- Thorn Legion
	[107] = {2,2850,166990}, -- Hazardous Alchemy
	[108] = {2,2903,167174}, -- Ancestral Akaviri
	[110] = {2,2905,167271}, -- Ancestral Reach
	[111] = {2,2926,167944}, -- Nighthollow
	[112] = {2,2938,167961}, -- Arkthzand Armory
	[113] = {2,2998,167978}, -- Wayward Guardian
	[114] = {2,2959,170132}, -- House Hexos
	--[115] = {2,?,?}, -- Deadlands Gladiator
	[116] = {2,2984,171552}, -- True-Sworn
	[117] = {2,2991,171581}, -- Waking Flame
	--[118] = {2,?,?}, -- Dremora Kynreeve
	[119] = {2,2999,171859}, -- Ancient Daedric
	[120] = {2,3000,171879}, -- Black Fin Legion
	[121] = {2,3001,171896}, -- Ivory Brigade
	[122] = {2,3002,171913}, -- Sul-Xan
	[123] = {2,3094,176058}, -- Crimson Oath
	[124] = {2,3097,178505}, -- Silver Rose
	[125] = {2,3098,178529}, -- Annihilarch's Chosen
	[126] = {2,3220,178707}, -- Fargrave Guardian
  }
  --|H1:item:96954:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
  
  local style_map = { -- book, first chapter, crown book, first crown chapter
    [ 1] = {16425 , 0     , 64541 , 0}, -- Breton
    [ 2] = {16427 , 0     , 64543 , 0}, -- Redguard
    [ 3] = {16426 , 0     , 64542 , 0}, -- Orc
    [ 4] = {27245 , 0     , 64546 , 0}, -- Dark Elf
    [ 5] = {27244 , 0     , 64545 , 0}, -- Nord
    [ 6] = {27246 , 0     , 64547 , 0}, -- Argonian
    [ 7] = {16424 , 0     , 64540 , 0}, -- High Elf
    [ 8] = {16428 , 0     , 64544 , 0}, -- Wood Elf
    [ 9] = {44698 , 0     , 64548 , 0}, -- Khajiit
    [11] = {74555 , 74556 , 74570 , 0}, -- Thieves Guild
    [12] = {82054 , 82055 , 82069 , 0}, -- Dark Brotherhood
    [13] = {71566 , 71567 , 71581 , 0}, -- Malacath
    [14] = {57572 , 57573 , 64553 , 0}, -- Dwemer
    [15] = {51638 , 0     , 64551 , 0}, -- Ancient Elf
    [16] = {82087 , 82088 , 82102 , 0}, -- Order of the Hour 
    [17] = {51565 , 0     , 64550 , 0}, -- Barbaric
    [19] = {51345 , 0     , 64549 , 0}, -- Primal
    [20] = {51688 , 0     , 64552 , 0}, -- Daedric
    [21] = {71550 , 71551 , 71565 , 0}, -- Trinimac
    [22] = {69527 , 69528 , 69542 , 0}, -- Ancient Orc
    [23] = {71704 , 71705 , 71719 , 0}, -- Daggerfall Covenant
    [24] = {71720 , 71721 , 71735 , 0}, -- Ebonheart Pact
    [25] = {71688 , 71689 , 71703 , 0}, -- Aldmeri Dominion
    [26] = {64715 , 64716 , 64730 , 0}, -- Mercenary
    [27] = {82006 , 82007 , 82021 , 0}, -- Celestial
    [28] = {64669 , 64670 , 64684 , 0}, -- Glass
    [29] = {57834 , 57835 , 64556 , 0}, -- Xivkyn
    [30] = {71765 , 0     , 0     , 0}, -- Soul Shriven
    [31] = {76894 , 76895 , 76909 , 0}, -- Draugr
    [33] = {57590 , 57591 , 64554 , 0}, -- Akaviri
    [34] = {54868 , 0     , 64559 , 0}, -- Imperial
    [35] = {57605 , 57606 , 64555 , 0}, -- Yokudan
	[38] = {0     , 0     , 132532, 0}, -- Tsaesci
    [39] = {82071 , 82072 , 82086 , 0}, -- Minotaur
    [40] = {75228 , 75229 , 75243 , 0}, --Ebony
    [41] = {74539 , 74540 , 74554 , 0}, -- Abah's Watch
    [42] = {73854 , 73855 , 73869 , 0}, -- Skinchanger
	[43] = {73838 , 73839 , 73853 , 0}, -- Morag Tong
    [44] = {71672 , 71673 , 71687 , 0}, -- Ra Gada
    [45] = {74652 , 74653 , 74667 , 0}, -- Dro-m'Athra
    [46] = {76878 , 76879 , 76893 , 0}, -- Assassin's League
    [47] = {71522 , 71523 , 71537 , 0}, -- Outlaw
	[48] = {130010, 130011, 130025, 0}, -- Redoran
	[49] = {129994, 129995, 130009, 0}, -- Hlaalu
	[50] = {121348, 121349, 121363, 0}, -- Militant Ordinator
	[51] = {121332, 121333, 121347, 0}, -- Telvanni
	[52] = {121316, 121317, 121331, 0}, -- Buoyant Armiger
    [53] = {0     , 0     , 96954 , 0}, -- Frostcaster
	[54] = {124679, 124680, 124694, 0}, -- Ashlander
	[55] = {134739, 134740, 134754, 0}, -- Worm Cult
	[56] = {114967, 114968, 114982, 0}, --Silken Ring
	[57] = {114951, 114952, 114966, 0}, --Mazzatun
	[58] = {82038 , 82039 , 82053 , 0}, -- Grim Harlequin
	[59] = {82022 , 82023 , 82037 , 82103 }, -- Hollowjack
	[60] = {130026, 130027, 130041, 0}, -- Refabricated
	[61] = {132533, 132534, 132548, 0}, -- Bloodforge
	[62] = {132565, 132566, 132580, 0}, -- Dreadhorn
	[65] = {132549, 132550, 132564, 0}, -- Apostle
	[66] = {132581, 132582, 132596, 0}, -- Ebonshadow
	[69] = {134755, 134756, 134770, 0}, -- Fang Lair
	[70] = {134771, 134772, 134786, 0}, -- Scalecaller
	[71] = {137851, 137852, 137866, 0}, -- Psijic Order
	[72] = {137920, 137921, 137935, 0}, -- Sapiarch
	[73] = {140496, 140497, 140511, 0}, -- Welkynar
	[74] = {140444, 140445, 140459, 0}, -- Dremora
	[75] = {140428, 140429, 139055, 140268}, -- Pyandonean
	[77] = {140462, 140463, 140477, 0}, -- Huntsman
	[78] = {140478, 140479, 140493, 0}, -- Silver Dawn
	[79] = {142202, 142203, 142217, 0}, -- Dead-Water
	[80] = {142186, 142187, 142201, 0}, -- Honor Guard
	[81] = {142218, 142219, 142233, 0}, -- Elder Argonian
	[82] = {147666, 147667, 147681, 0}, -- Coldsnap
	[83] = {147682, 147683, 147697, 0}, -- Meridian
	[84] = {147698, 147699, 147713, 0}, -- Anequina
	[85] = {147714, 147715, 147729, 0}, -- Pellitine
	[86] = {147730, 147731, 147745, 0}, -- Sunspire
	[89] = {156573, 156574, 156588, 0}, -- Stags of Z'en
	[92] = {156555, 156556, 156570, 0}, -- Dragonguard
	[93] = {156590, 156591, 156605, 0}, -- Moongrave Fane
	[94] = {156608, 156609, 156623, 0}, -- New Moon
	[95] = {156627, 156628, 156642, 0}, -- Shield of Senchal
	[97] = {157517, 157518, 157532, 0}, -- Icereach Coven
	[98] = {158291, 158292, 158306, 0}, -- Pyre Watch
	[100] = {160493, 160494, 160508, 0}, -- Blackreach Vanguard
	[101] = {160542, 160543, 160557, 0}, -- Greymoor
	[102] = {160559, 160560, 160574, 0}, -- Sea Giant
	[103] = {160576, 160577, 160591, 0}, -- Ancestral Nord
	[104] = {160593, 160594, 160608, 0}, -- Ancestral High Elf
	[105] = {160610, 160611, 160625, 0}, -- Ancestral Orc
	[106] = {166972, 166973, 166987, 0}, -- Thorn Legion
	[107] = {166989, 166990, 167004, 0}, -- Hazardous Alchemy
	[108] = {0     , 167174, 0     , 0}, -- Ancestral Akaviri
	[110] = {167270, 167271, 167285, 0}, -- Ancestral Reach
	[111] = {167943, 167944, 167958, 0}, -- Nighthollow
	[112] = {167960, 167961, 167975, 0}, -- Arkthzand Armory
	[113] = {167977, 167978, 167992, 0}, -- Wayward Guardian
	[114] = {170131, 170132, 170146, 0}, -- House Hexos
	--[115] = {X-1, X, X+14, 0}, -- Deadlands Gladiator
	[116] = {171551, 171552, 171566, 0}, -- True-Sworn
	[117] = {171580, 171581, 171595, 0}, -- Waking Flame
	--[118] = {X-1, X, X+14, 0}, -- Dremora Kynreeve
	[119] = {171858, 171859, 171873, 0}, -- Ancient Daedric
	[120] = {171878, 171879, 171893, 0}, -- Black Fin Legion
	[121] = {171895, 171896, 171910, 0}, -- Ivory Brigade
	[122] = {171912, 171913, 171927, 0}, -- Sul-Xan
	[123] = {176057, 176058, 176072, 0}, -- Crimson Oath
	[124] = {178504, 178505, 178519, 0}, -- Silver Rose
	[125] = {178528, 178529, 178543, 0}, -- Annihilarch's Chosen
	[126] = {178706, 178707, 178721, 0}, -- Fargrave Guardian
	}
  
	--build visual motif number list
	for style,data in pairs(styles) do
		local styleName = GetItemLinkName(('|H1:item:%u:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(styles[style][3]))
		local styleVisualId = styleName:match("%d+")
		styles[style][4] = styleVisualId ~= nil and styleVisualId or 0 
	end
  
	--build flattened complete style list
	function self.CompileStyles()
		CS.Styles.list = {}
		for style,data in pairs(style_map) do
			-- book
			if data[1] ~= 0 then
				table.insert(CS.Styles.list,data[1])
			end
			-- chapters
			if data[2] ~= 0 then
				for chapter = 0, 13 do
					table.insert(CS.Styles.list,data[2]+chapter)
				end
			end
			-- crown book
			if data[3] ~= 0 then
				table.insert(CS.Styles.list,data[3])
			end
			-- crown chapters
			if data[4] ~= 0 then
				for chapter = 0, 13 do
					table.insert(CS.Styles.list,data[4]+chapter)
				end
			end			
		end
	end
	
	--build flattened style list with exclusions
	function self.CompilePartialStyles(excludedStyles)
		CS.Styles.oldlist = {}
		for style,data in pairs(style_map) do
			-- skip over exluded
			if excludedStyles[style] == nil then
				-- book
				if data[1] ~= 0 then
					table.insert(CS.Styles.oldlist,data[1])
				end
				-- chapters
				if data[2] ~= 0 then
					for chapter = 0, 13 do
						table.insert(CS.Styles.oldlist,data[2]+chapter)
					end
				end
				-- crown book
				if data[3] ~= 0 then
					table.insert(CS.Styles.oldlist,data[3])
				end
				-- crown chapters
				if data[4] ~= 0 then
					for chapter = 0, 13 do
						table.insert(CS.Styles.oldlist,data[4]+chapter)
					end
				end	
			end		
		end
	end	

	function self.StyleMotifNumber(style)
		if styles[style][4] ~= nil then
			return styles[style][4]
		end
		return 0
	end
  
	function self.IsSimpleStyle(style)
		if not styles[style] then return false end
		if styles[style][1] == 1 then return true end
		return false
	end
  
	function self.IsCrownStyle(style)
		if not styles[style] then return false end
		if styles[style][1] == 3 then return true end
		return false
	end
  
	function self.StyleBookId(style)
		if not styles[style] then return false end
		if self.IsSimpleStyle(style) or self.IsCrownStyle(style) then
			return styles[style][3]
		else 
			return (styles[style][3]-1)
		end	
	end

	function self.IsPerfectedStyle(style)
		if not styles[style] then return false end
		if CS.SelectedPlayer == CS.CurrentPlayer then
		if self.IsSimpleStyle(style) then
			return IsSmithingStyleKnown(style)
		else 
			if self.IsCrownStyle(style) then
				return IsItemLinkBookKnown(('|H1:item:%u:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(styles[style][3]))
			else      
				for chapter = 1,14 do
					local known = self.IsKnownStyle(style,chapter)
					if not known then return false end
				end
			return true
			end
		end
		else
			local result = true
			for chapter = 1,14 do
				result = result and CS.Data.style.knowledge[CS.SelectedPlayer][CS.Style.GetChapterId(style,chapter)]
			end
			return result
		end
		return false
	end

	function self.IsKnownStyle(style,chapter)
		if not styles[style] then return false end
		if self.IsSimpleStyle(style) then
			return IsSmithingStyleKnown(style)
		else 
			if self.IsCrownStyle(style) then
				return IsItemLinkBookKnown(('|H1:item:%u:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(styles[style][3]))
			else  
				local categoryIndex, collectionIndex = self.GetLoreBookIndicesForStyle(style)
				local _, _, known = GetLoreBookInfo(categoryIndex, collectionIndex, chapter)
				return known
			end
		end
		return false
	end
	
	function self.GetLoreBookIndicesForStyle(style)
		local achievementId = styles[style][2]
		local collectionId = GetAchievementLinkedBookCollectionId(achievementId)
		return GetLoreBookCollectionIndicesFromCollectionId(collectionId)
	end
  
	function self.UpdatePreview(preview)
		if type(preview) == "string" or not preview then preview=1 end
		item = previewItems[preview]
	end
    
	function self.GetChapterId(style,chapter)
		if not styles[style] then styles[style] = {1,1028,63026} end
		if self.IsSimpleStyle(style) or self.IsCrownStyle(style) then return styles[style][3]
		else return styles[style][3] + (chapter - 1) end
	end
  
	function self.GetIconAndLink(style,chapter)
		if not styles[style] then styles[style] = {1,1028,63026} end	
		local link = GetItemStyleMaterialLink(style)
		local icon = GetItemLinkInfo(link)	
		link = ('|H1:item:%u:370:50:0:0:0:0:0:0:0:0:0:0:0:0:%u:0:0:0:10000:0|h|h'):format(item[chapter],style)
		icon = GetItemLinkInfo(link)
		if self.IsSimpleStyle(style) or self.IsCrownStyle(style) then link = ('|H1:item:%u:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(styles[style][3])
		else link = ('|H1:item:%u:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(styles[style][3] + (chapter - 1)) end
		return icon, link
	end
  
	function self.CheckStyle(style)
		if not CS.Debug then
			if not styles[style] then return false end
			if styles[style][2] == 1028 then return false end
			if styles[style][1] == 0 then return false end 
		elseif not styles[style] then 
			local link = GetItemStyleMaterialLink(style)
			local icon = GetItemLinkInfo(link)
			name = zo_strformat('<<C:1>>',GetItemStyleName(style))
			if name ~= "None" and name ~= "" then
				return true 
			else
				return false
			end
		end
		return true
	end
  
	function self.GetHeadline(style)
		if not styles[style] then styles[style] = {1,1028,63026} end
		local name, aName, aLink, popup
		local link = GetItemStyleMaterialLink(style)
		local icon = GetItemLinkInfo(link)
		name = zo_strformat('<<C:1>>',GetItemStyleName(style))
		--Check for undefined names
		if name:find("Unused") then
			for index,data in pairs (CS.Loc.styleNames) do
				if index:lower() == name:lower() then
					name = zo_strformat('<<C:1>>',data)
				end	
			end
		end
		if CS.Debug then name = name..zo_strformat('<<C:1>>',style) end
		if styles[style][1]~=3 then
			aLink = GetAchievementLink(styles[style][2],LINK_STYLE_BRACKETS)
			aName = zo_strformat('<<C:1>>',GetAchievementInfo(styles[style][2])) 
		else
			aName = 'crown'
		end
		local _,_,_,_,progress,ts = ZO_LinkHandler_ParseLink(aLink)
		popup = {styles[style][2],progress,ts}
		return icon, link, name, aName, aLink, popup
	end
	return self
end