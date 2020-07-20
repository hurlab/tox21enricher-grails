<%--
  Created by IntelliJ IDEA.
  User: Larson
  Date: 8/17/2017
  Time: 2:45 PM
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <meta name="layout" content="main" />
    <title>Network Generation</title>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/vis/4.20.1/vis.min.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/vis/4.20.1/vis.min.css" rel="stylesheet" type="text/css" />

    <script type="text/javascript">
        $(document).ready(function() {
            $("input").each(function() {
                console.log('setting checkboxes');
                console.log('this.data', $(this).data("checked"));
                if ($(this).data("checked") == true) {
                    console.log('data-checked = true');
                    $(this).prop("checked", true);
                }
            });
        });
    </script>

    <style type="text/css">
    #mynetwork {
        width: 75%;
        height: 75%;
        border: 1px solid lightgray;
    }
    #eventSpan {
        border-top: 1px dotted lightgray;
    }
    #qvalInput {
        width: 80px;
    }
    </style>

</head>
<body>
<g:form controller="analysisResults" action="createNetwork" params="${[resultSet: resultSet, numSets: numSets, inputSets: inputSets, network: network, nodeCutoff: nodeCutoff]}">
    <div class="row">
        <div class="small-3 columns">
            <h6>Edge Selection Criteria</h6>
            <nobr><label>Q-Value
                <input name="qval" id="qvalInput" value="${params.qval}">
            </label></nobr>
            <label>Select Input Sets</label>
            <br />
            <g:each var="inputSet" in="${inputSets.keySet()}">
                <input name="checkbox" type="checkbox" value="${inputSet}" data-checked="${Arrays.asList(inputSetCheckbox).contains(inputSet)}"><label for="checkbox">${inputSet}</label>
                <br />
            </g:each>
            <g:submitButton class="button small" name="networkSubmit" value="Begin Network Generation" />
            <div id="eventSpan">Click a node to see more details.</div>
            <div id="eventSpan">Node Legend</div>
            <g:each var="annoClass" in="${classColors.keySet()}">
                <g:if test="${classes.contains(annoClass)}">
                    <div style="background-color:rgb(${classColors[annoClass][0]}, ${classColors[annoClass][1]}, ${classColors[annoClass][2]})">${annoClass}</div>
                </g:if>
            </g:each>
        </div>
        <div id="mynetwork" class="small-9 column"></div>
    </div>
</g:form>

<script type="text/javascript">
    var resultSetId = "${resultSet}";
    var network = "${network}";
    $(document).ready(function() {
        $.get("../analysisResults/getGctJsonData?resultSet=" + resultSetId + "&network=" + network, function(response) {
            var jsonData = JSON.parse(response);
            var nodes = new vis.DataSet(
                jsonData.elements.nodes
            );
            var edges = new vis.DataSet(
                jsonData.elements.edges
            );
            // create a network
            var container = document.getElementById('mynetwork');

            // provide the data in the vis format
            var data = {
                nodes: nodes,
                edges: edges
            };
            var options = {
                physics: {
                    enabled: true,
                    stabilization: {
                        enabled: true,
                        iterations: 1000,
                        updateInterval: 25
                    }
                },
                layout: {
                    improvedLayout: true
                },
                interaction: {
                    hover: true
                }
            };

            // initialize your network!
            var network = new vis.Network(container, data, options);

            network.on("stabilizationIterationsDone", function () {
                network.setOptions( { physics: false } );
            });

            network.on("click", function (params) {
                params.event = "[original event]";
                var ids = params.nodes;

                var clickedNodes = nodes.get(ids);
                var clickedNodeUrl = clickedNodes[0].url;
                console.log('clicked nodes:', clickedNodes);
                console.log('clicked node url:', clickedNodeUrl);
                console.log('click event, getNodeAt returns: ' + this.getNodeAt(params.pointer.DOM));
                if (clickedNodeUrl != null) {
                    document.getElementById('eventSpan').innerHTML = '<p>More information about ' + clickedNodes[0].label + ' <a href="' + clickedNodeUrl + '" target="_blank">here</a>.</p>';
                }
                else
                    document.getElementById('eventSpan').innerHTML = 'Click a node to see more details.';
                    console.log('Node url is null')
            });
        })
    });

    $(document).foundation();
</script>
</body>
</html>