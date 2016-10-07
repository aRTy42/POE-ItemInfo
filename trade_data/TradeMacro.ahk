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
		Global TradeOpts
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		Send ^c
		Sleep 250
		TradeMacroMainFunction()
		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
return

OpenWiki:
	IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
	{
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		Send ^c
		Sleep 250
		DoParseClipboardFunction()

		if (Item.IsUnique) {
			UrlAffix := Item.Name
		} else if (Item.IsFlask) {
			UrlAffix := Item.SubType
		} else {
			UrlAffix := Item.TypeName
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

OpenSearchOnPeoTrade:
	Global TradeOpts
	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	Send ^c
	Sleep 250
	TradeMacroMainFunction(true)
	SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
return

; Prepare Reqeust Parametes and send Post Request
TradeMacroMainFunction(openSearchInBrowser = false)
{
	LeagueName := TradeGlobals.Get("LeagueName")
	Global Item, ItemData, TradeOpts, mapList, uniqueMapList
	
    out("+ Start of TradeMacroMainFunction")

	DoParseClipboardFunction()
	
	RequestParams := new RequestParams_()
	RequestParams.league := LeagueName
	
	; remove "Superior" from item name to exclude it from name search
	RequestParams.name   := Trim(StrReplace(Item.Name, "Superior", ""))
	
	if (Item.IsUnique) {
		; returns mods with their ranges of the searched item if it is unique and has variable mods
		uniqueWithVariableMods := FunctionFindUniqueItemIfItHasVariableRolls(Item.Name)
		if (uniqueWithVariableMods) {
			s := FunctionGetItemsPoeTradeUniqueMods(uniqueWithVariableMods)
			Loop % s.mods.Length() {
				modValue := FunctionGetModValueGivenPoeTradeMod(ItemData.Affixes, s.mods[A_Index].param)
				if (modValue) {
					;MsgBox % modValue "=" s.mods[A_Index].param
					modParam := new _ParamMod()
					modParam.mod_name := s.mods[A_Index].param
					modParam.mod_min := modValue
					RequestParams.modGroup.AddMod(modParam)
				}	
			}
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
		if (Item.Level >= TradeOpts.GemLevel) {
			RequestParams.level_min := Item.Level
		}
	}
	
	; handle item links
	if (ItemData.Links >= 5) {
		RequestParams.link_min := ItemData.Links
	}
	
	; handle item sockets
	if (ItemData.Sockets >= 5) {
		RequestParams.sockets_min := ItemData.Sockets
	}
	
	; handle corruption
	if (Item.IsCorrupted) {
		; search for both corrupted and un-corrupted
		RequestParams.corrupted := "x"
		; for gems only search corrupted ones
		if (Item.IsGem) {
			RequestParams.corrupted := "1"
		}
	}
	else {
		; always exclude corrupted gems from results if the source is not corrupted
		if (Item.IsGem) {
			RequestParams.corrupted := "0"
		}
		; either
		else if (TradeOpts.Corrupted = 2) {
			RequestParams.corrupted := "x"
		}
		; corrupted
		else if (TradeOpts.Corrupted = 1) {		
			RequestParams.corrupted := "1"
		}
		; non-corrupted
		else if (TradeOpts.Corrupted = 0) {		
			RequestParams.corrupted := "0"
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
		if (InStr(Item.name, "Ivory Temple")){
			RequestParams.xbase  := "Ivory Temple Map"
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
    Html := FunctionDoPostRequest(Payload, openSearchInBrowser)
	out("POST Request success")
	
	if(openSearchInBrowser) {
		; redirect was prevented to get the url and open the search on peotrade instead
		RegExMatch(Html, "i)href=""(https?:\/\/.*?)""", ParsedUrl)
		FunctionOpenUrlInBrowser(ParsedUrl1)
	}
	else {
		ParsedData := FunctionParseHtml(Html, Payload)
		out("Parsing HTML done")
		
		SetClipboardContents(ParsedData)
		ShowToolTip(ParsedData)
	}    
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

FunctionGetMeanMedianPrice(html, payload){
	itemCount := 1
    prices := []
    average := 0
	Title := ""
	
	; loop over the first 99 results if possible, otherwise over as many as are available
    While A_Index <= 99 {
        ChaosValue := StrX( html,  "data-name=""price_in_chaos""",N,0,  "currency", 1,0, N)
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
        average := average / itemCount - 1
		Title .= "Average price in chaos: " average " (" prices.MaxIndex() " results) `n"
		
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
		Title .= "Median  price in chaos: " median " (" prices.MaxIndex() " results) `n`n"
    }  
	return Title
}

FunctionParseHtml(html, payload)
{	
	Global Item, ItemData
	
	; Target HTML Looks like the ff:
    ;<tbody id="item-container-97" class="item" data-seller="Jobo" data-sellerid="458008" data-buyout="15 chaos" data-ign="Lolipop_Slave" data-league="Essence" data-name="Tabula Rasa Simple Robe" data-tab="This is a buff" data-x="10" data-y="9"> <tr class="first-line">

	
	Title := Trim(StrReplace(Item.Name, "Superior", ""))
	
	if (Item.IsMap && !Item.isUnique) {
		; Quick map fix (wrong Item.name on magic/rare maps)
		Title := 
		newName := Trim(StrReplace(Item.Name, "Superior", ""))
		newName := Trim(StrReplace(newName, "Shaped", ""))
		; prevent duplicate name on white maps
		if (newName != Item.SubType) {
			Title .= "(" Trim(StrReplace(Item.Name, "Superior", "")) ") "
		}
		; add "SHaped" to item title since it's missing from Item.name	 		
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
		Title := Item.Name " " Item.Quality "%"
		if (Item.Level >= 16) {
			Title := Item.Name " " Item.Level "`/" Item.Quality
		}
	}
	; add item sockets and links
    if (ItemData.Sockets >= 5) {
		Title := Item.Name " " ItemData.Sockets "s" ItemData.Links "l"
	}
	
	Title .= "`n ---------- `n"	
	; add average and median prices to title	
	Title .= FunctionGetMeanMedianPrice(html, payload)
	
    NoOfItemsToShow := TradeOpts.ShowItemResults
	; add table headers to tooltip
	Title .= FunctionShowAcc(StrPad("Account",10), "|") 
	Title .= StrPad("IGN",20) 	
	Title .= StrPad("Price |",20,"left")	
		
	if (Item.IsGem) {
		; add gem headers
		Title .= StrPad("Q. |",6,"left")
		Title .= StrPad("Lvl |",6,"left")
	}
	Title .= StrPad(" Age",8)	
	Title .= "`n"
	
	; add table header underline
	Title .= FunctionShowAcc(StrPad("----------",10), "-") 
	Title .= StrPad("--------------------",20) 
	Title .= StrPad("--------------------",20,"left")
	if (Item.IsGem) {
		Title .= StrPad("------",6,"left")
		Title .= StrPad("------",6,"left")
	}	
	Title .= StrPad("----------",8,"left")	
	Title .= "`n"
	
	; add search results to tooltip in table format
    While A_Index < NoOfItemsToShow {
        TBody       := StrX( html,   "<tbody id=""item-container-" . %A_Index%,  N,0,  "</tbody>", 1,23, N )
        AccountName := StrX( TBody,  "data-seller=""",                           1,13, """"  ,                      1,1,  T )
        Buyout      := StrX( TBody,  "data-buyout=""",                           T,13, """"  ,                      1,1,  T )
        IGN         := StrX( TBody,  "data-ign=""",                              T,10, """"  ,                      1,1     )
		
		; get item age
		Pos := RegExMatch(TBody, "i)class=""found-time-ago"">(.*?)<", Age)
		
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
		Title .= StrPad(Buyout . "|",20,"left") 
		
		if (Item.IsGem) {
			; add gem info
			Title .= StrPad(" " . Q1 . "% |",6,"left")
			Title .= StrPad(" " . LVL1 . " |" ,6,"left")
		}
		; add item age
		Title .= StrPad(FunctionFormatItemAge(Age1),10)
		Title .= "`n"
    }

    Return, Title
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
		unit := "1 day"
	} else if (unit = "hour") {
		unit := " h"
	} else if (unit = "minute") {
		unit := " min"
	} else if (unit = "second") {
		unit := " sec"
	} 		
	
	s := " " value unit
	
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

FunctionTestItemMods(){
	test := FunctionFindUniqueItemIfItHasVariableRolls("Chernobog's Pillar")
	if (test) {
		s := FunctionGetItemsPoeTradeMods(test)
		MsgBox % s.mods[1].param
		MsgBox % s.mods[2].param
		MsgBox % s.mods[3].param
	}
}

; Return unique item with its variable mods and mod ranges if it has any
FunctionFindUniqueItemIfItHasVariableRolls(name)
{
	data := TradeGlobals.Get("VariableUniqueData")
	For index, item in data {
		If (item.name == name ) {
			return item
		}
	} 
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

; Add poetrades mod names to the items mods to use as POST parameter
FunctionGetItemsPoeTradeUniqueMods(item) {
	mods := TradeGlobals.Get("ModsData")
	For k, imod in item.mods {	
		item.mods[k]["param"] := FunctionFindInModGroup(mods["unique explicit"], item.mods[k])
		if (StrLen(item.mods[k]["param"]) < 1) {
			item.mods[k]["param"] := FunctionFindInModGroup(mods["explicit"], item.mods[k])
		}
	}
	return item
}

; find mod in modgroup and return its name
FunctionFindInModGroup(modgroup, needle) {
	For j, mod in modgroup {
		s := Trim(RegExReplace(mod, "i)\(pseudo\)|\(total\)|\(crafted\)|\(implicit\)|\(explicit\)|\(enchant\)|\(prophecy\)", ""))
		ss := Trim(needle.name)	
			 
		If (s = ss) {
			return mod
		}
	}
	return ""
}

FunctionGetModValueGivenPoeTradeMod(itemModifiers, poeTradeMod) {
	Loop, Parse, itemModifiers, `n, `r
	{
		If StrLen(A_LoopField) = 0
		{
			Continue ; Not interested in blank lines
		}
		CurrValue := ""
		CurrValue := GetActualValue(A_LoopField)
		if (CurrValue ~= "\d+") {
			ModStr := StrReplace(A_LoopField, CurrValue)
			ModStr := StrReplace(ModStr, "+")
			IfInString, poeTradeMod, % ModStr
			{
				return CurrValue
			}
		}
	}
}

^j::
	;FunctionTestItemMods()
	;MsgBox % new RequestParams_().ToPayload()
	return
	
^b::
{
	out("testing")
	;Testing
	TestCase =
	( LTrim
		Rarity: Unique
		<<set:MS>><<set:M>><<set:S>>Belly of the Beast
		Full Wyrmscale
		--------
		Armour: 532 (augmented)
		Evasion Rating: 181
		--------
		Requirements:
		Level: 46
		Str: 68
		Dex: 68 (unmet)
		--------
		Sockets: R B G 
		--------
		Item Level: 72
		--------
		194`% increased Armour
		33`% increased maximum Life
		+14`% to all Elemental Resistances
		50`% increased Flask Life Recovery rate
		Extra gore
		--------
		There is no safer place
		Than the Belly of the Beast
	)
	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
	SetClipboardContents(TestCase)
	TradeMacroMainFunction(true)
	SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	return
}