#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         LoremasterLH

 Script Function:
 A script for creating any amount of trade offers by emulating player actions.

 Only works on 1080 × 1920 resolution

 Requires trading.dat which has instructions on which trades to post. Each command is issued on seperate line. "; " marks a comment.
 command is sctuctured as followed:
 1: Which age to trade with (negative value For trading down, positive For trading up). 'A' for trade_all_for_all mode
 2: Trade ratio (0.5-2)
 3: Amount of goods to offer,
 4: How many of each trades to make (min 0)
 5: Start age
 6: End age or row of good
 7: ALL, or which row target good is in (can be empty, if first parameter is 'A')

 Note that using scripts is not allowed. While it is unlikely this script to be detected; use at your own risk.

#ce ----------------------------------------------------------------------------

#include <MsgBoxConstants.au3>

Global $Paused
Global Const $mon=1920 ; 0 main, 1920 secondary monitor
Global $repeatable = False
HotKeySet("{ESC}", "Terminate")
HotKeySet("{SPACE}", "Pause")

Func _WinWaitActivate($title,$text,$timeout=0)
	WinWait($title,$text,$timeout)
	If Not WinActive($title,$text) Then WinActivate($title,$text)
	WinWaitActive($title,$text,$timeout)
EndFunc

Func Terminate()
   Exit
EndFunc

Func Pause()
	$Paused = NOT $Paused
	While $Paused
		sleep(100)
		ToolTip('Script is Paused',0,0)
	WEnd
EndFunc

Func set_guild_only()
	MouseClick("left",1300+$mon,440)
EndFunc

Func confirm_offer()
	MouseClick("left",1300+$mon,480,1)		;create offer (button)
	sleep(1500)
	MouseClick("left",1300+$mon,480,1)		;dismiss
EndFunc

Func create_offer($offered, $needed, $offered_amount, $needed_amount, $col1=0, $col2=0, $tab1=0, $tab2=0)
	; offered, needed = rows
	; goods represented as a 2×10 grid
	; width of item is 374 pixels, height 30 pixels
	; first row is @ 510
	; first column is @ 700, second @ 1200
	; height 440 - offered amount, height 480 demanded amount, width 1060
	If $tab1=0 Then ;tab of offered
		MouseClick("left",1330+$mon,580)
	ElseIf $tab1=1 Then
		MouseClick("left",1330+$mon,648)
	ElseIf $tab1=2 Then
		MouseClick("left",1330+$mon,708)
	ElseIf $tab1=3 Then
		MouseClick("left",1330+$mon,770)
	EndIf

	MouseClick("left",700+$col1*500+$mon,$offered,1)		; good location
	MouseClick("left",800+$col1*500+$mon,$offered-10,1)		; menu for offer

	If $tab1 <> $tab2 Then	; Only switch tab, if they're not the same
		If $tab2=0 Then
			MouseClick("left",1330+$mon,580)
		ElseIf $tab2=1 Then
			MouseClick("left",1330+$mon,648)
		ElseIf $tab2=2 Then
			MouseClick("left",1330+$mon,708)
		ElseIf $tab2=3 Then
			MouseClick("left",1330+$mon,770)
		EndIf
	EndIf

	MouseClick("left",700+$col2*500+$mon,$needed,1)
	MouseClick("left",800+$col2*500+$mon,$needed+10,1)	; menu for need
	If $repeatable = False Then							; If it's not the first pass, skip setting value
		MouseClick("left",1060+$mon,440,1)				; goods offered
		Send("^a"&$offered_amount)
		MouseClick("left",1060+$mon,480,1)				; goods demanded
		Send("^a"&$needed_amount)
	EndIf

EndFunc

Func trade_all_for_all($offered_row, $offered_col, $needed_row, $needed_col, $ratio, $amount, $num_trades, $tab1, $tab2) ;creates offers of all goods of an age for all goods of a different age
	For $i=0 to 4		; loop through goods of start_age
		For $j=0 to 4	; loop through goods of end_age
			create_offer($offered_row+$i*28, $needed_row+$j*28, $amount, round($ratio * $amount), $offered_col, $needed_col, $tab1, $tab2)
			$repeatable = True
			For $k=0 to $num_trades-1		; create trades for the good
				confirm_offer()
			Next
		Next
	Next
	$repeatable = False
EndFunc

Func get_good_location($age, $shift=0)	; $age of good in question and relative location within the age (0-4)
	If $shift > 4 Then
		MsgBox($MB_SYSTEMMODAL, "Error", "Good $row is invalid. It must be between 0 and 4")
		Exit
	EndIf
	Return $start_h + (int(mod($age,4) / 2) * 5 + $shift) * $row_h
EndFunc

Func get_col($age)
	Return mod($age,2)
EndFunc

Func get_tab($age)
	Return int($age / 4)
EndFunc

_WinWaitActivate("Forge of Empires – Google Chrome","Chrome Legacy Window")
MouseClick("left",5+$mon,1030,1)	;clear any opened window
MouseClick("left",70+$mon,980,1)	;open market
sleep(1000)
MouseClick("left",1000+$mon,370,1)	;create offer (tab)

;set_guild_only()	;mostly for testing

Local $file = FileOpen("trading.dat")
If $file = -1 Then
	MsgBox($MB_SYSTEMMODAL, "", "File trading.dat not found. Make sure it's in the same folder as the script.")
	Exit
EndIf

Local const $start_h = 550	;Location of first good/row. Subsequent ones are +28.
Local const $row_h = 28

; $command is sctuctured as followed:
; 1: Which age to trade with (negative value For trading down, positive For trading up). A for trade_all_for_all mode
; 2: Trade ratio (0.5-2)
; 3: Amount of goods to offer,
; 4: How many of each trades to make (min 0)
; 5: Start age
; 6: End age or row of good
; 7: Optional ALL, or which row target good is in

While 1
	Local $line = FileReadLine($file)
	If $line = "" Then
		ExitLoop
	EndIf
	Local $com = StringSplit($line," ")	; While arrays in AutoIt3 start at index 0, StringSplit returns array that starts at index 1.
	If $com[1] = ';' Then	;Comment
		ContinueLoop
	EndIf

	Local $tab1, $tab2, $col1, $col2, $start1, $start2, $target_age = $com[1], $ratio = $com[2], $amount = $com[3], $number = $com[4], $start_age = $com[5], $end_age = $com[6], $row = $com[6] ;last one wrong
	If $start_age + $target_age < 0 Then
		MsgBox($MB_SYSTEMMODAL, "Error", "Attempting to trade with an invalid age. Check input")
		Exit
	EndIf

	;init
	If $target_age <> 'A' Then	;not applicable in trade_all_for_all
		$col1 = get_col($start_age)
		$col2 = get_col($start_age + $target_age)
		$tab1 = get_tab($start_age)
		$tab2 = get_tab($start_age + $target_age)
		$start1 = get_good_location($start_age, $row) 	; Set where the traded good is
		$start2 = get_good_location($start_age + $target_age)
		; MsgBox($MB_SYSTEMMODAL, "", $col1 & ", " & $col2 & "\n" & $tab1 & ", " & $tab2)
	ElseIf $target_age = 'A' Then			;trade_all_for_all()
		$start1 = get_good_location($start_age)
		$start2 = get_good_location($end_age)
		$col1 = get_col($start_age)		;offered good
		$col2 = get_col($end_age)		;needed good
		$tab1 = get_tab($start_age)
		$tab2 = get_tab($end_age)
		trade_all_for_all($start1, _
							$col1, _
							$start2, _
							$col2, _
							$ratio, _
							$amount, _
							$number, _
							$tab1, _
							$tab2)
		;FileClose($file)
		ContinueLoop	; In this branch that's all there is to do
	EndIf

	If $com[0] = 7 Then	; First parameter is length ... beats me why.
		If $com[7] = "ALL" Then
			For $i=0 to 4						;All 5 goods of the selected age.
				;For $j=0 to int($number)-1		;Create set number of offers For each good.
				create_offer($start1, _	;$offered
							$start2+$i*$row_h, _			;$needed
							$amount, _						;$offered amount
							round($amount*$ratio), _		;$needed amount
							$col1, _						;$column
							$col2, _
							$tab1, _
							$tab2)							;$tab
				$repeatable = True
				For $j=0 to $number-1	;Post all the offers.
					confirm_offer()
				Next
				;MsgBox($MB_SYSTEMMODAL, "", $start2+$com[5]*$row_h)
			Next
			$repeatable = False
		; ElseIf IsNumber($com[7]) Then	; A single trade - $com[7] is row of target good
		Else
			;MsgBox($MB_SYSTEMMODAL, "", "HERE")
			create_offer($start1, _
						$start2+$com[7]*$row_h, _
						$amount, _						;$offered amount
						round($amount*$ratio), _		;$needed amount
						$col1, _						;$column
						$col2, _
						$tab1, _
						$tab2)
			For $j=0 to $number-1	;Post all the offers.
					confirm_offer()
			Next
		EndIf
	EndIf
WEnd

FileClose($file)