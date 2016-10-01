^z::
	SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event ourselves
	Send ^c
	Sleep 250
	TradeMacroMainFunction()
	
TradeMacroMainFunction()
{
    Global Opts, Globals

    CBContents := GetClipboardContents()
    CBContents := PreProcessContents(CBContents)
	
    Globals.Set("ItemText", CBContents)
    Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)

    ParsedData := ParseItemData(CBContents)
	ParsedData := RunPriceCheckFunction()
	
    ;SetClipboardContents(ParsedData)
    ShowToolTip(Item.Name)
}


RunPriceCheckFunction()
{
	return Item.Name
}

out(str)
{
	stdout := FileOpen("*", "w")
	stdout.WriteLine(str)
}