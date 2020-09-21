<%--
  Created by IntelliJ IDEA.
  User: Larson
  Date: 7/19/2016
  Time: 6:30 PM
--%>
<!DOCTYPE html>
<%@ page import="tox21_test.ResultSetModel" contentType="text/html;charset=UTF-8" %>
<html>
    <head>
        <meta name="layout" content="main" />

        <style>
        .loader {
            border: 16px solid #f3f3f3;
            border-radius: 50%;
            border-top: 16px solid #3498db;
            width: 120px; 
            height: 120px;
            -webkit-animation: spin 2s linear infinite;
            animation: spin 2s linear infinite;
            align-content: center;
        }

        @-webkit-keyframes spin {
            0% { -webkit-transform: rotate(0deg); }
            100% { -webkit-transform: rotate(360deg); }
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .column.small-centered {
            margin-left: auto;
            margin-right: auto;
            float: none !important;
        }
        </style>

        <%--Use Groovy to generate transaction UUID--%>
        <%def tid = UUID.randomUUID().toString()%>

        <script>
            //save UUID to JS variable for easy access
            var transactionId = "<%=tid%>"

            function toggleAccordions() {
                $("ul.accordion").each(function() {
                    var isDown = $(this).data("tox21_isExpanded");
                    var direction = "up";
                    if (!isDown) {
                        direction = "down";
                    }
                    if (direction == "down") {
                        $("#btnToggleAccordions").text("Collapse All");
                    } else {
                        $("#btnToggleAccordions").text("Expand All");
                    }

                    $(this).data("tox21_isExpanded", !$(this).data("tox21_isExpanded"));
                    var wrapper = this;
                    $(wrapper).find(".accordion-content").each(function() {
                        $(wrapper).foundation(direction, $(this));
                    });
                });
            }

            function regenerateNetwork() {
                $('#regen').submit();
            }

            //Toggle display of user-submitted items
            var showingSubmittedItems = false;
            function showSubmittedItems() {
                if(showingSubmittedItems == false) {    //display items
                    $('#submittedItems').show();
                    $('#showSubmittedItemsButton').text("Hide Submitted Items");
                    showingSubmittedItems = true;
                }
                else {                                  //hide items
                    $('#submittedItems').hide();
                    $('#showSubmittedItemsButton').text("Show Submitted Items");
                    showingSubmittedItems = false;
                }
            }

            var isPerformingEnrichment = false;
            function resubmitCasrns() {
                var textTest = "${casrnResults}";
                console.log(textTest);
                var aR = "${annoResults}";
                console.log(aR);
                document.getElementById("analysisType").value = "CASRNSReenrich";
                document.getElementById("transactionId").value = transactionId;
                document.getElementById("nodeCutoff").value = $("#nodeCutoff")
                $('#main').hide();
                $('#wait').show();
                isPerformingEnrichment = true;
                $('#enrichForm').submit();
            }

            //Periodically refresh the waiting page to update queue position and transaction status
            setInterval(function(){
                if (isPerformingEnrichment === true) {
                    $('#waittable').load("getQueueData?tid="+transactionId+" #waittable");
                    $('#submittedItemsList').load("getQueueData?tid="+transactionId+" #submittedItemsList");
                }
            }, 2000);

        </script>

        <title>Enrichment Results</title>
    </head>

    <body>

    <%-- Waiting page for re-enrichment, hidden by default until user resubmits --%>
    <div id="wait" style="display: none">
        <br />
        <h3>Enrichment in Progress...</h3>
        <p>You will be directed to the results page shortly. Please do not use your browser's back button.</p>
        <br />

        <div id="waittable" class="table-scroll">
            <table class="hover">
                <thead>
                    <tr>
                    <th width="150">Transaction ID</th>
                    <th width="150">Queue Position</th>
                    <th width="150">Status</th>
                    <th width="150">Enrichment Analysis Type</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                    <td>${tid}</td>
                    <td>${pos}</td>
                    <td>
                        <g:if test="${pos >= 5}">
                            Waiting
                        </g:if>
                        <g:elseif test="${pos < 5 && pos >= 0 && success == "waiting..."}">
                            Running
                        </g:elseif>
                        <g:elseif test="${pos < 5 && pos >= 0 && success != "waiting..."}">
                            Complete
                        </g:elseif>
                        <g:else>
                            Initializing
                        </g:else>
                    </td>
                    <td>${type}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <td>
        <br />
        <div class="row">
            <button class="button" type="button" id="showSubmittedItemsButton" onclick="showSubmittedItems()">Show Submitted Items</button>
            <div id="submittedItems" style="display: none">
                <div id="submittedItemsList" style="white-space: pre-line">
                    ${items}
                </div>
            </div>
        </div>      
        <br />
    </div>

    <%-- Main results page, shown by default --%>
    <div id="main">
        <br />
        <h3>Enrichment Results</h3>

        <%-- <button class="button" type="button" id="btnToggleAccordions" onclick="toggleAccordions();">Expand All</button> --%>

        <g:set var="count" value="${0}" />
        <ul class="accordion" data-accordion data-multi-expand="false" data-allow-all-closed="true">
        <g:each var="fileSet" in="${resultSetModel.sortedResultMap}">
            <li class="accordion-item" data-accordion-item>
                <a class="accordion-title">Set: ${fileSet.key}</a>
                <div class="accordion-content" data-tab-content>
                    <div class="row">
                        <div class="small-12 column">
                            <g:if test="${resultSetModel.enrichAnalysisType == 'SMILES'}">
                                <h6>SMILE input: ${resultSetModel.smilesWithResults[count]}</h6>
                            </g:if>
                            <g:set var="count" value="${count + 1}" />
                        </div>
                    </div>
                    <div class="row">
                        <g:each var="file" in="${fileSet.value}">
                            <div class="small-3 column end">
                                <g:if test="${file.endsWith("txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank">${file}</g:link>
                                </g:if>
                                <g:elseif test="${file.endsWith("png")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.gctPerSetDir, filename: file]" target="_blank">
                                        <asset:image src="HeatMapIcon.jpg" />
                                    </g:link>
                                </g:elseif>
                                <g:elseif test="${!file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveInputFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank">${fileSet.key} Input</g:link>
                                </g:elseif>
                                <g:else>
                                    <g:link controller="analysisResults" action="downloadFile" params="[resultSet: resultSetModel.resultSet, filename: file]">${file}</g:link>
                                </g:else>
                            </div>
                        </g:each>
                    </div>
                </div>
            </li>
        </g:each>
        </ul>

        <g:if test="${resultSetModel.enrichAnalysisType == 'SMILES' || resultSetModel.enrichAnalysisType == 'SMILESSimilarity'}">
            SMILE input with no results: <br />
            <g:each var="smileNoResults" in="${resultSetModel.smilesNoResults}">
                ${smileNoResults}<br />
            </g:each>
            <br />
        </g:if>

        <g:if test="${resultSetModel.numSets >= 1}">

            <%-- Only show option to view heatmaps & network if we actually generated them --%>
            <g:if test="${resultSetModel.images.size() > 0}">
                <div class="row" data-equalizer data-equalize-on="medium">
                    <div class="small-6 column hover-image" data-equalizer-watch >
                        <a href="#" data-open="chartModal"><span class="fa fa-picture-o" aria-hidden="true"></span>&nbspChart Full Heat Map</a>
                        
                        <div id="chartModal" class="large reveal" data-reveal aria-labelledby="modalTitle" aria-hidden="true" role="dialog">
                            <h2 id="chartModalTitle">Chart Full Heat Map</h2>
                            <p>${resultSetModel.images[0]}</p>
                            <div class="row align-middle">
                                <div class="small-10 column">
                                    <img src="../analysisResults/serveFile?resultSet=${resultSetModel.resultSet}&filename=gct/${resultSetModel.images[0]}" />
                                </div>
                                <div class="small-2 column">
                                    <p>Legend</p>
                                    <asset:image src="Heatmap_color_legend.png" />
                                </div>
                            </div>
                            <button class="close-button" data-close aria-label="Close modal" type="button">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>

                        <br/>
                        <br/>
                    </div>

                    <div class="small-6 column hover-image" data-equalizer-watch >
                        <a href="#" data-open="clusterModal"><span class="fa fa-picture-o" aria-hidden="true"></span>&nbspCluster Heat Map</a>

                        <div id="clusterModal" class="large reveal" data-reveal aria-labelledby="modalTitle" aria-hidden="true" role="dialog">
                            <h2 id="clusterModalTitle">Cluster Heat Map</h2>
                            <p>${resultSetModel.images[1]}</p>
                            <div class="row align-middle">
                                <div class="small-10 column">
                    <img src="../analysisResults/serveFile?resultSet=${resultSetModel.resultSet}&filename=gct/${resultSetModel.images[1]}" />

                                </div>
                                <div class="small-2 column">
                                    <p>Legend</p>
                                    <asset:image src="Heatmap_color_legend.png" />
                                </div>
                            </div>
                            <button class="close-button" data-close aria-label="Close modal" type="button">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>

                        <br/>
                        <br/>
                    </div>
                </div>
            

            <div class="row" >
                <div class="small-6 column" >
                    <%-- Network 1 loading modal/animation --%>
                    <div class="reveal tiny" id="network1LoadingModal" data-reveal data-options="close_on_background_click:false; close_on_esc: true;">
                        <p class="lead">Creating network...</p>
                        <p>You will be directed to the network page shortly. Please do not use your browser's back button.</p>
                        <div class="row">
                            <div class="small-12 small-centered columns">
                                <div class="loader small-centered"></div>
                            </div>
                        </div>
                    </div>
                    <%-- --------------------------------- --%>
                    <g:link class="button" controller="analysisResults" data-open="network1LoadingModal" action="createNetwork" params="[resultSet: resultSetModel.resultSet, network: 1, numSets: resultSetModel.numSets, qval: 0.05, nodeCutoff: nodeCutoff]">Begin Chart Full Network Creation</g:link>
                </div>

                <div class="small-6 column" >
                    <!-- Network 1 loading modal/animation -->
                    <div class="reveal tiny" id="network2LoadingModal" data-reveal data-options="close_on_background_click:false; close_on_esc: true;">
                        <p class="lead">Creating network...</p>
                        <p>You will be directed to the network page shortly. Please do not use your browser's back button.</p>
                        <div class="row">
                            <div class="small-12 small-centered columns">
                                <div class="loader small-centered"></div>
                            </div>
                        </div>
                    </div>
                    <%-- --------------------------------- --%>
                    <g:link class="button" controller="analysisResults" data-open="network2LoadingModal" action="createNetwork" params="[resultSet: resultSetModel.resultSet, network: 2, numSets: resultSetModel.numSets, qval: 0.05, nodeCutoff: nodeCutoff]">Begin Cluster Network Creation</g:link>
                </div>
            </div>

            </g:if>
        </g:if>
        <br />

        <g:link uri="/analysisResults/downloadFile?resultSet=${resultSetModel.resultSet}&filename=tox21enricher.zip">Download Full Result Set (.zip)</g:link>
        <br />

    <%--changing node cutoff to generate a new network--%>
    <%-- Only show option to view heatmaps & network if we actually generated them --%>
    <g:if test="${resultSetModel.images.size() > 0}"> 
        <div class="row">
            <div class="columns">
                <br>
                <h3>Adjust Network Generation</h3>
                <br>
                <form action="../analysisResults/regenNetwork" method="post" id="regen">
                    <label id="chartSelect">Select number of nodes to generate
                    <input type="text" name="nodeCutoff" id="nodeCutoff">
                        <div class="grid-x grid-margin-x">
                            <div id="similaritySlider" class="cell small-10">
                                <div class="slider" data-slider data-start="10" data-initial-start="10" data-end="100" data-step="1">
                                <span class="slider-handle"  data-slider-handle role="slider" tabindex="1" aria-controls="nodeCutoff"></span>
                                <span class="slider-fill" data-slider-fill></span>
                                </div>
                            </div>
                        </div>
                    </label>
                    <!-- Network regeneration loading modal/animation -->
                    <div class="reveal tiny" id="networkRegLoadingModal" data-reveal data-options="close_on_background_click:false; close_on_esc: true;">
                        <p class="lead">Recreating network...</p>
                        <p>The network is being updated. Please do not use your browser's back button.</p>
                        <div class="row">
                            <div class="small-12 small-centered columns">
                                <div class="loader small-centered"></div>
                            </div>
                        </div>
                    </div>
                    <%-- --------------------------------- --%>
                    <input type="button" class="button" name="regenerate" value="Regenerate Network" data-open="networkRegLoadingModal" onclick="regenerateNetwork()"  />
                    <input type="hidden" name="currentOutputDir" id="currentOutputDir" value="${currentOutputDir}" />
                </form>
            </div>
        </div>
    </g:if>

        <%-- for SMILES or InChI, show table --%>
        <g:if test="${(resultSetModel.enrichAnalysisType == 'SMILES' && resultSetModel.smilesWithResults != []) 
        || (resultSetModel.enrichAnalysisType == 'SMILESSimilarity' && resultSetModel.smilesWithResults != [])
        || (resultSetModel.enrichAnalysisType == 'InChI' && resultSetModel.smilesWithResults != [])
        || (resultSetModel.enrichAnalysisType == 'InChISimilarity' && resultSetModel.smilesWithResults != [])}">
        <form action="enrich" method="post" id="enrichForm">
            <br>
            <h3>Re-enrich Selected Chemicals</h3>
            <br>
            <ul class="accordion" data-accordion data-multi-expand="false" data-allow-all-closed="true">
                <g:each var="dataSet" in="${casrnResults}">
                    <li class="accordion-item" data-accordion-item>
                        <a class="accordion-title">Set: ${dataSet.key}</a>
                            <div class="accordion-content" data-tab-content>
                                <div class="row">
                                    <div class="columns">
                                        <div class="table-scroll"> <!-- to allow table to horizontaly scroll if content overflows-->
                                            <table class="hover">
                                                <input style="display: none" type="text" name="setName" id="setName" value="${"{\"#"+dataSet.key+"\":\""+dataSet.value.id+"\"}"}" />
                                                <thead>
                                                    <tr>
                                                    <th width="150">Select</th>
                                                    <!-- <th width="150">Chemical Structure</th> -->
                                                    <th width="150">Name</th>
                                                    <th width="150">Structural Similarity (Tanimoto)</th>
                                                    <!-- <th width="150">Biological Similarity (Pearson)</th> -->
                                                    <th width="150">CASRN</th>
                                                    <!-- <th width="150">Mismatch Structure Alert</th> -->
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <g:each var="casrn" in="${dataSet.value}">
                                                        <tr>
                                                        <td><input type="checkbox" name="CASRNSChecked" id="CASRNSChecked" value="${casrn.id}" checked></td>
                                                        <!-- <td>[CHEMICAL STRUCTURE IMAGE GOES HERE]</td> -->
                                                        <td>${casrn.name}</td>
                                                        <td>${casrn.sim}</td>
                                                        <!-- <td>[not implemented yet]</td> -->
                                                        <td id="casrnToReenrich">${casrn.id}</td>
                                                        <!-- <td>[not implemented yet]</td> -->
                                                        </tr>
                                                    </g:each>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                    </li>
                </g:each>
            </ul>
            <br />

            <input type="button" class="button" name="reenrich" value="Re-Enrich Selected Chemicals" onclick="resubmitCasrns()" />                
            <input type="hidden" name="analysisType" id="analysisType" value="CASRNSReenrich" />
            <input type="hidden" name="transactionId" id="transactionId" value="none" />
            <input type="hidden" name="nodeCutoff" id="nodeCutoff" value="${nodeCutoff}" />
            <input type="hidden" name="CASRNBox" id="CASRNBox" value = "" />
            <g:each var="annoSet" in="${annoResults}"> 
                <input type="hidden" name="${annoSet.key}" id="${annoSet.key}" value="${annoSet.value}" />
            </g:each>

        </form>
        </g:if> 


    </div>

    <script type="text/javascript">
        $(document).foundation();
    </script>
    </body>
</html>
