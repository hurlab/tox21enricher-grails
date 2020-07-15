<%--
  Created by IntelliJ IDEA.
  User: Larson
  Date: 9/9/2016
  Time: 2:36 AM
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <meta name="layout" content="main" />
    <title>Network Generation</title>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/2.7.9/cytoscape.min.js"></script>
    <script>
        var resultSetId = "${resultSet}";
        var network = "${network}";
        $(document).ready(function() {
           $.get("../analysisResults/getGctJsonData?resultSet=" + resultSetId + "&network=" + network, function(response) {

               var data = JSON.parse(response);
               initCy(data);
           })
        });

        var initCy = function(data) { // on dom ready
            console.log(data);

            var cy = cytoscape({
                container: $("#cy")[0],
                layout: {
                    name: 'concentric',
                    fit: true,
                    padding: 0,
                    startAngle: 3 / 2 * Math.PI,
                    clockwise: true,
                    equidistant: true,
                    minNodeSpacing: 10,
                    animate: true,
                    animationDuration: 1000,
                    avoidOverlap: false,
                    //radius:500,
                    sort: function(a, b) {
                        return a.data("name").localeCompare(b.data("name"))
                    }
                },
                style: [
                    {
                        "selector": "node",
                        "style": {
                            "content": "data(name)",
                            "font-size": "8px",
                            "text-valign": "center",
                            "text-halign": "center",
                            "background-color": "#555",
                            "text-outline-color": "#555",
                            "text-outline-width": "2px",
                            //"color": "#fff",
                            "color": "mapData(set, 1, 4, blue, green)",
                            "overlay-padding": "6px",
                            "z-index": "10",
                            padding: 10
                        }
                    },
                    {
                        "selector": "core",
                        "style": {
                            "selection-box-color": "#AAD8FF",
                            "selection-box-border-color": "#8BB0D0",
                            "selection-box-opacity": "0.5"
                        }
                    }, {
                        "selector": "node[[degree>=5]][[degree<=7]]",
                        "style": {
                            height: 50,
                            width: 50
                        }
                    }, {
                        "selector": "node[[degree<5]]",
                        "style": {
                            height: 25,
                            width: 25
                        }
                    }, {
                        "selector": "node[[degree>7]]",
                        "style": {
                            height: 75,
                            width: 75
                        }
                    }, {
                        selector: "edge",
                        style: {
                            "line-color": "mapData(jaccard, 0, 0.025, blue, red)",
                            "width": 1
                        }
                    }],
                elements: data.elements
            });

        cy.on('tap', 'node', function(){
            try { // your browser may block popups
                window.open( this.data('href') );
            } catch(e){ // fall back on url change
                window.location.href = this.data('href');
            }
        });

    }
    </script>
    <title></title>
    <style>
    #cy {
        height: 100%;
        width: 100%;
        position: absolute;
        left: 0;
        top: 0;
    }
    </style>
</head>

<body>
<div id="cy"></div>
</body>
</html>