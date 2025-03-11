-- Align Tools for 3ds Max
-- This script provides alignment tools for vertices, edges and faces
-- Created: March 2025
-- File: alignTools.ms

-- Global wrapper functions to work with both Editable_Poly and Edit_Poly
global getPolyVert
fn getPolyVert polyMod vertIndex =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getVert polyMod vertIndex)
    else if classOf polyMod == Edit_Poly then
        return (polyMod.GetVertex vertIndex)
    else
        return [0,0,0]
)

global setPolyVert
fn setPolyVert polyMod vertIndex newPos =
(
    if classOf polyMod == Editable_Poly then
        polyOp.setVert polyMod vertIndex newPos
    else if classOf polyMod == Edit_Poly then
        polyMod.SetVertex vertIndex newPos
)

global getPolyVertSelection
fn getPolyVertSelection polyMod =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getVertSelection polyMod)
    else if classOf polyMod == Edit_Poly then
        return (polyMod.GetSelection #Vertex)
)

global setPolyVertSelection
fn setPolyVertSelection polyMod selection =
(
    if classOf polyMod == Editable_Poly then
        polyOp.setVertSelection polyMod selection
    else if classOf polyMod == Edit_Poly then
        polyMod.SetSelection #Vertex selection
)

global getPolyEdgeSelection
fn getPolyEdgeSelection polyMod =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getEdgeSelection polyMod)
    else if classOf polyMod == Edit_Poly then
        return (polyMod.GetSelection #Edge)
)

global setPolyEdgeSelection
fn setPolyEdgeSelection polyMod selection =
(
    if classOf polyMod == Editable_Poly then
        polyOp.setEdgeSelection polyMod selection
    else if classOf polyMod == Edit_Poly then
        polyMod.SetSelection #Edge selection
)

global getPolyEdgeVerts
fn getPolyEdgeVerts polyMod edgeIndex =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getEdgeVerts polyMod edgeIndex)
    else if classOf polyMod == Edit_Poly then
    (
        -- For Edit_Poly, get both vertices of the edge
        local v1 = polyMod.GetEdgeVertex edgeIndex 1
        local v2 = polyMod.GetEdgeVertex edgeIndex 2
        return #(v1, v2)
    )
    else
        return #()
)

global getPolyFaceSelection
fn getPolyFaceSelection polyMod =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getFaceSelection polyMod)
    else if classOf polyMod == Edit_Poly then
        return (polyMod.GetSelection #Face)
)

global setPolyFaceSelection
fn setPolyFaceSelection polyMod selection =
(
    if classOf polyMod == Editable_Poly then
        polyOp.setFaceSelection polyMod selection
    else if classOf polyMod == Edit_Poly then
        polyMod.SetSelection #Face selection
)

global getPolyFaceVerts
fn getPolyFaceVerts polyMod faceIndex =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getFaceVerts polyMod faceIndex)
    else if classOf polyMod == Edit_Poly then
    (
        -- For Edit_Poly, we need to get vertices one by one
        local vertDegree = polyMod.GetFaceDegree faceIndex
        local vertArray = #()
        
        for i = 1 to vertDegree do
        (
            local vertIndex = polyMod.GetFaceVertex faceIndex i
            append vertArray vertIndex
        )
        
        return vertArray
    )
    else
        return #()
)

global getPolyFaceEdges
fn getPolyFaceEdges polyMod faceIndex =
(
    if classOf polyMod == Editable_Poly then
        return (polyOp.getFaceEdges polyMod faceIndex)
    else if classOf polyMod == Edit_Poly then
    (
        -- For Edit_Poly, we need to get edges one by one
        local edgeDegree = polyMod.GetFaceDegree faceIndex
        local edgeArray = #()
        
        for i = 1 to edgeDegree do
        (
            local edgeIndex = polyMod.GetFaceEdge faceIndex i
            append edgeArray edgeIndex
        )
        
        return edgeArray
    )
    else
        return #()
)

-- Create custom category and register tool
macroScript AlignTools
category:"Nimikko"
toolTip:"Align Tools" 
buttonText:"Align Tools"
(
    on execute do
    (
        fileIn (getSourceFileName())
    )
)

rollout AlignToolsRollout "Align Tools" width:250 height:420
(
	group "Vertex: Snap to grid"
    (
		dropdownList ddlGridAxes "Snap:" items:#("X", "Y", "Z", "XY", "XZ", "YZ", "XYZ") selection:7 width:120 align:#left toolTip:"Select which axes to snap to grid"
        spinner spnGridSize "Grid Size:" range:[0.1, 10000, 10] width:120 height:16 align:#left toolTip:"Set the grid size for snapping operations"
        button btnSnapToGrid "Snap" width:200 height:30 align:#center toolTip:"Snap selected vertices to the grid"
    )
	
    group "Vertex: Align selection to:"
    (
        button btnVertexAlignX "X" width:60 height:30 across:3 toolTip:"Align selected vertices to X axis"
        button btnVertexAlignY "Y" width:60 height:30 toolTip:"Align selected vertices to Y axis"
        button btnVertexAlignZ "Z" width:60 height:30 toolTip:"Align selected vertices to Z axis"
    )
    
    group "Edge: Align selection to:"
    (
        button btnEdgeAlignX "X" width:60 height:30 across:3 toolTip:"Align selected edges to X axis (preserves connected edges)"
        button btnEdgeAlignY "Y" width:60 height:30 toolTip:"Align selected edges to Y axis (preserves connected edges)"
        button btnEdgeAlignZ "Z" width:60 height:30 toolTip:"Align selected edges to Z axis (preserves connected edges)"
    )
    
    group "Face: Align selection to:"
    (
        button btnFaceAlignX "X" width:60 height:30 across:3 toolTip:"Align selected faces to X axis (preserves connected faces)"
        button btnFaceAlignY "Y" width:60 height:30 toolTip:"Align selected faces to Y axis (preserves connected faces)"
        button btnFaceAlignZ "Z" width:60 height:30 toolTip:"Align selected faces to Z axis (preserves connected faces)"
    )
    
    group "Global Settings"
    (
        radioButtons rdoGlobalSpace "Space:" labels:#("Local", "World") default:1 align:#left toolTip:"Toggle between local object space and world space for all operations"
    )
    
    label lblStatus "" width:240 height:30
    
    -- Helper function to get the active Editable Poly or Edit Poly modifier
    fn getActivePoly =
    (
        local thePoly = undefined
        
        -- Check if a node is selected
        if $ != undefined then
        (
            -- Check if we're in a sub-object level
            if subObjectLevel > 0 then
            (
                -- Try to get the current modifier
                thePoly = modPanel.getCurrentObject()
                
                -- If not a valid poly object, check if the current object is an Editable Poly
                if thePoly == undefined or (classOf thePoly != Edit_Poly and classOf thePoly != Editable_Poly) then
                (
                    -- Check if the selected node is an Editable_Poly
                    if classOf $ == Editable_Poly then
                        thePoly = $
                )
            )
            else
            (
                -- Not in subobject mode, check if the selected node is an Editable_Poly
                if classOf $ == Editable_Poly then
                    thePoly = $
            )
        )
        
        return thePoly
    )
    
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
                local objectPos = getPolyVert currentMod v
                
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
                setPolyVert currentMod v newObjectPos
            )
            else
            (
                -- LOCAL SPACE APPROACH
                -- Get current vertex position
                local pos = getPolyVert currentMod v
                
                -- Create new position by setting specific axis to average
                local newPos = pos
                
                case axisNum of
                (
                    1: newPos.x = avgPos.x -- Align to X
                    2: newPos.y = avgPos.y -- Align to Y
                    3: newPos.z = avgPos.z -- Align to Z
                )
                
                -- Update vertex position
                setPolyVert currentMod v newPos
            )
        )
        
        -- Update the mesh
        setPolyVertSelection currentMod selectedVerts
        
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
                local objectPos = getPolyVert currentMod v
                
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
                setPolyVert currentMod v newObjectPos
                
                -- Debug logs
                --format "==== WORLD SPACE SNAPPING ====\n"
                --format "Vertex: %\n" v
                --format "Object pos: [%, %, %]\n" objectPos.x objectPos.y objectPos.z
                --format "World pos: [%, %, %]\n" worldPos.x worldPos.y worldPos.z
                --format "Snapped world: [%, %, %]\n" newWorldX newWorldY newWorldZ
                --format "New object pos: [%, %, %]\n\n" newObjectPos.x newObjectPos.y newObjectPos.z
            )
            else
            (
                -- LOCAL SPACE APPROACH
                -- Get vertex position in local space
                local pos = getPolyVert currentMod v
                
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
                setPolyVert currentMod v newPos
                
                -- Debug logs
                --format "==== LOCAL SPACE SNAPPING ====\n"
                --format "Vertex: %\n" v
                --format "Local pos: [%, %, %]\n" x y z
                --format "New local pos: [%, %, %]\n\n" newX newY newZ
            )
        )
        
        -- Update the mesh
        setPolyVertSelection currentMod selectedVerts
        
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
                local verts = getPolyEdgeVerts currentMod currentEdge
                
                -- Find other selected edges that share these vertices
                for testEdge in selectedEdges where not (processedEdges[testEdge]) do
                (
                    local testVerts = getPolyEdgeVerts currentMod testEdge
                    
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
                local faceEdges = getPolyFaceEdges currentMod currentFace
                
                -- Find other selected faces that share these edges
                for testFace in selectedFaces where not (processedFaces[testFace]) do
                (
                    local testEdges = getPolyFaceEdges currentMod testFace
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
    
    -- First calculate the average coordinate for the selected axis
    local axisAvg = 0.0
    local vertCount = 0
    
    -- Collect all unique vertices from all selected edges
    local uniqueVerts = #{}
    
    for e in selectedEdges do
    (
        local verts = getPolyEdgeVerts currentMod e
        if not uniqueVerts[verts[1]] do uniqueVerts[verts[1]] = true
        if not uniqueVerts[verts[2]] do uniqueVerts[verts[2]] = true
    )
    
    -- Calculate average position on the selected axis
    for v in uniqueVerts do
    (
        local pos
        
        if useWorldSpace and theNode != undefined then
            pos = (getPolyVert currentMod v) * theNode.transform
        else
            pos = getPolyVert currentMod v
        
        -- Add coordinate based on the axis we're aligning to
        case axisNum of
        (
            1: axisAvg += pos.x  -- X axis
            2: axisAvg += pos.y  -- Y axis
            3: axisAvg += pos.z  -- Z axis
        )
        
        vertCount += 1
    )
    
    -- Calculate average
    if vertCount > 0 then axisAvg /= vertCount
    
    -- Now update all vertices positions for the selected edges
    for e in selectedEdges do
    (
        -- Get the edge vertices
        local verts = getPolyEdgeVerts currentMod e
        
        -- Process each vertex of the edge
        for v in verts do
        (
            local pos, newPos
            
            if useWorldSpace and theNode != undefined then
            (
                -- World space positions
                pos = (getPolyVert currentMod v) * theNode.transform
                
                -- Create new position by setting only the specific axis to average
                newPos = pos
                case axisNum of
                (
                    1: newPos.x = axisAvg -- X alignment
                    2: newPos.y = axisAvg -- Y alignment
                    3: newPos.z = axisAvg -- Z alignment
                )
                
                -- Convert back to local space
                newPos = newPos * (inverse theNode.transform)
            )
            else
            (
                -- Local space positions
                pos = getPolyVert currentMod v
                
                -- Create new position by setting only the specific axis to average
                newPos = pos
                case axisNum of
                (
                    1: newPos.x = axisAvg -- X alignment
                    2: newPos.y = axisAvg -- Y alignment
                    3: newPos.z = axisAvg -- Z alignment
                )
            )
            
            -- Update vertex position
            setPolyVert currentMod v newPos
        )
    )
    
    -- Update the mesh
    setPolyEdgeSelection currentMod selectedEdges
    
    -- Force viewport update
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
                local vertIndices = getPolyFaceVerts currentMod f
                
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
                    pos = (getPolyVert currentMod v) * theNode.transform
                else
                    pos = getPolyVert currentMod v
                
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
                setPolyVert currentMod v projectedPos
            )
        )
        
        -- Update the mesh
        setPolyFaceSelection currentMod selectedFaces
        
        -- Force viewport update
        redrawViews()
        completeRedraw()
    )
    
    -- Function to align vertices to specified axis
    fn alignVerticesToAxis axisNum =
    (
        -- Get the active poly object/modifier
        local currentMod = getActivePoly()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly or Edit Poly modifier found"
            return false
        )
        
        -- Check if we're in vertex subobject mode
        if (subObjectLevel != 1) then
        (
            lblStatus.text = "Error: Not in Vertex subobject mode"
            return false
        )
        
        -- Get selected vertices
        local selectedVerts = getPolyVertSelection currentMod
        
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
                pos = (getPolyVert currentMod v) * theNode.transform
            else
                pos = getPolyVert currentMod v
            
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
        -- Get the active poly object/modifier
        local currentMod = getActivePoly()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly or Edit Poly modifier found"
            return false
        )
        
        -- Check if we're in vertex subobject mode
        if (subObjectLevel != 1) then
        (
            lblStatus.text = "Error: Not in Vertex subobject mode"
            return false
        )
        
        -- Get selected vertices
        local selectedVerts = getPolyVertSelection currentMod
        
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
        -- Get the active poly object/modifier
        local currentMod = getActivePoly()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly or Edit Poly modifier found"
            return false
        )
        
        -- Check if we're in edge subobject mode
        if (subObjectLevel != 2) then
        (
            lblStatus.text = "Error: Not in Edge subobject mode"
            return false
        )
        
        -- Get selected edges
        local selectedEdges = getPolyEdgeSelection currentMod
        
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
        -- Get the active poly object/modifier
        local currentMod = getActivePoly()
        
        if currentMod == undefined then
        (
            lblStatus.text = "Error: No Editable Poly or Edit Poly modifier found"
            return false
        )
        
        -- Check if we're in face subobject mode
        if (subObjectLevel != 4) then
        (
            lblStatus.text = "Error: Not in Face subobject mode"
            return false
        )
        
        -- Get selected faces
        local selectedFaces = getPolyFaceSelection currentMod
        
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
 label lab1 "Align Tools" toolTip:"Precision alignment utility for 3ds Max"
 label lab2 "by asutekku 2025 for Nimikko" toolTip:"Visit github.com/asutekku/max-scripts for more tools"
 button btnHelp "Help" width:80 height:25 toolTip:"Open readme and documentation"
 
 on btnHelp pressed do
 (
   -- You could implement help functionality here, such as:
   -- Opening a webpage, showing a help dialog, etc.
   -- For now, just show a messagebox
   messageBox "Visit the GitHub repository for full documentation and examples.\n\nQuick Guide:\n- Select elements in Editable Poly mode\n- Use the appropriate alignment tools\n- Use the space toggle for local/world space operations" title:"Align Tools Help" beep:false
 )
)

AlignToolsFloater = newRolloutFloater "Align Tools" 250 440
addRollout AlignToolsRollout AlignToolsFloater
addRollout AlignToolsAbout AlignToolsFloater