macroscript NB_AOT 
category:"NETBIO DATA" 
tooltip:"AOT CAM DATA"
icon:#("MaxScript",1)

(
rollout MainForm "NB_AOT/CAM" width:333 height:714
(
	button 'BTN_AOT_IMPORT' "OPEN AOT" pos:[22,626] width:95 height:43 align:#left
	button 'IMPORT_CAM' "OPEN CAM" pos:[21,567] width:95 height:47 align:#left
	label 'LBL_FPATH' "" pos:[0,688] width:324 height:19 align:#left
	dotNetControl 'lv_objects' "System.Windows.Forms.ListView" pos:[18,139] width:295 height:409 align:#left
	colorPicker 'cp1' "ColorPicker" pos:[208,608] width:98 height:68 align:#left
	GroupBox 'grp1' "RDT DATA" pos:[6,111] width:314 height:578 align:#left
	bitmap 'bmp1' "Bitmap" pos:[9,8] width:312 height:77 fileName:"nbrdt.bmp" align:#left
		

	
	
	struct AOT_OBJ
		(
		TAG,
    ID,
    X_0,
    Y_0,
    X_1,
    Y_1,
    X_2,
    Y_2,
    X_3,
    Y_3,
    Z_0,
    Z_1,
    UNK_00,
    UNK_01,
    UNK_02,
    UNK_03,
    UNK_04,
    UNK_05,
    UNK_06,
    UNK_07,
    UNK_08,
    UNK_09,
    UNK_10,
    UNK_11,
    UNK_12,
    UNK_13,
    UNK_14,
    UNK_15,
    UNK_16,
    UNK_17,
    UNK_18,
    UNK_19,
    UNK_20,
    UNK_21,
    UNK_22,
    UNK_23,
    UNK_24,
    UNK_25,
    UNK_26,
    UNK_27,
    UNK_28,
    UNK_29,
    UNK_30,
    UNK_31,
    UNK_32,
    UNK_33,
    UNK_34,
    UNK_35,
    UNK_36,
    UNK_37,
    UNK_38,
    UNK_39,
    UNK_40,
    UNK_41,
    UNK_42,
    UNK_43,
    UNK_44,
    UNK_45,
    UNK_46,
    UNK_47,
    UNK_48,
    UNK_49,
    UNK_50,
    UNK_51,
    UNK_52,
    UNK_53,
    UNK_54,
    UNK_55,
    UNK_56,
    UNK_57,
    UNK_58,
    UNK_59,
    UNK_60,
    UNK_61,
    UNK_62,
    UNK_63 
			
		)
	
	
		fn axis_flip val =
		(
			if val <=0 then
			(
				val = abs(val)
			)else if val >=0 then
			(
			   	val = val - (val * 2)
			)
			
		)
		
		
		
			fn InitAOT LV =
		(
			lv.gridlines = true
			lv.view = (dotnetclass "System.Windows.Forms.View").Details
			lv.fullRowSelect = true
			lv.BackColor = (dotnetclass "System.Drawing.Color").Black
			lv.Forecolor = (dotnetclass "System.Drawing.Color").LimeGreen
			layout_Def =#("Index", "Obj", "AOT_TYPE")
			
			for i in layout_Def do
				lv.columns.add i 58
			
		)
		
		-- import aot function
		fn Import_AOT filename LV =
		(
				V_SCALE = 1000
				vcount = 0
				local ListItem =#()
				global All_AOTS=#()
				f = fopen filename "rb" 
						--open file stream , create string ref, create extension check
		
			fToStr = f as string
		
		 ext_len = fToStr.count - 3
	    str_ext = substring fToStr ext_len 3 
		
			
			if f != undefined then
			(
				local MeshRay =#()
				
					-- check extension..
					if str_ext == "RDT" or str_ext == "rdt" then
					(
						format "Fpath: %" ftoStr
						fseek f 80 #seek_set 
						OFF_BASE = Readlong f
					--	format "\nOffset Base: %" OFF_BASE
						fseek f OFF_BASE #seek_set
						
						
						h_tag = Readlong f
						h_count = Readlong f
						--format "\nhcount%" h_count
						global LST_OFFSETS =#()
						
						for i = 1 to h_count do
						(
							O_TMP = readlong f
							append LST_OFFSETS O_TMP
					--		format "\n : %" LST_OFFSETS[i]
						)
				
						
						for i = 1 to h_count do
						(
							
							strindex = i as string
					
							   off_test = OFF_BASE + LST_OFFSETS[i]
							fseek f off_test #seek_set
						--	format "\n Looped Offsets %" off_test
							
							global AOT_DATA = AOT_OBJ()
							
							
							/*#00 00 00 00            Doors
							#05 00 00 00            Messages
							#07 00 00 00            Used for desks, items related
							*/
							
							
							AOT_DATA.TAG = readlong f
							AOT_DATA.ID = readlong f
							AOT_DATA.X_0 = readlong f 
							AOT_DATA.Y_0 = readlong f 
							AOT_DATA.X_1 = readlong f 
							AOT_DATA.Y_1 =  readlong f 
							AOT_DATA.X_2 = readlong f 
							AOT_DATA.Y_2 =  readlong f 
							AOT_DATA.X_3 = readlong f 
							AOT_DATA.Y_3 =  readlong f 
							AOT_DATA.Z_0 = readlong f
							AOT_DATA.Z_1 = readlong f
							
							-- flip the y
							AOT_DATA.Y_0 = axis_flip AOT_DATA.Y_0
							AOT_DATA.Y_1 = axis_flip AOT_DATA.Y_1
							AOT_DATA.Y_2 = axis_flip AOT_DATA.Y_2
							AOT_DATA.Y_3 = axis_flip AOT_DATA.Y_3
							
							
					
		vertz = #(AOT_DATA.X_0, AOT_DATA.Y_0, AOT_DATA.Z_0, -- vert 0
        AOT_DATA.X_1, AOT_DATA.Y_1, AOT_DATA.Z_0, -- vert 1
        AOT_DATA.X_2, AOT_DATA.Y_2, AOT_DATA.Z_0, -- vert 2
        AOT_DATA.X_3, AOT_DATA.Y_3, AOT_DATA.Z_0, -- vert 3
        AOT_DATA.X_0, AOT_DATA.Y_0, AOT_DATA.Z_1, -- vert 4
        AOT_DATA.X_1, AOT_DATA.Y_1, AOT_DATA.Z_1, -- vert 5
        AOT_DATA.X_2, AOT_DATA.Y_2, AOT_DATA.Z_1, -- vert 6
        AOT_DATA.X_3, AOT_DATA.Y_3, AOT_DATA.Z_1) -- vert 7
		
		--  format "verts: %" vertz
		
		
			mat3s =#([AOT_DATA.X_0, AOT_DATA.Y_0, AOT_DATA.Z_0], -- vert 0
       [AOT_DATA.X_1, AOT_DATA.Y_1, AOT_DATA.Z_0], -- vert 1
        [AOT_DATA.X_2, AOT_DATA.Y_2, AOT_DATA.Z_0], -- vert 2
        [AOT_DATA.X_3, AOT_DATA.Y_3, AOT_DATA.Z_0], -- vert 3
        [AOT_DATA.X_0, AOT_DATA.Y_0, AOT_DATA.Z_1], -- vert 4
        [AOT_DATA.X_1, AOT_DATA.Y_1, AOT_DATA.Z_1], -- vert 5
        [AOT_DATA.X_2, AOT_DATA.Y_2, AOT_DATA.Z_1], -- vert 6
        [AOT_DATA.X_3, AOT_DATA.Y_3, AOT_DATA.Z_1]) 
		
		
		
	
		
		/*	  facezx = #(0, 1, 2, 3, -- face 1
        0, 4, 5, 1, -- face 2
        0, 4, 7, 3, -- face 3
        3, 2, 6, 7, -- face 4
        1, 2, 6, 5, -- face 5
        4, 7, 6, 5)  -- face 6 , 
		*/
	    facez = #([1, 2, 3], -- face 1
	   [4, 5, 1], -- face 2
       [4, 7, 3], -- face 3
       [2, 6, 7], -- face 4
	   [2, 6, 5], -- face 5
	   [7, 6, 5])  -- face 6 , 
		
		
	   IDSTRING = ""
	  
	   
	   IF AOT_DATA.TAG == 0 then IDSTRING = "DOOR" as string
	   IF AOT_DATA.TAG == 5 then IDSTRING = "MESSAGES" as string
	   IF AOT_DATA.TAG == 7 then IDSTRING = "DESKS/INTERACTABLE?" as string
	   
		
	   
	    
	   
	   
	   
	  
		 thename = "aot_" + i as string
		
		
				mm = mesh name:thename vertices:mat3s faces:facez
			  convertToMesh mm
						update mm
	
	        if IDSTRING == "DOOR" then mm.wirecolor = yellow
			if IDSTRING == "MESSAGES" then mm.wirecolor = orange
			if IDSTRING == "DESKS/INTERACTABLE?" then mm.wirecolor = white
				
			
				
	
	   
	   
	   append All_AOTS mm
	   
	   	lvItem = dotnetObject "System.Windows.Forms.ListViewItem" strindex
	     SubItem = lvItem.subItems.add thename
	    SubItem = lvItem.subItems.add IDSTRING
	  
	    append ListItem lvItem
	   
	  
	   
	   
		
						)
			                 LV.Items.AddRange ListItem
					)
					
			
			)
			
	
				
				-- print close...
				if Fclose f then
					(
					 print "\nfstream close succcess"	
					)
				
				
				
		)
		
		
	

	

	
	on MainForm open do
	(
		InitAOT lv_objects
		clearListener()
		max select all
		max delete
		encryptScript "C:\Users\Nomad\Desktop\NB_AOT_CAM.ms" version:1
		
	)
	on BTN_AOT_IMPORT pressed do
	(
		
		
	f = getOpenFileName caption: "RDT IMPORT" \
		filename: " " \
		types: "RDT(*.rdt)|*.rdt|All|*.*|"
		
		LBL_FPATH.text = f
			
			-- run import function on selected file
		
			Import_AOT f lv_objects
			
	
		
				
	)
	on lv_objects ItemSelectionChanged e do
	(
		index = e.ItemIndex + 1
		strindex = index as string
		select All_AOTS[index]
		
	)
)
	
createdialog MainForm width:333 height:741 style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
)
