<& ../header.html &>
<div id="tree"></div>
<script type="text/javascript">

CatTree = function() {

    var tree, currentIconMode;

    function changeIconMode() {
        var newVal = parseInt(this.value);
        if (newVal != currentIconMode) {
            currentIconMode = newVal;
        }
        buildTree();
    }

    function buildTree() {

        alert('build');
        //create a new tree:
        tree = new YAHOO.widget.TreeView("tree");

        //turn dynamic loading on for entire tree:
        tree.setDynamicLoad(loadNodeData, currentIconMode);

        //get root node for tree:
        var root = tree.getRoot();

        //add child nodes for tree; our top level nodes are
        //all the states in India:
        var obj = new Object();
        obj.html = "<input type='checkbox'><font color='red'>red</font>";
        var aStates = ["label","label2"]

        for (var i=0, j=aStates.length; i<j; i++) {
            var tempNode = new YAHOO.widget.TextNode(aStates[i], root, false);
            tempNode.cId = i;
        }

        // Use the isLeaf property to force the leaf node presentation for a given node.
        // This disables dynamic loading for the node.
        var tempNode = new YAHOO.widget.TextNode('This is a leaf node', root, false);
        tempNode.isLeaf = true;

        //render tree with these toplevel nodes; all descendants of these nodes
        //will be generated as needed by the dynamic loader.
        tree.draw();
    };

    function loadNodeData(node, fnLoadComplete)  {

        //We'll create child nodes based on what we get back when we
        //use Connection Manager to pass the text label of the 
        //expanding node to the Yahoo!
        //Search "related suggestions" API.  Here, we're at the 
        //first part of the request -- we'll make the request to the
        //server.  In our Connection Manager success handler, we'll build our new children
        //and then return fnLoadComplete back to the tree.

        //Get the node's label and urlencode it; this is the word/s
        //on which we'll search for related words:
        var nodeLabel = encodeURI(node.label);

        //prepare URL for XHR request:
        var sUrl = "/json/subcats.json&cId=" + nodeLabel;

        //prepare our callback object
        var callback = {

        //if our XHR call is successful, we want to make use
        //of the returned data and create child nodes.
        success: function(oResponse) {
            YAHOO.log("XHR transaction was successful.", "info", "example");
            console.log(oResponse.responseText);
            var oResults = eval("(" + oResponse.responseText + ")");
            if((oResults.ResultSet.Result) && (oResults.ResultSet.Result.length)) {
                //Result is an array if more than one result, string otherwise
                if(YAHOO.lang.isArray(oResults.ResultSet.Result)) {
                    for (var i=0, j=oResults.ResultSet.Result.length; i<j; i++) {
                        var tempNode = new YAHOO.widget.TextNode(oResults.ResultSet.Result[i], node, false);
                    }
                } else {
                    //there is only one result; comes as string:
                    var tempNode = new YAHOO.widget.TextNode(oResults.ResultSet.Result, node, false)
                }
            }

            //When we're done creating child nodes, we execute the node's
            //loadComplete callback method which comes in via the argument
            //in the response object (we could also access it at node.loadComplete,
            //if necessary):
            oResponse.argument.fnLoadComplete();
        },

        //if our XHR call is not successful, we want to
        //fire the TreeView callback and let the Tree
        //proceed with its business.
        failure: function(oResponse) {
            YAHOO.log("Failed to process XHR transaction.", "info", "example");
            oResponse.argument.fnLoadComplete();
        },

        //our handlers for the XHR response will need the same
        //argument information we got to loadNodeData, so
        //we'll pass those along:
        argument: {
            "node": node,
            "fnLoadComplete": fnLoadComplete
        },

        //timeout -- if more than 7 seconds go by, we'll abort
        //the transaction and assume there are no children:
        timeout: 7000
        };

        //With our callback object ready, it's now time to 
        //make our XHR call using Connection Manager's
        //asyncRequest method:
        YAHOO.util.Connect.asyncRequest('GET', sUrl, callback);
    }


    return {
        init: function() {
            YAHOO.util.Event.on(["mode0", "mode1"], "click", changeIconMode);
            var el = document.getElementById("mode1");
            if (el && el.checked) {
                currentIconMode = parseInt(el.value);
            } else {
                currentIconMode = 0;
            }

            buildTree();
        }


    }
} ();

//once the DOM has loaded, we can go ahead and set up our tree:
YAHOO.util.Event.onDOMReady(CatTree.init, CatTree,true)


</script>
<%perl>


my $root = xPapers::Cat->new(id=>1)->load;
print $root->name . "<br>";


</%perl>
