TITLE Battleship	(main.asm)
; Description:   CS-278 Final Project
; authors: Laura Delaney and Hannah Cobb
; program allows users to play a game of battleship against an artifically intelligent computer
INCLUDE Irvine32.inc    

BattleMap STRUCT
	grid BYTE 100 DUP (16*blue) ;remember to print the row and column labels during setup

	;grid bytes contain 3 pieces of data
	; in the upper 4 bits, the background color for the space to be printed in ;this may not be strictly neccesary, but will be helpful
	; the lowest bit acts as a flag for if this square of the grid has been explored or not
	; the other three bits form a code for if the square is part of a ship, and if so which one (see ship counter comments for their codes)
	; the no-ship code is 000

	;these are ship hit counters for each ship, they will be initialized during setup to 0, so the game can be replayed
	ship2 BYTE 0	;code for this ship = 001
	ship3A BYTE 0	;code for this ship = 010
	ship3B BYTE 0	;code for this ship = 011
	ship4 BYTE 0	;code for this ship = 100
	ship5 BYTE 0	;code for this ship = 101
BattleMap ENDS

.data
userMap BattleMap <>	;the structure holding all of the information about the user's map of ships
cpuMap BattleMap <>		;the structure holding all of the information about the cpu's map of ships
aiDifficulty BYTE 1 ; 0 = easy, 1 = medium, 2 = hard
welcomeBanner1 BYTE " _    _      _                            _         ______       _   _   _           _     _       _", 13, 10, 0 
welcomeBanner2 BYTE "| |  | |    | |                          | |        | ___ \     | | | | | |         | |   (_)     | |", 13, 10, 0
welcomeBanner3 BYTE "| |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___   | |_/ / __ _| |_| |_| | ___  ___| |__  _ _ __ | |", 13, 10, 0
welcomeBanner4 BYTE "| |/\| |/ _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \  | ___ \/ _` | __| __| |/ _ \/ __| '_ \| | '_ \| |", 13, 10, 0
welcomeBanner5 BYTE "\  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) | | |_/ / (_| | |_| |_| |  __/\__ \ | | | | |_) |_|", 13, 10, 0
welcomeBanner6 BYTE " \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/  \____/ \__,_|\__|\__|_|\___||___/_| |_|_| .__/(_)", 13, 10, 0
welcomeBanner7 BYTE "                                                                                            | |", 13, 10, 0
welcomeBanner8 BYTE "                                                                                            |_|", 13, 10, 0
numberLabels BYTE" 0123456789", 0 ;these are the labels for the top edge of the map
namePrompt BYTE "Please enter your name: ", 0
greetUser BYTE "Welcome, ", 0
lineFeed BYTE 10, 0
aiPrompt BYTE "Please select the AI difficulty. 0 is easy, 1 is normal, and 2 is hard", 0
inputPrompt1 BYTE "Please enter a value between ", 0
inputPrompt2 BYTE " and ", 0
inputPrompt3 BYTE ": ", 0
blankLine BYTE "                                                           ", 0
vOrHPrompt BYTE "Enter 0 to place your ship horizontally or 1 to place your ship vertically", 0
shipPlacePrompt BYTE "You are placing a ship of length: ", 0
cpuHitMsg2 BYTE "The AI fires and hits your ship of length 2", 0
cpuHitMsg3 BYTE "The AI fires and hits your ship of length 3", 0
cpuHitMsg4 BYTE "The AI fires and hits your ship of length 4", 0
cpuHitMsg5 BYTE "The AI fires and hits your ship of length 5", 0
cpuMissMsg BYTE "The AI fires and misses", 0
userHitMsg2 BYTE "You fire and hit a ship of length 2", 0
userHitMsg3 BYTE "You fire and hit a ship of length 3", 0
userHitMsg4 BYTE "You fire and hit a ship of length 4", 0
userHitMsg5 BYTE "You fire and hit a ship of length 5", 0
userMissMsg BYTE "You fire and miss", 0
userWinMsg BYTE "You have won", 0
userLossMsg BYTE "You have lost", 0
userMapCursor COORD <2, 2>
cpuMapCursor COORD <14, 2>
promptCursor COORD <2, 15>
rightPromptCursor COORD <27, 2> ;used as the prompt cursor for the right half of the screen, where the hit and miss output displays

userName BYTE ?
randVal BYTE ?
tempX BYTE ?
tempY BYTE ?


.code
main PROC

Welcome:
;before the setup label, print our welcome screen, and input the user's name
	mov edx, OFFSET welcomeBanner1
	call WriteString
	mov edx, OFFSET welcomeBanner2
	call WriteString
	mov edx, OFFSET welcomeBanner3
	call WriteString
	mov edx, OFFSET welcomeBanner4
	call WriteString
	mov edx, OFFSET welcomeBanner5
	call WriteString
	mov edx, OFFSET welcomeBanner6
	call WriteString
	mov edx, OFFSET welcomeBanner7
	call WriteString
	mov edx, OFFSET welcomeBanner8
	call WriteString
	mov edx, OFFSET namePrompt
	call WriteString
	mov ecx, 20
	mov edx, OFFSET userName
	call ReadString 
	mov edx, OFFSET greetUser
	call WriteString
	mov edx, OFFSET userName
	call WriteString
	call crlf
	mov edx, OFFSET aiPrompt
	call WriteString
	mov ebx, '0'
	mov ecx, '2'
	call UserInputChar
	sub eax, '0'
	mov aiDifficulty, al


	;pause to show the welcome prompt. eax does not actually need to be pushed and popped, because it does not need to be preserved right now
	push eax		
	call ReadChar
	pop eax

setup:
;setup will: 
	;initialize all ship counters to 0
	mov userMap.ship2, 0
	mov userMap.ship3A, 0
	mov userMap.ship3B, 0
	mov userMap.ship4, 0
	mov userMap.ship5, 0
	mov cpuMap.ship2, 0
	mov CPUMap.ship3A, 0
	mov CPUMap.ship3B, 0
	mov CPUMap.ship4, 0
	mov CPUMap.ship5, 0
	;place the CPU ships
	mov ecx, 5
	placeCPUships:										;WALKTHROUGH1
		;randomly select vertical or horizontal
		call Randomize
		mov eax, 2
		call RandomRange
		mov randVal, al

		;set the edge limit for the more restricted direction
		mov edx, 10 ;10 is our max (squares 0 to 9)
		sub edx, ecx ;ecx is at least the length of the ship
		
		;if we are placing one of the first three ships, the number in ecx will match the length of the ship 
		push ecx; the length of this ship is on the top of the stack
		cmp ecx, 2
		jg bigCPUShipsSkippedthis
			;for the other two ships, the ship is one longer than its counter value in ecx
			dec edx
			mov ebx, ecx
			inc ebx
			pop ecx
			push ebx ;the updated length of this ship is on the top of the stack 

	bigCPUShipsSkippedthis: 

	add randVal, 0
	jz placeCPUShipH ;else fall through to vertical placement


	placeCPUShipV: ;vertical ship placement, will never loop just back to here
		;randomly select the X coordinate
		call Randomize
		mov eax, 10
		call RandomRange
		mov tempX, al

		;randomly select the Y coordiante
		call Randomize
		mov eax, edx
		call RandomRange
		mov tempY, al

		;edx contains the max square for placement
		;for each map square, check if placeable
		;if any are not placeable, jmp back to place cpu ships
		;the top of the stack holds the ship length
		;eax will hold the offset for the array part we are going to
		;tempX and tempY hold the coordinates for the uppermost leftmost corner of the ship

		mov eax, 0
		mov al, tempY
		push ebx
		mov ebx, 10
		mul ebx
		pop ebx
		add al, tempX

		pop edx ;edx now holds the length of the ship
		push edx ;the top of the stack still holds the length of the ship
		

		;before checking, al holds the array index for the first element to check
		;before checking, edx holds the length of the ship, and will be our temporary counter

		placeCPUShipVCheck:		;"CLEAR CLEAR CLEAR CLEAR CLEAR" -spotlight

			mov ebx, OFFSET cpuMap.grid
			add ebx, eax
			;at this point, ebx holds the memory address of the grid square to be checked

			push eax
			mov al, BYTE PTR [ebx]
			test al, 00001110b ;are any of the ship bits set?
			jnz placeCPUShipVCheckFail ;if so, there is a ship here, and the test for if we can put a ship here fails
			pop eax

			add eax, 10
			dec edx ;if the ship length is 5, we want our first offset to be 4 (adjusting for indexing from 0)
		jnz placeCPUShipVCheck

			;before jumping, reset our ship length counter, put the index into ebx
			pop edx
			push edx ;so the stack counter is the same before and after this pair of operands
			jmp placeCPUShipVPlop ;goto plop

		placeCPUShipVCheckFail:
			pop eax ;the jump happened before eax was resotred
			pop edx ;clean up what we used of the stack (just the top element)
			jmp placeCPUShips ;try all over agin to place this ship
			
		placeCPUShipVPlop:		;"PLOP"
		;at the start of this loop, ebx holds the value of the bottomost ship index
		;at the start of this loop, edx will once more hold the number of squares in this ship (the ship length)
			mov al, cl
			add al, cl ;2*cl = the ship code in the 2nd-4th bits
			or al, BYTE PTR [ebx]
			mov BYTE PTR[ebx], al

			sub ebx, 10 ;move up a row for the next time
			dec edx
		jnz placeCPUShipVPlop ;this loop

		;if the ship was placed properly, dec ecx, jz to end of cpu ship placement
		pop edx ;take the ship length off of the stack, as we are done with it and don't want to waste memory
		dec ecx
		jnz PlaceCPUships
		jmp endCPUShipPlacement

	placeCPUShipH: ;horizontal ship placement, will never loop back to just here
	
		;randomly select the X coordiante
		call Randomize
		mov eax, edx
		call RandomRange
		mov tempX, al

		;randomly select the Y coordinate
		call Randomize
		mov eax, 10
		call RandomRange
		mov tempY, al

		;edx contains the max square for placement
		;for each map square, check if placeable
		;if any are not placeable, jmp back to place cpu ships

		;the top of the stack slready holds the ship length
		;eax will hold the offset for the array part we are going to
		;tempX and tempY hold the coordinates for the uppermost leftmost corner of the ship

		mov eax, 0
		mov al, tempY
		push ebx
		mov ebx, 10
		mul ebx
		pop ebx
		add al, tempX

		

		pop edx ;edx now holds the length of the ship
		push edx ;the top of the stack still holds the length of the ship
		

		;before checking, al holds the array index for the first element to check
		;before checking, edx holds the length of the ship, and will be our temporary counter

		placeCPUShipHCheck:		;"CLEAR CLEAR CLEAR CLEAR CLEAR" -spotlight										;WALKTHROUGH2
			mov ebx, OFFSET cpuMap.grid
			add ebx, eax
			;at this point, ebx holds the memory address of the grid square to be checked

			push eax
			mov al, BYTE PTR [ebx]
			test al, 00001110b ;are any of the ship bits set?
			jnz placeCPUShipHCheckFail ;if so, there is a ship here, and the test for if we can put a ship here fails
			pop eax 			

			inc eax ;add one, not ten, because we are placing horizontally
			dec edx ;if the ship length is 5, we want our first offset to be 4 (adjusting for indexing from 0)
		jnz placeCPUShipHCheck

			;before jumping, reset our ship length counter, put the index into ebx
			pop edx
			push edx ;so the stack counter is the same before and after this pair of operands
			
			jmp placeCPUShipHPlop ;goto plop

		placeCPUShipHCheckFail:
			pop eax ;the jump happened before eax was resotred
			pop edx ;clean up what we used of the stack (just the top element)
			jmp placeCPUShips ;try all over agin to place this ship

		placeCPUShipHPlop:		;"PLOP"										;WALKTHROUGH3
			;at the start of this loop, ebx holds the value of the bottomost ship index
			;at the start of this loop, edx will once more hold the number of squares in this ship (the ship length)
		
			mov al, cl
			add al, cl ;2*cl = the ship code in the 2nd-4th bits
			or al, BYTE PTR [ebx]
			mov BYTE PTR[ebx], al

			sub ebx, 1 ;move over a column for the next time
			dec edx
		jnz placeCPUShipHPlop ;this loop

			;after fully placing this ship, dec ecx, jz to end of cpu ship placement
			pop edx ;take the ship length off of the stack, as we are done with it and don't want to waste memory

			dec ecx
			jnz PlaceCPUships
			jmp endCPUShipPlacement ;we have placed all CPU ships
	endCPUShipPlacement:
		
		
	;print the starting map, including coordinate labels, hiding the ship locations of the CPU ships
	;guide the user through ship placement


	
	
	call Clrscr

printCPUMap:
	mov ecx, 10
	mov dx, cpuMapCursor.X
	mov ax, cpuMapCursor.Y
	mov dh, al
	call Gotoxy
	
	add cpuMapCursor.Y, 1
	mov eax, 'A'
	push edx
	mov edx, OFFSET numberLabels
	call WriteString
	mov edx, OFFSET lineFeed
	call WriteString
	pop edx
	mov ebx, OFFSET cpuMap.grid

	startingCMapOuter:
			push eax 
			inc dh
			call Gotoxy
			mov eax, black*16
			add al, lightgray
			call SetTextColor
			pop eax
		call WriteChar
		inc eax
		push ecx
		mov ecx, 10
		startingCMapInner:
			push eax
			mov eax, 0
			mov al, BYTE PTR [ebx]
			call SetTextColor
			;mov eax, "x"
			mov eax, " "
			call Writechar
			pop eax

			inc ebx;get ready to print the next square
			dec ecx
			jnz startingCMapInner
		pop ecx
		push edx
		mov edx, OFFSET lineFeed
		call WriteString
		pop edx
		dec ecx
		jnz startingCMapOuter

mov eax, black*16
add al, lightgray
call SetTextColor

printUserMap:
mov ecx, 10
	mov dx, userMapCursor.X
	mov ax, userMapCursor.Y
	mov dh, al
	call Gotoxy
	
	add userMapCursor.Y, 1
	mov eax, 'A'
	push edx
	mov edx, OFFSET numberLabels
	call WriteString
	mov edx, OFFSET lineFeed
	call WriteString
	pop edx
	mov ebx, OFFSET userMap.grid

	startingUMapOuter:
	push eax 
			inc dh
			call Gotoxy
			mov eax, black*16
			add al, lightgray
			call SetTextColor
			pop eax
		call WriteChar
		inc eax
		push ecx
		mov ecx, 10
		startingUMapInner:
			push eax
			mov eax, 0
			mov al, BYTE PTR [ebx]
			call SetTextColor
			mov eax, "x"
			;mov eax, " "
			call Writechar
			pop eax

			inc ebx;get ready to print the next square
			dec ecx
			jnz startingUMapInner
		pop ecx
		push edx
		mov edx, OFFSET lineFeed
		call WriteString
		pop edx
		dec ecx
		jnz startingUMapOuter

mov eax, black*16
add al, lightgray
call SetTextColor




;place the User ships
	mov ecx, 5
	placeUserships:
		;prompt user to select vertical or horizontal
		mov eax, black*16
		add al, lightgray
		call SetTextColor
		mov dx, promptCursor.X
		mov ax, promptCursor.Y
		sub al, 2
		mov dh, al
		call Gotoxy
		push edx ;push the cursor
		mov edx, OFFSET blankLine
		call WriteString
		pop edx ;restore the cursor
		call Gotoxy ;go to the cursor again
		push edx ; save the cursor
		mov edx, OFFSET shipPlacePrompt
		call WriteString
		mov eax, ecx ;show the ship length
		cmp eax, 3
		jge placeUserShipLengthChangeSkipped
		add eax, 1
		placeUserShipLengthChangeSkipped:
		add eax, '0'
		call WriteChar
		sub eax, '0'
		mov ebx, eax
		pop edx
		push ebx ;push the ship length to the stack, just under the cursor
		push edx



		pop edx ; restore the cursor
		inc dh
		call Gotoxy
		push edx ; save the cursor
		mov edx, OFFSET blankLine
		call WriteString
		pop edx ; restore the cursor
		call Gotoxy ; go to the cursor again
		mov edx, OFFSET vOrHPrompt
		call WriteString
	
	

		;move the values 0 and 1 to where they can be accessed by the procedure
		push ebx
		push ecx
		mov ebx, '0'
		mov ecx, '1'
		call userInputChar ;gets a user input where ebx <= input <= ecx
		sub eax, '0' ;to go from character 0 to decimal 0
		pop ecx
		pop ebx
	
		mov randVal, al ;randVal has now become our user input variable

		;set the edge limit for the more restricted direction
		mov edx, 10 ;10 is our max (squares 0 to 9)
		sub edx, ebx ;ebx is the length of the ship

	add randVal, 0
	jz placeUserShipH ;else fall through to vertical placement


	placeUserShipV: ;vertical ship placement, will never loop just back to here
		;Select the X coordinate
		push ebx
		push ecx
		mov ebx, '0'
		mov ecx, '9'
		call userInputChar
		sub eax, '0' ;to go from character 0 to decimal 0
		pop ecx
		pop ebx
		mov tempX, al

		;select the Y coordiante
		mov eax, edx
		push ebx ;get the user input
		push ecx
		mov ebx, 'A'
		add eax, 'A'
		mov ecx, eax
		call userInputChar
		sub eax, 'A' ;to go from character A to decimal 0
		pop ecx
		pop ebx
		mov tempY, al

		;edx contains the max square for placement
		;for each map square, check if placeable
		;if any are not placeable, jmp back to place cpu ships
		;the top of the stack holds the ship length
		;eax will hold the offset for the array part we are going to
		;tempX and tempY hold the coordinates for the uppermost leftmost corner of the ship

		mov eax, 0
		mov al, tempY
		push ebx
		mov ebx, 10
		mul ebx
		pop ebx
		add al, tempX

		pop edx ;edx now holds the length of the ship
		push edx ;the top of the stack still holds the length of the ship
		

		;before checking, al holds the array index for the first element to check
		;before checking, edx holds the length of the ship, and will be our temporary counter

		placeUserShipVCheck:		;"CLEAR CLEAR CLEAR CLEAR CLEAR" -spotlight

			mov ebx, OFFSET userMap.grid
			add ebx, eax
			;at this point, ebx holds the memory address of the grid square to be checked

			push eax
			mov al, BYTE PTR [ebx]
			test al, 00001110b ;are any of the ship bits set?
			jnz placeUserShipVCheckFail ;if so, there is a ship here, and the test for if we can put a ship here fails
			pop eax

			add eax, 10
			dec edx ;if the ship length is 5, we want our first offset to be 4 (adjusting for indexing from 0)
		jnz placeUserShipVCheck

			;before jumping, reset our ship length counter, put the index into ebx
			pop edx
			push edx ;so the stack counter is the same before and after this pair of operands
			jmp placeUserShipVPlop ;goto plop

		placeUserShipVCheckFail:
			pop eax ;the jump happened before eax was resotred
			pop edx ;clean up what we used of the stack (just the top element)
			jmp placeUserShips ;try all over agin to place this ship
			
		placeUserShipVPlop:		;"PLOP"
			
		;at the start of this loop, ebx holds the value of the bottomost ship index
		;at the start of this loop, edx will once more hold the number of squares in this ship (the ship length)
			mov al, cl	
			add al, cl ;2*cl = the ship code in the 2nd-4th bits ;set the ship code in the al byte
			or al, BYTE PTR [ebx]	;add the rest of the grid data to the ship code in al (the check would have failed if this byte already had a ship code)
			mov BYTE PTR[ebx], al	;store that byte

			sub ebx, 10 ;move up a row for the next time
			dec edx
		jnz placeUserShipVPlop ;this loop


		pop edx ;reset the ship length counter held in edx
		push edx ;don't change the stack state right now
		placeUserShipVPrint:
			mov ebx, edx
			push edx
			
			;set the cursor to  location and print for the ship
			mov dx, userMapCursor.X
			mov ax, userMapCursor.Y
			mov dh, al
			add dl, tempX
			dec dh
			inc dl
			add dh, bl	;this is the line that changes between the vertical and horizontal ship placement. 
						;We add the ship length to the Y coord instead of the X coord
			add dh, tempY
			call Gotoxy

			mov eax, 16*blue
			add eax, gray
			call SetTextColor
			mov eax, 'S'
			call WriteChar

			pop edx
			dec edx
			jnz placeUserShipVPrint ;This Loop

			;after fully placing this ship, dec ecx, jz to end of user ship placement
			pop edx ;take the ship length off of the stack, as we are done with it and don't want to waste memory

			dec ecx
			jnz PlaceUserships ;if we still have ships to place, jump to the top of ship placement
			jmp endUserShipPlacement ;we have placed all User ships




	placeUserShipH: ;horizontal ship placement, will never loop back to just here
	

		;select the X coordiante
		mov eax, edx
		push ebx		;get the user input
		push ecx
		mov ebx, '0'
		add eax, '0'
		mov ecx, eax 
		call userInputChar ;call the function to actually get the user input
		sub eax, '0' ;to go from character 0 to decimal 0
		pop ecx
		pop ebx
		mov tempX, al

		push ebx
		push ecx
		mov ebx, 'A'
		mov ecx, 'J'
		call userInputChar
		sub eax, 'A' ;to go from character A to decimal 0
		pop ecx
		pop ebx
		mov tempY, al

		

		;edx contains the max square for placement
		;for each map square, check if placeable
		;if any are not placeable, jmp back to place cpu ships

		;the top of the stack slready holds the ship length
		;eax will hold the offset for the array part we are going to
		;tempX and tempY hold the coordinates for the uppermost leftmost corner of the ship

		mov eax, 0
		mov al, tempY
		push ebx
		mov ebx, 10
		mul ebx
		pop ebx
		add al, tempX

		

		pop edx ;edx now holds the length of the ship
		push edx ;the top of the stack still holds the length of the ship
		

		;before checking, al holds the array index for the first element to check
		;before checking, edx holds the length of the ship, and will be our temporary counter

		placeUserShipHCheck:		;"CLEAR CLEAR CLEAR CLEAR CLEAR" -spotlight
			mov ebx, OFFSET userMap.grid
			add ebx, eax
			;at this point, ebx holds the memory address of the grid square to be checked

			push eax
			mov al, BYTE PTR [ebx]
			test al, 00001110b ;are any of the ship bits set?
			jnz placeUserShipHCheckFail ;if so, there is a ship here, and the test for if we can put a ship here fails
			pop eax 			

			inc eax ;add one, not ten, because we are placing horizontally
			dec edx ;if the ship length is 5, we want our first offset to be 4 (adjusting for indexing from 0)
		jnz placeUserShipHCheck

			;before jumping, reset our ship length counter, put the index into ebx
			pop edx
			push edx ;so the stack counter is the same before and after this pair of operands
			
			jmp placeUserShipHPlop ;goto plop

		placeUserShipHCheckFail:
			pop eax ;the jump happened before eax was resotred
			pop edx ;clean up what we used of the stack (just the top element)
			jmp placeUserShips ;try all over agin to place this ship

		placeUserShipHPlop:		;"PLOP"
			;at the start of this loop, ebx holds the value of the bottomost ship index
			;at the start of this loop, edx will once more hold the number of squares in this ship (the ship length)
		
			mov al, cl
			add al, cl ;2*cl = the ship code in the 2nd-4th bits ;WALKTHROUGH BONUS FUN
			or al, BYTE PTR [ebx]
			mov BYTE PTR[ebx], al

			push eax
			push edx
			mov al, BYTE PTR [ebx]
			call SetTextColor
			
			

			pop edx
			pop eax

			sub ebx, 1 ;move over a column for the next time
			dec edx
		jnz placeUserShipHPlop ;this loop

		pop edx
		push edx ;don't change the stack state right now
		placeUserShipHPrint:
			mov ebx, edx
			push edx
			
			;set the cursor to  location and print for the ship
			mov dx, userMapCursor.X
			mov ax, userMapCursor.Y
			mov dh, al
			add dl, tempX
			add dl, bl
			add dh, tempY
			call Gotoxy
			mov eax, 16*blue
			add eax, gray
			call SetTextColor
			mov eax, 'S'
			call WriteChar

			pop edx
			dec edx
			jnz placeUserShipHPrint ;This Loop

			;after fully placing this ship, dec ecx, jz to end of user ship placement
			pop edx ;take the ship length off of the stack, as we are done with it and don't want to waste memory

			dec ecx
			jnz PlaceUserships
			jmp endUserShipPlacement ;we have placed all User ships
	endUserShipPlacement:


gameplay:

cpuTurnStart:										;WALKTHROUGH4
mov ecx, 0 ;0 = first guess ;ecx will be used a flag to tell if we are on our first or second guess for the easy and hard AI difficulties

cpuGuessCoord:		;generate a guess coordinate that has not been checked yet
;randomly select the X coordinate
	call Randomize
	mov eax, 10
	call RandomRange
	mov tempX, al

	;randomly select the Y coordiante
	call Randomize
	mov eax, 10
	call RandomRange
	mov tempY, al

	;get the grid location of this guess into ebx
	mov eax, 0
	mov al, tempY
	mov bl, 10
	mul bl
	mov ebx, 0
	add bl, tempX
	add ebx, OFFSET userMap.grid
	add ebx, eax


	mov al, 00000001b
	and al, BYTE PTR [ebx]
	jz cpuGoodCoord ;if eax == 0 after this 'and', then the smallest bit of that grid square byte was set, which means the square was already explored
	;The AI's random guesses were making a checkerboard in a rough diagonal from the top left to bottom right, and lagging significantly towards the end of a game. 
	mov al, tempX
	push ebx
	mov bl, tempY
	mov tempY, al
	mov tempX, bl
	pop ebx
	;get the grid location of this new guess into ebx
	mov eax, 0
	mov al, tempY
	mov bl, 10
	mul bl
	mov ebx, 0
	add bl, tempX
	add ebx, OFFSET userMap.grid
	add ebx, eax


	mov al, 00000001b
	and al, BYTE PTR [ebx]
	jnz cpuGuessCoord


	cpuGoodCoord:										;WALKTHROUGH5
	mov al, aiDifficulty
	cmp al, 1
	je cpuCheckFinalGuess ;if we are medium difficulty, the first unexplored coordinate is the one that we guess

	;for easy and hard difficluties, do some other stuff, skip it on medium, and skip it on the second pass through easy and hard
	cmp ecx, 1 ;can increase this number to increase the significance of the different values
	je cpuCheckFinalGuess ;skip if we have already applied the difficulty to this guess
	cmp eax, 0
	je cpuApplyEasyDifficulty

	cpuApplyHardDifficulty:
		;ebx still holds the address of the point, so we can check if it holds a ship
		mov al, 00001110b
		and al, BYTE PTR [ebx]
		jnz cpuCheckFinalGuess ;if this point has a ship, use it as the guess
		;else make a second guess and set ecx so that the program knows that the difficulty has been applied, and jump back up to make a new guess
		inc ecx 
		jmp cpuGuessCoord

	cpuApplyEasyDifficulty:
	;ebx still holds the address of the point, so we can check if it holds a ship
		mov al, 00001110b
		and al, BYTE PTR [ebx]
		jz cpuCheckFinalGuess ;if this point does not have a ship, use it as the guess
		;else make a second guess and set ecx so that the program knows that the difficulty has been applied, and jump back up to make a new guess
		inc ecx 
		jmp cpuGuessCoord
	;

	cpuCheckFinalGuess:
	;ebx still holds the address of the point, so we can mark the square explored, check what it contains, display a hit or miss message, and update the map
	
	;mark the square explored
	mov al, BYTE PTR [ebx]
	or al, 1b
	mov BYTE PTR [ebx], al 
	;check what the square contains
	mov al, 00001110b
	and al, BYTE PTR [ebx]
	jz cpuResultMiss ;if there is no ship, treat it as a miss, else fall through to hit


	cpuResultHit: ;this label is superfluous, but I am leaving it in for clarity of program structure. It will never be jumped to.
	;update the grid square byte to contain the new color
		mov al, BYTE PTR [ebx]
		and al, 00001111b ;clear the top half
		or al, red*16 ;set the top half to red
		mov BYTE PTR [ebx], al ;set the grid square
		;update the map
		call SetTextColor
		mov dx, userMapCursor.X
		mov ax, userMapCursor.Y
		mov dh, al
		add dh, tempY
		add dl, tempX
		inc dl ;shifts the cursor right
		call Gotoxy
		mov eax, ' ' ;there is no longer an 'S' for the ship, because it is on fire
		call WriteChar
	;prepare to print a hit message, which will be displayed in the section of the ship that was hit
		mov eax, black*16
		add al, lightgray
		call SetTextColor
		mov dx, rightPromptCursor.X
		mov ax, rightPromptCursor.Y
		add ah, 1
		mov dh, al
		call Gotoxy
		push edx ;push the cursor
		mov edx, OFFSET blankLine
		call WriteString
		pop edx ;restore the cursor
		call Gotoxy ;go to the cursor again
		
	;set ecx to 1, to flag for the gameovercheck (so it knows it arrived there from a cpu turn, and should go to a user turn)
	mov ecx, 1
	;find out which ship was hit										;WALKTHROUGH6
	;update the hit counter for that ship
	;print the relevant hit message
		mov al, 00001110b
		and al, BYTE PTR [ebx]
		cpuHitShip2:
			cmp al, 0010b
			jg cpuHitShip3A 
			inc userMap.Ship2 
			mov edx, OFFSET cpuHitMsg2
			call WriteString
		jmp gameOvercheck
		cpuHitShip3A:
			cmp al, 0100b
			jg cpuHitShip3B 
			inc userMap.Ship3A
			mov edx, OFFSET cpuHitMsg3
			call WriteString
		jmp gameOvercheck
		cpuHitShip3B:
			cmp al, 0110b
			jg cpuHitShip4 
			inc userMap.Ship3B
			mov edx, OFFSET cpuHitMsg3
			call WriteString 
		jmp gameOverCheck
		cpuHitShip4:
			cmp al, 1000b
			jg cpuHitShip5 
			inc userMap.Ship4
			mov edx, OFFSET cpuHitMsg4
			call WriteString 
		jmp gameOvercheck
		cpuHitShip5:
			inc userMap.Ship5
			mov edx, OFFSET cpuHitMsg5
			call WriteString 
		jmp gameOverCheck

	cpuResultMiss:	;update the grid square color, display a miss message, and update the map
	;update the grid square byte to contain the new color
		mov al, BYTE PTR [ebx]
		and al, 00001111b ;clear the top half
		or al, lightblue*16 ;set the top half to red
		mov BYTE PTR [ebx], al ;set the grid square
	;update the map
		call SetTextColor
		mov dx, userMapCursor.X
		mov ax, userMapCursor.Y
		mov dh, al
		add dh, tempY
		add dl, tempX
		inc dl ;moves the cursor right
		call Gotoxy
		mov eax, ' '
		call WriteChar
	;prepare and print the message
		mov eax, black*16
		add al, lightgray
		call SetTextColor
		mov dx, rightPromptCursor.X
		mov ax, rightPromptCursor.Y
		add ah, 1
		mov dh, al
		call Gotoxy
		push edx ;push the cursor
		mov edx, OFFSET blankLine
		call WriteString
		pop edx ;restore the cursor
		call Gotoxy ;go to the cursor again
		mov edx, OFFSET cpuMissMsg
		call WriteString
		jmp userTurnStart ;yes, this could just fall through
userTurnStart:
userGuesscoord:
	;Select the X coordinate
		push ebx ;preserve ebx and ecx while getting the user input
		push ecx
		mov ebx, '0'
		mov ecx, '9'
		call userInputChar
		sub eax, '0' ;to go from character 0 to decimal 0
		pop ecx
		pop ebx
		mov tempX, al

		;select the Y coordiante
		push ebx ;preserve ebx and ecx while getting the user input
		push ecx
		mov ebx, 'A'
		mov ecx, 'J'
		call userInputChar
		sub eax, 'A' ;to go from character A to decimal 0
		pop ecx
		pop ebx
		mov tempY, al

		;get the grid location of this guess into ebx
	mov eax, 0
	mov al, tempY
	mov bl, 10
	mul bl
	mov ebx, 0
	add bl, tempX
	add ebx, OFFSET cpuMap.grid
	add ebx, eax
		 
		 mov al, 00000001b
	and al, BYTE PTR [ebx]
	jnz userGuessCoord ;if eax == 0 after this 'and', then the smallest bit of that grid square byte was set, which means the square was already explored

	userCheckFinalGuess:
	;ebx still holds the address of the point, so we can mark the square explored, check what it contains, display a hit or miss message, and update the map
	
	;mark the square explored
	mov al, BYTE PTR [ebx]
	or al, 1b
	mov BYTE PTR [ebx], al 
	;check what the square contains
	mov al, 00001110b
	and al, BYTE PTR [ebx]
	jz userResultMiss ;if there is no ship, treat it as a miss, else fall through to hit

	userResultHit: ;this label is superfluous
	;update the grid square byte to contain the new color
		mov al, BYTE PTR [ebx]
		and al, 00001111b ;clear the top half
		or al, red*16 ;set the top half to red
		mov BYTE PTR [ebx], al ;set the grid square
		;update the map
		call SetTextColor
		mov dx, cpuMapCursor.X
		mov ax, cpuMapCursor.Y
		mov dh, al
		add dh, tempY
		add dl, tempX
		inc dl ;moves the cursor right
		call Gotoxy
		mov eax, ' ' ;the user map only ever prints in spaces
		call WriteChar
	;prepare to print a hit message, which will be displayed in the section of the ship that was hit
		mov eax, black*16
		add al, lightgray
		call SetTextColor
		mov dx, rightPromptCursor.X
		mov ax, rightPromptCursor.Y
		add al, 4
		mov dh, al
		call Gotoxy
		push edx ;push the cursor
		mov edx, OFFSET blankLine
		call WriteString
		pop edx ;restore the cursor
		call Gotoxy ;go to the cursor again
		
	;set ecx to 0, to flag for the gameovercheck (so it knows it arrived there from a user turn, and should go to a cpu turn)
	mov ecx, 0
	;find out which ship was hit
	;update the hit counter for that ship
	;print the relevant hit message
		mov al, 00001110b
		and al, BYTE PTR [ebx]
		userHitShip2:
			cmp al, 0010b
			jg userHitShip3A 
			inc cpuMap.Ship2 
			mov edx, OFFSET userHitMsg2
			call WriteString
		jmp gameOvercheck
		userHitShip3A:
			cmp al, 0100b
			jg userHitShip3B 
			inc cpuMap.Ship3A
			mov edx, OFFSET userHitMsg3
			call WriteString
		jmp gameOvercheck
		userHitShip3B:
			cmp al, 0110b
			jg userHitShip4 
			inc cpuMap.Ship3B
			mov edx, OFFSET userHitMsg3
			call WriteString 
		jmp gameOverCheck
		userHitShip4:
			cmp al, 1000b
			jg userHitShip5 
			inc cpuMap.Ship4
			mov edx, OFFSET userHitMsg4
			call WriteString 
		jmp gameOvercheck
		userHitShip5:
			inc cpuMap.Ship5
			mov edx, OFFSET userHitMsg5
			call WriteString 
		jmp gameOverCheck

	userResultMiss:	;update the grid square color, display a miss message, and update the map
	;update the grid square byte to contain the new color
		mov al, BYTE PTR [ebx]
		and al, 00001111b ;clear the top half
		or al, lightblue*16 ;set the top half to red
		mov BYTE PTR [ebx], al ;set the grid square
	;update the map
		call SetTextColor
		mov dx, cpuMapCursor.X
		mov ax, cpuMapCursor.Y
		mov dh, al
		add dh, tempY
		add dl, tempX
		inc dl ;moves the cursor right
		call Gotoxy
		mov eax, ' '
		call WriteChar
	;print the message
		mov eax, black*16
		add al, lightgray
		call SetTextColor
		mov dx, rightPromptCursor.X
		mov ax, rightPromptCursor.Y
		add al, 4
		mov dh, al
		call Gotoxy
		push edx ;push the cursor
		mov edx, OFFSET blankLine
		call WriteString
		pop edx ;restore the cursor
		call Gotoxy ;go to the cursor again
		mov edx, OFFSET userMissMsg
		call WriteString
		jmp cpuTurnStart
;during gameplay
	;alternate user and CPU turns, the user will always guess first
	;check if the game has ended after ships are sunk
	;each turn will consist of a guess, the results of that guess, and a pause while those results are displayed



gameOverCheck:										;WALKTHROUGH7
;if ecx == 0, then it was a user turn, if ecx == 1, then it was a cpu turn 
cmp ecx, 0
je gameOverCheckCpuShips

gameOverCheckUserShips:	;if all counters are full the game is over, else go to a new user turn
cmp userMap.ship2, 2
jne userTurnStart;
cmp userMap.ship3A, 3
jne userTurnStart;
cmp userMap.ship3B, 3
jne userTurnStart;
cmp userMap.ship4, 4
jne userTurnStart;
cmp userMap.ship5, 5
jne endgame;

gameOverCheckCpuShips:	;if all counters are full, the game is over, else go to a new cpu turn
cmp cpuMap.ship2, 2
jne cpuTurnStart;
cmp cpuMap.ship3A, 3
jne cpuTurnStart;
cmp cpuMap.ship3B, 3
jne cpuTurnStart;
cmp cpuMap.ship4, 4
jne cpuTurnStart;
cmp cpuMap.ship5, 5
je endgame;





endgame:										;WALKTHROUGH8
;in the endgame
	;display the endgame screen (or the final map, possibly revealing cpu ships)
	;display a win or loss message
	;prompt the user to play again


	mov eax, black*16 ;reset the cursor
		add al, lightgray
		call SetTextColor
		mov dx, promptCursor.X
		mov ax, promptCursor.Y
		sub al, 2
		mov dh, al
		call Gotoxy

		cmp ecx, 0
		je endgameWin
	endgameLoss:
		mov edx, OFFSET userLossMsg
		call WriteString
		jmp postEndgame
	endgameWin:
		mov edx, OFFSET userWinMsg
		call WriteString
		jmp postEndgame

postEndgame:

    exit
main ENDP

										;WALKTHROUGH9
;---------------------------------------------------------
UserInputChar PROC
;
; Returns a user input in the given range
; Receives: EBX, ECX. Two ascii characters that the number will be between (inclusive)
; Returns: EAX = the valid input value
; EFLAGS are changed
; Requires: nothing
;---------------------------------------------------------
	userInputStart:
	push edx
	mov dx, promptCursor.X
	mov ax, promptCursor.Y
	mov dh, al
	call Gotoxy

	mov edx, OFFSET blankLine
	call WriteString

	mov dx, promptCursor.X
	mov ax, promptCursor.Y
	mov dh, al
	call Gotoxy


	mov edx, OFFSET inputPrompt1
	call WriteString
	mov eax, ebx
	call WriteChar
	mov edx, OFFSET inputPrompt2
	call WriteString
	mov eax, ecx
	call WriteChar
	mov edx, OFFSET inputPrompt3
	call WriteString
	pop edx
	mov eax, 0
	call ReadChar
	;mov edx, OFFSET lineFeed
	;call WriteString

	call WriteChar

	push eax		;pause to echo the input
	call ReadChar
	pop eax


	cmp al, bl
	jl userInputStart
	cmp al, cl
	jg userInputStart

	userInputEnd:

		ret
userInputChar ENDP




END main
