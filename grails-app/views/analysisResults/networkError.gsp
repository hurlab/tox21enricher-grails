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
    <script src="https://cdn.zingchart.com/zingchart.min.js"></script>
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
<p>
An error has occurred with network generation. Tox21 Enricher attempted to generate a network with 0 nodes. Please use the "back" button on your browser to return to the previous screen.
<br>
<br>
Network generation failed for the following arguments:
<br>
resultSet=${resultSet}
<br>
<g:if test="${network == 1}">
    network=Chart
</g:if>
<g:else>
    network=Cluster
</g:else>
<br>
inputSets=${inputSets}
<br>
numSets=${numSets}
<br>
qval=${qval}
<br>
nodeCutoff=${nodeCutoff}
<br>
</p>
<script>
    $(document).foundation();
</script>
</body>
</html>