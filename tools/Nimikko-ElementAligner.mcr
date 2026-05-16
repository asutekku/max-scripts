-- Element and Model Alignment Tool for 3ds Max
-- Aligns elements in Edit Poly / Editable Poly mode (across one OR
-- multiple selected objects, pooled in world space) or separate 3D models
try( destroyDialog ElementAlignmentTool ) catch()
rollout ElementAlignmentTool "Alignment Tools" width: 300 height: 555

(
	-- ===== Align to Axis =====
	groupBox grpAxis "Align to Axis" pos:[10, 8] width: 280 height: 92
	dropdownList ddlAlignMode "Alignment Mode:" items: #( "Average", "Minimum", "Maximum", "First Selected", "Last Selected" ) pos:[20, 28] width: 260
	button btnAlignX "Align to X" pos:[20, 66] width: 80 height: 26
	button btnAlignY "Align to Y" pos:[110, 66] width: 80 height: 26
	button btnAlignZ "Align to Z" pos:[200, 66] width: 80 height: 26

	-- ===== Align Evenly Settings =====
	groupBox grpEven "Align Evenly Settings" pos:[10, 110] width: 280 height: 150
	dropdownList ddlDistributionRef "Distribution Reference:" items: #( "Centers", "Bounding Box Centers", "Pivot Points" ) pos:[20, 130] width: 260
	dropdownList ddlDistributionMode "Distribution Mode:" items: #( "Maintain Relative Positions", "Straight Line", "Align to Axis" ) pos:[20, 173] width: 260
	label lblModeInfo "" pos:[20, 215] width: 260 height: 38

	-- ===== Distribution Options =====
	groupBox grpDist "Distribution Options" pos:[10, 270] width: 280 height: 210
	radiobuttons rbCustomMode "Distribute by:" labels: #( "Evenly", "Count", "Spacing" ) columns: 3 default: 1 pos:[20, 290] width: 260
	-- Count
	label lblCount "Count:" pos:[20, 322] width: 90 height: 18
	spinner spnElementCount "" type: #integer range:[2, 100, 3] pos:[115, 320] width: 155 enabled: true
	-- Spacing
	label lblSpacing "Spacing:" pos:[20, 348] width: 90 height: 18
	spinner spnSpacing "" type: #worldunits range:[0.01, 1e6, 10] pos:[115, 346] width: 155 enabled: false
	-- Spacing reference
	label lblSpacingRef "Spacing ref:" pos:[20, 374] width: 90 height: 18
	dropdownList ddlSpacingRef "" items: #( "Centers", "Bounding Box" ) pos:[115, 370] width: 155 enabled: false
	-- Clone type
	label lblCloneType "Clone type:" pos:[20, 400] width: 90 height: 18
	dropdownList ddlCloneType "" items: #( "Copy", "Instance", "Reference" ) pos:[115, 396] width: 155 enabled: true
	-- Randomize
	checkbox chkRandomize "Randomize order (shuffle slots)" pos:[20, 424] width: 250 checked: false tooltip: "Distribute evenly but assign objects to slots in random order. Fresh result each press."
	-- Align button
	button btnAlignEvenly "Align Evenly" pos:[70, 446] width: 160 height: 28

	-- ===== Coordinate System =====
	groupBox grpCoord "Coordinate System" pos:[10, 490] width: 280 height: 42
	radiobuttons rbCoordSystem labels: #( "Local", "World" ) columns: 2 pos:[20, 508] width: 260
	-- Tooltips & About section lives in separate rollout (like before)
	-- Variables to track current mode
	local isModelMode = false
	-- Return the array of face ids forming the full element (connected island)
	-- containing face f. theMod==undefined => Editable_Poly base object.
	fn elementFacesFor obj theMod f =
	(
		if theMod == undefined then
			return ( polyop.getElementsUsingFace obj #{ f } as array )
		theMod.SetSelection #Face #{ f } node:obj
		theMod.ConvertSelection #Face #Element
		return ( ( theMod.GetSelection #Face node:obj ) as array )
	)
	-- Extract selected elements from a single object (Editable_Poly or Edit_Poly modifier).
	-- Returns #( mod, #( elemFacesArray, ... ) ) or undefined if no face selection / not a poly.
	-- mod is undefined for Editable_Poly, or the Edit_Poly modifier instance otherwise.
	fn getObjElementSelection obj =
	(
		local theMod = undefined
		local faceSel = undefined
		-- Element mode must ONLY engage when this object is the one actively being
		-- edited at the Face/Polygon sub-object level. A stored face selection on a
		-- whole-object-selected mesh would otherwise be mistaken for element mode and
		-- move VERTICES instead of the node -- catastrophic for instances (shared
		-- mesh data warps every copy while the pivots stay put). Require: modify
		-- panel open, this object is the modify target, subobject level Face(4)/Poly(5).
		if ( getCommandPanelTaskMode() != #modify ) then
			return undefined
		local curObj = modPanel.getCurrentObject()
		if ( curObj == undefined ) then
			return undefined
		local soLevel = subObjectLevel
		if ( soLevel == undefined or soLevel < 4 ) then
			return undefined
		-- Confirm the active modify target actually belongs to THIS object.
		local isThisObj = false
		if ( classof curObj == Editable_Poly and curObj == obj.baseObject ) then
			isThisObj = true
		else
		(
			for m in obj.modifiers while not isThisObj do
				if ( m == curObj ) then isThisObj = true
		)
		if not isThisObj then
			return undefined
		if classof obj == Editable_Poly then
		(
			faceSel = ( polyop.getFaceSelection obj ) as array
		)
		else
		(
			for m in obj.modifiers
			where classof m == Edit_Poly do
			(
				if m.enabled then
				(
					theMod = m
					exit
				)
			)
			if theMod == undefined then
				return undefined
			-- GetSelection returns undefined when the object is selected but NOT in
			-- sub-object Face mode; don't cast undefined to array (that throws).
			local rawFaceSel = theMod.GetSelection #Face node:obj
			if rawFaceSel == undefined then
				return undefined
			faceSel = rawFaceSel as array
		)
		if faceSel == undefined or faceSel.count == 0 then
			return undefined
		-- Editable_Poly has polyop.getElementsUsingFace; the Edit_Poly modifier does
		-- NOT expose ElementsUsingFace, so we grow a single-face selection to its
		-- element via ConvertSelection and read it back (restoring selection after).
		local origEditSel = undefined
		if theMod != undefined then
			origEditSel = theMod.GetSelection #Face node:obj
		-- Group selected faces into elements
		local selectedElements = #()
		local processedFaces = #{}
		for f in faceSel do
		(
			if not processedFaces[f] then
			(
				local elemFaces = elementFacesFor obj theMod f
				local elementFound = false
				for ef in elemFaces do
				(
					if findItem faceSel ef > 0 then
					(
						elementFound = true
						exit
					)
				)
				if elementFound then
				(
					append selectedElements elemFaces
					for ef in elemFaces do
						processedFaces[ef] = true
				)
			)
		)
		-- Restore the user's original Edit_Poly face selection
		if theMod != undefined and origEditSel != undefined then
			theMod.SetSelection #Face origEditSel node:obj
		if selectedElements.count == 0 then
			return undefined
		return #( theMod, selectedElements )
	)
	-- Function to check if we're in model mode or element mode and update isModelMode variable.
	-- Element mode now spans ALL selected objects: returns #( #element, pool ) where
	-- pool is an array of #( obj, mod, elemFaces ) entries gathered across every object
	-- that has a sub-object face selection. If no object has an element selection we fall
	-- back to model mode (whole-object alignment).
	fn checkMode =
	(
		if selection.count == 0 then
		(
			isModelMode = false
			return undefined
		)
		-- Try to gather element selections from every selected object
		local pool = #()
		for obj in selection do
		(
			local res = getObjElementSelection obj
			if res != undefined then
			(
				local theMod = res[1]
				for elemFaces in res[2] do
					append pool #( obj, theMod, elemFaces )
			)
		)
		if pool.count > 0 then
		(
			isModelMode = false
			return #( #element, pool )
		)
		-- No element selection anywhere -> model mode
		isModelMode = true
		return #model
	)
	-- Helper functions for comparison
	-- qsort comparator: MUST return integer -1/0/1, not a bool. A bool
	-- return makes Max's qsort treat unequal items as equal -> garbage /
	-- non-deterministic order (this was the core alignment bug).
	fn compareBySecond a b =
	(
		if a[2] < b[2] then return -1
		if a[2] > b[2] then return 1
		return 0
	)
	-- Function to get selected models info
	fn getModelsInfo = 
	(		
		if selection.count == 0 then
			return undefined
		-- Set model mode flag
		isModelMode = true
		-- Return array with selected objects
		return #( selection as array )
	)
	-- Function to get model center
	fn getModelCenter obj refMode = 
	(		
		case refMode of
		(			
			1 : -- Centers (average of all vertices)
			(				
				local vertSum = [0, 0, 0]
				local vertCount = 0
				-- Get mesh vertices
				local mesh = snapshotAsMesh obj
				-- Sum all vertices
				for i = 1 to mesh.numverts do
				(					
					vertSum += mesh.verts[i].pos
					vertCount += 1
				)
				if vertCount > 0 then
					return vertSum / vertCount
				else
					return obj.center
			)
			2 : -- Bounding Box Center
			(				
				return obj.center
			)
			3 : -- Pivot Point
			(				
				return obj.pos
			)
			default: return obj.center
		)
	)
	-- Function to move model
	fn moveModel obj moveVec = 
	(		
		obj.pos += moveVec
	)
	-- Collect the unique vertex ids used by a set of faces.
	-- Editable_Poly: polyop.getFaceVerts. Edit_Poly modifier: GetFaceDegree +
	-- GetFaceVertex (the modifier has NO GetFaceVertices and its vertex/face
	-- accessors require the node: argument).
	fn elemVertIds obj mod elemFaces =
	(
		local vset = #{}
		if mod == undefined then
		(
			for f in elemFaces do
			(
				local fv = polyop.getFaceVerts obj f
				for v in fv do vset[v] = true
			)
		)
		else
		(
			for f in elemFaces do
			(
				local deg = mod.GetFaceDegree f node:obj
				for c = 1 to deg do
					vset[ mod.GetFaceVertex f c node:obj ] = true
			)
		)
		return ( vset as array )
	)
	-- Local-space position of a single vertex id.
	fn elemVertPos obj mod vid =
	(
		if mod == undefined then ( polyop.getVert obj vid )
		else ( mod.GetVertex vid node:obj )
	)
	-- Function to get element center
	fn getElementCenter obj mod elemFaces =
	(
		local verts = elemVertIds obj mod elemFaces
		if verts.count == 0 then return [0,0,0]
		local vertSum = [0,0,0]
		for v in verts do
			vertSum += elemVertPos obj mod v
		return vertSum / verts.count
	)
	-- Function to get element bounding box center
	fn getElementBBoxCenter obj mod elemFaces =
	(
		local verts = elemVertIds obj mod elemFaces
		if verts.count == 0 then return [0,0,0]
		local minPoint = [1e9, 1e9, 1e9]
		local maxPoint = [-1e9, -1e9, -1e9]
		for v in verts do
		(
			local vertPos = elemVertPos obj mod v
			minPoint.x = amin minPoint.x vertPos.x
			minPoint.y = amin minPoint.y vertPos.y
			minPoint.z = amin minPoint.z vertPos.z
			maxPoint.x = amax maxPoint.x vertPos.x
			maxPoint.y = amax maxPoint.y vertPos.y
			maxPoint.z = amax maxPoint.z vertPos.z
		)
		return ( minPoint + maxPoint ) / 2
	)
	-- World-space element center. polyop.getVert / Edit_Poly.GetVertex return points in
	-- the object's local space, so to compare elements that live on DIFFERENT objects we
	-- must lift them into world space via obj.objecttransform.
	fn getElementCenterWS obj mod elemFaces refMode =
	(
		local localC = if refMode == 2 then
			( getElementBBoxCenter obj mod elemFaces )
		else
			( getElementCenter obj mod elemFaces )
		return localC * obj.objecttransform
	)
	-- Move an element so its center shifts by worldVec (given in world space).
	fn moveElementWS obj mod elemFaces worldVec =
	(
		if mod == undefined then
		(
			-- Editable_Poly: setVert works in object-local space, so convert the
			-- world delta into a local-space direction (map vec and origin through
			-- the inverse transform, take the difference to drop translation).
			local invTM = inverse obj.objecttransform
			local localVec = ( worldVec * invTM ) - ( [0,0,0] * invTM )
			local vertSet = #{}
			for f in elemFaces do
			(
				local faceVerts = polyop.getFaceVerts obj f
				for v in faceVerts do
					vertSet[v] = true
			)
			for v in ( vertSet as array ) do
			(
				local p = polyop.getVert obj v
				polyop.setVert obj v ( p + localVec )
			)
		)
		else
		(
			-- Edit_Poly modifier: no setVert; select the element's faces and use
			-- MoveSelection. With an identity parent matrix MoveSelection works in
			-- WORLD space, so pass worldVec directly. Save/restore the user's
			-- face selection so multi-element loops don't clobber it.
			local prevSel = mod.GetSelection #Face node:obj
			local faceBitArray = #{}
			for f in elemFaces do
				faceBitArray[f] = true
			mod.SetSelection #Face faceBitArray node:obj
			mod.MoveSelection worldVec parent:( matrix3 1 )
			mod.SetSelection #Face prevSel node:obj
		)
	)
	fn getDominantAxis lineDir =
	(		
		local axisVec = #( abs lineDir.x, abs lineDir.y, abs lineDir.z )
		case( findItem axisVec( amax axisVec ) ) of
		(			
			1 : return 1 -- X
			2 : return 2 -- Y
			3 : return 3 -- Z
		)
	)
	-- Given the unoriented extreme endpoints, return a CANONICAL line:
	-- start = endpoint with the smaller coordinate on the line's dominant
	-- axis. Without this, which endpoint becomes "start" depends on
	-- `selection as array` iteration order (which Max reshuffles on
	-- undo/reselect), so the whole row mirrors direction non-
	-- deterministically. Returns #( startPoint, endPoint, lineDir ).
	fn orientExtremeLine pA pB =
	(
		local rawDir = pB - pA
		local dom = getDominantAxis rawDir
		local sp = pA
		local ep = pB
		if pA[dom] > pB[dom] then
		(
			sp = pB
			ep = pA
		)
		return #( sp, ep, ( normalize ( ep - sp ) ) )
	)
	-- Total order for projection sorting. Plain `a[2] < b[2]` returns
	-- false on equal projections; Max's qsort is NOT stable, so tied
	-- entries (evenly-spaced objects are full of ties) shuffle between
	-- runs. Tie-break by dominant-axis coord then full position so the
	-- order is fully deterministic and selection-order independent.
	-- Entry layout: #( idx, projection, domCoord, posPoint ).
	-- IMPORTANT: a MAXScript qsort comparator MUST return an INTEGER
	-- (-1 / 0 / 1), exactly like C's qsort. Returning a bool (true/false)
	-- makes qsort treat most pairs as "equal" -> garbage order. (The old
	-- compareBySecond returned a bool too, which is why it was flaky.)
	fn compareProjTotal a b =
	(
		if a[2] < b[2] - 1e-6 then return -1
		if a[2] > b[2] + 1e-6 then return 1
		if a[3] < b[3] - 1e-9 then return -1
		if a[3] > b[3] + 1e-9 then return 1
		local pa = a[4]
		local pb = b[4]
		if pa.x < pb.x then return -1
		if pa.x > pb.x then return 1
		if pa.y < pb.y then return -1
		if pa.y > pb.y then return 1
		if pa.z < pb.z then return -1
		if pa.z > pb.z then return 1
		return 0
	)
	fn getSortedIndicesByProjection centers startPoint dir =
	(
		local dom = getDominantAxis dir
		local indexed = #()
		for i = 1 to centers.count do
		(
			local projection = dot( centers[i] - startPoint ) dir
			append indexed #( i, projection, centers[i][dom], centers[i] )
		)
		qsort indexed compareProjTotal
		return indexed
	)
	-- Randomize feature: when chkRandomize is on, shuffle the sorted-slot
	-- array in place (Fisher-Yates) so objects land in random slots while
	-- the even-spaced grid built from it stays intact. Fresh result every
	-- press: seed from the system clock each call. Returns sortedArr (same
	-- ref) so call sites can write `sorted = maybeShuffleSlots sorted`.
	fn maybeShuffleSlots sortedArr =
	(
		if chkRandomize.checked then
		(
			seed ( ( timeStamp() ) as integer )
			for i = sortedArr.count to 2 by -1 do
			(
				local j = random 1 i
				local tmp = sortedArr[i]
				sortedArr[i] = sortedArr[j]
				sortedArr[j] = tmp
			)
		)
		return sortedArr
	)
	fn alignCentersByMode targets centers moveFn alignMode coordSystem objTransform =
	(		
		case alignMode of
		(			
			1 : -- Maintain Relative Positions
			(				
				local startPoint = targets[1][2]
				local endPoint = targets[targets.count][2]
				local lineVec = endPoint - startPoint
				local lineDir = normalize lineVec
				for i = 1 to targets.count do
				(					
					local idx = targets[i][1]
					local targetPos = targets[i][2]
					local center = centers[idx]
					local offsetVec = center - startPoint
					local currParam = dot offsetVec lineDir
					local currPos = startPoint +( lineDir * currParam )
					local moveVec = targetPos - currPos
					if coordSystem == 2 do
						moveVec = moveVec * ( inverse objTransform )
					moveFn idx moveVec
				)
			)
			2 : -- Straight Line
			(				
				for i = 1 to targets.count do
				(					
					local idx = targets[i][1]
					local targetPos = targets[i][2]
					local center = centers[idx]
					local moveVec = targetPos - center
					if coordSystem == 2 do
						moveVec = moveVec * ( inverse objTransform )
					moveFn idx moveVec
				)
			)
			3 : -- Align to Axis
			(				
				local startPoint = targets[1][2]
				local endPoint = targets[targets.count][2]
				local lineDir = normalize( endPoint - startPoint )
				local dominantAxis = getDominantAxis lineDir
				local axisVals = for i = 1 to targets.count collect( centers[targets[i][1]][dominantAxis] )
				local minVal = amin axisVals
				local maxVal = amax axisVals
				for i = 1 to targets.count do
				(					
					local idx = targets[i][1]
					local center = centers[idx]
					local targetVal = minVal +( ( maxVal - minVal )* ( i - 1 )/( targets.count - 1 ) )
					local moveVec = [0, 0, 0]
					moveVec[dominantAxis] = targetVal - center[dominantAxis]
					if coordSystem == 2 do
						moveVec = moveVec * ( inverse objTransform )
					moveFn idx moveVec
				)
			)
		)
	)
	-- Function to move element
	fn moveElement obj mod elemFaces moveVec = 
	(		
		if mod == undefined then
			-- Editable_Poly
		(			
			-- Get all unique vertices used by these faces
			local vertSet = #{}
			for f in elemFaces do
			(				
				local faceVerts = polyop.getFaceVerts obj f
				for v in faceVerts do
					vertSet[v] = true
			)
			-- Convert BitArray to array
			local vertArray = vertSet as array
			-- Move each vertex
			for v in vertArray do
			(				
				local pos = polyop.getVert obj v
				polyop.setVert obj v( pos + moveVec )
			)
		)
		else
			-- Edit_Poly modifier
		(			
			-- Create a BitArray for these faces
			local faceBitArray = #{}
			for f in elemFaces do
				faceBitArray[f] = true
			-- Select these faces
			mod.SetSelection #Face faceBitArray
			-- Move the selection using Move operation
			mod.Move moveVec
		)
	)
	-- Function to align elements to a specific axis value
	fn alignElementsToAxis obj mod selectedElems axis alignMode coordSystem = 
	(		
		local elemCenters = #()
		local targetPos = 0
		-- Get all element centers
		for elemFaces in selectedElems do
		(			
			if ddlDistributionRef.selection == 1 then
				-- Element Centers
			append elemCenters( getElementCenter obj mod elemFaces )
			else
				-- Bounding Box Centers
			append elemCenters( getElementBBoxCenter obj mod elemFaces )
		)
		-- Convert to world space if needed
		if coordSystem == 2 and obj.transform !=( matrix3 1 ) then
		(			
			for i = 1 to elemCenters.count do
				elemCenters[i] = elemCenters[i] * obj.transform
		)
		-- Determine target position based on alignment mode
		case alignMode of
		(			
			1 : -- Average
			(				
				local sum = 0
				for center in elemCenters do
					sum += center[axis]
				targetPos = sum / elemCenters.count
			)
			2 : -- Minimum
			(				
				targetPos = 1e9
				for center in elemCenters do
					if center[axis] < targetPos then
					targetPos = center[axis]
			)
			3 : -- Maximum
			(				
				targetPos = -1e9
				for center in elemCenters do
					if center[axis] > targetPos then
					targetPos = center[axis]
			)
			4 : -- First Selected
			targetPos = elemCenters[1][axis]
			5 : -- Last Selected
			targetPos = elemCenters[elemCenters.count][axis]
		)
		-- Move elements to target position
		for i = 1 to selectedElems.count do
		(			
			local elemFaces = selectedElems[i]
			local center = elemCenters[i]
			local moveVec = [0, 0, 0]
			moveVec[axis] = targetPos - center[axis]
			-- Convert move vector to local space if needed
			if coordSystem == 2 and obj.transform !=( matrix3 1 ) then
				moveVec = moveVec * ( inverse obj.transform )
			-- Move the element
			moveElement obj mod elemFaces moveVec
		)
	)
	fn moveElementFromWrapper obj mod resultElems idx vec = 
	(		
		moveElement obj mod resultElems[idx] vec
	)
	-- Function to align elements evenly between extremes
	fn alignElementsEvenly obj mod selectedElems coordSystem = 
	(		
		coordSystem = 1
		if selectedElems.count < 2 then
			return false
		-- Collect centers
		local elemCenters = for elemFaces in selectedElems collect
		(			
			case ddlDistributionRef.selection of
			(				
				1 : getElementCenter obj mod elemFaces
				2 : getElementBBoxCenter obj mod elemFaces
				default:[0, 0, 0]
			)
		)
		-- Convert to world space if needed
		if coordSystem == 2 and obj.transform !=( matrix3 1 ) then
		(			
			for i = 1 to elemCenters.count do
				elemCenters[i] = elemCenters[i] * obj.transform
		)
		-- Find extremes
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to elemCenters.count do
		(			
			for j = i + 1 to elemCenters.count do
			(				
				local d = distance elemCenters[i] elemCenters[j]
				if d > maxDist do
				(					
					maxDist = d
					extremeIndices = #( i, j )
				)
			)
		)
		local startPoint = elemCenters[extremeIndices[1]]
		local endPoint = elemCenters[extremeIndices[2]]
		local lineDir = normalize( endPoint - startPoint )
		local spacing = maxDist /( selectedElems.count - 1 )
		-- Sort by projection
		local sorted = getSortedIndicesByProjection elemCenters startPoint lineDir
		local targets = #()
		for i = 1 to sorted.count do
		(			
			local idx = sorted[i][1]
			local targetPos = startPoint + lineDir * ( spacing * ( i - 1 ) )
			append targets #( idx, targetPos )
		)
		-- ? Define move function properly
		-- Define a local struct to hold the move function with context
		struct LocalElementMover
		
		(			
			obj,
			mod,
			resultElems,
			fn move idx vec = 
			(				
				moveElementFromWrapper obj mod resultElems idx vec
			)
		)
		-- Create instance of local struct
		local mover = LocalElementMover obj: obj mod: mod resultElems: selectedElems
		-- Perform alignment using struct method
		alignCentersByMode targets elemCenters mover.move ddlDistributionMode.selection coordSystem obj.transform
		return true
	)
	-- ============================================================
	-- Multi-object element pool functions.
	-- pool = array of #( obj, mod, elemFaces ). All math is done in
	-- WORLD space so elements that live on different objects share
	-- one coordinate frame; moves are pushed back to local space by
	-- moveElementWS / getElementCenterWS.
	-- ============================================================
	fn poolCentersWS pool =
	(
		local refMode = ddlDistributionRef.selection
		return for e in pool collect ( getElementCenterWS e[1] e[2] e[3] refMode )
	)
	fn alignPoolToAxis pool axis alignMode =
	(
		local centers = poolCentersWS pool
		local targetPos = 0
		case alignMode of
		(
			1 : ( local s = 0.0; for c in centers do s += c[axis]; targetPos = s / centers.count )
			2 : ( targetPos = 1e9;  for c in centers do if c[axis] < targetPos do targetPos = c[axis] )
			3 : ( targetPos = -1e9; for c in centers do if c[axis] > targetPos do targetPos = c[axis] )
			4 : targetPos = centers[1][axis]
			5 : targetPos = centers[centers.count][axis]
		)
		for i = 1 to pool.count do
		(
			local moveVec = [0,0,0]
			moveVec[axis] = targetPos - centers[i][axis]
			moveElementWS pool[i][1] pool[i][2] pool[i][3] moveVec
		)
	)
	fn alignPoolEvenly pool =
	(
		if pool.count < 2 then return false
		local centers = poolCentersWS pool
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to centers.count do
			for j = i + 1 to centers.count do
			(
				local d = distance centers[i] centers[j]
				if d > maxDist do ( maxDist = d; extremeIndices = #( i, j ) )
			)
		local oriented   = orientExtremeLine centers[extremeIndices[1]] centers[extremeIndices[2]]
		local startPoint = oriented[1]
		local endPoint   = oriented[2]
		local lineDir    = oriented[3]
		local spacing    = maxDist / ( pool.count - 1 )
		local sorted     = getSortedIndicesByProjection centers startPoint lineDir
		sorted           = maybeShuffleSlots sorted
		local targets    = #()
		for i = 1 to sorted.count do
		(
			local idx = sorted[i][1]
			append targets #( idx, startPoint + lineDir * ( spacing * ( i - 1 ) ) )
		)
		struct PoolElementMover
		(
			thePool,
			fn move idx vec =
			(
				-- alignCentersByMode hands back a WORLD-space delta (it only converts
				-- when coordSystem==2; we pass 1 here so vec stays world space).
				moveElementWS thePool[idx][1] thePool[idx][2] thePool[idx][3] vec
			)
		)
		local mover = PoolElementMover thePool: pool
		alignCentersByMode targets centers mover.move ddlDistributionMode.selection 1 ( matrix3 1 )
		return true
	)
	-- Count / Spacing variants for the pool. Cloning duplicates the base element
	-- WITHIN its own source object (cross-object detach is not attempted), then the
	-- whole resulting selection is redistributed evenly.
	fn poolRebuildObjElements obj mod =
	(
		-- After cloning we no longer know exact face ids; re-derive every element of obj.
		local visited = #{}
		local elems = #()
		local nf = if mod == undefined then ( polyop.getNumFaces obj )
			else ( polyop.getFaceSelection obj ).count
		if mod == undefined then
		(
			for f = 1 to polyop.getNumFaces obj do
			(
				if not visited[f] do
				(
					local el = polyop.getElementsUsingFace obj #{ f }
					append elems ( el as array )
					visited += el
				)
			)
		)
		return elems
	)
	fn alignPoolWithCount pool customCount =
	(
		if pool.count < 2 then return false
		local centers = poolCentersWS pool
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to centers.count do
			for j = i + 1 to centers.count do
			(
				local d = distance centers[i] centers[j]
				if d > maxDist do ( maxDist = d; extremeIndices = #( i, j ) )
			)
		if customCount <= pool.count then
		(
			-- No cloning needed (equal) or reduction is ambiguous across objects:
			-- just redistribute the current elements evenly.
			return alignPoolEvenly pool
		)
		-- INCREASE: clone the extreme[1] element inside its own object.
		local baseObj   = pool[extremeIndices[1]][1]
		local baseMod   = pool[extremeIndices[1]][2]
		local baseFaces = pool[extremeIndices[1]][3]
		local startPoint = centers[extremeIndices[1]]
		local endPoint   = centers[extremeIndices[2]]
		local lineDir    = normalize( endPoint - startPoint )
		local spacing    = maxDist / ( customCount - 1 )
		local countToAdd = customCount - pool.count
		if baseMod != undefined then
		(
			messageBox "Count cloning requires the base object to be an Editable Poly (collapse the Edit Poly modifier on the first/extreme element's object)." title:"Element Aligner"
			return false
		)
		cloneElementToCount baseObj baseFaces countToAdd startPoint lineDir spacing
		-- Rebuild a pool from every element of the affected object plus the untouched
		-- elements from the OTHER objects, then redistribute.
		local newPool = #()
		for e in pool do
			if e[1] != baseObj then append newPool e
		for el in ( poolRebuildObjElements baseObj undefined ) do
			append newPool #( baseObj, undefined, el )
		return alignPoolEvenly newPool
	)
	fn alignPoolWithSpacing pool desiredSpacing spacingRefMode =
	(
		if pool.count < 2 then return false
		local centers = for e in pool collect
		(
			local lc = if spacingRefMode == 2 then ( getElementBBoxCenter e[1] e[2] e[3] )
				else ( getElementCenter e[1] e[2] e[3] )
			lc * e[1].objecttransform
		)
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to centers.count do
			for j = i + 1 to centers.count do
			(
				local d = distance centers[i] centers[j]
				if d > maxDist do ( maxDist = d; extremeIndices = #( i, j ) )
			)
		local startPoint = centers[extremeIndices[1]]
		local endPoint   = centers[extremeIndices[2]]
		local lineDir    = normalize( endPoint - startPoint )
		local spacing    = desiredSpacing
		if spacingRefMode == 2 then
		(
			local b1 = getElementBBoxCenter pool[extremeIndices[1]][1] pool[extremeIndices[1]][2] pool[extremeIndices[1]][3]
			local b2 = getElementBBoxCenter pool[extremeIndices[2]][1] pool[extremeIndices[2]][2] pool[extremeIndices[2]][3]
			spacing += abs( dot ( ( b2 * pool[extremeIndices[2]][1].objecttransform ) - ( b1 * pool[extremeIndices[1]][1].objecttransform ) ) lineDir )
		)
		local count = floor ( 1 + ( maxDist / spacing ) )
		if count < 2 then
		(
			messageBox "Spacing too large to fit more than one element." title:"Element Aligner"
			return false
		)
		if count <= pool.count then
			return alignPoolEvenly pool
		return alignPoolWithCount pool count
	)
	-- Function to align models to a specific axis value
	fn alignModelsToAxis models axis alignMode coordSystem =
	(		
		local modelCenters = #()
		local targetPos = 0
		-- Get all model centers
		for obj in models do
		(			
			append modelCenters( getModelCenter obj ddlDistributionRef.selection )
		)
		-- Determine target position based on alignment mode
		case alignMode of
		(			
			1 : -- Average
			(				
				local sum = 0
				for center in modelCenters do
					sum += center[axis]
				targetPos = sum / modelCenters.count
			)
			2 : -- Minimum
			(				
				targetPos = 1e9
				for center in modelCenters do
					if center[axis] < targetPos then
					targetPos = center[axis]
			)
			3 : -- Maximum
			(				
				targetPos = -1e9
				for center in modelCenters do
					if center[axis] > targetPos then
					targetPos = center[axis]
			)
			4 : -- First Selected
			targetPos = modelCenters[1][axis]
			5 : -- Last Selected
			targetPos = modelCenters[modelCenters.count][axis]
		)
		-- Move models to target position
		for i = 1 to models.count do
		(			
			local obj = models[i]
			local center = modelCenters[i]
			local moveVec = [0, 0, 0]
			moveVec[axis] = targetPos - center[axis]
			-- Move the model
			moveModel obj moveVec
		)
	)
	-- Function to clone a model
	fn cloneModel obj cloneType = 
	(		
		local newObj
		case cloneType of
		(			
			1 : newObj = copy obj -- Copy
			2 : newObj = instance obj -- Instance
			3 : newObj = reference obj -- Reference
			default: newObj = copy obj
		)
		return newObj
	)
	-- Function to detach an element to a new object
	fn detachElement obj mod elemFaces = 
	(		
		local newObj
		if mod == undefined then
			-- Editable_Poly
		(			
			-- Create a BitArray for these faces
			local faceBitArray = #{}
			for f in elemFaces do
				faceBitArray[f] = true
			-- Select the faces
			polyop.setFaceSelection obj faceBitArray
			-- Detach to a new object
			newObj = polyop.detachFaces obj faceBitArray asNode: true delete: false
		)
		else
			-- Edit_Poly modifier
		(			
			-- Create a BitArray for these faces
			local faceBitArray = #{}
			for f in elemFaces do
				faceBitArray[f] = true
			-- Select these faces
			mod.SetSelection #Face faceBitArray
			-- Detach to a new object
			mod.detachToObject #Face "TempDetachedElement" delete: false
			-- Find the new object
			newObj = getNodeByName "TempDetachedElement"
		)
		return newObj
	)
	-- Function to align models evenly between extremes with custom count
	fn alignModelsEvenlyWithCount models coordSystem customCount cloneType = 
	(		
		coordSystem = 1
		if models.count < 2 then
			return false
		-- Get original centers
		local modelCenters = for obj in models collect
			getModelCenter obj ddlDistributionRef.selection
		-- Find extreme pair
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to modelCenters.count do
		(			
			for j = i + 1 to modelCenters.count do
			(				
				local d = distance modelCenters[i] modelCenters[j]
				if d > maxDist do
				(					
					maxDist = d
					extremeIndices = #( i, j )
				)
			)
		)
		local startPoint = modelCenters[extremeIndices[1]]
		local endPoint = modelCenters[extremeIndices[2]]
		local lineDir = normalize( endPoint - startPoint )
		local spacing = maxDist /( customCount - 1 )
		local resultModels = #()
		local used = #{}
		-- === CASE 1: REDUCE ===
		if customCount < models.count then
		(			
			-- Keep extremes
			append resultModels models[extremeIndices[1]]
			append resultModels models[extremeIndices[2]]
			used[extremeIndices[1]] = true
			used[extremeIndices[2]] = true
			-- Project and collect unused
			local projected = #()
			for i = 1 to models.count do
			(				
				if not used[i] do
				(					
					local projVal = dot( modelCenters[i] - startPoint ) lineDir
					append projected #( i, projVal )
				)
			)
			-- Sort by projection value
			qsort projected compareBySecond
			-- Pick intermediate models
			local step = projected.count as float /( customCount - 2 )
			for j = 1 to( customCount - 2 ) do
			(				
				local pickIndex = ( step * j ) as integer
				pickIndex = amax #( 1, amin #( projected.count, pickIndex ) )
				local idx = projected[pickIndex][1]
				append resultModels models[idx]
				used[idx] = true
			)
			-- Delete unused models
			for i = models.count to 1 by -1 do
			(				
				if not used[i] do
					delete models[i]
			)
		)
		-- === CASE 2: INCREASE ===
		else
			if customCount > models.count then
		(			
			-- === CASE 2: INCREASE COUNT ===
			for obj in models do
				append resultModels obj
			local baseModel = models[extremeIndices[1]]
			with undo "Clone Models" on 
			(				
				for i = 1 to( customCount - models.count ) do
				(					
					local newObj = cloneModel baseModel cloneType
					if isValidNode newObj do
						append resultModels newObj
				)
			)
			-- Ensure new objects are updated in scene
			for obj in resultModels do
				update obj
			-- Now safely select them
			select resultModels
		)
		else
		(			
			-- === CASE 3: EQUAL COUNT ===
			resultModels = models
		)
		-- Recompute centers
		local resultCenters = for obj in resultModels collect
			getModelCenter obj ddlDistributionRef.selection
		-- Recompute extremes
		maxDist = 0.0
		extremeIndices = #( 1, 2 )
		for i = 1 to resultCenters.count do
		(			
			for j = i + 1 to resultCenters.count do
			(				
				local d = distance resultCenters[i] resultCenters[j]
				if d > maxDist do
				(					
					maxDist = d
					extremeIndices = #( i, j )
				)
			)
		)
		startPoint = resultCenters[extremeIndices[1]]
		endPoint = resultCenters[extremeIndices[2]]
		lineDir = normalize( endPoint - startPoint )
		spacing = maxDist /( resultCenters.count - 1 )
		-- Sort indices by projection
		local sorted = #()
		for i = 1 to resultCenters.count do
		(			
			local projVal = dot( resultCenters[i] - startPoint ) lineDir
			append sorted #( i, projVal )
		)
		qsort sorted compareBySecond
		-- Build targets
		local targets = #()
		for i = 1 to sorted.count do
		(			
			local idx = sorted[i][1]
			local targetPos = startPoint + lineDir * ( spacing * ( i - 1 ) )
			append targets #( idx, targetPos )
		)
		-- Define move function
		-- Define a local struct to bind the models and expose a move function
		struct LocalModelMover
		
		(			
			models,
			fn move idx vec = 
			(				
				moveModel models[idx] vec
			)
		)
		-- Instantiate the mover
		local mover = LocalModelMover models: resultModels
		-- Perform alignment
		alignCentersByMode targets resultCenters mover.move ddlDistributionMode.selection coordSystem resultModels[1].transform
		return true
	)
	fn alignModelsEvenlyWithSpacing models coordSystem desiredSpacing spacingRefMode = 
	(		
		coordSystem = 1 -- Local space only for now
		if models.count < 2 then
			return false
		-- Collect model reference points
		local modelPoints = for obj in models collect
		(			
			case spacingRefMode of
			(				
				1 : getModelCenter obj 1 -- Center
				2 : obj.center -- Bounding Box center
				default: obj.center
			)
		)
		-- Find extremes
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to modelPoints.count do
			for j = i + 1 to modelPoints.count do
		(			
			local d = distance modelPoints[i] modelPoints[j]
			if d > maxDist do
			(				
				maxDist = d
				extremeIndices = #( i, j )
			)
		)
		local startPoint = modelPoints[extremeIndices[1]]
		local endPoint = modelPoints[extremeIndices[2]]
		local lineDir = normalize( endPoint - startPoint )
		-- Adjust spacing for bounding box size if needed
		local spacing = desiredSpacing
		if spacingRefMode == 2 then
		(			
			local bb1 = models[extremeIndices[1]].boundingBox
			local bb2 = models[extremeIndices[2]].boundingBox
			local min1 = bb1.min
			local max2 = bb2.max
			local sizeEstimate = abs( dot( max2 - min1 ) lineDir )
			spacing += sizeEstimate
		)
		-- Determine how many should fit
		local count = 1 +( maxDist / spacing )
		count = floor count
		if count < 2 then
		(			
			messageBox "Spacing too large to fit more than one object."
			return false
		)
		-- Store result models
		local resultModels = #()
		local used = #{}
		local currentCount = models.count
		-- === CASE 1: EQUAL ===
		if count == currentCount then
		(			
			resultModels = models
		)
		-- === CASE 2: REDUCE ===
		else
			if count < currentCount then
		(			
			local startPoint = modelPoints[extremeIndices[1]]
			local endPoint = modelPoints[extremeIndices[2]]
			local lineDir = normalize( endPoint - startPoint )
			append resultModels models[extremeIndices[1]]
			append resultModels models[extremeIndices[2]]
			used[extremeIndices[1]] = true
			used[extremeIndices[2]] = true
			-- Project and sort remaining
			local projected = #()
			for i = 1 to models.count do
			(				
				if not used[i] do
				(					
					local projVal = dot( modelPoints[i] - startPoint ) lineDir
					append projected #( i, projVal )
				)
			)
			qsort projected compareBySecond
			local step = projected.count as float /( count - 2 )
			for j = 1 to( count - 2 ) do
			(				
				local pickIndex = ( step * j ) as integer
				pickIndex = amax #( 1, amin #( projected.count, pickIndex ) )
				local idx = projected[pickIndex][1]
				append resultModels models[idx]
				used[idx] = true
			)
			-- Delete unused models
			for i = models.count to 1 by -1 do
			(				
				if not used[i] do
					delete models[i]
			)
		)
		-- === CASE 3: INCREASE ===
		else
			if count > currentCount then
		(			
			for obj in models do
				append resultModels obj
			local baseModel = models[extremeIndices[1]]
			local countToAdd = count - models.count
			with undo "Clone Models (Spacing)" on 
			(				
				for i = 1 to countToAdd do
				(					
					local newObj = cloneModel baseModel ddlCloneType.selection
					if isValidNode newObj do
						append resultModels newObj
				)
			)
		)
		-- Recompute centers
		local resultCenters = for obj in resultModels collect
			getModelCenter obj 1
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to resultCenters.count do
			for j = i + 1 to resultCenters.count do
		(			
			local d = distance resultCenters[i] resultCenters[j]
			if d > maxDist do
			(				
				maxDist = d
				extremeIndices = #( i, j )
			)
		)
		startPoint = resultCenters[extremeIndices[1]]
		endPoint = resultCenters[extremeIndices[2]]
		lineDir = normalize( endPoint - startPoint )
		spacing = maxDist /( resultModels.count - 1 )
		-- Sort and assign target positions
		local sorted = getSortedIndicesByProjection resultCenters startPoint lineDir
		local targets = #()
		for i = 1 to sorted.count do
		(			
			local idx = sorted[i][1]
			local targetPos = startPoint + lineDir * ( spacing * ( i - 1 ) )
			append targets #( idx, targetPos )
		)
		-- Align models
		struct LocalModelMover
		
		(			
			models,
			fn move idx vec = ( moveModel models[idx] vec )
		)
		local mover = LocalModelMover models: resultModels
		alignCentersByMode targets resultCenters mover.move ddlDistributionMode.selection coordSystem resultModels[1].transform
		return true
	)
	fn cloneElementToCount obj elemFaces countToAdd lineStart lineDir spacing = 
	(		
		local faceBits = #{}
		for f in elemFaces do
			faceBits[f] = true
		if classof obj != Editable_Poly do
			obj = convertToPoly obj
		-- lineDir/spacing arrive in WORLD space; polyop.moveVert works in object-local
		-- space, so convert the world step into a local-space direction once.
		local invTM = inverse obj.objecttransform
		local worldStep = lineDir * spacing
		local spacingVec = ( worldStep * invTM ) - ( [0,0,0] * invTM )
		with undo "Clone Elements" on
		(			
			for i = 1 to countToAdd do
			(				
				local faceCountBefore = polyop.getNumFaces obj
				-- ?? Duplicate within same object as new element
				polyop.detachFaces obj faceBits delete: false asNode: false
				local faceCountAfter = polyop.getNumFaces obj
				local newFaces = #{}
				for f = ( faceCountBefore + 1 ) to faceCountAfter do
					newFaces[f] = true
				local vertsToMove = #{}
				for f in newFaces do
				(					
					local faceVerts = polyop.getFaceVerts obj f
					for v in faceVerts do
						vertsToMove[v] = true
				)
				local totalMove = spacingVec * i
				polyop.moveVert obj vertsToMove totalMove
			)
		)
		update obj
		return true
	)
	-- Function to align elements evenly between extremes with custom count
	fn alignElementsEvenlyWithCount obj mod selectedElems coordSystem customCount = 
	(		
		coordSystem = 1
		if selectedElems.count < 2 then
			return false
		local resultElems = #()
		-- === CASE 1: REDUCE ELEMENT COUNT ===
		if customCount < selectedElems.count then
		(			
			-- Compute initial centers
			local elemCenters = for elemFaces in selectedElems collect
			(				
				case ddlDistributionRef.selection of
				(					
					1 : getElementCenter obj mod elemFaces
					2 : getElementBBoxCenter obj mod elemFaces
					default:[0, 0, 0]
				)
			)
			-- Convert to world space if needed
			if coordSystem == 2 and obj.transform !=( matrix3 1 ) then
			(				
				for i = 1 to elemCenters.count do
				(					
					elemCenters[i] = elemCenters[i] * obj.transform
				)
			)
			-- Find extreme elements
			local maxDist = 0.0
			local extremeIndices = #( 1, 2 )
			for i = 1 to elemCenters.count do
			(				
				for j = i + 1 to elemCenters.count do
				(					
					local d = distance elemCenters[i] elemCenters[j]
					if d > maxDist do
					(						
						maxDist = d
						extremeIndices = #( i, j )
					)
				)
			)
			append resultElems selectedElems[extremeIndices[1]]
			append resultElems selectedElems[extremeIndices[2]]
			local startPoint = elemCenters[extremeIndices[1]]
			local lineDir = normalize( elemCenters[extremeIndices[2]] - startPoint )
			-- Project and collect intermediates
			local projected = #()
			for i = 1 to selectedElems.count do
			(				
				if( i != extremeIndices[1] and i != extremeIndices[2] ) do
				(					
					local projVal = dot( elemCenters[i] - startPoint ) lineDir
					append projected #( i, projVal )
				)
			)
			qsort projected compareBySecond
			local step = projected.count as float /( customCount - 2 )
			for j = 1 to( customCount - 2 ) do
			(				
				local pickIndex = ( step * j ) as integer
				pickIndex = amax #( 1, amin #( projected.count, pickIndex ) )
				append resultElems selectedElems[projected[pickIndex][1]]
			)
			-- Delete unused faces
			local toKeep = #{}
			for elem in resultElems do
			(				
				for f in elem do
					toKeep[f] = true
			)
			local allFaces = #{ 1..polyop.getNumFaces obj }
			local toDelete = allFaces - toKeep
			if toDelete.numberset > 0 do
			(				
				polyop.deleteFaces obj toDelete
				update obj
			)
		)
		-- === CASE 2: INCREASE ELEMENT COUNT ===
		else
			if customCount > selectedElems.count then
		(			
			for elem in selectedElems do
				append resultElems elem
			-- Compute initial centers
			local elemCenters = for elemFaces in selectedElems collect
			(				
				case ddlDistributionRef.selection of
				(					
					1 : getElementCenter obj mod elemFaces
					2 : getElementBBoxCenter obj mod elemFaces
					default:[0, 0, 0]
				)
			)
			if coordSystem == 2 and obj.transform !=( matrix3 1 ) then
			(				
				for i = 1 to elemCenters.count do
				(					
					elemCenters[i] = elemCenters[i] * obj.transform
				)
			)
			local maxDist = 0.0
			local extremeIndices = #( 1, 2 )
			for i = 1 to elemCenters.count do
			(				
				for j = i + 1 to elemCenters.count do
				(					
					local d = distance elemCenters[i] elemCenters[j]
					if d > maxDist do
					(						
						maxDist = d
						extremeIndices = #( i, j )
					)
				)
			)
			local baseFaces = selectedElems[extremeIndices[1]]
			local startPoint = elemCenters[extremeIndices[1]]
			local endPoint = elemCenters[extremeIndices[2]]
			local lineDir = normalize( endPoint - startPoint )
			local spacing = maxDist /( customCount - 1 )
			local countToAdd = customCount - selectedElems.count
			cloneElementToCount obj baseFaces countToAdd startPoint lineDir spacing
		)
		-- === CASE 3: EQUAL COUNT ===
		else
		(			
			resultElems = selectedElems
		)
		-- === Rebuild elements ===
		local visited = #{}
		resultElems = #()
		for f = 1 to polyop.getNumFaces obj do
		(			
			if not visited[f] do
			(				
				local elem = polyop.getElementsUsingFace obj #{ f }
				append resultElems( elem as array )
				visited += elem
			)
		)
		-- === Compute element centers ===
		local resultCenters = for elemFaces in resultElems collect
		(			
			case ddlDistributionRef.selection of
			(				
				1 : getElementCenter obj mod elemFaces
				2 : getElementBBoxCenter obj mod elemFaces
				default:[0, 0, 0]
			)
		)
		if coordSystem == 2 and obj.transform !=( matrix3 1 ) then
		(			
			for i = 1 to resultCenters.count do
			(				
				resultCenters[i] = resultCenters[i] * obj.transform
			)
		)
		-- === Recompute extremes ===
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to resultCenters.count do
		(			
			for j = i + 1 to resultCenters.count do
			(				
				local d = distance resultCenters[i] resultCenters[j]
				if d > maxDist do
				(					
					maxDist = d
					extremeIndices = #( i, j )
				)
			)
		)
		local startPoint = resultCenters[extremeIndices[1]]
		local endPoint = resultCenters[extremeIndices[2]]
		local lineDir = normalize( endPoint - startPoint )
		local spacing = maxDist /( resultCenters.count - 1 )
		-- Sort and build targets
		local sorted = #()
		for i = 1 to resultCenters.count do
		(			
			local projVal = dot( resultCenters[i] - startPoint ) lineDir
			append sorted #( i, projVal )
		)
		qsort sorted compareBySecond
		local targets = #()
		for i = 1 to sorted.count do
		(			
			local idx = sorted[i][1]
			local targetPos = startPoint + lineDir * ( spacing * ( i - 1 ) )
			append targets #( idx, targetPos )
		)
		-- Define a local struct to wrap the move function with context
		struct LocalElementMover
		
		(			
			obj,
			mod,
			resultElems,
			fn move idx vec = 
			(				
				moveElement obj mod resultElems[idx] vec
			)
		)
		-- Create the mover instance
		local mover = LocalElementMover obj: obj mod: mod resultElems: resultElems
		-- Align using the bound move method
		alignCentersByMode targets resultCenters mover.move ddlDistributionMode.selection coordSystem obj.transform
		return true
	)
	fn alignElementsEvenlyWithSpacing obj mod selectedElems coordSystem desiredSpacing spacingRefMode = 
	(		
		coordSystem = 1 -- Use local space
		if selectedElems.count < 2 then
			return false
		local centers = for elem in selectedElems collect
		(			
			case spacingRefMode of
			(				
				1 : getElementCenter obj mod elem
				2 : getElementBBoxCenter obj mod elem
				default:[0, 0, 0]
			)
		)
		-- Find extremes
		local maxDist = 0.0
		local extremeIndices = #( 1, 2 )
		for i = 1 to centers.count do
			for j = i + 1 to centers.count do
		(			
			local d = distance centers[i] centers[j]
			if d > maxDist do
			(				
				maxDist = d
				extremeIndices = #( i, j )
			)
		)
		local startPoint = centers[extremeIndices[1]]
		local endPoint = centers[extremeIndices[2]]
		local lineDir = normalize( endPoint - startPoint )
		local spacing = desiredSpacing
		if spacingRefMode == 2 then
		(			
			local bb1 = getElementBBoxCenter obj mod selectedElems[extremeIndices[1]]
			local bb2 = getElementBBoxCenter obj mod selectedElems[extremeIndices[2]]
			local estimatedWidth = abs( dot( bb2 - bb1 ) lineDir )
			spacing += estimatedWidth
		)
		local count = 1 +( maxDist / spacing )
		count = floor count
		if count < 2 then
		(			
			messageBox "Spacing too large to fit more than one element."
			return false
		)
		local currentCount = selectedElems.count
		local resultElems = #()
		if count == currentCount then
		(			
			resultElems = selectedElems
		)
		else
			if count < currentCount then
		(			
			-- Reduce: keep extremes and best intermediates
			local startPoint = centers[extremeIndices[1]]
			local lineDir = normalize( centers[extremeIndices[2]] - startPoint )
			append resultElems selectedElems[extremeIndices[1]]
			append resultElems selectedElems[extremeIndices[2]]
			local projected = #()
			for i = 1 to selectedElems.count do
			(				
				if( i != extremeIndices[1] and i != extremeIndices[2] ) do
				(					
					local projVal = dot( centers[i] - startPoint ) lineDir
					append projected #( i, projVal )
				)
			)
			qsort projected compareBySecond
			local step = projected.count as float /( count - 2 )
			for j = 1 to( count - 2 ) do
			(				
				local pickIndex = ( step * j ) as integer
				pickIndex = amax #( 1, amin #( projected.count, pickIndex ) )
				append resultElems selectedElems[projected[pickIndex][1]]
			)
			-- Delete all unselected faces
			local toKeep = #{}
			for elem in resultElems do
				for f in elem do
				toKeep[f] = true
			local allFaces = #{ 1..polyop.getNumFaces obj }
			local toDelete = allFaces - toKeep
			if toDelete.numberset > 0 do
				polyop.deleteFaces obj toDelete
			update obj
		)
		else
			if count > currentCount then
		(			
			-- Add: clone base element
			resultElems = selectedElems
			local baseFaces = selectedElems[extremeIndices[1]]
			local startPoint = getElementCenter obj mod baseFaces
			local endPoint = getElementCenter obj mod selectedElems[extremeIndices[2]]
			local lineDir = normalize( endPoint - startPoint )
			local spacingVec = lineDir * spacing
			local countToAdd = count - currentCount
			cloneElementToCount obj baseFaces countToAdd startPoint lineDir spacing
		)
		-- Rebuild elements
		local visited = #{}
		resultElems = #()
		for f = 1 to polyop.getNumFaces obj do
		(			
			if not visited[f] do
			(				
				local elem = polyop.getElementsUsingFace obj #{ f }
				append resultElems( elem as array )
				visited += elem
			)
		)
		-- Align all resulting elements evenly
		alignElementsEvenly obj mod resultElems coordSystem
		return true
	)
	-- Function to align models evenly between extremes
	fn alignModelsEvenly models coordSystem = 
	(		
		coordSystem = 1
		if models.count < 2 then
			return false
		local modelCenters = for obj in models collect
			getModelCenter obj ddlDistributionRef.selection
		-- Find extreme pair
		local maxDist = 0
		local extremeIndices = #( 1, 2 )
		for i = 1 to modelCenters.count do
			for j = i + 1 to modelCenters.count do
		(			
			local d = distance modelCenters[i] modelCenters[j]
			if d > maxDist do
			(				
				maxDist = d
				extremeIndices = #( i, j )
			)
		)
		local oriented = orientExtremeLine modelCenters[extremeIndices[1]] modelCenters[extremeIndices[2]]
		local startPoint = oriented[1]
		local endPoint = oriented[2]
		local lineDir = oriented[3]
		local spacing = maxDist /( models.count - 1 )
		-- Sorted indices by projection
		local sorted = getSortedIndicesByProjection modelCenters startPoint lineDir
		sorted = maybeShuffleSlots sorted
		-- Generate targets
		local targets = for i = 1 to sorted.count collect
			#( sorted[i][1], startPoint + lineDir * ( spacing * ( i - 1 ) ) )
		-- Call unified alignment
		-- Define a local struct to wrap model move logic
		struct LocalModelMover
		
		(			
			models,
			fn move idx vec = 
			(				
				moveModel models[idx] vec
			)
		)
		-- Instantiate mover
		local mover = LocalModelMover models: models
		-- Call unified alignment using mover.move
		alignCentersByMode targets modelCenters mover.move ddlDistributionMode.selection coordSystem models[1].transform
		return true
	)
	-- Function to update UI based on current mode
	fn updateUI = 
	(		
		local mode = checkMode()
		if mode == #model then
		(			
			-- Enable dropdown for models
			ddlDistributionRef.enabled = true
			-- Update labels for model mode
			if ddlDistributionRef.items[1] != "Centers" then
				ddlDistributionRef.items = #( "Centers", "Bounding Box Centers", "Pivot Points" )
			-- Make sure all options are available
			isModelMode = true
		)
		else
			if mode != undefined then
		(			
			-- Enable dropdown for elements
			ddlDistributionRef.enabled = true
			-- Update labels for element mode
			if ddlDistributionRef.items[1] != "Element Centers" then
				ddlDistributionRef.items = #( "Element Centers", "Bounding Box Centers", "Pivot Points" )
			-- If pivot points was selected, change to element centers
			if ddlDistributionRef.selection == 3 then
				ddlDistributionRef.selection = 1
			isModelMode = false
		)
		else
		(			
			-- No valid selection
			ddlDistributionRef.enabled = false
		)
	)
	-- Event handlers
	on btnAlignX pressed do
	(		
		local mode = checkMode()
		if mode == #model then
		(			
			local models = getModelsInfo()
			if models != undefined and models[1].count > 0 then
			(				
				undo "Align Models to X" on 
				(					
					alignModelsToAxis models[1] 1 ddlAlignMode.selection rbCoordSystem.state
				)
			)
			else
			(				
				messageBox "No models selected." title: "Error"
			)
		)
		else
			if mode != undefined and classof mode == Array and mode[1] == #element then
		(
			local pool = mode[2]
			if pool.count > 0 then
			(
				undo "Align Elements to X" on
				(
					alignPoolToAxis pool 1 ddlAlignMode.selection
				)
			)
			else
			(
				messageBox "No elements selected in Edit Poly mode." title: "Error"
			)
		)
		else
		(			
			messageBox "No valid selection. Select either elements in Edit Poly mode or multiple 3D models." title: "Error"
		)
	)
	on btnAlignY pressed do
	(		
		local mode = checkMode()
		if mode == #model then
		(			
			local models = getModelsInfo()
			if models != undefined and models[1].count > 0 then
			(				
				undo "Align Models to Y" on 
				(					
					alignModelsToAxis models[1] 2 ddlAlignMode.selection rbCoordSystem.state
				)
			)
			else
			(				
				messageBox "No models selected." title: "Error"
			)
		)
		else
			if mode != undefined and classof mode == Array and mode[1] == #element then
		(
			local pool = mode[2]
			if pool.count > 0 then
			(
				undo "Align Elements to Y" on
				(
					alignPoolToAxis pool 2 ddlAlignMode.selection
				)
			)
			else
			(
				messageBox "No elements selected in Edit Poly mode." title: "Error"
			)
		)
		else
		(			
			messageBox "No valid selection. Select either elements in Edit Poly mode or multiple 3D models." title: "Error"
		)
	)
	on btnAlignZ pressed do
	(		
		local mode = checkMode()
		if mode == #model then
		(			
			local models = getModelsInfo()
			if models != undefined and models[1].count > 0 then
			(				
				undo "Align Models to Z" on 
				(					
					alignModelsToAxis models[1] 3 ddlAlignMode.selection rbCoordSystem.state
				)
			)
			else
			(				
				messageBox "No models selected." title: "Error"
			)
		)
		else
			if mode != undefined and classof mode == Array and mode[1] == #element then
		(
			local pool = mode[2]
			if pool.count > 0 then
			(
				undo "Align Elements to Z" on
				(
					alignPoolToAxis pool 3 ddlAlignMode.selection
				)
			)
			else
			(
				messageBox "No elements selected in Edit Poly mode." title: "Error"
			)
		)
		else
		(			
			messageBox "No valid selection. Select either elements in Edit Poly mode or multiple 3D models." title: "Error"
		)
	)
	-- Update mode info when selection changes
	fn updateModeInfo mode = 
	(		
		case mode of
		(			
			1 : lblModeInfo.text = "Maintains the general shape of your arrangement\nwhile distributing elements evenly between extremes."
			2 : lblModeInfo.text = "Places all elements directly on a straight line\nbetween the two furthest elements."
			3 : lblModeInfo.text = "Aligns elements along the dominant axis (X, Y, or Z)\nwhile preserving positions on other axes."
			default: lblModeInfo.text = ""
		)
	)
	on ddlDistributionMode selected i do
	(		
		updateModeInfo i
	)
	on btnAlignEvenly pressed do
	(
		local mode = checkMode()
		if mode == #model then
		(
			local models = getModelsInfo()
			if models != undefined and models[1].count > 1 then
			(
				undo "Align Models Evenly" on
				(
					case rbCustomMode.state of
					(
						1 : alignModelsEvenly models[1] rbCoordSystem.state
						2 : alignModelsEvenlyWithCount models[1] rbCoordSystem.state spnElementCount.value ddlCloneType.selection
						3 : alignModelsEvenlyWithSpacing models[1] rbCoordSystem.state spnSpacing.value ddlSpacingRef.selection
					)
				)
			)
			else
			(				
				messageBox "You need at least 2 models selected." title: "Error"
			)
		)
		else
			if mode != undefined and classof mode == Array and mode[1] == #element then
		(
			local pool = mode[2]
			if pool.count > 1 then
			(
				undo "Align Elements Evenly" on
				(
					case rbCustomMode.state of
					(
						1 : alignPoolEvenly pool
						2 : alignPoolWithCount pool spnElementCount.value
						3 : alignPoolWithSpacing pool spnSpacing.value ddlSpacingRef.selection
					)
				)
			)
			else
			(
				messageBox "You need at least 2 elements selected in Edit Poly mode." title: "Error"
			)
		)
		else
		(			
			messageBox "No valid selection. Select either elements in Edit Poly mode or multiple 3D models." title: "Error"
		)
	)
	on ddlDistributionRef selected i do
	(		
		-- Check current mode
		checkMode()
		-- If in element mode and pivot points selected, switch back to element centers
		if not isModelMode and i == 3 then
		(			
			ddlDistributionRef.selection = 1
			messageBox "Pivot Points option is only available for model alignment." title: "Information"
		)
	)
	on rbCustomMode changed state do
	(		
		spnElementCount.enabled = ( state == 2 )
		spnSpacing.enabled = ( state == 3 )
		ddlSpacingRef.enabled = ( state == 3 )
		ddlCloneType.enabled = ( state == 2 and isModelMode )
	)
	-- Initialize UI and mode info text on load
	on elementAlignmentTool open do
	(		
		updateModeInfo ddlDistributionMode.selection
		updateUI()
		-- Initialize radio-based spacing/count UI
		rbCustomMode.state = 1
		spnElementCount.enabled = true
		spnSpacing.enabled = false
		ddlSpacingRef.enabled = false
		ddlCloneType.enabled = isModelMode
	)
)
-- Create a macro script that can be assigned to a button or shortcut
macroScript ElementAlignmentTool
category: "Nimikko"
toolTip: "Element Aligner"
buttonText: "Element Aligner"

(	
	on execute do
	(		
		createDialog ElementAlignmentTool
	)
)
-- About rollout
rollout AlignToolsAbout "About"

(	
	label lab1 "Element & Model Aligner" toolTip: "Precision alignment utility for 3ds Max"
	label lab2 "by asutekku 2026 for Nimikko" toolTip: "Visit github.com/asutekku/max-scripts for more tools"
	button btnHelp "Help" width: 80 height: 25 toolTip: "Open readme and documentation"
	on btnHelp pressed do
	(		
		-- You could implement help functionality here, such as:
		-- Opening a webpage, showing a help dialog, etc.
		-- For now, just show a messagebox
		messageBox "Visit the GitHub repository for full documentation and examples.\n\nQuick Guide:\n- Select elements in Editable Poly mode OR select multiple 3D models\n- Use the appropriate alignment tools\n- Enable 'Custom Element Count' to specify the exact number of elements\n- Use the space toggle for local/world space operations" title: "Element & Model Aligner Help" beep: false
	)
)
-- Create floater and add rollouts
ElementAlignerFloater = newRolloutFloater "Element & Model Aligner" 320 630
addRollout ElementAlignmentTool ElementAlignerFloater
addRollout AlignToolsAbout ElementAlignerFloater

