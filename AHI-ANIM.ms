/*
--------------
Resident evil outbreak 
AHI IMPORTER 3ds max 9 +   
Dchaps 9/25/2016

*/

Macroscript NETBIO_AHI category:"Animation Tools"
tooltip:"AHI IMPORTER" Icon:#("Maxscript",1)


(
rollout Main_Dialog "NB AHI TOOL" width:200 height:152
(
	
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
		 theBoneName
			
	)
	
	
	struct ANI_header
		(
			uint00,
			blk_count
	    )
		
	 struct Pointer_Obj
	 (
		ptr_count,
		ptr_offset,
		block_sz,
		anim_off
	  )
		
		
		struct ani_object
		(
			objectID, -- 0x2000080
			chunk_count,
		    chunk_sz
		
		)
		
		struct ani_sub_object
			(
			sub_objectID,
		    sub_container_count,
		    sub_container_sz -- tsize of sub instructions
				
			)
	          
			struct ani_sub_instr
			(
				instr_id,
				instr_count,
				instr_sz
				
			)
			
	button BTN_ABOUT "About" pos:[25,425] width:180 height:16
	button BTN_OPENAHI "OPEN" pos:[50,20] width:128 height:30
	button BTN_ANI_PARSE "Parse .ANI" pos:[50, 55] width: 128 height:30
 	button BTN_RESET "RESET AHI" pos:[50, 90] width:128 height:30
			
	listbox LB_ANI "Anim blocks" pos:[8,125] width:128 height:10
	progressbar buffer color:red orient:#horizontal
	colorpicker clr_pick "Wire Color" color:[0,255,144]  alpha: false fieldwidth: 25 height:24 modal: false
	
	
	
	

	on clr_pick changed new_col do 
	(
		for o in objects do 						
		(
		o.wirecolor = new_col
		)		
		clr_pick.color = new_col
	
		)
	
	
	on BTN_ANI_PARSE pressed do
	(
			
	
        global AniHdr = ANI_HEADER()
		global aniobj = ani_object()
		global anisubobj = ani_sub_object()
		global anisubInstr = ani_sub_instr()
		
		f = getOpenFilename caption: "ANI PARSE " \ 
		filename: " " \
		types: "bin(*.bin)|*.BIN|All|*.*|"
		 
		f = fopen f "rb"
		 fToStr = f as string
		ext_len = fToStr.count - 3
		str_ext = substring fToStr ext_len 3
		
		
		allContainers = #()
		allInstructions = #()
	
		Pointers = #()
		Offsets = #()
	global AnimOffs =#()
		AnimBlocks =#()
		
		
	 inc = 0
		if f != undefined then 
		(
			
			print ".bin stream found"
			print f
			
			
			if str_ext == "bin" or "BIN" then
				(					
				 fseek f 0 #seek_set	

				 Anihdr.uint00 = ReadLong f  -- alawys 0
				 Anihdr.blk_count = ReadLong f
				
					
			   ptr_count = Readlong f
			   ptr_off = Readlong f					
			    new_sz = ptr_off - 8 
					
					new_sz = ptr_off / 8 -- resize your ptr/count array with this
				
	
					fseek f 8 #seek_set
					
					-- parse header/re init new ptrs
					for i = 1 to new_sz - 1 do
					(
						 PtrObj = Pointer_Obj()
						 PtrObj.ptr_count = Readlong f
						 Ptrobj.ptr_offset = Readlong f
						 PtrObj.block_sz = PtrObj.ptr_count * 4
					
						append Pointers PtrObj
						 buffer.value = 100.*i/pointers.count
					)
					
					 -- loop thru all pointers, seek to relative offset
					-- resize 
						for x = 1 to pointers.count do
						(
							fseek f pointers[x].ptr_offset #seek_set
							
						     for j = 1 to pointers[x].ptr_count do
							 (
								 offsets.count = pointers[x].ptr_count
								 
								 cur_off = ftell f
								 offsets[j] = Readlong f
								 
								 -- if offset isnt negative 1 keep track of how many non negative offsets are in the block
								 if offsets[j] != -1 then
								 (  
									inc += 1     
									append animoffs offsets[j]
									--format "\n Main Pointer: % Sub Index: % Anim offset: % Ftell %"  pointers[x].ptr_offset j offsets[j] cur_off									 
								 )
							        								 
							 )
							 
							-- format "\n Pointers: %" pointers[x]
							 buffer.value = 100.*x/pointers.count
						)
				
								  -- loop thru anim offs, seek to each off, parse/store anim blocks
						
						

							for y = 1 to Animoffs.count do 
								(
									
									--format "\n block index[%] anim offs: %" y animoffs[y]
									fseek f animoffs[y] #seek_set
									aniobj.ObjectID = ReadLong f
									aniobj.chunk_count = Readlong f
									aniobj.chunk_sz = Readlong f
									
									cmd_off = animoffs[y] + 32
									
									fseek f cmd_off #seek_set
									
									
									append animBlocks aniobj
									format "\n block index[%] Anim Blocks: %" y animBlocks[y]
									
									
									LB_ANI.items = append LB_ANI.items ("Offset:" + (animoffs[y]) as string)
									
								)
			
					
			/*		
					
					
							
					
					fseek f 5768 #seek_set
					
				
					
					cur_off = ftell f
					new_off = cur_off + 20
					
					fseek f new_off #seek_set
					anisubobj.sub_objectID = Readlong f
					anisubobj.sub_container_count = Readlong f
					anisubobj.sub_container_sz = Readlong f
					
					
					
					
					for j = 0 to anisubobj.sub_container_count do
					(
						anisubInstr.instr_id = Readlong f
						anisubInstr.instr_count = Readlong f
						anisubInstr.instr_sz = Readlong f
						
						format "\nIndex %  ID: %  Count: % Size: %" j anisubInstr.instr_id anisubInstr.instr_count anisubInstr.instr_sz
						
					)
					
				*/	
					
				)
				
		
				if Fclose f then
				(
				 print "Stream closed succesfully!\n"	
				)
		
			
		)
	)
	
	on LB_ANI selected idx do 
	(
		idxStr = idx as string
		offStr = animoffs[idx] as string
	  messagebox offStr
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
		
	
			
			allBones = #()
			
			
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
					cur_pos += 192
			
				fseek f cur_pos #seek_set
				append allBones Bone_Data					
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
								allbones[b].theBone.Width =0 0.05
								allbones[b].theBone.height = 0.05      
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
							---	allbones[b].theBone.pos.controller = TCB_position()
							--	allbones[b].theBone.rotation.controller = TCB_rotation()
								allbones[b].theBone.transform = allbones[b].theBone.transform * (allbones[b].theBone.parent.transform)
								allbones[b].theBone.renderable = true
					
							)
						
							
                          				format "\n%" allbones[b]     						
						
					)
		   
					
					--max select all
					
					
					 if Fclose f then
					(
					   format "\n Filestream closed succesfully"
					)
					
		
			
		)
	
	on BTN_ABOUT pressed do
	(
	MessageBox "Outbreak AHI Tool 1.0\n Only Supports importing of player/enemy AHI data \n Supported Extensions\n (nbd/ahi)\n, DCHAPS 9/16/2016!" title: "About" beep: false
	)
	
	on BTN_RESET pressed do 
		(
		 max select all
		 max delete
		)
	

	)
createdialog Main_Dialog width:250 height:450
)
