#SingleInstance, force
#Include, lib\Class_ColorPicker.ahk

image := A_ScriptDir "\resources\images\colorPickerPreviewBg.png"
ColorPickerResults	:= new ColorPicker("FFFFFF", 85, "GDI+ Tooltip Text Color Picker", image)
;ColorPickerResults	:= new ColorPicker()

MsgBox % "ARGB hex: " ColorPickerResults[1] "`n" "RGB: " ColorPickerResults[2] "`n" "Opacity/Alpha: " ColorPickerResults[3]

