macroScript CollapseDeadStructs
category:"Nimikko" 
tooltip:"Collapses Dead Strucutres"
(
on execute do
(
    global cdsModName = "Collapse Dead Structs"
    
    -- Close existing floater if open
    if CollapseStructs != undefined do
    (
        try(closeRolloutFloater CollapseStructs)catch()
    )
    
    -- Create new floater
    CollapseStructs = newRolloutFloater "Collapse Dead Structs" 220 220
    
    -- Main rollout
    rollout rCDSGenerate "Collapse Dead Structs"
    (
        group "Operations:"
        (
            button cmdCreate "Collapse Selected" width:180 tooltip:"Collapse dead structures in the selected object(s)"
            button cmdCreateAll "Collapse All Editable Polys" width:180 tooltip:"Process all editable poly objects in the scene"
            checkbutton chkAutoUpdate "Auto-Update" width:180 tooltip:"Automatically update when selection changes"
        )
        
        group "Status:"
        (
            label lblStatus "Ready" align:#center
        )
        
        fn isValidPoly obj = 
        (
            return (superClassOf obj == GeometryClass and classOf obj == Editable_Poly)
        )
        
        fn processObject obj =
        (
            if isValidPoly obj then
            (
                lblStatus.text = "Processing: " + obj.name
                try
                (
                    polyop.collapseDeadStructs obj
                    return true
                )
                catch
                (
                    lblStatus.text = "Error processing: " + obj.name
                    return false
                )
            )
            return false
        )
        
        on cmdCreate pressed do
        (
            local successCount = 0
            local failCount = 0
            
            if selection.count == 0 then
            (
                lblStatus.text = "No objects selected!"
            )
            else
            (
                for obj in selection do
                (
                    if processObject obj then
                        successCount += 1
                    else
                        failCount += 1
                )
                
                lblStatus.text = "Processed " + successCount as string + " objects"
                if failCount > 0 do lblStatus.text += " (" + failCount as string + " failed)"
            )
        )
        
        on cmdCreateAll pressed do
        (
            local polyObjects = for obj in objects where isValidPoly obj collect obj
            local successCount = 0
            local failCount = 0
            
            if polyObjects.count == 0 then
            (
                lblStatus.text = "No editable poly objects found!"
            )
            else
            (
                for obj in polyObjects do
                (
                    if processObject obj then
                        successCount += 1
                    else
                        failCount += 1
                )
                
                lblStatus.text = "Processed " + successCount as string + " objects"
                if failCount > 0 do lblStatus.text += " (" + failCount as string + " failed)"
            )
        )
        
        on chkAutoUpdate changed state do
        (
            if state then
            (
                callbacks.addScript #selectionSetChanged "try(rCDSGenerate.cmdCreate.pressed())catch()"
                lblStatus.text = "Auto-Update enabled"
            )
            else
            (
                callbacks.removeScripts #selectionSetChanged
                lblStatus.text = "Auto-Update disabled"
            )
        )
    )
    
    -- About rollout
    rollout rCDSAbout "About"
    (
        label lab1 "Collapse Dead Structs 1.1"
        label lab2 "by asutekku 2025 for Nimikko"
        label lab3 "Enhanced version"
        hyperLink lnkHelp "Help & Documentation" address:"#" align:#center
        
        on lnkHelp pressed do
        (
            lblInfo = "This tool collapses dead structures in editable poly objects.\n\n"
            lblInfo += "- Select one or more editable poly objects\n"
            lblInfo += "- Click 'Collapse Selected' to process them\n"
            lblInfo += "- Or enable 'Auto-Update' for automatic processing\n"
            
            messageBox lblInfo title:"Collapse Dead Structs Help"
        )
    )
    
    -- Add rollouts to floater
    addRollout rCDSGenerate CollapseStructs
    addRollout rCDSAbout CollapseStructs
    
    -- Initialize
    rCDSGenerate.lblStatus.text = "Ready"
))