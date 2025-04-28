global The_INI_Path = ( ( getDir #userScripts )+ "/NIMIKKO/Export_Settings_3_0.ini" )
formatInfo = #(	
	#( "FBX", "FBXEXP", ".FBX" ),
	#( "OBJ", "ObjExp", ".OBJ" ),
	#( "3DS", "3D_StudioExporterPlugin", ".3DS" ),
	#( "DWG", "DWG_ExportExporterPlugin", ".DWG" ),
	#( "DXF", "DWG_Export", ".DXF" ),
	#( "ABC", "Alembic_Export", ".ABC" ),
	#( "SAT", "ACIS_SAT", ".SAT" ),
	#( "DAE", "DAEEXP", ".DAE" ),
	#( "IGS", "IGES_Export", ".IGS" ),
	#( "W3D", "SW3D_Exp", ".W3D" ),
	#( "FLT", "OpenFltExport", ".FLT" ),
	#( "ASE", "AsciiExp", ".ASE" ),
	#( "DWF", "DWF_Exporter", ".DWF" ),
	#( "STL", "STL_Exporter", ".STL" ),
	#( "PLY", "PLYEXP", ".PLY" ),
	#( "GLTF", "glTFExporter", ".GLTF" ), -- check plugin availability before enabling
	#( "USD", "USDExport", ".USD" ), -- optional, if plugin exists
	#( "VRSCENE", -1, ".VRSCENE" ),
	#( "MAX", -2, ".MAX" )
)
fn getExporterData index =
if index > 0 and index <= formatInfo.count then
	formatInfo[index]
else
	undefined
fn saveSetting section key value = 
(	
	if The_INI_Path != undefined do
		setINISetting The_INI_Path section key( value as string )
)
fn loadSetting section key fallback: undefined = 
(	
	if The_INI_Path != undefined then
	(		
		try( execute( getINISetting The_INI_Path section key ) ) catch( fallback )
	)
	else
		fallback
)
fn applyCheckbox checkboxCtrl section key default: false = 
(	
	local val = try( execute( getINISetting The_INI_Path section key ) ) catch( default )
	checkboxCtrl.checked = if val == undefined then
		default
	else
		val
)
fn replaceTokens name obj = 
(	
	local localTime = getLocalTime()
	local tokenKeys = #( "%name", "%layer", "%file", "%frame", "%YYYY", "%YY", "%MM", "%DD", "%hh", "%mm", "%ss" )
	local tokenValues = #(		
		if isValidNode obj then
			obj.name
		else
			"Unnamed",
		try( obj.layer.name ) catch( "NoLayer" ),
		getFilenameFile maxFileName,
		( currentTime as integer ) as string,
		formattedPrint localTime[1] format: "04d",
		substring( formattedPrint localTime[1] format: "04d" ) 3 2,
		formattedPrint localTime[2] format: "02d",
		formattedPrint localTime[4] format: "02d",
		formattedPrint localTime[5] format: "02d",
		formattedPrint localTime[6] format: "02d",
		formattedPrint localTime[7] format: "02d"
	)
	for i = 1 to tokenKeys.count do
		name = substituteString name tokenKeys[i] tokenValues[i]
	return name
)
fn ApplyNamingTemplate template obj = replaceTokens template obj
presetKeys = #(	
	#( "Format", ExportFormat ),
	#( "Collision_Prefix", CollisionType ),
	#( "Name_Template", NameTemplate ),
	#( "MoveToCenter", MoveToCenter ),
	#( "ResetRotation", ResetRotation ),
	#( "ResetX", ResetX ),
	#( "ConvertToEditableMesh", ConvertToEditableMesh ),
	#( "AddCollision", AddCollision ),
	#( "MergeAllNodes", MergeAllNodes ),
	#( "Show_Prompt", ShowPrompt ),
	#( "ExportToMaxfileLocation", ExportToMaxfileLocation ),
	#( "ExportByLayer", ExportByLayer ),
	#( "MaxLayerDepth", MaxLayerDepth ),
	#( "ReverseLayerDepth", ReverseLayerDepth ),
	#( "AddFormatFolder", AddFormatFolder ),
	#( "ExportToOwnFolder", ExportToOwnFolder )
)
try( destroyDialog TKT ) catch()
try( destroyDialog AboutRollout ) catch()
rollout AboutRollout "About Bulk Exporter v3.0" width: 440 height: 510

(	
	groupBox grpCredits "Credits" pos:[10, 10] width: 420 height: 100
	label lblTitle "Bulk Exporter v3.0" pos:[20, 30] width: 400 height: 16
	label lblOrig "Originally developed by Benjamin Boscher (n00byzor)" pos:[20, 50] width: 400 height: 16
	label lblMod "Modified by Asutekku for Nimikko" pos:[20, 70] width: 400 height: 16
	label lblFree "Free for all use and/or modifications. Cheers!" pos:[20, 90] width: 400 height: 16
	groupBox grpChangelog "Changelog (v3.0)" pos:[10, 115] width: 420 height: 330
	label lblChange1 "• Added 'Reset Rotation' option" pos:[20, 135] width: 400 height: 16
	label lblChange2 "• Export based on Layer structure (folder hierarchy)" pos:[20, 150] width: 400 height: 16
	label lblChange3 "• Save/Load/Delete Presets support" pos:[20, 165] width: 400 height: 16
	label lblChange4 "• Format-based subfolder option" pos:[20, 180] width: 400 height: 16
	label lblChange5 "• Export to own folder per object" pos:[20, 195] width: 400 height: 16
	label lblChange6 "• Live name preview and validation" pos:[20, 210] width: 400 height: 16
	label lblChange7 "• Naming templates with tokens (e.g. %name, %layer, %YYYY)" pos:[20, 225] width: 400 height: 16
	label lblChange8 "• New formats: STL, PLY, glTF, USD (if plugin available)" pos:[20, 240] width: 400 height: 16
	label lblChange9 "• Modular export logic and path generation" pos:[20, 255] width: 400 height: 16
	label lblChange10 "• Enhanced INI handling and last-used preset memory" pos:[20, 270] width: 400 height: 16
	label lblChange11 "• Two-column UI layout and inline tooltips" pos:[20, 285] width: 400 height: 16
	label lblChange12 "• Name validation to prevent invalid characters" pos:[20, 300] width: 400 height: 16
	label lblChange13 "• Prompts for unsaved preset changes" pos:[20, 315] width: 400 height: 16
	groupBox grpLinks "Links" pos:[10, 455] width: 420 height: 50
	label lblScriptSpot "Original script:" pos:[20, 470] width: 100 height: 16
	hyperlink ScriptSpotLink "Scriptspot" pos:[130, 470] width: 200 height: 16 color:( color 0 221 241 ) hovercolor:( color 0 255 0 ) visitedcolor:( color 0 221 241 ) address: "http://www.scriptspot.com/3ds-max/scripts/batch-exporter-0"
	label lblGithub "More scripts by Nimikko:" pos:[20, 485] width: 150 height: 16
	hyperlink NimikkoLink "GitHub" pos:[180, 485] width: 200 height: 16 color:( color 0 221 241 ) hovercolor:( color 0 255 0 ) visitedcolor:( color 0 221 241 ) address: "https://github.com/asutekku/max-scripts"
)
-- HELP ROLLOUT ADDITIONS
rollout HelpRollout "Help: Bulk Exporter v3.0" width: 520 height: 600

(	
	groupBox grpGeometry "Geometry" pos:[10, 10] width: 500 height: 100
	label geom1 "• Move to [0,0,0] – Centers objects temporarily before export." pos:[20, 30] width: 480
	label geom2 "• Reset Rotation – Applies neutral rotation before export." pos:[20, 45] width: 480
	label geom3 "• Reset XForm – Clears transforms to fix scaling/rotation issues." pos:[20, 60] width: 480
	label geom4 "• Convert to Editable Mesh – Converts to mesh before export." pos:[20, 75] width: 480
	label geom5 "• Merge All Nodes – Merges children under a dummy/point into one mesh." pos:[20, 90] width: 480
	groupBox grpName "Name" pos:[10, 115] width: 500 height: 70
	label name1 "• Change name – Adds prefix/suffix for exported files only." pos:[20, 135] width: 480
	label name2 "• Live Preview – Shows how final name will look, based on template." pos:[20, 150] width: 480
	label name3 "• Validation – Warns on illegal characters in name (e.g. : * ? < > |)." pos:[20, 165] width: 480
	groupBox grpCollision "Collision" pos:[10, 190] width: 500 height: 55
	label col1 "• Add Collision – Combines meshes with matching prefix (e.g. UCX_)." pos:[20, 210] width: 480
	groupBox grpGeneral "General" pos:[10, 250] width: 500 height: 40
	label gen1 "• Show prompt before export – Enables format-specific export options." pos:[20, 270] width: 480
	groupBox grpFormat "Format & Path" pos:[10, 295] width: 500 height: 120
	label f1 "• Format – Choose output type: FBX, OBJ, etc." pos:[20, 315] width: 480
	label f2 "• Path – Set export folder via dropdown or browse." pos:[20, 330] width: 480
	label f3 "• Export To Max File Location – Overrides path with .max location." pos:[20, 345] width: 480
	label f4 "• Max Folder – Opens .max folder in Explorer." pos:[20, 360] width: 480
	label f5 "• Add Format Folder – Adds subfolder matching selected format." pos:[20, 375] width: 480
	label f6 "• Export to Own Folder – Each object gets its own named folder." pos:[20, 390] width: 480
	groupBox grpLayer "Layer Export" pos:[10, 425] width: 500 height: 65
	label lay1 "• Export Based on Layer Structure – Auto-creates folders from layer names." pos:[20, 445] width: 480
	label lay2 "• Max Layer Depth – Controls how many layers deep to use." pos:[20, 460] width: 480
	label lay3 "• Reverse Layer Depth – Uses child-most layer names first when ON." pos:[20, 475] width: 480
	groupBox grpPresets "Export Presets" pos:[10, 495] width: 500 height: 55
	label pre1 "• Save – Store current settings." pos:[20, 515] width: 480
	label pre2 "• Load – Apply saved preset." pos:[150, 515] width: 480
	label pre3 "• X – Delete selected preset." pos:[280, 515] width: 480
)
fn ShowHelpRollout = 
(	
	try( destroyDialog HelpRollout ) catch()
	createDialog HelpRollout style: #( #style_titlebar, #style_sysmenu, #style_toolwindow )
)
rollout CustomPrefixDialog "Custom Collision Prefix"

(	
	editText customPrefixInput "Prefix:" text: "COL_" width: 150
	button okBtn "OK" width: 60
	local result = undefined
	on okBtn pressed do
	(		
		result = customPrefixInput.text
		destroyDialog CustomPrefixDialog
	)
	fn getResult = result
)
rollout PresetNameDialog "New Preset"

(	
	edittext presetNameInput "Preset Name:" width: 150
	button okBtn "OK"
	local result = undefined
	on okBtn pressed do
	(		
		result = presetNameInput.text
		destroyDialog PresetNameDialog
	)
	fn getResult = result
)
fn showPresetNameDialogAndGetName = 
(	
	try( destroyDialog PresetNameDialog ) catch()
	createDialog PresetNameDialog modal: true
	PresetNameDialog.getResult()
)
-- MAIN ROLLOUT --
rollout TKT "Bulk Exporter" width: 520 height: 470

(	
	local theClasses = exporterPlugin.classes
	local TheChildren = #()
	local CollisionMeshes = #()
	local MeshesToSelect = #()
	local LinkedToDummy = False
	global TheSelection = #()
	local TheExportPath
	local ExportPresets = #()
	local currentLoadedPreset = undefined
	local lastLoadedSettings = #()
	-- Top bar
	label versionLbl "v3.0" pos:[10, 10]
	button AboutButton "About" pos:[410, 8] width: 45
	button HelpButton "Help" pos:[460, 8] width: 45
	-- LEFT COLUMN -------------------------------------------
	groupBox grpLeft "Settings" pos:[10, 35] width: 250 height: 400
	-- Geometry
	groupBox grpGeometry "Geometry" pos:[20, 55] width: 230 height: 120
	checkbox MoveToCenter "Move to [0,0,0]" pos:[30, 70]
	checkbox ResetRotation "Reset Rotation" pos:[30, 88]
	checkbox ResetX "Reset XForm" pos:[30, 106]
	checkbox ConvertToEditableMesh "Convert to editable mesh" pos:[30, 124]
	checkbox MergeAllNodes "Merge All Nodes" pos:[30, 142]
	-- Export Name Template
	groupBox grpNamingTemplate "Export Name Template" pos:[20, 180] width: 230 height: 65
	label lblTemplate "Name:" pos:[30, 200]
	edittext NameTemplate "" pos:[75, 198] width: 120 tooltip: "Use tokens like %name, %layer, %YYMMDD"
	button ShowTokens "?" pos:[200, 196] width: 20 height: 20 tooltip: "Show available tokens"
	label ExportNamePreview "Preview: ---" pos:[30, 218] width: 200
	-- Collision
	groupBox grpCollision "Collision" pos:[20, 250] width: 230 height: 50
	checkbox AddCollision "Add collision" pos:[30, 270] tooltip: "Merge mesh with matching prefix (e.g. UCX_)"
	label lblColType "Type:" pos:[130, 272] width: 30
	dropdownlist CollisionType items: #( "UCX_", "UBX_", "USP_", "MCDCX_", "Custom..." ) pos:[165, 268] width: 55
	-- RIGHT COLUMN ------------------------------------------
	groupBox grpRight "Export Settings" pos:[270, 35] width: 240 height: 275
	-- Format
	label formatLbl "Format:" pos:[280, 55]
	dropdownList ExportFormat items: #() pos:[330, 50] width: 160
	label pathLbl "Path:" pos:[280, 85]
	dropdownList ExportPaths items: #() pos:[280, 105] width: 180
	button Browse "..." pos:[465, 105] width: 30
	checkbox ExportToMaxfileLocation "Export To Max File Location" pos:[280, 130] width: 160
	button OpenMaxfileLocation "Max Folder" pos:[440, 128] width: 60
	-- Layer Export
	checkbox ExportByLayer "Export Based on Layer Structure" pos:[280, 160] width: 220
	label maxDepthLbl "Max Layer Depth" pos:[280, 185]
	spinner MaxLayerDepth range:[1, 10, 1] pos:[400, 182] width: 40 type: #integer
	checkbox ReverseLayerDepth "Reverse Layer Depth" pos:[280, 205] width: 180
	-- Presets
	groupBox grpPresets "Export Preset" pos:[280, 235] width: 220 height: 50
	dropdownList PresetsList items: #() pos:[290, 250] width: 135
	button SavePresetButton "Save" pos:[430, 250] width: 30 tooltip: "Save preset"
	button DeletePresetButton "X" pos:[465, 250] width: 30 tooltip: "Delete selected preset"
	-- Advanced Export Options
	groupBox grpAdvanced "Advanced Options" pos:[270, 310] width: 240 height: 85
	checkbox AddFormatFolder "Add filetype to folder name" pos:[280, 330]
	checkbox ExportToOwnFolder "Each object to its own folder" pos:[280, 350]
	checkbox ShowPrompt "Show prompt before export" pos:[280, 370]
	button Export_Button "Export Selection" pos:[280, 405] width: 220 height: 50
	-- ***********************************************************************************************************************************
	-- **************************************************  FUNCTIONS  ********************************************************************
	-- ***********************************************************************************************************************************
	fn GetINISettings = 
	(		
		if( getFiles The_INI_Path ).count != 0 then
		(			
			try( DialogPositionExportTool = loadSetting "Dialog_Position" "DialogPositionExportTool" ) catch()
			-- Load export paths
			ExportPaths.items = loadSetting "Paths" "Export_Paths" fallback: #()
			if ExportPaths.items.count == 0 do
			(				
				temp01 = getDir #export
				insertItem temp01 ExportPaths.items 1
				ExportPaths.items = makeUniqueArray ExportPaths.items
				saveSetting "Paths" "Export_Paths" ExportPaths.items
			)
			-- Load presets
			ExportPresets = loadSetting "Presets" "Preset_Names" fallback: #()
			currentLoadedPreset = getINISetting The_INI_Path "Presets" "LastUsedPreset"
			if currentLoadedPreset != undefined and currentLoadedPreset != "" do
			(				
				if findItem ExportPresets currentLoadedPreset > 0 then
				(					
					LoadPreset currentLoadedPreset
					lastLoadedSettings = collectCurrentSettings()
				)
			)
			PresetsList.items = ExportPresets
			-- Format selection
			local fmtSel = loadSetting "Format" "Selected_Format" fallback: 1
			ExportFormat.selection = fmtSel
			-- Collision type (handle custom types)
			local savedColPrefix = getINISetting The_INI_Path "Texts" "Collision_Prefix"
			local foundIndex = findItem CollisionType.items savedColPrefix
			if foundIndex == 0 and savedColPrefix != "" do
			(				
				append CollisionType.items savedColPrefix
				foundIndex = findItem CollisionType.items savedColPrefix
			)
			CollisionType.selection = if foundIndex > 0 then
				foundIndex
			else
				1
			-- Name template
			local savedTemplate = getINISetting The_INI_Path "Texts" "Name_Template"
			NameTemplate.text = if savedTemplate != "" then
				savedTemplate
			else
				"%name"
			-- Apply checkboxes and spinner using helpers
			applyCheckbox MoveToCenter "Checkboxes" "MoveToCenter"
			applyCheckbox ResetRotation "Checkboxes" "ResetRotation"
			applyCheckbox ResetX "Checkboxes" "ResetX"
			applyCheckbox ConvertToEditableMesh "Checkboxes" "ConvertToEditableMesh"
			applyCheckbox AddCollision "Checkboxes" "AddCollision"
			applyCheckbox MergeAllNodes "Checkboxes" "MergeAllNodes"
			applyCheckbox ShowPrompt "Checkboxes" "Show_Prompt"
			applyCheckbox ExportToMaxfileLocation "Checkboxes" "ExportToMaxfileLocation"
			applyCheckbox AddFormatFolder "Checkboxes" "AddFormatFolder"
			applyCheckbox ExportByLayer "Checkboxes" "ExportByLayer"
			applyCheckbox ReverseLayerDepth "Checkboxes" "ReverseLayerDepth"
			-- Max layer depth (spinner)
			try
			(				
				local d = getINISetting The_INI_Path "Values" "MaxLayerDepth"
				MaxLayerDepth.value = if d != "" then
					execute d
				else
					1
			)
			catch( MaxLayerDepth.value = 1 )
		)
		else
		(			
			-- First-time initialization
			DialogPositionExportTool = getDialogPos TKT
			saveSetting "Dialog_Position" "DialogPositionExportTool" DialogPositionExportTool
			temp01 = getDir #export
			insertItem temp01 ExportPaths.items 1
			ExportPaths.items = makeUniqueArray ExportPaths.items
			saveSetting "Paths" "Export_Paths" ExportPaths.items
			ExportPresets = #()
			saveSetting "Presets" "Preset_Names" ExportPresets
			saveSetting "Format" "Selected_Format" ExportFormat.selection
			saveSetting "Texts" "Collision_Prefix" CollisionType.selected
			saveSetting "Texts" "Name_Template" NameTemplate.text
			-- Save all default checkbox and spinner states
			SaveCurrentPreset "Checkboxes"
			saveSetting "Values" "MaxLayerDepth" MaxLayerDepth.value
		)
	)
	fn ShowTokenReference = 
	(		
		local msg = ""
		msg += "Available Naming Tokens:\n\n"
		msg += "%name       - Object name\n"
		msg += "%layer      - Layer name\n"
		msg += "%file       - .max file name\n"
		msg += "%frame      - Current frame number\n"
		msg += "%YYYY       - Year (e.g. 2025)\n"
		msg += "%YY         - Short year (25)\n"
		msg += "%MM         - Month (01-12)\n"
		msg += "%DD         - Day (01-31)\n"
		msg += "%hh         - Hour (00-23)\n"
		msg += "%mm         - Minute (00-59)\n"
		msg += "%ss         - Second (00-59)\n"
		messageBox msg title: "Available Tokens"
	)
	on ShowTokens pressed do
		ShowTokenReference()
	-- PRESET FUNCTIONS
	fn collectCurrentSettings = 
	(		
		#(			
			ExportFormat.selection,
			CollisionType.selected,
			NameTemplate.text,
			MoveToCenter.checked,
			ResetRotation.checked,
			ResetX.checked,
			ConvertToEditableMesh.checked,
			AddCollision.checked,
			MergeAllNodes.checked,
			ShowPrompt.checked,
			ExportToMaxfileLocation.checked,
			ExportByLayer.checked,
			MaxLayerDepth.value,
			ReverseLayerDepth.checked,
			AddFormatFolder.checked
		)
	)
	fn settingsHaveChanged = 
	(		
		collectCurrentSettings()!= lastLoadedSettings
	)
	fn SaveCurrentPreset presetName = 
	(		
		if presetName == "" then
			return false
		-- Create a unique section name for this preset
		local sectionName = "Preset_" + presetName
		-- Save all current settings to the preset section
		setINISetting( The_INI_Path ) sectionName "Format"( ExportFormat.selection as string )
		setINISetting( The_INI_Path ) sectionName "Collision_Prefix" CollisionType.items[CollisionType.selection]
		setINISetting( The_INI_Path ) sectionName "Name_Template" NameTemplate.text
		setINISetting( The_INI_Path ) sectionName "MoveToCenter"( MoveToCenter.checked as string )
		setINISetting( The_INI_Path ) sectionName "ResetRotation"( ResetRotation.checked as string )
		setINISetting( The_INI_Path ) sectionName "ResetX"( ResetX.checked as string )
		setINISetting( The_INI_Path ) sectionName "ConvertToEditableMesh"( ConvertToEditableMesh.checked as string )
		setINISetting( The_INI_Path ) sectionName "AddCollision"( AddCollision.checked as string )
		setINISetting( The_INI_Path ) sectionName "MergeAllNodes"( MergeAllNodes.checked as string )
		setINISetting( The_INI_Path ) sectionName "Show_Prompt"( ShowPrompt.checked as string )
		setINISetting( The_INI_Path ) sectionName "ExportToMaxfileLocation"( ExportToMaxfileLocation.checked as string )
		setINISetting( The_INI_Path ) sectionName "ExportByLayer"( ExportByLayer.checked as string )
		setINISetting( The_INI_Path ) sectionName "MaxLayerDepth"( MaxLayerDepth.value as string )
		setINISetting( The_INI_Path ) sectionName "ReverseLayerDepth"( ReverseLayerDepth.checked as string )
		setINISetting( The_INI_Path ) sectionName "AddFormatFolder"( AddFormatFolder.checked as string )
		setINISetting( The_INI_Path ) sectionName "ExportToOwnFolder"( ExportToOwnFolder.checked as string )
		-- Add to preset list if not already there
		if( findItem ExportPresets presetName )== 0 then
		(			
			append ExportPresets presetName
			setINISetting( The_INI_Path ) "Presets" "Preset_Names"( ExportPresets as string )
			-- Update the dropdown
			PresetsList.items = ExportPresets
		)
		return true
	)
	fn LoadPreset presetName = 
	(		
		if presetName == "" then
			return false
		-- Create the section name for this preset
		local sectionName = "Preset_" + presetName
		-- Check if the preset exists
		if( getINISetting The_INI_Path sectionName "Format" )== "" then
			return false
		-- Load all settings from the preset
		ExportFormat.selection = execute( getINISetting The_INI_Path sectionName "Format" )
		local savedCollisionPrefix = getINISetting The_INI_Path sectionName "Collision_Prefix"
		local foundIndex = findItem CollisionType.items savedCollisionPrefix
		if foundIndex == 0 then
		(			
			-- Handle custom prefix
			append CollisionType.items savedCollisionPrefix
			foundIndex = findItem CollisionType.items savedCollisionPrefix
		)
		CollisionType.selection = foundIndex
		NameTemplate.text = getINISetting The_INI_Path sectionName "Name_Template"
		-- Fix for boolean values - safely parse them with error handling
		fn safeParseBoolean iniValue defaultValue = 
		(			
			if iniValue == "" then
				return defaultValue
			try
			(				
				local result = execute( iniValue )
				if classOf result == BooleanClass then
					result
				else
					defaultValue
			)
			catch
			(				
				defaultValue
			)
		)
		-- Apply boolean values safely
		MoveToCenter.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "MoveToCenter" ) false
		ResetRotation.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ResetRotation" ) false
		ResetX.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ResetX" ) false
		ConvertToEditableMesh.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ConvertToEditableMesh" ) false
		AddCollision.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "AddCollision" ) false
		MergeAllNodes.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "MergeAllNodes" ) false
		ShowPrompt.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "Show_Prompt" ) false
		ExportToMaxfileLocation.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ExportToMaxfileLocation" ) false
		ExportByLayer.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ExportByLayer" ) false
		ReverseLayerDepth.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ReverseLayerDepth" ) false
		AddFormatFolder.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "AddFormatFolder" ) false
		ExportToOwnFolder.checked = safeParseBoolean( getINISetting The_INI_Path sectionName "ExportToOwnFolder" ) false
		-- Handle the spinner (numeric) value
		try
		(			
			MaxLayerDepth.value = execute( getINISetting The_INI_Path sectionName "MaxLayerDepth" )
		)
		catch
		(			
			MaxLayerDepth.value = 1
		)
		-- Update UI based on loaded settings
		if ExportFormat.selection == 14 then
		(			
			AddCollision.enabled = false
		)
		else
		(			
			AddCollision.enabled = true
		)
		if MergeAllNodes.checked == False then
		(			
			ResetX.enabled = False
			ConvertToEditableMesh.enabled = False
		)
		else
			if MergeAllNodes.checked == True then
		(			
			ResetX.enabled = True
			ConvertToEditableMesh.enabled = True
		)
		if ExportToMaxfileLocation.checked then
		(			
			ExportPaths.enabled = false
			Browse.enabled = false
		)
		else
		(			
			ExportPaths.enabled = true
			Browse.enabled = true
		)
		return true
	)
	fn DeletePreset presetName = 
	(		
		if presetName == "" then
			return false
		-- Create the section name for this preset
		local sectionName = "Preset_" + presetName
		-- Delete all settings for this preset
		delIniSetting The_INI_Path sectionName
		-- Remove from preset list
		local index = findItem ExportPresets presetName
		if index > 0 then
		(			
			deleteItem ExportPresets index
			setINISetting( The_INI_Path ) "Presets" "Preset_Names"( ExportPresets as string )
			-- Update the dropdown
			PresetsList.items = ExportPresets
			if PresetsList.items.count > 0 then
				PresetsList.selection = 1
		)
		return true
	)
	-- END PRESET FUNCTIONS
	fn FindExporterClass TheClass = 
	(		
		Counter = 1
		for i in theClasses do
		(			
			if i as string == TheClass then
			(				
				return Counter
			)
			Counter += 1
		)
		if Counter == theClasses.count then
			return 0
	)
	fn GetExporterClass = 
	(		
		if ExportFormat.selection != undefined and ExportFormat.selection > 0 and ExportFormat.selection <= formatInfo.count then
		(			
			local exporterCode = formatInfo[ExportFormat.selection][2]
			-- Special handling for VRSCENE and MAX (negative codes)
			if exporterCode == -1 or exporterCode == -2 then
				return exporterCode
			-- Otherwise find exporter class from string
			return FindExporterClass exporterCode
		)
		else
			return undefined
	)
	fn GetRoot obj = -- Get the root of obj
	(		
		while
			obj.parent != undefined do
			obj = obj.parent
		return obj
	)
	on CollisionType selected typeIndex do
	(		
		if CollisionType.selected == "Custom..." then
		(			
			createDialog CustomPrefixDialog modal: true
			local userInput = CustomPrefixDialog.getResult()
			if userInput != undefined and userInput != "" then
			(				
				if findItem CollisionType.items userInput == 0 then
				(					
					local currentItems = CollisionType.items
					local customIndex = findItem currentItems "Custom..."
					insertItem userInput currentItems customIndex
					CollisionType.items = currentItems
				)
				CollisionType.selection = findItem CollisionType.items userInput
			)
			else
			(				
				CollisionType.selection = 1 -- fallback to UCX_
			)
		)
	)
	fn SelectObjAndCollisionMeshes obj UcxMeshes InitialUCXPos = 
	(		
		if LinkedToDummy == True then
		(			
			for i in CollisionMeshes do
				i.pos = obj.pos
			if MergeAllNodes.checked == False then
				select( CollisionMeshes + MeshesToSelect )
			else
				select( CollisionMeshes + obj )
		)
		else
		(			
			ClearSelection()
			local colPrefix = CollisionType.selected
			execute( "select $" + colPrefix + obj.name + "*" )
			for i in selection do
			(				
				append InitialUCXPos i.pos
				i.pos = obj.pos
				append UcxMeshes i
			)
			select( UcxMeshes + obj )
		)
	)
	fn GetAllChildren obj TheChildren = -- Get all the children of obj and append them to TheChildren
	(		
		if obj.children != undefined then
			for i in obj.children do
		(			
			appendifunique TheChildren i
			GetAllChildren i TheChildren
		)
	)
	fn MergeChildren TheRoot CollisionMeshes = -- Merge all the children of TheRoot and return them as a collapsed mesh,  and store collision meshes in CollisionMeshes (snap collision pivot point on root)
	(		
		free TheChildren
		free CollisionMeshes
		free MeshesToSelect
		MeshesToMerge = #()
		GetAllChildren TheRoot TheChildren
		for i in TheChildren do
		(			
			if CollisionType.selected != "" and matchPattern i.name pattern:( CollisionType.selected + "*" ) then
			(				
				if AddCollision.checked then
				(					
					NewObj = snapshot i
					NewObj.name = i.name
					NewObj.parent = TheRoot
					NewObj.pivot = TheRoot.pos
					appendifunique CollisionMeshes NewObj
				)
			)
			else
			(				
				if MergeAllNodes.checked == true then
				(					
					if superClassOf i != GeometryClass or( superClassOf i == GeometryClass and findString i.name "_" == 1 ) then
						-- Ignore meshes with name starting with "_"
					(						
						-- nothing ^^
					)
					else
					(						
						NewObj = snapshot i
						NewObj.parent = none
						resetxform NewObj
						collapseStack NewObj
						if classOf NewObj != Editable_Poly then
							convertTo NewObj Editable_Poly
						append MeshesToMerge NewObj
					)
				)
				else
				(					
					if findString i.name "_" != 1 then
						append MeshesToSelect i -- Ignore meshes with name starting with "_"
				)
			)
		)
		if MergeAllNodes.checked == true then
		(			
			FirstObj = MeshesToMerge[1]
			for i = 2 to MeshesToMerge.count do
			(				
				FirstObj.attach MeshesToMerge[i] FirstObj
			)
			FirstObj.parent = none
			FirstObj.pivot = TheRoot.pos
			FirstObj.transform = TheRoot.transform
			FirstObj.name = TheRoot.name
			return FirstObj
		)
		else
		(			
			return TheRoot
		)
	)
	fn SortSelection SelectionList = -- If any of the selected objects is linked to a dummy or a point helper, then keep this helper only in the selection
	(		
		-- if no parent or no helper then keep a copy of the selected objects in the selection
		local NewSelectionList = #()
		for i in SelectionList do
		(			
			TheRoot = GetRoot i
			if classOf( TheRoot )== Dummy or classOf( TheRoot )== Point then
			(				
				appendifunique NewSelectionList TheRoot
			)
			else
			(				
				-- Store the original layer
				local originalLayer = i.layer
				-- Make a copy
				NewObj = copy i
				NewObj.name = i.name
				-- Ensure the copy is on the same layer as the original
				if originalLayer != undefined then
				(					
					originalLayer.addnode NewObj
				)
				append NewSelectionList NewObj
			)
		)
		return NewSelectionList
	)
	fn AddFormatToName TheName = 
	(		
		if ExportFormat.selection > 0 and ExportFormat.selection <= formatInfo.count then
		(			
			local info = formatInfo[ExportFormat.selection]
			if info.count >= 3 and classOf info[3] == String then
				return TheName + info[3]
		)
		return TheName
	)
	fn GetLayerPath obj maxDepth reverseDepth = 
	(		
		try
		(			
			-- Get the object's layer name directly from the object
			local objLayerName = obj.layer.name
			-- Don't create folders for Default layer (0)
			if objLayerName == undefined or objLayerName == "0" or objLayerName == "Default" then
			(				
				return ""
			)
			-- Find the layer in the layer manager
			local foundLayer = undefined
			-- Search through all layers to find matching layer by name
			for i = 0 to LayerManager.count - 1 do
			(				
				local testLayer = LayerManager.getLayer i
				if testLayer.name == objLayerName then
				(					
					foundLayer = testLayer
					exit
				)
			)
			if foundLayer == undefined then
			(				
				return ""
			)
			-- Get the layer hierarchy
			local fullHierarchy = #()
			local currentLayer = foundLayer
			-- Build array of layer names from bottom up
			while
				currentLayer != undefined do
			(				
				if currentLayer.name != "0" and currentLayer.name != "Default" then
				(					
					append fullHierarchy currentLayer.name
				)
				-- Try to get the parent layer
				local parentLayer = currentLayer.getParent()
				currentLayer = parentLayer
			)
			-- Reverse to get top-down hierarchy 
			fullHierarchy = for i = fullHierarchy.count to 1 by -1 collect
				fullHierarchy[i]
			-- Build the path based on max depth and direction
			local layerPath = ""
			if reverseDepth then
			(				
				-- Take layers from the bottom (most child levels)
				-- For example with Props->Buildings->Kitchen and depth 1, we get "Kitchen"
				if fullHierarchy.count > 0 then
				(					
					local startIndex = fullHierarchy.count -( maxDepth - 1 )
					if startIndex < 1 then
						startIndex = 1
					for i = startIndex to fullHierarchy.count do
					(						
						layerPath += fullHierarchy[i]
						if i < fullHierarchy.count then
							layerPath += "\\"
					)
				)
			)
			else
			(				
				-- Take layers from the top (most parent levels)
				-- For example with Props->Buildings->Kitchen and depth 1, we get "Props"
				local endIndex = if maxDepth > fullHierarchy.count then
					fullHierarchy.count
				else
					maxDepth
				for i = 1 to endIndex do
				(					
					layerPath += fullHierarchy[i]
					if i < endIndex then
						layerPath += "\\"
				)
			)
			return layerPath
		)
		catch
		(			
			-- If any error occurs, just return empty string - no layer-based folder
			return ""
		)
	)
	fn CreateLayerDirectory basePath layerPath = 
	(		
		if layerPath != "" then
		(			
			local fullPath = basePath + "\\" + layerPath
			-- Create directory if it doesn't exist
			if not doesFileExist fullPath then
			(				
				local result = makeDir fullPath all: true
			)
			else
				-- Return full path
			return fullPath
		)
		else
		(			
			return basePath
		)
	)
	fn ValidateName name = 
	(		
		local invalidChars = #( "/", ":", "*", "?", "<", ">", "|", "/", "\\" )
		for c in invalidChars do
		(			
			if findString name c != undefined do
				return false
		)
		return true
	)
	fn ApplyNamingTemplate template obj = 
	(		
		local name = template
		local theName = if isValidNode obj then
			obj.name
		else
			"Unnamed"
		local theLayer = try( obj.layer.name ) catch( "NoLayer" )
		local timeArray = getLocalTime()
		local fileNameOnly = getFilenameFile maxFileName
		name = substituteString name "%name" theName
		name = substituteString name "%layer" theLayer
		name = substituteString name "%file" fileNameOnly
		name = substituteString name "%frame"( ( currentTime as integer ) as string )
		name = substituteString name "%YYYY"( formattedPrint timeArray[1] format: "04d" )
		name = substituteString name "%YY"( substring( formattedPrint timeArray[1] format: "04d" ) 3 2 )
		name = substituteString name "%MM"( formattedPrint timeArray[2] format: "02d" )
		name = substituteString name "%DD"( formattedPrint timeArray[4] format: "02d" )
		name = substituteString name "%hh"( formattedPrint timeArray[5] format: "02d" )
		name = substituteString name "%mm"( formattedPrint timeArray[6] format: "02d" )
		name = substituteString name "%ss"( formattedPrint timeArray[7] format: "02d" )
		return name
	)
	fn UpdateNamePreview = 
	(		
		if selection.count > 0 then
		(			
			local preview = ApplyNamingTemplate NameTemplate.text selection[1]
			ExportNamePreview.text = "Preview: " + preview
		)
		else
		(			
			ExportNamePreview.text = "Preview: ---"
		)
	)
	fn Export_Stuff obj ExporterClass = 
	(		
		-- Determine base export path
		if ExportToMaxfileLocation.checked then
			TheExportPath = maxFilePath as string
		else
			TheExportPath = ExportPaths.selected as string
		-- Add filetype folder (if selected and valid)
		if AddFormatFolder.checked do
		(			
			if ExportFormat.selection > 0 do
			(				
				local formatFolder = ExportFormat.items[ExportFormat.selection]
				if formatFolder != undefined and formatFolder != "" do
				(					
					TheExportPath += "\\" + formatFolder
					makeDir TheExportPath all: true
				)
			)
		)
		-- Layer-based folder (if enabled)
		if ExportByLayer.checked then
		(			
			local layerPath = GetLayerPath obj MaxLayerDepth.value ReverseLayerDepth.checked
			if layerPath != "" then
			(				
				TheExportPath = CreateLayerDirectory TheExportPath layerPath
			)
		)
		-- Build base file name
		local baseName = ApplyNamingTemplate NameTemplate.text obj
		-- Initialize final path with base export path
		local finalExportPath = TheExportPath
		-- Own-folder export
		if ExportToOwnFolder.checked do
		(			
			finalExportPath += "\\" + baseName
			if not doesFileExist finalExportPath do
				makeDir finalExportPath
		)
		-- Final file path with name
		local TheObjName = finalExportPath + "\\" + baseName
		TheObjName = AddFormatToName TheObjName
		-- Collision support
		if AddCollision.checked then
		(			
			UcxMeshes = #()
			InitialUCXPos = #()
			SelectObjAndCollisionMeshes obj UcxMeshes InitialUCXPos
		)
		else
		(			
			if not MergeAllNodes.checked and LinkedToDummy then
				select MeshesToSelect
			else
				select obj
		)
		-- Export logic
		if ExporterClass == -2 and ExportFormat.selection != 2 then
		(			
			saveNodes $ TheObjName
		)
		else
		(			
			if ExportCounter == 0 and ShowPrompt.checked then
				exportFile TheObjName selectedOnly: true using: theClasses[ExporterClass]
			else
				exportFile TheObjName #noPrompt selectedOnly: true using: theClasses[ExporterClass]
		)
		-- Post-export collision cleanup
		if AddCollision.checked then
		(			
			if LinkedToDummy then
			(				
				for i = CollisionMeshes.count to 1 by -1 do
					delete CollisionMeshes[i]
			)
			else
			(				
				for j = 1 to UcxMeshes.count do
					UcxMeshes[j].pos = InitialUCXPos[j]
			)
		)
		-- Delete temp obj if necessary
		if MergeAllNodes.checked or not LinkedToDummy then
			delete obj
	)
	-- Export validation
	fn ValidateExportConditions = 
	(		
		if ExportToMaxfileLocation.checked and( maxFilePath == undefined or maxFilePath == "" ) do
		(			
			messageBox "No max file currently opened :o"
			return false
		)
		if selection.count == 0 and( TheSelection == undefined or TheSelection.count == 0 ) do
		(			
			messageBox "Selection is empty!"
			return false
		)
		if ExportPaths.selected == undefined and not ExportToMaxfileLocation.checked do
		(			
			messageBox "Please select an export path ;)"
			return false
		)
		return true
	)
	fn PrepareSelection = 
	(		
		if selection.count > 0 then
		(			
			TheSelection = selection as array
		)
		else
		(			
			TheSelection = for node in TheSelection
			where
				isValidNode node collect
				node
		)
		SortSelection TheSelection
	)
	fn ExportVRSceneObjects selectedObjs = 
	(		
		-- Determine export path
		TheExportPath = if ExportToMaxfileLocation.checked then
			maxFilePath
		else
			ExportPaths.selected
		-- Hide everything in the scene
		local UnHiddenObj = #()
		for o in objects
		where
			not o.isHidden do
		(			
			append UnHiddenObj o
			o.isHidden = true
		)
		for i = 1 to selectedObjs.count do
		(			
			local obj = selectedObjs[i]
			local ParentedToDummy = false
			-- Duplicate and gather children if object is a Dummy or Point
			if classOf obj == Dummy or classOf obj == Point do
			(				
				ParentedToDummy = true
				free TheChildren
				GetAllChildren obj TheChildren
				local newRoot = copy obj
				newRoot.name = obj.name
				obj = newRoot
				for j in TheChildren do
				(					
					local newChild = copy j
					newChild.parent = obj
				)
				free TheChildren
				GetAllChildren obj TheChildren -- Fill again with copies
			)
			-- Unhide for export
			obj.isHidden = false
			-- Apply transforms
			if MoveToCenter.checked do
				obj.pos = [0, 0, 0]
			if ResetX.checked do
			(				
				if ParentedToDummy then
				(					
					for j in TheChildren do
					(						
						resetxform j
						collapseStack j
					)
				)
				else
				(					
					resetxform obj
					collapseStack obj
				)
			)
			if ConvertToEditableMesh.checked do
			(				
				if ParentedToDummy then
				(					
					for j in TheChildren do
						convertToMesh j
				)
				else
				(					
					convertToMesh obj
				)
			)
			if ParentedToDummy then
			(				
				for j in TheChildren do
					j.isHidden = false
			)
			-- Handle layer-based export path
			if ExportByLayer.checked do
			(				
				local layerPath = GetLayerPath obj MaxLayerDepth.value ReverseLayerDepth.checked
				if layerPath != "" do
					TheExportPath = CreateLayerDirectory TheExportPath layerPath
			)
			-- Build and validate name
			local baseName = ApplyNamingTemplate NameTemplate.text obj
			local exportPath = TheExportPath + "\\" + baseName
			exportPath = AddFormatToName exportPath
			if not ValidateName baseName then
			(				
				MessageBox( "Invalid characters in export name: " + baseName )
				continue
			)
			-- Export VRSCENE
			vrayExportRTScene exportPath
			-- Cleanup temp objects
			if ParentedToDummy then
			(				
				for j in TheChildren do
					delete j
				delete obj
			)
			else
			(				
				delete obj
			)
			ExportCounter += 1
		)
		-- Restore hidden state
		for o in UnHiddenObj
		where
			isValidNode o do
			o.isHidden = false
		ClearSelection()
		select TheSelection
		max modify mode
	)
	fn ExportSelectedObjects objs = 
	(		
		for obj in objs do
		(			
			if classOf obj == Dummy or classOf obj == Point then
			(				
				obj = MergeChildren obj CollisionMeshes
				LinkedToDummy = True
			)
			else
				LinkedToDummy = False
			-- Apply transforms
			if MoveToCenter.Checked do
				obj.pos = [0, 0, 0]
			if ResetRotation.Checked do
				obj.rotation = quat 0 0 0 1
			if ResetX.checked and( MergeAllNodes.checked or not LinkedToDummy ) do
			(				
				resetxform obj
				collapseStack obj
			)
			if ConvertToEditableMesh.Checked and( MergeAllNodes.checked or not LinkedToDummy ) do
				convertToMesh obj
			-- Validate and export
			local finalName = ApplyNamingTemplate NameTemplate.text obj
			if not ValidateName finalName then
			(				
				messageBox( "Invalid characters in name: " + finalName )
				return false
			)
			Export_Stuff obj ExporterClass
			ExportCounter += 1
		)
		return true
	)
	fn RefreshPresetsDropdown = 
	(		
		if ExportPresets.count > 0 then
			PresetsList.items = ExportPresets + #( "Add New Preset..." )
		else
			PresetsList.items = #( "Add New Preset..." )
	)
	-- ***********************************************************************************************************************************
	-- **************************************************  EVENTS  ***********************************************************************
	-- ***********************************************************************************************************************************
	on TKT open do
	(		
		windows.sendmessage ExportPaths.hwnd[1] 352 450 0
		GetINISettings()
		if DialogPositionExportTool != undefined do
			SetDialogPos TKT DialogPositionExportTool
		-- Ensure dropdown is valid
		RefreshPresetsDropdown()
		-- Try to auto-load last used preset
		if ExportPresets.count > 0 then
		(			
			if currentLoadedPreset != undefined and currentLoadedPreset != "" then
			(				
				local idx = findItem ExportPresets currentLoadedPreset
				if idx > 0 then
				(					
					PresetsList.selection = idx
					LoadPreset currentLoadedPreset
					lastLoadedSettings = collectCurrentSettings()
				)
			)
			else
			(				
				-- If no last-used preset, just load first
				currentLoadedPreset = ExportPresets[1]
				PresetsList.selection = 1
				LoadPreset currentLoadedPreset
				lastLoadedSettings = collectCurrentSettings()
			)
		)
		else
		(			
			PresetsList.selection = 1 -- This will be "Add New Preset..." if no real presets
		)
		-- Format-related UI enable/disable
		if ExportFormat.selection == 14 then
		(			
			AddCollision.enabled = false
			CollisionType.enabled = false
		)
		else
		(			
			AddCollision.enabled = true
			CollisionType.enabled = true
		)
		ResetX.enabled = MergeAllNodes.checked
		ConvertToEditableMesh.enabled = MergeAllNodes.checked
		ExportPaths.enabled = not ExportToMaxfileLocation.checked
		Browse.enabled = not ExportToMaxfileLocation.checked
		-- Populate exporter formats
		ExportFormat.items = for f in formatInfo
		where
		(			
			( classOf f[2] == String and FindExporterClass f[2] != undefined and FindExporterClass f[2] > 0 ) or
			( classOf f[2] == Integer and( f[2] == -1 or f[2] == -2 ) )
		)
		collect
			f[1]
		UpdateNamePreview()
	)
	on TKT close do
	(		
		setINISetting The_INI_Path "Dialog_Position" "DialogPositionExportTool"( GetDialogPos TKT as string )
	)
	-- Checkbox handlers
	on MoveToCenter changed val do
		saveSetting "Checkboxes" "MoveToCenter" val
	on ResetRotation changed val do
		saveSetting "Checkboxes" "ResetRotation" val
	on ResetX changed val do
		saveSetting "Checkboxes" "ResetX" val
	on ConvertToEditableMesh changed val do
		saveSetting "Checkboxes" "ConvertToEditableMesh" val
	on MergeAllNodes changed val do
	(		
		saveSetting "Checkboxes" "MergeAllNodes" val
		ResetX.enabled = val
		ConvertToEditableMesh.enabled = val
	)
	on AddCollision changed val do
		saveSetting "Checkboxes" "AddCollision" val
	on ExportToMaxfileLocation changed val do
	(		
		saveSetting "Checkboxes" "ExportToMaxfileLocation" val
		ExportPaths.enabled = not val
		Browse.enabled = not val
	)
	on ExportByLayer changed val do
		saveSetting "Checkboxes" "ExportByLayer" val
	on ReverseLayerDepth changed val do
		saveSetting "Checkboxes" "ReverseLayerDepth" val
	on AddFormatFolder changed val do
		saveSetting "Checkboxes" "AddFormatFolder" val
	on ShowPrompt changed val do
		saveSetting "Checkboxes" "Show_Prompt" val
	on MaxLayerDepth changed val do
		saveSetting "Values" "MaxLayerDepth" val
	-- Text handlers
	on NameTemplate changed val do
	(		
		saveSetting "Texts" "Name_Template" val
		UpdateNamePreview()
	)
	-- Dropdown handlers
	on ExportFormat selected idx do
	(		
		saveSetting "Format" "Selected_Format" idx
		local isSupported = idx != 14
		AddCollision.enabled = isSupported
		CollisionType.enabled = isSupported
	)
	on ExportPaths selected idx do
	(		
		insertItem ExportPaths.selected ExportPaths.items 1
		ExportPaths.items = makeUniqueArray ExportPaths.items
		ExportPaths.selection = 1
		saveSetting "Paths" "Export_Paths" ExportPaths.items
	)
	on ExportPaths rightClick do
	(		
		if ExportPaths.selected != undefined do
			shellLaunch "explorer.exe" ExportPaths.selected
	)
	on Browse pressed do
	(		
		local initial = if ExportPaths.selected != undefined then
			ExportPaths.selected
		else
			getDir #export
		local ExportPath = getSavePath initialDir: initial
		if ExportPath != undefined do
		(			
			insertItem ExportPath ExportPaths.items 1
			ExportPaths.items = makeUniqueArray ExportPaths.items
			saveSetting "Paths" "Export_Paths" ExportPaths.items
		)
	)
	on Browse rightClick do
	(		
		if queryBox "Are you sure you want to remove the selected path from the list?" then
		(			
			ExportPaths.items = deleteItem ExportPaths.items 1
			saveSetting "Paths" "Export_Paths" ExportPaths.items
		)
	)
	on Browse pressed do
	(		
		if ExportPaths.selected != undefined then
			Global ExportPath = getSavepath initialDir: ExportPaths.selected
		else
			Global ExportPath = getSavepath initialDir:( GetDir #export )
		if ExportPath != undefined do
		(			
			insertItem ExportPath ExportPaths.items 1
			ExportPaths.items = makeUniqueArray ExportPaths.items
			setINISetting( The_INI_Path ) "Paths" "Export_Paths"( ExportPaths.items as string )
		)
	)
	on Browse rightClick do
	(		
		if QueryBox "Are you sure you want to remove the selected path from the list ?" then
		(			
			ExportPaths.items = deleteItem ExportPaths.items 1
			setINISetting( The_INI_Path ) "Paths" "Export_Paths"( ExportPaths.items as string )
		)
	)
	on ExportToMaxfileLocation changed ExportToMaxfileLocation_State do
	(		
		setINISetting( The_INI_Path ) "Checkboxes" "ExportToMaxfileLocation"( ExportToMaxfileLocation_State as string )
		if ExportToMaxfileLocation.checked then
		(			
			ExportPaths.enabled = false
			Browse.enabled = false
		)
		else
		(			
			ExportPaths.enabled = true
			Browse.enabled = true
		)
	)
	-- NEW EVENT HANDLERS
	on ExportByLayer changed ExportByLayer_State do
		setINISetting( The_INI_Path ) "Checkboxes" "ExportByLayer"( ExportByLayer_State as string )
	on MaxLayerDepth changed MaxLayerDepth_Value do
		setINISetting( The_INI_Path ) "Values" "MaxLayerDepth"( MaxLayerDepth_Value as string )
	on ReverseLayerDepth changed ReverseLayerDepth_State do
		setINISetting( The_INI_Path ) "Checkboxes" "ReverseLayerDepth"( ReverseLayerDepth_State as string )
	-- END NEW EVENT HANDLERS
	on OpenMaxfileLocation pressed do
	(		
		if maxFilePath != undefined and maxFilePath != "" then
		(			
			TheCompleteMaxFilePath = maxFilePath + maxFileName
			shellLaunch "explorer.exe"( "/select, " + TheCompleteMaxFilePath as string )
		)
		else
			messageBox "No max file currently opened :o"
	)
	on Export_Button pressed do
	(		
		undo off
		
		(			
			max create mode
			local exportValid = ValidateExportConditions()
			if not exportValid then
				messageBox "Please fix errors before exporting."
			local SelectedObj = #()
			if exportValid then
			(				
				if selection.count > 0 then
					TheSelection = selection as array
				else
					TheSelection = for node in TheSelection
				where
					isValidNode node collect
					node
				if TheSelection.count > 0 then
					SelectedObj = SortSelection TheSelection
				else
					messageBox "No valid selection found."
			)
			local validPath = ExportPaths.selected != undefined or ExportToMaxfileLocation.checked
			local validSelection = SelectedObj.count > 0
			if exportValid and validPath and validSelection then
			(				
				ExporterClass = GetExporterClass()
				if ExporterClass == undefined or ExporterClass == 0 then
				(					
					messageBox "Export plugin not found!"
				)
				else
				(					
					global ExportCounter = 0
					-- VRSCENE export
					if ExporterClass == -1 then
					(						
						ExportVRSceneObjects SelectedObj
					)
					else
					(						
						-- Validate names first
						local allNamesValid = true
						for obj in SelectedObj do
						(							
							local nameToCheck = ApplyNamingTemplate NameTemplate.text obj
							if not ValidateName nameToCheck then
							(								
								messageBox( "Invalid characters in export name: " + nameToCheck )
								allNamesValid = false
							)
						)
						-- Export if all names are valid
						if allNamesValid then
							ExportSelectedObjects SelectedObj
					)
				)
			)
			-- Final cleanup: restore selection and mode
			ClearSelection()
			select TheSelection
			max modify mode
		)
	)
	on ShowPrompt changed ShowPromptState do
		setINISetting( The_INI_Path ) "Checkboxes" "Show_Prompt"( ShowPromptState as string )
	on AboutButton pressed do
	(		
		try( destroyDialog AboutRollout ) catch()
		CreateDialog AboutRollout
	)
	on SavePresetButton pressed do
	(		
		if currentLoadedPreset == undefined then
		(			
			local newName = showPresetNameDialogAndGetName()
			if newName != undefined and newName != "" then
			(				
				if SaveCurrentPreset newName then
				(					
					RefreshPresetsDropdown()
					PresetsList.selection = findItem PresetsList.items newName
					currentLoadedPreset = newName
					lastLoadedSettings = collectCurrentSettings()
				)
			)
		)
		else
		(			
			if SaveCurrentPreset currentLoadedPreset then
			(				
				lastLoadedSettings = collectCurrentSettings()
				messageBox "Preset updated."
			)
		)
	)
	-- LOAD / DROPDOWN CHANGE
	on PresetsList selected idx do
	(		
		local selectedName = PresetsList.items[idx]
		if selectedName == "Add New Preset..." then
		(			
			local newName = showPresetNameDialogAndGetName()
			if newName != undefined and newName != "" then
			(				
				if SaveCurrentPreset newName then
				(					
					RefreshPresetsDropdown()
					PresetsList.selection = findItem PresetsList.items newName
					currentLoadedPreset = newName
					lastLoadedSettings = collectCurrentSettings()
				)
			)
			else
			(				
				if currentLoadedPreset != undefined then
					PresetsList.selection = findItem PresetsList.items currentLoadedPreset
			)
		)
		else
		(			
			local proceed = true
			if settingsHaveChanged() then
			(				
				proceed = queryBox "You have unsaved changes.\nDo you want to discard them and load the selected preset?" title: "Unsaved Changes"
				if not proceed do
				(					
					PresetsList.selection = findItem PresetsList.items currentLoadedPreset
					return true
				)
			)
			if proceed then
			(				
				if LoadPreset selectedName then
				(					
					currentLoadedPreset = selectedName
					lastLoadedSettings = collectCurrentSettings()
					UpdateNamePreview()
					setINISetting The_INI_Path "Presets" "LastUsedPreset" currentLoadedPreset
				)
			)
		)
	)
	-- DELETE
	on DeletePresetButton pressed do
	(		
		if currentLoadedPreset != undefined then
		(			
			if queryBox( "Are you sure you want to delete preset '" + currentLoadedPreset + "'?" ) then
			(				
				if DeletePreset currentLoadedPreset then
				(					
					currentLoadedPreset = undefined
					lastLoadedSettings = #()
					RefreshPresetsDropdown()
					if ExportPresets.count > 0 then
					(						
						PresetsList.selection = 1
						currentLoadedPreset = ExportPresets[1]
						LoadPreset currentLoadedPreset
						lastLoadedSettings = collectCurrentSettings()
						setINISetting The_INI_Path "Presets" "LastUsedPreset" currentLoadedPreset
					)
					else
					(						
						PresetsList.selection = 0
						currentLoadedPreset = undefined
						lastLoadedSettings = #()
						setINISetting The_INI_Path "Presets" "LastUsedPreset" ""
					)
				)
			)		)
		else
		(			
			messageBox "No preset selected to delete."
		)
	)
	-- END PRESET EVENT HANDLERS
	on HelpButton pressed do
		ShowHelpRollout()
)
callbacks.removeScripts id: #NamePreviewCallback
callbacks.addScript #SelectionSetChanged "try(TKT.UpdateNamePreview())catch()" id: #NamePreviewCallback
macroScript BulkExporter
category: "Nimikko"
tooltip: "Bulk Exporter 3.0"
buttonText: "Bulk Exporter"
icon: #( "Containers", 8 )

(	
	on execute do
	(		
		CreateDialog TKT style: #( #style_titlebar, #style_sysmenu, #style_toolwindow )
	)
)
