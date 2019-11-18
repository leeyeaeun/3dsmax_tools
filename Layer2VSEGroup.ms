/***Utility to create a dummy per layer and link all objects on the layer to it.

This is the standard workflow to organize geometry for a VSE, hence the name.

***/

struct Layer2VSEGroup (

    fn getLayerDummy layerName = (
        /***Returns existing layer dummy or creates a new one.***/

        local layerDummy = getNodeByName layerName
        if layerDummy != undefined do (
            if classOf layerDummy == Dummy do
                return layerDummy
        )

        layerDummy = Dummy name:layerName
    ),

    fn convertLayer layer = (

        local layerDummy = this.getLayerDummy layer.name
        layer.nodes &layerNodes

        for layerNode in layerNodes where layerNode != layerDummy do
            layerNode.parent = layerDummy

        layer.addnode layerDummy
    ),

    fn convertAllLayers = (
        /***Create dummies for all layers (if not yet existing)
        and parent all layer objects to the dummy.

        Main entry function.
        Skips default layer '0'.

        **/
        for i = 1 to (Layermanager.count - 1) do
            this.convertLayer (LayerManager.getLayer i)
    )
)


global Layer2VSEGroup = Layer2VSEGroup()
