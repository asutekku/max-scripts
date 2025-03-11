-- Align Tools for 3ds Max
-- This script provides alignment tools for vertices, edges and faces
-- Created: March 2025
-- File: alignTools.ms

rollout AlignToolsRollout "Align Tools" width:250 height:420
(
    group "Vertex: Align selection to:"
    (
        button btnVertexAlignX "X" width:60 height:30 across:3
        button btnVertexAlignY "Y" width:60 height:30
        button btnVertexAlignZ "Z" width:60 height:30
    )
    
    group "Vertex: Snap to grid"
    (
        spinner spnGridSize "Grid Size:" range:[0.1, 1000, 10] width:120 height:16 across:2
        dropdownList ddlGridAxes "Snap:" items:#("X", "Y", "Z", "XY", "XZ", "YZ", "XYZ") selection:7 width:120
        button btnSnapToGrid "Snap" width:60 height:30 align:#right
    )
    
    group "Edge: Align selection to:"
    (
        button btnEdgeAlignX "X" width:60 height:30 across:3
        button btnEdgeAlignY "Y" width:60 height:30
        button btnEdgeAlignZ "Z" width:60 height:30
    )
    
    group "Face: Align selection to:"
    (
        button btnFaceAlignX "X" width:60 height:30 across:3
        button btnFaceAlignY "Y" width:60 height:30
        button btnFaceAlignZ "Z" width:60 height:30
    )
    
    group "Global Settings"
    (
        radioButtons rdoGlobalSpace "Space:" labels:#("Local", "World") default:1
    )
    
    label lblStatus "" width:240 height:30
    
    -- Global functions to avoid scoping issues with anonymous blocks
    
    -- Vertex alignment global function
    global alignVerticesToAxisFn
    fn alignVerticesToAxisFn currentMod selectedVerts avgPos axisNum useWorldSpace =
    (
        -- Get current selected node
        local theNode = $
        
        -- For each selected vertex
        for v in selectedVerts do
        (
            if useWorldSpace and theNode != undefined then
            (
                -- WORLD SPACE APPROACH
                -- Get vertex in object space
                local objectPos = polyOp.getVert currentMod v
                
                -- Convert to world space using object's transform
                local worldPos = (objectPos * theNode.transform)
                
                -- Create new position by setting specific axis to average in world space
                local newWorldPos = worldPos
                
                case axisNum of
                (
                    1: newWorldPos.x = avgPos.x -- Align to X
                    2: newWorldPos.y = avgPos.y -- Align to Y
                    3: newWorldPos.z = avgPos.z -- Align to Z
                )
                
                -- Convert back to object space
                local newObjectPos = newWorldPos * (inverse theNode.transform)
                
                -- Update vertex position
                polyOp.setVert currentMod v newObjectPos
            )
            else
            (
                -- LOCAL SPACE APPROACH
                -- Get current vertex position
                local pos = polyOp.getVert currentMod v
                
                -- Create new position by setting specific axis to average
                local newPos = pos
                
                case axisNum of
                (
                    1: newPos.x = avgPos.x -- Align to X
                    2: newPos.y = avgPos.y -- Align to Y
                    3: newPos.z = avgPos.z -- Align to Z
                )
                
                -- Update vertex position
                polyOp.setVert currentMod v newPos
            )
        )
        
        -- Update the mesh
        polyOp.setVertSelection currentMod selectedVerts
        
        -- Force viewport update
        redrawViews()
        completeRedraw()
    )
    
    -- Vertex snapping global function 
    global snapVerticesToGridFn
    fn snapVerticesToGridFn currentMod selectedVerts gridSize axesSelection useWorldSpace =
    (
        -- Get current selected node
        local theNode = $
        
        -- For each selected vertex
        for v in selectedVerts do
        (
            local oldPos, newPos
            
            if useWorldSpace and theNode != undefined then
            (
                -- WORLD SPACE APPROACH
                -- Get vertex in object space
                local objectPos = polyOp.getVert currentMod v
                
                -- Convert to world space using object's transform
                local worldPos = (objectPos * theNode.transform)
                
                -- Get world coordinates
                local worldX = worldPos.x
                local worldY = worldPos.y
                local worldZ = worldPos.z
                
                -- Snap in world space
                local newWorldX = worldX
                local newWorldY = worldY
                local newWorldZ = worldZ
                
                -- Apply grid snapping
                case axesSelection of
                (
                    1: newWorldX = floor((worldX / gridSize) + 0.5) * gridSize  -- X only
                    2: newWorldY = floor((worldY / gridSize) + 0.5) * gridSize  -- Y only
                    3: newWorldZ = floor((worldZ / gridSize) + 0.5) * gridSize  -- Z only
                    4: ( -- XY
                        newWorldX = floor((worldX / gridSize) + 0.5) * gridSize
                        newWorldY = floor((worldY / gridSize) + 0.5) * gridSize
                    )
                    5: ( -- XZ
                        newWorldX = floor((worldX / gridSize) + 0.5) * gridSize
                        newWorldZ = floor((worldZ / gridSize) + 0.5) * gridSize
                    )
                    6: ( -- YZ
                        newWorldY = floor((worldY / gridSize) + 0.5) * gridSize
                        newWorldZ = floor((worldZ / gridSize) + 0.5) * gridSize
                    )
                    7: ( -- XYZ
                        newWorldX = floor((worldX / gridSize) + 0.5) * gridSize
                        newWorldY = floor((worldY / gridSize) + 0.5) * gridSize
                        newWorldZ = floor((worldZ / gridSize) + 0.5) * gridSize
                    )
                )
                
                -- Create new world position
                local newWorldPos = point3 newWorldX newWorldY newWorldZ
                
                -- Convert back to object space
                local newObjectPos = newWorldPos * (inverse theNode.transform)
                
                -- Set the vertex back in object space
                polyOp.setVert currentMod v newObjectPos
                
                -- Debug logs
                format "==== WORLD SPACE SNAPPING ====\n"
                format "Vertex: %\n" v
                format "Object pos: [%, %, %]\n" objectPos.x objectPos.y objectPos.z
                format "World pos: [%, %, %]\n" worldPos.x worldPos.y worldPos.z
                format "Snapped world: [%, %, %]\n" newWorldX newWorldY newWorldZ
                format "New object pos: [%, %, %]\n\n" newObjectPos.x newObjectPos.y newObjectPos.z
            )
            else
            (
                -- LOCAL SPACE APPROACH
                -- Get vertex position in local space
                local pos = polyOp.getVert currentMod v
                
                -- Get coordinates
                local x = pos.x
                local y = pos.y
                local z = pos.z
                
                -- Apply grid snapping in local space
                local newX = x
                local newY = y
                local newZ = z
                
                case axesSelection of
                (
                    1: newX = floor((x / gridSize) + 0.5) * gridSize  -- X only
                    2: newY = floor((y / gridSize) + 0.5) * gridSize  -- Y only
                    3: newZ = floor((z / gridSize) + 0.5) * gridSize  -- Z only
                    4: ( -- XY
                        newX = floor((x / gridSize) + 0.5) * gridSize
                        newY = floor((y / gridSize) + 0.5) * gridSize
                    )
                    5: ( -- XZ
                        newX = floor((x / gridSize) + 0.5) * gridSize
                        newZ = floor((z / gridSize) + 0.5) * gridSize
                    )
                    6: ( -- YZ
                        newY = floor((y / gridSize) + 0.5) * gridSize
                        newZ = floor((z / gridSize) + 0.5) * gridSize
                    )
                    7: ( -- XYZ
                        newX = floor((x / gridSize) + 0.5) * gridSize
                        newY = floor((y / gridSize) + 0.5) * gridSize
                        newZ = floor((z / gridSize) + 0.5) * gridSize
                    )
                )
                
                -- Create new local position
                local newPos = point3 newX newY newZ
                
                -- Set the vertex
                polyOp.setVert currentMod v newPos
                
                -- Debug logs
                format "==== LOCAL SPACE SNAPPING ====\n"
                format "Vertex: %\n" v
                format "Local pos: [%, %, %]\n" x y z
                format "New local pos: [%, %, %]\n\n" newX newY newZ
            )
        )
        
        -- Update the mesh
        polyOp.setVertSelection currentMod selectedVerts
        
        -- Force viewport update
        redrawViews()
        completeRedraw()
    )
    
    -- Function to group connected edges
    fn groupConnectedEdges currentMod selectedEdges =
    (
        local edgeGroups = #()
        local processedEdges = #{}
        
        for e in selectedEdges where not (processedEdges[e]) do
        (
            local currentGroup = #(e)
            processedEdges[e] = true
            
            local edgesToCheck = #(e)
            
            while edgesToCheck.count > 0 do
            (
                local currentEdge = edgesToCheck[1]
                deleteItem edgesToCheck 1
                
                -- Get vertices for current edge
                local verts = polyOp.getEdgeVerts currentMod currentEdge
                
                -- Find other selected edges that share these vertices
                for testEdge in selectedEdges where not (processedEdges[testEdge]) do
                (
                    local testVerts = polyOp.getEdgeVerts currentMod testEdge
                    
                    -- Check if edges share a vertex
                    if (testVerts[1] == verts[1] or testVerts[1] == verts[2] or 
                        testVerts[2] == verts[1] or testVerts[2] == verts[2]) then
                    (
                        append currentGroup testEdge
                        append edgesToCheck testEdge
                        processedEdges[testEdge] = true
                    )
                )
            )
            
            append edgeGroups currentGroup
        )
        
        return edgeGroups
    )
    
    -- Function to group connected faces
    fn groupConnectedFaces currentMod selectedFaces =
    (
        local faceGroups = #()
        local processedFaces = #{}
        
        for f in selectedFaces where not (processedFaces[f]) do
        (
            local currentGroup = #(f)
            processedFaces[f] = true
            
            local facesToCheck = #(f)
            
            while facesToCheck.count > 0 do
            (
                local currentFace = facesToCheck[1]
                deleteItem facesToCheck 1
                
                -- Get edges for current face
                local faceEdges = polyOp.getFaceEdges currentMod currentFace
                
                -- Find other selected faces that share these edges
                for testFace in selectedFaces where not (processedFaces[testFace]) do
                (
                    local testEdges = polyOp.getFaceEdges currentMod testFace
                    local shareEdge = false
                    
                    -- Check if faces share an edge
                    for e1 in faceEdges do
                    (
                        for e2 in testEdges where e1 == e2 do
                        (
                            shareEdge = true
                            exit
                        )
                        if shareEdge then exit
                    )
                    
                    if shareEdge then
                    (
                        append currentGroup testFace
                        append facesToCheck testFace
                        processedFaces[testFace] = true
                    )
                )
            )
            
            append faceGroups currentGroup
        )
        
        return faceGroups
    )
    
    -- Edge alignment global function
    global alignEdgesToAxisFn
    fn alignEdgesToAxisFn currentMod selectedEdges axisNum useWorldSpace =
    (
        -- Get current selected node
        local theNode = $
        
        -- Group connected edges
        local edgeGroups = groupConnectedEdges currentMod selectedEdges
        
        -- Process each group of edges
        for edgeGroup in edgeGroups do
        (
            if edgeGroup.count == 1 then
            (
                -- Single edge case - use existing method
                local e = edgeGroup[1]
                
                -- Get the edge vertices
                local verts = polyOp.getEdgeVerts currentMod e
                
                -- Get vertex positions (in appropriate space)
                local pos1, pos2
                
                if useWorldSpace and theNode != undefined then
                (
                    -- World space positions
                    pos1 = (polyOp.getVert currentMod verts[1]) * theNode.transform
                    pos2 = (polyOp.getVert currentMod verts[2]) * theNode.transform
                )
                else
                (
                    -- Local space positions
                    pos1 = polyOp.getVert currentMod verts[1]
                    pos2 = polyOp.getVert currentMod verts[2]
                )
                
                -- Calculate edge center point (we'll keep this fixed)
                local centerPoint = (pos1 + pos2) / 2.0
                
                -- Calculate current edge vector and length
                local edgeVec = pos2 - pos1
                local edgeLength = length edgeVec
                
                -- Determine vertex ordering based on the target axis
                local v1IsFirst = case axisNum of
                (
                    1: (pos1.x <= pos2.x) -- For X-axis, compare X coordinates
                    2: (pos1.y <= pos2.y) -- For Y-axis, compare Y coordinates
                    3: (pos1.z <= pos2.z) -- For Z-axis, compare Z coordinates
                    default: true
                )
                
                -- Create new vector aligned to desired axis, maintaining length
                local newVec = [0, 0, 0]
                
                case axisNum of
                (
                    1: newVec = [edgeLength, 0, 0] -- X axis
                    2: newVec = [0, edgeLength, 0] -- Y axis
                    3: newVec = [0, 0, edgeLength] -- Z axis
                )
                
                -- Calculate new vertex positions preserving original order
                local newPos1, newPos2
                
                if v1IsFirst then
                (
                    newPos1 = centerPoint - (newVec / 2.0)
                    newPos2 = centerPoint + (newVec / 2.0)
                )
                else
                (
                    newPos2 = centerPoint - (newVec / 2.0)
                    newPos1 = centerPoint + (newVec / 2.0)
                )
                
                -- Convert back to local space if needed and update vertex positions
                if useWorldSpace and theNode != undefined then
                (
                    newPos1 = newPos1 * (inverse theNode.transform)
                    newPos2 = newPos2 * (inverse theNode.transform)
                )
                
                -- Update vertex positions
                polyOp.setVert currentMod verts[1] newPos1
                polyOp.setVert currentMod verts[2] newPos2
            )
            else
            (
                -- Multiple connected edges case
                local allVerts = #()
                local uniqueVerts = #{}
                
                -- Collect all unique vertices from all edges in the group
                for e in edgeGroup do
                (
                    local verts = polyOp.getEdgeVerts currentMod e
                    if not uniqueVerts[verts[1]] do
                    (
                        append allVerts verts[1]
                        uniqueVerts[verts[1]] = true
                    )
                    if not uniqueVerts[verts[2]] do
                    (
                        append allVerts verts[2]
                        uniqueVerts[verts[2]] = true
                    )
                )
                
                -- Calculate center point and bounding box of all vertices in appropriate space
                local centerPoint = [0,0,0]
                local minPoint = [1e9, 1e9, 1e9]
                local maxPoint = [-1e9, -1e9, -1e9]
                
                for v in allVerts do
                (
                    local pos
                    
                    if useWorldSpace and theNode != undefined then
                        pos = (polyOp.getVert currentMod v) * theNode.transform
                    else
                        pos = polyOp.getVert currentMod v
                    
                    centerPoint += pos
                    
                    -- Use if statements instead of max/min functions
                    if pos.x < minPoint.x then minPoint.x = pos.x
                    if pos.y < minPoint.y then minPoint.y = pos.y
                    if pos.z < minPoint.z then minPoint.z = pos.z
                    
                    if pos.x > maxPoint.x then maxPoint.x = pos.x
                    if pos.y > maxPoint.y then maxPoint.y = pos.y
                    if pos.z > maxPoint.z then maxPoint.z = pos.z
                )
                
                centerPoint /= allVerts.count
                
                -- Calculate axis-aligned vector
                local axisVector = case axisNum of
                (
                    1: [1, 0, 0] -- X axis
                    2: [0, 1, 0] -- Y axis
                    3: [0, 0, 1] -- Z axis
                    default: [1, 0, 0]
                )
                
                -- Calculate lengths for each axis
                local lengthX = maxPoint.x - minPoint.x
                local lengthY = maxPoint.y - minPoint.y
                local lengthZ = maxPoint.z - minPoint.z
                
                -- Find endpoints in the selected axis direction
                local endpoint1 = minPoint
                local endpoint2 = maxPoint
                
                -- Project all vertices onto the selected axis while preserving their relative positions
                for v in allVerts do
                (
                    local pos, newPos
                    
                    if useWorldSpace and theNode != undefined then
                        pos = (polyOp.getVert currentMod v) * theNode.transform
                    else
                        pos = polyOp.getVert currentMod v
                    
                    local normalizedOffset = [0,0,0]
                    
                    -- Calculate normalized position within bounding box (0-1 range)
                    case axisNum of
                    (
                        1: normalizedOffset.x = (pos.x - minPoint.x) / (if lengthX != 0 then lengthX else 1.0)
                        2: normalizedOffset.y = (pos.y - minPoint.y) / (if lengthY != 0 then lengthY else 1.0)
                        3: normalizedOffset.z = (pos.z - minPoint.z) / (if lengthZ != 0 then lengthZ else 1.0)
                    )
                    
                    -- Calculate new aligned position
                    newPos = pos
                    
                    case axisNum of
                    (
                        1: ( -- X alignment
                            newPos.y = centerPoint.y
                            newPos.z = centerPoint.z
                        )
                        2: ( -- Y alignment
                            newPos.x = centerPoint.x
                            newPos.z = centerPoint.z
                        )
                        3: ( -- Z alignment
                            newPos.x = centerPoint.x
                            newPos.y = centerPoint.y
                        )
                    )
                    
                    -- Convert back to local space if needed
                    if useWorldSpace and theNode != undefined then
                        newPos = newPos * (inverse theNode.transform)
                    
                    -- Update vertex position
                    polyOp.setVert currentMod v newPos
                )
            )
        )
        
        -- Update the mesh without using update function
        polyOp.setEdgeSelection currentMod selectedEdges
        
        -- Force viewport update with correct commands
        redrawViews()
        completeRedraw()
    )
    
    -- Face alignment global function
    global alignFacesToAxisFn
    fn alignFacesToAxisFn currentMod selectedFaces axisNum useWorldSpace =
    (
        -- Get current selected node
        local theNode = $
        
        -- Group connected faces
        local faceGroups = groupConnectedFaces currentMod selectedFaces
        
        -- Process each group of faces
        for faceGroup in faceGroups do
        (
            -- Collect all unique vertices from the faces in the group
            local allVerts = #()
            local uniqueVerts = #{}
            
            for f in faceGroup do
            (
                -- Get the face vertices
                local vertIndices = polyOp.getFaceVerts currentMod f
                
                for v in vertIndices where not uniqueVerts[v] do
                (
                    append allVerts v
                    uniqueVerts[v] = true
                )
            )
            
            -- Calculate center of all vertices in appropriate space
            local centerPoint = [0,0,0]
            
            for v in allVerts do
            (
                local pos
                
                if useWorldSpace and theNode != undefined then
                    pos = (polyOp.getVert currentMod v) * theNode.transform
                else
                    pos = polyOp.getVert currentMod v
                
                centerPoint += pos
            )
            
            centerPoint /= allVerts.count
            
            -- Calculate the normal direction based on the axis
            local normal = case axisNum of
            (
                1: [1,0,0] -- X axis
                2: [0,1,0] -- Y axis
                3: [0,0,1] -- Z axis
            )
            
            -- Project vertices onto a plane perpendicular to the chosen axis
            -- passing through the center point
            for v in allVerts do
            (
                local vertPos
                
                if useWorldSpace and theNode != undefined then
                    vertPos = (polyOp.getVert currentMod v) * theNode.transform
                else
                    vertPos = polyOp.getVert currentMod v
                
                -- Get distance from vertex to plane along normal
                local dist = dot (vertPos - centerPoint) normal
                
                -- Project vertex onto plane by subtracting normal component
                local projectedPos = vertPos - (normal * dist)
                
                -- Convert back to local space if needed
                if useWorldSpace and theNode != undefined then
                    projectedPos = projectedPos * (inverse theNode.transform)
                
                -- Set new vertex position
                polyOp.setVert currentMod v projectedPos
            )
        )
        
        -- Update the mesh
        polyOp.setFaceSelection currentMod selectedFaces
        
        -- Force viewport update
        redrawViews()
        completeRedraw()
    )
    
    -- Function to align vertices to specified axis
    fn alignVerticesToAxis axisNum =
    (
        -- Get the current EditablePoly/Edit_Poly modifier
        local currentMod = modPanel.getCurrentObject()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly selected"
            return false
        )
        
        -- Check if we're in vertex subobject mode
        if (subObjectLevel != 1) then
        (
            lblStatus.text = "Error: Not in Vertex subobject mode"
            return false
        )
        
        -- Get selected vertices
        local selectedVerts = polyOp.getVertSelection currentMod
        
        if selectedVerts.numberset == 0 then
        (
            lblStatus.text = "Error: No vertices selected"
            return false
        )
        
        -- Get space type (1=local, 2=world)
        local useWorldSpace = (rdoGlobalSpace.state == 2)
        
        -- Calculate the average position of selected vertices
        local avgPos = [0,0,0]
        local vertCount = 0
        
        -- Get current selected node
        local theNode = $
        
        for v in selectedVerts do
        (
            local pos
            
            if useWorldSpace and theNode != undefined then
                pos = (polyOp.getVert currentMod v) * theNode.transform
            else
                pos = polyOp.getVert currentMod v
            
            avgPos += pos
            vertCount += 1
        )
        
        if vertCount > 0 then avgPos /= vertCount
        
        -- Use undo correctly for MAXScript
        undo on
        (
            alignVerticesToAxisFn currentMod selectedVerts avgPos axisNum useWorldSpace
        )
        
        local axisName = case axisNum of
        (
            1: "X"
            2: "Y" 
            3: "Z"
            default: "Unknown"
        )
        
        local spaceText = if useWorldSpace then "world" else "local"
        lblStatus.text = "Aligned vertices to " + axisName + " in " + spaceText + " space"
        return true
    )
    
    -- Function to snap vertices to grid
    fn snapVerticesToGrid gridSize =
    (
        -- Get the current EditablePoly/Edit_Poly modifier
        local currentMod = modPanel.getCurrentObject()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly selected"
            return false
        )
        
        -- Check if we're in vertex subobject mode
        if (subObjectLevel != 1) then
        (
            lblStatus.text = "Error: Not in Vertex subobject mode"
            return false
        )
        
        -- Get selected vertices
        local selectedVerts = polyOp.getVertSelection currentMod
        
        if selectedVerts.numberset == 0 then
        (
            lblStatus.text = "Error: No vertices selected"
            return false
        )
        
        -- Get axes selection from dropdown
        local axesSelection = ddlGridAxes.selection
        
        -- Get space type (1=local, 2=world) from global setting
        local useWorldSpace = (rdoGlobalSpace.state == 2)
        
        -- Use undo correctly for MAXScript
        undo on
        (
            snapVerticesToGridFn currentMod selectedVerts gridSize axesSelection useWorldSpace
        )
        
        -- Create descriptive text based on the selected axes
        local axesText = case axesSelection of
        (
            1: "X axis"
            2: "Y axis"
            3: "Z axis"
            4: "XY axes"
            5: "XZ axes"
            6: "YZ axes"
            7: "all axes"
            default: "unknown axes"
        )
        
        local spaceText = if useWorldSpace then "world" else "local"
        
        lblStatus.text = "Snapped vertices to grid size " + gridSize as string + " on " + axesText + " in " + spaceText + " space"
        return true
    )
    
    -- Function to align each edge to specified axis
    fn alignEdgesToAxis axisNum =
    (
        -- Get the current EditablePoly/Edit_Poly modifier
        local currentMod = modPanel.getCurrentObject()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly selected"
            return false
        )
        
        -- Check if we're in edge subobject mode
        if (subObjectLevel != 2) then
        (
            lblStatus.text = "Error: Not in Edge subobject mode"
            return false
        )
        
        -- Get selected edges
        local selectedEdges = polyOp.getEdgeSelection currentMod
        
        if selectedEdges.numberset == 0 then
        (
            lblStatus.text = "Error: No edges selected"
            return false
        )
        
        -- Get space type (1=local, 2=world)
        local useWorldSpace = (rdoGlobalSpace.state == 2)
        
        -- Use undo correctly for MAXScript
        undo on
        (
            alignEdgesToAxisFn currentMod selectedEdges axisNum useWorldSpace
        )
        
        local axisName = case axisNum of
        (
            1: "X"
            2: "Y" 
            3: "Z"
            default: "Unknown"
        )
        
        local spaceText = if useWorldSpace then "world" else "local"
        lblStatus.text = "Aligned edges to " + axisName + " in " + spaceText + " space"
        return true
    )
    
    -- Function to align each face to specified axis
    fn alignFacesToAxis axisNum =
    (
        -- Get the current EditablePoly/Edit_Poly modifier
        local currentMod = modPanel.getCurrentObject()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly selected"
            return false
        )
        
        -- Check if we're in face subobject mode
        if (subObjectLevel != 4) then
        (
            lblStatus.text = "Error: Not in Face subobject mode"
            return false
        )
        
        -- Get selected faces
        local selectedFaces = polyOp.getFaceSelection currentMod
        
        if selectedFaces.numberset == 0 then
        (
            lblStatus.text = "Error: No faces selected"
            return false
        )
        
        -- Get space type (1=local, 2=world)
        local useWorldSpace = (rdoGlobalSpace.state == 2)
        
        -- Use undo correctly for MAXScript
        undo on
        (
            alignFacesToAxisFn currentMod selectedFaces axisNum useWorldSpace
        )
        
        local axisName = case axisNum of
        (
            1: "X"
            2: "Y" 
            3: "Z"
            default: "Unknown"
        )
        
        local spaceText = if useWorldSpace then "world" else "local"
        lblStatus.text = "Aligned faces to " + axisName + " in " + spaceText + " space"
        return true
    )
    
    -- Button click handlers for vertex alignment
    on btnVertexAlignX pressed do
    (
        alignVerticesToAxis 1
    )
    
    on btnVertexAlignY pressed do
    (
        alignVerticesToAxis 2
    )
    
    on btnVertexAlignZ pressed do
    (
        alignVerticesToAxis 3
    )
    
    -- Button click handler for vertex grid snapping
    on btnSnapToGrid pressed do
    (
        snapVerticesToGrid spnGridSize.value
    )
    
    -- Button click handlers for edge alignment
    on btnEdgeAlignX pressed do
    (
        alignEdgesToAxis 1
    )
    
    on btnEdgeAlignY pressed do
    (
        alignEdgesToAxis 2
    )
    
    on btnEdgeAlignZ pressed do
    (
        alignEdgesToAxis 3
    )
    
    -- Button click handlers for face alignment
    on btnFaceAlignX pressed do
    (
        alignFacesToAxis 1
    )
    
    on btnFaceAlignY pressed do
    (
        alignFacesToAxis 2
    )
    
    on btnFaceAlignZ pressed do
    (
        alignFacesToAxis 3
    )
)

-- Create and show the floater
if (AlignToolsFloater != undefined) and (AlignToolsFloater.open) do
(
    closeRolloutFloater AlignToolsFloater
)

-- about rollout
rollout AlignToolsAbout "About"
(
 label lab1 "Align Tools"
 label lab2 "by asutekku 2025"
)

AlignToolsFloater = newRolloutFloater "Align Tools" 250 440
addRollout AlignToolsRollout AlignToolsFloater
addRollout AlignToolsAbout AlignToolsFloater
