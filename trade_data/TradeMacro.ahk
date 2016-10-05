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

		Run % WikiUrl
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

TradeMacroMainFunction()
{
	LeagueName := TradeGlobals.Get("LeagueName")
	Global Item, ItemData, TradeOpts, mapList, uniqueMapList
	
    out("+ Start of TradeMacroMainFunction")

	DoParseClipboardFunction()
	
	RequestParams := new RequestParams_()
	RequestParams.league := LeagueName
	RequestParams.name   := Trim(StrReplace(Item.Name, "Superior", ""))
	
	; returns mods with their ranges of the searched item if it is unique and has variable mods
	variableItem := FunctionFindUniqueItemIfItHasVariableRolls(Item.Name)
	
	if (Item.IsGem) {
		RequestParams.q_min := Item.Quality
		if (Item.Level >= 16) {
			RequestParams.level_min := Item.Level
		}
	}
	out(ItemData.Links)
	if (ItemData.Links >= 5) {
		RequestParams.link_min := ItemData.Links
	}
	
	if (ItemData.Sockets >= 5) {
		RequestParams.sockets_min := ItemData.Sockets
	}
	
	if (Item.IsCorrupted) {
		RequestParams.corrupted := "x"
	}
	
	Payload := RequestParams.ToPayload()
	
	out("Running request with Payload:")
	out("------------------------------------")
	out(Payload)
	out("------------------------------------")
	
	ShowToolTip("Running search...")
    Html := FunctionDoPostRequest(Payload)
	out("POST Request success")
    ParsedData := FunctionParseHtml(Html, Payload)
	out("Parsing HTML done")
	
    SetClipboardContents(ParsedData)
    ShowToolTip(ParsedData)
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

FunctionDoPostRequest(payload)
{	
	;FileDelete, tempFiles\payload.txt
    ;FileAppend, %payload%, tempFiles\payload.txt
    
    ; TODO: split this function, HTTP POST and Html parsing should be separate
    ; Reference in making POST requests - http://stackoverflow.com/questions/158633/how-can-i-send-an-http-post-request-to-a-server-from-excel-using-vba
    HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
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
    ;FileRead, html, %tempFilesDirectory%Test1.txt
    ;FileDelete, %tempFilesDirectory%html.htm
    ;FileAppend, %html%, %tempFilesDirectory%html.htm
    
    Return, html
}

FunctionParseHtml(html, payload)
{
	
	Global Item, ItemData
	
	; Target HTML Looks like the ff:
    ;<tbody id="item-container-97" class="item" data-seller="Jobo" data-sellerid="458008" data-buyout="15 chaos" data-ign="Lolipop_Slave" data-league="Essence" data-name="Tabula Rasa Simple Robe" data-tab="This is a buff" data-x="10" data-y="9"> <tr class="first-line">
    ; TODO: grab more data like corruption found inside <tbody>
    
	; TODO refactor this
	
	Title := Trim(StrReplace(Item.Name, "Superior", ""))
	
	if (Item.IsCorrupted) {
		Title .= " [Corrupted] "
	}
	
	if (Item.IsGem) {
		Title := Item.Name " " Item.Quality "%"
		if (Item.Level >= 16) {
			Title := Item.Name " " Item.Level "`/" Item.Quality
		}
	}
    if (ItemData.Sockets >= 5) {
		Title := Item.Name " " ItemData.Sockets "s" ItemData.Links "l"
	}
	
	Title .= "`n ---------- `n"

    ; Text .= StrX( html,  "<tbody id=""item-container-0",          N,0, "<tr class=""first-line"">",1,28, N )

    NoOfItemsToShow = 15
    While A_Index < NoOfItemsToShow
          TBody       := StrX( html,   "<tbody id=""item-container-" . %A_Index%,  N,0,  "<tr class=""first-line"">", 1,23, N )
        , AccountName := StrX( TBody,  "data-seller=""",                           1,13, """"  ,                      1,1,  T )
        , Buyout      := StrX( TBody,  "data-buyout=""",                           T,13, """"  ,                      1,1,  T )
        , IGN         := StrX( TBody,  "data-ign=""",                              T,10, """"  ,                      1,1     )
        ;, Text .= StrPad(IGN, 30) StrPad(AccountName, 30) StrPad(Buyout,30) "`n"
        ;, Text .= StrPad(IGN,20) StrPad(Buyout,20,"left") "`n"
        , Title .= StrPad(IGN,20) StrPad(Buyout,20,"left")"`n"
    
    Return, Title
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
	mod_name := ""
	mod_min := ""
	mod_max := ""
	group_type := "And"
	group_min := ""
	group_max := ""
	group_count := "1"
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
	online := "x"
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
		p := "league=" this.league "&type=" this.xtype "&base=" this.xbase "&name=" this.name "&dmg_min=" this.dmg_min "&dmg_max=" this.dmg_max "&aps_min=" this.aps_min "&aps_max=" this.aps_max "&crit_min=" this.crit_min "&crit_max=" this.crit_max "&dps_min=" this.dps_min "&dps_max=" this.dps_max "&edps_min=" this.edps_min "&edps_max=" this.edps_max "&pdps_min=" this.pdps_min "&pdps_max=" this.pdps_max "&armour_min=" this.armour_min "&armour_max=" this.armour_max "&evasion_min=" this.evasion_min "&evasion_max=" this.evasion_max "&shield_min=" this.shield_min "&shield_max=" this.shield_max "&block_min=" this.block_min "&block_max=" this.block_max "&sockets_min=" this.sockets_min "&sockets_max=" this.sockets_max "&link_min=" this.link_min "&link_max=" this.link_max "&sockets_r=" this.sockets_r "&sockets_g=" this.sockets_g "&sockets_b=" this.sockets_b "&sockets_w=" this.sockets_w "&linked_r=" this.linked_r "&linked_g=" this.linked_g "&linked_b=" this.linked_b "&linked_w=" this.linked_w "&rlevel_min=" this.rlevel_min "&rlevel_max=" this.rlevel_max "&rstr_min=" this.rstr_min "&rstr_max=" this.rstr_max "&rdex_min=" this.rdex_min "&rdex_max=" this.rdex_max "&rint_min=" this.rint_min "&rint_max=" this.rint_max "&mod_name=" this.mod_name "&mod_min=" this.mod_min "&mod_max=" this.mod_max "&group_type=" this.group_type "&group_min=" this.group_min "&group_max=" this.group_max "&group_count=" this.group_count "&q_min=" this.q_min "&q_max=" this.q_max "&level_min=" this.level_min "&level_max=" this.level_max "&ilvl_min=" this.ilvl_min "&ilvl_max=" this.ilvl_max "&rarity=" this.rarity "&seller=" this.seller "&thread=" this.xthread "&identified=" this.identified "&corrupted=" this.corrupted "&online=" this.online "&buyout=" this.buyout "&altart=" this.altart "&capquality=" this.capquality "&buyout_min=" this.buyout_min "&buyout_max=" this.buyout_max "&buyout_currency=" this.buyout_currency "&crafted=" this.crafted "&enchanted=" this.enchanted
		return p
	}
}

FunctionFindUniqueItemIfItHasVariableRolls(name)
{
	data := TradeGlobals.Get("VariableUniqueData")
	For index, item in data {
		If (item.name == name ) {
			return item
		}
	} 
}
