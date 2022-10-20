local CS = CraftStoreFixedAndImprovedLongClassName
local LAM = LibAddonMenu2

function CS.UpdateGridPerSettings()
	for craft, storeCraft in pairs(CS.Account.crafting.stored) do
		for line, storeLine in pairs(storeCraft) do
			for trait,_ in pairs(storeLine) do 
				CS.UpdatePanelIcon(craft,line,trait)
			end
		end
	end
	CS.RepairStored()
end

function CS.SettingsUpdate(setname,setval)
	CS.Account.options[setname] = setval
end 

-- return local name of setting via index
function CS.SettingFromIndex(setname,setval)
	return CS.Loc.suboptions[setname][setval]
end

-- save relative index of setting via local name
function CS.DropdownSettingsUpdate(setname,setval,subname)
	if subname == nil then subname = setname end
	local index={}
	for k,v in pairs(CS.Loc.suboptions[subname]) do
		index[v]=k
	end
	CS.Account.options[setname] = index[setval]
end 

--Menu
CS.PanelData = {
    type = "panel",
    name = CS.Title,
    displayName = CS.Title,
    author = CS.Author,
    version = CS.Version,
    slashCommand = "/csoptions",
    registerForRefresh = true,
    registerForDefaults = true,
}

CS.OptionsTable = {
	--UI options
    [1] = {
        type 		= "header",
        name 		= "UI Settings",
        width 		= "full",
    },
	[2] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.showbutton,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.showbutton end, 
		setFunc     = function(value) 
						CS.SettingsUpdate('showbutton',value) 
						CS.OptionSet()
					  end, 
		default     = CS.AccountInit.options.showbutton, 
	},
	[3] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.lockbutton,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.lockbutton end, 
		setFunc     = function(value) 
						CS.SettingsUpdate('lockbutton',value) 
						CS.OptionSet()
					  end, 
		default     = CS.AccountInit.options.lockbutton, 
	},	
	[4] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.lockelements,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.lockelements end, 
		setFunc     = function(value) 
						CS.SettingsUpdate('lockelements',value) 
						CS.OptionSet()
					  end, 
		default     = CS.AccountInit.options.lockelements, 
	},
	[5] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.closeonmove,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.closeonmove end, 
		setFunc     = function(value) CS.SettingsUpdate('closeonmove',value) end, 
		default     = CS.AccountInit.options.closeonmove, 
	},
	[6] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.useartisan,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.useartisan end, 
		setFunc     = function(value) CS.SettingsUpdate('useartisan',value) end, 
		default     = CS.AccountInit.options.useartisan, 
		disabled    = true,
	},
	[7] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.useflask,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.useflask end, 
		setFunc     = function(value) CS.SettingsUpdate('useflask',value) end, 
		default     = CS.AccountInit.options.useflask,
		disabled    = true,
	},
	[8] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.usequest,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.usequest end, 
		setFunc     = function(value) CS.SettingsUpdate('usequest',value) end, 
		default     = CS.AccountInit.options.usequest, 
	},
	[9] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.usecook,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.usecook end, 
		setFunc     = function(value) CS.SettingsUpdate('usecook',value) end, 
		default     = CS.AccountInit.options.usecook, 
	},
	[10] = {
	    type        = "dropdown", 
		name        = CS.Loc.options.overviewstyle,
		tooltip     = "",
		choices     = CS.Loc.suboptions.overviewstyle,
		getFunc     = function() return CS.SettingFromIndex('overviewstyle',CS.Account.options.overviewstyle) end, 
		setFunc     = function(value) CS.DropdownSettingsUpdate('overviewstyle',value) end, 
		default     = CS.SettingFromIndex('overviewstyle',CS.AccountInit.options.overviewstyle),
		warning     = CS.Loc.reload,
	},
	-- CraftStoreRune Settings
	[11] = {
        type 		= "header",
        name 		= "CraftStoreRune Settings",
        width 		= "full",
    },
	[12] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.userune,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.userune end, 
		setFunc     = function(value) CS.SettingsUpdate('userune',value) end, 
		default     = CS.AccountInit.options.userune, 
	},
	[13] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.userunecreation,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.userunecreation end, 
		setFunc     = function(value) CS.SettingsUpdate('userunecreation',value) end, 
		default     = CS.AccountInit.options.userunecreation,
		disabled    = function() return not CS.Account.options.userune end,
	},
	[14] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.useruneextraction,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.useruneextraction end, 
		setFunc     = function(value) CS.SettingsUpdate('useruneextraction',value) end, 
		default     = CS.AccountInit.options.useruneextraction,
		disabled    = function() return not CS.Account.options.userune end,
	},
	[15] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.userunerecipe,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.userunerecipe end, 
		setFunc     = function(value) CS.SettingsUpdate('userunerecipe',value) end, 
		default     = CS.AccountInit.options.userunerecipe,
		disabled    = function() return not CS.Account.options.userune end,
	},
	--Item options
    [16] = {
        type 		= "header",
        name 		= "Item Settings",
        width 		= "full",
    },	
	[17] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.markitems,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.markitems end, 
		setFunc     = function(value) CS.SettingsUpdate('markitems',value) end, 
		default     = CS.AccountInit.options.markitems, 
	},
	[18] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.showsymbols,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.showsymbols end, 
		setFunc     = function(value) CS.SettingsUpdate('showsymbols',value) end, 
		default     = CS.AccountInit.options.showsymbols, 
	},
	[19] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.marksetitems,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.marksetitems end, 
		setFunc     = function(value) 
						CS.SettingsUpdate('marksetitems',value) 
						CS.UpdateGridPerSettings()
					  end, 
		default     = CS.AccountInit.options.marksetitems, 
	},
	[20] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.stacksplit,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.stacksplit end, 
		setFunc     = function(value) CS.SettingsUpdate('stacksplit',value) end, 
		default     = CS.AccountInit.options.stacksplit, 
	},
	[21] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.markduplicates,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.markduplicates end, 
		setFunc     = function(value) CS.SettingsUpdate('markduplicates',value) end, 
		default     = CS.AccountInit.options.markduplicates, 
	},	
	--Alarm options
    [22] = {
        type 		= "header",
        name 		= "Alarm Settings",
        width 		= "full",
    },	
	[23] = {
	    type        = "dropdown", 
		name        = CS.Loc.options.timeralarm,
		tooltip     = "",
		choices     = CS.Loc.suboptions.alarms,
		getFunc     = function() return CS.SettingFromIndex('alarms',CS.Account.options.timeralarm) end, 
		setFunc     = function(value) CS.DropdownSettingsUpdate('timeralarm',value,'alarms') end, 
		default     = CS.SettingFromIndex('alarms',CS.AccountInit.options.timeralarm),
	},
	[24] = {
	    type        = "dropdown", 
		name        = CS.Loc.options.mountalarm,
		tooltip     = "",
		choices     = CS.Loc.suboptions.alarms,
		getFunc     = function() return CS.SettingFromIndex('alarms',CS.Account.options.mountalarm) end, 
		setFunc     = function(value) CS.DropdownSettingsUpdate('mountalarm',value,'alarms') end, 
		default     = CS.SettingFromIndex('alarms',CS.AccountInit.options.mountalarm),		
	},
	[25] = {
	    type        = "dropdown", 
		name        = CS.Loc.options.researchalarm,
		tooltip     = "",
		choices     = CS.Loc.suboptions.alarms,
		getFunc     = function() return CS.SettingFromIndex('alarms',CS.Account.options.researchalarm) end, 
		setFunc     = function(value) CS.DropdownSettingsUpdate('researchalarm',value,'alarms') end, 
		default     = CS.SettingFromIndex('alarms',CS.AccountInit.options.researchalarm), 
	},
		--Tooltip settings
    [26] = {
        type 		= "header",
        name 		= "Tooltip Settings",
        width 		= "full",
    },	
	[27] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displayrunelevel,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displayrunelevel end, 
		setFunc     = function(value) CS.SettingsUpdate('displayrunelevel',value) end, 
		default     = CS.AccountInit.options.displayrunelevel, 
	},	
	[28] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displaymm,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displaymm end, 
		setFunc     = function(value) CS.SettingsUpdate('displaymm',value) end, 
		default     = CS.AccountInit.options.displaymm, 
	},	
	[29] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displayttc,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displayttc end, 
		setFunc     = function(value) CS.SettingsUpdate('displayttc',value) end, 
		default     = CS.AccountInit.options.displayttc, 
	},	
	[30] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displaystyles,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displaystyles end, 
		setFunc     = function(value) CS.SettingsUpdate('displaystyles',value) end, 
		default     = CS.AccountInit.options.displaystyles, 
	},
	[31] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.showstock,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.showstock end, 
		setFunc     = function(value) CS.SettingsUpdate('showstock',value) end, 
		default     = CS.AccountInit.options.showstock, 
	},	
	[32] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displayunknown,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displayunknown end, 
		setFunc     = function(value) CS.SettingsUpdate('displayunknown',value) end, 
		default     = CS.AccountInit.options.displayunknown, 
	},
	[33] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displayknown,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displayknown end, 
		setFunc     = function(value) CS.SettingsUpdate('displayknown',value) end, 
		default     = CS.AccountInit.options.displayknown, 
	},
	[34] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.displaycount,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.displaycount end, 
		setFunc     = function(value) CS.SettingsUpdate('displaycount',value) end, 
		default     = CS.AccountInit.options.displaycount, 
	},
	--Misc options
    [35] = {
        type 		= "header",
        name 		= "Misc Settings",
        width 		= "full",
    },
	[36] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.playrunevoice,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.playrunevoice end, 
		setFunc     = function(value) CS.SettingsUpdate('playrunevoice',value) end, 
		default     = CS.AccountInit.options.playrunevoice, 
	},	
	[37] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.advancedcolorgrid,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.advancedcolorgrid end, 
		setFunc     = function(value) 
						CS.SettingsUpdate('advancedcolorgrid',value)
						CS.UpdateGridPerSettings()
					  end, 
		default     = CS.AccountInit.options.advancedcolorgrid, 
	},
	[38] = {
	    type        = "checkbox", 
		name        = CS.Loc.options.lockprotection,
		tooltip     = "",
		getFunc     = function() return CS.Account.options.lockprotection end, 
		setFunc     = function(value) CS.SettingsUpdate('lockprotection',value) end, 
		default     = CS.AccountInit.options.lockprotection, 
	},	
	[39] = {
	    type        = "dropdown", 
		name        = CS.Loc.options.sortsets,
		tooltip     = "",
		choices     = CS.Loc.suboptions.sortsets,
		getFunc     = function() return CS.SettingFromIndex('sortsets',CS.Account.options.sortsets) end, 
		setFunc     = function(value) CS.DropdownSettingsUpdate('sortsets',value) end, 
		default     = CS.SettingFromIndex('sortsets',CS.AccountInit.options.sortsets),
	},
	[40] = {
	    type        = "dropdown", 
		name        = CS.Loc.options.sortstyles,
		tooltip     = "",
		choices     = CS.Loc.suboptions.sortstyles,
		getFunc     = function() return CS.SettingFromIndex('sortstyles',CS.Account.options.sortstyles) end, 
		setFunc     = function(value) 
						CS.DropdownSettingsUpdate('sortstyles',value)
						CS.StyleInitialize()  
					  end, 
		default     = CS.SettingFromIndex('sortstyles',CS.AccountInit.options.sortstyles),
	},
	[41] = {
	    type        = "editbox", 
		name        = CS.Loc.options.bulkcraftlimit,
		tooltip     = "",
		isMultiline = false,
		getFunc     = function() return CS.Account.options.bulkcraftlimit end, 
		setFunc     = function(value) CS.SettingsUpdate('bulkcraftlimit',tonumber(value)) end, 
		default     = CS.AccountInit.options.bulkcraftlimit, 
	},
}