#To be inserted at 8024d92c
.include "../../Globals.s"

backup

#Check For L
	li	r3,4
	branchl	r12,Inputs_GetPlayerInstantInputs
	rlwinm.	r0, r4, 0, 25, 25			#CHECK FOR L
	bne	OpenFDD
	rlwinm.	r0, r4, 0, 27, 27			#CHECK FOR Z
	bne	OpenOptions

#Check for Tutotial (R)
#Check For Training Mode ISO Game ID First
	lis	r5,0x8000
	lwz	r5,0x0(r5)
	load	r6,0x47544d45			#GTME
	cmpw	r5,r6
	bne	CheckToSwitchPage
#Check for R
	rlwinm.	r0, r4, 0, 26, 26			#CHECK FOR R
	bne	PlayMovie

CheckToSwitchPage:
	li	r3,4
	branchl	r12,Inputs_GetPlayerRapidInputs
#Check For Left
	li	r5,-1
	rlwinm. r0,r3,0,25,25
	bne	SwitchPage
#Check For Right
	li	r5,1
	rlwinm. r0,r3,0,24,24
	bne	SwitchPage
	b	exit

OpenFDD:

	#PLAY SFX
	li	r3, 1
	branchl	r4,0x80024030

	#SET FLAG IN RULES STRUCT
	li	r0,3								#3 = frame data from event toggle
	load	r3,0x804a04f0
	stb	r0, 0x0011 (r3)

	#SET SOMETHING
	li	r0, 5
	sth	r0, -0x4AD8 (r13)

	#BACKUP CURRENT EVENT ID
	lwz	r3, -0x4A40 (r13)
	lwz	r5, 0x002C (r3)
	lbz	r3,0x0(r5)
	lwz	r4,0x4(r5)
	add	r3,r3,r4
	lwz	r4, -0x77C0 (r13)
	stb	r3, 0x0535 (r4)

	#LOAD RSS
	branchl	r3,0x80237410

	#REMOVE EVENT THINK FUNCTION
	lwz	r3, -0x3E84 (r13)
	branchl	r12,0x80390228

	b	exit

OpenOptions:

#Create Background + GObj
	bl	OptionMenu_CreateBackground
#Display Menus Text
	bl	MenuData_MainMenuBlrl
	mflr r4
	bl	OptionMenu_CreateText
#Play SFX
	li	r3,1
	branchl r12,0x80024030
	b	exit

#region OptionMenu_CreateBackground
OptionMenu_CreateBackground:
.set	REG_GObj,20
.set	REG_GObjData,21

#this returns a pointer to the gobj

backup

#Create Background GObj
  li  r3,6
  li  r4,7
  li  r5,0x80
  branchl r12,GObj_Create
  mr  REG_GObj,r3
#Allocate Space
	li	r3,64
	branchl r12,HSD_MemAlloc
	mr	REG_GObjData,r3
#Zero
	li	r4,64
	branchl r12,ZeroAreaLength
#Initialize
	mr	r6,REG_GObjData
	mr	r3,REG_GObj
	li	r4,4
	load	r5,0x8037f1b0
	branchl r12,GObj_AddUserData
#Add Process
	mr	r3,REG_GObj
	bl	OptionMenu_Think
	mflr r4
	li	r5,0
	branchl r12,GObj_AddProc
#Get JObj from archive
  lwz	r3, -0x4AE8 (r13)
  load r4,0x803efa0c
  branchl r12,0x80380358
#Load JObj
  branchl r12,HSD_JObjLoadJoint
#Get child JObj (the black background)
	lwz r3,0x10(r3)
#Remove parent and child (the message box)
	li	r4,0
	stw r4,0x0c(r3)
	stw r4,0x10(r3)
#Adjust transparency
	lwz r4,0x18(r3)
	lwz r4,0x8(r4)
	lwz r4,0xC(r4)
	bl	BG_Constants
	mflr r5
	lfs f1,BG_Transparency(r5)
	stfs f1,0xC(r4)
#Adjust color
	lwz r6,BG_Color(r5)
	stw r6,0x4(r4)
#Adjust Scale
	lfs f1,BG_ScaleX(r5)
	stfs f1,0x2C(r3)
	lfs f1,BG_ScaleY(r5)
	stfs f1,0x30(r3)
#Adjust Position
	lfs f1,BG_TransformX(r5)
	stfs f1,0x38(r3)
	lfs f1,BG_TransformY(r5)
	stfs f1,0x3C(r3)
	lfs f1,BG_TransformZ(r5)
	stfs f1,0x40(r3)
#Store JObj to GObj
  mr  r5,r3
  mr  r3,REG_GObj
  lbz	r4, -0x3E57 (r13)
  branchl r12,GObj_StorePointerToJObj
#Add GX Link
  mr  r3,REG_GObj
  load r4,0x80391070
  li  r5,7                    #layer id? higher = drawn later
  li  r6,127                  #priority, higher = drawn later
  branchl r12,GObj_AddGXLink

#Return the GObj
	mr	r3,REG_GObj

#Exit
	restore
	blr

BG_Constants:
blrl
.set BG_Transparency,0x0
.set BG_ScaleX,0x4
.set BG_ScaleY,0x8
.set BG_TransformX,0xC
.set BG_TransformY,0x10
.set BG_TransformZ,0x14
.set BG_Color,0x18
.float 0.85				#transparency
.float 0.1				#scale X
.float 0.15				#scale Y
.float 7					#X Position
.float 3					#Y position
.float 20					#Z Position
.long 0x000000FF	#Color
#endregion

#region OptionMenu_Think
OptionMenu_Think:
blrl
.set REG_GObj,31
backup

#Backup
	mr	REG_GObj,r3
	lwz	REG_GObjData,0x2C(REG_GObj)

#Disable Event Menu
	li	r3,1
	sth	r3, -0x4AD8 (r13)

#Check for Z and close menu
	li	r3,4
	branchl r12,Inputs_GetPlayerInstantInputs
	rlwinm.	r0, r4, 0, 27, 27			#CHECK FOR Z
	bne	OptionMenu_ThinkDestroy
	rlwinm.	r0, r3, 0, 26, 26			#CHECK FOR Down
	bne OptionMenu_ThinkDown
	rlwinm.	r0, r3, 0, 27, 27			#CHECK FOR Up
	bne OptionMenu_ThinkUp
	rlwinm.	r0, r3, 0, 31, 31			#CHECK FOR A
	bne OptionMenu_ThinkSelect
	rlwinm.	r0, r3, 0, 30, 30			#CHECK FOR B
	bne OptionMenu_ThinkBack
	b	OptionMenu_ThinkExit

OptionMenu_ThinkDown:
#Down one cursor position
	lwz	r3,Cursor(REG_GObjData)
	addi r4,r3,1
#Highlight current cursor
	mr	r3,REG_GObjData
	bl	OptionMenu_AdjustCursor
#Play SFX
	li	r3,2
	branchl r12,0x80024030
	b	OptionMenu_ThinkExit

OptionMenu_ThinkUp:
#Up one cursor position
	lwz	r3,Cursor(REG_GObjData)
	subi r4,r3,1
#Highlight current cursor
	mr	r3,REG_GObjData
	bl	OptionMenu_AdjustCursor
#Play SFX
	li	r3,2
	branchl r12,0x80024030
	b	OptionMenu_ThinkExit

OptionMenu_ThinkSelect:
#Loop through current menu
.set REG_Count,20
.set REG_OptionData,22
.set REG_OptionCount,23
.set REG_MenuData,24
.set REG_Cursor,25
#Init
	li	REG_Count,0														#loop count
	li	REG_OptionCount,0											#Only incremented when an option is found
	lwz	REG_MenuData,MenuData(REG_GObjData)
	lwz	REG_Cursor,Cursor(REG_GObjData)

OptionMenu_ThinkSelect_SearchOptionsLoop:
#Get this option's text
	addi r3,REG_MenuData,MenuData_OptionsStart
	mulli	r4,REG_Count,MenuData_OptionDataLength
	add	REG_OptionData,r3,r4
#Get OnSelectType
	lwz 	r3,MenuData_OnSelectType(REG_OptionData)
	cmpwi	r3,OnSelect_None
	beq	OptionMenu_ThinkSelect_SearchOptionsIncLoop
#Check if this is the desired option
	cmpw REG_OptionCount,REG_Cursor
	beq OptionMenu_ThinkSelect_SelectOption
#Increment Option Count
	addi	REG_OptionCount,REG_OptionCount,1
	b	OptionMenu_ThinkSelect_SearchOptionsIncLoop

OptionMenu_ThinkSelect_SelectOption:
#Play SFX
	li	r3,1
	branchl r12,0x80024030
#Decide Selection Type
	lwz	r3,MenuData_OnSelectType(REG_OptionData)
	cmpwi	r3,OnSelect_Menu
	beq	OptionMenu_ThinkSelect_GetNextMenu
	cmpwi	r3,OnSelect_Function
	beq	OptionMenu_ThinkSelect_GetFunction
	b	OptionMenu_ThinkSelect_SearchOptionsEnd

OptionMenu_ThinkSelect_GetNextMenu:
#Convert bl instruction to mem address
	addi	r4,REG_OptionData,MenuData_OnSelectData
	lwz	r5,0x0(r4)
  rlwinm	r5,r5,0,6,29		#Mask Bits 6-29 (the offset)
	extsh	r5,r5
  add	r4,r4,r5						#Gets Address in r3
#Create Text
	mr	r3,REG_GObj
	bl	OptionMenu_CreateText
	b	OptionMenu_ThinkSelect_SearchOptionsEnd

OptionMenu_ThinkSelect_GetFunction:
#Convert bl instruction to mem address
	addi	r4,REG_OptionData,MenuData_OnSelectData
	lwz	r5,0x0(r4)
  rlwinm	r5,r5,0,6,29		#Mask Bits 6-29 (the offset)
	extsh	r5,r5
	cmpwi	r5,0
	beq	OptionMenu_ThinkSelect_NoFunction
  add	r4,r4,r5						#Gets Address in r3
	mtctr	r4
	mr	r3,REG_GObj
	bctrl
	b	OptionMenu_ThinkSelect_SearchOptionsEnd
OptionMenu_ThinkSelect_NoFunction:
#Play Error Sound
  li	r3, 3
  branchl	r12,0x80024030
  li	r3, 3
  branchl	r12,0x80024030
	b	OptionMenu_ThinkSelect_SearchOptionsEnd

OptionMenu_ThinkSelect_SearchOptionsIncLoop:
	addi REG_Count,REG_Count,1
	b	OptionMenu_ThinkSelect_SearchOptionsLoop

OptionMenu_ThinkSelect_SearchOptionsEnd:
	b	OptionMenu_ThinkExit

OptionMenu_ThinkBack:
.set REG_MenuData,24
	lwz	r4,MenuData(REG_GObjData)
#Convert bl instruction to mem address
	addi	r4,r4,MenuData_ReturnMenu
	lwz	r5,0x0(r4)
  rlwinm	r5,r5,0,6,29		#Mask Bits 6-29 (the offset)
	extsh	r5,r5
	cmpwi	r5,0
	beq OptionMenu_ThinkDestroy
  add	r4,r4,r5						#Gets Address in r4
#Load Prev Menu
	mr	r3,REG_GObj
	bl	OptionMenu_CreateText
#Play SFX
	li	r3,0
	branchl r12,0x80024030
	b	OptionMenu_ThinkExit

OptionMenu_ThinkDestroy:
#Remove text
	lwz	r3,0x2C(REG_GObj)
	lwz	r3,TextGObj(r3)
	branchl r12,Text_RemoveText
#Remove GObj
	mr	r3,REG_GObj
	branchl r12,GObj_Destroy
#Play SFX
	li	r3,0
	branchl r12,0x80024030

OptionMenu_ThinkExit:
	restore
	blr
#endregion

#region OptionMenu_CreateText
OptionMenu_CreateText:
.set REG_MenuData,28
.set REG_GObjData,29
.set REG_TextProp,30
.set REG_TextGObj,31

#GObj Data Struct
.set Cursor,0x0
.set TextGObj,0x4
.set MenuData,0x8

#MenuData Struct
.set MenuData_ReturnMenu,0x0
.set MenuData_OptionsStart,0x4
	.set MenuData_OptionDataLength,0xC
	.set MenuData_OptionName,0x0
	.set MenuData_OnSelectType,0x4
	.set MenuData_OnSelectData,0x8

backup

#Backup GObj and MenuData
	lwz	REG_GObjData,0x2C(r3)
	mr	REG_MenuData,r4

#Check if a text gobj already
	lwz r3,TextGObj(REG_GObjData)
	cmpwi r3,0
	beq OptionMenu_CreateText_SkipDestroyOldText
#Destroy
	branchl r12,Text_RemoveText
	li	r3,0
	stw r3,TextGObj(REG_GObjData)
OptionMenu_CreateText_SkipDestroyOldText:

#Store new menudata
	stw	REG_MenuData,MenuData(REG_GObjData)

#GET PROPERTIES TABLE
	bl TextProperties
	mflr REG_TextProp

########################
## Create Text Object ##
########################

#CREATE TEXT OBJECT, RETURN POINTER TO STRUCT IN r3
	li r3,0
	li r4,1
	branchl r12,Text_CreateTextStruct
	stw r3,TextGObj(REG_GObjData)
#BACKUP STRUCT POINTER
	mr REG_TextGObj,r3
#SET TEXT SPACING TO TIGHT
	li r4,0x1
	stb r4,0x49(REG_TextGObj)
#SET TEXT TO CENTER AROUND X LOCATION
	li r4,0x0
	stb r4,0x4A(REG_TextGObj)
#Store Base Z Offset
	lfs f1,ZOffset(REG_TextProp) #Z offset
	stfs f1,0x8(REG_TextGObj)
#Scale Canvas Down
  lfs f1,CanvasScaling(REG_TextProp)
  stfs f1,0x24(REG_TextGObj)
  stfs f1,0x28(REG_TextGObj)

OptionMenu_CreateText_PrintOptions:
.set REG_Count,20
.set REG_ASCII,21
.set REG_OptionData,22
.set OFST_LastYPos,0x80
#Init
	li	REG_Count,0									#loop count
	lfs	f1,VersionY(REG_TextProp)		#Last text's Y position
	stfs	f1,OFST_LastYPos(sp)

OptionMenu_CreateText_PrintOptionsLoop:
#Get this option's text
	addi r3,REG_MenuData,MenuData_OptionsStart
	mulli	r4,REG_Count,MenuData_OptionDataLength
	add	REG_OptionData,r3,r4
#Convert bl instruction to mem address
  lwz	r4,0x0(REG_OptionData)		#Get bl Instruction
	extsb	r5,r4										#Check if none left
	cmpwi	r5,-1
	beq OptionMenu_CreateText_PrintOptionsEnd
  rlwinm	r4,r4,0,6,29							#Mask Bits 6-29 (the offset)
	extsh	r4,r4
  add	REG_ASCII,REG_OptionData,r4		#Gets ASCII Address in r3

#Get Y offset
	lfs	f2,OFST_LastYPos(sp)		 	#Y base offset of REG_TextGObj
	lfs	f3,YOffset(REG_TextProp)			#Y offset difference
	fadds	f2,f2,f3
#Check if this is the first option
	cmpwi REG_Count,0
	beq OptionMenu_CreateText_PrintOptions_SkipTitleAdjust
#Check if last option was a title
	lwz	r3,-MenuData_OptionDataLength + MenuData_OnSelectType(REG_OptionData)
	cmpwi	r3,OnSelect_None
	bne	OptionMenu_CreateText_PrintOptions_SkipTitleAdjust
#Move down further
	lfs	f1,YOffsetAddAfterTitle(REG_TextProp)
	fadds	f2,f1,f2

OptionMenu_CreateText_PrintOptions_SkipTitleAdjust:
#Store as last Y position
	stfs	f2,OFST_LastYPos(sp)
#Initialize Subtext
	mr 	r3,REG_TextGObj		#struct pointer
	mr	r4,REG_ASCII			#text
	lfs	f1,VersionX(REG_TextProp) 		#X offset of REG_TextGObj
	branchl r12,0x803a6b98

#Change Text Scale
	mr 	r3,REG_TextGObj		#struct pointer
	mr	r4,REG_Count
	lfs 	f1,Scale(REG_TextProp) 		#X offset of REG_TextGObj
	lfs 	f2,Scale(REG_TextProp)	  	#Y offset of REG_TextGObj
	branchl r12,Text_UpdateSubtextSize

OptionMenu_CreateText_PrintOptionsIncLoop:
	addi REG_Count,REG_Count,1
	b	OptionMenu_CreateText_PrintOptionsLoop

OptionMenu_CreateText_PrintOptionsEnd:

#Reset cursor position
	li	r3,0
#Highlight current cursor
	mr	r4,r3
	mr	r3,REG_GObjData
	bl	OptionMenu_AdjustCursor



#Exit
	restore
	blr

TextProperties:
blrl
.set VersionX,0x0
.set VersionY,0x4
.set ZOffset,0x8
.set CanvasScaling,0xC
.set Scale,0x10
.set YOffset,0x14
.set YOffsetAddAfterTitle,0x18
.float 100      #REG_TextGObj X pos
.float -250  		#REG_TextGObj Y pos
.float 21.9     #Z offset
.float 0.035   	#Canvas Scaling
.float 0.65			#Text scale
.float 30				#Y offset difference
.float 20				#Y Offset to Add After Title
#endregion

#region OptionMenu_AdjustCursor
OptionMenu_AdjustCursor:
.set REG_GObjData,31
.set REG_TextGObj,30
.set REG_Cursor,29

backup

#Backup
	mr	REG_GObjData,r3
	lwz	REG_TextGObj,TextGObj(REG_GObjData)
	mr	REG_Cursor,r4

#Change all options to white
OptionMenu_AdjustCursor_ResetColors:
.set REG_Count,20
#Init
	li	REG_Count,0									#loop count
OptionMenu_AdjustCursor_ResetColorsLoop:
#Adjust Subtext
	mr 	r3,REG_TextGObj		#struct pointer
	mr	r4,REG_Count			#subtext text
	load	r5,0xFFFFFF00
	stw	r5,0x80(sp)
	addi	r5,sp,0x80
	branchl r12,Text_ChangeTextColor

OptionMenu_AdjustCursor_ResetColorsIncLoop:
	addi	REG_Count,REG_Count,1
#Get number of subtexts
	lwz	r3,0x64(REG_TextGObj)
	lwz	r3,0xC(r3)
	cmpw REG_Count,r3
	blt OptionMenu_AdjustCursor_ResetColorsLoop

#Ensure this isnt below 0
	cmpwi REG_Cursor,0
	bge OptionMenu_AdjustCursor_SearchOptions
#Adjust to be 0
	li	REG_Cursor,0

#Loop through current menu
OptionMenu_AdjustCursor_SearchOptions:
.set REG_Count,20
.set REG_ASCII,21
.set REG_OptionData,22
.set REG_OptionCount,23
.set REG_MenuData,24
#Init
	li	REG_Count,0									#loop count
	li	REG_OptionCount,0						#Only incremented when an option is found
	lwz	REG_MenuData,MenuData(REG_GObjData)

OptionMenu_AdjustCursor_SearchOptionsLoop:
#Get this option's text
	addi r3,REG_MenuData,MenuData_OptionsStart
	mulli	r4,REG_Count,MenuData_OptionDataLength
	add	REG_OptionData,r3,r4
#Convert bl instruction to mem address
  lwz	r4,0x0(REG_OptionData)		#Get bl Instruction
	extsb	r5,r4										#Check if none left
	cmpwi	r5,-1
	bne	OptionMenu_AdjustCursor_SearchOptionsNotLast
	subi REG_Count,REG_Count,1
	subi REG_OptionCount,REG_OptionCount,1
	b	OptionMenu_AdjustCursor_SearchOptionsChangeColor
#Get OnSelectType
OptionMenu_AdjustCursor_SearchOptionsNotLast:
	lwz 	r3,MenuData_OnSelectType(REG_OptionData)
	cmpwi	r3,OnSelect_None
	beq	OptionMenu_AdjustCursor_SearchOptionsIncLoop
#Check if this is the desired option
	cmpw REG_OptionCount,REG_Cursor
	beq OptionMenu_AdjustCursor_SearchOptionsChangeColor
#Increment Option Count
	addi	REG_OptionCount,REG_OptionCount,1
	b	OptionMenu_AdjustCursor_SearchOptionsIncLoop

OptionMenu_AdjustCursor_SearchOptionsChangeColor:
#Adjust Subtext
	mr 	r3,REG_TextGObj		#struct pointer
	mr	r4,REG_Count			#subtext text
	load	r5,0xFFFF0000		#color
	stw	r5,0x80(sp)
	addi	r5,sp,0x80
	branchl r12,Text_ChangeTextColor

#Update Cursor Position
	stw	REG_OptionCount,Cursor(REG_GObjData)
	b	OptionMenu_AdjustCursor_SearchOptionsEnd

OptionMenu_AdjustCursor_SearchOptionsIncLoop:
	addi REG_Count,REG_Count,1
	b	OptionMenu_AdjustCursor_SearchOptionsLoop

OptionMenu_AdjustCursor_SearchOptionsEnd:
#Exit
	restore
	blr
#endregion

#region MenuData
.set OnSelect_None,0
.set OnSelect_Menu,1
.set OnSelect_Function,2

#region Options
MenuData_MainMenuBlrl:
blrl
MenuData_MainMenu:
#Return menu
	.long 0
#Options
	bl	MenuData_MainMenu_OptionsName
	.long	OnSelect_None
	.long 0
#Create Save File
	bl	MenuData_MainMenu_CreateSaveName
	.long	OnSelect_Menu
	bl	MenuData_CreateSave
#Play
	bl	MenuData_MainMenu_PlayCreditsName
	.long	OnSelect_Function
	bl	LoadCredits
	.long -1
.align 2

MenuData_MainMenu_OptionsName:
.string "Options"
.align 2
MenuData_MainMenu_PlayCreditsName:
.string "Show Credits"
.align 2
MenuData_MainMenu_CreateSaveName:
.string "Create Save"
.align 2
#endregion
#region Create Save
MenuData_CreateSave:
#Return menu
	bl	MenuData_MainMenu
#Create Save
	bl	MenuData_MainMenu_CreateSaveName
	.long	OnSelect_None
	.long 0
#Play
	bl	MenuData_CreateSave_SlotA
	.long	OnSelect_Function
	.long 0#bl	CreateSave_SlotA
#Create Save File
	bl	MenuData_CreateSave_SlotB
	.long	OnSelect_Function
	.long 0#bl	CreateSave_SlotB
.long -1
.align 2

MenuData_CreateSave_SlotA:
.string "Save to SlotA"
.align 2
MenuData_CreateSave_SlotB:
.string "Save to SlotB"
.align 2

CreateSave_SlotA:
	li	r3,0
	b	CreateSave

CreateSave_SlotB:
	li	r3,1
	b	CreateSave
#endregion

#endregion

#region CreateSave
CreateSave:
.set MemcardFileList,0x804333c8
.set REG_MemcardSlot,20
backup

#Backup slot
	mr	REG_MemcardSlot,r3

#Backup current Game ID
  addi r3,sp,0xB0
  lis r4,0x8000
  branchl r12,strcpy
#Change Game ID to Melee's
  lis r3,0x8000
  bl  MeleeGameID
  mflr r4
  branchl r12,strcpy

#Get memcard pointer
.set REG_Memcard,30
  lwz	REG_Memcard, -0x77C0 (r13)

###########################
## Create Main Save File ##
###########################

#Check if save file already exists
	mr	r3,REG_MemcardSlot
	load	r6,0x803bab60
	addi	r4, r6, 252
	addi	r5, r6, 20
	load r7,0x8043331C
  branchl r12,0x8001b7e0
  cmpwi r3,0x1
  bne CreateMainSave

DeleteMainSave:
	mr	r3,REG_MemcardSlot
	load	r4,0x803bac5c
	load	r5,0x8043331c
  branchl r12,0x8001ba44
  cmpwi r3,0
  bne SaveError

CreateMainSave:
.set REG_OldSaveBackup,31
#Allocate mem to backup current save data to
  load  r3,68144
  branchl r12,HSD_MemAlloc
  mr  REG_OldSaveBackup,r3
#Copy old data here
  mr	r4, REG_Memcard
  load  r5,68144
  branchl r12,memcpy
#Start building exploit
  addi r3,REG_Memcard,0x3190    #destination
  load r4,0xdd064bdd            #data to write
  li  r5,0xD4                   #length to write
  subi r3,r3,4
ExploitFillLoop:
  stwu r4,0x4(r3)
  subi r5,r5,0x4
  cmpwi r5,0
  bgt ExploitFillLoop
#Place LR hijacks
  mr	r3, REG_Memcard
  load  r4,0x804eeac8
  stw r4,0x3230(r3)
  load  r4,0x8045d930
  stw r4,0x3234(r3)
  load  r4,0x804ee8f8
  stw r4,0x3264(r3)
  load  r4,0x8045d930
  stw r4,0x3268(r3)
#Place exploit code for 1.02
  addi r3,REG_Memcard,0x3270             #exploit code destination
  bl  ExploitCode102
  mflr r4
  li  r5,0xD30                  #length of code
  branchl r12,memcpy
#Place exploit code for 1.00
  addi r3,REG_Memcard,0x5238             #exploit code destination
  bl  ExploitCode100
  mflr r4
  li  r5,0x80                  #length of code
  branchl r12,memcpy
#Place exploit code for 1.01
  addi r3,REG_Memcard,0x3f50            #exploit code destination
  bl  ExploitCode101
  mflr r4
  li  r5,0x80                  #length of code
  branchl r12,memcpy

#Run onSaveCreate functions (enable UCF and unlock trophies)
  OnSaveCreate

#Unlock All Messages
  addi r3,REG_Memcard,0x1B4C
  li  r4,0xFF
  li  r5,0x34
  branchl r12,0x80003100

#Only Mewtwo Unlocked
  li  r3,0x8
  stb r3,6249(REG_Memcard)

#Wipe High Scores
  addi r3,REG_Memcard,0x1A70
  li  r4,0
  li  r5,0xCC
  branchl r12,0x80003100
#Set as unplayed
  li  r3,0
  stw r3,0x1A68(REG_Memcard)
  stw r3,0x1A6C(REG_Memcard)

#Create Save
	mr	r3,REG_MemcardSlot
	load	r6,0x803bab60
	addi	r5,r6,20
	addi	r4,r6,252
	bl	MainSaveName
	mflr r7
	load	r10,0x80433318
	lwz	r9,0x5C(r10)
	lwz r8,0x8(r9)					#banner data with flames
	lwz r9,0xC(r9)					#icon data
	addi	r10,r10,4
  branchl r12,0x8001bc18
  cmpwi r3,0
  bne SaveError
#Copy original save data back
  mr	r3, REG_Memcard
  mr  r4,REG_OldSaveBackup
  load  r5,68144
  branchl r12,memcpy
#Free allocation
  mr  r3,REG_OldSaveBackup
  branchl r12,HSD_Free

##########################
## Create Snapshot File ##
##########################

#Update list of present memcard snapshots
  mr	r3,REG_MemcardSlot
  branchl r12,0x80253e90

.set REG_Count,31
.set REG_Index,30
.set REG_SnapshotStruct,29
.set REG_SnapshotID,28
#Check if file exists on card
  load  r3,MemcardFileList                            #go to pointer location
  lwz REG_SnapshotStruct,0x0(r3)                      #access pointer to snapshot file list
	mulli	r3,REG_MemcardSlot,1032
	add	REG_SnapshotStruct,REG_SnapshotStruct,r3
  lwz REG_Index,0x4(REG_SnapshotStruct)               #get number of snapshots present
  addi REG_SnapshotStruct,REG_SnapshotStruct,0x10     #get to snapshot info
  bl  SnapshotID                                      #get ID we are looking for
  mflr r3
  lwz REG_SnapshotID,0x0(r3)
  li  REG_Count,0                                     #init count
SnapshotSearchLoop:
  cmpw REG_Count,REG_Index
  bge SnapshotSearchLoop_NotFound
#Get the next snapshots ID
  mulli r3,REG_Count,0x8          #each snapshots data is 0x8 long
  add r3,r3,REG_SnapshotStruct
  lwz r4,0x0(r3)                  #get the snaps ID
  cmpw r4,REG_SnapshotID
  bne SnapshotSearchLoop_IncLoop
  b SnapshotSearchLoop_Found
SnapshotSearchLoop_IncLoop:
  addi REG_Count,REG_Count,1
  b SnapshotSearchLoop

SnapshotSearchLoop_NotFound:
  b CreateSnapshot

SnapshotSearchLoop_Found:
#Delete Snapshot
  mr	r3,REG_MemcardSlot
  mr  r4,REG_Count
  branchl r12,0x8001d5fc
WaitToDeleteLoop:
  branchl	r12,0x8001b6f8
  cmpwi	r3,0xB
  beq	WaitToDeleteLoop
#If Exists
  cmpwi	r3,0x0
  beq	CreateSnapshot
  cmpwi	r3,0x9
  bne	SaveError

CreateSnapshot:
.set REG_Codeset,31

#Get codeset pointer and length
  lwz REG_Codeset,CodesetPointer(rtoc)
  bl  SnapshotSaveStruct
  mflr r4
  stw REG_Codeset,0x8(r4)
#Store file size
  lwz r3,0x0(REG_Codeset)
  stw r3,0x0(r4)
#Load banner and image
#Convert ID to string
  addi r3,sp,0x80
  bl  SnapshotString
  mflr r4
  bl  SnapshotID
  mflr r5
  lwz r5,0x0(r5)
  branchl r12,0x80323cf4
#Create File
  mr	r3,REG_MemcardSlot
  addi r4,sp,0x80       #Snapshot ID
  bl  SnapshotSaveStruct
  mflr r5
  load r6,0x803bacc8
  bl  SnapshotSaveName
  mflr r7
  load r8,0x80433380
  lwz	r8,0x44(r8)
  lwz	r9,0x4(r8)        #icon data
  lwz	r8,0x0(r8)        #banner data
  li  r10,0
  branchl r12,0x8001bb48

WaitToLoadLoop:
  branchl	r12,0x8001b6f8
  cmpwi	r3,0xB
  beq	WaitToLoadLoop
#If Exists
  cmpwi	r3,0x0
  beq	Success
  cmpwi	r3,0x9
  beq	Success
  b	Failure

Success:
  li	r3,0xAA
  branchl	r12,0x801c53ec
  b CreateSnapshot_End

Failure:
#Play Error Sound
  li	r3, 3
  branchl	r12,0x80024030
  li	r3, 3
  branchl	r12,0x80024030
  b CreateSnapshot_End

CreateSnapshot_End:
#Change Game ID back
  lis r3,0x8000
  addi r4,sp,0xB0
  branchl r12,strcpy
  b ExitInjection

SaveError:
#Play Error Sound
  li	r3, 3
  branchl	r12,0x80024030
  li	r3, 3
  branchl	r12,0x80024030
#Change Game ID back
  lis r3,0x8000
  addi r4,sp,0xB0
  branchl r12,strcpy
  b ExitInjection

###################
MainSaveName:
blrl
.ascii "Super Smash Bros. Melee         "
.ascii "Mod Launcher (1 of 2)           "
###################
SnapshotID:
blrl
.long 0x00D0C0DE
.align 2
###################
SnapshotString:
blrl
.string "%u"
.align 2
###################
SnapshotSaveStruct:
blrl
.long 0         #File size, will dynamically change based on gct size
.long 3         #Unknown
.long 0         #Pointer to snapshot data, will be stored to during runtime
.long -1        #end of structure
.align 2
###################
SnapshotSaveName:
blrl
.ascii "Training Mode v2.0              "
.ascii "Mod Data (2 of 2)               "
###################
CodeFileName:
blrl
.string "codes.gct"
.align 2
###################
TMGameID:
blrl
.string "GTME01"
.align 2
###################
MeleeGameID:
blrl
.string "GALE01"
.align 2
###################

#region ExploitCode102
ExploitCode102:
blrl
.set InjectionPoint,0x80375510 #0x803754e4
.set InjectionReturn,0x803754dc #0x803754e8


##################################
## PLACE AT 0xb6f3d0 IN state FILE ##
##################################


#*** Possibly inject into 801a4000, memcard stuff has already been reset, this might be the
#neatest place to do this. destroy the heap, make a new one, load the snapshot and rerun this
#function


##################
## Change Major ##
##################

#request to change screen
 branchl r3,0x801A4B60

#Set Next Scene Byte (Main Menu) for sceneDecide_Menu
#Check For X Button Held
li	r3,4
branchl	r12,0x801a3680
rlwinm.	r4,r4,0,21,21
beq	ExploitCode102_GoToEventSS

ExploitCode102_GoToCSS:
li	r3,2
b	ExploitCode102_StoreNewScene

#Spoof current (soon to be previous) screen
ExploitCode102_GoToEventSS:
 li	r3,0x2b
 load	r4,0x80479d30
 stb	r3,0x0(r4)
 li r3,0x1

ExploitCode102_StoreNewScene:
 lis r4,0x804d
 stb r3,0x68bC(r4)

################################
## Disable memory card saving ##
################################

#lis 	r5,0x8043		#v1.0=80431360
#li	r6,4
#stw	r6,0x3320(r5)	# store 4 to disable memory card saving henceforth

#########################
## Tournament Settings ##
#########################

lwz	r4, -0x77C0 (r13)
load r3,0x00340102
stw r3,0x1850(r4)			#store stock mode
load r3,0x04000A00
stw r3,0x1854(r4)			#store 4 stocks
load r3,0x08010100
stw r3,0x1858(r4)			#store 8 minutes

load r3,0xFF000000
stw r3,0x1CB0(r4)			#store items off
load r3,0xE70000B0
stw r3,0x1CC8(r4)			#store stages

#################################
## Place Branch To Heap Hijack ##
#################################

#Get Function To Branch To
  bl	ExploitCode102_HeapHijack
  mflr	r3
#Get Where to Place Branch
  load	r4,InjectionPoint
#Make a Branch Instruction out of This (FunctionAddress - BranchPoint)
  sub	r3,r3,r4		#r3 contains difference between
  rlwinm	r3,r3,0,6,29		#Mask Out bits 6 through 29
  oris	r3,r3,0x4800		#Place 0x48 at the start (opcode)
  stw	r3,0x0(r4)

#####################
## TRK_flush_cache ##
#####################

load r3,InjectionPoint
lis	r4,0x4
branchl	r12,0x80328F50

##########
## Exit ##
##########

lis r12,0x8023
ori r12,r12,0x9e9c
mtctr r12
bctr

#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################


######################
## Heap Hijack Code ##
######################
ExploitCode102_HeapHijack:
blrl

backup

###################
## Load Snapshot ##
###################

#Update list of present memcard snapshots
  li  r3,0
  branchl r12,0x80253e90

.set MemcardFileList,0x804333c8
.set REG_Count,31
.set REG_Index,30
.set REG_SnapshotStruct,29
.set REG_SnapshotID,28
#Check if file exists on card
  load  r3,MemcardFileList                            #go to pointer location
  lwz REG_SnapshotStruct,0x0(r3)                      #access pointer to snapshot file list
  lwz REG_Index,0x4(REG_SnapshotStruct)               #get number of snapshots present
  addi REG_SnapshotStruct,REG_SnapshotStruct,0x10     #get to snapshot info
  bl  ExploitCode102_HeapHijack_SnapshotIDInt                                      #get ID we are looking for
  mflr r3
  lwz REG_SnapshotID,0x0(r3)
  li  REG_Count,0                                     #init count
ExploitCode102_HeapHijack_SnapshotSearchLoop:
  cmpw REG_Count,REG_Index
  bge ExploitCode102_HeapHijack_SnapshotSearchLoop_NotFound
#Get the next snapshots ID
  mulli r3,REG_Count,0x8          #each snapshots data is 0x8 long
  add r3,r3,REG_SnapshotStruct
  lwz r4,0x0(r3)                  #get the snaps ID
  cmpw r4,REG_SnapshotID
  bne ExploitCode102_HeapHijack_SnapshotSearchLoop_IncLoop
  b ExploitCode102_HeapHijack_SnapshotSearchLoop_Found
ExploitCode102_HeapHijack_SnapshotSearchLoop_IncLoop:
  addi REG_Count,REG_Count,1
  b ExploitCode102_HeapHijack_SnapshotSearchLoop

ExploitCode102_HeapHijack_SnapshotSearchLoop_NotFound:
#Play Error Sound
  li	r3, 3
  branchl	r12,0x80024030
  li	r3, 3
  branchl	r12,0x80024030
#Disable Saving
  lis     r4,0x8043
  li     r3,4
  stw    r3,0x3320(r4)    # store 4 to disable memory card saving
  b ExploitCode102_HeapHijack_CleanUpHijack

ExploitCode102_HeapHijack_SnapshotSearchLoop_Found:
.set REG_CodesetSize,31
.set REG_CodesetPointer,30
#Convert blocks to bytes
  lhz r3,0x6(r3)
  mulli REG_CodesetSize,r3,0x2000
#Alloc Space For Snapshot File
  mr  r3,REG_CodesetSize
  branchl	r12,0x8037f1e4			       #HSD_Alloc
  mr  REG_CodesetPointer,r3
  load	r5,0x803bacdc			           #Snapshot Data Struct
  stw	REG_CodesetPointer,0x8(r5)     #Store Pointer to this area

#Remove Pointer To Current Memcard Stuff
  branchl	r12,0x8001c5a4
#Alloc Space For Memcard Stuff
  branchl	r12,0x8001c550

#Load File
  li	r3,0x0		#Slot A?
  bl	ExploitCode102_HeapHijack_SnapshotID
  mflr	r4
  load	r5,0x803bacdc		#Snapshot Data Struct
  load	r6,0x80433384		#String Space?
  load	r9,0x80433380
  lwz	r9,0x44(r9)
  lwz	r7,0x0(r9)		#Weird Char Pointer, Maybe Icon Image
  lwz	r8,0x4(r9)		#Banner Image
  li	r9,0		#Unk
  branchl	r12,0x8001bf04
#Store Result
  load	r4,0x804A0B6C
  stw	r3,0x0(r4)

ExploitCode102_HeapHijack_WaitToLoadLoop:
  branchl	r12,0x8001b6f8
  cmpwi	r3,0xB
  beq	ExploitCode102_HeapHijack_WaitToLoadLoop
#If Exists
  cmpwi	r3,0x0
  beq	ExploitCode102_HeapHijack_Success
  cmpwi	r3,0x9
  beq	ExploitCode102_HeapHijack_Success
  b	ExploitCode102_HeapHijack_Failure

ExploitCode102_HeapHijack_SnapshotIDInt:
blrl
.long 0x00D0C0DE
.align 2
ExploitCode102_HeapHijack_SnapshotID:
blrl
.string "13680862"
.align 2

#############
## Failure ##
#############

ExploitCode102_HeapHijack_Failure:
#Play Error Sound
  li	r3, 3
  branchl	r12,0x80024030
  li	r3, 3
  branchl	r12,0x80024030
#Disable Saving
  lis     r4,0x8043
  li     r3,4
  stw    r3,0x3320(r4)    # store 4 to disable memory card saving

b	ExploitCode102_Exit


#############
## Success ##
#############
ExploitCode102_HeapHijack_Success:
#Store codeset pointer and length
  stw REG_CodesetPointer,CodesetPointer(rtoc)

#Play SFX
  li	r3,0xAA
  branchl	r12,0x801c53ec

#Boot up tasks
  OnBootup

#####################
## Run Codehandler ##
#####################

ExploitCode102_HeapHijack_RunCodehandler:
  addi r4,REG_CodesetPointer,32
  bl	GeckoCodehandler

###################################
## Change Start Of Original Heap ##
###################################

  load	r3,0x8043200c			#Heap Start
  mr	r4,REG_CodesetSize			#Space to Add
  lwz	r5,0x4(r3)			#Get Heap Start
  add	r4,r4,r5			#Add
  stw	r4,0x4(r3)			#Store New Heap Start

##################
## Destroy Heap ##
##################

  lwz	r3, -0x58A0 (r13)
  branchl	r12,0x80344154

#####################
## Exit HeapHijack ##
#####################

#Adjust Heap Start
  lwz	r3, -0x3FE8 (r13)
  mr	r4,REG_CodesetSize
  add	r3,r3,r4
  stw	r3,-0x3FE8 (r13)


ExploitCode102_HeapHijack_CleanUpHijack:

################################
## Remove Branch To This Code ##
################################

load	r3,0x806da760
load	r4,InjectionPoint
stw	r3,0x0(r4)

#############################
## Flush Instruction Cache ##
#############################
ExploitCode102_Exit:
#Now flush the instruction cache
  lis r3,0x8000
  load r4,0x3b722c    #might be overkill but flush the entire dol file
  branchl r12,0x80328f50

###################################
## Zero fill entire nametag area ##
###################################

restore

load	r3,InjectionReturn
mtlr	r3

lis r3,0x8045
ori r3,r3,0xd850			#v1.0 = 8045b888
li r4,0
li r5,0
ori r5,r5,0xc344
lis r12,0x8000
ori r12,r12,0x3130			#v1.0 = 8045b888
mtctr r12
bctr


#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################


#######################
## Gecko Codehandler ##
#######################

.text

.set r0,0;   .set r1,1;   .set r2,2; .set r3,3;   .set r4,4
.set r5,5;   .set r6,6;   .set r7,7;   .set r8,8;   .set r9,9
.set r10,10; .set r11,11; .set r12,12; .set r13,13; .set r14,14
.set r15,15; .set r16,16; .set r17,17; .set r18,18; .set r19,19
.set r20,20; .set r21,21; .set r22,22; .set r23,23; .set r24,24
.set r25,25; .set r26,26; .set r27,27; .set r28,28; .set r29,29
.set r30,30; .set r31,31; .set f0,0; .set f2,2; .set f3,3

.globl _start

cheatdata:
.long	frozenvalue
.space 39*4

GeckoCodehandler:
_start:
	stwu	r1,-168(r1)		# stores sp
	stw	r0,8(r1)		# stores r0

	mflr	r0
	stw	r0,172(r1)		# stores lr

	mfcr	r0
	stw	r0,12(r1)		# stores cr

	mfctr	r0
	stw	r0,16(r1)		# stores ctr

	mfxer	r0
	stw	r0,20(r1)		# stores xer

	stmw	r3,24(r1)		# saves r3-r31

	mfmsr	r20
	ori	r26,r20,0x2000		#enable floating point ?
	andi.	r26,r26,0xF9FF
	mtmsr	r26

	stfd	f2,152(r1)		# stores f2
	stfd	f3,160(r1)		# stores f3

    lis	r31,0x8000

    lis r3, 0xCC00
    lhz r28, 0x4010(r3)
    ori r21, r28, 0xFF
    sth r21, 0x4010(r3) # disable MP3 memory protection

	mflr	r29
	mr	r15,r4

	ori	r7, r31, cheatdata@l	# set pointer for storing data (before the codelist)

	lis	r6,0x8000		# default base address = 0x80000000 (code handler)

	mr	r16,r6			# default pointer =0x80000000 (code handler)

	li	r8,0			# code execution status set to true (code handler)

	lis	r3,0x00D0
    ori	r3,r3,0xC0DE

	lwz	r4,0(r15)
	cmpw	r3,r4
	bne-	_exitcodehandler
	lwz	r4,4(r15)
	cmpw	r3,r4
    bne-	_exitcodehandler	# lf no code list skip code handler
    addi	r15,r15,8
	b	_readcodes

_exitcodehandler:
	mtlr	r29

resumegame:
    lis r3, 0xCC00
    sth r28,0x4010(r3)  # restore memory protection value

	lfd	f2,152(r1)		# loads f2
	lfd	f3,160(r1)		# loads f3

	mtmsr	r20         # restore msr

	lwz	r0,172(r1)
	mtlr	r0			# restores lr

	lwz	r0,12(r1)
	mtcr	r0			# restores cr

	lwz	r0,16(r1)
	mtctr	r0			# restores ctr

	lwz	r0,20(r1)
	mtxer	r0			# restores xer

	lmw	r3,24(r1)		# restores r3-r31

	lwz	r0,8(r1)		# loads r0

	addi	r1,r1,168

	isync

    blr				# return back to game

_readcodes:
	lwz	r3,0(r15)		#load code address
	lwz	r4,4(r15)		#load code value

	addi	r15,r15,8		#r15 points to next code

	andi.	r9,r8,1
	cmpwi	cr7,r9,0		#check code execution status in cr7. eq = true, ne = false

	li	r9,0			#Clears r9

	rlwinm	r10,r3,3,29,31		#r10 = extract code type, 3 bits
	rlwinm 	r5,r3,7,29,31		#r5  = extract sub code type 3 bits

	andis.	r11,r3,0x1000		#test pointer
	rlwinm	r3,r3,0,7,31		#r3  = extract address in r3 (code type 0/1/2) #0x01FFFFFF

	bne	+12			#jump lf the pointer is used

	rlwinm	r12,r6,0,0,6		#lf pointer is not used, address = base address
	b	+8

	mr	r12,r16			#lf pointer is used, address = pointer

	cmpwi	cr4,r5,0		#compares sub code type with 0 in cr4

	cmpwi	r10,1
	blt+	_write			#code type 0 : write
	beq+	_conditional		#code type 1 : conditional

	cmpwi	r10,3
	blt+	_ba_pointer		#Code type 2 : base address operation

	beq-	_repeat_goto		#Code type 3 : Repeat & goto

	cmpwi	r10,5
	blt-	_operation_rN		#Code type 4 : rN Operation
	beq+	_compare16_NM_counter	#Code type 5 : compare [rN] with [rM]

	cmpwi	r10,7
	blt+	_hook_execute		#Code type 6 : hook, execute code

	b	_terminator_onoff_	#code type 7 : End of code list

#CT0=============================================================================
#write  8bits (0): 00XXXXXX YYYY00ZZ
#write 16bits (1): 02XXXXXX YYYYZZZZ
#write 32bits (2): 04XXXXXX ZZZZZZZZ
#string code  (3): 06XXXXXX YYYYYYYY, d1d1d1d1 d2d2d2d2, d3d3d3d3 ....
#Serial Code  (4): 08XXXXXX YYYYYYYY TNNNZZZZ VVVVVVVV

_write:
	add	r12,r12,r3		#address = (ba/po)+(XXXXXX)
	cmpwi	r5,3
	beq-	_write_string		#r5  == 3, goto string code
	bgt-	_write_serial		#r5  >= 4, goto serial code

	bne-	cr7,_readcodes		#lf code execution set to false skip code

	cmpwi	cr4,r5,1		#compares sub code type and 1 in cr4

	bgt-	cr4,_write32		#lf sub code type == 2, goto write32

	#lf sub code type = 0 or 1 (8/16bits)
	rlwinm	r10,r4,16,16,31		#r10 = extract number of times to write (16bits value)

_write816:
	beq	cr4,+16			#lf r5 = 1 then 16 bits write
	stbx	r4,r9,r12		#write byte
	addi	r9,r9,1
	b	+12
	sthx	r4,r9,r12		#write halfword
	addi	r9,r9,2
	subic.	r10,r10,1		#number of times to write -1
	bge-	_write816
	b	_readcodes

_write32:
	rlwinm	r12,r12,0,0,29		#32bits align adress
    stw	r4,0(r12)		#write word to address
    b	_readcodes

_write_string:				#endianess ?
	mr	r9,r4
	bne-	cr7,_skip_and_align	#lf code execution is false, skip string code data

	_stb:
	subic.	r9,r9,1			#r9 -= 1 (and compares r9 with 0)
	blt-	_skip_and_align		#lf r9 < 0 then ExploitCode102_Exit
	lbzx	r5,r9,r15
	stbx	r5,r9,r12		#loop until all the data has been written
	b	_stb

_write_serial:
	addi	r15,r15,8		#r15 points to the code after the serial code
	bne-	cr7,_readcodes		#lf code execution is false, skip serial code

	lwz	r5,-8(r15)		#load TNNNZZZZ
	lwz	r11,-4(r15)		#r11 = load VVVVVVVV

	rlwinm	r17,r5,0,16,31		#r17 = ZZZZ
	rlwinm	r10,r5,16,20,31		#r10 = NNN (# of times to write -1)
	rlwinm	r5,r5,4,28,31		#r5  = T (0:8bits/1:16bits/2:32bits)

_loop_serial:
	cmpwi	cr5,r5,1
	beq-	cr5,+16			#lf 16bits
	bgt+	cr5,+20			#lf 32bits

	stbx	r4,r9,r12		#write serial byte (CT04,T=0)
	b	+16

	sthx	r4,r9,r12		#write serial halfword (CT04,T=1)
	b	+8

	stwx	r4,r9,r12		#write serial word (CT04,T>=2)

	add	r4,r4,r11		#value +=VVVVVVVV
	add	r9,r9,r17		#address +=ZZZZ
	subic.	r10,r10,1
	bge+	_loop_serial		#loop until all the data has been written

	b	_readcodes

#CT1=============================================================================
#32bits conditional (0,1,2,3): 20XXXXXX YYYYYYYY
#16bits conditional (4,5,6,7): 28XXXXXX ZZZZYYYY

#PS : 31 bit of address = endlf.

_conditional:
	rlwinm.	r9,r3,0,31,31		#r10 = (bit31 & 1) (endlf enabled?)

	beq	+16			#jump lf endlf is not enabled

	rlwinm	r8,r8,31,1,31		#Endlf (r8>>1)
	andi.	r9,r8,1			#r9=code execution status
	cmpwi	cr7,r9,0		#check code execution status in cr7
	cmpwi	cr5,r5,4		#compares sub code type and 4 in cr5
	cmpwi	cr3,r10,5		#compares code type and 5 in cr3

	rlwimi	r8,r8,1,0,30		#r8<<1 and current execution status = old execution status
	bne-	cr7,_true_end		#lf code execution is set to false -> ExploitCode102_Exit

	bgt	cr3,_addresscheck2	#lf code type==6 -> address check
	add	r12,r12,r3		#address = (ba/po)+(XXXXXX)

	blt	cr3,+12			#jump lf code type <5 (==1)
	blt	cr5,_condition_sub	#compare [rN][rM]
	b	_conditional16_2	#counter compare
	bge	cr5,_conditional16	#lf sub code type>=4 -> 16 bits conditional

_conditional32:
	rlwinm	r12,r12,0,0,29		#32bits align
	lwz	r11,0(r12)
	b	_condition_sub

_conditional16:
	rlwinm	r12,r12,0,0,30		#16bits align
	lhz	r11,0(r12)
_conditional16_2:
	nor	r9,r4,r4
	rlwinm	r9,r9,16,16,31		#r9  = extract mask
	and	r11,r11,r9		#r11 &= r9
	rlwinm	r4,r4,0,16,31		#r4  = extract data to check against

_condition_sub:
	cmpl	cr6,r11,r4		#Unsigned compare. r11=data at address, r4=YYYYYYYY
	andi.	r9,r5,3
	beq	_skip_NE		#lf sub code (type & 3) == 0
	cmpwi	r9,2
	beq	_skip_LE		#lf sub code (type & 3) == 2
	bgt	_skip_GE		#lf sub code (type & 3) == 3

_skip_EQ:#1
	bne-	cr6,_true_end		#CT21, CT25, CT29 or CT2D (lf !=)
	b	_skip

_skip_NE:#0
	beq-	cr6,_true_end		#CT20, CT24, CT28 or CT2C (lf==)
	b	_skip

_skip_LE:#2
	bgt-	cr6,_true_end		#CT22, CT26, CT2A or CT2E (lf r4>[])
	b	_skip

_skip_GE:#3
	blt-	cr6,_true_end		#CT23, CT27, CT2B or CT2F (lf r4<r4)

_skip:
	ori	r8,r8,1			#r8|=1 (execution status set to false)
_true_end:
	bne+	cr3,_readcodes		#lf code type <> 5
	blt	cr5,_readcodes
	lwz	r11,-8(r15)		#load counter
	bne	cr7,_clearcounter	#lf previous code execution false clear counter
	andi.	r12,r3,0x8		#else lf clear counter bit not set increase counter
	beq	_increase_counter
	andi.	r12,r8,0x1		#else lf.. code result true clear counter
	beq	_clearcounter

_increase_counter:
	addi	r12,r11,0x10		#else increase the counter
	rlwimi	r11,r12,0,12,27		#update counter
	b	_savecounter

_clearcounter:
	rlwinm	r11,r11,0,28,11		#clear the counter
_savecounter:
	stw	r11,-8(r15)		#save counter
	b _readcodes


#CT2============================================================================

#load base adress    (0): 40TYZ00N XXXXXXXX = (load/add:T) ba from [(ba/po:Y)+XXXXXXXX(+rN:Z)]

#set base address    (1): 42TYZ00N XXXXXXXX = (set/add:T) ba to (ba/po:Y)+XXXXXXXX(+rN:Z)

#store base address  (2): 440Y0000 XXXXXXXX = store base address to [(ba/po)+XXXXXXXX]
#set base address to (3): 4600XXXX 00000000 = set base address to code address+XXXXXXXX
#load pointer        (4): 48TYZ00N XXXXXXXX = (load/add:T) po from [(ba/po:Y)+XXXXXXXX(+rN:Z)]

#set pointer         (5): 4ATYZ00N XXXXXXXX = (set/add:T) po to (ba/po:Y)+XXXXXXXX(+rN:Y)

#store pointer       (6): 4C0Y0000 XXXXXXXX = store pointer to [(ba/po)+XXXXXXXX]
#set pointer to      (7): 4E00XXXX 00000000 = set pointer to code address+XXXXXXXX

_ba_pointer:
	bne-	cr7,_readcodes

	rlwinm	r9,r3,2,26,29		#r9  = extract N, makes N*4

	rlwinm	r14,r3,16,31,31		#r3 = add ba/po flag bit (Y)
	cmpwi	cr3,r14,0

	cmpwi	cr4,r5,4		#cr4 = compare sub code type with 4 (ba/po)
	andi.	r14,r5,3		#r14 = sub code type and 3

	cmpwi	cr5,r14,2		#compares sub code type and 2

	blt-	cr5,_p01
	beq-	cr5,_p2			#sub code type 2

_p3:
	extsh	r4,r3
	add	r4,r4,r15		#r4=XXXXXXXX+r15 (code location in memory)
	b	_pend

_p01:
	rlwinm.	r5,r3,20,31,31		#r3 = rN use bit (Z)
	beq	+12			#flag is not set(=0), address = XXXXXXXX

	lwzx	r9,r7,r9		#r9 = load register N
	add	r4,r4,r9		#flag is set (=1), address = XXXXXXXX+rN

	beq	cr3,+8			#(Y) flag is not set(=0), address = XXXXXXXX (+rN)

  	add	r4,r12,r4		#address = XXXXXXXX (+rN) + (ba/po)

	cmpwi	cr5,r14,1
	beq	cr5,+8			#address = (ba/po)+XXXXXXXX(+rN)
	lwz	r4,0(r4)		#address = [(ba/po)+XXXXXXXX(+rN)]

	rlwinm.	r3,r3,12,31,31		#r5 = add/replace flag (T)
	beq	_pend			#flag is not set (=0), (ba/po)= XXXXXXXX (+rN) + (ba/po)
	bge	cr4,+12
	add	r4,r4,r6		#ba += XXXXXXXX (+rN) + (ba/po)
	b	_pend
	add	r4,r4,r16		#po += XXXXXXXX (+rN) + (ba/po)
	b	_pend

_p2:
	rlwinm.	r5,r3,20,31,31		#r3 = rN use bit (Z)
	beq	+12			#flag is not set(=0), address = XXXXXXXX

	lwzx	r9,r7,r9		#r9 = load register N
	add	r4,r4,r9		#flag is set (=1), address = XXXXXXXX+rN

	bge	cr4,+12
	stwx	r6,r12,r4		#[(ba/po)+XXXXXXXX] = base address
	b	_readcodes
	stwx	r16,r12,r4		#[(ba/po)+XXXXXXXX] = pointer
	b	_readcodes

_pend:
	bge	cr4,+12
	mr	r6,r4			#store result to base address
	b	_readcodes
	mr	r16,r4			#store result to pointer
	b	_readcodes


#CT3============================================================================
#set repeat     (0): 6000ZZZZ 0000000P = set repeat
#execute repeat (1): 62000000 0000000P = execute repeat
#return		(2): 64S00000 0000000P = return (lf true/false/always)
#goto		(3): 66S0XXXX 00000000 = goto (lf true/false/always)
#gosub		(4): 68S0XXXX 0000000P = gosub (lf true/false/always)

_repeat_goto:
	rlwinm	r9,r4,3,25,28		#r9  = extract P, makes P*8
	addi	r9,r9,0x40		#offset that points to block P's
	cmpwi	r5,2			#compares sub code type with 2
	blt-	_repeat

	rlwinm.	r11,r3,10,0,1		#extract (S&3)
	beq	+20			#S=0, skip lf true, don't skip lf false
	bgt	+8
	b	_b_bl_blr_nocheck	#S=2/3, always skip (code exec status turned to true)
	beq-	cr7,_readcodes		#S=1, skip lf false, don't skip lf true
	b	_b_bl_blr_nocheck

_b_bl_blr:
	bne-	cr7,_readcodes		#lf code execution set to false skip code

_b_bl_blr_nocheck:
	cmpwi	r5,3

	bgt-	_bl			#sub code type >=4, bl
	beq+	_b			#sub code type ==3, b

_blr:
	lwzx	r15,r7,r9		#loads the next code address
	b	_readcodes

_bl:
	stwx	r15,r7,r9		#stores the next code address in block P's address
_b:
	extsh	r4,r3			#XXXX becomes signed
	rlwinm	r4,r4,3,9,28

	add	r15,r15,r4		#next code address +/-=line XXXX
	b	_readcodes

_repeat:
	bne-	cr7,_readcodes		#lf code execution set to false skip code

	add	r5,r7,r9		#r5 points to P address
	bne-	cr4,_execute_repeat	#branch lf sub code type == 1

_set_repeat:
	rlwinm	r4,r3,0,16,31		#r4  = extract NNNNN
	stw	r15,0(r5)		#store current code address to [bP's address]
	stw	r4,4(r5)		#store NNNN to [bP's address+4]

	b	_readcodes

_execute_repeat:
	lwz	r9,4(r5)		#load NNNN from [M+4]
	cmpwi	r9,0
	beq-	_readcodes
	subi	r9,r9,1
	stw	r9,4(r5)		#saves (NNNN-1) to [bP's address+4]
	lwz	r15,0(r5)		#load next code address from [bP's address]
	b	_readcodes

#CT4============================================================================
#set/add to rN(0) : 80SY000N XXXXXXXX = rN = (ba/po) + XXXXXXXX
#load rN      (1) : 82UY000N XXXXXXXX = rN = [XXXXXXXX] (offset support) (U:8/16/32)
#store rN     (2) : 84UYZZZN XXXXXXXX = store rN in [XXXXXXXX] (offset support) (8/16/32)

#operation 1  (3) : 86TY000N XXXXXXXX = operation rN?XXXXXXXX ([rN]?XXXXXXXX)
#operation 2  (4) : 88TY000N 0000000M = operation rN?rM ([rN]?rM, rN?[rM], [rN]?[rM])

#copy1        (5) : 8AYYYYNM XXXXXXXX = copy YYYY bytes from [rN] to ([rM]+)XXXXXXXX
#copy2        (6) : 8CYYYYNM XXXXXXXX = copy YYYY bytes from ([rN]+)XXXXXX to [rM]


#for copy1/copy2, lf register == 0xF, base address is used.

#of course, sub codes types 0/1, 2/3 and 4/5 can be put together lf we need more subtypes.


_operation_rN:
	bne-	cr7,_readcodes

	rlwinm	r11,r3,2,26,29		#r11  = extract N, makes N*4
	add	r26,r7,r11		#1st value address = rN's address
	lwz	r9,0(r26)		#r9 = rN

	rlwinm	r14,r3,12,30,31		#extracts S, U, T (3bits)

	beq-	cr4,_op0		#lf sub code type = 0

	cmpwi	cr4,r5,5
	bge-	cr4,_op56			#lf sub code type = 5/6

	cmpwi	cr4,r5,3
	bge-	cr4,_op34			#lf sub code type = 3/4

	cmpwi	cr4,r5,1

_op12:	#load/store
	rlwinm.	r5,r3,16,31,31		#+(ba/po) flag : Y
	beq	+8			#address = XXXXXXXX
	add	r4,r12,r4

	cmpwi	cr6,r14,1
	bne-	cr4,_store

_load:
	bgt+	cr6,+24
	beq-	cr6,+12

	lbz	r4,0(r4)		#load byte at address
	b	_store_reg

	lhz	r4,0(r4)		#load halfword at address
	b	_store_reg

	lwz	r4,0(r4)		#load word at address
	b	_store_reg

_store:
	rlwinm	r19,r3,28,20,31		#r9=r3 ror 12 (N84UYZZZ)

_storeloop:
	bgt+	cr6,+32
	beq-	cr6,+16

	stb	r9,0(r4)		#store byte at address
	addi	r4,r4,1
	b	_storeloopend

	sth	r9,0(r4)		#store byte at address
	addi	r4,r4,2
	b	_storeloopend

	stw	r9,0(r4)		#store byte at address
	addi	r4,r4,4
_storeloopend:
	subic.	r19,r19,1
	bge 	_storeloop
	b	_readcodes

_op0:
	rlwinm.	r5,r3,16,31,31		#+(ba/po) flag : Y
	beq	+8			#value = XXXXXXXX
	add	r4,r4,r12		#value = XXXXXXXX+(ba/po)

	andi.	r5,r14,1		#add flag : S
	beq	_store_reg		#add flag not set (=0), rN=value
	add	r4,r4,r9		#add flag set (=1), rN=rN+value
	b	_store_reg

_op34:	#operation 1 & 2
	rlwinm	r10,r3,16,30,31		#extracts Y

	rlwinm	r14,r4,2,26,29		#r14  = extract M (in r4), makes M*=4

	add	r19,r7,r14		#2nd value address = rM's address
	bne	cr4,+8
	subi	r19,r15,4		#lf CT3, 2nd value address = XXXXXXXX's address

	lwz	r4,0(r26)		#1st value = rN
	lwz	r9,0(r19)		#2nd value = rM/XXXXXXXX

	andi.	r11,r10,1		#lf [] for 1st value
	beq	+8
	mr	r26,r4

	andi.	r11,r10,2		#lf [] for 2nd value
	beq	+16
	mr	r19,r9
	bne+	cr4,+8
	add	r19,r12,r19		#lf CT3, 2nd value address = XXXXXXXX+(ba/op)

	rlwinm.	r5,r3,12,28,31		#operation # flag : T

	cmpwi	r5,9
	bge	_op_float

_operation_bl:
	bl	_operation_bl_return

_op450:
	add	r4,r9,r4		#N + M
	b	_store_reg

_op451:
	mullw	r4,r9,r4		#N * M
	b	_store_reg

_op452:
	or	r4,r9,r4		#N | M
	b	_store_reg

_op453:
	and	r4,r9,r4		#N & M
	b	_store_reg

_op454:
	xor	r4,r9,r4		#N ^ M
	b	_store_reg

_op455:
	slw	r4,r9,r4		#N << M
	b	_store_reg

_op456:
	srw	r4,r9,r4		#N >> M
	b	_store_reg

_op457:
	rlwnm	r4,r9,r4,0,31		#N rol M
	b	_store_reg

_op458:
	sraw	r4,r9,r4		#N asr M

_store_reg:
	stw	r4,0(r26)		#Store result in rN/[rN]
	b	_readcodes

_op_float:
	cmpwi	r5,0xA
	bgt	_readcodes

	lfs	f2,0(r26)		#f2 = load 1st value
	lfs	f3,0(r19)		#f3 = load 2nd value
	beq-	_op45A

_op459:
	fadds	f2,f3,f2		#N = N + M (float)
	b	_store_float

_op45A:
	fmuls	f2,f3,f2		#N = N * M (float)

_store_float:
	stfs	f2,0(r26)		#Store result in rN/[rN]
	b	_readcodes

_operation_bl_return:
	mflr	r10
	rlwinm	r5,r5,3,25,28		#r5 = T*8
	add	r10,r10,r5		#jumps to _op5: + r5

	lwz	r4,0(r26)		#load [rN]
	lwz	r9,0(r19)		#2nd value address = rM/XXXXXXXX

	mtlr	r10
	blr

#copy1        (5) : 8AYYYYNM XXXXXXXX = copy YYYY bytes from [rN] to ([rM]+)XXXXXXXX
#copy2        (6) : 8CYYYYNM XXXXXXXX = copy YYYY bytes from ([rN]+)XXXXXX to [rM]

_op56:
	bne-	cr7,_readcodes		#lf code execution set to false skip code

	rlwinm	r9,r3,24,0,31		#r9=r3 ror 8 (NM8AYYYY, NM8CYYYY)
	mr	r14,r12			#r14=(ba/po)
	bl	_load_NM

	beq-	cr4,+12
	add	r17,r17,r4		#lf sub code type==0 then source+=XXXXXXXX
	b	+8
	add	r9,r9,r4		#lf sub code type==1 then destination+=XXXXXXXX

	rlwinm.	r4,r3,24,16,31		#Extracts YYYY, compares it with 0
	li	r5,0

	_copy_loop:
	beq 	_readcodes		#Loop until all bytes have been copied.
	lbzx 	r10,r5,r17
	stbx 	r10,r5,r9
	addi	r5,r5,1
	cmpw	r5,r4
	b 	_copy_loop


#===============================================================================
#This is a routine called by _memory_copy and _compare_NM_16

_load_NM:
	cmpwi	cr5,r10,4		#compare code type and 4(rn Operations) in cr5

	rlwinm 	r17,r9,6,26,29		#Extracts N*4
	cmpwi 	r17,0x3C
	lwzx	r17,r7,r17		#Loads rN value in r17
	bne 	+8
	mr	r17,r14			#lf N==0xF then source address=(ba/po)(+XXXXXXXX, CT5)

	beq	cr5,+8
	lhz	r17,0(r17)		#...and lf CT5 then N = 16 bits at [XXXXXX+base address]

	rlwinm 	r9,r9,10,26,29		#Extracts M*4
	cmpwi 	r9,0x3C
	lwzx	r9,r7,r9		#Loads rM value in r9
	bne 	+8
	mr	r9,r14			#lf M==0xF then dest address=(ba/po)(+XXXXXXXX, CT5)

	beq	cr5,+8
	lhz	r9,0(r9)		#...and lf CT5 then M = 16 bits at [XXXXXX+base address]

	blr

#CT5============================================================================
#16bits conditional (0,1,2,3): A0XXXXXX NM00YYYY (unknown values)
#16bits conditional (4,5,6,7): A8XXXXXX ZZZZYYYY (counter)

#sub codes types 0,1,2,3 compare [rN] with [rM] (both 16bits values)
#lf register == 0xF, the value at [base address+XXXXXXXX] is used.

_compare16_NM_counter:
	cmpwi 	r5,4
	bge	_compare16_counter

_compare16_NM:
	mr	r9,r4			#r9=NM00YYYY

	add	r14,r3,r12		#r14 = XXXXXXXX+(ba/po)

	rlwinm	r14,r14,0,0,30		#16bits align (base address+XXXXXXXX)

	bl	_load_NM		#r17 = N's value, r9 = M's value

	nor	r4,r4,r4		#r4=!r4
	rlwinm	r4,r4,0,16,31		#Extracts !YYYY

	and	r11,r9,r4		#r3 = (M AND !YYYY)
	and	r4,r17,r4		#r4 = (N AND !YYYY)

	b _conditional

_compare16_counter:
	rlwinm	r11,r3,28,16,31		#extract counter value from r3 in r11
	b _conditional

#===============================================================================
#execute     (0) : C0000000 NNNNNNNN = execute
#hook1       (2) : C4XXXXXX NNNNNNNN = insert instructions at XXXXXX
#hook2       (3) : C6XXXXXX YYYYYYYY = branch from XXXXXX to YYYYYY
#on/off      (6) : CC000000 00000000 = on/off switch
#range check (7) : CE000000 XXXXYYYY = is ba/po in XXXX0000-YYYY0000

_hook_execute:
	mr	r26,r4			#r18 = 0YYYYYYY
	rlwinm	r4,r4,3,0,28		#r4  = NNNNNNNN*8 = number of lines (and not number of bytes)
	bne-	cr4,_hook_addresscheck	#lf sub code type != 0
	bne-	cr7,_skip_and_align

_execute:
	mtlr	r15
	blrl

_skip_and_align:
	add	r15,r4,r15
	addi	r15,r15,7
	rlwinm	r15,r15,0,0,28		#align 64-bit
	b	_readcodes

_hook_addresscheck:

	cmpwi	cr4,r5,3
	bgt-	cr4,_addresscheck1	#lf sub code type ==6 or 7
	lis	r5,0x4800
	add	r12,r3,r12
	rlwinm	r12,r12,0,0,29		#align address

	bne-	cr4,_hook1		#lf sub code type ==2

_hook2:
	bne-	cr7,_readcodes

	rlwinm	r4,r26,0,0,29		#address &=0x01FFFFFC

	sub	r4,r4,r12		#r4 = to-from
	rlwimi	r5,r4,0,6,29		#r5  = (r4 AND 0x03FFFFFC) OR 0x48000000
	rlwimi	r5,r3,0,31,31		#restore lr bit
	stw	r5,0(r12)		#store opcode
	b	_readcodes

_hook1:
	bne-	cr7,_skip_and_align

	sub	r9,r15,r12		#r9 = to-from
	rlwimi	r5,r9,0,6,29		#r5  = (r9 AND 0x03FFFFFC) OR 0x48000000
	stw	r5,0(r12)		#stores b at the hook place (over original instruction)
	addi	r12,r12,4
	add	r11,r15,r4
	subi	r11,r11,4		#r11 = address of the last work of the hook1 code
	sub	r9,r12,r11
	rlwimi	r5,r9,0,6,29		#r5  = (r9 AND 0x03FFFFFC) OR 0x48000000
	stw	r5,0(r11)		#stores b at the last word of the hook1 code
	b	_skip_and_align

_addresscheck1:
	cmpwi	cr4,r5,6
	beq	cr4,_onoff
	b	_conditional
_addresscheck2:
	rlwinm	r12,r12,16,16,31
	rlwinm	r4,r26,16,16,31
	rlwinm	r26,r26,0,16,31
	cmpw	r12,r4
	blt	_skip
	cmpw	r12,r26
	bge	_skip
	b	_readcodes

_onoff:
	rlwinm	r5,r26,31,31,31		#extracts old exec status (x b a)
	xori	r5,r5,1
	andi.	r3,r8,1			#extracts current exec status
	cmpw	r5,r3
	beq	_onoff_end
	rlwimi	r26,r8,1,30,30
	xori	r26,r26,2

	rlwinm.	r5,r26,31,31,31		#extracts b
	beq	+8

	xori	r26,r26,1

	stw	r26,-4(r15)		#updates the code value in the code list

_onoff_end:
	rlwimi	r8,r26,0,31,31		#current execution status = a

	b _readcodes

#===============================================================================
#Full terminator  (0) = E0000000 XXXXXXXX = full terminator
#Endlfs/Else      (1) = E2T000VV XXXXXXXX = endlfs (+else)
#End code handler     = F0000000 00000000

_terminator_onoff_:
	cmpwi	r11,0			#lf code type = 0xF
    beq _notTerminator
    cmpwi r5,1
    beq _asmTypeba
    cmpwi r5,2
    beq _asmTypepo
    cmpwi r5,3
    beq _patchType
    b _exitcodehandler
_asmTypeba:
    rlwinm r12,r6,0,0,6 # use base address
_asmTypepo:
    rlwinm r23,r4,8,24,31 # extract number of half words to XOR
    rlwinm r24,r4,24,16,31 # extract XOR checksum
    rlwinm r4,r4,0,24,31 # set code value to number of ASM lines only
    bne cr7,_goBackToHandler #skip code if code execution is set to false
    rlwinm. r25,r23,0,24,24 # check for negative number of half words
    mr r26,r12 # copy ba/po address
    add r26,r3,r26 # add code offset to ba/po code address
    rlwinm r26,r26,0,0,29 # clear last two bits to align address to 32-bit
    beq _positiveOffset # if number of half words is negative, extra setup needs to be done
    extsb r23,r23
    neg r23,r23
    mulli r25,r23,2
    addi r25,r25,4
    subf r26,r25,r26
_positiveOffset:
    cmpwi r23,0
    beq _endXORLoop
    li r25,0
    mtctr r23
_XORLoop:
    lhz r27,4(r26)
    xor r25,r27,r25
    addi r26,r26,2
    bdnz _XORLoop
_endXORLoop:
    cmpw r24,r25
    bne _goBackToHandler
    b _hook_execute
_patchType:
    rlwimi	r8,r8,1,0,30		#r8<<1 and current execution status = old execution status
    bne	cr7,_exitpatch		#lf code execution is set to false -> ExploitCode102_Exit
    rlwinm. r23,r3,22,0,1
    bgt _patchfail
    blt _copytopo
_runpatch:
    rlwinm r30,r3,0,24,31
    mulli r30,r30,2
    rlwinm r23,r4,0,0,15
    xoris r24,r23,0x8000
    cmpwi r24,0
    bne- _notincodehandler
    ori r23,r23,0x3000
_notincodehandler:
    rlwinm r24,r4,16,0,15
    mulli r25,r30,4
    subf r24,r25,r24
_patchloop:
    li r25,0
_patchloopnext:
    mulli r26,r25,4
    lwzx r27,r15,r26
    lwzx r26,r23,r26
    addi r25,r25,1
    cmplw r23,r24
    bgt _failpatchloop
    cmpw r25,r30
    bgt _foundaddress
    cmpw r26,r27
    beq _patchloopnext
    addi r23,r23,4
    b _patchloop
_foundaddress:
    lwz r3,-8(r15)
    ori r3,r3,0x300
    stw r3,-8(r15)
    stw r23,-4(r15)
    mr r16,r23
    b _exitpatch
_failpatchloop:
    lwz r3,-8(r15)
    ori r3,r3,0x100
    stw r3,-8(r15)
_patchfail:
    ori	r8,r8,1			#r8|=1 (execution status set to false)
    b _exitpatch
_copytopo:
    mr r16,r4
_exitpatch:
    rlwinm r4,r3,0,24,31 # set code to number of lines only
_goBackToHandler:
    mulli r4,r4,8
    add r15,r4,r15 # skip the lines of the code
    b _readcodes

_notTerminator:

_terminator:
	bne	cr4,+12			#check lf sub code type == 0
	li	r8,0			#clear whole code execution status lf T=0
	b	+20

	rlwinm.	r9,r3,0,27,31		#extract VV
#	bne 	+8			#lf VV!=0
#	bne-	cr7,+16

	rlwinm	r5,r3,12,31,31		#extract "else" bit

	srw	r8,r8,r9		#r8>>VV, meaning endlf VV lfs

    rlwinm. r23,r8,31,31,31
    bne +8 # execution is false if code execution >>, so don't invert code status
	xor	r8,r8,r5		#lf 'else' is set then invert current code status

_load_baseaddress:
	rlwinm.	r5,r4,0,0,15
	beq	+8
	mr	r6,r5			#base address = r4
	rlwinm.	r5,r4,16,0,15
	beq	+8
	mr	r16,r5			#pointer = r4
	b	_readcodes

#===============================================================================

frozenvalue:	#frozen value, then LR
.long        0,0
dwordbuffer:
.long        0,0
rem:
.long        0
bpbuffer:
.long 0		#int address to bp on
.long 0		#data address to bp on
.long 0		#alignement check
.long 0		#counter for alignement

regbuffer:
#.space 72*4

#.align 3

#codelist:
#.space 2*4
#.end
#endregion
#region ExploitCode101
ExploitCode101:
blrl
#Scene Change
  branchl r12,0x801a4518
#Start Menu
  li	r3, 0
  lis	r4, 0x804D
  stb	r3, 0x5B9C (r4)
#Disable Saving
  lis r5,0x8043
  li	r6, 4
  stw	r6, 0x2640 (r5)
#Error SFX
  li  r3,3
  branchl r12,0x80024030
#Error SFX
  li  r3,3
  branchl r12,0x80024030
#Zero Nametag and exit
  load r3,0x80239700
  mtlr r3
  load r3,0x8045cb70
  li  r4,0
  load  r5,0xC344
  branch r12,0x80003130
#endregion
#region ExploitCode100
ExploitCode100:
blrl
#Scene Change
  branchl r12,0x801a3e18
#Start Menu
  li	r3, 0
  lis	r4, 0x804D
  stb	r3, 0x473c (r4)
#Disable Saving
  lis r5,0x8043
  li	r6,4
  stw	r6,0x1360 (r5)
#Error SFX
  li  r3,3
  branchl r12,0x80023fb0
#Error SFX
  li  r3,3
  branchl r12,0x80023fb0
#Zero Nametag and exit
  load r3,0x80238b90
  mtlr r3
  load r3,0x8045b888
  li  r4,0
  load  r5,0xC344
  branch r12,0x80003130

#endregion

ExitInjection:
#Exit
  restore
  blr
#endregion

#region LoadCredits
LoadCredits:
backup

#Load Minor Scene 0x1
	load	r4,SceneController
	li	r3,0x1
	stb	r3,0x4(r4)

#Change Screen
	li	r3,0x1
	stw	r3,0x34(r4)

#Make Previous Major Event CSS So It Returns to Event SS
	load	r4,SceneController
	li	r3,0x2B
	stb	r3,0x2(r4)

#BACKUP CURRENT EVENT ID
	lwz	r3, -0x4A40 (r13)
	lwz	r5, 0x002C (r3)
	lbz	r3,0x0(r5)
	lwz	r4,0x4(r5)
	add	r3,r3,r4
	lwz	r4, -0x77C0 (r13)
	stb	r3, 0x0535 (r4)

#Return To Event SS
	#load	r4,0x804d68b8
	#li	r3,0x7
	#stb	r3,0x0(r4)
	#li	r3,0x2B
	#stb	r3,0x4(r4)

#Overwrite SceneDecide Function So It Doesn't Change Majors
	bl	TempSceneDecide
	mflr	r3
	load	r4,0x803dae44		#Main Menu's Minor Table Pointer
	lwz	r4,0x0(r4)
	stw	r3,0x8(r4)		#Overwrite MainMenu's SceneDecide Temporarily

#Init Name Count Variable
	li	r3,0x0
	stw	r3, -0x4eac (r13)

#Exit
	restore
	blr
#endregion

#region PlayMovie
PlayMovie:
		#Get Events Tutorial
			branchl r12,GetEventTutorialFileName
			mr	r20,r3					#Get Event's Tutorial File Name in r20

			#Get Extension Pointer in r21
			bl	FileSuffixes
			mflr	r21

		##############################
		## Play Movie's Audio Track ##
		##############################

			#Copy To Temp Audio String Space
			load	r22,0x803bb380		#Temp Audio String Space
			addi	r3,r22,0x7		#After the /audio/
			mr	r4,r20		#Movie FileName
			branchl	r12,0x80325a50		#strcpy

			#Get Length of This String Now
			mr	r3,r22
			branchl	r12,0x80325b04

			#Copy .hps to the end of it
			add	r3,r3,r22		#Dest
			mr	r4,r21		#.hps string
			branchl	r12,0x80325a50

			#Check If File Exists
			mr	r3,r22
			branchl	r12,0x8033796c
			cmpwi	r3,-1
			beq	FileNotFound

			#Load Song File
			LoadSongFile:
			mr	r3,r22		#Full Song File Name
			li	r4,127		#Volume?
			li	r5,1		#Unk
			branchl	r12,0x80023ed4


		#####################
		## Load Movie File ##
		#####################

		StartLoadMovieFile:

			#Copy File Name To Temp Space
			load	r22,0x80432058		#Temp File Name Space
			mr	r3,r22		#Destination
			mr	r4,r20		#Movie FileName
			branchl	r12,0x80325a50		#strcpy

			#Get Length of This String Now
			mr	r3,r22		#Destination
			branchl	r12,0x80325b04

			#Copy .mth Suffix
			add	r3,r3,r22		#Dest
			addi	r4,r21,0x8		#.mth string
			branchl	r12,0x80325a50

			#Check If File Exists
			mr	r3,r22
			branchl	r12,0x8033796c
			cmpwi	r3,-1
			beq	FileNotFound

			#PLAY SFX
			li	r3, 1
			branchl	r4,0x80024030

			#Unk Set
			li	r3,0x1
			branchl	r12,0x80024e50

			#Load Movie File
			mr	r3,r22								#File Name
			bl	FramerateDefinition
			mflr r4										#0x803dbfb4 = opening movie fps define
			li	r5,0									#lwz	r5, -0x4A14 (r13)
			load	r6,0x00271000				#li	r6,0		#Frame Buffer Heap Size?
			li	r7,0
			branchl	r12,0x8001f410

		#Set Framerate
			load r3,0x804333e0
			lwz r3,0x18(r3)						#get framerate from mth header
			li	r4,60
			divw r3,r4,r3							#decide how many in game frames per movie frame
			bl	FramerateDefinition
			mflr r4
			stw r3,0x4(r4)						#update fps

			#Unk Unset
			li	r3,0x0
			branchl	r12,0x80024e50



	#Create And Schedule Custom Movie Think Functions

		#Create Camera Think Entity
			li	r3, 13
			li	r4,14
			li	r5,0
			branchl	r12,0x803901f0
		#Attach Camera Think
			mr	r31,r3
			li	r4,640
			li	r5,480
			li	r6,8
			li	r7,0
			branchl	r12,0x801a9dd0
			li	r0,0x800
			stw	r0,0x24(r31)
			li	r0,0x0
			stw	r0,0x20(r31)

		#Create Movie Display Entity
			li	r3, 14
			li	r4,15
			li	r5,0
			branchl	r12,0x803901f0
			mr	r30,r3
			stw	r3, -0x4E48 (r13)
			lbz	r4, -0x3D40 (r13)
			li	r5, 0
			branchl	r12,0x80390a70
		#Attach Display Process
			mr	r3,r30
			load	r4,0x8001f67c
			li	r5,11
			li	r6,0
			branchl	r12,0x8039069c

		#Change Screen Size to Fullscreen
			mr	r3,r30
			li	r4,640
			li	r5,480
			branchl	r12,0x8001f624
			lfs	f0, -0x3680 (rtoc)
			stfs	f0, 0x0010 (r3)
			stfs	f0, 0x0014 (r3)



		#Create Movie Think Entity
			li	r3, 6
			li	r4,7
			li	r5,128
			branchl	r12,0x803901f0
			mr	r29,r3
		#Alloc 10 Bytes
			li	r3,10
			branchl	r12,0x8037f1e4
		#Initliaze Entity
			mr	r6,r3
			mr	r3,r29
			li	r4,0x0
			load	r5,0x8037f1b0
			branchl	r12,0x80390b68
		#Schedule Think
			mr	r3,r29
			bl	MovieThink
			mflr	r4
			li	r5,0x0
			branchl	r12,0x8038fd54
		#Store Display Entity and Camera Entity to the Think Entity
			lwz	r3,0x2C(r29)		#Think's Data
			stw	r31,0x0(r3)		#Camera Entity
			stw	r30,0x4(r3)		#Display Entity

		#REMOVE EVENT THINK FUNCTION
			lwz	r3, -0x3E84 (r13)
			branchl	r12,0x80390228

	b	exit
#endregion
#######################################
FramerateDefinition:
blrl
#This structure is passed through via r4 to the MTH play function
#It contains variable framerate information

#Structure is
# 0x0 = number of frames to use the following fps for
# 0x4 = in game frames per movie frame
.long 1048576
.long 2
#######################################

FileNotFound:

	#PLAY SFX
	li	r3, 3
	branchl	r4,0x80024030

	b	exit

#######################################

TempSceneDecide:
blrl

#Store Back
load	r3,0x801b138c		#Function Address
load	r4,0x803dae44		#Main Menu's Minor Table Pointer
lwz	r4,0x0(r4)
stw	r3,0x8(r4)		#Overwrite MainMenu's SceneDecide

blr

#######################################

MovieThink:
blrl

backup

#Backup Entity Pointer
	mr	r31,r3
	lwz	r30,0x2C(r3)

#Advance Frame
	branchl	r12,0x8001f578

#Check If Movie Is Over
	branchl	r12,0x8001f604
	cmpwi	r3,0x0
	bne	EndMovie

#Check For Button Press
	li	r3, 4
	branchl	r12,0x801a36a0		#All Players Inputs
	andi.	r4,r4,0x1100
	beq	Exit
#PLAY SFX
	li	r3, 1
	branchl	r4,0x80024030
	b	EndMovie

restore
blr


EndMovie:
#Stop Music
	branchl	r12,0x800236dc
#Remove Camera Think Function
	lwz	r3,0x0(r30)		#Camera Entity
	branchl	r12,0x80390228
#Remove Display Process Function
	lwz	r3,0x4(r30)		#Display Entity
	branchl	r12,0x80390228
#Remove This Think Function
	mr	r3,r31
	branchl	r12,0x80390228
#Unload Movie
	branchl	r12,0x8001f800
#Play Menu Music
	lwz	r3, -0x77C0 (r13)
	lbz	r3, 0x1851 (r3)
	branchl	r12,0x80023f28
#Reload Event Match Think
	li	r3, 0
	li	r4, 1
	li	r5, 128
	branchl	r12,0x803901f0
	load	r4,0x8024d864
	li	r5,0
	branchl	r12,0x8038fd54

Exit:
restore
blr

FileSuffixes:
blrl

#.hps
.string ".hps"
.align 2

#.mth
.string ".mth"
.align 2

#######################################

SwitchPage:

#Change page
	lwz r4,MemcardData(r13)
	lbz r3,CurrentEventPage(r4)
	add	r3,r3,r5
	stb r3,CurrentEventPage(r4)
#Check if within page bounds
SwitchPage_CheckHigh:
	cmpwi r3,NumOfPages
	ble SwitchPage_CheckLow
#Stay on current page
	subi r3,r3,1
	stb r3,CurrentEventPage(r4)
	b	exit
SwitchPage_CheckLow:
	cmpwi r3,0
	bge SwitchPage_ChangePage
#Stay on current page
	li	r3,0
	stb r3,CurrentEventPage(r4)
	b	exit

SwitchPage_ChangePage:
#Get Page Name ASCII
	branchl r12,GetCustomEventPageName
#Update Page Name
	mr	r5,r3
	lwz r3,-0x4EB4(r13)
	li	r4,0
	branchl r12,Text_UpdateSubtextContents

#Reset cursor to 0,0
	lwz	r5, -0x4A40 (r13)
	lwz	r5, 0x002C (r5)
	li	r3,0
	stw	r3, 0x0004 (r5)		 #Selection Number
	stb	r3, 0 (r5)		  	 #Page Number

#Redraw Event Text
SwitchPage_DrawEventTextInit:
	li	r29,0							#loop count
	lwz	r3, 0x0004 (r5)		 #Selection Number
	lbz	r4, 0 (r5)		  	 #Page Number
	add r28,r3,r4
SwitchPage_DrawEventTextLoop:
	mr	r3,r29
	add	r4,r29,r28
	branchl r12,0x8024d15c
	addi r29,r29,1
	cmpwi r29,9
	blt SwitchPage_DrawEventTextLoop

#Redraw Event Description
	lwz	r3, -0x4A40 (r13)
	mr	r4,r28
	branchl r12,0x8024d7e0

#Update High Score
	lwz	r3, -0x4A40 (r13)
	li	r4,0
	branchl r12,0x8024d5b0

#Update cursor position
#Get Texture Data
	lwz	r3, -0x4A40 (r13)
	lwz	r3, 0x0028 (r3)
	addi r4,sp,0x40
	li	r5,11
	li	r6,-1
	crclr	6
	branchl r12,0x80011e24
	lwz r3,0x40(sp)
#Change Y offset?
	li	r0,0
	stw r0,0x3C(r3)
#DirtySub
	branchl r12,0x803732e8

#Play SFX
	li	r3,2
	branchl r12,SFX_MenuCommonSound

#######################################

exit:
restore
li	r0, 16
