; TradeMacro Add-on to POE-ItemInfo
; IGN: Eruyome

PriceCheck:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_PriceCheckHotkey()
	}
Return

TradeFunc_PriceCheckHotkey(priceCheckTest = false, itemData = "") {
	Global TradeOpts, Item

	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	TradeFunc_PreventClipboardGarbageAfterInit()
	
	; simulate clipboard change to test item pricing
	If (priceCheckTest) {
		Clipboard :=
		Clipboard := itemData
	} Else {
		scancode_c := Globals.Get("Scancodes").c
		Send ^{%scancode_c%}
	}
	Sleep 250
	TradeFunc_Main()
	SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
}

AdvancedPriceCheck:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_AdvancedPriceCheckHotkey()
	}
Return

TradeFunc_AdvancedPriceCheckHotkey(priceCheckTest = false, itemData = "") {
	Global TradeOpts, Item

	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	TradeFunc_PreventClipboardGarbageAfterInit()
	
	; simulate clipboard change to test item pricing
	If (priceCheckTest) {
		Clipboard :=
		CLipboard := itemData
	} Else {
		scancode_c := Globals.Get("Scancodes").c
		Send ^{%scancode_c%}
	}
	Sleep 250
	TradeFunc_Main(false, true)
	SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
}

OpenSearchOnPoeTrade:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_OpenSearchOnPoeTradeHotkey()
	}
Return

TradeFunc_OpenSearchOnPoeTradeHotkey(priceCheckTest = false, itemData = "") {
	Global TradeOpts, Item

	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	TradeFunc_PreventClipboardGarbageAfterInit()

	; simulate clipboard change to test item pricing
	If (priceCheckTest) {
		Clipboard :=
		Clipboard := itemData
	} Else {
		scancode_c := Globals.Get("Scancodes").c
		Send ^{%scancode_c%}
	}
	Sleep 250
	TradeFunc_Main(true)
	SuspendPOEItemScript = 0 ; Allow ItemInfo to handle clipboard change event
}

OpenSearchOnPoEApp:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_OpenSearchOnPoeAppHotkey()
	}
Return

TradeFunc_OpenSearchOnPoeAppHotkey(priceCheckTest = false, itemData = "") {
	Global TradeOpts, Item

	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	TradeFunc_PreventClipboardGarbageAfterInit()
	
	clipPrev :=
	; simulate clipboard change to test item pricing
	If (priceCheckTest) {
		Clipboard :=
		Clipboard := itemData
	} Else {
		clipPrev := Clipboard
		scancode_c := Globals.Get("Scancodes").c
		Send ^{%scancode_c%}
	}
	Sleep 250
	
	TradeFunc_DoParseClipboard()
	If (Item.Name or Item.BaseName) {
		itemContents := TradeUtils.UriEncode(Clipboard)
		url := "https://poeapp.com/#/item-import/" + itemContents
		Clipboard := clipPrev
		TradeFunc_OpenUrlInBrowser(url)	
	}
	SuspendPOEItemScript = 0 ; Allow ItemInfo to handle clipboard change event
}

ShowItemAge:
	IfWinActive, ahk_group PoEWindowGrp
	{
		Global TradeOpts, Item
		If (!TradeOpts.AccountName) {
			ShowTooltip("No Account Name specified in settings menu.")
			return
		}
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		TradeFunc_PreventClipboardGarbageAfterInit()
		
		scancode_c := Globals.Get("Scancodes").c
		Send ^{%scancode_c%}
		Sleep 250
		TradeFunc_Main(false, false, false, true)
		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
Return

OpenWiki:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_OpenWikiHotkey()
	}
Return

TradeFunc_OpenWikiHotkey(priceCheckTest = false, itemData = "") {
	Global TradeOpts, Item

	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event

	If (priceCheckTest) {
		Clipboard :=
		CLipboard := itemData
	} Else {
		scancode_c := Globals.Get("Scancodes").c
		Send ^{%scancode_c%}
	}
	Sleep 250
	TradeFunc_DoParseClipboard()

	If (!Item.Name and TradeOpts.OpenUrlsOnEmptyItem) {
		If (TradeOpts.WikiAlternative) {
			;http://poedb.tw/us/item.php?n=The+Doctor
			TradeFunc_OpenUrlInBrowser("http://poedb.tw/us/")
		} Else {
			TradeFunc_OpenUrlInBrowser("http://pathofexile.gamepedia.com/")	
		}	
	}
	Else {
		UrlAffix := ""
		UrlPage := ""
		If (TradeOpts.WikiAlternative) {
			; uses poedb.tw
			If (Item.IsUnique) {
				UrlPage := "unique.php?n="
			} Else {
				UrlPage := "item.php?n="
			}
			
			If (Item.IsUnique or Item.IsGem or Item.IsDivinationCard or Item.IsCurrency) {
				UrlAffix := Item.Name
			} Else If (Item.IsFlask) {
				UrlPage := "search.php?Search="
				UrlAffix := Item.SubType
			} Else If (Item.IsMap) {
				UrlPage := "area.php?n="				
				UrlAffix := RegExMatch(Item.SubType, "i)Unknown Map") ? Item.BaseName : Item.SubType
			} Else If (RegExMatch(Item.Name, "i)Sacrifice At") or RegExMatch(Item.Name, "i)Fragment of") or RegExMatch(Item.Name, "i)Mortal ") or RegExMatch(Item.Name, "i)Offering to ") or RegExMatch(Item.Name, "i)'s Key") or RegExMatch(Item.Name, "i)Breachstone")) {
				UrlAffix := Item.Name
			} Else {
				UrlAffix := Item.BaseName
			}
		}
		Else {
			UrlPage := ""
			
			If (Item.IsUnique or Item.IsGem or Item.IsDivinationCard or Item.IsCurrency) {
				UrlAffix := Item.Name
			} Else If (Item.IsFlask or Item.IsMap) {
				UrlAffix := Item.SubType
			} Else If (RegExMatch(Item.Name, "i)Sacrifice At") or RegExMatch(Item.Name, "i)Fragment of") or RegExMatch(Item.Name, "i)Mortal ") or RegExMatch(Item.Name, "i)Offering to ") or RegExMatch(Item.Name, "i)'s Key") or RegExMatch(Item.Name, "i)Breachstone")) {
				UrlAffix := Item.Name
			} Else {
				UrlAffix := Item.BaseName
			}
		}		

		If (StrLen(UrlAffix) > 0) {
			If (TradeOpts.WikiAlternative) {
				UrlAffix := StrReplace(UrlAffix," ","+")
				WikiUrl := "http://poedb.tw/us/" UrlPage . UrlAffix
			} Else {				
				UrlAffix := StrReplace(UrlAffix," ","_")
				WikiUrl := "http://pathofexile.gamepedia.com/" UrlPage . UrlAffix
			}
			TradeFunc_OpenUrlInBrowser(WikiUrl)
		}
	}

	SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	If (not TradeOpts.CopyUrlToClipboard) {
		SetClipboardContents("")	
	}	
}

SetCurrencyRatio:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_SetCurrencyRatio()
	}
Return

TradeFunc_SetCurrencyRatio() {
	Global TradeOpts, Item

	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event

	TradeFunc_PreventClipboardGarbageAfterInit()
	scancode_c := Globals.Get("Scancodes").c
	Send ^{%scancode_c%}
	Sleep 250
	TradeFunc_DoParseClipboard()
	
	If (not Item.name or (not Item.IsCurrency or Item.IsEssence or Item.IsDivinationCard)) {
		ShowToolTip("Item not supported by this function.`nWorks only on currency.")
		Return
	}
	
	tags := TradeGlobals.Get("CurrencyTags")	
	;debugprintarray(tags)
	
	windowPosY := Round(A_ScreenHeight / 2)
	windowPosX := Round(A_ScreenWidth / 2)
	windowTitle := "Set currency ratio"
	
	color := "000000"
	
	Gui, CurrencyRatio:Destroy
	Gui, CurrencyRatio:New, +hwndCurrencyRatioHwnd
	Gui, CurrencyRatio:Font, s8 c%color%, Verdana
	Gui, CurrencyRatio:Color, ffffff, ffffff
	
	Gui, CurrencyRatio:Add, Text, x10, % "You want to sell your"
	Gui, CurrencyRatio:Font, cGreen bold
	itemName := Item.BaseName ? Item.name " " Item.BaseName "." : Item.Name "(s)."
	Gui, CurrencyRatio:Add, Text, x+5 yp+0, % itemName
	Gui, CurrencyRatio:Font, c%color% norm
	
	;Gui, CurrencyRatio:Add, Text, x10, % "Select what you want to receive for the amount of currency that you want to sell."	
	Gui, CurrencyRatio:Add, Text, x10 y+10, % "Input the "
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x+0 yp+0, % "minimum "
	Gui, CurrencyRatio:Font, norm
	Gui, CurrencyRatio:Add, Text, x+0 yp+0, % "amounts that you want to sell and receive"
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x+0 yp+0, % " per single trade"
	Gui, CurrencyRatio:Font, norm
	Gui, CurrencyRatio:Add, Text, x10, % "instead of the amounts that you want to sell and receive in total."	
	
	delimitedListString := ""
	For key, c in tags.currency {
		If (not RegExMatch(c.Text, "i)blessing of | shard")) {
			If (Item.Name != "Chaos Orb") {
				delimiter := RegExMatch(c.Text, "i)Chaos Orb") ? "||" : "|" 
			} Else {
				delimiter := RegExMatch(c.Text, "i)Exalted Orb") ? "||" : "|"
			}
			
			If (c.short) {
				delimitedListString .= c.short delimiter	
			} Else {
				delimitedListString .= c.Text delimiter
			}			
		}		
	}
	For key, c in tags.fragments {		
		If (RegExMatch(c.Text, "i)Splinter of ")) {
			If (c.short) {
				delimitedListString .= c.short "|"
			} Else {
				delimitedListString .= c.Text "|"
			}			
		}
	}
	
	global SelectCurrencyRatioReceiveCurrency := ""
	global SelectCurrencyRatioReceiveAmount := ""
	global SelectCurrencyRatioSellCurrency := Item.name
	global SelectCurrencyRatioSellAmount := ""
	global SelectCurrencyRatioReceiveRatio := ""
	
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x15 y+15 w60, % "Sell:"
	Gui, CurrencyRatio:Font, c%color% norm
	Gui, CurrencyRatio:Add, Edit, x+10 yp-3 w55 vSelectCurrencyRatioSellAmount
	Gui, CurrencyRatio:Add, Text, x+14 yp+3 w276, % Item.name
	
	Gui, CurrencyRatio:Add, GroupBox, x7 y+10 w485 h83,
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x15 yp+15 w60, % "Receive:"
	Gui, CurrencyRatio:Font, c%color% norm
	Gui, CurrencyRatio:Add, Edit, x+10 yp-3 w55 vSelectCurrencyRatioReceiveAmount
	Gui, CurrencyRatio:Add, DropDownList, x+10 yp+0 w280 vSelectCurrencyRatioReceiveCurrency, % delimitedListString
	
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x220 y+5 w100, % "- OR USE -"
	;Gui, CurrencyRatio:Add, Picture, w15 h-1 x10 y+10, %A_ScriptDir%\resources\images\info-blue.png
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x15 y+8 w60 +BackgroundTrans hwndCurrencyRatioInfoTT, % "Ratio*:"
	Gui, CurrencyRatio:Font, norm
	Gui, CurrencyRatio:Add, Text, x+10 yp+0, % Item.name "  1 :"
	
	Gui, CurrencyRatio:Add, Edit, x+8 yp-3 w55 vSelectCurrencyRatioReceiveRatio, 
	Gui, CurrencyRatio:Add, Text, x+8 yp+3, % "[Receive Currency]"

	Gui, CurrencyRatio:Add, Button, x7 y+15 w80 gSelectCurrencyRatioPreview, Preview
	Gui, CurrencyRatio:Add, Text, x+15 yp+3 w260,
	Gui, CurrencyRatio:Add, Button, x+15 yp-3 w116 gSelectCurrencyRatioSubmit, Copy to clipboard
	
	msg := "This UI creates a note that can be used with premium stash tabs to set prices "
	msg .= "`n" "by right-clicking an item and pasting it into the ""Note"" field."
	Gui, CurrencyRatio:Add, Text, x10 y+15, % msg
	
	Gui, CurrencyRatio:Font, bold
	Gui, CurrencyRatio:Add, Text, x10 y+13, % "*"
	Gui, CurrencyRatio:Font, norm
	Gui, CurrencyRatio:Font, s7
	msg := "Using a ratio ignores any receive amount. The macro may change the sell amount"
	msg .= "`n" "while trying to calculate a good (integer) receive amount."
	Gui, CurrencyRatio:Add, Text, x+4 yp-1, % msg
	Gui, CurrencyRatio:Font, s8
	
	Gui, CurrencyRatio:Font, s7 bold
	Gui, CurrencyRatio:Add, Text, x10 y+10, % "Your trade will be listed on all trade-sites."
	
	Gui, CurrencyRatio:Show, center AutoSize, % windowTitle

	SuspendPOEItemScript = 0 ; Allow ItemInfo to handle clipboard change event
}

CustomInputSearch:
	IfWinActive, ahk_group PoEWindowGrp
	{
		TradeFunc_CustomSearchGui()
	}
Return

ChangeLeague:
	IfWinActive, ahk_group PoEWindowGrp
	{
		Global TradeOpts
		TradeFunc_ChangeLeague()
	}
Return

; Prepare Request Parameters and send Post Request
; openSearchInBrowser : set to true to open the search on poe.trade instead of showing the tooltip
; isAdvancedPriceCheck : set to true If the GUI to select mods should be openend
; isAdvancedPriceCheckRedirect : set to true If the search is triggered from the GUI
; isItemAgeRequest : set to true to check own listed items age
TradeFunc_Main(openSearchInBrowser = false, isAdvancedPriceCheck = false, isAdvancedPriceCheckRedirect = false, isItemAgeRequest = false)
{
	LeagueName := TradeGlobals.Get("LeagueName")
	Global Item, ItemData, TradeOpts, mapList, uniqueMapList, Opts

	; When redirected from AdvancedPriceCheck form the clipboard has already been parsed
	If (!isAdvancedPriceCheckRedirect) {
		TradeFunc_DoParseClipboard()
	}
	iLvl     := Item.Level

	; cancel search if Item is empty
	If (!Item.Name) {
		If (TradeOpts.OpenUrlsOnEmptyItem and openSearchInBrowser) {
			TradeFunc_OpenUrlInBrowser("https://poe.trade")
		}
		return
	}

	If (Item.IsRelic) {
		Item.IsUnique := true
	}

	If (Opts.ShowMaxSockets != 1) {
		TradeFunc_SetItemSockets()
	}

	Stats := {}
	Stats.Quality := Item.Quality
	Stats.QualityType := Item.QualityType
	DamageDetails := Item.DamageDetails
	Name := Item.Name

	Item.xtype		:= ""
	Item.UsedInSearch	:= {}
	Item.UsedInSearch.iLvl	:= {}
	For key, val in Item.UsedInSearch {
		If (isObject(val)) {
			Item[key] := {}
		} Else {
			Item[key] := 
		}
	}

	RequestParams			:= new RequestParams_()
	RequestParams.league	:= LeagueName
	RequestParams.has_buyout	:= "1"

	/*
		ignore item name in certain cases
		*/ 
	If (!Item.IsJewel and !Item.IsLeaguestone and Item.RarityLevel > 1 and Item.RarityLevel < 4 and !Item.IsFlask or (Item.IsJewel and not Item.RarityLevel = 4 and isAdvancedPriceCheckRedirect)) {
		IgnoreName := true
	}
	If (Item.RarityLevel > 0 and Item.RarityLevel < 4 and (Item.IsWeapon or Item.IsArmour or Item.IsRing or Item.IsBelt or Item.IsAmulet)) {
		IgnoreName := true
	}
	If (Item.IsRelic) {
		IgnoreName := false
	}
	If (Item.IsBeast) {
		If (Item.IsUnique) {
			IgnoreName := false
		} Else {
			IgnoreName := true
		}
	}

	If (Item.IsLeagueStone) {
		ItemData.Affixes := TradeFunc_AddCustomModsToLeaguestone(ItemData.Affixes, Item.Charges)
	}

	/*
		check if the item implicit mod is an enchantment or corrupted. retrieve this mods data.
		*/	
	Enchantment := false
	Corruption  := false

	If (Item.hasImplicit or Item.hasEnchantment) {
		Enchantment := TradeFunc_GetEnchantment(Item, Item.SubType)
		If (StrLen(Enchantment) and Item.hasImplicit and not Item.hasEnchantment) {
			Item.hasImplicit := false	; implicit was assumed but is actually an enchantment
		}
		Corruption  := Item.IsCorrupted ? TradeFunc_GetCorruption(Item) : false
	}

	If (Item.IsWeapon or Item.IsQuiver or Item.IsArmour or Item.IsLeagueStone or Item.IsBeast or (Item.IsFlask and Item.RarityLevel > 1) or Item.IsJewel or (Item.IsMap and Item.RarityLevel > 1) of Item.IsBelt or Item.IsRing or Item.IsAmulet)
	{
		hasAdvancedSearch := true
	}

	/*
		further item parsing and preparation
		*/	
	If (!Item.IsUnique or Item.IsBeast) {
		; TODO: improve this
		If (Item.IsBeast) {
			Item.BeastData.GenusMod 			:= {}
			Item.BeastData.GenusMod.name_orig	:= "(beast) Genus: " Item.BeastData.Genus
			Item.BeastData.GenusMod.name		:= RegExReplace(Item.BeastData.GenusMod.name_orig, "i)\d+", "#")
			Item.BeastData.GenusMod.param		:= TradeFunc_FindInModGroup(TradeGlobals.Get("ModsData")["bestiary"], Item.BeastData.GenusMod)
		}
		
		preparedItem  := TradeFunc_PrepareNonUniqueItemMods(ItemData.Affixes, Item.Implicit, Item.RarityLevel, Enchantment, Corruption, Item.IsMap, Item.IsBeast, Item.IsSynthesisedBase)
		preparedItem.maxSockets	:= Item.maxSockets
		preparedItem.iLvl		:= Item.level
		preparedItem.Name		:= Item.Name
		preparedItem.BaseName	:= Item.BaseName
		preparedItem.Rarity		:= Item.RarityLevel
		preparedItem.BeastData	:= Item.BeastData
		preparedItem.IsCorrupted	:= Item.IsCorrupted
		preparedItem.IsJewel	:= Item.IsJewel
		preparedItem.veiledPrefixCount := Item.veiledPrefixCount
		preparedItem.veiledSuffixCount := Item.veiledSuffixCount
		preparedItem.Enchantment := Enchantment

		If (Item.HasInfluence.length() or Item.IsAbyssJewel or Item.isFracturedBase or Item.isSynthesisedBase) {
			If (Item.HasInfluence.length()) {
				preparedItem.specialBase	:= ""
				For key, val in Item.HasInfluence {
					preparedItem.specialBase	.= key == 1 ? val : ", " val
				}				
			} Else If (Item.isFracturedBase) {
				preparedItem.specialBase	:= "Fractured Base"
			} Else If (Item.isSynthesisedBase) {
				preparedItem.specialBase	:= "Synthesised Base"
			}
		}
		If (Item.isFracturedBase) {
			preparedItem.isFracturedBase	:= true
		}
		If (Item.IsSynthesisedBase) {
			preparedItem.IsSynthesisedBase:= true
		}
		Stats.Defense := TradeFunc_ParseItemDefenseStats(ItemData.Stats, preparedItem)
		Stats.Offense := TradeFunc_ParseItemOffenseStats(DamageDetails, preparedItem)

		If (isAdvancedPriceCheck and hasAdvancedSearch) {
			If (Corruption.Length()) {
				TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links, "", Corruption)
			}
			Else If (Item.IsSynthesisedBase) {
				Item.Implicit := []
				For key, val in preparedItem.mods {
					If (val.type = "implicit") {
						Item.Implicit.push(val)
					} 
				}				
				TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links, "", Item.Implicit)
			}
			Else {
				TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links)
			}
			return
		}
		Else If (isAdvancedPriceCheck and not hasAdvancedSearch) {
			ShowToolTip("Advanced search not available for this item.")
			return
		}
	}

	If (Item.IsUnique) {
		; returns mods with their ranges of the searched item if it is unique and has variable mods
		uniqueWithVariableMods :=
		uniqueWithVariableMods := TradeFunc_FindUniqueItemIfItHasVariableRolls(Name, Item.IsRelic)

		; Return if the advanced search was used but the checked item doesn't have variable mods
		If (!uniqueWithVariableMods and isAdvancedPriceCheck and not Enchantment.Length() and not Corruption.Length()) {
			ShowToolTip("Advanced search not available for this item (no variable mods)`nor item is new and the necessary data is not yet available/updated.")
			return
		}
		
		UniqueStats := TradeFunc_GetUniqueStats(Name, Item.IsRelic)
		If (uniqueWithVariableMods or Corruption.Length() or Enchantment.Length()) {
			Gui, SelectModsGui:Destroy

			preparedItem := {}
			preparedItem := TradeFunc_GetItemsPoeTradeUniqueMods(uniqueWithVariableMods)
			preparedItem := TradeFunc_RemoveAlternativeVersionsMods(preparedItem, ItemData.Affixes)
			If (not preparedItem.Name and not preparedItem.mods.length()) {
				preparedItem := {}
				preparedItem.Name := Item.Name
				preparedItem.maxSockets := Item.maxSockets
				preparedItem.IsUnique := Item.IsUnique
				preparedItem.class := Item.SubType
			}
			preparedItem.maxSockets 	:= Item.maxSockets
			preparedItem.isCorrupted	:= Item.isCorrupted
			preparedItem.isRelic	:= Item.isRelic
			preparedItem.iLvl 		:= Item.level
			preparedItem.BaseName	:= Item.BaseName
			preparedItem.veiledPrefixCount := Item.veiledPrefixCount
			preparedItem.veiledSuffixCount := Item.veiledSuffixCount
			preparedItem.Enchantment := Enchantment
			preparedItem.isFracturedBase := false
			preparedItem.isSynthesisedBase := false
			preparedItem.specialBase := ""

			If (Item.isFracturedBase or Item.isSynthesisedBase) {
				If (Item.isFracturedBase) {
					preparedItem.specialBase	:= "Fractured Base"
					preparedItem.isFracturedBase	:= true
				} Else If (Item.isSynthesisedBase) {
					preparedItem.specialBase	:= "Synthesised Base"					
					preparedItem.IsSynthesisedBase:= true
				}
			}
			
			Stats.Defense := TradeFunc_ParseItemDefenseStats(ItemData.Stats, preparedItem)
			Stats.Offense := TradeFunc_ParseItemOffenseStats(DamageDetails, preparedItem)

			; open TradeFunc_AdvancedPriceCheckGui to select mods and their min/max values
			If (isAdvancedPriceCheck) {
				UniqueStats := TradeFunc_GetUniqueStats(Name)
				/*
				If (Enchantment.Length()) {
					TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links, UniqueStats, Enchantment)
				}
				*/

				If (Corruption.Length()) {
					TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links, UniqueStats, Corruption)
				}
				Else If (Item.IsSynthesisedBase) {
					Item.Implicit := []
					For key, val in preparedItem.mods {
						If (val.type = "implicit") {
							Item.Implicit.push(val)
						} 
					}		
					TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links, UniqueStats, Item.Implicit)
				}
				Else {
					TradeFunc_AdvancedPriceCheckGui(preparedItem, Stats, ItemData.Sockets, ItemData.Links, UniqueStats)
				}
				return
			}
		}
		Else {
			RequestParams.name   := Trim(StrReplace(Name, "Superior", ""))
			Item.UsedInSearch.FullName := true
		}

		; only find items that can have the same amount of sockets
		If (Item.MaxSockets = 6) {
			RequestParams.ilevel_min  := 50
			Item.UsedInSearch.iLvl.min:= 50
		}
		Else If (Item.MaxSockets = 5) {
			RequestParams.ilevel_min := 35
			RequestParams.ilevel_max := 49
			Item.UsedInSearch.iLvl.min := 35
			Item.UsedInSearch.iLvl.max := 49
		}
		; is (no 1-hand or shield or unset ring or helmet or glove or boots) but is weapon or armor
		Else If ((not Item.IsFourSocket and not Item.IsThreeSocket and not Item.IsSingleSocket) and (Item.IsWeapon or Item.IsArmour) and Item.Level < 35) {
			RequestParams.ilevel_max := 34
			Item.UsedInSearch.iLvl.max := 34
		}

		; set links to max for corrupted items with 3/4 max sockets if the own item is fully linked		
		; poe.trade doesn't count abyssal sockets as "normal sockets"
		If (Item.IsCorrupted and TradeOpts.ForceMaxLinks) {
			If (Item.MaxSocketsNormal = 4 and ItemData.Links = 4) {
				RequestParams.link_min := 4
			}
			Else If (Item.MaxSocketsNormal = 3 and ItemData.Links = 3) {
				RequestParams.link_min := 3
			}
		}
		
		; special bases (elder/shaper/fractured/synthesised/redeemer/hunter/crusader/warlord)
		If (Item.HasInfluence.length() or Item.isFracturedBase or Item.isSynthesisedBase) {
			If (Item.HasInfluence.length()) {
				Item.UsedInSearch.specialBase := ""
				For key, val in Item.HasInfluence {
					RequestParams[val] := 1
					Item.UsedInSearch.specialBase .= key == 1 ? val : ", " val
				}				
			}
			Else If (Item.IsFracturedBase) {
				RequestParams.Fractured := 1
				Item.UsedInSearch.specialBase := "Fractured"
			}
			Else If (Item.IsSynthesisedBase) {
				RequestParams.Synthesised := 1
				Item.UsedInSearch.specialBase := "Synthesised"
			}
		}
	}

	/*
		ignore mod rolls unless the TradeFunc_AdvancedPriceCheckGui is used to search
		*/
	AdvancedPriceCheckItem := TradeGlobals.Get("AdvancedPriceCheckItem")
	If (isAdvancedPriceCheckRedirect) {
		; submitting the AdvancedPriceCheck Gui sets TradeOpts.Set("AdvancedPriceCheckItem") with the edited item (selected mods and their min/max values)
		s := TradeGlobals.Get("AdvancedPriceCheckItem")
		Loop % s.mods.Length() {
			If (s.mods[A_Index].selected > 0) {
				modParam := new _ParamMod()
				
				If (s.mods[A_Index].spawntype = "fractured" and s.includeFractured) {
					modParam.mod_name := TradeFunc_FindInModGroup(TradeGlobals.Get("ModsData")["fractured"], s.mods[A_Index])
				}

				If (not StrLen(modParam.mod_name)) {
					modParam.mod_name := s.mods[A_Index].param	
				}
				
				modParam.mod_min := s.mods[A_Index].min
				modParam.mod_max := s.mods[A_Index].max	
				RequestParams.modGroups[1].AddMod(modParam)
			}
		}
		If (s.includeFracturedCount and s.fracturedCount > 0) {
			modParam := new _ParamMod()
			modParam.mod_name := "(pseudo) # Fractured Modifiers" ; TradeFunc_FindInModGroup(TradeGlobals.Get("ModsData")["pseudo"], "# Fractured Modifiers")
			/*
			_tmpitem := {}
			_tmpitem.mods := []
			_tmpitem.mods.push({name : "# Fractured Modifiers"})
			modParam.mod_name := TradeFunc_GetItemsPoeTradeMods(_tmpitem)
			*/			
			modParam.mod_min := s.fracturedCount
			modParam.mod_max := s.fracturedCount
			RequestParams.modGroups[1].AddMod(modParam)
		}
		Loop % s.stats.Length() {
			If (s.stats[A_Index].selected > 0) {
				; defense
				If (InStr(s.stats[A_Index].Param, "Armour")) {
					RequestParams.armour_min  := (s.stats[A_Index].min > 0) ? s.stats[A_Index].min : ""
					RequestParams.armour_max  := (s.stats[A_Index].max > 0) ? s.stats[A_Index].max : ""
				}
				Else If (InStr(s.stats[A_Index].Param, "Evasion")) {
					RequestParams.evasion_min := (s.stats[A_Index].min > 0) ? s.stats[A_Index].min : ""
					RequestParams.evasion_max := (s.stats[A_Index].max > 0) ? s.stats[A_Index].max : ""
				}
				Else If (InStr(s.stats[A_Index].Param, "Energy")) {
					RequestParams.shield_min  := (s.stats[A_Index].min > 0) ? s.stats[A_Index].min : ""
					RequestParams.shield_max  := (s.stats[A_Index].max > 0) ? s.stats[A_Index].max : ""
				}
				Else If (InStr(s.stats[A_Index].Param, "Block")) {
					RequestParams.block_min  := (s.stats[A_Index].min > 0)  ? s.stats[A_Index].min : ""
					RequestParams.block_max  := (s.stats[A_Index].max > 0)  ? s.stats[A_Index].max : ""
				}

				; offense
				Else If (InStr(s.stats[A_Index].Param, "Physical")) {
					RequestParams.pdps_min  := (s.stats[A_Index].min > 0)  ? s.stats[A_Index].min : ""
					RequestParams.pdps_max  := (s.stats[A_Index].max > 0)  ? s.stats[A_Index].max : ""
				}
				Else If (InStr(s.stats[A_Index].Param, "Elemental")) {
					RequestParams.edps_min  := (s.stats[A_Index].min > 0)  ? s.stats[A_Index].min : ""
					RequestParams.edps_max  := (s.stats[A_Index].max > 0)  ? s.stats[A_Index].max : ""
				}
			}
		}

		; min quality for catalysed jewelry
		If (s.minQuality and s.UseQualityType) {
			RequestParams.q_min			:= s.minQuality
			Item.UsedInSearch.Quality	:= s.minQuality
		}

		; handle item sockets
		If (s.UseSockets) {
			RequestParams.sockets_min := ItemData.Sockets - Item.AbyssalSockets
			Item.UsedInSearch.Sockets := ItemData.Sockets - Item.AbyssalSockets
		}
		If (s.UseSocketsMaxFour) {
			RequestParams.sockets_min := 4 - Item.AbyssalSockets
			Item.UsedInSearch.Sockets := 4 - Item.AbyssalSockets
		}
		If (s.UseSocketsMaxThree) {
			RequestParams.sockets_min := 3 - Item.AbyssalSockets
			Item.UsedInSearch.Sockets := 3 - Item.AbyssalSockets
		}

		; handle item links
		If (s.UseLinks) {
			RequestParams.link_min	:= ItemData.Links
			Item.UsedInSearch.Links	:= ItemData.Links
		}
		If (s.UseLinksMaxFour) {
			RequestParams.link_min	:= 4 - Item.AbyssalSockets
			Item.UsedInSearch.Links	:= 4 - Item.AbyssalSockets
		}
		If (s.UseLinksMaxThree) {
			RequestParams.link_min	:= 3 - Item.AbyssalSockets
			Item.UsedInSearch.Links	:= 3 - Item.AbyssalSockets
		}

		If (s.UsedInSearch) {
			Item.UsedInSearch.Enchantment := s.UsedInSearch.Enchantment
			Item.UsedInSearch.CorruptedMod:= s.UsedInSearch.Corruption
		}

		If (s.useIlvl) {
			RequestParams.ilvl_min := s.minIlvl
			Item.UsedInSearch.iLvl.min := true
		}

		If (s.useBase) {
			If (Item.IsBeast) {
				modParam := new _ParamMod()
				modParam.mod_name := Item.BeastData.GenusMod.param
				modParam.mod_min := ""
				RequestParams.modGroups[1].AddMod(modParam)
				Item.UsedInSearch.Type := Item.BaseType ", " Item.BeastData.Genus
			} Else {
				RequestParams.xbase := Item.BaseName
				Item.UsedInSearch.ItemBase := Item.BaseName
			}			
		}

		If (s.onlineOverride) {
			RequestParams.online := ""
		}
		
		If (s.corruptedOverride) {
			RequestParams.corrupted := "1"
		} Else {
			RequestParams.corrupted := "0"
		}
		
		; special bases (elder/shaper/synthesised/fractured/crusader/warlord/redeemer/hunter)
		If (s.useSpecialBase) {
			If (Item.HasInfluence.length()) {
				For key, val in Item.HasInfluence {
					RequestParams[val] := 1
				}
			}
			Else If (Item.IsFracturedBase) {
				RequestParams.Fractured := 1
			}
			Else If (Item.IsSynthesisedBase) {
				RequestParams.Synthesised := 1
			}
		} Else {
			RequestParams.Shaper	:= ""
			RequestParams.Elder		:= ""
			RequestParams.crusader	:= ""
			RequestParams.Warlord	:= ""
			RequestParams.Redeemer	:= ""
			RequestParams.Hunter	:= ""			
			RequestParams.Fractured	:= ""
			RequestParams.Synthesised:= ""
		}

		; abyssal sockets 
		If (s.useAbyssalSockets) {
			RequestParams.sockets_a_min := s.abyssalSockets
			RequestParams.sockets_a_max := s.abyssalSockets
		}
		
		; veiled mods
		If (s.useVeiledPrefix) {
			/*
			RequestParams.veiledPrefix_min := s.veiledPrefixCount
			RequestParams.veiledPrefix_max := s.veiledPrefixCount
			*/
			RequestParams.veiled		 := 1
			
		}
		If (s.useVeiledSuffix) {
			/*
			RequestParams.veiledSuffix_min := s.useVeiledSuffix
			RequestParams.veiledSuffix_max := s.useVeiledSuffix
			*/
			RequestParams.veiled		 := 1
		}
	}
	
	/*
		prepend the item.subtype to match the options used on poe.trade
		*/	
	If (RegExMatch(Item.SubType, "i)Mace|Axe|Sword|Sceptre")) {
		If (Item.IsThreeSocket) {
			If (TradeItemBasesWeapons[Item.BaseName]["Item Class"]) {
				Item.ItemClass := TradeItemBasesWeapons[Item.BaseName]["Item Class"]
			}
			
			If (Item.ItemClass) {
				If (RegExMatch(Item.ItemClass, "i)Sceptres")) {
					Item.xtype := "Sceptre"
				}
			} Else {
				If (RegExMatch(Item.BaseName, "i)Sceptre")) {
					Item.xtype := "Sceptre"
				}
			}
			
			If (not Item.xtype) {
				Item.xtype := "One Hand " . Item.SubType				
			}
		}
		Else {
			Item.xtype := "Two Hand " . Item.SubType
		}
	}
	/*
		"workaround" for poe.trade missing the warstaff/rune dagger item types
		todo: remove when types are available
	*/
	If (RegExMatch(Item.SubType, "i)Warstaff")) {
		Item.xtype := "Staff"
	}
	If (RegExMatch(Item.SubType, "i)Rune Dagger")) {
		Item.xtype := "Dagger"
	}

	/*
		Fix Body Armour subtype
		*/	
	If (RegExMatch(Item.SubType, "i)BodyArmour")) {
		Item.xtype := "Body Armour"
	}

	/*
		remove "Superior" from item name to exclude it from name search
		*/
	If (!IgnoreName) {
		RequestParams.name   := Trim(StrReplace(Name, "Superior", ""))
		If (Item.IsRelic) {
			RequestParams.rarity := "relic"
			Item.UsedInSearch.Rarity := "Relic"
		} Else If (Item.IsUnique) {
			RequestParams.rarity := "unique"
			; Harbinger fragments are unique but don't have a selectable base type on poe.trade
			If (!RegExMatch(Item.Name, "i)(First|Second|Third|Fourth) Piece of.*")) {
				RequestParams.xbase  := Item.BaseName
			}
		}
		Item.UsedInSearch.FullName := true
	}
	Else If (!Item.isUnique and AdvancedPriceCheckItem.mods.length() <= 0) {
		isCraftingBase         := TradeFunc_CheckIfItemIsCraftingBase(Item.BaseName)
		hasHighestCraftingILvl := TradeFunc_CheckIfItemHasHighestCraftingLevel(Item.SubType, iLvl)
		; xtype = Item.SubType (Helmet)
		; xbase = Item.BaseName (Eternal Burgonet)

		; if desired crafting base and not isAdvancedPriceCheckRedirect
		If (isCraftingBase and not Enchantment.Length() and not Corruption.Length() and not isAdvancedPriceCheckRedirect) {
			RequestParams.xbase := Item.BaseName
			Item.UsedInSearch.ItemBase := Item.BaseName
			; if highest item level needed for crafting
			If (hasHighestCraftingILvl) {
				RequestParams.ilvl_min := hasHighestCraftingILvl
				Item.UsedInSearch.iLvl.min := hasHighestCraftingILvl
			}
		}
		Else If (Enchantment.param and not isAdvancedPriceCheckRedirect) {
			modParam := new _ParamMod()
			modParam.mod_name := Enchantment.param
			modParam.mod_min  := Enchantment.min
			modParam.mod_max  := Enchantment.max
			RequestParams.modGroups[1].AddMod(modParam)
			Item.UsedInSearch.Enchantment := true
		} 		
		Else If (Enchantment.Length() and not isAdvancedPriceCheckRedirect) {		
			For key, val in Enchantment {
				If (val.param) {
					modParam := new _ParamMod()
					modParam.mod_name := val.param
					modParam.mod_min  := val.min
					modParam.mod_max  := val.max
					RequestParams.modGroups[key].AddMod(modParam)
					Item.UsedInSearch.Enchantment := true
				}			
			}	
		} 
		Else If (Corruption.Length() and not isAdvancedPriceCheckRedirect) {
			For key, val in Corruption {
				If (val.param) {
					modParam := new _ParamMod()
					modParam.mod_name := val.param
					modParam.mod_min  := (val.min) ? val.min : ""
					RequestParams.modGroups[key].AddMod(modParam)
					Item.UsedInSearch.CorruptedMod := true		
				}			
			}	
		}
		Else {
			RequestParams.xtype := (Item.xtype) ? Item.xtype : Item.SubType
			If (not Item.IsBeast) {
				Item.UsedInSearch.Type := (Item.xtype) ? Item.xtype : Item.SubType
			}
		}
		
		If (isAdvancedPriceCheckRedirect and not TradeGlobals.Get("AdvancedPriceCheckItem").useSpecialBase) {
			RequestParams.Shaper	:= ""
			RequestParams.Elder		:= ""
			RequestParams.crusader	:= ""
			RequestParams.Warlord	:= ""
			RequestParams.Redeemer	:= ""
			RequestParams.Hunter	:= ""
			RequestParams.Fractured 	:= ""
			RequestParams.Synthesised:= ""
		} Else {
			If (Item.HasInfluence.length()) {
				For key, val in Item.HasInfluence {
					RequestParams[val] := 0
				}
				For key, val in Item.HasInfluence {
					RequestParams[val] := 1
					Item.UsedInSearch.specialBase .= key == 1 ? val : ", " val
				}
			}

			If (Item.IsFracturedBase) {
				RequestParams.Fractured := 1
				Item.UsedInSearch.specialBase := "Fractured"
			}
			Else {			
				RequestParams.Fractured := 0
			}
			
			If (Item.IsSynthesisedBase) {
				RequestParams.Synthesised := 1
				Item.UsedInSearch.specialBase := "Synthesised"
			}
			Else {			
				RequestParams.Synthesised := 0
			}
		}		
	} 
	Else {
		RequestParams.xtype := (Item.xtype) ? Item.xtype : Item.SubType
		If (not Item.IsBeast) {
			Item.UsedInSearch.Type := (Item.xtype) ? Item.GripType . " " . Item.SubType : Item.SubType	
		}		
	}
	
	If (not AdvancedPriceCheckItem.mods.length() <= 0) {
		If (Item.veiledPrefixCount) {
			/*
			RequestParams.veiledPrefix_min := Item.veiledPrefixCount
			RequestParams.veiledPrefix_min := Item.veiledPrefixCount
			
			*/
			Item.UsedInSearch.veiledPrefix := Item.veiledPrefixCount
			RequestParams.veiled		 := 1
		}
		If (Item.veiledSuffixCount) {
			/*
			RequestParams.veiledSuffix_min := Item.veiledSuffixCount
			RequestParams.veiledSuffix_min := Item.veiledSuffixCount
			
			*/
			Item.UsedInSearch.veiledSuffix := Item.veiledSuffixCount
			RequestParams.veiled		 := 1
		}
		*/
	}
	
	/*
		handle abyssal sockets for the default search
		*/
	If (AdvancedPriceCheckItem.mods.length() <= 0) {
		If (Item.AbyssalSockets > 0) {
			RequestParams.sockets_a_min := Item.AbyssalSockets
			RequestParams.sockets_a_max := Item.AbyssalSockets
			Item.UsedInSearch.AbyssalSockets := (Item.AbyssalSockets > 0) ? Item.AbyssalSockets : ""
		}	
	}
	
	/*
		make sure to not look for unique items when searching rare/white/magic items
		*/
	If (!Item.IsUnique) {
		RequestParams.rarity := "non_unique"
	}
	
	/*
		handle beasts
		*/
	If (Item.IsBeast) {
		If (!Item.IsUnique) {
			RequestParams.Name := ""
		}
		
		RequestParams.xtype := Item.BaseType
		If (not isAdvancedPriceCheckRedirect) {
			Item.UsedInSearch.Type := Item.BaseType ", " Item.BeastData.Genus
		}
		
		/*
			add genus
			*/
		If (not isAdvancedPriceCheckRedirect) {
			modParam := new _ParamMod()
			modParam.mod_name := TradeFunc_FindInModGroup(TradeGlobals.Get("ModsData")["bestiary"], Item.BeastData.GenusMod)
			modParam.mod_min  := ""
			RequestParams.modGroups[1].AddMod(modParam)	
		}
		
		; legendary beasts:
		; Farric Wolf Alpha, Fenumal Scorpion, Fenumal Plaqued Arachnid, Farric Frost Hellion Alpha,  Farric Lynx ALpha, Saqawine Vulture,
		; Craicic Chimeral, Saqawine Cobra, Craicic Maw, Farric Ape, Farric Magma Hound, Craicic Vassal, Farric Pit Hound, Craicic Squid,  
		; Farric Taurus, Fenumal Scrabbler, Farric Goliath, Fenumal Queen, Saqawine Blood Viper, Fenumal Devourer, Farric Ursa, Fenumal Widow, 
		; Farric Gargantuan, Farric Chieftain, Farric Ape, Farrci Flame Hellion Alpha, Farrci Goatman, Craicic Watcher, Saqawine Retch, 
		; Saqawine Chimeral, Craicic Shield Crab, Craicic Sand Spitter, Craicic Savage Crab, Saqawine Rhoa
		
		; portal beasts:
		; Farric Tiger Alpha, Craicic Spider Crab, Fenumal Hybrid Arachnid, Saqawine Rhex
		
		; aspect beasts:
		; "Farrul, First of the Plains", "Craiceann, First of the Deep", "Fenumus, First of the Night", "Saqawal, First of the Sky"
		/*
			add beast name and base/subtype
			*/
		skipBeastMods := false
		If (Item.BeastData.IsLegendaryBeast or Item.BeastData.IsPortalBeast) {
			RequestParams.Name := Item.BeastData.BeastBase
			Item.UsedInSearch.BeastBase := true
			skipBeastMods := true			
		}	
		If (Item.BeastData.IsAspectBeast) {
			RequestParams.Name := Item.BeastData.BeastName
			Item.UsedInSearch.FullName := true
			skipBeastMods := true
		}
		
		/* 
			add beastiary mods
			*/
		If (not isAdvancedPriceCheckRedirect and not skipBeastMods) {			
			If (not isAdvancedPriceCheck) {		
				
				useOnlyThisBeastMod := ""
				For key, imod in preparedItem.mods {
					; http://poecraft.com/bestiary
					; craicis presence is valuable, requires ilvl 70+
					If (RegExMatch(imod.param, "i)(Craicic Presence)", match) and Item.Level >= 70) {
						useOnlyThisBeastMod := match1
					}					
					
					; crimson flock, putrid flight, unstable swarm 80+
					If (RegExMatch(imod.param, "i)(Crimson Flock|Putrid Flight|Unstable Swarm)", match) and Item.Level >= 80) {
						useOnlyThisBeastMod := match1
					}
				}				
				
				For key, imod in preparedItem.mods {
					If (imod.param) {	; exists on poe.trade
						If ((StrLen(useOnlyThisBeastMod) and RegExMatch(imod.param, "i)" useOnlyThisBeastMod "")) or (not StrLen(useOnlyThisBeastMod))) {								
							modParam := new _ParamMod()
							modParam.mod_name := imod.param
							modParam.mod_min  := ""
							RequestParams.modGroups[1].AddMod(modParam)
							
							If (StrLen(useOnlyThisBeastMod)) {
								RequestParams.ilvl_min := 70
							}
						}
					}				
				}
			}			
		}
	}
	
	/*
		metamorph samples
	*/
	If (Item.IsMetamorphSample) {
		;RequestParams.xtype := "Metamorph"
		RequestParams.xBase	:= Item.SubType
		UsedInSearch.Type	:= Item.SubType
		RequestParams.Name	:= Item.Name
		UsedInSearch.Name	:= Item.Name
	}
	
	/*
		league stones
		*/
	If (Item.IsLeagueStone) {
		; only manually add these mods if they don't already exist (created by advanced search)
		temp_name := "(leaguestone) Can only be used in Areas with Monster Level # or below"
		If (not TradeFunc_FindModInRequestParams(RequestParams, temp_name)) {
			; mod does not exist on poe.trade: "Can only be used in Areas with Monster Level # or above"
			If (Item.AreaMonsterLevelReq.logicalOperator = "above") {
				; do nothing, min (above) requirement has no correlation with item level, only with the mods spawned on the stone
				; stones with the same name should have the same "above" requirement so we ignore it
			} Else If (Item.AreaMonsterLevelReq.logicalOperator = "between") {
				; stones with the same name should have the same "above" requirement so we ignore it
				; the upper limit value ("below") depends on the item level, it should be limit = (ilvl + 11)
				; so we could use the max item level parameter with some buffer (not sure about the + 11).
				RequestParams.ilvl_max := Item.AreaMonsterLevelReq.lvl_upper + 15
				Item.UsedInSearch.iLvl.min := RequestParams.ilvl_max
			} Else {
				modParam := new _ParamMod()
				modParam.mod_name := temp_name

				If (Item.AreaMonsterLevelReq.lvl) {
					modParam.mod_min  := Item.AreaMonsterLevelReq.lvl_upper - 10
					modParam.mod_max  := Item.AreaMonsterLevelReq.lvl_upper
					RequestParams.modGroups[1].AddMod(modParam)
					Item.UsedInSearch.AreaMonsterLvl := "Area Level: " modParam.mod_min " - " modParam.mod_max
				} Else {
					; add second mod group to exclude area restrictions
					RequestParams.AddModGroup("Not", 1)
					RequestParams.modGroups[RequestParams.modGroups.MaxIndex()].AddMod(modParam)
					Item.UsedInSearch.AreaMonsterLvl := "Area Level: no restriction"
				}
			}
		}

		If (Item.Charges.max > 1) {
			temp_name := "(leaguestone) Currently has # Charges"
			If (not TradeFunc_FindModInRequestParams(RequestParams, temp_name)) {
				modParam := new _ParamMod()
				modParam.mod_name := "(leaguestone) Currently has # Charges"
				modParam.mod_min  := Item.Charges.Current
				modParam.mod_max  := Item.Charges.Current
				RequestParams.modGroups[1].AddMod(modParam)
				Item.UsedInSearch.Charges:= "Charges: " Item.Charges.Current
			}
		}
	}

	/*
		don't overwrite advancedItemPriceChecks decision to include/exclude sockets/links
		*/ 
	If (not isAdvancedPriceCheckRedirect) {
		; handle item sockets
		; maybe don't use this for unique-items as default
		If (ItemData.Sockets >= 5 and not Item.IsUnique) {
			RequestParams.sockets_min := ItemData.Sockets
			Item.UsedInSearch.Sockets := ItemData.Sockets
		}
		If (ItemData.Sockets >= 6) {
			RequestParams.sockets_min := ItemData.Sockets
			Item.UsedInSearch.Sockets := ItemData.Sockets
		}
		; handle item links
		If (ItemData.Links >= 5) {
			RequestParams.link_min := ItemData.Links
			Item.UsedInSearch.Links := ItemData.Links
		}
	}

	/*
		handle corruption
		*/		
	If (Item.IsCorrupted and isAdvancedPriceCheckRedirect and RequestParams.corrupted = "0" and Item.IsJewel) {
		RequestParams.corrupted := "1"
	}
	Else If (Item.IsCorrupted and TradeOpts.CorruptedOverride and not Item.IsDivinationCard) {
		If (TradeOpts.Corrupted = "Either") {
			RequestParams.corrupted := ""
			Item.UsedInSearch.Corruption := "Either"
		}
		Else If (TradeOpts.Corrupted = "Yes") {
			RequestParams.corrupted := "1"
			Item.UsedInSearch.Corruption := "Yes"
		}
		Else If (TradeOpts.Corrupted = "No") {
			RequestParams.corrupted := "0"
			Item.UsedInSearch.Corruption := "No"
		}
	}
	Else If (Item.IsCorrupted and not Item.IsDivinationCard) {
		RequestParams.corrupted := "1"
		Item.UsedInSearch.Corruption := "Yes"
	}
	Else If (TradeOpts.Corrupted = "Either" and TradeOpts.CorruptedOverride) {
		RequestParams.corrupted := ""
		Item.UsedInSearch.Corruption := "Either"
	}
	Else {
		RequestParams.corrupted := "0"
		Item.UsedInSearch.Corruption := "No"
	}

	/*
		maps
		*/
	If (Item.IsMap) {
		; add Item.subtype to make sure to only find maps
		RegExMatch(Item.Name, "i)The Beachhead.*", isHarbingerMap)
		RegExMatch(Item.SubType, "i)Unknown Map", isUnknownMap)
		isElderMap := RegExMatch(Item.Name, ".*?Elder .*") and Item.MapTier = 16
		isBlightedMap := RegExMatch(Item.SubType, "\bBlighted .*")

		mapTypes := TradeGlobals.Get("ItemTypeList")["Map"]
		typeFound := TradeUtils.IsInArray(Item.SubType, mapTypes)

		If (not isHarbingerMap and not isUnknownMap and typeFound) {
			RequestParams.xbase := Item.SubType
			RequestParams.xtype := ""		
			If (isElderMap) {
				RequestParams.name := "Elder"
			} Else If (isBlightedMap) {
				RequestParams.name := "Blighted"
			}
		} Else {
			RequestParams.xbase := ""
			RequestParams.xtype := "Map"
		}		

		If (not Item.IsUnique) {
			If (not typeFound) {			
				RequestParams.name := Item.BaseName
				RequestParams.level_min := Item.MapTier
				RequestParams.level_max := Item.MapTier
			} Else If (not isElderMap) {
				RequestParams.name := ""
			}
		} Else If (Item.IsUnique and isHarbingerMap) {
			RequestParams.corrupted := "1"
		}
	
		If (StrLen(isUnknownMap)) {
			RequestParams.xbase := Item.BaseName
			Item.UsedInSearch.type := Item.BaseName
		}		
		
		RequestParams.level_min := Item.MapTier
		RequestParams.level_max := Item.MapTier
		
		Item.priceHistory := TradeFunc_FindMapHistoryData(Item.SubType, Item.MapTier)
	}
	
	/*
		fossils
		*/
	If (Item.IsFossil) {
		Item.priceHistory := TradeFunc_FindFossilHistoryData(Item.Name)
	}

	/*
		gems
		*/
	If (Item.IsGem) {
		RequestParams.xtype := Item.BaseType
		foundOnPoeTrade := false
		_xbase := TradeFunc_CompareGemNames(Trim(RegExReplace(Item.Name, "i)support|superior")), foundOnPoeTrade)
		If (not foundOnPoeTrade) {
			RequestParams.name := Trim(RegExReplace(Item.Name, "i)support|superior"))
		} Else {
			RequestParams.xbase := _xbase
			RequestParams.name := ""	
		}
		
		If (TradeOpts.GemQualityRange > 0) {
			RequestParams.q_min := Item.Quality - TradeOpts.GemQualityRange
			RequestParams.q_max := Item.Quality + TradeOpts.GemQualityRange
		}
		Else {
			RequestParams.q_min := Item.Quality
		}
		; match exact gem level if enhance, empower or enlighten
		If (InStr(Name, "Empower") or InStr(Name, "Enlighten") or InStr(Name, "Enhance")) {
			RequestParams.level_min := Item.Level
			RequestParams.level_max := Item.Level
		}
		Else If (TradeOpts.GemLevelRange > 0 and Item.Level >= TradeOpts.GemLevel) {
			RequestParams.level_min := Item.Level - TradeOpts.GemLevelRange
			RequestParams.level_max := Item.Level + TradeOpts.GemLevelRange
		}
		Else If (Item.Level >= TradeOpts.GemLevel) {
			RequestParams.level_min := Item.Level
		}
		
		; experiment with values and maybe add an option
		If ((RegExMatch(Item.Name, "i)Empower|Enhance|Enlighten") or Item.Level >= 19) and TradeOpts.UseGemXP) {
			If (Item.Experience >= TradeOpts.GemXPThreshold) {			
				RequestParams.progress_min := Item.Experience
				RequestParams.progress_max := ""
				Item.UsedInSearch.ItemXP := Item.Experience
			}
		}	
	}

	/*
		divination cards and jewels
		*/
	If (Item.IsDivinationCard or Item.IsJewel) {
		RequestParams.xtype := Item.BaseType
		If (Item.IsJewel and Item.IsUnique) {
			RequestParams.xbase := Item.SubType
		}
		; TODO: add request param (not supported yet)
		If (Item.IsAbyssJewel) {
			;RequestParams. := 1
			;Item.UsedInSearch.abyssJewel := 1 
		}
	}
	
	/*
		prophecies
		*/
	If (Item.IsProphecy and RegExMatch(Item.Name, "i)A Master seeks Help")) {
		_tempItem	:= {}
		_tempItem.name_orig	:= "(prophecy) " ItemData.Affixes
		_tempItem.name		:= "(prophecy) " ItemData.Affixes
		_tempItem.param	:= "(prophecy) " ItemData.Affixes

		modParam := new _ParamMod()
		modParam.mod_name := _tempItem.param
		modParam.mod_min := 
		modParam.mod_max := 
		RequestParams.modGroups[1].AddMod(modParam)
	}

	/*
		predicted pricing (poeprices.info - machine learning)
		*/
	If (Item.RarityLevel > 2 and Item.RarityLevel < 4 and not (Item.IsCurrency or Item.IsDivinationCard or Item.IsEssence or Item.IsProphecy or Item.IsMap or Item.IsMapFragment or Item.IsGem or Item.IsBeast)) {		
		If ((Item.IsJewel or Item.IsFlask or Item.IsLeaguestone)) {
			If (Item.RarityLevel = 2) {
				itemEligibleForPredictedPricing := false	
			} Else {
				itemEligibleForPredictedPricing := true
			}
		}
		Else If (not (Item.RarityLevel = 3 and Item.IsUnidentified)) { ; filter out unid rare items
			itemEligibleForPredictedPricing := true	
		}		
	}

	/*
		show item age
		*/
	If (isItemAgeRequest) {
		RequestParams.name        := Item.Name
		RequestParams.has_buyout      := ""
		RequestParams.seller      := TradeOpts.AccountName
		RequestParams.q_min       := Item.Quality
		RequestParams.q_max       := Item.Quality
		RequestParams.rarity      := Item.IsRelic ? "relic" : Item.Rarity
		RequestParams.link_min    := ItemData.Links ? ItemData.Links : ""
		RequestParams.link_max    := ItemData.Links ? ItemData.Links : ""
		RequestParams.sockets_min := ItemData.Sockets ? ItemData.Sockets : ""
		RequestParams.sockets_max := ItemData.Sockets ? ItemData.Sockets : ""
		RequestParams.identified  := (!Item.IsUnidentified) ? "1" : "0"
		RequestParams.corrupted   := (Item.IsCorrupted) ? "1" : "0"
		RequestParams.enchanted   := (Enchantment.Length()) ? "1" : "0"
		; change values a bit to accommodate for rounding differences
		RequestParams.armour_min  := Stats.Defense.TotalArmour.Value - 2
		RequestParams.armour_max  := Stats.Defense.TotalArmour.Value + 2
		RequestParams.evasion_min := Stats.Defense.TotalEvasion.Value - 2
		RequestParams.evasion_max := Stats.Defense.TotalEvasion.Value + 2
		RequestParams.shield_min  := Stats.Defense.TotalEnergyShield.Value - 2
		RequestParams.shield_max  := Stats.Defense.TotalEnergyShield.Value + 2

		If (Item.IsGem) {
			RequestParams.level_min := Item.Level
			RequestParams.level_max := Item.Level
		}
		Else If (Item.Level and not Item.IsDivinationCard and not Item.IsCurrency) {
			RequestParams.ilvl_min := Item.Level
			RequestParams.ilvl_max := Item.Level
		}
	}
	
	/*
		parameter fixes
		*/
	If (StrLen(RequestParams.xtype) and StrLen(RequestParams.xbase)) {
		; Some type and base combinations on poe.trade are different than the ones in-game (Tyrant's Sekhem for example)
		; If we have the base we don't need the type though.
		RequestParams.xtype := ""
	}

	If (openSearchInBrowser) {
		If (!TradeOpts.BuyoutOnly) {
			RequestParams.has_buyout := ""
		}
	}

	/*
		create payload
		*/
	Payload := RequestParams.ToPayload()
	
	/*
		Create second payload for exact currency search (backup search if no results were found with primary currency)
		*/		
	If (not Item.IsCurrency and TradeOpts.ExactCurrencySearch) {
		Payload_alt := Payload
		Item.UsedInSearch.ExactCurrency := true
		
		ExactCurrencySearchOptions := TradeGlobals.Get("ExactCurrencySearchOptions").poetrade
		If (buyout_currency := ExactCurrencySearchOptions[TradeOpts.CurrencySearchHave]) {
			Payload .= "&buyout_currency=" TradeUtils.UriEncode(buyout_currency)
		}
		If (buyout_currency := ExactCurrencySearchOptions[TradeOpts.CurrencySearchHave2]) {
			Payload_alt .= "&buyout_currency=" TradeUtils.UriEncode(buyout_currency)
		}
	}	
	
	/*
		decide how to handle the request (open in browser on a specific site or make a POST/GET request to parse the results)
		*/		
	If (openSearchInBrowser) {
		ShowToolTip("Opening search in your browser... ")
	} Else If (not (TradeOpts.UsePredictedItemPricing and itemEligibleForPredictedPricing)) {
		ShowToolTip("Requesting search results... ")
	}

	ParsingError	:= ""
	currencyUrl	:= ""	
	If (Item.IsCurrency and not Item.IsEssence and TradeFunc_CurrencyFoundOnCurrencySearch(Item.Name)) {
		Item.priceHistory := TradeFunc_FindCurrencyHistoryData(Item.Name)
		If (!TradeOpts.AlternativeCurrencySearch or Item.IsFossil) {			
			Html := TradeFunc_DoCurrencyRequest(Item.Name, openSearchInBrowser, 0, currencyUrl, error)
			If (error) {
				ParsingError := Html
			}
		}
		Else {
			; Update currency data if last update is older than 30min
			last := TradeGlobals.Get("LastAltCurrencyUpdate")
			diff  := A_NowUTC
			EnvSub, diff, %last%, Seconds
			If (diff > 1800) {
				GoSub, ReadPoeNinjaCurrencyData
			}
		}
	}
	Else If (not openSearchInBrowser and TradeOpts.UsePredictedItemPricing and itemEligibleForPredictedPricing and not isAdvancedPriceCheckRedirect and not isItemAgeRequest) {
		requestCurl := ""
		Html := TradeFunc_DoPoePricesRequest(ItemData.FullText, requestCurl)
	}
	Else If (not openSearchInBrowser) {
		Html := TradeFunc_DoPostRequest(Payload, openSearchInBrowser)
	}

	If (openSearchInBrowser) {
		If (TradeOpts.PoENinjaSearch and (url := TradeFunc_GetPoENinjaItemUrl(TradeOpts.SearchLeague, Item))) {
			TradeFunc_OpenUrlInBrowser(url)
			If (not TradeOpts.CopyUrlToClipboard) {
				SetClipboardContents("")	
			}
		} Else {
			If (Item.IsCurrency and !Item.IsEssence and TradeFunc_CurrencyFoundOnCurrencySearch(Item.Name)) {
				ParsedUrl1 := currencyUrl
			}
			Else {
				; using GET request instead of preventing the POST request redirect and parsing the url
				parsedUrl1 := "https://poe.trade/search?" Payload
				; redirect was prevented to get the url and open the search on poe.trade instead
				;RegExMatch(Html, "i)href=""(https?:\/\/.*?)""", ParsedUrl)
			}

			If (StrLen(ParsingError)) {
				ShowToolTip("")
				ShowToolTip(ParsingError)
			} Else {
				TradeFunc_OpenUrlInBrowser(ParsedUrl1)
				If (not TradeOpts.CopyUrlToClipboard) {
					SetClipboardContents("")	
				}
			}
		}	
	}
	Else If (Item.isCurrency and !Item.IsEssence and TradeFunc_CurrencyFoundOnCurrencySearch(Item.Name)) {
		TradeFunc_AprilFools()
		
		; Default currency search
		If (!TradeOpts.AlternativeCurrencySearch or Item.IsFossil) {
			ParsedData := TradeFunc_ParseCurrencyHtml(Html, Payload, ParsingError)
		}
		; Alternative currency search (poeninja)
		Else {
			ParsedData := TradeFunc_ParseAlternativeCurrencySearch(Item.Name, Payload)
		}

		SetClipboardContents("")
		ShowToolTip("")
		ShowToolTip(ParsedData)
	}
	Else If (TradeOpts.UsePredictedItemPricing and itemEligibleForPredictedPricing and not isAdvancedPriceCheckRedirect and not isItemAgeRequest) {		
		TradeFunc_AprilFools()
		SetClipboardContents("")
	
		If (TradeFunc_ParsePoePricesInfoErrorCode(Html, requestCurl)) {
			If (TradeOpts.UsePredictedItemPricingGui) {
				TradeFunc_ShowPredictedPricingFeedbackUI(Html)
			} Else {
				ParsedData := TradeFunc_ParsePoePricesInfoData(Html)
				ShowToolTip("")
				ShowToolTip(ParsedData)
			}			
		}
	}
	Else {
		TradeFunc_AprilFools()
		; Check item age
		If (isItemAgeRequest) {
			Item.UsedInSearch.SearchType := "Item Age Search"
		}
		Else If (isAdvancedPriceCheckRedirect) {
			Item.UsedInSearch.SearchType := "Advanced"
		}
		Else {
			Item.UsedInSearch.SearchType := "Default"
		}
		
		; add second request for payload_alt (exact currency search fallback request)		
		searchResults := TradeFunc_ParseHtmlToObj(Html, Payload, iLvl, Enchantment, isItemAgeRequest, isAdvancedPriceCheckRedirect)
		If (not searchResults.results.length and StrLen(Payload_alt)) {
			Html := TradeFunc_DoPostRequest(Payload_alt, openSearchInBrowser)
			ParsedData := TradeFunc_ParseHtml(Html, Payload_alt, iLvl, Enchantment, isItemAgeRequest, isAdvancedPriceCheckRedirect)
		}
		Else {
			ParsedData := TradeFunc_ParseHtml(Html, Payload, iLvl, Enchantment, isItemAgeRequest, isAdvancedPriceCheckRedirect)	
		}		
		
		SetClipboardContents("")
		ShowToolTip("")
		ShowToolTip(ParsedData)
	}

	TradeGlobals.Set("AdvancedPriceCheckItem", {})
}

TradeFunc_FindMapHistoryData(baseType, tier) {
	For key, value in MapHistoryData {
		If (baseType = value.baseType and tier = value.mapTier) {
			Return {"totalChange" : value.sparkline.totalChange, "chaosValue" : value.chaosValue, "exaltedValue" : value.exaltedValue}
		}
	}
}
TradeFunc_FindFossilHistoryData(name) {
	For key, value in FossilHistoryData {
		If (name = value.name) {
			Return {"totalChange" : value.sparkline.totalChange, "chaosValue" : value.chaosValue, "exaltedValue" : value.exaltedValue}
		}
	}
}
TradeFunc_FindCurrencyHistoryData(name) {
	For key, value in CurrencyHistoryData {
		If (name = value.currencyTypeName) {			
			obj := {}
			If (value.receiveSparkLine.data.length) {
				obj.totalChange := value.receiveSparkLine.totalChange
			} Else {
				obj.totalChange := value.lowConfidenceReceiveSparkLine.totalChange
			}			
			obj.chaosValue := value.chaosEquivalent
			
			Return obj
		}
	}
}

TradeFunc_GetPoENinjaItemUrl(league, item) {	
	url := "https://poe.ninja/"

	If (league = "tmpstandard") {
		url .= "challenge/"
	} Else If (league = "tmphardcore") {
		url .= "challengehc/"
	} Else If (league = "standard") {
		url .= "standard/"
	} Else If (league = "hardcore") {
		url .= "hardcore/"
	} Else If (RegExMatch(league, "i)hc") and RegExMatch(league, "i)event")) {
		url .= "eventhc/"
	} Else If (RegExMatch(league, "i)event")) {
		url .= "event/"
	}
	
	If (Item.hasImplicit or item.hasEnchantment) {
		Enchantment := TradeFunc_GetEnchantment(Item, Item.SubType)
	}
	
	url_suffix := ""
	If (item.IsDivinationCard) {
		url_suffix := "divinationcards"
	} Else If (item.IsProphecy) {
		url_suffix := "prophecies"
	} Else If (item.IsFragment) {
		;url_suffix := "fragments"	; currently not supported (no filter)
	} Else If (item.IsGem) {
		;url_suffix := "skill-gems"	; supported but using poe.trade for this may be the better choice
	} Else If (item.IsEssence) {
		url_suffix := "essences"
	} Else If (item.SubType = "Helmet" and Enchantment[1].name) {
		url_suffix := "helmet-enchants"
	} Else If (item.IsUnique) {
		If (item.IsMap) {
			url_suffix := "unique-maps"
		} Else If (item.IsJewel) {
			url_suffix := "unique-jewels"
		} Else If (item.IsFlask) {
			url_suffix := "unique-flasks"
		} Else If (item.IsWeapon or item.IsQuiver) {
			url_suffix := "unique-weapons"
		} Else If (item.IsArmour) {
			url_suffix := "unique-armours"
		} Else If (item.IsRing or Item.IsBelt or Item.IsAmulet) {
			url_suffix := "unique-accessories"
		}
	} Else If (item.IsMap) {
		url_suffix := "maps"
	}
	
	; filters
	url_params := "?"
	url_param_1 := "name="
	url_param_2 := "&tier="
	
	If (item.IsMap) {
		url_param_arg_1 := TradeUtils.UriEncode(Item.BaseName)
		url_param_arg_2 := TradeUtils.UriEncode(Item.MapTier)
		url_params .= url_param_1 . url_param_arg_1 . url_param_2 . url_param_arg_2
	}
	Else If (item.SubType = "Helmet" and Enchantment.Length()) {
		url_param_arg_1 := TradeUtils.UriEncode(Enchantment[1].name)
		url_params .= url_param_1 . url_param_arg_1
	}
	Else {
		url_param_arg_1 := TradeUtils.UriEncode(Item.Name)
		url_params .= url_param_1 . url_param_arg_1
	}
	
	If (url_suffix) {
		Return url . url_suffix . url_params
	} Else {
		Return false
	}
}

TradeFunc_AddCustomModsToLeaguestone(ItemAffixes, Charges) {
	If (Item.AreaMonsterLevelReq.lvl) {
		ItemAffixes .= "`nCan only be used in Areas with Monster Level " Item.AreaMonsterLevelReq.lvl " or below"
	}

	If (Charges.max > 1) {
		ItemAffixes .= "`nCurrently has " Item.Charges.Current " Charges"
	}

	return ItemAffixes
}

; parse items defense stats
TradeFunc_ParseItemDefenseStats(stats, mods){
	Global ItemData
	iStats := {}
	debugOutput := ""

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
	baseES := TradeFunc_CalculateBase(EnergyShield1, affixPercentES1, Quality1, affixFlatES1)
	baseAR := TradeFunc_CalculateBase(Armour1      , affixPercentAR1, Quality1, affixFlatAR1)
	baseEV := TradeFunc_CalculateBase(Evasion1     , affixPercentEV1, Quality1, affixFlatEV1)

	; calculate items Q20 total defense stats
	Armour       := TradeFunc_CalculateQ20(baseAR, affixFlatAR1, affixPercentAR1)
	EnergyShield := TradeFunc_CalculateQ20(baseES, affixFlatES1, affixPercentES1)
	Evasion      := TradeFunc_CalculateQ20(baseEV, affixFlatEV1, affixPercentEV1)

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
				If (RegExMatch(affix, "i)#.*to maximum.*?Energy Shield"  , affixFlatES)) {
					If (not mod.isVariable) {
						min_affixFlatES    := mod.values[1]
						max_affixFlatES    := mod.values[1]
					}
					Else {
						min_affixFlatES    := mod.ranges[1][1]
						max_affixFlatES    := mod.ranges[1][2]
					}
					debugOutput .= affix "`nmax es : " min_affixFlatES " - " max_affixFlatES "`n`n"
				}
				If (RegExMatch(affix, "i)#.*to maximum.*?Armour"         , affixFlatAR)) {
					If (not mod.isVariable) {
						min_affixFlatAR    := mod.values[1]
						max_affixFlatAR    := mod.values[1]
					}
					Else {
						min_affixFlatAR    := mod.ranges[1][1]
						max_affixFlatAR    := mod.ranges[1][2]
					}
					debugOutput .= affix "`nmax ar : " min_affixFlatAR " - " max_affixFlatAR "`n`n"
				}
				If (RegExMatch(affix, "i)#.*to maximum.*?Evasion"        , affixFlatEV)) {
					If (not mod.isVariable) {
						min_affixFlatEV    := mod.values[1]
						max_affixFlatEV    := mod.values[1]
					}
					Else {
						min_affixFlatEV    := mod.ranges[1][1]
						max_affixFlatEV    := mod.ranges[1][2]
					}
					debugOutput .= affix "`nmax ev : " min_affixFlatEV " - " max_affixFlatEV "`n`n"
				}
				If (RegExMatch(affix, "i)#.*increased.*?Energy Shield"   , affixPercentES)) {
					If (not mod.isVariable) {
						min_affixPercentES := mod.values[1]
						max_affixPercentES := mod.values[1]
					}
					Else {
						min_affixPercentES := mod.ranges[1][1]
						max_affixPercentES := mod.ranges[1][2]
					}
					debugOutput .= affix "`ninc es : " min_affixPercentES " - " max_affixPercentES "`n`n"
				}
				If (RegExMatch(affix, "i)#.*increased.*?Evasion"         , affixPercentEV)) {
					If (not mod.isVariable) {
						min_affixPercentEV := mod.values[1]
						max_affixPercentEV := mod.values[1]
					}
					Else {
						min_affixPercentEV := mod.ranges[1][1]
						max_affixPercentEV := mod.ranges[1][2]
					}
					debugOutput .= affix "`ninc ev : " min_affixPercentEV " - " max_affixPercentEV "`n`n"
				}
				If (RegExMatch(affix, "i)#.*increased.*?Armour"          , affixPercentAR)) {
					If (not mod.isVariable) {
						min_affixPercentAR := mod.values[1]
						max_affixPercentAR := mod.values[1]
					}
					Else {
						min_affixPercentAR := mod.ranges[1][1]
						max_affixPercentAR := mod.ranges[1][2]
					}
					debugOutput .= affix "`ninc ar : " min_affixPercentAR " - " max_affixPercentAR "`n`n"
				}
			}
		}
	}

	min_Armour       := Round(TradeFunc_CalculateQ20(baseAR, min_affixFlatAR, min_affixPercentAR))
	max_Armour       := Round(TradeFunc_CalculateQ20(baseAR, max_affixFlatAR, max_affixPercentAR))
	min_EnergyShield := Round(TradeFunc_CalculateQ20(baseES, min_affixFlatES, min_affixPercentES))
	max_EnergyShield := Round(TradeFunc_CalculateQ20(baseES, max_affixFlatES, max_affixPercentES))
	min_Evasion      := Round(TradeFunc_CalculateQ20(baseEV, min_affixFlatEV, min_affixPercentEV))
	max_Evasion      := Round(TradeFunc_CalculateQ20(baseEV, max_affixFlatEV, max_affixPercentEV))

	iStats.TotalBlock			:= {}
	iStats.TotalBlock.Value 		:= Block1
	iStats.TotalBlock.Name  		:= "Block Chance"
	iStats.TotalArmour			:= {}
	iStats.TotalArmour.Value		:= Armour
	iStats.TotalArmour.Name		:= "Armour"
	iStats.TotalArmour.Base		:= baseAR
	iStats.TotalArmour.min  		:= min_Armour
	iStats.TotalArmour.max  		:= max_Armour
	iStats.TotalEnergyShield		:= {}
	iStats.TotalEnergyShield.Value:= EnergyShield
	iStats.TotalEnergyShield.Name	:= "Energy Shield"
	iStats.TotalEnergyShield.Base	:= baseES
	iStats.TotalEnergyShield.min 	:= min_EnergyShield
	iStats.TotalEnergyShield.max	:= max_EnergyShield
	iStats.TotalEvasion			:= {}
	iStats.TotalEvasion.Value	:= Evasion
	iStats.TotalEvasion.Name		:= "Evasion Rating"
	iStats.TotalEvasion.Base		:= baseEV
	iStats.TotalEvasion.min		:= min_Evasion
	iStats.TotalEvasion.max		:= max_Evasion
	iStats.Quality				:= Quality1

	If (TradeOpts.Debug) {
		;console.log(output)
	}

	Return iStats
}

TradeFunc_CalculateBase(total, affixPercent, qualityPercent, affixFlat){
	SetFormat, FloatFast, 5.2
	If (total) {
		affixPercent  := (affixPercent) ? (affixPercent / 100) : 0
		affixFlat     := (affixFlat) ? affixFlat : 0
		qualityPercent:= (qualityPercent) ? (qualityPercent / 100) : 0
		base := Round((total / (1 + affixPercent + qualityPercent)) - affixFlat)
		Return base
	}
	return
}
TradeFunc_CalculateQ20(base, affixFlat, affixPercent){
	SetFormat, FloatFast, 5.2
	If (base) {
		affixPercent  := (affixPercent) ? (affixPercent / 100) : 0
		affixFlat     := (affixFlat) ? affixFlat : 0
		total := (base + affixFlat) * (1 + affixPercent + (20 / 100))
		Return total
	}
	return
}

; parse items dmg stats
TradeFunc_ParseItemOffenseStats(Stats, mods) {	
	Global ItemData
	iStats := {}
	debugOutput :=

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

			nname :=
			If (RegExMatch(affix, "Adds.*Lightning Damage")) {
				affix := RegExReplace(affix, "i)to (\d+)", "to #")
				affix := RegExReplace(affix, "i)to (\d+.*?\d+?)", "to #")
				If (not mod.isVariable) {
					nname := RegExReplace(mod.name, "i)(Adds )(#)( Lightning Damage)", "$1" mod.values[1] " to #$3")
				}
			}
			Else {
				affix := RegExReplace(affix, "i)(\d+ to \d+)", "#")
				affix := RegExReplace(affix, "i)(\d+.*?\d+?)", "#")
			}
			affix := RegExReplace(affix, "i)# %", "#%")
			affix := Trim(RegExReplace(affix, "\s", " "))
			nname := StrLen(nname) ? Trim(nname) : Trim(mod.name)

			If ( affix = nname ){
				match :=
				; ignore mods like " ... per X dexterity" and "damage to spells"
				If (RegExMatch(affix, "i) per | to spells")) {
					continue
				}
				If (RegExMatch(affix, "i)Adds.*#.*(Physical|Fire|Cold|Chaos) Damage", dmgType)) {
					If (not mod.isVariable) {
						min_affixFlat%dmgType1%Low    := mod.values[1]
						min_affixFlat%dmgType1%Hi     := mod.values[2]
						max_affixFlat%dmgType1%Low    := mod.values[1]
						max_affixFlat%dmgType1%Hi     := mod.values[2]
					}
					Else {
						min_affixFlat%dmgType1%Low    := mod.ranges[1][1]
						min_affixFlat%dmgType1%Hi     := mod.ranges[1][2]
						max_affixFlat%dmgType1%Low    := mod.ranges[2][1]
						max_affixFlat%dmgType1%Hi     := mod.ranges[2][2]
					}
					debugOutput .= affix "`nflat " dmgType1 " : " min_affixFlat%dmgType1%Low " - " min_affixFlat%dmgType1%Hi " to " max_affixFlat%dmgType1%Low " - " max_affixFlat%dmgType1%Hi "`n`n"
				}
				If (RegExMatch(affix, "i)Adds.*(\d+) to #.*(Lightning) Damage", match)) {
					If (not mod.isVariable) {
						min_affixFlat%match2%Low    := match1
						min_affixFlat%match2%Hi     := match1
						max_affixFlat%match2%Low    := mod.values[2]
						max_affixFlat%match2%Hi     := mod.values[2]
					}
					Else {
						min_affixFlat%match2%Low    := match1
						min_affixFlat%match2%Hi     := match1
						max_affixFlat%match2%Low    := mod.ranges[1][1]
						max_affixFlat%match2%Hi     := mod.ranges[1][2]
					}
					debugOutput .= affix "`nflat " match2 " : " min_affixFlat%match2%Low " - " min_affixFlat%match2%Hi " to " max_affixFlat%match2%Low " - " max_affixFlat%match2%Hi "`n`n"
				}
				If (RegExMatch(affix, "i)#.*increased Physical Damage")) {
					If (not mod.isVariable) {
						min_affixPercentPhys    := mod.values[1]
						max_affixPercentPhys    := mod.values[1]
					}
					Else {
						min_affixPercentPhys    := mod.ranges[1][1]
						max_affixPercentPhys    := mod.ranges[1][2]
					}
					debugOutput .= affix "`ninc Phys : " min_affixPercentPhys " - " max_affixPercentPhys "`n`n"
				}
				If (RegExMatch(affix, "i)#.*increased Attack Speed")) {
					If (not mod.isVariable) {
						min_affixPercentAPS     := mod.values[1] / 100
						max_affixPercentAPS     := mod.values[1] / 100
					}
					Else {
						min_affixPercentAPS     := mod.ranges[1][1] / 100
						max_affixPercentAPS     := mod.ranges[1][2] / 100
					}
					debugOutput .= affix "`ninc attack speed : " min_affixPercentAPS " - " max_affixPercentAPS "`n`n"
				}
			}
		}
	}

	SetFormat, FloatFast, 5.2
	baseAPS      := (!affixAttackSpeed) ? AttacksPerSecond : AttacksPerSecond / (1 + (affixAttackSpeed / 100))
	basePhysLow  := TradeFunc_CalculateBase(physicalDamageLow, affixPercentPhys, Stats.Quality, affixFlatPhysLow)
	basePhysHi   := TradeFunc_CalculateBase(physicalDamageHi , affixPercentPhys, Stats.Quality, affixFlatPhysHi)

	minPhysLow   := Round(TradeFunc_CalculateQ20(basePhysLow, min_affixFlatPhysicalLow, min_affixPercentPhys))
	minPhysHi    := Round(TradeFunc_CalculateQ20(basePhysHi , max_affixFlatPhysicalLow, min_affixPercentPhys))
	maxPhysLow   := Round(TradeFunc_CalculateQ20(basePhysLow, min_affixFlatPhysicalHi , max_affixPercentPhys))
	maxPhysHi    := Round(TradeFunc_CalculateQ20(basePhysHi , max_affixFlatPhysicalHi , max_affixPercentPhys))
	min_affixPercentAPS := (min_affixPercentAPS) ? min_affixPercentAPS : 0
	max_affixPercentAPS := (max_affixPercentAPS) ? max_affixPercentAPS : 0

	SetFormat, FloatFast, 5.4
	minAPS       := baseAPS * (1 + min_affixPercentAPS)
	maxAPS       := baseAPS * (1 + max_affixPercentAPS)
	For key, val in mods.stats {
		If (val.name = "APS") {
			If (val.ranges[1][1]) {
				minAPS := val.ranges[1][1]
			}
			If (val.ranges[1][2]) {
				maxAPS := val.ranges[1][2]
			}
		}
	}

	iStats.PhysDps        := {}
	iStats.PhysDps.Name   := "Physical Dps (Q20)"
	iStats.PhysDps.Value  := (Stats.Q20Dps > 0) ? (Stats.Q20Dps - Stats.EleDps - Stats.ChaosDps) : Stats.PhysDps
	iStats.PhysDps.Min    := Floor(((minPhysLow + minPhysHi) / 2) * minAPS)
	iStats.PhysDps.Max    := Ceil(((maxPhysLow + maxPhysHi) / 2) * maxAPS)
	iStats.EleDps         := {}
	iStats.EleDps.Name    := "Elemental Dps"
	iStats.EleDps.Value   := Stats.EleDps
	iStats.EleDps.Min     := Floor(TradeFunc_CalculateEleDps(min_affixFlatFireLow, max_affixFlatFireLow, min_affixFlatColdLow, max_affixFlatColdLow, min_affixFlatLightningLow, max_affixFlatLightningLow, minAPS))
	iStats.EleDps.Max     := Ceil(TradeFunc_CalculateEleDps(min_affixFlatFireHi, max_affixFlatFireHi, min_affixFlatColdHi, max_affixFlatColdHi, min_affixFlatLightningHi, max_affixFlatLightningHi, maxAPS))

	debugOutput .= "Phys DPS: " iStats.PhysDps.Value "`n" "Phys Min: " iStats.PhysDps.Min "`n" "Phys Max: " iStats.PhysDps.Max "`n" "EleDps: " iStats.EleDps.Value "`n" "Ele Min: " iStats.EleDps.Min "`n" "Ele Max: "  iStats.EleDps.Max

	If (TradeOpts.Debug) {
		;console.log(debugOutput)
	}
	SetFormat, FloatFast, 5.2

	Return iStats
}

TradeFunc_CalculateEleDps(fireLo, fireHi, coldLo, coldHi, lightLo, lightHi, aps) {
	dps := 0
	fireLo  := fireLo  > 0 ? fireLo  : 0
	fireHi  := fireHi  > 0 ? fireHi  : 0
	coldLo  := coldLo  > 0 ? coldLo  : 0
	coldHi  := coldHi  > 0 ? coldHi  : 0
	lightLo := lightLo > 0 ? lightLo : 0
	lightHi := lightHi > 0 ? lightHi : 0

	If (TradeOpts.Debug) {
		;console.log("((" fireLo " + " fireHi " + " coldLo " + " coldHi " + " lightLo " + " lightHi ") / 2) * " aps " )")
	}
	dps := ((fireLo + fireHi + coldLo + coldHi + lightLo + lightHi) / 2) * aps
	dps := Round(dps, 1)

	return dps
}

TradeFunc_CompareGemNames(name, ByRef found = false) {
	poeTradeNames := TradeGlobals.Get("GemNameList")

	If (poeTradeNames.Length() < 1) {
		return name
	}
	Else {
		Loop, % poeTradeNames.Length() {
			stack := Trim(RegExReplace(poeTradeNames[A_Index], "i)support", ""))
			If (stack = name) {
				found := true
				return poeTradeNames[A_Index]
			}
		}
		return name
	}
}

TradeFunc_GetUniqueStats(name, isRelic = false) {
	items := isRelic ? TradeGlobals.Get("VariableRelicData") : TradeGlobals.Get("VariableUniqueData")
	For i, uitem in items {
		If (name = uitem.name) {
			Return uitem.stats
		}
	}
}

; copied from PoE-ItemInfo because there it'll only be called If the option "ShowMaxSockets" is enabled
TradeFunc_SetItemSockets() {
	Global Item

	If (Item.IsWeapon or Item.IsArmour)
	{
		If (Item.Level >= 50) {
			Item.MaxSockets := 6
		}
		Else If (Item.Level >= 35) {
			Item.MaxSockets := 5
		}
		Else If (Item.Level >= 25) {
			Item.MaxSockets := 4
		}
		Else If (Item.Level >= 1) {
			Item.MaxSockets := 3
		}
		Else	{
			Item.MaxSockets := 2
		}

		If (Item.IsFourSocket and Item.MaxSockets > 4) {
			Item.MaxSockets := 4
		}
		Else If (Item.IsThreeSocket and Item.MaxSockets > 3) {
			Item.MaxSockets := 3
		}
		Else If (Item.IsSingleSocket)	{
			Item.MaxSockets := 1
		}
	}
}

TradeFunc_CheckIfItemIsCraftingBase(type){
	bases := TradeGlobals.Get("CraftingData")
	For i, base in bases {
		If (type = base) {
			Return true
		}
	}
	Return false
}

TradeFunc_CheckIfItemHasHighestCraftingLevel(subtype, iLvl){
	If (RegExMatch(subtype, "i)Helmet|Gloves|Boots|Body Armour|Shield|Quiver")) {
		Return (iLvl >= 84) ? 84 : false
	}
	Else If (RegExMatch(subtype, "i)Weapon")) {
		Return (iLvl >= 83) ? 83 : false
	}
	Else If (RegExMatch(subtype, "i)Belt|Amulet|Ring")) {
		Return (iLvl >= 83) ? 83 : false
	}
	Return false
}

TradeFunc_DoParseClipboard()
{
	Global Opts, Globals
	CBContents := GetClipboardContents()
	CBContents := PreProcessContents(CBContents)

	Globals.Set("ItemText", CBContents)
	Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)

	ParsedData := ParseItemData(CBContents)
}

TradeFunc_DoPostRequest(payload, openSearchInBrowser = false) {
	UserAgent   := TradeGlobals.Get("UserAgent")
	cfduid      := TradeGlobals.Get("cfduid")
	cfClearance := TradeGlobals.Get("cfClearance")

	postData 	:= payload
	payLength	:= StrLen(postData)
	url 		:= "https://poe.trade/search"
	options	:= ""
	options	.= "`n" "ReturnHeaders: append"
	options	.= "`n" "TimeOut: " TradeOpts.CurlTimeout

	reqHeaders	:= []
	reqHeaders.push("Connection: keep-alive")
	reqHeaders.push("Cache-Control: max-age=0")
	reqHeaders.push("Origin: https://poe.trade")
	reqHeaders.push("Upgrade-Insecure-Requests: 1")
	reqHeaders.push("Content-type: application/x-www-form-urlencoded; charset=UTF-8")
	reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
	reqHeaders.push("Referer: https://poe.trade/")	
	
	If (StrLen(UserAgent)) {
		reqHeaders.push("User-Agent: " UserAgent)
		reqHeaders.push("Cookie: __cfduid=" cfduid "; cf_clearance=" cfClearance)
	} Else {
		reqHeaders.push("User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36")
	}

	html := PoEScripts_Download(url, postData, reqHeaders, options, false)
	
	If (TradeOpts.Debug) {
		FileDelete, %A_ScriptDir%\temp\DebugSearchOutput.html
		FileAppend, %html%, %A_ScriptDir%\temp\DebugSearchOutput.html
	}

	Return, html
}

TradeFunc_ParseRequestErrors(response) {
	RegExMatch(Trim(response), "i)'(\d{1,3})'$", httpCode)
	response := RegExReplace(Trim(response), "i)(.*)('\d{1,3}')$", "$1")
	
	error := ""
	If (httpCode1 = "000") {
		error := "ERROR: Client disconnected before completing the request to poe.trade."
		error .= "`n`n" "The timeout (currently " TradeOpts.CurlTimeout "s) may have to be increased."
		error .= "`n" "You can do this in the settings menu -> ""TradeMacro"" tab."
		error .=  "`n`n" "This might just be a temporary issue because of slow server responses."
	}

	Return error
}

TradeFunc_DoPoePricesRequest(RawItemData, ByRef retCurl) {
	RawItemData := RegExReplace(RawItemData, "<<.*?>>|<.*?>")
	encodingError := ""
	EncodedItemData := StringToBase64UriEncoded(RawItemData, true, encodingError)
	
	postData 	:= "l=" UriEncode(TradeGlobals.Get("LeagueName")) "&i=" EncodedItemData
	payLength	:= StrLen(postData)
	url 		:= "https://www.poeprices.info/api"
	
	reqTimeout := 25
	options	:= "RequestType: GET"
	;options	.= "`n" "ReturnHeaders: skip"
	options	.= "`n" "ReturnHeaders: append"
	options	.= "`n" "TimeOut: " reqTimeout
	reqHeaders := []

	reqHeaders.push("Connection: keep-alive")
	reqHeaders.push("Cache-Control: max-age=0")
	reqHeaders.push("Origin: https://poeprices.info")
	reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8")
	
	ShowToolTip("Getting price prediction... ")
	retCurl := true
	response := PoEScripts_Download(url, postData, reqHeaders, options, false, false, false, "", "", true, retCurl)
	
	debugout := RegExReplace("""" A_ScriptDir "\lib\" retCurl, "curl", "curl.exe""")
	FileDelete, %A_ScriptDir%\temp\poeprices_request.txt
	FileAppend, %debugout%, %A_ScriptDir%\temp\poeprices_request.txt
	
	
	If (TradeOpts.Debug) {
		FileDelete, %A_ScriptDir%\temp\DebugSearchOutput.html
		FileAppend, %response%, %A_ScriptDir%\temp\DebugSearchOutput.html
	}

	responseObj := {}
	responseHeader := ""
	
	RegExMatch(response, "is)(.*?({.*}))?.*?'(.*?)'.*", responseMatch)
	response := responseMatch1
	responseHeader := responseMatch3
	
	Try {
		responseObj := JSON.Load(response)
	} Catch e {
		responseObj.failed := "ERROR: Parsing response failed, invalid JSON! "
	}
	
	If (not isObject(responseObj)) {		
		responseObj := {}
	}

	If (TradeOpts.Debug) {
		arr := {}
		arr.RawItemData := RawItemData
		arr.EncodedItemata := EncodedItemData
		arr.League := TradeGlobals.Get("LeagueName")
		TradeFunc_LogPoePricesRequest(arr, request, "poe_prices_debug_log.txt")
	}

	responseObj.added := {}
	responseObj.added.encodedData := EncodedItemData
	responseObj.added.league := TradeGlobals.Get("LeagueName")
	responseObj.added.requestUrl := url "?" postData
	responseObj.added.browserUrl := url "?" postData "&w=1"
	responseObj.added.encodingError := encodingError
	responseObj.added.retHeader := responseHeader
	responseObj.added.timeoutParam := reqTimeout
	
	Return responseObj
}

TradeFunc_ParsePoePricesInfoErrorCode(response, request) {
	httpErrors := {"403":"Forbidden", "404":"Not Found", "504":"Gateway Timeout", "000":"Client disconnected"}
	; https://docs.google.com/spreadsheets/d/1XwHk6FZwzRDxTbDraGkMy5sF0mfGJhCIzCmLSD66JO0/edit#gid=0
	If (RegExMatch(response.added.retHeader, "i)(403|404|504)", errMatch)) {
		ShowToolTip("")
		errorDesc := " (" httpErrors[errMatch1] ")"
		ShowTooltip("ERROR: Request to poeprices.info returned HTTP ERROR " errMatch1 errorDesc "! `n`nPlease take a look at the file ""temp\poeprices_log.txt"".")
		TradeFunc_LogPoePricesRequest(response, request)
		Return 0
	}
	Else If (RegExMatch(response.added.retHeader, "i)(000)", errMatch)) {
		ShowToolTip("")
		ShowTooltip("ERROR: Client disconnected before completing the request to poeprices.info.`nA possible cause is that the timeout was set too low (" response.added.timeoutParam "s) and may have to be increased! `n`nThis might be a temporary issue because of slow server responses.`nPlease report it anyway.")
		TradeFunc_LogPoePricesRequest(response, request)
		Return 0
	}
	Else If (not response or not response.HasKey("error")) {
		ShowToolTip("")
		ShowTooltip("ERROR: Request to poeprices.info timed out or`nreturned an invalid response! `n`nPlease take a look at the file ""temp\poeprices_log.txt"".")
		TradeFunc_LogPoePricesRequest(response, request)
		Return 0
	}
	Else If (response.error != "0") {
		ShowToolTip("")
		If (response.error_msg) {
			msg := "ERROR: Predicted search has encountered an issue! `n`n"
			msg .= "Returned message: `n"
			msg .= TradeFunc_AddLineBreaksToText(response.error_msg, 100)
			ShowTooltip(msg)
		} Else {
			ShowTooltip("ERROR: Predicted search has encountered an unknown error! `n`nPlease take a look at the file ""temp\poeprices_log.txt"".")
		}
		TradeFunc_LogPoePricesRequest(response, request)		
		Return 0
	}
	Else If (response.error = "0") {
		min := response.HasKey("min") or response.HasKey("min_price") ? true : false
		max := response.HasKey("max") or response.HasKey("max_price") ? true : false		
		
		min_value := StrLen(response.min) ? response.min : response.min_price
		max_value := StrLen(response.max) ? response.max : response.max_price
		
		If (min and max) {
			If (not StrLen(min_value) and not StrLen(max_value)) {
				ShowToolTip("")
				ShowTooltip("No price prediction available. `n`nItem not found, insufficient sample data.")
				Return 0
			}
		} Else If (not StrLen(min_value) and not StrLen(max_value)) {
			ShowToolTip("")
			ShowTooltip("ERROR: Request to poeprices.info failed,`nno prices were returned! `n`nPlease take a look at the file ""temp\poeprices_log.txt"".")
			TradeFunc_LogPoePricesRequest(response, request)
			Return 0
		}
		
		Return 1
	}
	Return 0
}

TradeFunc_AddLineBreaksToText(text, approximateCharsPerLine) {
	arr := StrSplit(text, " ")
	
	string := ""
	l := 0
	For key, value in arr {
		l += StrLen(value) + 1
		If (l >= approximateCharsPerLine) {
			string .= " " value "`n"
			l := 0
		} Else {
			string .= " " value
		}
	}
	
	Return string
}

TradeFunc_LogPoePricesRequest(response, request, filename = "poeprices_log.txt") {
	text := "#####"
	text .= "`n### " "Please post this log file below to https://www.pathofexile.com/forum/view-thread/1216141/."	
	text .= "`n### " "Try not to ""spam"" their thread if a few other reports with the same error description were posted in the last hours."	
	text .= "`n#####"	
	
	text .= "`n`n"
	text .= "Request and response:`n"
	Try {
		text .= JSON.Dump(response, "", 4)
	} Catch e {
		text .= response
	}
	
	FileDelete, %A_ScriptDir%\temp\%filename%
	FileAppend, %text%, %A_ScriptDir%\temp\%filename%
	
	Return
}

TradeFunc_MapCurrencyNameToID(name) {
	; map the actual ingame name of the currency to the one used on poe.trade and get the corresponding ID
	name := RegExReplace(name, "i) ", "_")
	name := RegExReplace(name, "i)'", "")
	mappedName := TradeCurrencyNames.eng[name]
	ID := TradeGlobals.Get("CurrencyIDs")[mappedName]

	Return ID
}

; Get currency.poe.trade html
; Either at script start to parse the currency IDs or when searching to get currency listings
TradeFunc_DoCurrencyRequest(currencyName = "", openSearchInBrowser = false, init = false, ByRef currencyURL = "", ByRef error = 0) {
	UserAgent   := TradeGlobals.Get("UserAgent")
	cfduid      := TradeGlobals.Get("cfduid")
	cfClearance := TradeGlobals.Get("cfClearance")

	If (init) {
		Url := "http://currency.poe.trade/"
		SplashUI.SetSubMessage("Looking up poe.trade currency IDs...")
	}
	Else {
		LeagueName := TradeGlobals.Get("LeagueName")
		IDs := TradeGlobals.Get("CurrencyIDs")
		Have:= TradeOpts.CurrencySearchHave
		If (Have = currencyName) {
			Have := TradeOpts.CurrencySearchHave2
		}

		; currently not necessary
		; idWant := TradeFunc_MapCurrencyNameToID(currencyName)
		; idHave := TradeFunc_MapCurrencyNameToID(TradeOpts.CurrencySearchHave)

		idWant := IDs[currencyName]
		idHave := IDs[Have]
		minStockSize := 0

		If (idWant and idHave) {
			Url := "http://currency.poe.trade/search?league=" . TradeUtils.UriEncode(LeagueName) . "&online=x&want=" . idWant . "&have=" . idHave . "&stock=" . minStockSize
			currencyURL := Url
		} Else {
			errorMsg = Couldn't find currency "%currencyname%" on poe.trade's currency search.`n`nThis search needs to know the currency names used on poe.trades currency page.`n`nEither this item doesn't exist on that page or parsing and mapping the poe.trade`nnames to the actual names failed. Please report this issue.
			error := 1
			Return, errorMsg
		}
	}

	postData 	:= ""
	options	:= ""
	options	.= "`n" "ReturnHeaders: append"
	options	.= "`n" "TimeOut: " TradeOpts.CurlTimeout

	reqHeaders	:= []
	If (StrLen(UserAgent)) {
		reqHeaders.push("User-Agent: " UserAgent)
		authHeaders.push("User-Agent: " UserAgent)
		reqHeaders.push("Cookie: __cfduid=" cfduid "; cf_clearance=" cfClearance)
		authHeaders.push("Cookie: __cfduid=" cfduid "; cf_clearance=" cfClearance)
	} Else {
		reqHeaders.push("User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36")
	}

	reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8")
	reqHeaders.push("Accept-Encoding:gzip, deflate")
	reqHeaders.push("Accept-Language:de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4")
	reqHeaders.push("Connection:keep-alive")
	reqHeaders.push("Referer:https://poe.trade/")
	reqHeaders.push("Upgrade-Insecure-Requests:1")

	html := PoEScripts_Download(url, postData, reqHeaders, options, false)

	If (init) {
		TradeFunc_ParseCurrencyIDs(html)
		Return
	}

	If (TradeOpts.Debug) {
		FileDelete, %A_ScriptDir%\temp\DebugSearchOutput.txt
		FileAppend, %html%, %A_ScriptDir%\temp\DebugSearchOutput.txt
	}

	Return, html
}

; Open given Url with default Browser
TradeFunc_OpenUrlInBrowser(Url) {
	Global TradeOpts
	
	openWith :=
	If (TradeOpts.CopyUrlToClipboard) {	
		SuspendPOEItemScript := 1
		Clipboard = %Url%		
		SuspendPOEItemScript := 0
		shortenedUrl := StrLen(Url) > 50 ? SubStr(Url, 1, 50) "..." : Url
		ShowToolTip("Copied URL to clipboard:`n`n" shortenedUrl)
		Return
	}	
	Else If (TradeFunc_CheckBrowserPath(TradeOpts.BrowserPath, false)) {
		openWith := TradeOpts.BrowserPath
		OpenWebPageWith(openWith, Url)
	}
	Else If (TradeOpts.OpenWithDefaultWin10Fix) {
		openWith := AssociatedProgram("html")
		OpenWebPageWith(openWith, Url)
	}
	Else {
		Run %Url%
	}
}

TradeFunc_CurrencyFoundOnCurrencySearch(currencyName) {
	id := TradeGlobals.Get("CurrencyIDs")[currencyName]
	Return StrLen(id) > 0 ? 1 : 0
}

; Parse currency.poe.trade to get all available currencies and their IDs
TradeFunc_ParseCurrencyIDs(html) {
	; remove linebreaks and replace multiple spaces with a single one
	StringReplace, html,html, `r,, All
	StringReplace, html,html, `n,, All
	html := RegExReplace(html,"\s+"," ")

	categoryBlocks := []
	Pos		:= 0
	While Pos := RegExMatch(html, "i)id=""cat-want-(.*?)(id=""cat-want-|id=""cat-have-|input)", match, Pos + (StrLen(match1) ? StrLen(match1) : 1)) {
		categoryBlocks.push(match1)
	}

	RegExMatch(html, "is)id=""currency-want"">(.*?)input", match)
	startStringCurrency	:= "<div data-tooltip"
	startStringOthers	:= "<div class=""currency-selectable"

	Currencies := {}

	For key, val in categoryBlocks {
		Loop {
			start := key > 2 ? startStringOthers : startStringCurrency
			CurrencyBlock 	:= TradeUtils.HtmlParseItemData(val, start . "(.*?)>", val)
			CurrencyName 	:= TradeUtils.HtmlParseItemData(CurrencyBlock, "title=""(.*?)""")
			CurrencyID 	:= TradeUtils.HtmlParseItemData(CurrencyBlock, "data-id=""(.*?)""")
			CurrencyName 	:= StrReplace(CurrencyName, "&#39;", "'")

			If (!CurrencyName) {
				TradeGlobals.Set("CurrencyIDs", Currencies)
				break
			}

			match1 := match1
			match1 := SubStr(match1, StrLen(CurrencyBlock))

			Currencies[CurrencyName] := CurrencyID
		}
	}

	If (!Currencies["Chaos Orb"]) {
		Currencies := TradeCurrencyIDsFallback
	}

	TradeGlobals.Set("CurrencyIDs", Currencies)
}

; Parse currency.poe.trade to display tooltip with first X listings
TradeFunc_ParseCurrencyHtml(html, payload, ParsingError = "") {
	Global Item, ItemData, TradeOpts
	LeagueName := TradeGlobals.Get("LeagueName")
	
	httpError := TradeFunc_ParseRequestErrors(html)
	If (httpError) {
		Return httpError
	}	
	
	If (StrLen(ParsingError)) {
		Return, ParsingError
	}

	Title := Item.Name
	Title .= " (" LeagueName ")"
	Title .= "`n------------------------------ `n"
	NoOfItemsToShow := TradeOpts.ShowItemResults

	totalChangeSign := (Item.priceHistory.totalChange > 0) ? "+" : ""
	If (Item.IsFossil or Item.IsCurrency) {
		If (Item.priceHistory.exaltedValue >= 1) {
			Title .= "poe.ninja price history: " Round(Item.priceHistory.exaltedValue, 2) " exalted."	
		} Else {
			Title .= "poe.ninja price history: " Round(Item.priceHistory.chaosValue, 2) " chaos."	
		}
		Title .= " Change: " totalChangeSign "" Round(Item.priceHistory.totalChange, 0) "% (last 7 days).`n`n"
	}

	Title .= StrPad("IGN" ,10)
	Title .= StrPad("| Ratio",20)
	Title .= "| " . StrPad("Buy  ",20, "Left")
	Title .= StrPad("Pay",18)
	Title .= StrPad("| Stock",8)
	Title .= "`n"

	Title .= StrPad("----------" ,10)
	Title .= StrPad("--------------------",20)
	Title .= StrPad("--------------------",20)
	Title .= StrPad("--------------------",18)
	Title .= StrPad("--------",8)
	Title .= "`n"

	SetFormat, float, 0.4

	While A_Index < NoOfItemsToShow {
		Offer       := TradeUtils.StrX( html,   "data-username=""",     N, 0, "Contact Seller"   , 1,1, N )
		SellCurrency:= TradeUtils.StrX( Offer,  "data-sellcurrency=""", 1,19, """"        , 1,1, T )
		SellValue   := TradeUtils.StrX( Offer,  "data-sellvalue=""",    1,16, """"        , 1,1, T )
		BuyValue    := TradeUtils.StrX( Offer,  "data-buyvalue=""",     1,15, """"        , 1,1, T )
		BuyCurrency := TradeUtils.StrX( Offer,  "data-buycurrency=""",  1,18, """"        , 1,1, T )
		AccountName := TradeUtils.StrX( Offer,  "data-ign=""",          1,10, """"        , 1,1    )

		RatioBuying := BuyValue / SellValue
		RatioSelling  := SellValue / BuyValue

		Pos   := RegExMatch(Offer, "si)displayoffer-bottom(.*)", StockMatch)
		Loop, Parse, StockMatch, `n, `r
		{
			RegExMatch(TradeUtils.CleanUp(A_LoopField), "i)Stock:? ?(\d+) ", StockMatch)
			If (StockMatch) {
				Stock := StockMatch1
			}
		}

		Pos := RegExMatch(Offer, "si)displayoffer-primary(.*)<.*displayoffer-centered", Display)
		P := ""
		DisplayNames := []
		Loop {
			Column := TradeUtils.StrX( Display1, "column", P, 0, "</div", 1,1, P )
			RegExMatch(Column, ">(.*)<", Column)
			Column := RegExReplace(Column1, "\t|\r|\n", "")
			If (StrLen(Column) < 1) {
				Break
			}
			Column := StrReplace(Column, "&#39;", "'")
			DisplayNames.Push(Column)
		}

		subAcc := TradeFunc_TrimNames(AccountName, 10, true)
		Title .= StrPad(subAcc,10)
		Title .= StrPad("| " . "1 <-- " . TradeUtils.ZeroTrim(RatioBuying)            ,20)
		Title .= StrPad("| " . StrPad(DisplayNames[1] . " " . StrPad(TradeUtils.ZeroTrim(SellValue), 4, "left"), 17, "left") ,20)
		Title .= StrPad("<= " . StrPad(TradeUtils.ZeroTrim(BuyValue), 4) . " " . DisplayNames[3] ,20)
		Title .= StrPad("| " . Stock,8)
		Title .= "`n"
	}

	Return, Title
}

TradeFunc_ParseAlternativeCurrencySearch(name, payload) {
	Global Item, ItemData, TradeOpts
	
	LeagueName	:= RegexReplace(TradeGlobals.Get("LeagueName"), "\s")
	shortName		:= Trim(RegExReplace(name,  "Orb\s?|\s?of| Cartographer's", ""))
	shortTitleName	:= Trim(RegExReplace(Item.Name,  " Cartographer's", ""))

	Title := StrPad(shortTitleName " (" LeagueName ")", 44)
	Title .= StrPad("provided by poe.ninja", 25, "left")
	Title .= "`n---------------------------------------------------------------------`n"

	Title .= StrPad("" , 11)
	Title .= StrPad("|| Buy (" shortName ")" , 28)
	Title .= StrPad("|| Sell (" shortName ")", 28)
	Title .= "`n"
	Title .= StrPad("===========||==========================||============================", 40)
	Title .= "`n"

	Title .= StrPad("Time" , 11)
	Title .= StrPad("|| Pay (Chaos)", 15)
	Title .= StrPad("| Get", 13)

	Title .= StrPad("|| Pay", 14)
	Title .= StrPad("| Get (Chaos)", 15)

	Title .= "`n"
	Title .= StrPad("-----------||-------------|------------||------------|---------------", 40)

	currencyData :=
	For key, val in CurrencyHistoryData {
		If (val.currencyTypeName = name) {
			currencyData := val
			break
		}
	}

	prices		:= {}
	prices.pay	:= {}
	prices.receive	:= {}
	prices.pay.pay	:= []
	prices.pay.get	:= []
	prices.pay.highestDigitPay	:= 1
	prices.pay.highestDigitGet	:= 1
	prices.receive.pay	:= []
	prices.receive.get	:= []
	prices.receive.highestDigitPay	:= 1
	prices.receive.highestDigitGet	:= 1

	arr := ["receive", "pay"]
	SetFormat, float, 0.6

	For arrKey, arrVal in arr {
		tmpCurrent := currencyData[arrVal].value

		For key, val in currencyData[arrVal "SparkLine"].data {
			; turn null values into 0
			val := val >= 0 ? val : 0
			tmp := tmpCurrent * (1 - val / 100)

			priceGet := tmp > 1 ? 1 : Round(1 / tmp, 2)
			pricePay := tmp > 1 ? Round(tmp, 2) : 1

			prices[arrVal].get.push(priceGet)
			prices[arrVal].pay.push(pricePay)

			testGet := StrLen(RegExReplace(priceGet,  "\..*", ""))
			testPay := StrLen(RegExReplace(pricePay,  "\..*", ""))

			prices[arrVal].highestDigitGet := testGet > prices[arrVal].highestDigitGet ? testGet : prices[arrVal].highestDigitGet
			prices[arrVal].highestDigitPay := testPay > prices[arrVal].highestDigitPay ? testPay : prices[arrVal].highestDigitPay
		}
	}

	SetFormat, float, 0.4

	Loop % prices.receive.pay.length() {
		If (A_Index = 1) {
			date := "Currently"
		} Else {
			date := A_Index > 2 ? A_Index - 1 " days ago" : A_Index - 1 " day ago"
		}

		Title .= "`n"
		Title .= StrPad(date, 11)

		buyPayPart1 := RegExReplace(prices.receive.pay[A_Index], "\..*")
		buyPayPart2 := RegExMatch(prices.receive.pay[A_Index], ".*\.") ? RegExReplace(prices.receive.pay[A_Index], ".*\.", ".") : ""
		buyGetPart1 := RegExReplace(prices.receive.get[A_Index], "\..*")
		buyGetPart2 := RegExMatch(prices.receive.get[A_Index], ".*\.") ? RegExReplace(prices.receive.get[A_Index], ".*\.", ".") : ""
		If (prices.receive.pay[A_Index] > 0) {
			Title .= StrPad("|| " StrPad(buyPayPart1, prices.receive.highestDigitPay, "left") StrPad(buyPayPart2, 2), 15)
		} Else {
			Title .= StrPad("|| no data", 15)
		}
		If (prices.receive.get[A_Index] > 0) {
			Title .= StrPad("| "  StrPad(buyGetPart1, prices.receive.highestDigitGet, "left") StrPad(buyGetPart2, 2), 13)
		} Else {
			Title .= StrPad("| no data", 13)
		}

		sellGetPart1 := RegExReplace(prices.pay.get[A_Index], "\..*")
		sellGetPart2 := RegExMatch(prices.pay.get[A_Index], ".*\.") ? RegExReplace(prices.pay.get[A_Index], ".*\.", ".") : ""
		sellPayPart1 := RegExReplace(prices.pay.pay[A_Index], "\..*")
		sellPayPart2 := RegExMatch(prices.pay.pay[A_Index], ".*\.") ? RegExReplace(prices.pay.pay[A_Index], ".*\.", ".") : ""
		If (prices.pay.pay[A_Index] > 0) {
			Title .= StrPad("|| " StrPad(sellPayPart1, prices.pay.highestDigitPay, "left") StrPad(sellPayPart2, 2), 14)
		} Else {
			Title .= StrPad("|| no data", 14)
		}
		If (prices.pay.get[A_Index] > 0) {
			Title .= StrPad("| "  StrPad(sellGetPart1, prices.pay.highestDigitGet, "left") StrPad(sellGetPart2, 2), 15)
		} Else {
			Title .= StrPad("| no data", 15)
		}
	}

	Return Title
}

; Calculate average and median price of X listings
TradeFunc_GetMeanMedianPrice(html, payload, ByRef errorMsg = "") {
	itemCount := 1
	prices := []
	average := 0
	Title := ""
	error := 0

	; loop over the first 200 results if possible, otherwise over as many as are available
	accounts := []
	NoOfItemsToCount := 200
	NoOfItemsSkipped := 0
	While A_Index <= NoOfItemsToCount {
		ItemBlock 	:= TradeUtils.HtmlParseItemData(html, "<tbody id=""item-container-" A_Index - 1 """(.*?)<\/tbody>", html)
		AccountName 	:= TradeUtils.HtmlParseItemData(ItemBlock, "data-seller=""(.*?)""")
		AccountName	:= RegexReplace(AccountName, "i)^\+", "")
		;ChaosValue 	:= TradeUtils.HtmlParseItemData(ItemBlock, "data-name=""price_in_chaos_new""(.*?)>")
		Currency	 	:= TradeUtils.HtmlParseItemData(ItemBlock, "has-tip.*currency-(.*?)""", rest)
		CurrencyV	 	:= TradeUtils.HtmlParseItemData(rest, ">(.*?)<", rest)
		RegExMatch(CurrencyV, "i)(\d+((\.|,)\d{1,2})?|\d+)", match)
		CurrencyV		:= match1

		; skip multiple results from the same account
		If (TradeOpts.RemoveMultipleListingsFromSameAccount) {
			If (TradeUtils.IsInArray(AccountName, accounts)) {
				NoOfItemsSkipped := NoOfItemsSkipped + 1
				continue
			} Else {
				accounts.Push(AccountName)
			}
		}

		If (StrLen(CurrencyV) <= 0) {
			Continue
		}  Else {
			itemCount++
		}

		CurrencyName := TradeUtils.Cleanup(Currency)
		CurrencyValue := TradeUtils.Cleanup(CurrencyV)

		; add chaos-equivalents (chaos prices) together and count results
		If (StrLen(CurrencyValue) > 0) {
			SetFormat, float, 6.2
			chaosEquivalent := 0

			mappedCurrencyName := TradeFunc_MapCurrencyPoeTradeNameToIngameName(CurrencyName)
			chaosEquivalentSingle := ChaosEquivalents[mappedCurrencyName]
			chaosEquivalent := CurrencyValue * chaosEquivalentSingle
			If (!chaosEquivalentSingle) {
				error++
			}

			StringReplace, FloatNumber, chaosEquivalent, ., `,, 1
			average += chaosEquivalent
			prices[itemCount-1] := chaosEquivalent
		}
	}

	If (error) {
		errorMsg := "Couldn't find the chaos equiv. value for " error " item(s). Please report this."
	}

	; calculate average and median prices (truncated median, too)
	If (prices.MaxIndex() > 0) {
		; average
		average := average / (itemCount)
		
		; truncated mean
		trimPercent := 20
		topTrim	:= prices.MaxIndex() - prices.MaxIndex() * (trimPercent / 100)
		bottomTrim:= prices.MaxIndex() * (trimPercent / 100)
		avg := 0
		avgCount := 0
		
		Loop, % prices.MaxIndex() {
			If (A_Index <= bottomTrim or A_Index >= topTrim) {
				continue
			}
			avg += prices[A_Index]
			avgCount++
		}
		truncMean := Round(avg / avgCount, 2)
		
		; median		
		If (prices.MaxIndex()&1) {
			; results count is odd
			index1 := Floor(prices.MaxIndex()/2)
			index2 := Ceil(prices.MaxIndex()/2)
			median := (prices[index1] + prices[index2]) / 2
			If (median > 2) {
				median := Round(median, 2)
			}
		}
		Else {
			; results count is even
			index := Floor(prices.MaxIndex()/2)
			median := prices[index]
			If (median > 2) {
				median := Round(median, 2)
			}
		}

		length := (StrLen(average) > StrLen(median)) ? StrLen(average) : StrLen(median)
		desc1 := "Average price: "
		desc2 := "Trimmed Mean (" trimPercent "%):"
		desc3 := "Median price: "
		dlength := (dlength > StrLen(desc2)) ? StrLen(desc1) : StrLen(desc2)
		dlength := (dlength > StrLen(desc3)) ? dlength : StrLen(desc3)		
		
		Title .= StrPad(desc1, dlength, "right") StrPad(average, length, "left") " chaos (" prices.MaxIndex() " results"
		Title .= (NoOfItemsSkipped > 0) ? ", " NoOfItemsSkipped " removed by Acc. Filter" : ""
		Title .= ") `n"
		
		Title .= StrPad(desc2, dlength, "right") StrPad(truncMean, length, "left") " chaos (" prices.MaxIndex() " results"
		Title .= (NoOfItemsSkipped > 0) ? ", " NoOfItemsSkipped " removed by Acc. Filter" : ""
		Title .= ") `n"

		Title .= StrPad(desc3, dlength, "right") StrPad(median, length, "left") " chaos (" prices.MaxIndex() " results"
		Title .= (NoOfItemsSkipped > 0) ? ", " NoOfItemsSkipped " removed by Acc. Filter" : ""
		Title .= ") `n`n"
	}
	
	Return Title
}

TradeFunc_MapCurrencyPoeTradeNameToIngameName(CurrencyName) {
	; map poe.trade currency names to actual ingame names
	mappedCurrencyName := ""
	For key, val in TradeCurrencyNames.eng {
		If (val = CurrencyName) {
			mappedCurrencyName := RegExReplace(key, "i)_", " ")
		}
	}

	; if mapping the exact name failed try to map it a bit less strict (example, poe.trade uses "chrome" for currencies and "chromatic" for items)
	If (!StrLen(mappedCurrencyName)) {
		For key, val in TradeCurrencyNames.eng {
			tempKey := RegExReplace(key, "i)_", " ")
			If (InStr(tempKey, CurrencyName, 0)) {
				mappedCurrencyName := tempKey
			}
		}
	}

	Return mappedCurrencyName
}

; Parse poe.trade search result html to object
TradeFunc_ParseHtmlToObj(html, payload, iLvl = "", ench = "", isItemAgeRequest = false, isAdvancedSearch = false) {
	Global Item, ItemData, TradeOpts
	LeagueName := TradeGlobals.Get("LeagueName")
	
	;median_average := TradeFunc_GetMeanMedianPrice(html, payload, error)	
	
	; Target HTML Looks like the ff:
     ; <tbody id="item-container-97" class="item" data-seller="Jobo" data-sellerid="458008"
	; data-buyout="15 chaos" data-ign="Lolipop_Slave" data-league="Essence" data-name="Tabula Rasa Simple Robe"
	; data-tab="This is a buff" data-x="10" data-y="9"> <tr class="first-line">	

	NoOfItemsToShow := TradeOpts.ShowItemResults
	results := []
	accounts := {}
	While A_Index < NoOfItemsToShow {
		result := {}
		
		ItemBlock 	:= TradeUtils.HtmlParseItemData(html, "<tbody id=""item-container-" A_Index - 1 """(.*?)<\/tbody>", html)
		AccountName 	:= TradeUtils.HtmlParseItemData(ItemBlock, "data-seller=""(.*?)""")
		AccountName	:= RegexReplace(AccountName, "i)^\+", "")
		Buyout 		:= TradeUtils.HtmlParseItemData(ItemBlock, "data-buyout=""(.*?)""")
		IGN			:= TradeUtils.HtmlParseItemData(ItemBlock, "data-ign=""(.*?)""")
		AFK			:= TradeUtils.HtmlParseItemData(ItemBlock, "class="".*?(label-afk).*?"".*?>")

		If (not AccountName) {
			continue
		}
		Else {
			itemsListed++
		}

		; skip multiple results from the same account
		If (TradeOpts.RemoveMultipleListingsFromSameAccount and not isItemAgeRequest) {
			If (accounts[AccountName]) {
				NoOfItemsToShow += 1
				accounts[AccountName] += 1
				continue
			} Else {
				accounts[AccountName] := 1
			}
		}
		result.accountName := AccountName
		result.ign := IGN
		result.afk := StrLen(AFK) ? true : false

		; get item age
		Pos := RegExMatch(ItemBlock, "i)class=""found-time-ago"">(.*?)<", Age)
		result.age := Age1
		
		Pos := RegExMatch(ItemBlock, "i)data-name=""ilvl"">.*: ?(\d+?)<", iLvl, Pos)
		result.itemLevel := iLvl1
		
		If (Item.IsGem) {
			; get gem quality, level and xp
			RegExMatch(ItemBlock, "i)data-name=""progress"".*<b>\s?(\d+)\/(\d+)\s?<\/b>", GemXP_Flat)
			RegExMatch(ItemBlock, "i)data-name=""progress"">\s*?Experience:.*?([0-9.]+)\s?%", GemXP_Percent)
			Pos := RegExMatch(ItemBlock, "i)data-name=""q"".*?data-value=""(.*?)""", Q, Pos)
			Pos := RegExMatch(ItemBlock, "i)data-name=""level"".*?data-value=""(.*?)""", LVL, Pos)
			
			result.gemData := {}
			result.gemData.xpFlat := GemXP_Flat1
			result.gemData.xpPercent := GemXP_Percent1
			result.gemData.quality := Q1
			result.gemData.level := LVL1
		}

		; buyout price
		RegExMatch(Buyout, "i)([-.0-9]+) (.*)", BuyoutText)
		RegExMatch(BuyoutText1, "i)(\d+)(.\d+)?", BuyoutPrice)
		
		If (TradeOpts.ShowPricesAsChaosEquiv and not TradeOpts.ExactCurrencySearch) {
			; translate buyout to chaos equivalent
			RegExMatch(Buyout, "i)\d+(\.|,?\d+)?(.*)", match)
			CurrencyName := TradeUtils.Cleanup(match2)

			mappedCurrencyName		:= TradeFunc_MapCurrencyPoeTradeNameToIngameName(CurrencyName)
			chaosEquivalentSingle	:= ChaosEquivalents[mappedCurrencyName]
			chaosEquivalent		:= BuyoutPrice * chaosEquivalentSingle
			RegExMatch(chaosEquivalent, "i)(\d+)(.\d+)?", BuyoutPrice)

			If (chaosEquivalentSingle) {
				BuyoutPrice    := (BuyoutPrice2) ? BuyoutPrice1 . BuyoutPrice2 : BuyoutPrice1
				BuyoutCurrency := "chaos"
			}
		}
		Else {
			BuyoutPrice    := (BuyoutPrice2) ? BuyoutPrice1 . BuyoutPrice2 : BuyoutPrice1
			BuyoutCurrency := BuyoutText2
		}
		
		result.buyoutPrice := BuyoutPrice
		result.buyoutCurrency := BuyoutCurrency	

		results.push(result)
	}
	
	data := {}
	data.results := results
	data.accounts := accounts

	Return data
}


; Parse poe.trade html to display the search result tooltip with X listings
TradeFunc_ParseHtml(html, payload, iLvl = "", ench = "", isItemAgeRequest = false, isAdvancedSearch = false) {
	Global Item, ItemData, TradeOpts	
	
	httpError := TradeFunc_ParseRequestErrors(html)
	If (httpError) {
		Return httpError
	}

	LeagueName := TradeGlobals.Get("LeagueName")

	seperatorBig := "`n-----------------------------------------------------------------------`n"

	; Target HTML Looks like the ff:
     ; <tbody id="item-container-97" class="item" data-seller="Jobo" data-sellerid="458008"
	; data-buyout="15 chaos" data-ign="Lolipop_Slave" data-league="Essence" data-name="Tabula Rasa Simple Robe"
	; data-tab="This is a buff" data-x="10" data-y="9"> <tr class="first-line">
	If (not Item.IsGem and not Item.IsDivinationCard and not Item.IsJewel and not Item.IsCurrency and not Item.IsMap) {
		showItemLevel := true
	}

	Name := (Item.IsRare and not Item.IsMap) ? Item.Name " " Item.BaseName : Item.Name
	Title := Trim(StrReplace(Name, "Superior", ""))

	; catalysed quality for jewelry 
	If (Item.IsRing or Item.IsAmulet) {
		Title .= Item.UsedInSearch.Quality ? " (" Item.UsedInSearch.Quality "% Q) " : ""
	}	
	
	If (Item.IsMap && !Item.isUnique) {
		; map fix (wrong Item.name on magic/rare maps)
		Title :=
		newName := Trim(StrReplace(Item.Name, "Superior", ""))
		; prevent duplicate name on white and magic maps
		If (newName != Item.SubType) {
			s := Trim(RegExReplace(Item.Name, "Superior", ""))
			s := Trim(StrReplace(s, Item.SubType, ""))
			Title .= "(" RegExReplace(s, " +", " ") ") "
		}
		Title .= Trim(StrReplace(Item.SubType, "Superior", ""))
	}

	; add corrupted tag
	If (Item.IsCorrupted) {
		Title .= " [Corrupted] "
	}

	; add gem quality and level
	If (Item.IsGem) {
		Title := Item.Name ", Q" Item.Quality "%"
		If (Item.Level >= 16) {
			Title := Item.Name ", " Item.Level "`/" Item.Quality "%"
		}
	}
	; add item sockets and links
	If (ItemData.Sockets >= 5) {
		Title := Name " " ItemData.Sockets "s" ItemData.Links "l"
	}
	If (showItemLevel) {
		Title .= ", iLvl: " iLvl
	}

	Title .= ", (" LeagueName ")"
	Title .= seperatorBig

	; add notes what parameters where used in the search
	ShowFullNameNote := false
	If (not Item.IsUnique and not Item.IsGem and not Item.IsDivinationCard) {
		ShowFullNameNote := true
	}

	If (Item.UsedInSearch) {
		If (isItemAgeRequest) {
			Title .= Item.UsedInSearch.SearchType
		}
		Else {
			Title .= "Used in " . Item.UsedInSearch.SearchType . " Search: "
			Title .= (Item.UsedInSearch.Enchantment)  ? "Enchantment " : ""
			Title .= (Item.UsedInSearch.CorruptedMod) ? "Corr. Implicit " : ""
			Title .= (Item.UsedInSearch.Sockets)      ? "| " . Item.UsedInSearch.Sockets . "S " : ""
			Title .= (Item.UsedInSearch.AbyssalSockets) ? "| " . Item.UsedInSearch.AbyssalSockets . " Abyss Sockets " : ""
			Title .= (Item.UsedInSearch.Links)        ? "| " . Item.UsedInSearch.Links   . "L " : ""
			If (Item.UsedInSearch.iLvl.min and Item.UsedInSearch.iLvl.max) {
				Title .= "| iLvl (" . Item.UsedInSearch.iLvl.min . "-" . Item.UsedInSearch.iLvl.max . ")"
			}
			Else {
				Title .= (Item.UsedInSearch.iLvl.min) ? "| iLvl (>=" . Item.UsedInSearch.iLvl.min . ") " : ""
				Title .= (Item.UsedInSearch.iLvl.max) ? "| iLvl (<=" . Item.UsedInSearch.iLvl.max . ") " : ""
			}

			Title .= (Item.UsedInSearch.FullName and ShowFullNameNote) ? "| Full Name " : ""
			Title .= (Item.UsedInSearch.BeastBase and ShowFullNameNote) ? "| Beast Base " : ""
			Title .= (Item.UsedInSearch.Rarity) ? "(" Item.UsedInSearch.Rarity ") " : ""
			Title .= (Item.UsedInSearch.Corruption and not Item.IsMapFragment and not Item.IsDivinationCard and not Item.IsCurrency)   ? "| Corrupted (" . Item.UsedInSearch.Corruption . ") " : ""
			Title .= (Item.UsedInSearch.ItemXP) ?  "| XP (>= 70%) " : ""
			Title .= (Item.UsedInSearch.Type) ? "| Type (" . Item.UsedInSearch.Type . ") " : ""			
			Title .= (Item.UsedInSearch.abyssJewel) ? "| Abyss Jewel " : ""
			Title .= (Item.UsedInSearch.ItemBase and ShowFullNameNote) ? "| Base (" . Item.UsedInSearch.ItemBase . ") " : ""
			Title .= (Item.UsedInSearch.specialBase) ? "| " . Item.UsedInSearch.specialBase . " Base " : ""
			Title .= (Item.UsedInSearch.Charges) ? "`n" . Item.UsedInSearch.Charges . " " : ""
			Title .= (Item.UsedInSearch.AreaMonsterLvl) ? "| " . Item.UsedInSearch.AreaMonsterLvl . " " : ""
			
			If (Item.UsedInSearch.veiledPrefix or Item.UsedInSearch.veiledSuffix) {
				Title .= "`n"
				Title .= (Item.UsedInSearch.veiledPrefix) ? "Veiled Prefixes: " Item.UsedInSearch.Charges . " | " : ""	
				Title .= (Item.UsedInSearch.veiledSuffix) ? "Veiled Suffixes: " Item.UsedInSearch.Charges . " | " : ""	
			}
			
			If (Item.IsBeast and not Item.IsUnique) {
				Title .= (Item.UsedInSearch.SearchType = "Default") ? "`n" . "!! Added special bestiary mods to the search !!" : ""	
			} Else {
				Title .= (Item.UsedInSearch.SearchType = "Default") ? "`n" . "!! Mod rolls are being ignored !!" : ""
				If (Item.UsedInSearch.ExactCurrency) {
					Title .= "`n" . "!! Using exact currency option !!"
				}
			}
		}
		Title .= seperatorBig
	}

	; add average and median prices to title
	If (not isItemAgeRequest) {
		Title .= TradeFunc_GetMeanMedianPrice(html, payload, error)
		If (StrLen(error)) {
			Title .= error "`n`n"
		}
	} Else {
		Title .= "`n"
	}

	; add poe.ninja chaos equivalents
	totalChangeSign := (Item.priceHistory.totalChange > 0) ? "+" : ""	
	If (Item.IsMap) {
		Title .= "poe.ninja price history: " Round(Item.priceHistory.chaosValue, 2) " chaos."		
		Title .= " Change: " totalChangeSign "" Round(Item.priceHistory.totalChange, 0) "% (last 7 days).`n`n"
	} 
	Else If (Item.IsFossil) {
		If (Item.priceHistory.exaltedValue >= 1) {
			Title .= "poe.ninja price history: " Round(Item.priceHistory.exaltedValue, 2) " exalted."
		} Else {
			Title .= "poe.ninja price history: " Round(Item.priceHistory.chaosValue, 2) " chaos."	
		}		
		Title .= " Change: " totalChangeSign "" Round(Item.priceHistory.totalChange, 0) "% (last 7 days).`n`n"
	}

	NoOfItemsToShow := TradeOpts.ShowItemResults
	; add table headers to tooltip
	Title .= TradeFunc_ShowAcc(StrPad("Account",12), "|")
	Title .= StrPad("IGN",20)
	Title .= StrPad(StrPad("| Price ", 19, "right") . "|",20,"left")

	If (Item.IsGem) {
		; add gem headers
		Title .= StrPad("Q. |",6,"left")
		Title .= StrPad("Lvl |",6,"left")
		Title .= StrPad("Xp |",6,"left")
	}
	If (showItemLevel) {
		; add ilvl
		Title .= StrPad("iLvl |",7,"left")
	}
	Title .= StrPad("   Age",8)
	Title .= "`n"

	; add table head underline
	Title .= TradeFunc_ShowAcc(StrPad("------------",12), "-")
	Title .= StrPad("--------------------",20)
	Title .= StrPad("--------------------",19,"left")
	If (Item.IsGem) {
		Title .= StrPad("------",6,"left")
		Title .= StrPad("------",6,"left")
		Title .= StrPad("------",6,"left")
	}
	If (showItemLevel) {
		Title .= StrPad("-------",8,"left")
	}
	Title .= StrPad("----------",8,"left")
	Title .= "`n"

	; add search results to tooltip in table format
	accounts := []
	itemsListed := 0
	While A_Index < NoOfItemsToShow {
		ItemBlock 	:= TradeUtils.HtmlParseItemData(html, "<tbody id=""item-container-" A_Index - 1 """(.*?)<\/tbody>", html)
		AccountName 	:= TradeUtils.HtmlParseItemData(ItemBlock, "data-seller=""(.*?)""")
		AccountName	:= RegexReplace(AccountName, "i)^\+", "")
		Buyout 		:= TradeUtils.HtmlParseItemData(ItemBlock, "data-buyout=""(.*?)""")
		IGN			:= TradeUtils.HtmlParseItemData(ItemBlock, "data-ign=""(.*?)""")

		If (not AccountName) {
			continue
		}
		Else {
			itemsListed++
		}

		; skip multiple results from the same account
		If (TradeOpts.RemoveMultipleListingsFromSameAccount and not isItemAgeRequest) {
			If (TradeUtils.IsInArray(AccountName, accounts)) {
				NoOfItemsToShow := NoOfItemsToShow + 1
				continue
			} Else {
				accounts.Push(AccountName)
			}
		}

		; get item age
		Pos := RegExMatch(ItemBlock, "i)class=""found-time-ago"">(.*?)<", Age)

		If (showItemLevel) {
			; get item level
			Pos := RegExMatch(ItemBlock, "i)data-name=""ilvl"">.*: ?(\d+?)<", iLvl, Pos)
		}
		If (Item.IsGem) {
			; get gem quality, level and xp
			RegExMatch(ItemBlock, "i)data-name=""progress"".*<b>\s?(\d+)\/(\d+)\s?<\/b>", GemXP_Flat)
			RegExMatch(ItemBlock, "i)data-name=""progress"">\s*?Experience:.*?([0-9.]+)\s?%", GemXP_Percent)
			Pos := RegExMatch(ItemBlock, "i)data-name=""q"".*?data-value=""(.*?)""", Q, Pos)
			Pos := RegExMatch(ItemBlock, "i)data-name=""level"".*?data-value=""(.*?)""", LVL, Pos)
		}

		; trim account and ign
		subAcc := TradeFunc_TrimNames(AccountName, 12, true)
		subIGN := TradeFunc_TrimNames(IGN, 20, true)

		Title .= TradeFunc_ShowAcc(StrPad(subAcc,12), "|")
		Title .= StrPad(subIGN,20)

		; buyout price
		RegExMatch(Buyout, "i)([-.0-9]+) (.*)", BuyoutText)
		RegExMatch(BuyoutText1, "i)(\d+)(.\d+)?", BuyoutPrice)

		If (TradeOpts.ShowPricesAsChaosEquiv) {
			; translate buyout to chaos equivalent
			RegExMatch(Buyout, "i)\d+(\.|,?\d+)?(.*)", match)
			CurrencyName := TradeUtils.Cleanup(match2)

			mappedCurrencyName		:= TradeFunc_MapCurrencyPoeTradeNameToIngameName(CurrencyName)
			chaosEquivalentSingle	:= ChaosEquivalents[mappedCurrencyName]
			chaosEquivalent		:= BuyoutPrice * chaosEquivalentSingle
			RegExMatch(chaosEquivalent, "i)(\d+)(.\d+)?", BuyoutPrice)

			If (chaosEquivalentSingle) {
				BuyoutPrice    := (BuyoutPrice2) ? StrPad(BuyoutPrice1 BuyoutPrice2, (3 - StrLen(BuyoutPrice1), "left")) : StrPad(StrPad(BuyoutPrice1, 2 + StrLen(BuyoutPrice1), "right"), 3 - StrLen(BuyoutPrice1), "left")
				BuyoutCurrency := "chaos"
			}
		}
		Else {
			BuyoutPrice    := (BuyoutPrice2) ? StrPad(BuyoutPrice1 BuyoutPrice2, (3 - StrLen(BuyoutPrice1), "left")) : StrPad(StrPad(BuyoutPrice1, 2 + StrLen(BuyoutPrice1), "right"), 3 - StrLen(BuyoutPrice1), "left")
			BuyoutCurrency := BuyoutText2
		}
		BuyoutText := StrPad(BuyoutPrice, 5, "left") . " " BuyoutCurrency
		Title .= StrPad("| " . BuyoutText . "",19,"right")

		If (Item.IsGem) {
			; add gem info
			If (Q1 > 0) {
				Title .= StrPad("| " . StrPad(Q1,2,"left") . "% ",6,"right")
			} Else {
				Title .= StrPad("|  -  ",6,"right")
			}
			Title .= StrPad("| " . StrPad(LVL1,3,"left") . " " ,6,"right")
			
			If (GemXP_Percent1) {
				Title .= StrPad("| " . StrPad(GemXP_Percent1,2,"left") . "% ",6,"right")
			} Else {
				Title .= StrPad("|  -  ",6,"right")
			}
		}
		If (showItemLevel) {
			; add item level
			Title .= StrPad("| " . StrPad(iLvl1,3,"left") . "  |" ,8,"right")
		}
		Else {
			Title .= "|"
		}
		; add item age
		Title .= StrPad(TradeFunc_FormatItemAge(Age1),10)
		Title .= "`n"
	}
	Title .= (itemsListed > 0) ? "" : "`nNo item found.`n"
	Title .= (isAdvancedSearch) ? "" : "`n`n" "Use Shift + Alt + D (default) instead for a more thorough search."

	Return, Title
}

TradeFunc_ParsePoePricesInfoData(response) {
	Global Item, ItemData, TradeOpts
	
	LeagueName := TradeGlobals.Get("LeagueName")

	Name := (Item.IsRare and not Item.IsMap) ? Item.Name " " Item.BaseName : Item.Name
	headLine := Trim(StrReplace(Name, "Superior", ""))
	; add corrupted tag
	If (Item.IsCorrupted) {
		headLine .= " [Corrupted] "
	}

	; add gem quality and level
	If (Item.IsGem) {
		headLine := Item.Name ", Q" Item.Quality "%"
		If (Item.Level >= 16) {
			headLine := Item.Name ", " Item.Level "`/" Item.Quality "%"
		}
	}
	; add item sockets and links
	If (ItemData.Sockets >= 5) {
		headLine := Name " " ItemData.Sockets "s" ItemData.Links "l"
	}
	If (showItemLevel) {
		headLine .= ", iLvl: " iLvl
	}
	headLine .= ", (" LeagueName ")"

	lines := []
	lines.push(["~~ Predicted item pricing (via machine-learning) ~~", "center", true])
	lines.push([headLine, "left",  true])
	lines.push(["", "left"])
	lines.push(["   Price range: " Round(Trim(response.min), 2) " ~ " Round(Trim(response.max), 2) " " Trim(response.currency), "left"])
	lines.push(["", "left", true])
	lines.push(["", "left"])
	
	_details := TradeFunc_PreparePredictedPricingContributionDetails(response.pred_explanation, 40)
	lines.push(["Contribution to predicted price:", "left"])
	For _k, _v in _details {
		_line := _v.percentage " -> " _v.name 
		lines.push(["  " _line, "left"])
	}
	lines.push(["", "left"])
	
	lines.push(["Please consider supporting POEPRICES.INFO.", "left"])
	lines.push(["Financially or via feedback on this feature on their website.", "left"])
	
	maxWidth := 0
	For i, line in lines {
		maxWidth := StrLen(line[1]) > maxWidth ? StrLen(line[1]) : maxWidth
	}

	Title := ""
	For i, line in lines {
		If (RegExMatch(line[2], "i)center")) {
			diff := maxWidth - StrLen(line[1])			
			line[1] := StrPad(line[1], maxWidth - Floor(diff / 2), "left")
		}
		If (RegExMatch(line[2], "i)right")) {
			line[1] := StrPad(line[1], maxWidth, "left")
		}
		
		Title .= line[1] "`n"
		If (line[3]) {
			seperator := ""
			Loop, % maxWidth {
				seperator .= "-"
			}
			Title .= seperator "`n"
		}
	}
	
	Return Title
}

; Trim names/string and add dots at the end If they are longer than specified length
TradeFunc_TrimNames(name, length, addDots) {
	s := SubStr(name, 1 , length)
	If (StrLen(name) > length + 3 && addDots) {
		StringTrimRight, s, s, 3
		s .= "..."
	}
	Return s
}

; Add sellers accountname to string If that option is selected
TradeFunc_ShowAcc(s, addString) {
	If (TradeOpts.ShowAccountName = 1) {
		s .= addString
		Return s
	}
}

; format item age to be shorter
TradeFunc_FormatItemAge(age) {
	age := RegExReplace(age, "^a", "1")
	RegExMatch(age, "\d+", value)
	RegExMatch(age, "i)month|week|yesterday|hour|minute|second|day", unit)

	If (unit = "month") {
		unit := " mo"
	} Else If (unit = "week") {
		unit := " week"
	} Else If (unit = "day") {
		unit := " day"
	} Else If (unit = "yesterday") {
		unit := " day"
		value := "1"
	} Else If (unit = "hour") {
		unit := " h"
	} Else If (unit = "minute") {
		unit := " min"
	} Else If (unit = "second") {
		unit := " sec"
	}

	s := " " StrPad(value, 3, left) unit

	Return s
}

class RequestParams_ {
	; these are special cases, for example by default, the string key "base" is used to retrieve or set the object's base object, so cannot be used for storing ordinary values with a normal assignment.
	xtype		:= ""
	xbase		:= ""
	xthread 		:= ""
	;

	league		:= ""
	name			:= ""
	dmg_min 		:= ""
	dmg_max 		:= ""
	aps_min 		:= ""
	aps_max 		:= ""
	crit_min 		:= ""
	crit_max 		:= ""
	dps_min 		:= ""
	dps_max		:= ""
	edps_min		:= ""
	edps_max		:= ""
	pdps_min 		:= ""
	pdps_max 		:= ""
	armour_min	:= ""
	armour_max	:= ""
	evasion_min	:= ""
	evasion_max 	:= ""
	shield_min 	:= ""
	shield_max 	:= ""
	block_min		:= ""
	block_max 	:= ""
	sockets_min 	:= ""
	sockets_max 	:= ""
	link_min 		:= ""
	link_max 		:= ""
	sockets_r 	:= ""
	sockets_g 	:= ""
	sockets_b 	:= ""
	sockets_w 	:= ""
	linked_r 		:= ""
	linked_g 		:= ""
	linked_b 		:= ""
	linked_w 		:= ""
	rlevel_min 	:= ""
	rlevel_max 	:= ""
	rstr_min 		:= ""
	rstr_max 		:= ""
	rdex_min 		:= ""
	rdex_max 		:= ""
	rint_min 		:= ""
	rint_max 		:= ""
	modGroups		:= [new _ParamModGroup()]
	q_min 		:= ""
	q_max 		:= ""
	level_min 	:= ""
	level_max 	:= ""
	ilvl_min 		:= ""
	ilvl_max		:= ""
	rarity 		:= ""
	seller 		:= ""
	identified 	:= ""
	corrupted		:= "0"
	online 		:= (TradeOpts.OnlineOnly == 0) ? "" : "x"
	has_buyout 	:= ""
	altart 		:= ""
	capquality 	:= "x"
	buyout_min 	:= ""
	buyout_max 	:= ""
	buyout_currency:= ""
	exact_currency	:= (TradeOpts.ExactCurrencySearch == 0) ? "" : "x"
	crafted		:= ""
	enchanted 	:= ""
	progress_min	:= ""
	progress_max	:= ""
	sockets_a_min	:= ""
	sockets_a_max	:= ""
	shaper		:= ""
	elder		:= ""
	hunter		:= ""	; check todo
	crusader		:= ""	; check
	redeemer		:= ""	; check
	warlord		:= ""	; check
	synthesised	:= ""
	fractured		:= ""
	map_series 	:= ""
	veiled		:= ""

	ToPayload() {
		modGroupStr := ""
		Loop, % this.modGroups.MaxIndex() {
			modGroupStr .= this.modGroups[A_Index].ToPayload()
		}

		p :=
		For key, val in this {
			; check if not array (modGroups for example are arrays)
			If (!this[key].MaxIndex()) {
				If (StrLen(val)) {
					; remove prefixed x for special keys
					argument := RegExReplace(key, "i)(x(base|thread|type))?(.*)", "$2$3")
					p .= "&" argument "=" TradeUtils.UriEncode(val)
				}
			}
		}
		p .= modGroupStr
		p := RegExReplace(p, "^&", "")

		Return p
	}

	AddModGroup(type, count, min = "", max = "") {
		this.modGroups.push(new _ParamModGroup())
		this.modGroups[this.modGroups.MaxIndex()].SetGroupOptions(type, count, min, max)
	}
}

CleanPayload(payload) {
	StringSplit, parameters, payload, `&
	params 	:= []
	i 		:= 1
	While (parameters%i%) {
		RegExMatch(parameters%i%, "=$", match)
		If (!match) {
			params.push(parameters%i%)
		}
		i++
	}

	payload := ""
	For key, val in params {
		payload .= val "&"
	}
	return payload
}

class _ParamModGroup {
	ModArray		:= []
	group_type	:= "And"
	group_min		:= ""
	group_max		:= ""
	group_count	:= 1

	ToPayload() {
		p := ""

		If (this.ModArray.Length() = 0) {
			this.AddMod(new _ParamMod())
		}
		this.group_count := this.ModArray.Length()
		Loop % this.ModArray.Length() {
			p .= this.ModArray[A_Index].ToPayload()
		}
		p .= "&group_type="  TradeUtils.UriEncode(this.group_type)
		p .= "&group_min="   TradeUtils.UriEncode(this.group_min)
		p .= "&group_max="   TradeUtils.UriEncode(this.group_max)
		p .= "&group_count=" TradeUtils.UriEncode(this.group_count)

		;p .= "&group_type=" this.group_type "&group_min=" this.group_min "&group_max=" this.group_max "&group_count=" this.group_count

		Return p
	}

	AddMod(paraModObj) {
		this.ModArray.Push(paraModObj)
	}

	SetGroupOptions(type, count, min = "", max = "") {
		this.group_type	:= type
		this.group_count	:= count
		this.group_min		:= min
		this.group_max		:= max
	}
	SetGroupType(type) {
		this.group_type := type
	}
	SetGroupMinMax(min = "", max = "") {
		this.group_min := min
		this.group_max := max
	}
	SetGroupCount(count) {
		this.group_count := count
	}
}

class _ParamMod {
	mod_name	:= ""
	mod_min	:= ""
	mod_max	:= ""
	mod_weight := ""
	
	ToPayload()
	{
		If (StrLen(this.mod_name)) {
			p .= "&mod_name=" TradeUtils.UriEncode(this.mod_name)
			p .= "&mod_min="  TradeUtils.UriEncode(this.mod_min) "&mod_max=" TradeUtils.UriEncode(this.mod_max)
			p .= "&mod_weight=" TradeUtils.UriEncode(this.mod_weight)
		}

		Return p
	}
}

TradeFunc_FindModInRequestParams(RequestParams, name) {
	For gkey, gval in RequestParams.modGroups {
		For mkey, mval in gval.ModArray {
			If (mval.mod_name == name) {
				Return true
			}
		}
	}
	Return False
}

; Return unique item with its variable mods and mod ranges if it has any
TradeFunc_FindUniqueItemIfItHasVariableRolls(name, isRelic = false) {
	data := isRelic ? TradeGlobals.Get("VariableRelicData") : TradeGlobals.Get("VariableUniqueData")
	For index, uitem in data {
		If (uitem.name = name) {
			Loop % uitem.mods.Length() {				
				If (uitem.mods[A_Index].isVariable) {
					uitem.IsUnique := true
					Return uitem
				}
			}
			If (uitem.hasVariant) {
				uitem.IsUnique := true
				Return uitem
			}
		}
	}
	Return 0
}

TradeFunc_RemoveAlternativeVersionsMods(_item, Affixes) {
	Affixes	:= StrSplit(Affixes, "`n")
	i 		:= 0
	tempMods	:= []
	tempMods2 := []
	
	For k, v in _item.mods {
		negativeToPositiveRange := false
		; Mod can be 0 or negative since the range goes from negative to positive, example: ventors gamble.
		; This means the mod can be missing from the item or change it's description from "increased" to reduced.
		If (v.ranges[1][1] < 0 and v.ranges[1][2] > 0) {
			negativeToPositiveRange := true
		}		
		
		modFound := false 
		negativeValue := false
		spawnType := ""
		For key, val in Affixes {
			RegExMatch(Trim(val), "i)\((fractured|crafted)\)", sType)
			val := RegExReplace(Trim(val), "i)\((fractured|crafted)\)")

			; remove negative sign also			
			t := TradeUtils.CleanUp(RegExReplace(val, "i)-?[\d\.]+", "#"))
			
			n := TradeUtils.CleanUp(RegExReplace(v.name_orig, "i)-?[\d\.]+|-?\(.+?\)", "#"))
			n := TradeUtils.CleanUp(n)
			
			; match with optional positive sign to match for example "-7% to cold resist" with "+#% to cold resist"
			If (not negativeToPositiveRange) {
				RegExMatch(n, "i)^(\+?" . t . ")$", match)	
			} Else {
				t2 := RegExReplace(t, "i)(reduced)", "(increased)")
				RegExMatch(n, "i)^(\+?" . t2 . ")$", match)
			}			

			If (match) {
				negativeValue := RegExMatch(t, "i)#%? reduced")				
				spawnType := sType1	
				modFound := true
			}
		}

		If (modFound) {
			; Rewrite some values because poe.trade doesn't support "increased" mods with negative parameters.
			; The solution is to use "reduced" instead, which requires changing the range values.
			If (negativeToPositiveRange and negativeValue) {
				v.name := RegExReplace(v.name, "i)(.*#%?) increased", "$1 reduced")
				v.name_orig := RegExReplace(v.name_orig, "i)(.*-?[\d\.]+|-?\(.+?\))(%?) increased", "$1$2$3 reduced")
				v.param := RegExReplace(v.param, "i)(.*#%?) increased", "$1 reduced")
				
				v.ranges[1][2] := Abs(v.ranges[1][1])
				v.ranges[1][1] := (v.ranges[1][2] > 2) ? 1 : 0.1
			}
			v.IsUnknown := false
			v.spawnType := spawnType
			tempMods.push(v)
			tempMods2.push(v)
		}
	}

	For key, val in Affixes {
		val := RegExReplace(Trim(val), "i)\((fractured|crafted)\)")
		
		t := TradeUtils.CleanUp(RegExReplace(val, "i)-?[\d\.]+", "#"))		
		modFound := false
		
		For k, v in tempMods {
			n := TradeUtils.CleanUp(RegExReplace(v.name_orig, "i)-?[\d\.]+|-?\(.+?\)", "#"))
			n := TradeUtils.CleanUp(n)

			If (RegExMatch(n, "i)^(\+?" . t . ")$", match)) {
				modFound := true
			}
		}
		If (not modFound) {
			m := {}
			m.name := t
			m.name_orig := t 
			m.param := t
			m.ranges := []
			m.IsUnknown := true
			tempMods2.push(m)
		}
	}		

	_item.mods := tempMods2
	return _item
}

; Return an items mods and ranges
TradeFunc_PrepareNonUniqueItemMods(Affixes, Implicit, Rarity, Enchantment = false, Corruption = false, isMap = false, isBeast = false, isSynthesisedBase = false) {
	Affixes	:= StrSplit(Affixes, "`n")
	mods		:= []
	i		:= 0

	If (Implicit.maxIndex() and not Enchantment.Length() and not Corruption.Length()) {
		modStrings := Implicit
		For i, modString in modStrings {			
			tempMods := ModStringToObject(modString, true)
			For i, tempMod in tempMods {
				mods.push(tempMod)
			}
		}
	}

	For key, val in Affixes {
		If (!val or RegExMatch(val, "i)---")) {
			continue
		}
		If (i >= 1 and (Enchantment.Length() or Corruption.Length())) {
			continue
		}
		If (i <= 1 and Implicit and Rarity = 1) {
			continue
		}

		temp := ModStringToObject(val, false)
		;combine mods if they have the same name and add their values
		For tempkey, tempmod in temp {
			found := false

			For key, mod in mods {			
				If (tempmod.name = mod.name) {
					; skip merging of implicit + explicit for synthesised items					
					If (((mod.type = "implicit" and tempmod.type = "explicit") or (mod.type = "explicit" and tempmod.type = "implicit")) and isSynthesisedBase) {
						found := false
					} Else {					
						Index := 1
						Loop % mod.values.MaxIndex() {
							mod.values[Index] := mod.values[Index] + tempmod.values[Index]
							Index++
						}

						tempStr  := RegExReplace(mod.name_orig, "i)([.0-9]+)", "#")

						Pos		:= 1
						tempArr	:= []
						While Pos := RegExMatch(tempmod.name_orig, "i)([.0-9]+)", value, Pos + (StrLen(value) ? StrLen(value) : 0)) {
							tempArr.push(value)
						}

						Pos		:= 1
						Index	:= 1
						While Pos := RegExMatch(mod.name_orig, "i)([.0-9]+)", value, Pos + (StrLen(value) ? StrLen(value) : 0)) {
							tempStr := StrReplace(tempStr, "#", value + tempArr[Index],, 1)
							Index++
						}
						mod.name_orig := tempStr
						found := true
					}
				}
			}
			If (tempmod.name and !found) {
				mods.push(tempmod)
			}
		}
	}

	; adding the values (value array) fails in the above loop, so far I have no idea why,
	; as a workaround we take the values from the mod description (where it works and use them)
	For key, mod in mods {
		mod.values := []
		Pos		:= 1
		Index	:= 1
		While Pos := RegExMatch(mod.name_orig, "i)([.0-9]+)", value, Pos + (StrLen(value) ? StrLen(value) : 0)) {
			mod.values.push(value)
			Index++
		}
	}

	mods := CreatePseudoMods(mods, True)

	tempItem		:= {}
	tempItem.mods	:= []
	tempItem.mods	:= mods
	tempItem.isBeast := isBeast
	tempItem.isSynthesisedBase := isSynthesisedBase
	temp			:= TradeFunc_GetItemsPoeTradeMods(tempItem, isMap)
	tempItem.mods	:= temp.mods
	tempItem.IsUnique := false

	Return tempItem
}

TradeFunc_CheckIfTempModExists(needle, mods) {
	For key, val in mods {
		If (RegExMatch(val.name, "i)" needle "")) {
			Return true
		}
	}
	Return false
}

; Add poe.trades mod names to the items mods to use as POST parameter
TradeFunc_GetItemsPoeTradeMods(_item, isMap = false) {
	mods := TradeGlobals.Get("ModsData")

	; use this to control search order (which group is more important)
	For k, imod in _item.mods {		
		If (_item.isBeast) {			
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["bestiary"], _item.mods[k])
			}		
		}
		Else {
			; always search implicits first when mod is implicit and item is a synthesised base
			If (_item.isSynthesisedBase and _item.mods[k].type = "implicit" and not isMap) {
				If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
					_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["implicit"], _item.mods[k])
				}
			}
			; check total and then implicits first if mod is implicit, otherwise check later
			If (StrLen(_item.mods[k]["param"]) < 1 and _item.mods[k].type = "implicit" and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["[total] mods"], _item.mods[k])
				If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
					_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["implicit"], _item.mods[k])
				}
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["[total] mods"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["[pseudo] mods"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["explicit"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["shaped"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["elder"], _item.mods[k])
			}
			/*
				todo check / validate
				*/
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["hunter"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["crusader"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["redeemer"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["warlord"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["influence"], _item.mods[k])
			}
			/*
				*/
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["abyss jewels"], _item.mods[k])
			}			
			
			
			; check crafted before unique explicit and synthesised if spawntype is crafted, otherwise check afte	
			If (StrLen(_item.mods[k]["param"]) < 1 and _item.mods[k].spawnType = "crafted") {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["crafted"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["unique explicit"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["synthesised"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["crafted"], _item.mods[k])
			}
			
			
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["implicit"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["enchantments"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["map mods"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["prophecies"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["leaguestone"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["fractured"], _item.mods[k])
			}
			If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
				_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["synthesised"], _item.mods[k])
			}
			
			; Handle special mods like "Has # Abyssal Sockets" which technically has no rolls but different mod variants.
			; It's also not available on poe.trade as a mod but as a seperate form option.
			If (RegExMatch(_item.mods[k].name, "i)Has # Abyssal (Socket|Sockets)")) {
				_item.mods[k].showModAsSeperateOption := true
			}
		}
	}

	Return _item
}

; Add poe.trades mod names to the items mods to use as POST parameter
TradeFunc_GetItemsPoeTradeUniqueMods(_item) {
	mods := TradeGlobals.Get("ModsData")
	For k, imod in _item.mods {
		_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["unique explicit"], _item.mods[k])
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["explicit"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["[total] mods"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["[pseudo] mods"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1 and not isMap) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["abyss jewels"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["map mods"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["leaguestone"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["fractured"], _item.mods[k])
		}
		If (StrLen(_item.mods[k]["param"]) < 1) {
			_item.mods[k]["param"] := TradeFunc_FindInModGroup(mods["synthesised"], _item.mods[k])
		}
		
		; Handle special mods like "Has # Abyssal Sockets" which technically has no rolls but different mod variants.
		; It's also not available on poe.trade as a mod but as a seperate form option.		
		If (RegExMatch(_item.mods[k].name, "i)Has # Abyssal (Socket|Sockets)")) {
			_item.mods[k].showModAsSeperateOption := true
		}
	}

	Return _item
}

; find mod in modgroup and return its name
TradeFunc_FindInModGroup(modgroup, needle, simpleRange = true, recurse = true) {
	matches := []
	editedNeedle := ""

	For j, mod in modgroup {
		s  := Trim(RegExReplace(mod, "i)\(pseudo\)|\(total\)|\(crafted\)|\(implicit\)|\(explicit\)|\(enchant\)|\(prophecy\)|\(leaguestone\)|\(beastiary\)|\(fractured\)|\(synthesised\)", ""))
		If (simpleRange) {
			s  := RegExReplace(s, "# ?to ? #", "#")
		}
		
		s  := TradeUtils.CleanUp(s)
		ss := TradeUtils.CleanUp(needle.name)
		st := TradeUtils.CleanUp(needle.name_orig)
		
		If (simpleRange) {
			; matches "1 to" in for example "adds 1 to (20-40) lightning damage"
			ss := RegExReplace(ss, "\d+ ?to ?#", "#")
		}		
		;ss := RegExReplace(ss, "Monsters' skills Chain # additional times", "Monsters' skills Chain 2 additional times")
		;ss := RegExReplace(ss, "Has # socket", "Has 1 socket")
		editedNeedle := ss
		
		; push matches to array to find multiple matches (case sensitive variations)
		If (s = ss or s = st) {
			temp := {}
			temp.s := s
			temp.mod := mod
			matches.push(temp)
		}
	}

	If (matches.Length()) {
		If (matches.Length() = 1) {
			Return matches[1].mod
		}
		Else {
			Loop % matches.Length()
			{
				; use == instead of = to search case sensitive, there is at least one case where this matters (Life regenerated per second)
				If (matches[A_Index].s == editedNeedle) {
					Return matches[A_Index].mod
				}
			}
		}
	}
	
	If (not matches[1] and recurse = true) {
		TradeFunc_FindInModGroup(modgroup, needle, false, false)
	} Else {
		Return ""
	}
}

TradeFunc_GetCorruption(_item) {
	mods     := TradeGlobals.Get("ModsData")
	corrMods := TradeGlobals.Get("CorruptedModsData")
	corrImplicits := []
	
	For key, val in _item.Implicit {
		RegExMatch(_item.Implicit[key], "i)([-.0-9]+)", value)
		If (RegExMatch(imp, "i)Limited to:")) {
			;return false
		}
		imp      := RegExReplace(_item.Implicit[key], "i)([-.0-9]+)", "#")

		corrMod  := {}
		For i, corr in corrMods {
			If (imp = corr) {
				For j, mod in mods["implicit"] {
					match := Trim(RegExReplace(mod, "i)\(implicit\)", ""))
					If (match = corr) {
						corrMod.param := mod
						corrMod.name  := _item.implicit[key]
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
			corrImplicits.push(corrMod)
		}
	}
	
	If (corrImplicits.Length()) {
		Return corrImplicits
	}
	Else {
		Return false
	}
}

TradeFunc_GetEnchantment(_item, type) {
	mods     := TradeGlobals.Get("ModsData")
	enchants := TradeGlobals.Get("EnchantmentData")
	enchImplicits := []

	; currently a missing implicit causes the enchantment to take the "implicit slot"
	; we can only say for sure whether we have an implicit or enchantment if both are present and we know don't have a magic/rare item with completely annulled explicit mods
	; or by matching against all possible enchantments	
	searchKey := "implicit"
	If (Item.hasEnchantment) {
		searchKey := "enchantment"
	}

	group :=
	If (type = "Boots") {
		group := enchants.boots
	}
	Else If (type = "Gloves") {
		group := enchants.gloves
	}
	Else If (type = "Helmet") {
		group := enchants.helmet
	}

	For key, val in _item[searchKey] {
		RegExMatch(_item[searchKey][key], "i)([.0-9]+)(%? to ([.0-9]+))?", values)
		imp      := RegExReplace(_item[searchKey][key], "i)([.0-9]+)", "#")

		enchantment := {}
		If (group.length()) {
			For i, enchant in group {
				If (TradeUtils.CleanUp(imp) = enchant) {
					For j, mod in mods["enchantments"] {
						match := Trim(RegExReplace(mod, "i)\(enchant\)", ""))
						If (match = enchant) {
							enchantment.param := mod
							enchantment.name  := _item[searchKey][key]
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
			enchImplicits.push(enchantment)
		}
	}

	If (enchImplicits.Length()) {
		Return enchImplicits
	}
	Else {
		Return false
	}
}

TradeFunc_GetModValueGivenPoeTradeMod(itemModifiers, poeTradeMod) {
	If (StrLen(poeTradeMod) < 1) {
		ErrorMsg := "Mod not found on poe.trade!"
		Return ErrorMsg
	}
	poeTradeMod_ValueTypes := TradeFunc_CountValuesAndReplacedValues(poeTradeMod)

	Loop, Parse, itemModifiers, `n, `r
	{		
		If StrLen(A_LoopField) = 0
		{
			Continue ; Not interested in blank lines
		}		
		LoopField := Trim(RegExReplace(A_LoopField, "i)\((fractured|crafted)\)"))
		
		ModStr := ""
		CurrValues := []
		CurrLine_ValueTypes := TradeFunc_CountValuesAndReplacedValues(LoopField)		
		CurrValue := TradeFunc_GetActualValue(LoopField, poeTradeMod_ValueTypes)
		
		If (CurrValue ~= "\d+") {
			; handle value range
			RegExMatch(CurrValue, "(\d+) ?(-|to) ?(\d+)", values)
			If (values3) {
				CurrValues.Push(values1)
				CurrValues.Push(values3)
				CurrValue := values1 " to " values3
				ModStr := StrReplace(LoopField, CurrValue, "# to #")
			}
			; handle single value
			Else {
				CurrValues.Push(CurrValue)
				ModStr := StrReplace(LoopField, CurrValue, "#")
			}
			
			; remove negative sign since poe.trade mods are always positive
			ModStr := RegExReplace(ModStr, "^-#", "#")
			ModStr := StrReplace(ModStr, "+")
			; replace multi spaces with a single one
			ModStr := RegExReplace(ModStr, " +", " ")
			
			If (RegExMatch(poeTradeMod, "i).*" ModStr "$")) {
				Return CurrValues
			}
		}
		
	}
}

; Get value while being able to ignore some, depending on their position
; ValueTypes = ["value", "replaced"]
TradeFunc_GetActualValue(ActualValueLine, ValueTypes)
{
	returnValue 	:= ""	
	Pos		:= 0
	Count 	:= 0
	; Leaves "-" in for negative values, example: "Ventor's Gamble"
	While Pos	:= RegExMatch(ActualValueLine, "\+?(-?\d+(?: to -?\d+|\.\d+)?)", value, Pos + (StrLen(value) ? StrLen(value) : 1)) {
		Count++		
		If (InStr(ValueTypes[Count], "Replaced", 0)) {			
			; Formats "1 to 2" as "1-2"
			StringReplace, Result, value1, %A_SPACE%to%A_SPACE%, -
			returnValue := Trim(RegExReplace(Result, ""))	
		}
	}
	
	return returnValue
}

; Get actual values from a line of the ingame tooltip as numbers
; that can be used in calculations.
TradeFunc_GetActualValues(ActualValueLine)
{
	values := []
	
	Pos		:= 0
	; Leaves "-" in for negative values, example: "Ventor's Gamble"
	While Pos	:= RegExMatch(ActualValueLine, "\+?(-?\d+(?: to -?\d+|\.\d+)?)", value, Pos + (StrLen(value) ? StrLen(value) : 1)) {
		; Formats "1 to 2" as "1-2"
		StringReplace, Result, value1, %A_SPACE%to%A_SPACE%, -
		values.push(Trim(RegExReplace(Result, "")))
	}
	
	return values
}

TradeFunc_CountValuesAndReplacedValues(ActualValueLine)
{
	values := []
	
	Pos		:= 0
	Count	:= 0
	; Leaves "-" in for negative values, example: "Ventor's Gamble"
	While Pos	:= RegExMatch(ActualValueLine, "\+?(-?\d+(?: to -?\d+|\.\d+)?)|\+?(-?#(?: to -?#)?)", value, Pos + (StrLen(value) ? StrLen(value) : 1)) {
		Count++
		If (value1) {
			values.push("value")
		}
		Else If (value2) {
			values.push("replaced")
		}
	}

	return values
}


TradeFunc_GetNonUniqueModValueGivenPoeTradeMod(itemModifiers, poeTradeMod, ByRef keepOrigModName = false) {
	If (StrLen(poeTradeMod) < 1) {
		ErrorMsg := "Mod not found on poe.trade!"
		Return ErrorMsg
	}
	
	CurrValue	:= ""
	CurrValues:= []
	CurrValue := GetActualValue(itemModifiers.name_orig)
	
	If (CurrValue ~= "\d+") {
		; handle value range
		RegExMatch(CurrValue, "(\d+) ?(-|to) ?(\d+)", values)

		If (values3) {
			CurrValues.Push(values1)
			CurrValues.Push(values3)
			CurrValue := values1 " to " values3
			ModStr := StrReplace(itemModifiers.name_orig, CurrValue, "#")
		}
		; handle single value
		Else {
			CurrValues.Push(CurrValue)
			ModStr := StrReplace(itemModifiers.name_orig, CurrValue, "#")
		}

		ModStr := StrReplace(ModStr, "+")
		; replace multi spaces with a single one
		ModStr := RegExReplace(ModStr, " +", " ")
		poeTradeMod := RegExReplace(poeTradeMod, "# ?to ? #", "#")
		poeTradeMod := StrReplace(poeTradeMod, "+")
		
		If (RegExMatch(poeTradeMod, "i).*" ModStr "$")) {
			Return CurrValues
		} Else If (RegExMatch(poeTradeMod, "i).*" itemModifiers.name_orig "$")) {
			keepOrigModName := true
			Return 
		}
	}
}

; Create custom search GUI
TradeFunc_CustomSearchGui() {
	Global
	Gui, CustomSearch:Destroy
	Gui, CustomSearch:Color, ffffff, ffffff
	customSearchItemTypes := TradeGlobals.Get("ItemTypeList")

	CustomSearchTypeList := ""
	CustomSearchBaseList := ""
	For type, bases in customSearchItemTypes {
		CustomSearchTypeList .= "|" . type
		For key, base in bases {
			CustomSearchBaseList .= "|" . base
		}
	}

	Gui, CustomSearch:Add, Edit, w480 vCustomSearchName

	; Type
	Gui, CustomSearch:Add, Text, x10 y+10, Type
	Gui, CustomSearch:Add, DropDownList, x+10 yp-4 vCustomSearchType, %CustomSearchTypeList%
	; Rarity
	Gui, CustomSearch:Add, Text, x+10 yp+4 w50, Rarity
	Gui, CustomSearch:Add, DropDownList, x+10 yp-4 w90 vCustomSearchRarity, any||Normal|Magic|Rare|Unique
	; Sockets
	Gui, CustomSearch:Add, Text, x+10 yp+4 w50, Sockets
	Gui, CustomSearch:Add, Edit, x+10 yp-4 w30 vCustomSearchSocketsMin
	Gui, CustomSearch:Add, Text, x+6 yp+4 w10, -
	Gui, CustomSearch:Add, Edit, x+0 yp-4 w30 vCustomSearchSocketsMax

	; Base
	Gui, CustomSearch:Add, Text, x10 y+10, Base
	Gui, CustomSearch:Add, DropDownList, x+10 yp-4 vCustomSearchBase, %CustomSearchBaseList%
	; Corrupted
	Gui, CustomSearch:Add, Text, x+10 yp+4 w50, Corrupted
	Gui, CustomSearch:Add, DropDownList, x+10 yp-4 w90 vCustomSearchCorrupted, either||Yes|No
	; Links
	Gui, CustomSearch:Add, Text, x+10 yp+4 w50, Links
	Gui, CustomSearch:Add, Edit, x+10 yp-4 w30 vCustomSearchLinksMin
	Gui, CustomSearch:Add, Text, x+6 yp+4 w10, -
	Gui, CustomSearch:Add, Edit, x+0 yp-4 w30 vCustomSearchLinksMax

	; Quality
	Gui, CustomSearch:Add, Text, x10 y+10 w40, Quality
	Gui, CustomSearch:Add, Edit, x+10 yp-4 w30 vCustomSearchQualityMin
	Gui, CustomSearch:Add, Text, x+6 yp+4 w10, -
	Gui, CustomSearch:Add, Edit, x+0 yp-4 w30 vCustomSearchQualityMax

	; Level/Tier
	Gui, CustomSearch:Add, Text, x175 yp+4 w40, Level/Tier
	Gui, CustomSearch:Add, Edit, x+10 yp-4 w30 vCustomSearchLevelMin
	Gui, CustomSearch:Add, Text, x+6 yp+4 w10, -
	Gui, CustomSearch:Add, Edit, x+0 yp-4 w30 vCustomSearchLevelMax

	; ItemLevel
	Gui, CustomSearch:Add, Text, x335 yp+4 w50, ItemLevel
	Gui, CustomSearch:Add, Edit, x+10 yp-4 w30 vCustomSearchItemLevelMin
	Gui, CustomSearch:Add, Text, x+6 yp+4 w10, -
	Gui, CustomSearch:Add, Edit, x+0 yp-4 w30 vCustomSearchItemLevelMax

	; Buttons
	Gui, CustomSearch:Add, Button, x10 gSubmitCustomSearch hwndCSearchBtnHwnd, &Search
	Gui, CustomSearch:Add, Button, x+10 yp+0 gOpenCustomSearchOnPoeTrade Default, Op&en on poe.trade
	Gui, CustomSearch:Add, Button, x+10 yp+0 gCloseCustomSearch, &Close
	Gui, CustomSearch:Add, Text, x+10 yp+4 cGray, (Use Alt + S/C to submit a button)

	Gui, CustomSearch:Show, w500 , Custom Search
}

TradeFunc_CreateItemPricingTestGUI() {
	Global
	Gui, PricingTest:Destroy
	Gui, PricingTest:Color, ffffff, ffffff

	Gui, PricingTest:Add, Text, x10 y10 w480, Input item information/data
	Gui, PricingTest:Add, Edit, x10 w480 y+10 R30 vPricingTestItemInput

	Gui, PricingTest:Add, Button, x10 gSubmitPricingTestDefault , &Normal
	Gui, PricingTest:Add, Button, x+10 yp+0 gSubmitPricingTestAdvanced, &Advanced
	Gui, PricingTest:Add, Button, x+10 yp+0 gOpenPricingTestOnPoeTrade, Op&en on poe.trade
	Gui, PricingTest:Add, Button, x+10 yp+0 gSubmitPricingTestWiki, Open &Wiki
	Gui, PricingTest:Add, Button, x+10 yp+0 gSubmitPricingTestParsing, Parse (&Tooltip)
	Gui, PricingTest:Add, Button, x+10 yp+0 gSubmitPricingTestParsingObject, Parse (&Object)
	Gui, PricingTest:Add, Button, x10 yp+40 gClosePricingTest, &Close
	Gui, PricingTest:Add, Text, x+10 yp+4 cGray, (Use Alt + N/A/E/W/C/T/O to submit a button)

	Gui, PricingTest:Show, w500 , Item Pricing Test
}

TradeFunc_PreparePredictedPricingContributionDetails(details, nameLength) {
	arr := []
	longest := 0

	For key, val in details {
		obj := {}
		name := val[1]
		shortened := RegExReplace(Trim(name), "^\(.*?\)")
		obj.name := shortened
		obj.name := (StrLen(shortened) > nameLength ) ? Trim(SubStr(obj.name, 1, nameLength) "...") : Trim(StrPad(obj.name, nameLength + 3))
		obj.contribution := val[2] * 100 
		obj.percentage := Trim(obj.contribution " %")
		longest := (longest > StrLen(obj.percentage)) ? longest : StrLen(obj.percentage)
		
		arr.push(obj)
	}

	For key, val in arr {
		val.percentage := StrPad(val.percentage, longest, "left", " ")
	}

	Return arr
}

TradeFunc_ShowPredictedPricingFeedbackUI(data) {
	Global
	
	_Name := (Item.IsRare and not Item.IsMap) ? Item.Name " " Item.BaseName : Item.Name
	_headLine := Trim(StrReplace(_Name, "Superior", ""))
	; add corrupted tag
	If (Item.IsCorrupted) {
		_headLine .= " [Corrupted] "
	}

	; add gem quality and level
	If (Item.IsGem) {
		_headLine := Item.Name ", Q" Item.Quality "%"
		If (Item.Level >= 16) {
			_headLine := Item.Name ", " Item.Level "`/" Item.Quality "%"
		}
	}
	; add item sockets and links
	If (ItemData.Sockets >= 5) {
		_headLine := _Name " " ItemData.Sockets "s" ItemData.Links "l"
	}
	If (showItemLevel) {
		_headLine .= ", iLvl: " iLvl
	}
	_headLine .= ", (" TradeGlobals.Get("LeagueName") ")"
	
	
	Gui, PredictedPricing:Destroy
	Gui, PredictedPricing:Color, ffffff, ffffff
	
	Gui, PredictedPricing:Margin, 10, 10

	Gui, PredictedPricing:Font, bold s8 c000000, Verdana
	Gui, PredictedPricing:Add, Text, BackgroundTrans, Priced using machine learning algorithms.
	Gui, PredictedPricing:Add, Text, BackgroundTrans x+5 yp+0 cRed, (Close with ESC)
	
	_details := TradeFunc_PreparePredictedPricingContributionDetails(data.pred_explanation, 40)
	_contributionOffset := _details.Length() * 24
	_groupBoxHeight := _contributionOffset + 83
	
	Gui, PredictedPricing:Add, GroupBox, w400 h%_groupBoxHeight% y+10 x10, Results
	Gui, PredictedPricing:Font, norm s10 c000000, Consolas
	Gui, PredictedPricing:Add, Text, yp+25 x20 w380 BackgroundTrans, % _headLine
	Gui, PredictedPricing:Font, norm bold c000000, Consolas
	Gui, PredictedPricing:Add, Text, x20 w90 y+10 BackgroundTrans, % "Price range: "
	Gui, PredictedPricing:Font, norm c000000, Consolas
	Gui, PredictedPricing:Add, Text, x+5 yp+0 BackgroundTrans, % Round(Trim(data.min), 2) " ~ " Round(Trim(data.max), 2) " " Trim(data.currency)
	Gui, PredictedPricing:Add, Text, x20 w300 y+10 BackgroundTrans, % "Contribution to predicted price: "	
	
	; mod importance graph
	Gui, PredictedPricing:Font, s8 c000000
	For _k, _v in _details {
		If (StrLen(_v.name)) {
			_line := _v.percentage " -> " _v.name 
			Gui, PredictedPricing:Add, Text, x30 w350 y+4 BackgroundTrans, % _line	
		}		
	}

	; browser url
	_url := data.added.browserUrl
	Gui, PredictedPricing:Add, Link, x245 y+12 cBlue BackgroundTrans, <a href="%_url%">Open on poeprices.info</a>
	
	Gui, PredictedPricing:Font, norm s8 italic c000000, Verdana	

	If (StrLen(data.warning_msg)) {
		Gui, PredictedPricing:Add, Text, x15 y+25 w380 cc14326 BackgroundTrans, % "poeprices warning message:"
		Gui, PredictedPricing:Add, Text, x15 y+8 w380 cc14326 BackgroundTrans, % data.warning_msg
	} Else {
		Gui, PredictedPricing:Add, Text, x15 y+25 w380 BackgroundTrans, % ""
	}

	Gui, PredictedPricing:Font, bold s8 c000000, Verdana
	Gui, PredictedPricing:Add, GroupBox, w400 h230 y+10 x10, Feedback
	Gui, PredictedPricing:Font, norm c000000, Verdana
	
	Gui, PredictedPricing:Add, Text, x20 yp+25 BackgroundTrans, You think the predicted price range is?
	Gui, PredictedPricing:Add, Progress, x16 yp+18 w2 h56 BackgroundRed hwndPredictedPricingHiddenControl1
	GuiControl, Hide, % PredictedPricingHiddenControl1
	Gui, PredictedPricing:Add, Radio, x20 yp+2 vPredictionPricingRadio1 Group BackgroundTrans, Low
	Gui, PredictedPricing:Add, Radio, x20 yp+20 vPredictionPricingRadio2 BackgroundRed, Fair
	Gui, PredictedPricing:Add, Radio, x20 yp+20 vPredictionPricingRadio3 BackgroundTrans, High
	
	Gui, PredictedPricing:Add, Text, x20 yp+30 BackgroundTrans, % "Add comment (max. 1000 characters):"
	Gui, PredictedPricing:Add, Edit, x20 yp+20 w380 r4 limit1000 vPredictedPricingComment, 
	
	Gui, PredictedPricing:Add, Text, x100 y+10 cRed hwndPredictedPricingHiddenControl2, Please select a rating first!
	GuiControl, Hide, % PredictedPricingHiddenControl2
	Gui, PredictedPricing:Add, Button, x260 w90 yp-5 gPredictedPricingSendFeedback, Send && Close
	Gui, PredictedPricing:Add, Button, x+11 w40 gPredictedPricingClose, Close
	
	Gui, PredictedPricing:Font, bold s8 c000000, Verdana
	Gui, PredictedPricing:Add, Text, x15 y+20 cGreen BackgroundTrans, % "This feature is powered by poeprices.info!"
	Gui, PredictedPricing:Font, norm c000000, Verdana
	Gui, PredictedPricing:Add, Link, x15 y+5 cBlue BackgroundTrans, <a href="https://www.paypal.me/poeprices/5">Support them via PayPal</a>
	Gui, PredictedPricing:Add, Text, x+5 yp+0 cBlack BackgroundTrans, % "or"
	Gui, PredictedPricing:Add, Link, x+5 yp+0 cBlue BackgroundTrans, <a href="https://www.patreon.com/bePatron?u=5966037">Patreon</a>
	
	Gui, PredictedPricing:Add, Text, BackgroundTrans x15 y+10 w390, % "You can disable this GUI in favour of a simple result tooltip. Settings menu -> under 'Search' group. Or even disable this predicted search entirely."
	
	; invisible fields
	Gui, PredictedPricing:Add, Edit, x+0 yp+0 w0 h0 ReadOnly vPredictedPricingEncodedData, % data.added.encodedData
	Gui, PredictedPricing:Add, Edit, x+0 yp+0 w0 h0 ReadOnly vPredictedPricingLeague, % data.added.League
	Gui, PredictedPricing:Add, Edit, x+0 yp+0 w0 h0 ReadOnly vPredictedPricingMin, % data.min
	Gui, PredictedPricing:Add, Edit, x+0 yp+0 w0 h0 ReadOnly vPredictedPricingMax, % data.max
	Gui, PredictedPricing:Add, Edit, x+0 yp+0 w0 h0 ReadOnly vPredictedPricingCurrency, % data.currency
	
	Gui, PredictedPricing:Color, FFFFFF	
	Gui, PredictedPricing:Show, AutoSize, Predicted Item Pricing
	ControlFocus, Send && Close, Predicted Item Pricing
}

HandleGuiControlSetFocus( p_w, p_l, p_m, p_hw ) {
	global
	local lastControl

	; EN_KILLFOCUS = 0x0200
	; EN_SETFOCUS = 0x0100
	If ( p_w & 0x1000000 and TradeOpts.IncludeSearchParamByFocus)
	{
		Gui, SelectModsGui:Submit, NoHide
		If (WinActive(ahk_group SelectModsGui)) {
			GuiControlGet, lastControl, Name, % p_l

			RegExMatch(lastControl, "i)(TradeAdvancedMod|TradeAdvancedStat).*?(\d+)$", match)
			If (RegExMatch(match1, "i)TradeAdvancedMod")) {
				GuiControl,, TradeAdvancedSelected%match2% , 1
			}
			Else If (RegExMatch(match1, "i)TradeAdvancedStat")) {
				GuiControl,, TradeAdvancedStatSelected%match2% , 1
			}			
		}		
	}
}

; Open Gui window to show the items variable mods, select the ones that should be used in the search and set their min/max values
TradeFunc_AdvancedPriceCheckGui(advItem, Stats, Sockets, Links, UniqueStats = "", ChangedImplicit = "") {
	;https://autohotkey.com/board/topic/9715-positioning-of-controls-a-cheat-sheet/
	Global

	;prevent advanced gui in certain cases
	If (not advItem.mods.Length() and not (ChangedImplicit or ChangedImplicit.Length())) {
		;ShowTooltip("Advanced search not available for this item.")
		;Return
	}

	TradeFunc_ResetGUI()
	advItem := TradeFunc_DetermineAdvancedSearchPreSelectedMods(advItem, Stats)

	ValueRangeMin := advItem.IsUnique ? TradeOpts.AdvancedSearchModValueRangeMin : TradeOpts.AdvancedSearchModValueRangeMin / 2
	ValueRangeMax := advItem.IsUnique ? TradeOpts.AdvancedSearchModValueRangeMax : TradeOpts.AdvancedSearchModValueRangeMax / 2
	
	Gui, +LastFound
	hw_gui := WinExist()	
	
	Gui, SelectModsGui:Destroy

	/*
		"Dummy" edit field which gets focus on creation.
		"Real" edit fields trigger on SetFocus, which checks the corresponding checkbox, this should only happen via user interaction.
		*/
	Gui, SelectModsGui:Add, Edit, x0 y0 w0 h0,	
	
	Gui, SelectModsGui:Color, ffffff, ffffff
	Gui, SelectModsGui:Add, Text, x10 y12, Percentage to pre-calculate min/max values (halved for non-unique items):
	Gui, SelectModsGui:Add, Text, x+5 yp+0 cGreen, % ValueRangeMin "`% / " ValueRangeMax "`%"
	Gui, SelectModsGui:Add, Text, x10 y+8, This calculation considers the (unique) item's mods difference between their min and max value as 100`%.

	line :=
	Loop, 500 {
		line := line . "-"
	}

	/*
		Add item "nameplate" including sockets and links
		*/

	itemName := advItem.name
	itemType := advItem.BaseName
	If (advItem.Rarity = 1) {
		iPic 	:= "bg-normal"
		tColor	:= "cc8c8c8"
	} Else If (advItem.Rarity = 2) {
		iPic 	:= "bg-magic"
		tColor	:= "c8787fe"
	} Else If (advItem.Rarity = 3) {
		iPic 	:= "bg-rare"
		tColor	:= "cfefe76"
	} Else If (advItem.isUnique) {
		iPic 	:= "bg-unique"
		tColor	:= "cAF5F1C"
	}
	
	image := A_ScriptDir "\resources\images\" iPic ".png"
	If (FileExist(image)) {
		Gui, SelectModsGui:Add, Picture, w900 h30 x0 yp+20, %image%
	}		
	Gui, SelectModsGui:Add, Text, x14 yp+9 %tColor% BackgroundTrans, %itemName%
	If (advItem.Rarity > 2 or advItem.isUnique) {
		Gui, SelectModsGui:Add, Text, x14 yp+0 x+5 cc8c8c8 BackgroundTrans, %itemType%
	}
	If (advItem.isRelic) {
		Gui, SelectModsGui:Add, Text, x+10 yp+0 cGreen BackgroundTrans, Relic
	}
	If (advItem.isCorrupted) {
		Gui, SelectModsGui:Add, Text, x+10 yp+0 cD20000 BackgroundTrans, (Corrupted)
	}
	If (advItem.maxSockets > 0) {
		tLinksSockets := "S (" Sockets "/" advItem.maxSockets ")"
		If (advItem.maxSockets > 1) {
			tLinksSockets .= " - " "L (" Links "/" advItem.maxSockets ")"
		}
		Gui, SelectModsGui:Add, Text, x+10 yp+0 cc8c8c8 BackgroundTrans, %tLinksSockets%
	}

	Gui, SelectModsGui:Add, Text, x0 w800 yp+13 cBlack BackgroundTrans, %line%

	ValueRangeMin	:= ValueRangeMin / 100
	ValueRangeMax	:= ValueRangeMax / 100

	/*
		calculate length of first column
		*/
	modLengthMax	:= 0
	modGroupBox	:= 0
	Loop % advItem.mods.Length() {
		invalidUnique := ((not advItem.mods[A_Index].isVariable and not advItem.hasVariant) and advItem.IsUnique and not advItem.mods[A_Index].isUnknown)
		If (invalidUnique) {
			continue
		}
		tempValue := StrLen(advItem.mods[A_Index].name)
		If (modLengthMax < tempValue ) {
			modLengthMax := tempValue
			modGroupBox := modLengthMax * 6
		}
	}
	Loop % ChangedImplicit.Length() {
		tempValue := StrLen(ChangedImplicit[A_Index].param)
		If (modLengthMax < tempValue ) {
			modLengthMax := tempValue
			modGroupBox := modLengthMax * 6
		}
	}
	modGroupBox := modGroupBox + 10
	
	modCount := advItem.mods.Length()

	/*
		calculate row count and mod box heights
		*/
		
	statCount := 0
	For i, stat in Stats.Defense {
		statCount := (stat.value) ? statCount + 1 : statCount
	}
	For i, stat in Stats.Offense {
		statCount := (stat.value) ? statCount + 1 : statCount
	}
	statCount := (ChangedImplicit) ? statCount + 1 : statCount

	boxRows := modCount * 3 + statCount * 3

	modGroupYPos := 4
	Gui, SelectModsGui:Add, Text, x14 y+%modGroupYPos% w%modGroupBox%, Mods
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w90, min
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w45, current
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w90, max
	Gui, SelectModsGui:Add, Text, x+10 yp+0 w30, Select

	line :=
	Loop, 500 {
		line := line . "-"
	}
	Gui, SelectModsGui:Add, Text, x0 w700 yp+13, %line%
	
	hasUnknownMods := false
	For k, v in advItem.mods {
		If (v.isUnknown) {
			hasUnknownMods := true
			Break
		}	
	}	
	
	/*
		add defense stats
		*/

	j := 1
	For i, stat in Stats.Defense {
		If (stat.value) {
			xPosMin := modGroupBox + 25
			yPosFirst := ( j = 1 ) ? 20 : 25

			If (!stat.min or !stat.max or (stat.min = stat.max and (Stats.Defense.Quality <= 20 or hasUnknownMods)) and advItem.IsUnique) {
				continue
			}

			If (stat.Name != "Block Chance") {
				stat.value   := Round(stat.value)
				statValueQ20 := Round(stat.value)
			}

			; calculate values to prefill min/max fields
			; assume the difference between the theoretical max and min value as 100%
			If (advItem.IsUnique) {
				statValueMin := Round(statValueQ20 - ((stat.max - stat.min) * valueRangeMin))
				statValueMax := Round(statValueQ20 + ((stat.max - stat.min) * valueRangeMax))
			}
			Else {
				statValueMin := Round(statValueQ20 - (statValueQ20 * valueRangeMin))
				statValueMax := Round(statValueQ20 + (statValueQ20 * valueRangeMax))
			}

			; prevent calculated values being smaller than the lowest possible min value or being higher than the highest max values
			If (advItem.IsUnique) {
				statValueMin := Floor((statValueMin < stat.min) ? stat.min : statValueMin)
				statValueMax := Floor((statValueMax > stat.max) ? stat.max : statValueMax)
			}

			If (not TradeOpts.PrefillMinValue) {
				statValueMin :=
			}
			If (not TradeOpts.PrefillMaxValue) {
				statValueMax :=
			}

			minLabelFirst  := advItem.isUnique ? "(" Floor(stat.min) : ""
			minLabelSecond := advItem.isUnique ? ")" : ""
			maxLabelFirst  := advItem.isUnique ? "(" Ceil(stat.max) : ""
			maxLabelSecond := advItem.isUnique ? ")" : ""

			Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%							, % "(Total Q20) " stat.name
			Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w40 vTradeAdvancedStatMin%j% r1	, % statValueMin
			Gui, SelectModsGui:Add, Text, x+5  yp+3       w45 cGreen					, % minLabelFirst minLabelSecond
			Gui, SelectModsGui:Add, Text, x+10 yp+0       w45 r1						, % Floor(statValueQ20)
			Gui, SelectModsGui:Add, Edit, x+10 yp-3       w40 vTradeAdvancedStatMax%j% r1	, % statValueMax
			Gui, SelectModsGui:Add, Text, x+5  yp+3       w45 cGreen					, % maxLabelFirst maxLabelSecond
			checkedState := stat.PreSelected ? "Checked" : ""
			Gui, SelectModsGui:Add, CheckBox, x+10 yp+1       vTradeAdvancedStatSelected%j% %checkedState%

			TradeAdvancedStatParam%j% := stat.name
			j++
		}
	}

	If (j > 1) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+18 cc9cacd, %line%
	}

	/*
		add dmg stats
		*/
		
	k := 1
	For i, stat in Stats.Offense {
		If (stat.value) {
			xPosMin := modGroupBox + 25
			yPosFirst := ( j = 1 ) ? 20 : 25

			If (!stat.min or !stat.max or (stat.min == stat.max and (Stats.Offense.Quality <= 20 or hasUnknownMods)) and advItem.IsUnique) {
				continue
			}

			; calculate values to prefill min/max fields
			; assume the difference between the theoretical max and min value as 100%
			If (advItem.IsUnique) {
				statValueMin := Round(stat.value - ((stat.max - stat.min) * valueRangeMin))
				statValueMax := Round(stat.value + ((stat.max - stat.min) * valueRangeMax))
			}
			Else {
				statValueMin := Round(stat.value - (stat.value * valueRangeMin))
				statValueMax := Round(stat.value + (stat.value * valueRangeMax))
			}

			; prevent calculated values being smaller than the lowest possible min value or being higher than the highest max values
			If (advItem.IsUnique) {
				statValueMin := Floor((statValueMin < stat.min) ? stat.min : statValueMin)
				statValueMax := Floor((statValueMax > stat.max) ? stat.max : statValueMax)
			}

			If (not TradeOpts.PrefillMinValue) {
				statValueMin :=
			}
			If (not TradeOpts.PrefillMaxValue) {
				statValueMax :=
			}

			minLabelFirst  := advItem.isUnique ? "(" Floor(stat.min) : ""
			minLabelSecond := advItem.isUnique ? ")" : ""
			maxLabelFirst  := advItem.isUnique ? "(" Ceil(stat.max) : ""
			maxLabelSecond := advItem.isUnique ? ")" : ""

			Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%						  , % stat.name
			Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w40 vTradeAdvancedStatMin%j% r1, % statValueMin
			Gui, SelectModsGui:Add, Text, x+5  yp+3       w45 cGreen				  , % minLabelFirst minLabelSecond
			Gui, SelectModsGui:Add, Text, x+10 yp+0       w45 r1					  , % Floor(stat.value)
			Gui, SelectModsGui:Add, Edit, x+10 yp-3       w40 vTradeAdvancedStatMax%j% r1, % statValueMax
			Gui, SelectModsGui:Add, Text, x+5  yp+3       w45 cGreen				  , % maxLabelFirst maxLabelSecond
			checkedState := stat.PreSelected ? "Checked" : ""
			Gui, SelectModsGui:Add, CheckBox, x+10 yp+1       vTradeAdvancedStatSelected%j% %checkedState%

			TradeAdvancedStatParam%j% := stat.name
			j++
			TradeAdvancedStatsCount := j
			k++
		}
	}

	If (k > 1) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+18 cc9cacd, %line%
	}

	/*
		Enchantment
		*/		
	en := 0
	If (advItem.Enchantment.Length()) {	
		xPosMin := modGroupBox + 25
		yPosFirst := 20 ; ( j > 1 ) ? 20 : 30
		xPosMin := xPosMin + 40 + 5 + 45 + 10 + 45 + 10 + 40 + 5 + 45 + 10 ; edit/text field widths and offsets
		
		For key, val in advItem.Enchantment {
			en++
			modValueMin := val.min
			modValueMax := val.max
			displayName := val.name			
			
			If (key > 1) {
				yPosFirst := 20
			}
			
			Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%, % displayName
			Gui, SelectModsGui:Add, CheckBox, x%xPosMin% yp+1 vTradeAdvancedSelected%en%

			TradeAdvancedModMin%en% 		:= val.min
			TradeAdvancedModMax%en% 		:= val.max
			TradeAdvancedParam%en%  		:= val.param
			TradeAdvancedIsImplicit%en%	:= false
			TradeAdvancedIsEnchantment%en%:= true	
		}
	}
	TradeAdvancedEnchantmentCount := en

	If (advItem.Enchantment.Length()) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+18 cc9cacd, %line%
	}

	/*
		Synthesis or Corrupted Implicit
		*/	
	e := 0
	If (ChangedImplicit.Length()) {
		xPosMin := modGroupBox + 25
		yPosFirst := 20 ; ( j > 1 ) ? 20 : 30
		xPosMin := xPosMin + 40 + 5 + 45 + 10 + 45 + 10 + 40 + 5 + 45 + 10 ; edit/text field widths and offsets
		
		For key, val in ChangedImplicit {
			e++
			modValueMin := val.min
			modValueMax := val.max
			displayName := val.name			
			
			If (key > 1) {
				yPosFirst := 20
			}
			index := e + en
			Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%, % displayName
			Gui, SelectModsGui:Add, CheckBox, x%xPosMin% yp+1 vTradeAdvancedSelected%index%

			TradeAdvancedModMin%index% 		:= val.min
			TradeAdvancedModMax%index% 		:= val.max
			TradeAdvancedParam%index%  		:= val.param
			TradeAdvancedIsImplicit%index%	:= true	
		}		
	}
	TradeAdvancedImplicitCount := e

	If (ChangedImplicit) {
		Gui, SelectModsGui:Add, Text, x0 w700 yp+18 cc9cacd, %line%
	}

	/*
		add mods
		*/
	l := 1
	p := 1
	fracturedImageShift := 7
	TradeAdvancedNormalModCount := 0
	ModNotFound := false
	PreCheckNormalMods := TradeOpts.AdvancedSearchCheckMods ? "Checked" : ""

	Loop % advItem.mods.Length() {
		hidePseudo := advItem.mods[A_Index].hideForTradeMacro ? true : false
		If (advItem.mods[A_Index].hideForTradeMacro and advItem.mods[A_Index].type = "pseudo" and advItem.IsSynthesisedBase) {
			hidePseudo := false
		}
	
		; allow non-variable mods if the item has variants to better identify the specific version/variant
		invalidUnique := ((not advItem.mods[A_Index].isVariable and not advItem.hasVariant) and advItem.IsUnique and not advItem.mods[A_Index].isUnknown)
		If (invalidUnique or hidePseudo or not StrLen(advItem.mods[A_Index].name)) {
			continue
		}
		xPosMin := modGroupBox + 25

		; matches "1 to #" in for example "adds 1 to # lightning damage"
		; may be replaced later with original name
		If (RegExMatch(advItem.mods[A_Index].name, "i)Adds (\d+(.\d+)?) to #.*Damage", match)) {
			displayName := RegExReplace(advItem.mods[A_Index].name, "\d+(.\d+)? to #", "#")
			staticValue := match1
		}
		Else {
			displayName := advItem.mods[A_Index].name
			staticValue :=
		}

		If (advItem.mods[A_Index].ranges.Length() > 1) {
			theoreticalMinValue := advItem.mods[A_Index].ranges[1][1]
			theoreticalMaxValue := advItem.mods[A_Index].ranges[2][2]
		}
		Else {
			; use staticValue to create 2 ranges; for example (1 to 50) to (1 to 70) instead of only having 1 to (50 to 70)
			If (staticValue) {
				theoreticalMinValue := staticValue
				theoreticalMaxValue := advItem.mods[A_Index].ranges[1][2]
			}
			Else {
				theoreticalMinValue := advItem.mods[A_Index].ranges[1][1] ? advItem.mods[A_Index].ranges[1][1] : 0
				theoreticalMaxValue := advItem.mods[A_Index].ranges[1][2] ? advItem.mods[A_Index].ranges[1][2] : 0
			}
		}
		
		SetFormat, FloatFast, 5.2
		ErrorMsg :=
		If (advItem.IsUnique) {
			modValues := TradeFunc_GetModValueGivenPoeTradeMod(ItemData.Affixes, advItem.mods[A_Index].param)
		}
		Else {
			useOriginalModName := false
			modValues := TradeFunc_GetNonUniqueModValueGivenPoeTradeMod(advItem.mods[A_Index], advItem.mods[A_Index].param, useOriginalModName)
			If (useOriginalModName) {
				displayName := advItem.mods[A_Index].name_orig
			}			
		}
		
		If (modValues.Length() > 1) {
			modValue := (modValues[1] + modValues[2]) / 2
		}
		Else {
			If (StrLen(modValues) > 10) {
				; error msg
				ErrorMsg := modValues
				ModNotFound := true
			}
			modValue := modValues[1]
		}
		
		switchValue :=
		; make sure that the lower vaule is always min (reduced mana cost of minion skills)
		If (StrLen(theoreticalMinValue) and StrLen(theoreticalMaxValue)) {
			If (theoreticalMinValue > theoreticalMaxValue) {
				switchValue		:= theoreticalMinValue
				theoreticalMinValue := theoreticalMaxValue
				theoreticalMaxValue := switchValue
			}
		}
		
		If (advItem.mods[A_Index].isVariable or not advItem.IsUnique or advItem.mods[A_Index].isUnknown) {	
			; calculate values to prefill min/max fields
			; assume the difference between the theoretical max and min value as 100%
			If (advItem.mods[A_Index].ranges[1]) {
				If (not StrLen(switchValue)) {
					modValueMin := modValue - ((theoreticalMaxValue - theoreticalMinValue) * valueRangeMin)
					modValueMax := modValue + ((theoreticalMaxValue - theoreticalMinValue) * valueRangeMax)
				} Else {
					modValueMin := modValue - ((theoreticalMaxValue - theoreticalMinValue) * valueRangeMin)
					modValueMax := modValue + ((theoreticalMaxValue - theoreticalMinValue) * valueRangeMax)
				}
			} Else {
				modValueMin := modValue - (modValue * valueRangeMin)
				modValueMax := modValue + (modValue * valueRangeMax)
			}

			; floor/Ceil values only if greater than 2, in case of leech/regen mods, use Abs() to support negative numbers
			modValueMin := (Abs(modValueMin) > 2) ? Floor(modValueMin) : modValueMin
			modValueMax := (Abs(modValueMax) > 2) ? Ceil(modValueMax) : modValueMax

			; prevent calculated values being smaller than the lowest possible min value or being higher than the highest max values
			If (advItem.mods[A_Index].ranges[1]) {
				modValueMin := TradeUtils.ZeroTrim((modValueMin < theoreticalMinValue and not staticValue) ? theoreticalMinValue : modValueMin)
				modValueMax := TradeUtils.ZeroTrim((modValueMax > theoreticalMaxValue) ? theoreticalMaxValue : modValueMax)
			}

			; create Labels to show unique items min/max rolls
			If (advItem.mods[A_Index].ranges[2][1]) {
				minLF := "(" TradeUtils.ZeroTrim((advItem.mods[A_Index].ranges[1][1] + advItem.mods[A_Index].ranges[1][2]) / 2) ")"
				maxLF := "(" TradeUtils.ZeroTrim((advItem.mods[A_Index].ranges[2][1] + advItem.mods[A_Index].ranges[2][2]) / 2) ")"
			}
			Else If (staticValue) {
				minLF := "(" TradeUtils.ZeroTrim((staticValue + advItem.mods[A_Index].ranges[1][1]) / 2) ")"
				maxLF := "(" TradeUtils.ZeroTrim((staticValue + advItem.mods[A_Index].ranges[1][2]) / 2) ")"
			}
			Else {
				minLF := "(" TradeUtils.ZeroTrim(advItem.mods[A_Index].ranges[1][1]) ")"
				maxLF := "(" TradeUtils.ZeroTrim(advItem.mods[A_Index].ranges[1][2]) ")"
			}
			
			; make sure that the lower value is always min (reduced mana cost of minion skills)
			If (not StrLen(switchValue)) {
				minLabelFirst	:= minLF
				maxLabelFirst	:= maxLF
			} Else {
				minLabelFirst	:= maxLF
				maxLabelFirst	:= minLF
			}
		}
		Else {
			modValueMin := ""
			modValueMax := ""
		}

		If (not TradeOpts.PrefillMinValue or ErrorMsg) {
			modValueMin :=
		}
		If (not TradeOpts.PrefillMaxValue or ErrorMsg) {
			modValueMax :=
		}

		yPosFirst := ( l > 1 ) ? 25 : 20
		; increment index if the item has an enchantment or implicit
		index := A_Index + e + en

		isPseudo := advItem.mods[A_Index].type = "pseudo" ? true : false
		If (isPseudo) {
			If (p = 1) {
				; add line if first pseudo mod
				Gui, SelectModsGui:Add, Text, x0 w700 y+5 cc9cacd, %line%
				yPosFirst := 20
			}
			p++
			; change color if pseudo mod
			color := "cGray"
		}
		Else {
			TradeAdvancedNormalModCount++
		}

		state := modValue and (advItem.mods[A_Index].isVariable or not advItem.IsUnique or advItem.mods[A_Index].isUnknown) ? 0 : 1

		Gui, SelectModsGui:Add, Text, x15 yp+%yPosFirst%  %color% vTradeAdvancedModName%index%			, % isPseudo ? "(pseudo) " . displayName : displayName
		Gui, SelectModsGui:Add, Edit, x%xPosMin% yp-3 w40 vTradeAdvancedModMin%index% r1 Disabled%state% 	, % modValueMin
		DllCall( "FindWindowEx", "uint", hw_gui, "uint", 0, "str", "Edit", "uint", 0 )
		Gui, SelectModsGui:Add, Text, x+5  yp+3       w45 cGreen                  		 				, % (advItem.mods[A_Index].ranges[1]) ? minLabelFirst : ""
		Gui, SelectModsGui:Add, Text, x+10 yp+0       w45 r1     		                         		, % TradeUtils.ZeroTrim(modValue)
		Gui, SelectModsGui:Add, Edit, x+10 yp-3       w40 vTradeAdvancedModMax%index% r1 Disabled%state% 	, % modValueMax
		DllCall( "FindWindowEx", "uint", hw_gui, "uint", 0, "str", "Edit", "uint", 0 )
		Gui, SelectModsGui:Add, Text, x+5  yp+3       w45 cGreen 			                       		, % (advItem.mods[A_Index].ranges[1]) ? maxLabelFirst : ""
		checkEnabled := ErrorMsg ? 0 : 1
		
		; pre-select mods according to the options in the settings menu
		If (checkEnabled) {
			checkedState := (advItem.mods[A_Index].PreSelected or TradeOpts.AdvancedSearchCheckMods or (not advItem.mods[A_Index].isVariable and not advItem.mods[A_Index].isUnknown and advItem.IsUnique)) ? "Checked" : ""
			Gui, SelectModsGui:Add, CheckBox, x+10 yp+1 %checkedState% vTradeAdvancedSelected%index% BackgroundTrans, % ""
		}
		Else {
			Gui, SelectModsGui:Add, Picture, x+10 yp+1 hwndErrorPic 0x0100, %A_ScriptDir%\resources\images\error.png
		}

		If (advItem.isFracturedBase and advItem.mods[A_Index].spawnType = "fractured") {
			GuiAddPicture(A_ScriptDir "\resources\images\fractured-symbol.png", "xp+28 yp-" fracturedImageShift " w27 h-1 0x0100", "", "", "", "", "SelectModsGui")
			Gui, SelectModsGui:Add, Edit, xp+0 h27 w1 yp+%fracturedImageShift% vTradeAdvancedIsFractured%index% Disabled1, % "1" 	; fix positions and set the hidden "fractured" parameter
		}
		
		; hidden fields to pass the raw/original mod names also
		Gui, SelectModsGui:Add, Edit, xp+100 yp+0 w1 vTradeAdvancedModNameRaw%index% r1 Disabled1, % advItem.mods[A_Index].name
		Gui, SelectModsGui:Add, Edit, xp+1 yp+0 w1 vTradeAdvancedModNameRawOrig%index% r1 Disabled1, % advItem.mods[A_Index].name_orig

		color := "cBlack"

		TradeAdvancedParam%index% := advItem.mods[A_Index].param
		l++
		TradeAdvancedModsCount := l
	}
	
	/*
		Prepare some special options
		*/
		
	abyssalSockets := 0	
	Loop % advItem.mods.Length() {
		If (advItem.mods[A_Index].showModAsSeperateOption) {
			If (RegExMatch(advItem.mods[A_Index].name, "i)^Has # Abyssal (Socket|Sockets)$")) {
				abyssalSockets := advItem.mods[A_Index].values[1]
			}
		}
	}

	/*
		Links and Sockets
		*/
	
	m := 1
	If (advItem.mods.Length()) {
		Gui, SelectModsGui:Add, Text, x0 w700 y+5 cc9cacd, %line%
	}	
	
	If (abyssalSockets) {
		Gui, SelectModsGui:Add, CheckBox, x15 y+10 vTradeAdvancedUseAbyssalSockets Checked, % "Abyssal Sockets: " abyssalSockets
		Gui, SelectModsGui:Add, Edit, x+0 yp+0 w0 vTradeAdvancedAbyssalSockets, % abyssalSockets
	}	
	
	Sockets := Sockets - abyssalSockets
	If (Sockets >= 5) {
		m++
		text := "Sockets: " . Trim(Sockets)
		If (Links >= 5) {
			Gui, SelectModsGui:Add, CheckBox, x15 y+10 vTradeAdvancedUseSockets, % text
		} Else {
			Gui, SelectModsGui:Add, CheckBox, x15 y+10 vTradeAdvancedUseSockets Checked, % text
		}
	}
	Else If (Sockets <= 4 and advItem.maxSockets = 4) {
		m++
		text := "Sockets (max): " 4 - abyssalSockets
		Gui, SelectModsGui:Add, CheckBox, x15 y+10 vTradeAdvancedUseSocketsMaxFour, % text
	}
	Else If (Sockets <= 3 and advItem.maxSockets = 3) {
		m++
		text := "Sockets (max): " 3 - abyssalSockets
		Gui, SelectModsGui:Add, CheckBox, x15 y+10 vTradeAdvancedUseSocketsMaxThree, % text
	}

	If (Links >= 5) {
		offset := (m > 1 ) ? "+10" : "15"
		m++
		text := "Links:  " . Trim(Links)
		Gui, SelectModsGui:Add, CheckBox, x%offset% yp+0 vTradeAdvancedUseLinks Checked, % text
	}
	Else If (Links <= 4 and advItem.maxSockets = 4) {
		offset := (m > 1 ) ? "+10" : "15"
		m++
		text := "Links (max): " advItem.maxSockets - abyssalSockets
		Gui, SelectModsGui:Add, CheckBox, x%offset% yp+0 vTradeAdvancedUseLinksMaxFour, % text
	}
	Else If (Links <= 3 and advItem.maxSockets = 3) {
		offset := (m > 1 ) ? "+10" : "15"
		m++
		text := "Links (max): " advItem.maxSockets - abyssalSockets
		Gui, SelectModsGui:Add, CheckBox, x%offset% yp+0 vTradeAdvancedUseLinksMaxThree, % text
	}

	/*
		ilvl
		*/

	offsetX := (m = 1) ? "15" : "+10"
	offsetY := (m = 1) ? "20" : "+0"
	iLvlCheckState := ""
	iLvlValue		:= ""
	If (advItem.specialBase or advItem.IsBeast) {
		iLvlCheckState := TradeOpts.AdvancedSearchCheckILVL ? "Checked" : ""
		iLvlValue := advItem.iLvl 											; use itemlevel to fill the box in any case (elder/shaper/crusader/redeemer/hunter/warlord)
	}
	Else If (TradeOpts.AdvancedSearchCheckILVL) {
		iLvlCheckState := "Checked"
		iLvlValue		:= advItem.iLvl
	}
	Else {
		If (advItem.maxSockets > 1) {
			If (advItem.iLvl >= 50 and advItem.maxSockets > 5) {
				iLvlValue := 50
			} Else If (advItem.iLvl >= 35 and advItem.maxSockets > 4) {
				iLvlValue := 35
			} Else If (advItem.iLvl >= 25 and advItem.maxSockets > 3) {
				iLvlValue := 25
			} Else If (advItem.iLvl >= 2 and advItem.maxSockets > 2) {
				iLvlValue := 2
			}
			iLvlCheckState := "Checked"
		}
		Else {
			iLvlValue := advItem.iLvl
		}
	}
	Gui, SelectModsGui:Add, CheckBox, x%offsetX% yp%offsetY% vTradeAdvancedSelectedILvl %iLvlCheckState%, % "iLvl (min)"
	Gui, SelectModsGui:Add, Edit    , x+1 yp-3 w30 vTradeAdvancedMinILvl , % iLvlValue

	/*
		item base
		*/
		
	If (advItem.IsBeast) {
		baseCheckState := "Checked"
		Gui, SelectModsGui:Add, CheckBox, x+15 yp+3 vTradeAdvancedSelectedItemBase %baseCheckState%, % "Use Genus (" advItem.BeastData.Genus ")"
	} Else {
		baseCheckState := TradeOpts.AdvancedSearchCheckBase ? "Checked" : ""
		Gui, SelectModsGui:Add, CheckBox, x+15 yp+3 vTradeAdvancedSelectedItemBase %baseCheckState%, % "Use Item Base"
	}	

	If (advItem.specialBase) {
		If (not RegExMatch(advItem.specialBase,"i)fractured")) {
			Gui, SelectModsGui:Add, CheckBox, x+15 yp+0 vTradeAdvancedSelectedSpecialBase Checked, % advItem.specialBase 	
		} Else If (advItem.isFracturedBase) {
			Gui, SelectModsGui:Add, CheckBox, x+15 yp+0 vTradeAdvancedSelectedSpecialBase Checked, % advItem.specialBase 
		}		
	}

	If (Stats.QualityType) {
		Gui, SelectModsGui:Add, CheckBox, x+15 yp+0 vTradeAdvancedSelectedQualityType, % "Quality min % (" Stats.QualityType "): "
		Gui, SelectModsGui:Add, Edit    , x+1 yp-3 w30 vTradeAdvancedMinQuality, % Stats.Quality
	}

	/*
		veiled mods
		*/
	If (advItem.veiledPrefixCount) {
		Gui, SelectModsGui:Add, CheckBox, x15 yp+25 vTradeAdvancedSelectedVeiledPrefix Checked, % "Veiled Prefix"
		Gui, SelectModsGui:Add, Edit    , x+1 yp-3 w30 vTradeAdvancedVeiledPrefixCount        , % advItem.veiledPrefixCount
	}
	If (advItem.veiledSuffixCount) {
		voffsetX := advItem.veiledPrefixCount ? "+10" : "15"
		voffsetY := advItem.veiledPrefixCount ? "+3"  : "+25"
		Gui, SelectModsGui:Add, CheckBox, x%voffsetX% yp%voffsetY% vTradeAdvancedSelectedVeiledSuffix Checked, % "Veiled Suffix"
		Gui, SelectModsGui:Add, Edit    , x+1 yp-3 w30 vTradeAdvancedVeiledSuffixCount        , % advItem.veiledSuffixCount
	}

	/*
		corrupted state for jewels
		*/
	If (advItem.IsJewel and Item.IsCorrupted) {
		Gui, SelectModsGui:Add, CheckBox, x+15 yp+0 vTradeAdvancedSelectedCorruptedState Checked, % "Corrupted"
	}

	Item.UsedInSearch.SearchType := "Advanced"
	; closes this window and starts the search
	offset := (m > 1) ? "+25" : "+15"
	Gui, SelectModsGui:Add, Button, x10 y%offset% gAdvancedPriceCheckSearch hwndSearchBtnHwnd Default, &Search

	; open search on poe.trade instead
	Gui, SelectModsGui:Add, Button, x+10 yp+0 gAdvancedOpenSearchOnPoeTrade, Op&en on poe.trade

	; override online state
	Gui, SelectModsGui:Add, CheckBox, x+10 yp+5 vTradeAdvancedOverrideOnlineState, % "Show offline results"

	; add some widths and margins to align the checkox with the others on the right side
	RightPos := xPosMin + 40 + 5 + 45 + 10 + 45 + 10 + 40 + 5 + 45 + 10
	RightPosText := RightPos - 140
	Gui, SelectModsGui:Add, Text, x%RightPosText% yp+0 right w130, Check normal mods
	Gui, SelectModsGui:Add, CheckBox, x%RightPos% yp+0 %PreCheckNormalMods% vTradeAdvancedSelectedCheckAllMods gAdvancedCheckAllMods, % ""
	
	/*
		fractured mods
		*/
	If (advItem.isFracturedBase) {
		GuiAddText("Include fractured states", "x" RightPosText " y+10 right w130 0x0100", "LblFracturedInfo", "LblFracturedInfoH", "", "", "SelectModsGui")
		Gui, SelectModsGui:Add, CheckBox, x%RightPos% yp+0 vTradeAdvancedSelectedIncludeFractured gAdvancedIncludeFractured Checked, % " "	
		GuiAddPicture(A_ScriptDir "\resources\images\fractured-symbol.png", "xp+28 yp-" fracturedImageShift " w27 h-1 0x0100", "", "", "", "", "SelectModsGui")

		GuiAddPicture(A_ScriptDir "\resources\images\info-blue.png", "x+-" 193 " yp+" fracturedImageShift - 1 " w15 h-1 0x0100", "FracturedInfo", "FracturedInfoH", "", "", "SelectModsGui")
		AddToolTip(LblFracturedInfoH, "Includes selected fractured mods with their ""fractured"" porperty`n instead of as normal mods.")
		
		GuiAddText("Fractured mods count", "x" RightPosText " y+10 right w130 0x0100", "LblFracturedCount", "LblFracturedCountH", "", "", "SelectModsGui")
		Gui, SelectModsGui:Add, CheckBox, x%RightPos% yp+0 vTradeAdvancedSelectedFracturedCount Checked, % " "
		Gui, SelectModsGui:Add, Edit    , x+1 yp-4 w30 vTradeAdvancedFracturedCount , 
		GuiAddPicture(A_ScriptDir "\resources\images\info-blue.png", "x+-" 193 " yp+" 3 " w15 h-1 0x0100", "FracturedCount", "FracturedCountH", "", "", "SelectModsGui")
		AddToolTip(LblFracturedCountH, "The correct number of fractured mods can't be determined from the item data reliably.`n`nMake sure to check it by pressing ""Alt"" when hovering over your item, `nwhich requires ""Advanced Mod Descriptions"" to be enabled.")
	}

	If (ModNotFound) {
		Gui, SelectModsGui:Add, Picture, x10 y+16, %A_ScriptDir%\resources\images\error.png
		Gui, SelectModsGui:Add, Text, x+10 yp+2 cRed,One or more mods couldn't be found on poe.trade
	}
	Gui, SelectModsGui:Add, Text, x10 y+14 cGreen, Please support poe.trade by disabling adblock
	Gui, SelectModsGui:Add, Link, x+5 yp+0 cBlue, <a href="https://poe.trade">visit</a>
	Gui, SelectModsGui:Add, Text, x+10 yp+0 cGray, (Use Alt + S/E to submit a button)
	Gui, SelectModsGui:Add, Link, x10 yp+18 cBlue, <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4ZVTWJNH6GSME">Support PoE-TradeMacro</a>

	windowWidth := modGroupBox + 40 + 5 + 45 + 10 + 45 + 10 + 40 + 5 + 45 + 10 + 65
	windowWidth := advItem.isFracturedBase ? windowWidth + 20 : windowWidth
	windowWidth := (windowWidth > 510) ? windowWidth : 510
	AdvancedSearchLeagueDisplay := TradeGlobals.Get("LeagueName")
	Gui, SelectModsGui:Show, w%windowWidth% , Select Mods to include in Search - %AdvancedSearchLeagueDisplay%
}

TradeFunc_DetermineAdvancedSearchPreSelectedMods(advItem, ByRef Stats) {
	Global TradeOpts

	FlatMaxLifeSelected			:= 0
	PercentMaxLifeSelected		:= 0
	TotalEnergyShieldSelected	:= 0
	FlatEnergyShieldSelected		:= 0
	PercentEnergyShieldSelected	:= 0

	; make sure that normal mods aren't marked as selected if they are included in existing pseudo mods, for example life -> total life
	; and that mods aren't selected if they are included in defense stats, for example energy shield
	If (Stats.Defense.TotalEnergyShield.Value > 0 and TradeOpts.AdvancedSearchCheckTotalES) {
		Stats.Defense.TotalEnergyShield.PreSelected := 1
		TotalEnergyShieldSelected := 1
	}

	If (Stats.Offense.EleDps.Value > 0 and TradeOpts.AdvancedSearchCheckEDPS) {
		Stats.Offense.EleDps.PreSelected	:= 1
	}
	If (Stats.Offense.PhysDps.Value > 0 and TradeOpts.AdvancedSearchCheckPDPS) {
		Stats.Offense.PhysDps.PreSelected	:= 1
	}

	i := advItem.mods.maxIndex()
	Loop, % i {
		FlatLife		:= RegExMatch(advItem.mods[i].name, "i).* to maximum Life$")
		PercentLife	:= RegExMatch(advItem.mods[i].name, "i).* increased maximum Life$")
		FlatES		:= RegExMatch(advItem.mods[i].name, "i).* to maximum Energy Shield$")
		PercentES		:= RegExMatch(advItem.mods[i].name, "i).* increased maximum Energy Shield$")
		EleRes		:= RegExMatch(advItem.mods[i].name, "i).* total Elemental Resistance$")

		If (FlatLife and TradeOpts.AdvancedSearchCheckTotalLife and not FlatMaxLifeSelected) {
			advItem.mods[i].PreSelected	:= 1
			FlatMaxLifeSelected			:= 1
		}
		If (PercentLife and TradeOpts.AdvancedSearchCheckTotalLife and not PercentMaxLifeSelected) {
			advItem.mods[i].PreSelected	:= 1
			PercentMaxLifeSelected		:= 1
		}

		; only select flat ES/percent ES when no defense stat is present (for example on rings, belts, jewels, amulets)
		If ((FlatES or PercentES) and TradeOpts.AdvancedSearchCheckES and not TotalEnergyShieldSelected) {
			advItem.mods[i].PreSelected		:= 1
			If (FlatES) {
				FlatEnergyShieldSelected		:= 1
			} Else {
				PercentEnergyShieldSelected	:= 1
			}
		}

		If (EleRes and TradeOpts.AdvancedSearchCheckTotalEleRes) {
			advItem.mods[i].PreSelected	:= 1
		}

		i--
	}

	Return advItem
}

AdvancedCheckAllMods:
	ImplicitCount := TradeAdvancedImplicitCount
	EmptySelect := 0
	GuiControlGet, IsChecked, SelectModsGui:, TradeAdvancedSelectedCheckAllMods
	Loop, 20 {
		If ((A_Index) > (TradeAdvancedNormalModCount + ImplicitCount + EmptySelect) or (ImplicitCount = A_Index)) {
			continue
		}
		Else {
			state := IsChecked ? 1 : 0
			GuiControl, SelectModsGui:, TradeAdvancedSelected%A_Index%, %state%
			GuiControlGet, TempModName, SelectModsGui:, TradeAdvancedModName%A_Index%
			If (StrLen(TempModName) < 1) {
				EmptySelect++
			}
		}
	}
Return

AdvancedIncludeFractured:

Return

AdvancedPriceCheckSearch:
	TradeFunc_HandleGuiSubmit()
	TradeFunc_Main(false, false, true)
return

AdvancedOpenSearchOnPoeTrade:
	TradeFunc_HandleGuiSubmit()
	TradeFunc_Main(true, false, true)
return

TradeFunc_ResetGUI() {
	Global
	Loop {
		If (TradeAdvancedModMin%A_Index% or TradeAdvancedParam%A_Index%) {
			TradeAdvancedParam%A_Index%	:=
			TradeAdvancedSelected%A_Index%:=
			TradeAdvancedModMin%A_Index%	:=
			TradeAdvancedModMax%A_Index%	:=
			TradeAdvancedModName%A_Index%	:=
			TradeAdvancedIsFractured%A_Index% :=
			TradeAdvancedModNameRaw%A_index% :=
			TradeAdvancedModNameRawOrig%A_index% :=
		}
		Else If (A_Index >= 20) {
			TradeAdvancedStatCount :=
			break
		}
	}

	Loop {
		If (TradeAdvancedStatMin%A_Index% or TradeAdvancedStatParam%A_Index%) {
			TradeAdvancedStatParam%A_Index%	:=
			TradeAdvancedStatSelected%A_Index%	:=
			TradeAdvancedStatMin%A_Index%		:=
			TradeAdvancedStatMax%A_Index%		:=
		}
		Else If (A_Index >= 20) {
			TradeAdvancedModCount :=
			break
		}
	}

	TradeAdvancedUseSockets			:=
	TradeAdvancedUseLinks			:=
	TradeAdvancedUseSocketsMaxThree	:=
	TradeAdvancedUseLinksMaxThree		:=
	TradeAdvancedUseSocketsMaxFour	:=
	TradeAdvancedUseLinksMaxFour		:=
	TradeAdvancedSelectedILvl		:=
	TradeAdvancedMinILvl			:=
	TradeAdvancedSelectedItemBase		:=
	TradeAdvancedSelectedSpecialBase	:=
	TradeAdvancedSelectedCheckAllMods	:=
	TradeAdvancedImplicitCount		:=
	TradeAdvancedNormalModCount		:=
	TradeAdvancedOverrideOnlineState	:=
	TradeAdvancedUseAbyssalSockets	:=
	TradeAdvancedAbyssalSockets		:=
	TradeAdvancedSelectedCorruptedState:=	
	TradeAdvancedSelectedVeiledPrefix	:=
	TradeAdvancedVeiledPrefixCount	:=
	TradeAdvancedSelectedVeiledSuffix	:=
	TradeAdvancedVeiledSuffixCount	:=	
	TradeAdvancedSelectedIncludeFractured	:=	
	TradeAdvancedSelectedFracturedCount	:=	
	TradeAdvancedFracturedCount		:=	
	TradeAdvancedSelectedQualityType	:=	
	TradeAdvancedMinQuality			:=	

	TradeGlobals.Set("AdvancedPriceCheckItem", {})
}

TradeFunc_HandleGuiSubmit() {
	Global

	Gui, SelectModsGui:Submit
	newItem := {mods:[], stats:[], UsedInSearch : {}}
	mods  := []
	stats := []

	Loop {
		mod := {param:"",selected:"",min:"",max:""}
		If (TradeAdvancedSelected%A_Index%) {
			mod.param		:= TradeAdvancedParam%A_Index%
			mod.selected	:= TradeAdvancedSelected%A_Index%
			mod.min		:= TradeAdvancedModMin%A_Index%
			mod.max		:= TradeAdvancedModMax%A_Index%
			mod.name		:= TradeAdvancedModNameRaw%A_Index%
			mod.name_orig	:= TradeAdvancedModNameRawOrig%A_Index%
			; has Enchantment
			If (RegExMatch(TradeAdvancedParam%A_Index%, "i)enchant") and mod.selected) {
				newItem.UsedInSearch.Enchantment := true
			}
			; has Corrupted Implicit
			Else If (TradeAdvancedIsImplicit%A_Index% and mod.selected) {
				newItem.UsedInSearch.CorruptedMod := true
			}
			; fractured mod
			If (TradeAdvancedIsFractured%A_Index% = "1" or TradeAdvancedIsFractured%A_Index% = 1) {
				mod.spawntype := "fractured"
			}

			mods.Push(mod)
		}
		Else If (A_Index >= 20) {
			break
		}
	}

	Loop {
		stat := {param:"",selected:"",min:"",max:""}
		If (TradeAdvancedStatMin%A_Index% or TradeAdvancedStatMax%A_Index%) {
			stat.param    := TradeAdvancedStatParam%A_Index%
			stat.selected := TradeAdvancedStatSelected%A_Index%
			stat.min      := TradeAdvancedStatMin%A_Index%
			stat.max      := TradeAdvancedStatMax%A_Index%

			stats.Push(stat)
		}
		Else If (A_Index >= 20) {
			break
		}
	}

	newItem.mods				:= mods
	newItem.stats				:= stats
	newItem.useSockets			:= TradeAdvancedUseSockets
	newItem.useLinks			:= TradeAdvancedUseLinks
	newItem.useSocketsMaxThree	:= TradeAdvancedUseSocketsMaxThree
	newItem.useLinksMaxThree		:= TradeAdvancedUseLinksMaxThree
	newItem.useSocketsMaxFour	:= TradeAdvancedUseSocketsMaxFour
	newItem.useLinksMaxFour		:= TradeAdvancedUseLinksMaxFour
	newItem.useIlvl			:= TradeAdvancedSelectedILvl
	newItem.minIlvl			:= TradeAdvancedMinILvl
	newItem.useBase			:= TradeAdvancedSelectedItemBase
	newItem.useSpecialBase		:= TradeAdvancedSelectedSpecialBase
	newItem.onlineOverride		:= TradeAdvancedOverrideOnlineState
	newItem.corruptedOverride	:= TradeAdvancedSelectedCorruptedState
	newItem.useAbyssalSockets 	:= TradeAdvancedUseAbyssalSockets
	newItem.abyssalSockets		:= TradeAdvancedAbyssalSockets	
	newItem.useVeiledPrefix		:= TradeAdvancedSelectedVeiledPrefix
	newItem.veiledPrefixCount	:= TradeAdvancedVeiledPrefixCount
	newItem.useVeiledSuffix		:= TradeAdvancedSelectedVeiledSuffix
	newItem.veiledSuffixCount	:= TradeAdvancedVeiledSuffixCount
	newItem.includeFractured		:= TradeAdvancedSelectedIncludeFractured
	newItem.includeFracturedCount	:= TradeAdvancedSelectedFracturedCount
	newItem.fracturedCount		:= TradeAdvancedFracturedCount
	newItem.minQuality			:= TradeAdvancedMinQuality
	newItem.useQualityType		:= TradeAdvancedSelectedQualityType

	TradeGlobals.Set("AdvancedPriceCheckItem", newItem)
	Gui, SelectModsGui:Destroy
	TradeFunc_ActivatePoeWindow()
}

class TradeUtils {
	; also see https://github.com/ahkscript/awesome-AutoHotkey
	; and https://autohotkey.com/boards/viewtopic.php?f=6&t=53
	IsArray(obj) {
		Return !!obj.MaxIndex()
	}
	
	; careful : circular references crash the script.
	; https://autohotkey.com/board/topic/69542-objectclone-doesnt-create-a-copy-keeps-references/#entry440561
	ObjFullyClone(obj)
	{
		nobj := obj.Clone()
		for k,v in nobj
			if IsObject(v)
				nobj[k] := A_ThisFunc.(v)
		return nobj
	}

	; Trim trailing zeros from numbers
	ZeroTrim(number) {
		RegExMatch(number, "(\d+)\.?(.+)?", match)
		If (StrLen(match2) < 1) {
			Return number
		} Else {
			trail := RegExReplace(match2, "0+$", "")
			number := (StrLen(trail) > 0) ? match1 "." trail : match1
			Return number
		}
	}

	IsInArray(el, array) {
		For i, element in array {
			If (el = "") {
				Return false
			}
			If (element = el) {
				Return true
			}
		}
		Return false
	}

	CleanUp(in) {
		StringReplace, in, in, `n,, All
		StringReplace, in, in, `r,, All
		Return Trim(in)
	}


	Arr_concatenate(p*) {
		res := Object()
		For each, obj in p
			For each, value in obj
				res.Insert(value)
		return res
	}

	; ------------------------------------------------------------------------------------------------------------------ ;
	; TradeUtils.StrX Function for parsing html, see simple example usage at https://gist.github.com/thirdy/9cac93ec7fd947971721c7bdde079f94
	; ------------------------------------------------------------------------------------------------------------------ ;

	; Cleanup TradeUtils.StrX Function and Google Example from https://autohotkey.com/board/topic/47368-TradeUtils.StrX-auto-parser-for-xml-html
	; By SKAN

	;1 ) H = HayStack. The "Source Text"
	;2 ) BS = BeginStr. Pass a String that will result at the left extreme of Resultant String
	;3 ) BO = BeginOffset.
	; Number of Characters to omit from the left extreme of "Source Text" while searching for BeginStr
	; Pass a 0 to search in reverse ( from right-to-left ) in "Source Text"
	; If you intend to call TradeUtils.StrX() from a Loop, pass the same variable used as 8th Parameter, which will simplify the parsing process.
	;4 ) BT = BeginTrim.
	; Number of characters to trim on the left extreme of Resultant String
	; Pass the String length of BeginStr If you want to omit it from Resultant String
	; Pass a Negative value If you want to expand the left extreme of Resultant String
	;5 ) ES = EndStr. Pass a String that will result at the right extreme of Resultant String
	;6 ) EO = EndOffset.
	; Can be only True or False.
	; If False, EndStr will be searched from the end of Source Text.
	; If True, search will be conducted from the search result offset of BeginStr or from offset 1 whichever is applicable.
	;7 ) ET = EndTrim.
	; Number of characters to trim on the right extreme of Resultant String
	; Pass the String length of EndStr If you want to omit it from Resultant String
	; Pass a Negative value If you want to expand the right extreme of Resultant String
	;8 ) NextOffset : A name of ByRef Variable that will be updated by TradeUtils.StrX() with the current offset, You may pass the same variable as Parameter 3, to simplify data parsing in a loop

	StrX(H,  BS="",BO=0,BT=1,   ES="",EO=0,ET=1,  ByRef N="" )
	{
		Return SubStr(H,P:=(((Z:=StrLen(ES))+(X:=StrLen(H))+StrLen(BS)-Z-X)?((T:=InStr(H,BS,0,((BO
            <0)?(1):(BO))))?(T+BT):(X+1)):(1)),(N:=P+((Z)?((T:=InStr(H,ES,0,((EO)?(P+1):(0))))?(T-P+Z
		+(0-ET)):(X+P)):(X)))-P)
	}
	; v1.0-196c 21-Nov-2009 www.autohotkey.com/forum/topic51354.html
	; | by Skan | 19-Nov-2009


	; ------------------------------------------------------------------------------------------------------------------ ;
	; TradeUtils.HtmlParseItemData, alternative Function for parsing html with simple regex
	; ------------------------------------------------------------------------------------------------------------------ ;

	HtmlParseItemData(ByRef html, regex, ByRef htmlOut = "", leftOffset = 0) {
		; last capture group captures the remaining string
		Pos := RegExMatch(html, "isO)" . regex . "(.*)", match)

		If (match.count() >= 2) {
			htmlOut := match[match.count()]
		}
		If (Pos and leftOffset) {
			offset  := SubStr(html, Pos - leftOffset, leftOffset)
			htmlOut := offset . htmlOut
		}
		Return match.value(1)
	}

	UriEncode(Uri, Enc = "UTF-8")
	{
		TradeUtils.StrPutVar(Uri, Var, Enc)
		f := A_FormatInteger
		SetFormat, IntegerFast, H
		Loop
		{
			Code := NumGet(Var, A_Index - 1, "UChar")
			If (!Code)
				Break
			If (Code >= 0x30 && Code <= 0x39 ; 0-9
				|| Code >= 0x41 && Code <= 0x5A ; A-Z
				|| Code >= 0x61 && Code <= 0x7A) ; a-z
				Res .= Chr(Code)
			Else
				Res .= "%" . SubStr(Code + 0x100, -1)
		}
		SetFormat, IntegerFast, %f%
		Return, Res
	}

	UriDecode(Uri, Enc = "UTF-8")
	{
		Pos := 1
		Loop
		{
			Pos := RegExMatch(Uri, "i)(?:%[\da-f]{2})+", Code, Pos++)
			If (Pos = 0)
				Break
			VarSetCapacity(Var, StrLen(Code) // 3, 0)
			StringTrimLeft, Code, Code, 1
			Loop, Parse, Code, `%
				NumPut("0x" . A_LoopField, Var, A_Index - 1, "UChar")
			StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, Enc), All
		}
		Return, Uri
	}

	StrPutVar(Str, ByRef Var, Enc = "")
	{
		Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
		VarSetCapacity(Var, Len, 0)
		Return, StrPut(Str, &Var, Enc)
	}
}

OverwriteSettingsWidthTimer:
	o := Globals.Get("SettingsUIWidth")

	If (o) {
		Globals.Set("SettingsUIWidth", 963)
		SetTimer, OverwriteSettingsWidthTimer, Off
	}
Return

OverwriteSettingsHeightTimer:
	o := Globals.Get("SettingsUIHeight")

	If (o) {
		Globals.Set("SettingsUIHeight", 665)
		SetTimer, OverwriteSettingsHeightTimer, Off
	}
Return

OverwriteAboutWindowSizesTimer:
	o := Globals.Get("AboutWindowHeight")
	l := Globals.Get("AboutWindowWidth")

	If (o and l) {
		Globals.Set("AboutWindowHeight", 400)
		Globals.Set("AboutWindowWidth", 880)
		TradeFunc_CreateTradeAboutWindow()
		SetTimer, OverwriteAboutWindowSizesTimer, Off
	}
Return

ChangeScriptListsTimer:
	o := Globals.Get("ScriptList")
	l := Globals.Get("UpdateNoteFileList")

	If (o and l.Length()) {
		o.push(A_ScriptDir "\TradeMacroMain")
		o.push(A_ScriptDir "\PoE-TradeMacro_(Fallback)")
		Global.Set("ScriptList", o)

		l.push([A_ScriptDir "\resources\Updates_Trade.txt","TradeMacro"])
		Global.Set("UpdateNoteFileList", l)

		SetTimer, ChangeScriptListsTimer, Off
	}
Return

OverwriteSettingsNameTimer:
	o := Globals.Get("SettingsUITitle")

	If (o) {
		RelVer := TradeGlobals.Get("ReleaseVersion")
		TradeFunc_SetMenuTrayTip("Path of Exile TradeMacro - " RelVer)
		If (TradeOpts.SearchLeague) {
			_l := ""
			If (TradeGlobals.Get("Leagues")[SearchLeague]) {
				_l := " (" TradeGlobals.Get("Leagues")[SearchLeague] ")"
			}
			TradeFunc_SetMenuTrayTip("`nSelected league: """ TradeOpts.SearchLeague """" _l, true)
		}

		OldMenuTrayName := Globals.Get("SettingsUITitle")
		NewMenuTrayName := TradeGlobals.Get("SettingsUITitle")
		Menu, Tray, UseErrorLevel
		Menu, Tray, Rename, % OldMenuTrayName, % NewMenuTrayName
		If (ErrorLevel = 0) {
			Menu, Tray, Icon, %A_ScriptDir%\resources\images\poe-trade-bl.ico
			Globals.Set("SettingsUITitle", TradeGlobals.Get("SettingsUITitle"))
			SetTimer, OverwriteSettingsNameTimer, Off
		}
		Menu, Tray, UseErrorLevel, off
	}
Return

TradeFunc_SetMenuTrayTip(msg, append := false) {
	_TrayTip := ""
	If (not append) {
		TradeGlobals.Set("TrayTip", msg)
		_TrayTip := TradeGlobals.Get("TrayTip")
	} Else {
		_TrayTip := TradeGlobals.Get("TrayTip") . msg
		TradeGlobals.Set("TrayTip", _TrayTip)
	}	
	Menu, Tray, Tip, %_TrayTip%
}

OverwriteUpdateOptionsTimer:
	If (InititalizedItemInfoUserOptions) {
		TradeFunc_SyncUpdateSettings()
	}
Return

CheckForUpdatesTimer:
	PoEScripts_Update(globalUpdateInfo.user, globalUpdateInfo.repo, globalUpdateInfo.releaseVersion, ShowUpdateNotification, userDirectory, isDevVersion, globalUpdateInfo.skipSelection, globalUpdateInfo.skipBackup, SplashScreenTitle, TradeOpts.Debug, true)
Return

BringPoEWindowToFrontAfterInit:
	TradeFunc_ActivatePoeWindow()
	SetTimer, BringPoEWindowToFrontAfterInit, OFF
Return

OpenGithubWikiFromMenu:
	repo := TradeGlobals.Get("GithubRepo")
	user := TradeGlobals.Get("GithubUser")
	TradeFunc_OpenUrlInBrowser("https://github.com/" user "/" repo "/wiki")
Return

OpenPayPal:
	url := "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4ZVTWJNH6GSME"
	TradeFunc_OpenUrlInBrowser(url)
Return

TradeSettingsUI_BtnOK:
	Global TradeOpts
	Gui, SettingsUI:Submit
	SavedTradeSettings := true
	Sleep, 50
	WriteTradeConfig()
	UpdateTradeSettingsUI()
Return

TradeSettingsUI_BtnCancel:
	Gui, SettingsUI:Cancel
Return

TradeSettingsUI_BtnDefaults:
	Gui, SettingsUI:Cancel
	Sleep, 75
	ReadTradeConfig(A_ScriptDir "\resources\default_UserFiles")
	Sleep, 75
	UpdateTradeSettingsUI()
	ShowSettingsUI()
Return

TradeSettingsUI_BtnRestoreAlternativeHotkeys:
	Gui, SettingsUI:Cancel
	Sleep, 75
	ReadTradeConfig(A_ScriptDir "\resources\default_UserFiles")
	Sleep, 75
	RestoreAlternativeHotkeys()
	ShowSettingsUI()
Return

TradeSettingsUI_ChkCorruptedOverride:
	GuiControlGet, IsChecked,, CorruptedOverride
	If (Not IsChecked) {
		GuiControl, Disable, Corrupted
	}
	Else	{
		GuiControl, Enable, Corrupted
	}
Return

ReadPoeNinjaCurrencyData:
	/*
		https://poe.ninja/swagger/
	*/

	; Disable hotkey until currency data was parsed
	key := TradeOpts.ChangeLeagueHotKey
	loggedCurrencyRequestAtStartup := loggedCurrencyRequestAtStartup ? loggedCurrencyRequestAtStartup : false
	loggedTempLeagueCurrencyRequest := loggedTempLeagueCurrencyRequest ? loggedTempLeagueCurrencyRequest : false
	usedFallback := false
	
	If (TempChangingLeagueInProgress) {
		ShowToolTip("Changing league to " . TradeOpts.SearchLeague " (" . TradeGlobals.Get("LeagueName") . ")...", true)
	}
	sampleValue	:= ChaosEquivalents["Chaos Orb"]
	league		:= TradeUtils.UriEncode(TradeGlobals.Get("LeagueName"))
	fallback		:= ""
	isFallback	:= false
	file			:= A_ScriptDir . "\temp\currencyData.json"
	fallBackDir	:= A_ScriptDir . "\data_trade"
	url			:= "https://poe.ninja/api/data/CurrencyOverview?league=" . league . "&type=Currency"

	parsedJSON	:= CurrencyDataDownloadURLtoJSON(url, sampleValue, false, isFallback, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, loggedCurrencyRequestAtStartup, loggedTempLeagueCurrencyRequest, TradeOpts.CurlTimeout)

	mapUrl		:= "https://poe.ninja/api/data/ItemOverview?league=" . league . "&type=Map"
	parsedMapJSON	:= PoENinjaPriceDataDownloadURLtoJSON(mapUrl, "map", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
	
	fossilUrl		:= "https://poe.ninja/api/data/ItemOverview?league=" . league . "&type=Fossil"
	parsedFossilJSON	:= PoENinjaPriceDataDownloadURLtoJSON(fossilUrl, "fossil", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
	
	/*
	scarabUrl		:= "https://poe.ninja/api/data/itemoverview?=" . league . "&type=Scarab"
	parsedScarabJSON	:= PoENinjaPriceDataDownloadURLtoJSON(scarabUrl, "scarab", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
	
	essenceUrl		:= "https://poe.ninja/api/data/itemoverview?=" . league . "&type=Essence"
	parsedEssenceJSON	:= PoENinjaPriceDataDownloadURLtoJSON(essenceUrl, "essence", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
	
	fragmentUrl		:= "https://poe.ninja/api/data/itemoverview?=" . league . "&type=Fragment"
	parsedFragmentJSON	:= PoENinjaPriceDataDownloadURLtoJSON(fragmentUrl, "fragment", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
	*/

	; fallback to Standard and Hardcore league if used league seems to not be available
	If (not parsedJSON.currencyDetails.length() or not parsedMapJSON.lines.length()) {
		isFallback	:= true
		If (InStr(league, "Hardcore", 0) or RegExMatch(league, "HC")) {
			league	:= "Hardcore"
			fallback	:= "Hardcore"
		} Else {
			league	:= "Standard"
			fallback	:= "Standard"
		}
		
		If (not parsedJSON.currencyDetails.length()) {
			url			:= "https://poe.ninja/api/data/CurrencyOverview?league=" . league . "&type=Currency"
			parsedJSON	:= CurrencyDataDownloadURLtoJSON(url, sampleValue, true, isFallback, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, loggedCurrencyRequestAtStartup, loggedTempLeagueCurrencyRequest, TradeOpts.CurlTimeout)	
		}
		If (not parsedMapJSON.lines.length()) {
			mapUrl		:= "https://poe.ninja/api/data/ItemOverview?league=" . league . "&type=Map"
			parsedMapJSON	:= PoENinjaPriceDataDownloadURLtoJSON(mapUrl, "map", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
		}
		If (not parsedFossilJSON.lines.length()) {
			fossilUrl		:= "https://poe.ninja/api/data/ItemOverview?league=" . league . "&type=Fossil"
			parsedFossilJSON	:= PoENinjaPriceDataDownloadURLtoJSON(fossilUrl, "fossil", true, false, league, "PoE-TradeMacro", file, fallBackDir, usedFallback, TradeOpts.CurlTimeout)
		}
	}
	global CurrencyHistoryData := parsedJSON.lines
	global MapHistoryData := parsedMapJSON.lines
	global FossilHistoryData := parsedFossilJSON.lines
	TradeGlobals.Set("LastAltCurrencyUpdate", A_NowUTC)
	
	global ChaosEquivalents	:= {}
	For key, val in CurrencyHistoryData {
		currencyBaseName	:= RegexReplace(val.currencyTypeName, "[^a-z A-Z]", "")
		ChaosEquivalents[currencyBaseName] := val.chaosEquivalent
	}
	ChaosEquivalents["Chaos Orb"] := 1

	If (TempChangingLeagueInProgress) {
		msg := "Changing league to " . TradeOpts.SearchLeague " (" . TradeGlobals.Get("LeagueName") . ") finished."
		msg .= "`n- Requested chaos equivalents and currency history from poe.ninja."
		msg .= StrLen(fallback) ? "`n- Using data from " fallback " league since the requested data is not available." : ""
		ShowToolTip(msg, true)
	}

	TempChangingLeagueInProgress := False
Return

CloseCookieWindow:
	Gui, CookieWindow:Cancel
Return

ContinueAtConnectionFailure:
	Gui, ConnectionFailure:Cancel
Return

OpenCookieFile:
	Run, %A_ScriptDir%\temp\cookie_data.txt
Return

DeleteCookies:
	TradeFunc_ClearWebHistory()
	Run, Run_TradeMacro.ahk
	ExitApp
Return

OpenPageInInternetExplorer:
	RegRead, iexplore, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\iexplore.exe
	Run, %iexplore% https://poe.trade
Return

ReloadScriptAtCookieError:
	scriptName := "Run_TradeMacro.ahk"
	Run, "%A_AhkPath%" "%A_ScriptDir%\%scriptName%"
Return

TradeAboutDlg_GitHub:
	repo := TradeGlobals.Get("GithubRepo")
	user := TradeGlobals.Get("GithubUser")
	TradeFunc_OpenUrlInBrowser("https://github.com/" user "/" repo)
Return

TradeVisitForumsThread:
	TradeFunc_OpenUrlInBrowser("https://www.pathofexile.com/forum/view-thread/1757730")
Return

CloseCustomSearch:
	TradeFunc_ResetCustomSearchGui()
	Gui, CustomSearch:Destroy
	TradeFunc_ActivatePoeWindow()
Return

TradeFunc_ResetCustomSearchGui() {
	CustomSearchName		:=
	CustomSearchType		:=
	CustomSearchBase		:=
	CustomSearchRarity		:=
	CustomSearchCorrupted	:=
	CustomSearchSocketsMin	:=
	CustomSearchSocketsMax	:=
	CustomSearchLinksMin	:=
	CustomSearchLinksMax	:=
	CustomSearchQualityMin	:=
	CustomSearchQualityMax	:=
	CustomSearchLevelMin	:=
	CustomSearchLevelMax	:=
	CustomSearchItemLevelMin	:=
	CustomSearchItemLevelMax	:=
}

OpenCustomSearchOnPoeTrade:
	TradeFunc_HandleCustomSearchSubmit(true)
Return

SubmitCustomSearch:
	TradeFunc_HandleCustomSearchSubmit()
Return

DebugTestItemPricing:
	TradeFunc_CreateItemPricingTestGUI()
Return

ClosePricingTest:
	PricingTestItemInput :=
	Gui, PricingTest:Destroy
Return

OpenPricingTestOnPoeTrade:
	Gui, PricingTest:Submit, Nohide
	TradeFunc_OpenSearchOnPoeTradeHotkey(true, PricingTestItemInput)
Return

SubmitPricingTestDefault:
	Gui, PricingTest:Submit, Nohide
	TradeFunc_PriceCheckHotkey(true, PricingTestItemInput)
Return

SubmitPricingTestAdvanced:
	Gui, PricingTest:Submit, Nohide
	TradeFunc_AdvancedPriceCheckHotkey(true, PricingTestItemInput)
Return

SubmitPricingTestWiki:
	Gui, PricingTest:Submit, Nohide
	TradeFunc_OpenWikiHotkey(true, PricingTestItemInput)
Return

SubmitPricingTestParsing:
	Gui, PricingTest:Submit, Nohide
	SuspendPOEItemScript = 1
	Clipboard := PricingTestItemInput
	ParseClipBoardChanges(true)
	SuspendPOEItemScript = 0
Return

SubmitPricingTestParsingObject:
	Gui, PricingTest:Submit, Nohide
	SuspendPOEItemScript = 1
	Clipboard := PricingTestItemInput
	ParseClipBoardChanges(true)
	DebugTmpObject			:= {}
	DebugTmpObject.Item		:= Item
	DebugTmpObject.ItemData	:= ItemData
	DebugPrintArray(DebugTmpObject)
	SuspendPOEItemScript = 0
Return

TradeFunc_HandleCustomSearchSubmit(openInBrowser = false) {
	Global
	Gui, CustomSearch:Submit

	If (CustomSearchName or CustomSearchType or CustomSearchBase) {
		RequestParams := new RequestParams_()
		LeagueName := TradeGlobals.Get("LeagueName")
		RequestParams.name   := CustomSearchName
		RequestParams.league := LeagueName
		Item.Name := CustomSearchName

		StringLower, CustomSearchRarity, CustomSearchRarity

		RequestParams.xtype		:= CustomSearchType         ? CustomSearchType : ""
		RequestParams.xbase		:= CustomSearchBase         ? CustomSearchBase : ""
		RequestParams.rarity	:= CustomSearchRarity       ? CustomSearchRarity : ""
		RequestParams.link_min	:= CustomSearchLinksMin     ? CustomSearchLinksMin : ""
		RequestParams.link_max	:= CustomSearchLinksMax     ? CustomSearchLinksMax : ""
		RequestParams.q_min		:= CustomSearchQualityMin   ? CustomSearchQualityMin : ""
		RequestParams.q_max		:= CustomSearchQualityMax   ? CustomSearchQualityMax : ""
		RequestParams.sockets_min:= CustomSearchSocketsMin   ? CustomSearchSocketsMin : ""
		RequestParams.sockets_max:= CustomSearchSocketsMax   ? CustomSearchSocketsMax : ""
		RequestParams.level_min 	:= CustomSearchLevelMin     ? CustomSearchLevelMin : ""
		RequestParams.level_max	:= CustomSearchLevelMax     ? CustomSearchLevelMax : ""
		RequestParams.ilvl_min 	:= CustomSearchItemLevelMin ? CustomSearchItemLevelMin : ""
		RequestParams.ilvl_max 	:= CustomSearchItemLevelMax ? CustomSearchItemLevelMax : ""

		If (CustomSearchCorrupted = "Yes") {
			RequestParams.corrupted := "1"
		} Else If (CustomSearchCorrupted = "No") {
			RequestParams.corrupted := "0"
		} Else {
			RequestParams.corrupted := "x"
		}
		Item.UsedInSearch.Corruption := CustomSearchCorrupted

		Payload := RequestParams.ToPayload()
		If (openInBrowser) {
			ShowToolTip("")
			Html := TradeFunc_DoPostRequest(Payload, true)
			RegExMatch(Html, "i)href=""\/(search\/.*?)\/live", ParsedUrl)
			TradeFunc_OpenUrlInBrowser("https://poe.trade/" ParsedUrl1)
		}
		Else {
			ShowToolTip("Requesting search results... ")
			Html := TradeFunc_DoPostRequest(Payload)
			ParsedData := TradeFunc_ParseHtml(Html, Payload)
			SetClipboardContents(ParsedData)

			ShowToolTip("")
			ShowToolTip(ParsedData, true)
		}
	}
	GoSub, CloseCustomSearch
}

TradeFunc_ChangeLeague() {
	Global
	If (TempChangingLeagueInProgress = true) {
		; Return while league is being changed in case of enabled alternative currency search.
		; Downloading and parsing the data from poe.ninja takes a moment.
		Return
	}

	leagues := TradeGlobals.Get("Leagues")

	index:= 0
	i	:= 0
	For key, val in leagues {
		i++
		If (SearchLeague == key) {
			index := i
		}
	}
	j	:= 0
	first:= ""
	next := ""
	For key, val in leagues {
		j++
		If (j = i) {
			first:= key
		}
		If ((index - 1) = j) {
			next	:= key
		}
	}

	NewSearchLeague := (next) ? next : first
	; Call Submit for the settings UI, otherwise we can't set the new league if the UI was last closed via close button or "x"
	Gui, SettingsUI:Submit
	SearchLeague := TradeFunc_CheckIfLeagueIsActive(NewSearchLeague)
	TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[SearchLeague])
	WriteTradeConfig()
	UpdateTradeSettingsUI()

	If (TradeOpts.SearchLeague) {
		RelVer := TradeGlobals.Get("ReleaseVersion")
		_l := "Selected league: """ TradeOpts.SearchLeague """"
		If (TradeGlobals.Get("Leagues")[SearchLeague]) {			
			_l .= " (" TradeGlobals.Get("Leagues")[SearchLeague] ")"
		}		
		TradeFunc_SetMenuTrayTip("Path of Exile TradeMacro - " RelVer "`n" _l)
	}

	TempChangingLeagueInProgress := True
	GoSub, ReadPoeNinjaCurrencyData
}

TradeFunc_PreventClipboardGarbageAfterInit() {
	Global
	
	If (not TradeGlobals.Get("FirstSearchTriggered")) {
		Clipboard := ""
	}
	TradeGlobals.Set("FirstSearchTriggered", true)
}

ResetWinHttpProxy:
	PoEScripts_RunAsAdmin()
	RunWait %comspec% /c netsh winhttp reset proxy ,,Hide
	Run, "%A_AhkPath%" "%A_ScriptDir%\Run_TradeMacro.ahk"
	ExitApp
Return

TrackUserCount:
	Run, "%A_AhkPath%" "%A_ScriptDir%\lib\IEComObjectTestCall.ahk" "%userDirectory%"
Return

Kill_CookieDataExe:
	Try {
		WinKill % "ahk_pid " cdePID
	} Catch e {

	}
	SetTimer, Kill_CookieDataExe, Off
Return

SelectModsGuiGuiEscape:
	; trademacro advanced search 
	Gui, SelectModsGui:Cancel
	TradeFunc_ActivatePoeWindow()
Return

CustomSearchGuiEscape:
	Gui, CustomSearch:Cancel
	TradeFunc_ActivatePoeWindow()
Return

CurrencyRatioGuiEscape:
	Gui, CurrencyRatio:Cancel
	TradeFunc_ActivatePoeWindow()
Return

PricingTestGuiEscape:
	Gui, PricingTest:Cancel
	TradeFunc_ActivatePoeWindow()
Return

CookieWindowGuiEscape:
	Gui, CookieWindow:Cancel
Return

ConnectionFailureGuiEscape:
	Gui, ConnectionFailure:Cancel
Return

PredictedPricingGuiEscape:
	Gui, PredictedPricing:Destroy
	TradeFunc_ActivatePoeWindow()
Return

PredictedPricingClose:
	Gui, PredictedPricing:Destroy
	TradeFunc_ActivatePoeWindow()
Return

PredictedPricingSendFeedback:
	Gui, PredictedPricing:Submit, NoHide
	If (PredictionPricingRadio1 or PredictionPricingRadio2 or PredictionPricingRadio3) {
		Gui, PredictedPricing:Destroy
	} Else {
		GuiControl, Show, % PredictedPricingHiddenControl1
		GuiControl, Show, % PredictedPricingHiddenControl2
		Return
	}

	TradeFunc_ActivatePoeWindow()
	_rating := ""
	If (PredictionPricingRadio1) {
		_rating := "Low"
	} Else If (PredictionPricingRadio2) {
		_rating := "Fair"
	} Else If (PredictionPricingRadio3) {
		_rating := "High"
	}
	
	_prices := {}
	_prices.min := PredictedPricingMin
	_prices.max := PredictedPricingMax
	_prices.currency := PredictedPricingCurrency
	TradeFunc_PredictedPricingSendFeedback(_rating, PredictedPricingComment, PredictedPricingEncodedData, PredictedPricingLeague, _prices)
Return

SelectCurrencyRatioPreview:
	Gui, CurrencyRatio:Submit, NoHide
	TradeFunc_SelectCurrencyRatio(SelectCurrencyRatioSellCurrency, SelectCurrencyRatioSellAmount, SelectCurrencyRatioReceiveCurrency, SelectCurrencyRatioReceiveAmount, SelectCurrencyRatioReceiveRatio, true)
Return

SelectCurrencyRatioSubmit:
	Gui, CurrencyRatio:Submit
	TradeFunc_SelectCurrencyRatio(SelectCurrencyRatioSellCurrency, SelectCurrencyRatioSellAmount, SelectCurrencyRatioReceiveCurrency, SelectCurrencyRatioReceiveAmount, SelectCurrencyRatioReceiveRatio)
Return

TradeFunc_SelectCurrencyRatio(typeSell, amountSell, typeReceive, amountReceive, ratioReceive, isPreview = false) {
	tags := TradeGlobals.Get("CurrencyTags")
	
	id := ""
	For key, category in tags {
		For k, type in category {
			If (type.text = typeReceive or type.short = typeReceive) {
				id := type.id
			}
		}
	}
	
	note := "~price "
	If (not ratioReceive) {
		amountReceive := Round(amountReceive)
		amountSell := Round(amountSell)
		ratio1 := TradeUtils.ZeroTrim(Round(amountReceive / amountSell, 4))
		ratio2 := TradeUtils.ZeroTrim(Round(amountSell / amountReceive, 4))
		note .= amountReceive "/" amountSell " " id
	} Else {
		ratioReceive := RegExReplace(ratioReceive, ",", ".")
		ratio1 := ratioReceive
		ratio2 := TradeUtils.ZeroTrim(Round(1 / ratioReceive, 4))

		; loop over the sell amount, increasing and decreasing it until we get an integer receive amount (rounded 3 decimals).
		sVHi := amountSell
		sVLow := amountSell
		loops := 0
		Loop {
			rVHi := TradeUtils.ZeroTrim(Round(sVHi / ratio2, 3))
			rVLow := TradeUtils.ZeroTrim(Round(sVLow / ratio2, 3))
			
			If (RegExMatch(rVHi, "^\d+$")) {
				receiveValue := rVHi
				sellValue := sVHi
			} Else If (RegExMatch(rVLow, "^\d+$")) {
				receiveValue := rVLow	
				sellValue := sVLow
			}	
			
			sVHi++			
			If (A_Index & 0) {
				; decrease the sell amount only on even loops
				sVLow := sVLow > 1 ? sVLow - 1 : sVLow	
			}			
			loops := A_Index
		} Until receiveValue
		
		note .= receiveValue "/" sellValue " " id
	}
	
	If (not isPreview) {		
		Clipboard := note
		msg := "Copied note """ note """ to the clipboard"
		msg := loops > 1 ? msg " after changing the sell amount to better fit the ratio." : msg "."		
	}
	Else {
		msg := "Note preview """ note """ created"
		msg := loops > 1 ? msg " after changing the sell amount to better fit the ratio." : msg "." 
	}
	
	msg .= "`n`n" "This is equivalent to a ratio of:"
	msg .= "`n"   "    [" typeSell "]  1 : " ratio1 "  [" typeReceive "]"
	msg .= "`n"   "    [" typeSell "]  " ratio2 " : 1  [" typeReceive "]"
	ShowTooltip(msg)
	
	Return
}

TradeFunc_PredictedPricingSendFeedback(selector, comment, encodedData, league, price) {
	postData 	:= ""
	postData := selector ? postData "selector=" UriEncode(Trim(selector)) "&" : postData
	postData := comment ? postData "feedbacktxt=" UriEncode(comment) "&" : postData
	postData := encodedData ? postData "qitem_txt=" encodedData "&" : postData
	postData := price.min ? postData "min=" UriEncode(price.min "") "&" : postData
	postData := price.max ? postData "max=" UriEncode(price.max "") "&" : postData
	postData := price.currency ? postData "currency=" UriEncode(price.currency "") "&" : postData
	postData := league ? postData "league=" UriEncode(league) "&" : postData
	postData := postData "source=" UriEncode("poetrademacro") "&"

	If (TradeOpts.Debug) {
		postData := postData "debug=1" "&"	
	}
	postData := RegExReplace(postData, "(\&)$")

	payLength	:= StrLen(postData)
	url 		:= "https://www.poeprices.info/send_feedback"
	options	:= "ReturnHeaders: skip"
	options	.= "`n" "ValidateResponse: false"
	
	reqHeaders	:= []
	reqHeaders.push("Connection: keep-alive")
	reqHeaders.push("Cache-Control: max-age=0")
	reqHeaders.push("Origin: https://poeprices.info")
	reqHeaders.push("Content-type: application/x-www-form-urlencoded; charset=UTF-8")
	reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")

	response := PoEScripts_Download(url, postData, reqHeaders, options, false)
	If (not RegExMatch(response, "i)^""?(low|fair|high)""?$")) {
		ShowTooltip("ERROR: Sending feedback failed. ", true)
	}
}

TradeFunc_ActivatePoeWindow() {
	If (not WinActive("ahk_group PoEWindowGrp")) {
		WinActivate, ahk_group PoEWindowGrp
	}
}

TradeFunc_CheckAprilFools() {
	FormatTime, Date_now, A_Now, MMdd	
	Date_until := 0401

	If (Date_now = Date_Until) {
		Return 1
	} Else {
		Return 0
	}
}

TradeFunc_AprilFools() {
	global ItsApriFoolsTime
	
	Random, chance, 1, 200
	
	If (not ItsApriFoolsTime) {
		Return
	}
	
	If (chance != 1) {
		Return
	}
	
	text := "Memory Access Violation`n"
	text .= "Cavas error at 000000 in "
	text .= "C:\Program Files\Synthesis\3.6\modules\april\fools\bin\readFragment.exe"
	MsgBox, 0x12, Error, %text%, 
	IfMsgBox, Retry 
	{
		TradeFunc_AprilFools()
	}
}