�
 TMIDIPLAYER 0;  TPF0TMidiPlayer
MidiPlayerLeft� Top� Width#Height$Caption
MidiPlayerColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrder	OnCreate
FormCreateOnShowFormShowPixelsPerInch`
TextHeight 
TMidiScope
MidiScope1Left� Top WidthdHeight$  TLabelLabel3LeftTopWidthHeightCaptionBPM  TButtonButton1LeftTop Width)HeightCaptionLoadTabOrder OnClickButton1Click  TButtonButton3LeftHTop Width)HeightCaptionPlayTabOrderOnClickButton3Click  TButtonButton4Left� Top Width)HeightCaptionStopTabOrderOnClickButton4Click  	TComboBoxcmbInputLeft�TopWidth� Height
ItemHeightTabOrderTextcmbInputOnChangecmbInputChange  TEditedtBpmLeftHTopWidth)HeightTabOrder
OnKeyPressedtBpmKeyPress  TMemoMemo2Left�TopHWidthqHeight� Lines.StringsMemo2 TabOrder  TEditedtTimeLeft� Top WidthiHeightReadOnly	TabOrderTextedtTime  TButtonButton2LeftxTop Width)HeightCaptionContinueTabOrderOnClickButton2Click  TStringGrid	TrackGridLeftTopHWidthYHeight� ColCountDefaultRowHeightOptionsgoFixedVertLinegoFixedHorzLine
goVertLine
goHorzLinegoRangeSelectgoRowSizinggoColSizing TabOrder  TStringGrid
TracksGridLeftTop Width� Height$ColCountDefaultColWidth� DefaultRowHeight	FixedCols RowCount	FixedRows 
ScrollBarsssNoneTabOrder	OnSelectCellTracksGridSelectCell  TEdit	edtLengthLeftPTop WidthaHeightTabOrder
Text	edtLength  TOpenDialogOpenDialog1FilterMidi files|*.midLeftTopP  TMidiOutputMidiOutput1LeftTopp  	TMidiFile	MidiFile1Bpm OnMidiEventMidiFile1MidiEventOnUpdateEventMidiFile1UpdateEventLeftTop8   