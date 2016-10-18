; TradeMacro Add-on to POE-ItemInfo v0.1
; IGN: ManicCompression
; Notes:
; 1. To enable debug output, find the out() function and uncomment
;
; Todo:
; Support for modifiers
; Allow user to customize which mod and value to use

PriceCheck:
	IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
	{
		Global TradeOpts, Item
		Item := {}
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		Send ^c
		Sleep 250
		TradeMacroMainFunction()
		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
return

AdvancedPriceCheck:
	IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
	{
		Global TradeOpts, Item
		Item := {}
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		Send ^c
		Sleep 250
		TradeMacroMainFunction(false, true)
		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
return

OpenWiki:
	IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
	{
		Global Item
		Item := {}
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		Send ^c
		Sleep 250
		DoParseClipboardFunction()

		if (Item.IsUnique or Item.IsGem or Item.IsDivinationCard or Item.IsCurrency) {
			UrlAffix := Item.Name
		} else if (Item.IsFlask or Item.IsMap) {
			UrlAffix := Item.SubType
		} else if (RegExMatch(Item.Name, "i)Sacrifice At") or RegExMatch(Item.Name, "i)Fragment of") or RegExMatch(Item.Name, "i)Mortal ") or RegExMatch(Item.Name, "i)Offering to ") or RegExMatch(Item.Name, "i)'s Key")) {
			UrlAffix := Item.Name
		} else {
			UrlAffix := Item.BaseType
		}

		UrlAffix := StrReplace(UrlAffix," ","_")
		WikiUrl := "http://pathofexile.gamepedia.com/" UrlAffix		
		FunctionOpenUrlInBrowser(WikiUrl)

		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
return

CustomInputSearch:
	IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
	{
	  Global X
	  Global Y
	  MouseGetPos, X, Y	
	  InputBox,ItemName,Price Check,Item Name,,250,100,X-160,Y - 250,,30,
	  if ItemName {
		RequestParams := new RequestParams_()
		LeagueName := TradeGlobals.Get("LeagueName")
		RequestParams.name   := ItemName
		RequestParams.league := LeagueName
		Item.Name := ItemName
		Payload := RequestParams.ToPayload()
		Html := FunctionDoPostRequest(Payload)
		ParsedData := FunctionParseHtml(Html, Payload)
		SetClipboardContents(ParsedData)
		ShowToolTip(ParsedData)
	  }
	}
return

OpenSearchOnPoeTrade:
	Global TradeOpts, Item
	Item := {}
	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	Send ^c
	Sleep 250
	TradeMacroMainFunction(true)
	SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
return

; Prepare Reqeust Parametes and send Post Request
; openSearchInBrowser : set to true to open the search on poe.trade instead of showing the tooltip
; isAdvancedPriceCheck : set to true if the GUI to select mods should be openend
; isAdvancedPriceCheckRedirect : set to true if the search is triggered from the GUI
TradeMacroMainFunction(openSearchInBrowser = false, isAdvancedPriceCheck = false, isAdvancedPriceCheckRedirect = false)
{	
    out("+ Start of TradeMacroMainFunction")
	LeagueName := TradeGlobals.Get("LeagueName")
	Global Item, ItemData, TradeOpts, mapList, uniqueMapList, Opts
	
	DoParseClipboardFunction()
	iLvl     := Item.Level

	; cancel search if Item is empty
	if (!Item.name) {
		return
	}
	
	if (Opts.ShowMaxSockets != 1) {
		FunctionSetItemSockets()
	}
	
	Stats := {}
	Stats.Quality := Item.Quality
	DamageDetails := Item.DamageDetails
	Name := Item.Name
	
	Item.UsedInSearch := {}
	Item.UsedInSearch.iLvl := {}
	Item.IsEssence    := 
	if (RegExMatch(Item.Name, "i)essence of")) {
		Item.IsEssence:= true
	}
		
	RequestParams := new RequestParams_()
	RequestParams.league := LeagueName
	
	; ignore item name in certain cases
	if (!Item.IsJewel and Item.RarityLevel > 1 and Item.RarityLevel < 4 and !Item.IsFlask) {
		IgnoreName := true
	}
	if (Item.RarityLevel > 0 and Item.RarityLevel < 4 and (Item.IsWeapon or Item.IsArmour or Item.IsRing or Item.IsBelt or Item.IsAmulet)) {
		IgnoreName := true
	}
	
	; check if the item implicit mod is an enchantment or corrupted. retrieve this mods data.
	if (Item.hasImplicit) {
		Enchantment := FunctionGetEnchantment(Item, Item.SubType)
		Corruption  := Item.IsCorrupted ? FunctionGetCorruption(Item) : false
	}	
	
	if (Item.IsUnique) {		
		; returns mods with their ranges of the searched item if it is unique and has variable mods
		uniqueWithVariableMods := FunctionFindUniqueItemIfItHasVariableRolls(Name)

		; return if the advanced search was used but the checked item doesn't have variable mods
		if(!uniqueWithVariableMods and isAdvancedPriceCheck) {
			ShowToolTip("Advanced search not available for this item (no variable mods).")
			return
		}
		
		UniqueStats := FunctionGetUniqueStats(Name)
		if (uniqueWithVariableMods) {
			Gui, SelectModsGui:Destroy

			s := FunctionGetItemsPoeTradeUniqueMods(uniqueWithVariableMods)	
			Stats.Defense := FunctionParseItemDefenseStats(ItemData.Stats, s, Item.IsUnique)
			Stats.Offense := FunctionParseItemOffenseStats(DamageDetails, s, Item.IsUnique)	

			; open AdvancedPriceCheckGui to select mods and their min/max values
			if (isAdvancedPriceCheck) {
				UniqueStats := FunctionGetUniqueStats(Name)
				if (Enchantment) {
					AdvancedPriceCheckGui(s, Stats, UniqueStats, Enchantment)
				}
				else if (Corruption) {
					AdvancedPriceCheckGui(s, Stats, UniqueStats, Corruption)
				} else {
					AdvancedPriceCheckGui(s, Stats, UniqueStats)
				}				
				return
			}		
			; ignore mod rolls unless the AdvancedPriceCheckGui is used to search
			if (isAdvancedPriceCheckRedirect) {
				; submitting the AdvancedPriceCheck Gui sets TradeOpts.Set("AdvancedPriceCheckItem") with the edited item (selected mods and their min/max values)
				s := TradeGlobals.Get("AdvancedPriceCheckItem")
				Loop % s.mods.Length() {
					if (s.mods[A_Index].selected > 0) {
						modParam := new _ParamMod()
						modParam.mod_name := s.mods[A_Index].param
						modParam.mod_min := s.mods[A_Index].min
						modParam.mod_max := s.mods[A_Index].max
						RequestParams.modGroup.AddMod(modParam)
					}	
				}
				Loop % s.stats.Length() {
					if (s.stats[A_Index].selected > 0) {
						; defense
						if (InStr(s.stats[A_Index].Param, "Armour")) {
							RequestParams.armour_min  := (s.stats[A_Index].min > 0) ? s.stats[A_Index].min : ""
							RequestParams.armour_max  := (s.stats[A_Index].max > 0) ? s.stats[A_Index].max : ""
						} 
						else if (InStr(s.stats[A_Index].Param, "Evasion")) {
							RequestParams.evasion_min := (s.stats[A_Index].min > 0) ? s.stats[A_Index].min : ""
							RequestParams.evasion_max := (s.stats[A_Index].max > 0) ? s.stats[A_Index].max : ""
						}
						else if (InStr(s.stats[A_Index].Param, "Energy")) {
							RequestParams.shield_min  := (s.stats[A_Index].min > 0) ? s.stats[A_Index].min : ""
							RequestParams.shield_max  := (s.stats[A_Index].max > 0) ? s.stats[A_Index].max : ""
						}
						else if (InStr(s.stats[A_Index].Param, "Block")) {
							RequestParams.block_min  := (s.stats[A_Index].min > 0)  ? s.stats[A_Index].min : ""
							RequestParams.block_max  := (s.stats[A_Index].max > 0)  ? s.stats[A_Index].max : ""
						}
						
						; offense
						else if (InStr(s.stats[A_Index].Param, "Physical")) {
							RequestParams.pdps_min  := (s.stats[A_Index].min > 0)  ? s.stats[A_Index].min : ""
							RequestParams.pdps_max  := (s.stats[A_Index].max > 0)  ? s.stats[A_Index].max : ""
						}
						else if (InStr(s.stats[A_Index].Param, "Elemental")) {
							RequestParams.edps_min  := (s.stats[A_Index].min > 0)  ? s.stats[A_Index].min : ""
							RequestParams.edps_max  := (s.stats[A_Index].max > 0)  ? s.stats[A_Index].max : ""
						}						
					}	
				}
				
				If(s.UsedInSearch) {
					Item.UsedInSearch.Enchantment := s.UsedInSearch.Enchantment
					Item.UsedInSearch.CorruptedMod:= s.UsedInSearch.Corruption
				}
			}			
		}
		else {
			RequestParams.name   := Trim(StrReplace(Name, "Superior", ""))		
			Item.UsedInSearch.FullName := true
		}		

		; only find items that can have the same amount of sockets
		if (Item.MaxSockets = 6) {
			RequestParams.ilevel_min  := 50
			Item.UsedInSearch.iLvl.min:= 50
		} 
		else if (Item.MaxSockets = 5) {
			RequestParams.ilevel_min := 35
			RequestParams.ilevel_max := 49
			Item.UsedInSearch.iLvl.min := 35
			Item.UsedInSearch.iLvl.max := 49
		} 
		else if (Item.MaxSockets = 5) {
			RequestParams.ilevel_min := 35
			Item.UsedInSearch.iLvl.min := 35
		}
		; is (no 1-hand or shield or unset ring or helmet or glove or boots) but is weapon or armor
		else if ((not Item.IsFourSocket and not Item.IsThreeSocket and not Item.IsSingleSocket) and (Item.IsWeapon or Item.IsArmour) and Item.Level < 35) {		
			RequestParams.ilevel_max := 34
			Item.UsedInSearch.iLvl.max := 34
		}		
	}
	
	; prepend the item.subtype to match the options used on poe.trade
	if (RegExMatch(Item.SubType, "i)Mace|Axe|Sword")) {
		if (Item.IsThreeSocket) {
			Item.xtype := "One Hand " . Item.SubType
		}
		else {
			Item.xtype := "Two Hand " . Item.SubType
		}
	}
	
	; remove "Superior" from item name to exclude it from name search
	if (!IgnoreName) {
		RequestParams.name   := Trim(StrReplace(Name, "Superior", ""))		
		Item.UsedInSearch.FullName := true
	} else if (!Item.isUnique) {
		isCraftingBase         := CheckIfItemIsCraftingBase(Item.TypeName)
		hasHighestCraftingILvl := CheckIfItemHasHighestCraftingLevel(Item.SubType, iLvl)
		; xtype = Item.SubType (Helmet)
		; xbase = Item.TypeName (Eternal Burgonet)

		;if desired crafting base
		if (isCraftingBase and not Enchantment and not Corruption) {			
			RequestParams.xbase := Item.TypeName
			Item.UsedInSearch.ItemBase := Item.TypeName
			; if highest item level needed for crafting
			if (hasHighestCraftingILvl) {
				RequestParams.ilvl_min := hasHighestCraftingILvl
				Item.UsedInSearch.iLvl.min := hasHighestCraftingILvl
			}			
		} else if (Enchantment) {			
			modParam := new _ParamMod()
			modParam.mod_name := Enchantment.param
			modParam.mod_min  := Enchantment.min
			modParam.mod_max  := Enchantment.max
			RequestParams.modGroup.AddMod(modParam)	
			Item.UsedInSearch.Enchantment := true
		} else if (Corruption) {			
			modParam := new _ParamMod()
			modParam.mod_name := Corruption.param
			modParam.mod_min  := (Corruption.min) ? Corruption.min : ""
			RequestParams.modGroup.AddMod(modParam)	
			Item.UsedInSearch.CorruptedMod := true
		} else {
			RequestParams.xtype := (Item.xtype) ? Item.xtype : Item.SubType
			Item.UsedInSearch.Type := (Item.xtype) ? Item.GripType . " " . Item.SubType : Item.SubType
		}		
	}	
		
	; handle item sockets
	; maybe don't use this for unique-items as default
	if (ItemData.Sockets >= 5) {
		RequestParams.sockets_min := ItemData.Sockets
		Item.UsedInSearch.Sockets := ItemData.Sockets
	}	
	; handle item links
	if (ItemData.Links >= 5) {
		RequestParams.link_min := ItemData.Links
		Item.UsedInSearch.Links := ItemData.Links
	}
	
	; handle corruption
	if (Item.IsCorrupted) {
		; search for both corrupted and un-corrupted
		; "x" for "Either"
		RequestParams.corrupted := "1"
		Item.UsedInSearch.Corruption := "Yes"
		; for gems only search corrupted ones
		if (Item.IsGem) {
			RequestParams.corrupted := "1"
			Item.UsedInSearch.Corruption := "Yes"
		}
		if(Item.IsUnique) {
			RequestParams.corrupted := "1"
			Item.UsedInSearch.Corruption := "Yes"	
		}
		if(ItemData.Links >= 5) {
			RequestParams.corrupted := "1"
			Item.UsedInSearch.Corruption := "Yes"
		}
	}
	else {
		; always exclude corrupted gems from results if the source is not corrupted
		if (Item.IsGem) {
			RequestParams.corrupted := "0"
			Item.UsedInSearch.Corruption := "No"
		}
		; either
		else if (TradeOpts.Corrupted = "Either") {
			RequestParams.corrupted := "x"
			Item.UsedInSearch.Corruption := "Either"
		}
		; corrupted
		else if (TradeOpts.Corrupted = "Yes") {		
			RequestParams.corrupted := "1"
			Item.UsedInSearch.Corruption := "Yes"
		}
		; non-corrupted
		else if (TradeOpts.Corrupted = "No") {		
			RequestParams.corrupted := "0"
			Item.UsedInSearch.Corruption := "No"
		}
	}
	
	if (Item.IsMap) {	
		; add Item.subtype to make sure to only find maps
		; handle shaped maps, Item.subtype or Item.name won't work here
		if (InStr(ItemData.Nameplate, "Shaped")) {
			RequestParams.xbase := "Shaped " Trim(StrReplace(Item.SubType, "Superior", ""))
		}
		else {
			RequestParams.xbase := Item.SubType
		}
		
		; Quick map fix (wrong Item.name on magic/rare maps), map name prefixes/suffixes can be ignored
		if (!Item.isUnique) {	
			RequestParams.name   := Trim(StrReplace(Item.SubType, "Superior", ""))		
		}
		; Ivory Temple fix, not sure why it's not recognized and if there are more cases like it
		if (InStr(Name, "Ivory Temple")){
			RequestParams.xbase  := "Ivory Temple Map"
		}
	}

	; handle gems
	if (Item.IsGem) {
		if (TradeOpts.GemQualityRange > 0) {
			RequestParams.q_min := Item.Quality - TradeOpts.GemQualityRange
			RequestParams.q_max := Item.Quality + TradeOpts.GemQualityRange
		}
		else {
			RequestParams.q_min := Item.Quality
		}
		; match exact gem level if enhance, empower or enlighten
		if (InStr(Name, "Empower") or InStr(Name, "Enlighten") or InStr(Name, "Enhance")) {
			RequestParams.level_min := Item.Level
			RequestParams.level_max := Item.Level
		}
		else if (Item.Level >= TradeOpts.GemLevel) {
			RequestParams.level_min := Item.Level
		}
	}
	
	; handle divination cards
	if (Item.IsDivinationCard) {
		RequestParams.xtype := Item.BaseType
	}
	
	Payload := RequestParams.ToPayload()
	
	out("Running request with Payload:")
	out("------------------------------------")
	out(Payload)
	out("------------------------------------")
	
	ShowToolTip("Running search...")
	
	if (Item.isCurrency and !Item.IsEssence) {		
		Html := FunctionDoCurrencyRequest(Item.Name, openSearchInBrowser)
	}
	else {
		Html := FunctionDoPostRequest(Payload, openSearchInBrowser)	
	}
	out("POST Request success")
	
	if(openSearchInBrowser) {
		; redirect was prevented to get the url and open the search on poe.trade instead
		if (Item.isCurrency and !Item.IsEssence) {
			IDs := TradeGlobals.Get("CurrencyIDs")
			ParsedUrl1 := "http://currency.poe.trade/search?league=" . LeagueName . "&online=x&want=" . IDs[Name] . "&have=" . IDs["Chaos Orb"]
		}
		else {
			RegExMatch(Html, "i)href=""(https?:\/\/.*?)""", ParsedUrl)
		}		
		FunctionOpenUrlInBrowser(ParsedUrl1)
	}
	else if (Item.isCurrency and !Item.IsEssence) {
		ParsedData := FunctionParseCurrencyHtml(Html, Payload)
		out("Parsing HTML done")
		
		SetClipboardContents(ParsedData)
		ShowToolTip(ParsedData)
	}
	else {
		Item.UsedInSearch.SearchType := "Default"
		ParsedData := FunctionParseHtml(Html, Payload, iLvl, Enchantment)
		out("Parsing HTML done")
		
		SetClipboardContents(ParsedData)
		ShowToolTip(ParsedData)
	}    
	
	; reser Item and ItemData after search
	Item := {}
	ItemData := {}
}

; parse items defense stats
FunctionParseItemDefenseStats(stats, mods, isUnique){
	Global ItemData
	iStats := {}
	
	RegExMatch(stats, "i)chance to block ?:.*?(\d+)", Block)
	RegExMatch(stats, "i)armour ?:.*?(\d+)"         , Armour)
	RegExMatch(stats, "i)energy shield ?:.*?(\d+)"  , EnergyShield)
	RegExMatch(stats, "i)evasion rating ?:.*?(\d+)" , Evasion)
	RegExMatch(stats, "i)quality ?:.*?(\d+)"        , Quality)

	RegExMatch(ItemData.Affixes, "i)(\d+).*maximum.*?Energy Shield"  , affixFlatES) 
	RegExMatch(ItemData.Affixes, "i)(\d+).*maximum.*?Armour"         , affixFlatAR) 
	RegExMatch(ItemData.Affixes, "i)(\d+).*maximum.*?Evasion"        , affixFlatEV) 
	RegExMatch(ItemData.Affixes, "i)(\d+).*increased.*?Energy Shield", affixPercentES) 
	RegExMatch(ItemData.Affixes, "i)(\d+).*increased.*?Evasion"      , affixPercentEV) 
	RegExMatch(ItemData.Affixes, "i)(\d+).*increased.*?Armour"       , affixPercentAR) 

	; calculate items base defense stats
	baseES := FunctionCalculateBase(EnergyShield1, affixPercentES1, Quality1, affixFlatES1)
	baseAR := FunctionCalculateBase(Armour1      , affixPercentAR1, Quality1, affixFlatAR1)
	baseEV := FunctionCalculateBase(Evasion1     , affixPercentEV1, Quality1, affixFlatEV1)
	
	; calculate items Q20 total defense stats
	Armour       := FunctionCalculateQ20(baseAR, affixFlatAR1, affixPercentAR1)
	EnergyShield := FunctionCalculateQ20(baseES, affixFlatES1, affixPercentES1)
	Evasion      := FunctionCalculateQ20(baseEV, affixFlatEV1, affixPercentEV1)
	
	; calculate items Q20 defense stat min/max values
	Affixes := StrSplit(ItemData.Affixes, "`n")
	For key, mod in mods.mods {
		For i, affix in Affixes {
			affix := RegExReplace(affix, "i)(\d+.?\d+?)", "#")
			affix := RegExReplace(affix, "i)# %", "#%")
			affix := Trim(RegExReplace(affix, "\s", " "))
			name :=  Trim(mod.name)		
			
			If ( affix = name ){
				; ignore mods like " ... per X dexterity"
				If (RegExMatch(affix, "i) per ")) {
					continue
				}
				if (RegExMatch(affix, "i)#.*to maximum.*?Energy Shield"  , affixFlatES)) {
					min_affixFlatES    := mod.ranges[1][1] 
					max_affixFlatES    := mod.ranges[1][2] 
					;MsgBox % affix "`nmax es : " min_affixFlatES " - " max_affixFlatES
				}
				if (RegExMatch(affix, "i)#.*to maximum.*?Armour"         , affixFlatAR)) {
					min_affixFlatAR    := mod.ranges[1][1]
					max_affixFlatAR    := mod.ranges[1][2]
					;MsgBox % affix "`nmax ar : " min_affixFlatAR " - " max_affixFlatAR
				}
				if (RegExMatch(affix, "i)#.*to maximum.*?Evasion"        , affixFlatEV)) {
					min_affixFlatEV    := mod.ranges[1][1]
					max_affixFlatEV    := mod.ranges[1][2]
					;MsgBox % affix "`nmax ev : " min_affixFlatEV " - " max_affixFlatEV
				}
				if (RegExMatch(affix, "i)#.*increased.*?Energy Shield"   , affixPercentES)) {
					min_affixPercentES := mod.ranges[1][1]
					max_affixPercentES := mod.ranges[1][2]
					;MsgBox % affix "`ninc es : " min_affixPercentES " - " max_affixPercentES
				}
				if (RegExMatch(affix, "i)#.*increased.*?Evasion"         , affixPercentEV)) {
					min_affixPercentEV := mod.ranges[1][1]
					max_affixPercentEV := mod.ranges[1][2]
					;MsgBox % affix "`ninc ev : " min_affixPercentEV " - " max_affixPercentEV
				}
				if (RegExMatch(affix, "i)#.*increased.*?Armour"          , affixPercentAR)) {
					min_affixPercentAR := mod.ranges[1][1]
					max_affixPercentAR := mod.ranges[1][2]
					;MsgBox % affix "`ninc ar : " min_affixPercentAR " - " max_affixPercentAR
				}
			}
		}
	}
	
	min_Armour       := FunctionCalculateQ20(baseAR, min_affixFlatAR   , min_affixPercentAR)
	max_Armour       := FunctionCalculateQ20(baseAR, max_affixFlatAR   , max_affixPercentAR)
	min_EnergyShield := FunctionCalculateQ20(baseES, min_affixFlatES   , min_affixPercentES)
	max_EnergyShield := FunctionCalculateQ20(baseES, max_affixFlatES   , max_affixPercentES)
	min_Evasion      := FunctionCalculateQ20(baseEV, min_affixPercentEV, min_affixPercentEV)	
	max_Evasion      := FunctionCalculateQ20(baseEV, max_affixPercentEV, max_affixPercentEV)	
	
	iStats.TotalBlock 				:= {}
	iStats.TotalBlock.Value 		:= Block1
	iStats.TotalBlock.Name  		:= "Block Chance"
	iStats.TotalArmour 				:= {}
	iStats.TotalArmour.Value 		:= Armour
	iStats.TotalArmour.Name  		:= "Armour"
	iStats.TotalArmour.Base  		:= baseAR
	iStats.TotalArmour.min  		:= min_Armour
	iStats.TotalArmour.max  		:= max_Armour
	iStats.TotalEnergyShield 		:= {}
	iStats.TotalEnergyShield.Value 	:= EnergyShield
	iStats.TotalEnergyShield.Name  	:= "Energy Shield"
	iStats.TotalEnergyShield.Base  	:= baseES
	iStats.TotalEnergyShield.min 	:= min_EnergyShield
	iStats.TotalEnergyShield.max  	:= max_EnergyShield
	iStats.TotalEvasion 			:= {}
	iStats.TotalEvasion.Value 		:= Evasion
	iStats.TotalEvasion.Name  		:= "Evasion Rating"
	iStats.TotalEvasion.Base  		:= baseEV
	iStats.TotalEvasion.min  		:= min_Evasion
	iStats.TotalEvasion.max  		:= max_Evasion
	iStats.Quality 					:= Quality1
	
	return iStats
}

FunctionCalculateBase(total, affixPercent, qualityPercent, affixFlat){
	SetFormat, FloatFast, 5.2
	If (total) {
		affixPercent  := (affixPercent) ? (affixPercent / 100) : 0
		affixFlat     := (affixFlat) ? affixFlat : 0
		qualityPercent:= (qualityPercent) ? (qualityPercent / 100) : 0
		base := Round((total / (1 + affixPercent + qualityPercent)) - affixFlat)
		return base
	}
	return
}
FunctionCalculateQ20(base, affixFlat, affixPercent){
	SetFormat, FloatFast, 5.2
	If (base) {
		affixPercent  := (affixPercent) ? (affixPercent / 100) : 0
		affixFlat     := (affixFlat) ? affixFlat : 0
		total := Round((base + affixFlat) * (1 + affixPercent + (20 / 100)))
		return total
	}
	return
}

; parse items dmg stats
FunctionParseItemOffenseStats(Stats, mods, isUnique){
	Global ItemData
	iStats := {}

	RegExMatch(ItemData.Stats, "i)Physical Damage ?:.*?(\d+)-(\d+)", match)
	physicalDamageLow := match1
	physicalDamageHi  := match2
	RegExMatch(ItemData.Stats, "i)Attacks per Second ?: ?(\d+.?\d+)", match)
	AttacksPerSecond := match1
	RegExMatch(ItemData.Affixes, "i)(\d+).*increased.*?Physical Damage", match)
	affixPercentPhys := match1
	RegExMatch(ItemData.Affixes, "i)Adds\D+(\d+)\D+(\d+).*Physical Damage", match)
	affixFlatPhysLow := match1
	affixFlatPhysHi  := match2

	Affixes := StrSplit(ItemData.Affixes, "`n")
	For key, mod in mods.mods {
		For i, affix in Affixes {
			If (RegExMatch(affix, "i)(\d+.?\d+?).*increased Attack Speed", match)) {
				affixAttackSpeed := match1
			}
					
			If (RegExMatch(affix, "Adds.*Lightning Damage")) {
				affix := RegExReplace(affix, "i)to (\d+)", "to #")
				affix := RegExReplace(affix, "i)to (\d+.*?\d+?)", "to #")
			} 
			Else {
				affix := RegExReplace(affix, "i)(\d+ to \d+)", "#")
				affix := RegExReplace(affix, "i)(\d+.*?\d+?)", "#")
			}						
			affix := RegExReplace(affix, "i)# %", "#%")
			affix := Trim(RegExReplace(affix, "\s", " "))
			name :=  Trim(mod.name)	
			
			If ( affix = name ){
				match :=
				; ignore mods like " ... per X dexterity"
				If (RegExMatch(affix, "i) per ")) {
					continue
				}
				If (RegExMatch(affix, "i)Adds.*#.*(Physical|Fire|Cold|Chaos) Damage", dmgType)) {
					min_affixFlat%dmgType1%Low    := mod.ranges[1][1] 
					min_affixFlat%dmgType1%Hi     := mod.ranges[1][2] 
					max_affixFlat%dmgType1%Low    := mod.ranges[2][1] 
					max_affixFlat%dmgType1%Hi     := mod.ranges[2][2] 
					;MsgBox % affix "`nflat " dmgType1 " : " min_affixFlat%dmgType1%Low " - " min_affixFlat%dmgType1%Hi " to " max_affixFlat%dmgType1%Low " - " max_affixFlat%dmgType1%Hi
				}
				If (RegExMatch(affix, "i)Adds.*(\d+) to #.*(Lightning) Damage", match)) {
					min_affixFlat%match2%Low    := match1 
					min_affixFlat%match2%Hi     := mod.ranges[1][1] 
					max_affixFlat%match2%Low    := match1
					max_affixFlat%match2%Hi     := mod.ranges[1][2] 
					;MsgBox % affix "`nflat " match2 " : " min_affixFlat%match2%Low " - " min_affixFlat%match2%Hi " to " max_affixFlat%match2%Low " - " max_affixFlat%match2%Hi
				}
				If (RegExMatch(affix, "i)#.*increased Physical Damage")) {
					min_affixPercentPhys    := mod.ranges[1][1] 
					max_affixPercentPhys    := mod.ranges[1][2] 
					;MsgBox % affix "`ninc Phys : " min_affixPercentPhys " - " max_affixPercentPhys
				}
				If (RegExMatch(affix, "i)#.*increased Attack Speed")) {
					min_affixPercentAPS     := mod.ranges[1][1] 
					max_affixPercentAPS     := mod.ranges[1][2] 
					;MsgBox % affix "`ninc attack speed : " min_affixPercentAPS " - " max_affixPercentAPS
				}
			}
		}
	}
	
	SetFormat, FloatFast, 5.2	
	baseAPS      := (!affixAttackSpeed) ? AttacksPerSecond : AttacksPerSecond / (1 + (affixAttackSpeed / 100))
	basePhysLow  := FunctionCalculateBase(physicalDamageLow, affixPercentPhys, Stats.Quality, affixFlatPhysLow)
	basePhysHi   := FunctionCalculateBase(physicalDamageHi , affixPercentPhys, Stats.Quality, affixFlatPhysHi)
	
	minPhysLow   := FunctionCalculateQ20(basePhysLow, min_affixFlatPhysicalLow, min_affixPercentPhys)
	minPhysHi    := FunctionCalculateQ20(basePhysHi , min_affixFlatPhysicalHi , min_affixPercentPhys)
	maxPhysLow   := FunctionCalculateQ20(basePhysLow, max_affixFlatPhysicalLow, max_affixPercentPhys)
	maxPhysHi    := FunctionCalculateQ20(basePhysHi , max_affixFlatPhysicalHi , max_affixPercentPhys)
	minAPS       := baseAPS * (1 + (min_affixPercentAPS / 100))
	maxAPS       := baseAPS * (1 + (max_affixPercentAPS / 100))
	
	iStats.PhysDps        := {}
    iStats.PhysDps.Name   := "Physical Dps (Q20)"
    iStats.PhysDps.Value  := (Stats.Q20Dps > 0) ? (Stats.Q20Dps - Stats.EleDps - Stats.ChaosDps) : Stats.PhysDps 
    iStats.PhysDps.Min    := ((minPhysLow + minPhysHi) / 2) * minAPS
    iStats.PhysDps.Max    := ((maxPhysLow + maxPhysHi) / 2) * maxAPS
    iStats.EleDps         := {}
    iStats.EleDps.Name    := "Elemental Dps"
    iStats.EleDps.Value   := Stats.EleDps
	iStats.EleDps.Min     := ((min_affixFlatFireLow + min_affixFlatFireHi + min_affixFlatColdLow + min_affixFlatColdHi + min_affixFlatLightningLow + min_affixFlatLightningHi) / 2) * minAPS
	iStats.EleDps.Max     := ((max_affixFlatFireLow + max_affixFlatFireHi + max_affixFlatColdLow + max_affixFlatColdHi + max_affixFlatLightningLow + max_affixFlatLightningHi) / 2) * maxAPS
	
	;MsgBox % "Phys DPS: " iStats.PhysDps.Value "`n" "Phys Min: " iStats.PhysDps.Min "`n" "Phys Max: " iStats.PhysDps.Max "`n" "EleDps: " iStats.EleDps.Value "`n" "Ele Min: " iStats.EleDps.Min "`n" "Ele Max: "  iStats.EleDps.Max
	
	return iStats
}

FunctionGetUniqueStats(name){
	items := TradeGlobals.Get("VariableUniqueData")
	For i, uitem in items {
		If (name = uitem.name) {
			return uitem.stats
		}
	}
}

; copied from PoE-ItemInfo because there it'll only be called if the optioen "ShowMaxSockets" is enabled
FunctionSetItemSockets() {
	Global Item
	
	If (Item.IsWeapon or Item.IsArmour)
    {
        If (Item.Level >= 50)
        {
            Item.MaxSockets := 6
        }
        Else If (Item.Level >= 35)
        {
            Item.MaxSockets := 5
        }
        Else If (Item.Level >= 25)
        {
            Item.MaxSockets := 4
        }
        Else If (Item.Level >= 1)
        {
            Item.MaxSockets := 3
        }
        Else
        {
            Item.MaxSockets := 2
        }
        
        If(Item.IsFourSocket and Item.MaxSockets > 4)
        {
            Item.MaxSockets := 4
        }
        Else If(Item.IsThreeSocket and Item.MaxSockets > 3)
        {
            Item.MaxSockets := 3
        }
        Else If(Item.IsSingleSocket)
        {
            Item.MaxSockets := 1
        }
    }
}

CheckIfItemIsCraftingBase(type){
	bases := TradeGlobals.Get("CraftingData")
	For i, base in bases {
		If (type = base) {
			return true
		}
	}
	return false
}

CheckIfItemHasHighestCraftingLevel(subtype, iLvl){
	If (RegExMatch(subtype, "i)Helmet|Gloves|Boots|Body Armour|Shield|Quiver")) {
		return (iLvl >= 84) ? 84 : false
	}
	Else If (RegExMatch(subtype, "i)Weapon")) {
		return (iLvl >= 83) ? 83 : false
	}	
	Else If (RegExMatch(subtype, "i)Belt|Amulet|Ring")) {
		return (iLvl >= 83) ? 83 : false
	}
	return false
}

DoParseClipboardFunction()
{
	CBContents := GetClipboardContents()
    CBContents := PreProcessContents(CBContents)
	
    Globals.Set("ItemText", CBContents)
    Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)

    ParsedData := ParseItemData(CBContents)
	out("ItemInfo Parsing Success")
}


out(str)
{
	;stdout := FileOpen("*", "w")
	;stdout.WriteLine(str)
}

FunctionDoPostRequest(payload, openSearchInBrowser = false)
{	
    ; Reference in making POST requests - http://stackoverflow.com/questions/158633/how-can-i-send-an-http-post-request-to-a-server-from-excel-using-vba
    HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	if (openSearchInBrowser) {
		HttpObj.Option(6) := False ;
	}    
    ;HttpObj := ComObjCreate("MSXML2.ServerXMLHTTP") 
    ; We use this instead of WinHTTP to support gzip and deflate - http://microsoft.public.winhttp.narkive.com/NDkh5vEw/get-request-for-xml-gzip-file-winhttp-wont-uncompress-automagically
    HttpObj.Open("POST","http://poe.trade/search")
    HttpObj.SetRequestHeader("Host","poe.trade")
    HttpObj.SetRequestHeader("Connection","keep-alive")
    HttpObj.SetRequestHeader("Content-Length",StrLen(payload))
    HttpObj.SetRequestHeader("Cache-Control","max-age=0")
    HttpObj.SetRequestHeader("Origin","http://poe.trade")
    HttpObj.SetRequestHeader("Upgrade-Insecure-Requests","1")
    HttpObj.SetRequestHeader("User-Agent","Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36")
    HttpObj.SetRequestHeader("Content-type","application/x-www-form-urlencoded")
    HttpObj.SetRequestHeader("Accept","text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
    HttpObj.SetRequestHeader("Referer","http://poe.trade/")
    HttpObj.SetRequestHeader("Accept-Encoding","gzip;q=0,deflate;q=0") ; disables compression
    ;HttpObj.SetRequestHeader("Accept-Encoding","gzip, deflate")
    HttpObj.SetRequestHeader("Accept-Language","en-US,en;q=0.8")	
    HttpObj.Send(payload)
    HttpObj.WaitForResponse()

    ;MsgBox % HttpObj.StatusText . HttpObj.GetAllResponseHeaders()
    ;MsgBox % HttpObj.ResponseText
    ; Dear GGG, it would be nice if you can provide an API like http://pathofexile.com/trade/search?name=Veil+of+the+night&links=4
    ; Pete's indexer is open sourced here - https://github.com/trackpete/exiletools-indexer you can use this to provide this api
    html := HttpObj.ResponseText
    
    Return, html
}

; Get currency.poe.trade html
; Either at script start to parse the currency IDs or when searching to get currency listings
FunctionDoCurrencyRequest(currencyName = "", openSearchInBrowser = false, init = false){
	HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	if (openSearchInBrowser) {
		HttpObj.Option(6) := False ;
	} 

	if (init) {
		Url := "http://currency.poe.trade/"
	}
	else {
		LeagueName := TradeGlobals.Get("LeagueName")
		IDs := TradeGlobals.Get("CurrencyIDs")
		Url := "http://currency.poe.trade/search?league=" . LeagueName . "&online=x&want=" . IDs[currencyName] . "&have=" . IDs["Chaos Orb"]
	}
	
    HttpObj.Open("GET",Url)
	HttpObj.Send()
    HttpObj.WaitForResponse()
    html := HttpObj.ResponseText

	if (init) {
		FunctionParseCurrencyIDs(html)
		Return
	}
	
    Return, html
}

; Open given Url with default Browser
FunctionOpenUrlInBrowser(Url){
	Global TradeOpts
	
	if (TradeOpts.OpenWithDefaultWin10Fix) {
		openWith := AssociatedProgram("html") 
		Run, %openWith% -new-tab "%Url%"
	}
	else {		
		Run %Url%
	}		
}

; Parse currency.poe.trade to get all available currencies and their IDs
FunctionParseCurrencyIDs(html){
	RegExMatch(html, "is)id=""currency-want"">(.*?)input", match)	
	Currencies := {}
	
	Loop {
		Div          := StrX( match1, "<div data-tooltip",  N, 0, "<img" , 1,4, N )
        CurrencyName := StrX( Div,  "title=""",             1, 7, """"   , 1,1, T )
        CurrencyID   := StrX( Div,  "data-id=""",           1, 9, """"   , 1,1    )			
		CurrencyName := StrReplace(CurrencyName, "&#39;", "'")
		
		If (!CurrencyName) {			
			TradeGlobals.Set("CurrencyIDs", Currencies)
			break
		}
		
		Currencies[CurrencyName] := CurrencyID  
		TradeGlobals.Set("CurrencyIDs", Currencies)
	}
}

; Parse currency.poe.trade to display tooltip with first X listings
FunctionParseCurrencyHtml(html, payload){
	Global Item, ItemData, TradeOpts
	LeagueName := TradeGlobals.Get("LeagueName")

	Title := Item.Name
	Title .= " (" LeagueName ")"
	Title .= "`n------------------------------ `n"	
	NoOfItemsToShow := TradeOpts.ShowItemResults
	
	Title .= StrPad("IGN" ,10) 	
	Title .= StrPad("| Ratio",20)	
	Title .= "| " . StrPad("Buy  ",20, "Left")	
	Title .= StrPad("Pay",20)	
	Title .= "`n"
	
	Title .= StrPad("----------" ,10) 	
	Title .= StrPad("--------------------",20)	
	Title .= StrPad("--------------------",20)	
	Title .= StrPad("--------------------",20)		
	Title .= "`n"

	While A_Index < NoOfItemsToShow {
        Offer       := StrX( html,   "data-username=""",     N, 0, "<a href"   , 1,1, N )
        SellCurrency:= StrX( Offer,  "data-sellcurrency=""", 1,19, """"        , 1,1, T )
        SellValue   := StrX( Offer,  "data-sellvalue=""",    1,16, """"        , 1,1, T )
        BuyValue    := StrX( Offer,  "data-buyvalue=""",     1,15, """"        , 1,1, T )
        BuyCurrency := StrX( Offer,  "data-buycurrency=""",  1,18, """"        , 1,1, T )
        AccountName := StrX( Offer,  "data-ign=""",          1,10, """"        , 1,1    )
	
		RatioBuying := BuyValue / SellValue
		RatioSelling  := SellValue / BuyValue
		
		Pos := RegExMatch(Offer, "si)displayoffer-primary(.*)<.*displayoffer-centered", Display)
		P := ""
		DisplayNames := []
		Loop {
			Column := StrX( Display1, "column", P, 0, "</div", 1,1, P )
			RegExMatch(Column, ">(.*)<", Column)
			Column := RegExReplace(Column1, "\t|\r|\n", "")
			If (StrLen(Column) < 1) {
				Break
			}
			DisplayNames.Push(Column)
		}	
		
		subAcc := FunctionTrimNames(AccountName, 10, true)
		Title .= StrPad(subAcc,10) 
		Title .= StrPad("| " . "1 <-- " . zerotrimmer(RatioBuying)            ,20)
		Title .= StrPad("| " . StrPad(DisplayNames[1] . " " . StrPad(zerotrimmer(SellValue), 4, "left"), 17, "left") ,20)
		Title .= StrPad("<= " . StrPad(zerotrimmer(BuyValue), 4) . " " . DisplayNames[3] ,20)		
		Title .= "`n"		
	}
	
	Return, Title
}

; Trim trailing zeros from numbers
zerotrimmer(number) { 
	RegExMatch(number, "(\d+)\.?(.+)?", match)
	If (StrLen(match2) < 1) {
		return number
	} else {
		trail := RegExReplace(match2, "0+$", "")
		number := (StrLen(trail) > 0) ? match1 "." trail : match1
		return number
	}
}

; Calculate average and median price of X listings
FunctionGetMeanMedianPrice(html, payload){
	itemCount := 1
    prices := []
    average := 0
	Title := ""
	
	; loop over the first 99 results if possible, otherwise over as many as are available
	accounts := []
	NoOfItemsToCount := 99
	NoOfItemsSkipped := 0
    While A_Index <= NoOfItemsToCount {
		TBody       := StrX( html,   "<tbody id=""item-container-" . %A_Index%,  N, 0, "</tbody>" , 1,23, N )
        AccountName := StrX( TBody,  "data-seller=""",                           1,13, """"       , 1,1,  T )
        ChaosValue  := StrX( TBody,  "data-name=""price_in_chaos""",             T, 0, "currency" , 1,1     )	
		
		; skip multiple results from the same account		
		If (TradeOpts.RemoveMultipleListingsFromSameAccount) {
			If (FunctionIsInArray(AccountName, accounts)) {
				NoOfItemsToShow := NoOfItemsToShow + 1
				NoOfItemsSkipped := NoOfItemsSkipped + 1
				continue
			} Else {
				accounts.Push(AccountName)
			}
		}		
		
        If (StrLen(ChaosValue) <= 0) {
            Continue
        }  Else { 
            itemCount++
        }
        
		; add chaos-equivalents (chaos prices) together and count results
        RegExMatch(ChaosValue, "i)data-value=""-?(\d+.?\d+?)""", priceChaos)
        If (StrLen(priceChaos1) > 0) {
            SetFormat, float, 6.2            
            StringReplace, FloatNumber, priceChaos1, ., `,, 1
            average += priceChaos1
            prices[itemCount-1] := priceChaos1
        }
    }
    
	; calculate average and median prices
    If (prices.MaxIndex() > 0) {
		; average
        average := average / (itemCount - 1)
		Title .= "Average price in chaos: " average " (" prices.MaxIndex() " results"
		Title .= (NoOfItemsSkipped > 0) ? ", " NoOfItemsSkipped " removed" : ""		
		Title .= ") `n"
		
		; median
        If (prices.MaxIndex()&1) {
			; results count is odd
			index1 := Floor(prices.MaxIndex()/2)
			index2 := Ceil(prices.MaxIndex()/2)
			median := (prices[index1] + prices[index2]) / 2
			if (median > 2) {
				median := Round(median, 2)
			}
        }
        Else {
			; results count is even
			index := Floor(prices.MaxIndex()/2)
            median := prices[index]		
			if (median > 2) {
				median := Round(median, 2)
			}
        } 
		Title .= "Median  price in chaos: " median " (" prices.MaxIndex() " results"
		Title .= (NoOfItemsSkipped > 0) ? ", " NoOfItemsSkipped " removed" : ""		
		Title .= ") `n`n"
    }  
	return Title
}

; Parse poe.trade html to display the search result tooltip with X listings
FunctionParseHtml(html, payload, iLvl = "", ench = "")
{	
	Global Item, ItemData, TradeOpts
	LeagueName := TradeGlobals.Get("LeagueName")

	; Target HTML Looks like the ff:
    ;<tbody id="item-container-97" class="item" data-seller="Jobo" data-sellerid="458008" data-buyout="15 chaos" data-ign="Lolipop_Slave" data-league="Essence" data-name="Tabula Rasa Simple Robe" data-tab="This is a buff" data-x="10" data-y="9"> <tr class="first-line">

	if (not Item.IsGem and not Item.IsDivinationCard and not Item.IsJewel and not Item.IsCurrency and not Item.IsMap) {
		showItemLevel := true
	}
	
	Name := (Item.IsRare and not Item.IsMap) ? Item.Name " " Item.TypeName : Item.Name
	Title := Trim(StrReplace(Name, "Superior", ""))
	
	if (Item.IsMap && !Item.isUnique) {
		; map fix (wrong Item.name on magic/rare maps)
		Title := 
		newName := Trim(StrReplace(Item.Name, "Superior", ""))
		newName := Trim(StrReplace(newName, "Shaped", ""))
		; prevent duplicate name on white and magic maps
		if (newName != Item.SubType) {
			s := Trim(RegExReplace(Item.Name, "Superior|Shaped", "")) 
			s := Trim(StrReplace(s, Item.SubType, "")) 
			Title .= "(" RegExReplace(s, " +", " ") ") "
		}
		; add "Shaped" to item title since it's missing from Item.name	 		
		if (InStr(ItemData.Nameplate, "Shaped")) {
			Title .= "Shaped "
		}
		Title .= Trim(StrReplace(Item.SubType, "Superior", ""))
	}
	
	; add corrupted tag
	if (Item.IsCorrupted) {
		Title .= " [Corrupted] "
	}
	
	; add gem quality and level
	if (Item.IsGem) {
		Title := Item.Name ", Q" Item.Quality "%"
		if (Item.Level >= 16) {
			Title := Item.Name ", " Item.Level "`/" Item.Quality "%"
		}
	}
	; add item sockets and links
    if (ItemData.Sockets >= 5) {
		Title := Name " " ItemData.Sockets "s" ItemData.Links "l"
	}
	if (showItemLevel) {
		Title .= ", iLvl: " iLvl
	}
	
	Title .= ", (" LeagueName ")"
	Title .= "`n------------------------------ `n"	
	
	; add notes what parameters where used in the search
	if (Item.UsedInSearch) {
		Title .= "Used in " . Item.UsedInSearch.SearchType . " Search: "
		Title .= (Item.UsedInSearch.Enchantment)  ? "Enchantment " : "" 	
		Title .= (Item.UsedInSearch.CorruptedMod) ? "Corr. Implicit " : "" 	
		Title .= (Item.UsedInSearch.Sockets)      ? "| " . Item.UsedInSearch.Sockets . "S " : ""
		Title .= (Item.UsedInSearch.Links)        ? "| " . Item.UsedInSearch.Links   . "L " : ""
		if (Item.UsedInSearch.iLvl.min and Item.UsedInSearch.iLvl.max) {
			Title .= "| iLvl (" . Item.UsedInSearch.iLvl.min . "-" . Item.UsedInSearch.iLvl.max . ")"
		}
		else {
			Title .= (Item.UsedInSearch.iLvl.min) ? "| iLvl (>=" . Item.UsedInSearch.iLvl.min . ") " : ""
			Title .= (Item.UsedInSearch.iLvl.max) ? "| iLvl (<=" . Item.UsedInSearch.iLvl.max . ") " : ""
		}		
		Title .= (Item.UsedInSearch.FullName)     ? "| Full Name " : ""
		Title .= (Item.UsedInSearch.Corruption)   ? "| Corrupted (" . Item.UsedInSearch.Corruption . ") " : ""
		Title .= (Item.UsedInSearch.Type)         ? "| Type (" . Item.UsedInSearch.Type . ") " : ""
		Title .= (Item.UsedInSearch.ItemBase)     ? "| Base (" . Item.UsedInSearch.ItemBase . ") " : ""
		
		Title .= "`n------------------------------ `n"	
	}	
	
	; add average and median prices to title	
	Title .= FunctionGetMeanMedianPrice(html, payload)
	
    NoOfItemsToShow := TradeOpts.ShowItemResults
	; add table headers to tooltip
	Title .= FunctionShowAcc(StrPad("Account",10), "|") 
	Title .= StrPad("IGN",20) 	
	Title .= StrPad(StrPad("| Price ", 19, "right") . "|",20,"left")	
		
	if (Item.IsGem) {
		; add gem headers
		Title .= StrPad("Q. |",6,"left")
		Title .= StrPad("Lvl |",6,"left")
	}
	if (showItemLevel) {
		; add ilvl
		Title .= StrPad("iLvl |",7,"left")
	}
	Title .= StrPad("   Age",8)	
	Title .= "`n"
	
	; add table head underline
	Title .= FunctionShowAcc(StrPad("----------",10), "-") 
	Title .= StrPad("--------------------",20) 
	Title .= StrPad("--------------------",19,"left")
	if (Item.IsGem) {
		Title .= StrPad("------",6,"left")
		Title .= StrPad("------",6,"left")
	}	
	if (showItemLevel) {
		Title .= StrPad("-------",8,"left")
	}
	Title .= StrPad("----------",8,"left")	
	Title .= "`n"
	
	; add search results to tooltip in table format
	accounts := []
    While A_Index < NoOfItemsToShow {
        TBody       := StrX( html,   "<tbody id=""item-container-" . %A_Index%,  N,0,  "</tbody>", 1,23, N )
        AccountName := StrX( TBody,  "data-seller=""",                           1,13, """"  ,     1,1,  T )
        Buyout      := StrX( TBody,  "data-buyout=""",                           T,13, """"  ,     1,1,  T )
        IGN         := StrX( TBody,  "data-ign=""",                              T,10, """"  ,     1,1     )
		
		; skip multiple results from the same account
		if (TradeOpts.RemoveMultipleListingsFromSameAccount) {
			if (FunctionIsInArray(AccountName, accounts)) {
				NoOfItemsToShow := NoOfItemsToShow + 1
				continue
			} else {
				accounts.Push(AccountName)
			}
		}		
		
		; get item age
		Pos := RegExMatch(TBody, "i)class=""found-time-ago"">(.*?)<", Age)
		
		if (showItemLevel) {
			; get item level
			Pos := RegExMatch(TBody, "i)data-name=""ilvl"">.*: ?(\d+?)<", iLvl, Pos)
		}		
		if (Item.IsGem) {
			; get gem quality and level
			Pos := RegExMatch(TBody, "i)data-name=""q"".*?data-value=""(.*?)""", Q, Pos)
			Pos := RegExMatch(TBody, "i)data-name=""level"".*?data-value=""(.*?)""", LVL, Pos)
		}		
		
		; trim account and ign
		subAcc := FunctionTrimNames(AccountName, 10, true)
		subIGN := FunctionTrimNames(IGN, 20, true) 
		
        Title .= FunctionShowAcc(StrPad(subAcc,10), "|") 
		Title .= StrPad(subIGN,20) 
		Title .= StrPad("| " . Buyout . "",19,"right") 
		
		if (Item.IsGem) {
			; add gem info
			if (Q1 > 0) {
				Title .= StrPad("| " . StrPad(Q1,2,"left") . "% ",6,"right")
			} else {
				Title .= StrPad("|  -  ",6,"right")
			}
			Title .= StrPad("| " . StrPad(LVL1,3,"left") . " |" ,7,"right")
		}
		if (showItemLevel) {
			; add item level
			Title .= StrPad("| " . StrPad(iLvl1,3,"left") . "  |" ,8,"right")
		}	
		; add item age
		Title .= StrPad(FunctionFormatItemAge(Age1),10)
		Title .= "`n"
    }

    Return, Title
}

FunctionIsInArray(el, array) {
	For i, element in array {
		If (el = "") {
			return false
		}
		If (element = el) {
			return true
		}
	}
	return false
}

; Trim names/string and add dots at the end if they are longer than specified length
FunctionTrimNames(name, length, addDots) {
	s := SubStr(name, 1 , length)
	if (StrLen(name) > length + 3 && addDots) {
		StringTrimRight, s, s, 3
		s .= "..."
	}
	return s
}

; Add sellers accountname to string if that option is selected
FunctionShowAcc(s, addString) {
	if (TradeOpts.ShowAccountName = 1) {
		s .= addString
		return s	
	}	
}

; format item age to be shorter
FunctionFormatItemAge(age) {
	age := RegExReplace(age, "^a", "1")
	RegExMatch(age, "\d+", value)
	RegExMatch(age, "i)month|week|yesterday|hour|minute|second|day", unit)
	
	if (unit = "month") {
		unit := " mo"
	} else if (unit = "week") {
		unit := " week"
	} else if (unit = "day") {
		unit := " day"
	} else if (unit = "yesterday") {
		unit := " day"
		value := "1"
	} else if (unit = "hour") {
		unit := " h"
	} else if (unit = "minute") {
		unit := " min"
	} else if (unit = "second") {
		unit := " sec"
	} 		
	
	s := " " StrPad(value, 3, left) unit
	
	return s
}

; ------------------------------------------------------------------------------------------------------------------ ;
; StrX function for parsing html, see simple example usage at https://gist.github.com/thirdy/9cac93ec7fd947971721c7bdde079f94
; ------------------------------------------------------------------------------------------------------------------ ;

; Cleanup StrX function and Google Example from https://autohotkey.com/board/topic/47368-strx-auto-parser-for-xml-html
; By SKAN

;1 ) H = HayStack. The "Source Text"
;2 ) BS = BeginStr. Pass a String that will result at the left extreme of Resultant String
;3 ) BO = BeginOffset. 
; Number of Characters to omit from the left extreme of "Source Text" while searching for BeginStr
; Pass a 0 to search in reverse ( from right-to-left ) in "Source Text"
; If you intend to call StrX() from a Loop, pass the same variable used as 8th Parameter, which will simplify the parsing process.
;4 ) BT = BeginTrim. 
; Number of characters to trim on the left extreme of Resultant String
; Pass the String length of BeginStr if you want to omit it from Resultant String
; Pass a Negative value if you want to expand the left extreme of Resultant String
;5 ) ES = EndStr. Pass a String that will result at the right extreme of Resultant String
;6 ) EO = EndOffset. 
; Can be only True or False. 
; If False, EndStr will be searched from the end of Source Text. 
; If True, search will be conducted from the search result offset of BeginStr or from offset 1 whichever is applicable.
;7 ) ET = EndTrim. 
; Number of characters to trim on the right extreme of Resultant String
; Pass the String length of EndStr if you want to omit it from Resultant String
; Pass a Negative value if you want to expand the right extreme of Resultant String
;8 ) NextOffset : A name of ByRef Variable that will be updated by StrX() with the current offset, You may pass the same variable as Parameter 3, to simplify data parsing in a loop

StrX(H,  BS="",BO=0,BT=1,   ES="",EO=0,ET=1,  ByRef N="" ) 
{ 
        Return SubStr(H,P:=(((Z:=StrLen(ES))+(X:=StrLen(H))+StrLen(BS)-Z-X)?((T:=InStr(H,BS,0,((BO
            <0)?(1):(BO))))?(T+BT):(X+1)):(1)),(N:=P+((Z)?((T:=InStr(H,ES,0,((EO)?(P+1):(0))))?(T-P+Z
            +(0-ET)):(X+P)):(X)))-P)
}
; v1.0-196c 21-Nov-2009 www.autohotkey.com/forum/topic51354.html
; | by Skan | 19-Nov-2009

class RequestParams_ {
	league := ""
	xtype := ""
	xbase := ""
	name := ""
	dmg_min := ""
	dmg_max := ""
	aps_min := ""
	aps_max := ""
	crit_min := ""
	crit_max := ""
	dps_min := ""
	dps_max := ""
	edps_min := ""
	edps_max := ""
	pdps_min := ""
	pdps_max := ""
	armour_min := ""
	armour_max := ""
	evasion_min := ""
	evasion_max := ""
	shield_min := ""
	shield_max := ""
	block_min := ""
	block_max := ""
	sockets_min := ""
	sockets_max := ""
	link_min := ""
	link_max := ""
	sockets_r := ""
	sockets_g := ""
	sockets_b := ""
	sockets_w := ""
	linked_r := ""
	linked_g := ""
	linked_b := ""
	linked_w := ""
	rlevel_min := ""
	rlevel_max := ""
	rstr_min := ""
	rstr_max := ""
	rdex_min := ""
	rdex_max := ""
	rint_min := ""
	rint_max := ""
	; For future development, change this to array to provide multi mod groups
	modGroup := new _ParamModGroup()
	q_min := ""
	q_max := ""
	level_min := ""
	level_max := ""
	ilvl_min := ""
	ilvl_max := ""
	rarity := ""
	seller := ""
	xthread := ""
	identified := ""
	corrupted := "0"
	online := (TradeOpts.OnlineOnly == 0) ? "" : "x"
	buyout := "x"
	altart := ""
	capquality := "x"
	buyout_min := ""
	buyout_max := ""
	buyout_currency := ""
	crafted := ""
	enchanted := ""
	
	ToPayload() 
	{
		modGroupStr := this.modGroup.ToPayload()
		
		p := "league=" this.league "&type=" this.xtype "&base=" this.xbase "&name=" this.name "&dmg_min=" this.dmg_min "&dmg_max=" this.dmg_max "&aps_min=" this.aps_min "&aps_max=" this.aps_max "&crit_min=" this.crit_min "&crit_max=" this.crit_max "&dps_min=" this.dps_min "&dps_max=" this.dps_max "&edps_min=" this.edps_min "&edps_max=" this.edps_max "&pdps_min=" this.pdps_min "&pdps_max=" this.pdps_max "&armour_min=" this.armour_min "&armour_max=" this.armour_max "&evasion_min=" this.evasion_min "&evasion_max=" this.evasion_max "&shield_min=" this.shield_min "&shield_max=" this.shield_max "&block_min=" this.block_min "&block_max=" this.block_max "&sockets_min=" this.sockets_min "&sockets_max=" this.sockets_max "&link_min=" this.link_min "&link_max=" this.link_max "&sockets_r=" this.sockets_r "&sockets_g=" this.sockets_g "&sockets_b=" this.sockets_b "&sockets_w=" this.sockets_w "&linked_r=" this.linked_r "&linked_g=" this.linked_g "&linked_b=" this.linked_b "&linked_w=" this.linked_w "&rlevel_min=" this.rlevel_min "&rlevel_max=" this.rlevel_max "&rstr_min=" this.rstr_min "&rstr_max=" this.rstr_max "&rdex_min=" this.rdex_min "&rdex_max=" this.rdex_max "&rint_min=" this.rint_min "&rint_max=" this.rint_max modGroupStr "&q_min=" this.q_min "&q_max=" this.q_max "&level_min=" this.level_min "&level_max=" this.level_max "&ilvl_min=" this.ilvl_min "&ilvl_max=" this.ilvl_max "&rarity=" this.rarity "&seller=" this.seller "&thread=" this.xthread "&identified=" this.identified "&corrupted=" this.corrupted "&online=" this.online "&buyout=" this.buyout "&altart=" this.altart "&capquality=" this.capquality "&buyout_min=" this.buyout_min "&buyout_max=" this.buyout_max "&buyout_currency=" this.buyout_currency "&crafted=" this.crafted "&enchanted=" this.enchanted
		return p
	}
}

class _ParamModGroup {
	ModArray := []
	group_type := "And"
	group_min := ""
	group_max := ""
	group_count := 1
	
	ToPayload() 
	{
		p := ""
		
		if (this.ModArray.Length() = 0) {
			this.AddMod(new _ParamMod())
		}
		this.group_count := this.ModArray.Length()
		Loop % this.ModArray.Length()
			p .= this.ModArray[A_Index].ToPayload()
		p .= "&group_type=" this.group_type "&group_min=" this.group_min "&group_max=" this.group_max "&group_count=" this.group_count
		return p
	}
	AddMod(paraModObj) {
		this.ModArray.Push(paraModObj)
	}
}

class _ParamMod {
	mod_name := ""
	mod_min := ""
	mod_max := ""
	ToPayload() 
	{
		; for some reason '+' is not encoded properly, this affects mods like '+#% to all Elemental Resistances'
		this.mod_name := StrReplace(this.mod_name, "+", "%2B")
		p := "&mod_name=" this.mod_name "&mod_min=" this.mod_min "&mod_max=" this.mod_max
		return p
	}
}

; Return unique item with its variable mods and mod ranges if it has any
FunctionFindUniqueItemIfItHasVariableRolls(name)
{
	data := TradeGlobals.Get("VariableUniqueData")
	For index, uitem in data {		
		If (uitem.name = name ) {
			return uitem
		}
	}  
	return false
}

; Add poetrades mod names to the items mods to use as POST parameter
FunctionGetItemsPoeTradeMods(item) {
	mods := TradeGlobals.Get("ModsData")
	
	/*
	; loop over poetrade mod groups
	returnItem := item	

	matchCount := 0
	For i, modgroup in mods {		
		; loop over modgroup mods
		For j, mod in modgroup {
			; loop over items variable mods
			For k, imod in item.mods {	
				s := Trim(RegExReplace(mod, "i)\(pseudo\)|\(total\)|\(crafted\)|\(implicit\)|\(explicit\)|\(enchant\)|\(prophecy\)", ""))
				ss := Trim(imod.name)				
				If (s = ss) {
					;MsgBox % s
					; add poetrades mod name to item (POST param)
					returnItem.mods[k]["param"] := mod
					
					If (matchCount >= item.mods.maxIndex()) {						
						return returnItem
					}
					matchCount++
				}
			}
		}	
	} 
	*/
	
	; use this to control search order (which group is more important)
	For k, imod in item.mods {	
		item.mods[k]["param"] := FunctionFindInModGroup(mods["[total] mods"], item.mods[k])
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["[pseudo] mods"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["explicit"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["implicit"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["unique explicit"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["crafted"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["enchantments"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["prophecies"], item.mods[k])
		}
	}

	return item
}

; Add poe.trades mod names to the items mods to use as POST parameter
FunctionGetItemsPoeTradeUniqueMods(item) {
	mods := TradeGlobals.Get("ModsData")
	For k, imod in item.mods {	
		item.mods[k]["param"] := FunctionFindInModGroup(mods["unique explicit"], item.mods[k])
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["explicit"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["[total] mods"], item.mods[k])
		}
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["[pseudo] mods"], item.mods[k])
		}
	}
	return item
}

; find mod in modgroup and return its name
FunctionFindInModGroup(modgroup, needle) {
	For j, mod in modgroup {
		s  := Trim(RegExReplace(mod, "i)\(pseudo\)|\(total\)|\(crafted\)|\(implicit\)|\(explicit\)|\(enchant\)|\(prophecy\)", ""))
		s  := RegExReplace(s, "# ?to ? #", "#")
		ss := Trim(needle.name)	
		;matches "1 to" in for example "adds 1 to (20-40) lightning damage"
		ss := RegExReplace(ss, "\d+ ?to ?#", "#")	
		
		If (s = ss) {
			return mod
		}
	}
	return ""
}

FunctionGetCorruption(item) {
	mods     := TradeGlobals.Get("ModsData")	
	corrMods := TradeGlobals.Get("CorruptedModsData")
	RegExMatch(item.Implicit, "i)([-.0-9]+)", value)
	imp      := RegExReplace(item.Implicit, "i)([-.0-9]+)", "#")
	
	corrMod  := {}
	For i, corr in corrMods {	
		If (imp = corr) {
			For j, mod in mods["implicit"] {					
				match := Trim(RegExReplace(mod, "i)\(implicit\)", ""))					
				If (match = corr) {
					corrMod.param := mod
					corrMod.name  := item.implicit
				}
			}
		}
	}	
	
	valueCount := 0
	Loop {
		If (!value%A_Index%) {
			break
		}	
		valueCount++
	}
	If (StrLen(corrMod.param)) {
		If (valueCount = 1) {
			corrMod.min := value1
		}
		return corrMod
	}
	Else {
		return false
	}
}

FunctionGetEnchantment(item, type) {
	mods     := TradeGlobals.Get("ModsData")	
	enchants := TradeGlobals.Get("EnchantmentData")	

	If (type = "Boots") {
		group := enchants.boots
	} 
	Else If (type = "Gloves") {
		group := enchants.gloves
	} 
	Else If (type = "Helmet") {
		group := enchants.helmet
	} 

	RegExMatch(item.implicit, "i)([.0-9]+)(%? to ([.0-9]+))?", values)
	imp      := RegExReplace(item.implicit, "i)([.0-9]+)", "#")

	enchantment := {}	
					
	If (group.length()) {	
		For i, enchant in group {	
			If (imp = enchant) {
				For j, mod in mods["enchantments"] {					
					match := Trim(RegExReplace(mod, "i)\(enchant\)", ""))					
					If (match = enchant) {
						enchantment.param := mod
						enchantment.name  := item.implicit
					}
				}
			}
		}
	}	
	
	valueCount := 0
	Loop {
		If (!values%A_Index%) {
			break
		}	
		valueCount++
	}

	If (StrLen(enchantment.param)) {
		If (valueCount = 1) {
			enchantment.min := values1
			enchantment.max := values1
		}
		Else If (valueCount = 3) {
			enchantment.min := values1
			enchantment.max := values3
		}
		return enchantment
	}
	Else {
		return false
	}
}

FunctionGetModValueGivenPoeTradeMod(itemModifiers, poeTradeMod) {
	Loop, Parse, itemModifiers, `n, `r
	{
		If StrLen(A_LoopField) = 0
		{
			Continue ; Not interested in blank lines
		}
		CurrValue := ""
		CurrValues := []
		CurrValue := GetActualValue(A_LoopField)
		if (CurrValue ~= "\d+") {
			
			; handle value range
			RegExMatch(CurrValue, "(\d+) ?(-|to) ?(\d+)", values)			
			if (values3) {
				CurrValues.Push(values1)
				CurrValues.Push(values3)
				CurrValue := values1 " to " values3
				ModStr := StrReplace(A_LoopField, CurrValue, "# to #")		
			}
			; handle single value
			else {
				CurrValues.Push(CurrValue)
				ModStr := StrReplace(A_LoopField, CurrValue, "#")		
			}			
					
			ModStr := StrReplace(ModStr, "+")
			; replace multi spaces with a single one
			ModStr := RegExReplace(ModStr, " +", " ")			
			;MsgBox % "Loop: " A_LoopField "`nCurr: " CurrValue "`nModStr: " ModStr "`ntradeMod: " poeTradeMod
			
			IfInString, poeTradeMod, % ModStr
			{			
				return CurrValues
			}
		}
	}
}

; Open Gui window to show the items variable mods, select the ones that should be used in the search and se their min/max values
AdvancedPriceCheckGui(advItem, Stats, UniqueStats = "", ChangedImplicit = ""){	
	;https://autohotkey.com/board/topic/9715-positioning-of-controls-a-cheat-sheet/
	Global 

	TradeGlobals.Set("AdvancedPriceCheckItem", advItem)
	ValueRange := TradeOpts.AdvancedSearchModValueRange

	Gui, SelectModsGui:Destroy    
    Gui, SelectModsGui:Add, Text, x10 y12, Percentage to pre-calculate min/max values: 
	Gui, SelectModsGui:Add, Text, x+5 yp+0 cGreen, % ValueRange "`%" 
    Gui, SelectModsGui:Add, Text, x10 y+8, This calculation considers the items mods difference between their min and max value as 100`%.			
	
	ValueRange := ValueRange / 100 	
		
	Loop % advItem.mods.Length() {	
		tempValue := StrLen(advItem.mods[A_Index].name)
		if(modLengthMax < tempValue ) {
			modLengthMax := tempValue
			modGroupBox := modLengthMax * 6
		}
	}
	modCount := advItem.mods.Length()
	
	statCount := 0
	For i, stat in Stats.Defense {
		statCount := (stat.value) ? statCount + 1 : statCount
	}
	For i, stat in Stats.Offense {
		statCount := (stat.value) ? statCount + 1 : statCount
	}
	statCount := (ChangedImplicit) ? statCount + 1 : statCount

	boxRows := modCount * 3 + statCount * 3 
	;Gui, SelectModsGui:Add, Groupbox, x10 y+10 w%modGroupBox% r%boxRows%, Mods
	;Gui, SelectModsGui:Add, Groupbox, x+10 yp+0 w80 r%boxRows%, min
	;Gui, SelectModsGui:Add, Groupbox, x+10 yp+0 w80 r%boxRows%, current
;	Gui, SelectModsGui:Add, Groupbox, x+10 yp+0 w80 r%boxRows%, max
	;Gui, SelectModsGui:Add, Groupbox, x+10 yp+0 w45 r%boxRows%, Select
	
	Gui, SelectModsGui:Add, Text, x14 y+10 w%modGroupBox%, Mods
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w80, min
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w80, current
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w80, max
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w45, Select

	line :=
	Loop, 500 {
		line := line . "-"
	}
	Gui, SelectModsGui:Add, Text, x0 w700 yp+13, %line% 	
	
	;add defense stats
	j := 1
	For i, stat in Stats.Defense {
		If (stat.value) {			
			xPosMin := modGroupBox + 25
			yPosFirst := ( j = 1 ) ? 30 : 45		
			
			if (stat.Name != "Block Chance") {
				stat.value   := Round(stat.value * 100 / (100 + Stats.Quality)) 
				statValueQ20 := Round(stat.value * ((100 + 20) / 100))
			}
			
			; calculate values to prefill min/max fields		
			; assume the difference between the theoretical max and min value as 100%
			statValueMin := Round(statValueQ20 - ((stat.max - stat.min) * valueRange))
			statValueMax := Round(statValueQ20 + ((stat.max - stat.min) * valueRange))			
			
			minLabelFirst := "(" zerotrimmer(stat.min)
			minLabelSecond := ")" 
			maxLabelFirst := "(" zerotrimmer(stat.max)
			maxLabelSecond := ")"
			
			Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%							 , % "(Total Q20) " stat.name
			Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w70 vTradeAdvancedStatMin%j% r1, % statValueMin
			Gui, SelectModsGui:Add, Text, xp+5 yp+25 w65 cGreen                          , % minLabelFirst minLabelSecond
			Gui, SelectModsGui:Add, Text, x+20 yp-22 w70 r1								 , % statValueQ20
			Gui, SelectModsGui:Add, Edit, x+20 yp-3 w70 vTradeAdvancedStatMax%j% r1	     , % statValueMax
			Gui, SelectModsGui:Add, Text, xp+5 yp+25 w65 cGreen                          , % maxLabelFirst maxLabelSecond
			Gui, SelectModsGui:Add, CheckBox, x+30 yp-20 vTradeAdvancedStatSelected%j%
			
			TradeAdvancedStatParam%j% := stat.name			
			j++
		}
	}	
	
	If (j > 1) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+33 cc9cacd, %line% 
	}	
		
	k := 1
	;add dmg stats
	For i, stat in Stats.Offense {
		If (stat.value) {			
			xPosMin := modGroupBox + 25
			yPosFirst := ( j = 1 ) ? 20 : 45			

			; calculate values to prefill min/max fields		
			; assume the difference between the theoretical max and min value as 100%
			statValueMin := Round(stat.value - ((stat.max - stat.min) * valueRange))
			statValueMax := Round(stat.value + ((stat.max - stat.min) * valueRange))			
			
			minLabelFirst := "(" zerotrimmer(stat.min)
			minLabelSecond := ")" 
			maxLabelFirst := "(" zerotrimmer(stat.max)
			maxLabelSecond := ")"
			
			Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%							 , % stat.name
			Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w70 vTradeAdvancedStatMin%j% r1, % statValueMin
			Gui, SelectModsGui:Add, Text, xp+5 yp+25 w65 cGreen                          , % minLabelFirst minLabelSecond
			Gui, SelectModsGui:Add, Text, x+20 yp-22 w70 r1								 , % stat.value
			Gui, SelectModsGui:Add, Edit, x+20 yp-3 w70 vTradeAdvancedStatMax%j% r1	     , % statValueMax
			Gui, SelectModsGui:Add, Text, xp+5 yp+25 w65 cGreen                          , % maxLabelFirst maxLabelSecond
			Gui, SelectModsGui:Add, CheckBox, x+30 yp-20 vTradeAdvancedStatSelected%j%
			
			TradeAdvancedStatParam%j% := stat.name			
			j++
			k++
		}
	}

	If (k > 1) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+33 cc9cacd, %line% 
	}	

	e := 0
	; Enchantment or Corrupted Implicit
	If (ChangedImplicit) {
		e := 1
		xPosMin := modGroupBox + 25	
		yPosFirst := ( j > 1 ) ? 20 : 30
		
		modValueMin := ChangedImplicit.min
		modValueMax := ChangedImplicit.max
		displayName := ChangedImplicit.name
		
		Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%                                   , % displayName
		;Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w70 vTradeAdvancedModMin%e% r1       , % modValueMin
		;Gui, SelectModsGui:Add, Text, xp+5 yp+25      w65 cGreen                           , % modValueMin
		;Gui, SelectModsGui:Add, Text, x+20 yp-22      w70 r1                               , % modValueMax
		;Gui, SelectModsGui:Add, Edit, x+20 yp-3       w70 vTradeAdvancedModMax%e% r1       , % modValueMax
		;Gui, SelectModsGui:Add, Text, xp+5 yp+25      w65 cGreen                           , % ""
		Gui, SelectModsGui:Add, CheckBox, x449 yp+1      vTradeAdvancedSelected%e%
		
		TradeAdvancedModMin%e% 		:= ChangedImplicit.min
		TradeAdvancedModMax%e% 		:= ChangedImplicit.max
		TradeAdvancedParam%e%  		:= ChangedImplicit.param
		TradeAdvancedIsImplicit%e%  := true
	}
	
	If (ChangedImplicit) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+18 cc9cacd, %line% 
	}	
	
	;add mods	
	Loop % advItem.mods.Length() {
		xPosMin := modGroupBox + 25			
	
		; matches "1 to #" in for example "adds 1 to # lightning damage"
		if (RegExMatch(advItem.mods[A_Index].name, "i)Adds (\d+(.\d+)?) to #.*Damage", match)) {
			displayName := RegExReplace(advItem.mods[A_Index].name, "\d+(.\d+)? to #", "#")
			staticValue := match1
		}
		else {
			displayName := advItem.mods[A_Index].name			
			staticValue := 	
		}
		
		if (advItem.mods[A_Index].ranges.Length() > 1) {
			theoreticalMinValue := advItem.mods[A_Index].ranges[1][1]
			theoreticalMaxValue := advItem.mods[A_Index].ranges[2][2]
		}
		else {
			; use staticValue to create 2 ranges; for example (1 to 50) to (1 to 70) instead of having only (50 to 70)  
			if (staticValuee) {
				theoreticalMinValue := staticValue
				theoreticalMaxValue := advItem.mods[A_Index].ranges[1][2]
			}
			else {
				theoreticalMinValue := advItem.mods[A_Index].ranges[1][1]
				theoreticalMaxValue := advItem.mods[A_Index].ranges[1][2]
			}
		}
		
		SetFormat, FloatFast, 5.2
		
		modValues := FunctionGetModValueGivenPoeTradeMod(ItemData.Affixes, advItem.mods[A_Index].param)
		if (modValues.Length() > 1) {
			modValue := (modValues[1] + modValues[2]) / 2
		}
		else {
			modValue := modValues[1]
		}	

		; calculate values to prefill min/max fields		
		; assume the difference between the theoretical max and min value as 100%
		modValueMin := modValue - ((theoreticalMaxValue - theoreticalMinValue) * valueRange)
		modValueMax := modValue + ((theoreticalMaxValue - theoreticalMinValue) * valueRange)
		; floor values only if greater than 2, in case of leech/regen mods
		modValueMin := (modValueMin > 2) ? Floor(modValueMin) : modValueMin
		modValueMax := (modValueMax > 2) ? Floor(modValueMax) : modValueMax
		
		; prevent calculated values being smaller than the lowest possible min value or being higher than the highest max values
		modValueMin := zerotrimmer((modValueMin < theoreticalMinValue and not staticValue) ? theoreticalMinValue : modValueMin)
		modValueMax := zerotrimmer((modValueMax > theoreticalMaxValue) ? theoreticalMaxValue : modValueMax)

		; create Labels to show unique items min/max rolls		
		if (advItem.mods[A_Index].ranges[2][1]) {
			minLabelFirst := "(" zerotrimmer((advItem.mods[A_Index].ranges[1][1] + advItem.mods[A_Index].ranges[1][2]) / 2) ")"
			maxLabelFirst := "(" zerotrimmer((advItem.mods[A_Index].ranges[2][1] + advItem.mods[A_Index].ranges[2][2]) / 2) ")"
		}
		else if (staticValue) {
			minLabelFirst := "(" zerotrimmer((staticValue + advItem.mods[A_Index].ranges[1][1]) / 2) ")"
			maxLabelFirst := "(" zerotrimmer((staticValue + advItem.mods[A_Index].ranges[1][2]) / 2) ")"
		}
		else {
			minLabelFirst := "(" zerotrimmer(advItem.mods[A_Index].ranges[1][1]) ")"
			maxLabelFirst := "(" zerotrimmer(advItem.mods[A_Index].ranges[1][2]) ")"
		}
		
		yPosFirst := ( j > 1 ) ? 20 : 30
		; increment index if the item has an enchantment
		index := A_Index + e
		
		Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%                                   , % displayName
		Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w70 vTradeAdvancedModMin%index% r1   , % modValueMin
		Gui, SelectModsGui:Add, Text, xp+5 yp+25      w65 cGreen                           , % minLabelFirst
		Gui, SelectModsGui:Add, Text, x+20 yp-22      w70 r1                               , % zerotrimmer(modValue)
		Gui, SelectModsGui:Add, Edit, x+20 yp-3       w70 vTradeAdvancedModMax%index% r1   , % modValueMax
		Gui, SelectModsGui:Add, Text, xp+5 yp+25      w65 cGreen                           , % maxLabelFirst
		Gui, SelectModsGui:Add, CheckBox, x+30 yp-21      vTradeAdvancedSelected%index%
		
		TradeAdvancedParam%index% := advItem.mods[A_Index].param
	}
	
	Item.UsedInSearch.SearchType := "Advanced"
	; closes this window and starts the search
	Gui, SelectModsGui:Add, Button, x10 y+50 gAdvancedPriceCheckSearch, &Search
	
	; open search on poe.trade instead
	Gui, SelectModsGui:Add, Button, x+10 yp+0 gAdvancedOpenSearchOnPoeTrade, Op&en on poe.trade
	
	Gui, SelectModsGui:Add, Text, x+20 yp+5 cGray, (Pro-Tip: Use Alt + S/E to submit the buttons)
	
	windowWidth := modGroupBox + 80 + 10 + 10 + 80 + 80 + 10 + 60 + 20
	windowWidth := (windowWidth > 250) ? windowWidth : 250
    Gui, SelectModsGui:Show, w%windowWidth% , Select Mods to include in Search
}

AdvancedPriceCheckSearch:	
	FunctionHandleGuiSubmit()
	TradeMacroMainFunction(false, false, true)
return

AdvancedOpenSearchOnPoeTrade:	
	FunctionHandleGuiSubmit()
	TradeMacroMainFunction(true, false, true)
return

FunctionHandleGuiSubmit(){
	Global 
	
	Gui, SelectModsGui:Submit
	newItem := {mods:[], stats:[], UsedInSearch : {}}
	mods  := []	
	stats := []	
	
	Loop {
		mod := {param:"",selected:"",min:"",max:""}
		If (TradeAdvancedModMin%A_Index%) {
			mod.param    := TradeAdvancedParam%A_Index%
			mod.selected := TradeAdvancedSelected%A_Index%
			mod.min      := TradeAdvancedModMin%A_Index%
			mod.max      := TradeAdvancedModMax%A_Index%
			; has Enchantment
			If (RegExMatch(TradeAdvancedParam%A_Index%, "i)enchant")) {
				newItem.UsedInSearch.Enchantment := true
			}
			; has Corrupted Implicit
			Else If (TradeAdvancedIsImplicit%A_Index%) {
				newItem.UsedInSearch.CorruptedMod := true
			}
			
			mods.Push(mod)
		}
		Else {
			break
		}
	}
	
	Loop {
		stat := {param:"",selected:"",min:"",max:""}
		If (TradeAdvancedStatMin%A_Index%) {
			stat.param    := TradeAdvancedStatParam%A_Index%
			stat.selected := TradeAdvancedStatSelected%A_Index%
			stat.min      := TradeAdvancedStatMin%A_Index%
			stat.max      := TradeAdvancedStatMax%A_Index%
			
			stats.Push(stat)
		}
		Else {
			break
		}
	}
	
	newItem.mods := mods
	newItem.stats := stats
	
	TradeGlobals.Set("AdvancedPriceCheckItem", newItem)	
	Gui, SelectModsGui:Destroy
}

CloseUpdateWindow:
	Gui, UpdateNotification:Destroy
return

OverwriteSettingsTimer:
	o := Globals.Get("SettingsUIWidth")
	
	If (o) {
		Globals.Set("SettingsUIWidth", 1085)
		RelVer := TradeGlobals.Get("ReleaseVersion")
		Menu, Tray, Tip, Path of Exile TradeMacro %RelVer%
		OldMenuTrayName := Globals.Get("SettingsUITitle")
		NewMenuTrayName := TradeGlobals.Get("SettingsUITitle")
		Menu, Tray, Rename, % OldMenuTrayName, % NewMenuTrayName	
		Menu, Tray, Icon, %A_ScriptDir%\trade_data\poe-trade-bl.ico		
		SetTimer, OverwriteSettingsTimer, Off
	}	
return

TradeSettingsUI_BtnOK:
    Global TradeOpts
    Gui, Submit
	SavedTradeSettings := true
    Sleep, 50
    WriteTradeConfig()
    UpdateTradeSettingsUI()
return

TradeSettingsUI_BtnCancel:
    Gui, Cancel
return

TradeSettingsUI_BtnDefaults:
    Gui, Cancel
    RemoveTradeConfig()
    Sleep, 75
    CopyDefaultTradeConfig()
    Sleep, 75
    ReadTradeConfig()
    Sleep, 75
    UpdateTradeSettingsUI()
    ShowSettingsUI()
return