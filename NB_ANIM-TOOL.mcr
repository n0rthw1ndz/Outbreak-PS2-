macroScript NETBIO_AHI category:"Animation Tools"
tooltip:"AHI IMPORTER" Icon:#("Maxscript",1)

(
rollout Main_Dialog "NB AHI TOOL" width:467 height:812
(
	
	
	
	
/************************************************************************************************
    STRUCTS
************************************************************************************************/
	struct AHI_HEADER	
	(
	ufloat,
	bonecount,
	tsize, 
	uint00,
	uint01,
	ucount00, 
	uint02
	)
	
	struct nbd_header 
		(
		 t_type,
		 chk_off,
		 chk_sz
		)
	
	
		
	struct BONE_OBJ
	(
     		obj_id,
			uint00,
			bonesz,
			boneID,
			bone_prev,
			bone_next,
			bone_obj,
			scalex,
			scaley,
			scalez,
			ufloat00,
			qnon00,
			qnon01,
			qnon02,
			qnon03,
			transformx,
			transformy,
			transformz,
		t4,
		 theBone, 
		 theBonePos, -- vec 3 position 
		 theBoneRot, -- quat rotation
		 theBoneMat3,
		 theBoneScale, -- vec 3 scale
		 theBoneName,
		 meshID,
		 groupID
			
	)
	
	struct BIN_PTR_TBL_OBJ
	(
		
		
-- 	     anim_ptr_bg1,  -- LOWER
-- 		 anim_ptr_bg2,  -- HIGHER
-- 		 anim_ptr_bg3,  -- FACE
-- 		 anim_ptr_bg4,  -- HANDS
-- 		 anim_ptr_bg5  -- HANDS
		 AnimPtrs=#()
									-- ** unknown for enemies, enemies seem to use 0x12/0x13		
	)
		
	  
	  -- main anim blocks
		struct ANIM_BLOCK_HEADER_OBJ
		(
			objectID, -- 0x2000080
			sub_count, -- # of sub blocks
		    blk_sz, -- total size of entire anim block..
			
			
			-- array of bone objects in anim block
			ANIM_BONE_OBJECTS =#()
			
		)
		
		
		-- animation bone blocks need as many of these as blk sz
		struct ANIM_BLOCK_SUB_HEADER_OBJ
			(
			sub_objectID, -- 0x3F000XX
		    sub_container_count, -- # of instructions in sub block
		    sub_container_sz, -- tsize of sub instructions
			
				--  # should be as many instruction objects as the count
				--
			ANIM_INSTRUCTION_OBJECTS=#() 
			
		--	sub_next_off, -- ptr to next bone object
		--	Instruction_Objects=#() -- current bones instruction blocks
			)
	          
			-- animation instruction blocks (x,y,z,scales) should be as many as these as sub_containersz ^
			struct ANIM_INSTR_HEADER_OBJ
			(
				id, -- determines rotation/scale x,y,z
				ubyte00,
				instr_type, -- string ID
				t_frame,
				fcount,
				sz,
				ANIM_FRAME_DATA=#() 
			--	Animation_Data =#()		
			)
			
			-- animation Instruction data itself(frame/xforms)
			
			
			
			-- 0x12 (4 int16 per key frame) should be as many of these as ^ count
			struct ANI_INSTR_OBJ
			(
				xform00, -- int16s until you find flags that will change the types
				frame00,
				xform01,
				xform02
				--ANIM_INSTR_HEADER_OBJ =#() 
			)
			
			
			
		
			
	button 'btn_about' "About" pos:[328,127] width:109 height:14 align:#left
	button 'BTN_OPENAHI' "OPEN" pos:[16,29] width:112 height:16 align:#left
	button 'BTN_ANI_BLOCK' "PARSE BLOCK" pos:[166,238] width:105 height:22 align:#left
	button 'BTN_RESET' "RESET AHI" pos:[331,26] width:106 height:19 align:#left
	button 'Btn_LoadAnim' "Load Anim" pos:[12,770] width:414 height:26 align:#left
	
			
	 --listbox LB_ANI "Animation Blocks" pos:[325,228] width:112 height:7
	
	colorPicker 'clr_pick' "Wire Color" pos:[346,97] width:78 height:24 color:[0,255,144] fieldWidth:25 alpha:false modal:false align:#left
	GroupBox 'grp_anim' "Animation" pos:[8,216] width:441 height:592 align:#left
	GroupBox 'grp_ahi' "AHI/Skeleton" pos:[9,10] width:441 height:187 align:#left
	label 'LBL_fpath' "fpath:" pos:[216,172] width:215 height:16 align:#left
	button 'BTN_extract' "Extract AHI" pos:[332,50] width:104 height:19 toolTip:"Extract AHI from NBD container" align:#left
	listbox 'LB_BoneList' "BoneList" pos:[21,57] width:130 height:8 align:#left
	
	
	
	
	

/************************************************************************************************
  HELPER FUNCTIONS
************************************************************************************************/
	
	-- dump objects xforms
	fn DumpxForms obj = 
	(	
            format "%:\t%\n" "transform" obj.transform
			format "%:\t%\n" "position " obj.pos
			format "%:\t%\n" "rotation " obj.rotation
		-- output node's pivot point location
			format "%:\t%\n" "pivot " obj.pivot
		-- output object offsets
			format "%:\t%\n" "objectoffsetpos" obj.objectoffsetpos
			format "%:\t%\n" "objectoffsetrot" obj.objectoffsetrot
			format "%:\t%\n" "objectoffsetscale" obj.objectoffsetscale
		-- output object transform
			format "%:\t%\n" "objecttransform " obj.objecttransform
		-- output vertex position in local and world coordinates
			format "%:\t%\n" "vert 1 (local) "(in coordsys local getvert obj 1)
			format "%:\t%\n" "vert 1 (world1) "(in coordsys world getvert obj 1)
		-- calculate and output vertex position in world coordinates
			local v_pos = (in coordsys local getvert obj 1)* obj.objecttransform
			format"%:\t%\n" "vert 1 (world2) " v_pos				
	)
	
	-- return instruction object type
	fn Instr_Type Instr_Sig = 
		( 
			if Instr_Sig == 0x01 then return "Scale X" as string
			if Instr_Sig == 0x02 then return "Scale Z" as string
			if Instr_Sig == 0x04 then return "Scale Y" as string
			if Instr_Sig == 0x08 then return "Rotation X" as string
			if Instr_Sig == 0x10 then return "Rotation Z" as string
			if Instr_Sig == 0x20 then return "Rotation Y" as string				
		)
		
		

   fn BoneGroupType idx =
   (
	
	    if idx == 0x01 then return "Lower" as string
		if idx == 0x02 then return "Upper" as string
		if idx == 0x03 then return "Face" as string
		if idx == 0x04 then return "Hands" as string
		if idx == 0x05 then return "Hands" as string
		

	   
    )
		
		
		
		
-- 		
-- 	fn SetBoneInstruction frames frameIndex AllBones boneIndex InstructionID 
-- 	(
-- 		    if InstructionID == 0x01 then at time frames[frameIndex] set AllBones[boneIndex].
-- 			if InstructionID == 0x02 then 
-- 			if InstructionID == 0x04 then 
-- 			if InstructionID == 0x08 then 
-- 			if InstructionID == 0x10 then 
-- 			if InstructionID == 0x20 then 			
-- 	)
	
	-- run modulo
	fn Divisor x n = 
		(
		  return mod x n
		)

		
		fn ReadBytes stream val = 
			(
				 for i = 1 to val do Readbyte stream
			)
	
			-- read reverse short
		fn ReadBEShort fstream = 
			(
			 
				
				short = readshort fstream #unsigned
             short = bit.swapbytes short 2 1
					b = (bit.get short 16)
				for i = 17 to 32 do short = bit.set short i b
					return short
				
			)
			
		-- init listview for main anim blocks, offsets, signatures, bone containers, and block sizes
		-- keep in mind all these listviews have a 0 based index despite the rest of this crap uses 1 based
		fn initlvBoneContainer LV =
		(
			lv.gridlines = true
			lv.view = (dotnetclass "System.Windows.Forms.View").Details
			lv.fullRowSelect = true
			lv.BackColor = (dotnetclass "System.Drawing.Color").DimGray
			lv.Forecolor = (dotnetclass "System.Drawing.Color").Black
			layout_Def =#("Index", "Obj ID", "Instr Count", "t_size", "Offset")
			
			for i in layout_def do
				lv.columns.add i 58
			
		)
		
		
	 
		
		-- init listview for specific bone blocks inside anim containers
		-- need a better name for this lol
		
		
			
			
			

			
		-- Read Selected Anim Block on Listbox click

			
		   	   
	   -- for parsing specific selected bone container on listview select
	


-- [************************************ EVENTS ******************************] -- 
-----------------------------------------------------------------------------------------



	
	

	checkbutton 'ckb1' "UPPER 0x0C" pos:[214,40] width:81 height:44 enabled:false align:#left
	button 'BTN_DUMP_FRAME' "DUMP FRAME DATA" pos:[191,684] width:215 height:27 enabled:false align:#left
	
	
	

	
	
	
	
   global upper = undefined
	

	button 'BTN_DUMP_SCHUNK' "DUMP SUB CHUNK" pos:[192,720] width:217 height:27 enabled:false align:#left
	button 'BTN_DUMP_INSTR_H' "DUMP INSTRUCTION DATA" pos:[192,642] width:211 height:27 enabled:false align:#left
	button 'BTN_BONE_XFORMS' "DUMP BONE XFORMS" pos:[316,157] width:121 height:17 align:#left
	button 'BTN_FRAME_TEST' "Frame0 Test" pos:[289,267] width:136 height:14 align:#left
	
	
	spinner 'spn_block' "Block ID" pos:[281,240] width:73 height:16 range:[0,100,0] type:#integer align:#left
	button 'BTN_BIN' "Parse Bin" pos:[23,238] width:129 height:30 align:#left
	listbox 'LB_ANIM_IDX' "Animation" pos:[33,280] width:59 height:6 align:#left
	
	-- ## TRY AND DUMP and APPLY ALL FRAME 0 VALUES TO CORRECT BONE

	
	
	
	
	 



	-- catch(
		 
		-- )
		
	    
	

	
	
	on Main_Dialog open do
	(
		--initLvAniBone lv_objects
		--initLvInstr lv_instructions
	--	initlvBoneContainer lv_boneContainer
		
		clearListener()
		max select all
		max delete
		
	)
	on btn_about pressed do
	(
	MessageBox "Outbreak AHI Tool 1.0\n Only Supports importing of player/enemy AHI data \n Supported Extensions\n (nbd/ahi)\n, DCHAPS 9/16/2016!" title: "About" beep: false
	)
	on BTN_OPENAHI pressed do
	(
		max select all
		max delete
		
	--global Bone_Data = BONE_OBJ()
	global Header = AHI_HEADER()
	global Nbd_Ahi = NBD_HEADER()
	
	f = getOpenFileName caption: "AHI IMPORT" \
		filename: " " \
		types: "NBD(*.nbd)|*.nbd|AHI(*.ahi)|*.ahi|All|*.*|"
		
		format "f test: %" f
	
		
	LBL_fpath.text = f
				f=fopen f "rb"
			
			
		fToStr = f as string
		
		ext_len = fToStr.count - 3
	str_ext = substring fToStr ext_len 3 
		
		format "str_ext % " str_ext
		
		
		if f != undefined then
			(
			   print "binstream found"	
			   print f
			
				
				if str_ext == "nbd" or str_ext == "NBD" then
				(
				 fseek f 32 #seek_set
					Nbd_Ahi.t_type = ReadLong f
					Nbd_Ahi.chk_off = ReadLong f
					Nbd_Ahi.chk_sz = Readlong f
					
					
					fseek f nbd_ahi.chk_off #seek_Set	
					
				)
				else if str_ext == "ahi" or str_ext == "AHI" then
				(
					fseek f 0 #seek_set
				)
				
				
				)
			
	
		
		
		Header.ufloat = ReadFloat f
		Header.bonecount = ReadLong f
		Header.tsize = ReadLong f
		Header.uint00 = ReadLong f
		Header.uint01 = ReadLong f
		Header.ucount00 = Readlong f
		Header.uint02 = Readlong f
		
		
		str_bonecount = "Total Bones: " + Header.bonecount as string
		str_tsize = "Total File Size: " + Header.tsize as string
		fpos = ftell f
		
				print "////////////////////////////////\n Note: If Bone Parent == -1 it is a root node If Bone Child == -1 it is a leaf node \n //////////////////////////////////"
	
	
		
		Global allBones = #()
		Global BonesLower =#()
		Global BonesHigher =#()
		Global BonesHands =#()
		Global BonesFace =#()
		
		
		
		
		for i = 1 to Header.bonecount - 1 do 
			(
				start_off = ftell f
	
			Bone_Data = BONE_OBJ()
			
					
			Bone_Data.obj_id = ReadLong f
			Bone_Data.uint00 = ReadLong f
		    Bone_Data.bonesz = Readlong f
		    Bone_Data.boneID = ReadLong f
			Bone_Data.bone_prev = Readlong f
		    Bone_Data.bone_next = Readlong f
		    Bone_Data.bone_obj = Readlong f
		    Bone_Data.scalex = ReadFloat f
		    Bone_Data.scaley = ReadFloat f
		    Bone_Data.scalez = ReadFloat f
		    Bone_Data.ufloat00 = ReadFloat f
		    Bone_Data.qnon00 = ReadFloat f
		    Bone_Data.qnon01 = ReadFloat f
		    Bone_Data.qnon02 = ReadFloat f
		    Bone_Data.qnon03 = ReadFloat f
		    Bone_Data.transformx = ReadFloat f
		    Bone_Data.transformz = ReadFloat f
		    Bone_Data.transformy = ReadFloat f
			Bone_Data.t4 = ReadFloat f
			Bone_Data.meshID = ReadLong f
			Bone_Data.groupID = ReadLong f
			
			
	
	
	
	
	
	      q1  = quat Bone_Data.qnon00 Bone_Data.qnon01 Bone_Data.qnon02 Bone_Data.qnon03 
	      v1 = Point3 Bone_Data.transformx Bone_Data.transformy Bone_Data.transformz 
		  s1 = Point3 Bone_Data.scalex Bone_Data.scalez Bone_Data.scaley
		  mat3 = q1 as matrix3
		  
		  Bone_Data.theBonePos = v1
		  Bone_Data.theBoneScale = s1
		  Bone_Data.theBoneName = "bone " + Bone_Data.boneID as string
		  Bone_Data.theBoneRot = q1
		  Bone_Data.theBoneMat3 = mat3
		  
		  Bone_Data.theBoneMat3.row1 *= Bone_Data.theBonescale
		  Bone_Data.theBoneMat3.row2 *= Bone_Data.theBonescale			 
		  Bone_Data.theBoneMat3.row3 *= Bone_Data.theBonescale
		  
		  Bone_Data.theBoneMat3.row4 *= Bone_Data.theBonePos
	
			cur_pos = ftell f as integer
				cur_pos += 184
		
			fseek f cur_pos #seek_set
			
			
				if Bone_Data.groupID == 0 then append BonesLower Bone_Data
				if Bone_Data.groupID == 1 then append BonesHigher Bone_Data
				if Bone_Data.groupID == 2 then append BonesFace Bone_Data
				if Bone_Data.groupID == 3 then append BonesHands Bone_Data
				if Bone_Data.groupID == 4 then append BonesHands Bone_Data
			
			
			append allBones Bone_Data	
			
			
			
	
			--LB_BoneList.items = append LB_BoneList.items ("Bone:" + i as string)
	
			)
			
		
			
			
			-- create bone heirarchy
			for b = 1 to allBones.count do 
				(					
	                   -- if root bone
					if allBones[b].BoneID == 0  then
						(
							allBones[1].theBone = BoneSys.CreateBone allBones[1].theBonePos allBones[1].theBonePos [0,0,1]					
							allbones[1].theBone.ShowLinks = true	
							allbones[1].theBone.Name = AllBones[1].theBoneName
							allbones[1].theBone.Width = 0.05
							allbones[1].theBone.height = 0.05
							LB_BoneList.items = append LB_BoneList.items allBones[1].theBone.Name							
						)
				
						else 
						(
							 parent_id = allbones[b].bone_prev + 1 as integer
							 child_id = allbones[b].bone_next + 1 as integer
							allBones[b].theBone = BoneSys.CreateBone allBones[b].theBonePos allBones[b].theBonePos [0,0,1]
							allbones[b].theBone.Parent = allBones[parent_id].theBone
							
							allbones[b].theBone.Name = AllBones[b].theBoneName
						    allbones[b].theBone.ShowLinks = true
							allbones[b].theBone.Width = 0.05
							allbones[b].theBone.height = 0.05
							allbones[b].theBone.wirecolor = color 0 255 144
						--	allbones[b].theBone.pos.controller = TCB_position()
						--	allbones[b].theBone.rotation.controller = TCB_rotation()
							allbones[b].theBone.transform = allbones[b].theBone.transform * (allbones[b].theBone.parent.transform)
							LB_BoneList.items = append LB_BoneList.items allBones[b].theBone.Name
				
						)
						
						
						
						
					
									--LB_BoneList.items = append LB_BoneList.items allBones[b].theBone.Name
	                  				format "\n%" allbones[b]     						
					
				)
				
					
	   
				
				--max select all
				
				
				 if Fclose f then
				(
				   format "\n Filestream closed succesfully"
				)
				
	
		
	)
	on BTN_ANI_BLOCK pressed do
	(
		
		-- DEFINE MAIN HEADER OBJECT
		 ANIM_BLOCK_HEADER = ANIM_BLOCK_HEADER_OBJ()
	   
	
	
		
	--	ANI_INST = ANI_INST =#()
		
		try(
		
		f = getOpenFileName caption: "ANIM BLOCK IMPORT" \
		filename: " " \
		types: "BIN(*.bin)|*.bin|All|*.*|"
		
		--global ANIM_BLOCK_HEADER = ANIM_BLOCK_HEADER_OBJ()
		--global ANIM_BLOCK_SUB_HEADER = ANIM_BLOCK_SUB_HEADER_OBJ()
		
		format "f test: %" f
		
	 f=fopen f "rb"
		
		--fToStr = f as string9
		fToStr = f as string
		ext_len = fToStr.count - 3
	    str_ext = substring fToStr ext_len 3 
		format "str_ext % " str_ext
		)
		catch(
			messageBox("No file found")
			)
		
		-- CREATE ARRAYS FOR SUB CHUNK HEADERS, INTRSTRUCTION HEADERS AND INSTRUCTIONS THEMSELVES
		
		global Instruction_Headers = #()
		 global Instructions = #()
		 global SubObj_Headers= #()
			global colArray =#()
			
			
		global FirstRotations =#()
		 
		
		
		 if f != undefined then
		 (
		  
	
			 
				fseek f 0 #seek_set
			
		
			 
			 ANIM_BLOCK_HEADER.objectID = ReadLong f
			 ANIM_BLOCK_HEADER.sub_count = ReadLong f
			 ANIM_BLOCK_HEADER.blk_sz = ReadLong f
			 
							print "\n[ANIM BLOCK HEADER]"
	
				global boneGroup = ANIM_BLOCK_HEADER.sub_count
			 
			 
			 -- ## set number of BONE OBJECTS TO MAIN HEADER COUNT
			 ANIM_BLOCK_HEADER.ANIM_BONE_OBJECTS[ANIM_BLOCK_HEADER.sub_count] = 0
			 
			 print ANIM_BLOCK_HEADER.ANIM_BONE_OBJECTS.count as string
			
			
				
			--	format "OBJECT ID : %" ANIM_BLOCK_HEADER.objectID
			--	format "BLOCK COUNT : %" ANIM_BLOCK_HEADER.sub_count
			--	format "BLOCK SIZE LEN : %" ANIM_BLOCK_HEADER.blk_sz
				
			-- if boneGroup = 12 then fseek f 8 #seek_cur
			-- if boneGroup = 10 then fseek f 28 #seek_cur
			
			fseek f 20 #seek_set
				
				
			 
			 
			 		
			 -- #### SUB CHUNK HEADER ##### 
			 for i = 1 to ANIM_BLOCK_HEADER.sub_count do
				 (
			     
					 -- CREATE A NEW SUB HEADER OBJ
				ANIM_BLOCK_SUB_HEADER = ANIM_BLOCK_SUB_HEADER_OBJ() 
					
				ANIM_BLOCK_SUB_HEADER.sub_objectID = ReadLong f
				ANIM_BLOCK_SUB_HEADER.sub_container_count = ReadLong f
				ANIM_BLOCK_SUB_HEADER.sub_container_sz = ReadLong f
					 
					 
					 
			    -- SET INSTRUCTION ARRAY TO SUB COUNT SIZE
				ANIM_BLOCK_SUB_HEADER.ANIM_INSTRUCTION_OBJECTS[ANIM_BLOCK_SUB_HEADER.sub_container_count] = 0
					 
					 
					 
					 --ANIM_BLOCK_SUB_HEADER.sub_container_count = 0 do ANIM_BLOCK_SUB_HEADER.sub_container_count = 1
					 
					 print ANIM_BLOCK_SUB_HEADER.ANIM_INSTRUCTION_OBJECTS.count as string
					 
					 			 -- # STORE 
				ANIM_BLOCK_HEADER.ANIM_BONE_OBJECTS[i] = ANIM_BLOCK_SUB_HEADER
					 
					 append colArray ANIM_BLOCK_SUB_HEADER
					 
					 append SubObj_Headers ANIM_BLOCK_SUB_HEADER
					 
				
					 			--	 print ANIM_BLOCK_HEADER.ANIM_BONE_OBJECTS.count as string
			
					 
					--  format "\n[sub chunk header data %]\n" i										
					--  format "\nSub Obj: ID: % "  ANIM_BLOCK_SUB_HEADER.sub_objectID
					--  format "\nCount: ID: % "  ANIM_BLOCK_SUB_HEADER.sub_container_count
					--  format "\nTsize: % "  ANIM_BLOCK_SUB_HEADER.sub_container_sz
					 
	
					 
			
				for x = 1 to ANIM_BLOCK_HEADER.ANIM_BONE_OBJECTS[i].sub_container_count do
				(
					
					ANIM_INSTR_HEADER = ANIM_INSTR_HEADER_OBJ()
					
					ANIM_INSTR_HEADER.id = ReadByte f
					ANIM_INSTR_HEADER.ubyte00 = ReadByte f
					ANIM_INSTR_HEADER.instr_type = ReadByte f
					ANIM_INSTR_HEADER.t_frame = ReadByte f
					ANIM_INSTR_HEADER.fcount = ReadLong f
					ANIM_INSTR_HEADER.sz = ReadLong f
					
					
					
					
					
					-- ADD EACH READ INSTRUCTION TO SUB HEADER STRUCT ARRAY
					  ANIM_BLOCK_SUB_HEADER.ANIM_INSTRUCTION_OBJECTS[x] = ANIM_INSTR_HEADER
				--	 append ANIM_BLOCK_SUB_HEADER.Instruction_Objects[i] ANIM_INSTR_HEADER
					
					
					
					
					
					    -- set frame array to # of instruction header count
					   ANIM_INSTR_HEADER.ANIM_FRAME_DATA[ANIM_INSTR_HEADER.fcount] = 0
					   
					 --  print ANIM_INSTR_HEADER.ANIM_FRAME_DATA.count as string
					
					 append colArray ANIM_INSTR_HEADER
					
					
					
					
					
					-- APPEND READ STRUCTURE TO ARRAY
					append Instruction_Headers ANIM_INSTR_HEADER
					
					
					--print "\n[instruction header data " + x as string + "]\n"	
				  --  format "ID: %" ANIM_INSTR_HEADER.id
				 --   format "type: %" ANIM_INSTR_HEADER.instr_type					
				--	format "count: %" ANIM_INSTR_HEADER.count
				--	format "size: %" ANIM_INSTR_HEADER.sz
					
			
					
			--		print Instruction_Headers.count
					
			
					for j = 1 to ANIM_BLOCK_SUB_HEADER.ANIM_INSTRUCTION_OBJECTS[x].fcount do
					(
						
						ANI_INST = ANI_INSTR_OBJ()
					
						ANI_INST.xform00 = ReadShort f
						ANI_INST.frame00 = ReadShort f
					    ANI_INST.xform01 = ReadShort f
					    ANI_INST.xform02 = ReadShort f
					
						ANIM_INSTR_HEADER.ANIM_FRAME_DATA[j] = ANI_INST
						
						
						 append colArray ANI_INST
						
					--	ANI_INST.xform00 =  (float)ANI_INST.xform00
						--ANI_INST.xform01   --(float)ANI_INST.xform01 / 2880
					--	ANI_INST.xform01 =  (float)ANI_INST.xform01 / 2880
					--	ANI_INST.xform02 = (float)ANI_INST.xform02 / 2880
						
					--	 ANI_INST.xform00 = DegToRad ANI_INST.xform00
						 
											
					--insertItem ANI_INST.xform00
					-- APPEND READ STRUCTURE TO ARRAY
				     	append Instructions ANI_INST
						
						
					case ANIM_INSTR_HEADER.id of
						(
						  
							8: append FirstRotations ANI_INST.xform00
							16: append FirstRotations ANI_INST.xform00
							32: append FirstRotations ANI_INST.xform00
							
							
						)
						
						
						
					--	cls = classOf ANI_INST.xform00
						--format "xform00: [%] class: [%]" ANI_INST.xform00 cls
						--format "\n[frame data %]\n" j
						
				--	format "\nrotation: %" ANI_INST.xform00 
				--	format "\nrotation: %" ANI_INST.frame00
				--	format "\nrotation: %" ANI_INST.xform01
				--	format "\nrotation: %" ANI_INST.xform02
				
				
					)
					
					
				)
	
					
					 
					 		append SubObj_Headers ANIM_BLOCK_SUB_HEADER
					 
				)
		     
			 fclose f
				
				
			    BTN_DUMP_FRAME.enabled = true
				BTN_DUMP_INSTR_H.enabled = true
				BTN_DUMP_SCHUNK.enabled = true
			 
		 )
		
	
		
	)
	on BTN_RESET pressed do
	(
	 max select all
	 max delete
		
		count = Lb_BoneList.Items.Count
		
	
				free Lb_BoneList.items
		        Lb_BoneList.items.count = 0
		
		
	)
	on Btn_LoadAnim pressed do
	(
	
			--animbuttonstate = true
	
	with animate on(
	
	-- BONEGROUP VALUES --
	-- 0x0C LOWER 
	-- 0x0A UPPER
	
	  animationrange = interval 0 128	
	
					
	              
		
		  global boneStart = 0
		     
		   if boneGroup == 10 then bonestart = 1
		   if boneGroup == 12 then bonestart = 10
		--   if boneGroup == 06 then bonestart = 22
		
		   
		    format "BoneGroup In File: [%]" boneGroup
		   
	-- 		    for x = bonestart to bonestart + boneGroup do 
	-- 				(
	-- 					
	-- 				  print x	
	-- 				)
		   
		  
	-- 		 
				for x = bonestart to bonestart + boneGroup do
				(
		              
					
					
					
				  for y = 1 to Instruction_Headers.count do
				  (
					  
					    cur_axis = Instruction_Headers[y].id
					     --strAxis = Instr_Type Instruction_Headers[y].id
					   --  print cur_axis
					  
					--   format "BONE IDX: [%]\n Axis: [%]\n Instruction Header Type: [%]" x axis Instruction_Headers[y].instr_type 
					  
					    for t = 1 to Instructions.count do							
						(	
							       
							  --  yl = EulerAngles Instructions[t].xform00 Instructions[t].xform00 Instructions[t].xform00
							
								--  allbones[t].theBone.transform = * allbones[t].bone_prev.transform
							    --allbones[upper].theBone.rotation.x_rotation.controller = Float_Script()
					
							  				  
								if(cur_axis == 1) then (at time Instructions[t].frame00 AllBones[x].theBone.Scale.x = Instructions[t].xform00)
								if (cur_axis == 2) then (at time Instructions[t].frame00 AllBones[x].theBone.Scale.y = Instructions[t].xform00)
								if (cur_axis == 4) then (at time Instructions[t].frame00 AllBones[x].theBone.Scale.z = Instructions[t].xform00)
								if (cur_axis == 8) then (at time Instructions[t].frame00 AllBones[x].theBone.rotation.x = Instructions[t].xform00)
								if (cur_axis == 16) then (at time Instructions[t].frame00 AllBones[x].theBone.rotation.y = Instructions[t].xform00)
								if (cur_axis == 32) then (at time Instructions[t].frame00 AllBones[x].theBone.rotation.z = Instructions[t].xform00)
								--if (cur_axis == 64) then (at time Instructions[t].frame00 AllBones[x].theBone.transform.x = Instructions[t].xform00 *  (allbones[t].theBone.parent.transform))
							 --   if (cur_axis == 128) then (at time Instructions[t].frame00 AllBones[x].theBone.transform.y = Instructions[t].xform00 * (allbones[t].theBone.parent.transform))
							--	if (cur_axis == 256) then (at time Instructions[t].frame00 AllBones[x].theBone.transform.z = Instructions[t].xform00 * (allbones[t].theBone.parent.transform))
							
						
							
								
							)
					  
					
					  
					  
				  )
				 
				)
	-- 	-- 			 
		
		
		
	-- 	                       
	-- 		         
					
					
	
	
	)
	
	
	
	                -- ######### OLD EXPERIEMNTS/STUFF #########
	-- 					
	-- 			
					--allbones[upper].theBone.rotation.controller = Float_Script()
					--allbones[upper].theBone.rotation.controller.script = "degToRad currentTime"
					
			--	format "\n Instruction Type[%] Bone Name: % Bone Rotation % ANIM DATA ################### % " instr allbones[upper].theBone.Name allbones[upper].theBone.rotation Bone_Containers[i].Instruction_objects[x].Animation_Data[y]
					
					-- each instruction object is relative to 1 axis?? so multiplay the frame transform by specific axis instead of qnon as a whole
					
			--		allbones[upper].theBone.rotation.x_rotation.controller = Float_Script()
				--	allbones[upper].theBone.rotation.y_rotation.controller = Float_Script()
				--	allbones[upper].theBone.rotation.z_rotation.controller = Float_Script()
					
				--	allbones[upper].theBone.rotation.x_rotation.controller.script = "degToRad currentTime"
				--	allbones[upper].theBone.rotation.y_rotation.controller.script = "degToRad currentTime"
					--allbones[upper].theBone.rotation.z_rotation.controller.script = "degToRad currentTime"
					
				
					
				--	at time Bone_Containers[i].Instruction_objects[x].Animation_Data[y].r_frame allbones[upper].theBone.transform * (allbones[upper].theBone.parent.transform)
					
				--	at time Bone_Containers[i].Instruction_objects[x].Animation_Data[y].r_frame allbones[upper].theBone.rotation /= Bone_Containers[i].Instruction_objects[x].Animation_Data[y].r_xform
						--Bone_Containers[i].Instruction_objects[x].Animation_Data[y].r_xform
			--	)
		      	
	
	
	
	
	
	)
	on clr_pick changed new_col do
	(
		for o in objects do 						
		(
		o.wirecolor = new_col
		)		
		clr_pick.color = new_col
	
	)
	on ckb1 changed state do
	(
	 
	   if state then 
	   (
	    upper = true
	
	   )else (
		upper=false   
		
		)
	)
	on BTN_DUMP_FRAME pressed do
	(
		
		for i = 1 to Instruction_Headers.count do
		(
			
		 format "Instruction Header [%]" i 
		  print Instruction_Headers[i] as string
			
			
			
		 for x = 1 to  Instructions.count do  
		(
		  
		  print Instructions[x] as string
		)
		
		 axis=Instr_Type Instruction_Headers[i].id
		  print axis
			
		)
	    		
	
	)
	on BTN_DUMP_SCHUNK pressed do
	(
	    	  for x = 1 to  SubObj_Headers.count do
	   (
	  	  print SubObj_Headers[x] as string 	   	   
	    )
	
	
	)
	on BTN_DUMP_INSTR_H pressed do
	(
	     for x = 1 to  Instruction_Headers.count do
	    (
	   	  print Instruction_Headers[x] as string		
		  axis=Instr_Type Instruction_Headers[x].id
		  print axis
		 
	   )
	 	
	
	)
	on BTN_BONE_XFORMS pressed do
	(
		
		for i = 1 to allbones.count do 
			(
				 format "BONE ID[%]\n Bone Position: [%]\n Bone Rotation [%]\n Bone Scale [%]\n" i allbones[i].theBone.position allbones[i].theBone.rotation allbones[i].theBone.scale
			     print allbones[i].bone_prev as string
				
			)
			
			
					print "##########BONES HIGHER################"		
			for i = 1 to BonesHigher.count do
			(
				
			   print BonesHigher[i] as string	
			 	
			)
			
			
			print "##########BONES LOWER################"
			for i = 1 to bonesLower.count do
			(
				
			   print BonesLower[i] as string	
			 	
			)
			
			
				print "##########BONES FACE################"
			for i = 1 to BonesFace.count do
			(
				
			   print BonesFace[i] as string	
			 	
			)
			
			
				print "##########BONES HANDS################"
			for i = 1 to BonesHands.count do
			(
				
			   print BonesHands[i] as string	
			 	
			)
	
			
			
		
			
		
	
	)
	on BTN_FRAME_TEST pressed do
	(
		  
	-- 		for i = 1 to Instruction_Headers.count do 
	-- 		(
	-- 	     format "[%] %\n" i Instruction_Headers[i]
	-- 	     )
	-- 		
	--	print SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS.count as string
		
		  --print boneGroup as string
		--	 cur_bone = 10 + spn_block.value - 1
						--	print cur_bone as string
		
		cur_bone =  Lb_BoneList.selection
					   
		--print cur_bone as string
		
		
	--	cls = classOf = allBones[cur_bone].theBone.parent.transform
		
		--print cls as string
	                       							
		
	--	global cur_scale = point3
		
		
	-- 		
	-- 	 --  try(
	-- 	-- 	-- loop through all instructions of selected block 
	 for x = 1 to SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS.count do
		(
		    
	-- 			-- if Instruction_Headers[spn_block.value].ANIM_INSTR_HEADER != undefined then
			
				cur_xform = (float)SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].ANIM_FRAME_DATA[1].xform00 / (32768.0 / (3.141592654 * 2.0 * 2.0))

			
	      	   -- cur_xform = DegToRad cur_xform
			
			     
			       
			  --  if SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].id == 1 then cur_scale.x = cur_xform = (float)SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].ANIM_FRAME_DATA[1].xform00
			--	if SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].id == 2 then cur_scale.z = cur_xform = (float)SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].ANIM_FRAME_DATA[1].xform00
			--	if SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].id == 4 then cur_scale.y = cur_xform = (float)SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].ANIM_FRAME_DATA[1].xform00
			
			      if boneGroup == 12 then(
	-- 			
					  	
			            -- check if block contains rotations 
		       	 	case  SubObj_Headers[spn_block.value].ANIM_INSTRUCTION_OBJECTS[x].id of
						(
	-- 						   -- if so print  first frame value of rotations
							
							-- 1: allBones[cur_bone].theBone.transform.controller[3].value = cur_scale
							-- 2: allBones[cur_bone].theBone.transform.controller[3].value = cur_scale
							-- 4: allBones[cur_bone].theBone.transform.controller[3].value = cur_scale
	-- 							local v_pos = (in coordsys local
							 8:  allBones[cur_bone].theBone.transform.controller[2][1].value = (in coordsys local cur_xform) 					
							16:  allBones[cur_bone].theBone.transform.controller[2][3].value = (in coordsys local cur_xform)
							16:	  print cur_xform as string	
							32:  allBones[cur_bone].theBone.transform.controller[2][2].value = (in coordsys local cur_xform)
							32:	 print cur_xform as string
-- 							
-- 							8:  allBones[cur_bone].theBone.rotation.x = cur_xform
-- 					
-- 											
-- 							16:   allBones[cur_bone].theBone.rotation.z = cur_xform
-- 				
-- 							
-- 							32:   allBones[cur_bone].theBone.rotation.y =  cur_xform
-- 							
	-- 							
	
						)
						
					)
						
				
					
						
		)
				
		        clz = classOf allBones[cur_bone].theBone.transform.controller[3].value
		        print clz
		
	-- 		 
	    )
	on spn_block changed val do
		(
	
	    )
	on BTN_BIN pressed do
	(
	
		
		
		
		
		f = getOpenFileName caption: "ANIM BLOCK IMPORT" \
		filename: " " \
		types: "BIN(*.bin)|*.bin|All|*.*|"
		
		--global ANIM_BLOCK_HEADER = ANIM_BLOCK_HEADER_OBJ()
		--global ANIM_BLOCK_SUB_HEADER = ANIM_BLOCK_SUB_HEADER_OBJ()
		
		format "f test: %" f
		
	    f=fopen f "rb"
		
		--fToStr = f as string9
		fToStr = f as string
		ext_len = fToStr.count - 3
	    str_ext = substring fToStr ext_len 3 
		format "str_ext % " str_ext
			
			
			
			
		if f != undefined then
		 (
			 fseek f 4 #seek_set
			 
			 GroupCount = Readlong f
			 
			 print GroupCount
			 
			 fseek f 20 #seek_set
			 
			 ptr_tbl_offset = ReadLong f
			 
			 fseek f ptr_tbl_offset #seek_set
			 
			 
			 
	
			global AnimPtrGroup =#()
			 -- # for as many ptr groups u need
			 for i = 1 to 8 do
				 (  -- create a new group instance
					 BIN_PTR_TBL = BIN_PTR_TBL_OBJ()
					 
					  -- Set array to fixed length?
					 BIN_PTR_TBL.AnimPtrs[5] = 0
					 
					 for x = 1 to BIN_PTR_TBL.AnimPtrs.count do
						 (
							 BIN_PTR_TBL.AnimPtrs[x] = ReadLong f
						 )
					 
-- 					 BIN_PTR_TBL.anim_ptr_bg1 = ReadLong f  -- lower
-- 					 BIN_PTR_TBL.anim_ptr_bg2 = ReadLong f  -- upper
-- 					 BIN_PTR_TBL.anim_ptr_bg3 = ReadLong f  -- face
-- 					 BIN_PTR_TBL.anim_ptr_bg4 = ReadLong f  -- hands
-- 					 BIN_PTR_TBL.anim_ptr_bg5 = ReadLong f  -- hands
					 append AnimPtrGroup BIN_PTR_TBL
					 
					 idx = i as string
					 LB_ANIM_IDX.items = append LB_ANIM_IDX.items idx
					 
					 
					-- print BIN_PTR_TBL as string
				 )
				 
				
				 
				 
				 
				 
				 
-- 				AnimPtrGroup = for i = 1 to 8 collect BIN_PTR_TBL_OBJ \
-- 					anim_ptr_bg1:(ReadLong f) \
-- 					anim_ptr_bg2:(ReadLong f) \
-- 					anim_ptr_bg3:(ReadLong f) \
-- 					anim_ptr_bg4:(ReadLong f) \
-- 					anim_ptr_bg5:(ReadLong f) \	
-- 					LB_ANIM_IDX.items = append LB_ANIM_IDX.items
				    
					
				

					 
				 
				 
				 print AnimPtrGroup as string
				 
				 
			
			 
	-- 			 for i = 1 to 40 do
	-- 			 (
	-- 			
	-- 			    ptr = ReadLong f
	-- 				 
	-- 				 print ptr as string
	-- 				 
	-- 				 if ptr != -1 then
	-- 				 (
	-- 					  -- seek to ptr and collect block type
	-- 				      fseek f (ptr + 4) #seek_set
	-- 					  block_type = ReadLong f 
	-- 					 
	-- 					 fseek f (ptr_tbl_offset + (4 * i)) #seek_set
	-- 					 
	-- 					 print block_type as string
	-- 					 
	-- 				 )
	-- 				 
	-- 				 
	-- 			 )
	-- 			 
			 
		 )
			 
		
		
		
		
	)
	on LB_ANIM_IDX selected sel do
   (
	 -- idx = LB_ANIM_IDX.selection 
	  

	--  print "Selected Anim Group [" + sel as string + "]"
	 
 	   print AnimPtrGroup[sel] as string
	   
	   for i = 1 to AnimPtrGroup[sel].AnimPtrs.count do
	   (
		   if AnimPtrGroup[sel].AnimPtrs[i] != -1 then
		   (
			   
			   type = BoneGroupType i
			   print type
			   print  AnimPtrGroup[sel].AnimPtrs[i] as string
			   
			   
			   if(type == "Lower") then for i in BonesLower do(print i as string)
			   if(type == "Upper") then for i in BonesHigher do(print i as string)
			   if(type == "Hands") then for i in BonesHands do(print i as string)
			   if(type == "Face") then for i in BonesFace do(print i as string)
			   
			   
		   )
		   
		 --- if AnimPtrGroup[sel].AnimPtrs[i] == -1 then
			--  deleteItem AnimPtrGroup[sel].AnimPtrs[i] i
			  
		   
	   )
	  --print AnimPtrGroup[idx] as string
	    
	
   )
)
	


createdialog Main_Dialog width:450 height:812 style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
)
