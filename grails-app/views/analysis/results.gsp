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

            function toggleAccordionsReenrich() {
                $("div.accordion").each(function() {
                    var isDown = $(this).data("tox21_isExpanded");
                    var direction = "up";
                    if (!isDown) {
                        direction = "down";
                    }
                    if (direction == "down") {
                        $("#btnToggleAccordionsReenrich").text("Collapse All");
                    } else {
                        $("#btnToggleAccordionsReenrich").text("Expand All");
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
                //Check if at least one checkbox is checked
                var minChecked = false;
                $("input[type=checkbox]").each(function() {
                    var isChecked = $(this).prop("checked");
                    if (isChecked) minChecked = true;
                });
                if (minChecked == true) {   //if yes, then perform enrichment
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
                else {  //if not, show warning
                    $('#reenrichWarning').show();
                }
            }

            //Toggle select/deselect all for reenrichment
            //todo: fix this so it doesn't work so weirdly with the other deselect button
            var selectMode = "deselect";
            var selectModeWarnings = "deselect";
            function selectAllReenrich() {       //toggle enrichment category checkboxes
                $("input[type=checkbox]").each(function() {
                    var isChecked = $(this).prop("checked");

                    //IF GOING TO DESELECT
                    if (isChecked && selectMode == "deselect") { //deselect
                        $(this).prop("checked", false);
                        $("#selectReenrichButton").text("Select All");
                        $("#selectWarningsButton").text("Select All With Warnings");
                    }

                    //IF GOING TO SELECT
                    if (!isChecked && selectMode == "select") { //select
                        $(this).prop("checked", true);
                        $("#selectReenrichButton").text("Deselect All");
                        $("#selectWarningsButton").text("Deselect All With Warnings");
                    }
                });
                if (selectMode == "deselect") {
                    selectMode = "select";
                    selectModeWarnings = "select";
                }
                else {
                    selectMode = "deselect";
                    selectModeWarnings = "deselect";
                }
            }

            //Toggle select/deselect only chemicals with hyperactive functional group warnings for reenrichment
            
            function selectAllWarnings() {       //toggle enrichment category checkboxes
                $("input[type=checkbox]").each(function() {
                    var isChecked = $(this).prop("checked");

                    //IF GOING TO DESELECT
                    if (isChecked && selectModeWarnings == "deselect" && $(this).hasClass("warnYes")) { //deselect
                        $(this).prop("checked", false);
                        $("#selectWarningsButton").text("Select All With Warnings");
                    }

                    //IF GOING TO SELECT
                    if (!isChecked && selectModeWarnings == "select"  && $(this).hasClass("warnYes")) { //select
                        $(this).prop("checked", true);
                        $("#selectWarningsButton").text("Deselect All With Warnings");
                    }
                });
                if (selectModeWarnings == "deselect") selectModeWarnings = "select";
                else selectModeWarnings = "deselect";
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
        <p>You will be directed to the results page shortly. Please do not use your browser's back button or close this page.</p>
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

        <button class="button" type="button" id="btnToggleAccordions" onclick="toggleAccordions();">Expand All</button>

        <div id="resultFile">
        <g:set var="count" value="${0}" />
        <ul class="accordion" data-accordion data-multi-expand="true" data-allow-all-closed="true">
        <g:each var="fileSet" in="${resultSetModel.sortedResultMap}">
            <li class="accordion-item" data-accordion-item>
                <a class="accordion-title">Set: ${fileSet.key}</a>
                <div class="accordion-content" data-tab-content>
                    <div class="row">
                        <div class="small-12 column">
                            <g:if test="${resultSetModel.enrichAnalysisType != 'CASRNS'}">
                                <h6>SMILES input: ${resultSetModel.smilesWithResults[count]}</h6>
                            </g:if>
                            <g:set var="count" value="${count + 1}" />
                        </div>
                    </div>
                    <div class="row">
                        <g:each var="file" in="${fileSet.value}" >
                            <div class="small-3 column end"> 
                                <%-- display each result set file with tooltips --%>
                                <%-- todo: do this in a way that's not so messy, or at least put it somewhere else --%>
                                <g:if test="${file.endsWith("Cluster.xls") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="downloadFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of significant terms in which functionally similar annotations are grouped together to remove redundancy. This is performed with respect to the whole annotation set rather than to individual annotation classes (.xls format).">${file}</g:link>
                                </g:if>

                                <g:elseif test="${file.endsWith("Cluster.txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of significant terms in which functionally similar annotations are grouped together to remove redundancy. This is performed with respect to the whole annotation set rather than to individual annotation classes (.txt format).">${file}</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("Chart.xls") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="downloadFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of all significant annotations (.xls format).">${file}</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("Chart.txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of all significant annotations in (.txt format).">${file}</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("ChartSimple.xls") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="downloadFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of the top 10 most signicant annotations for each annotation class (.xls format).">${file}</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("ChartSimple.txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of the top 10 most signicant annotations for each annotation class (.txt format).">${file}</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("Matrix.txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A text representation of the heatmap.">${file}</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("png")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.gctPerSetDir, filename: file]" target="_blank" data-tooltip tabindex="0" title="A heatmap image of the enrichment results.">
                                        <asset:image src="HeatMapIcon.jpg" width="50" height="50" />
                                    </g:link>
                                </g:elseif>

                                <g:elseif test="${!file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveInputFile" params="[resultSet: resultSetModel.resultSet, filename: file]" target="_blank" data-tooltip tabindex="0" title="A list of the submitted chemicals, displayed as CASRNs with corresponding names.">${fileSet.key} Input</g:link>
                                </g:elseif>

                                <g:elseif test="${file.endsWith("ErrorCasrns.txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" data-tooltip tabindex="0" title="CASRNs that did not produce any results.">${file}</g:link>
                                </g:elseif> 

                                <g:else>
                                    <g:link controller="analysisResults" action="downloadFile" params="[resultSet: resultSetModel.resultSet, filename: file]" >${file}</g:link>
                                </g:else>
                            </div>
                        </g:each>
                    </div>
                </div>
            </li>
        </g:each>
        </ul>
        </div>

        <g:if test="${resultSetModel.enrichAnalysisType != 'CASRNS' && resultSetModel.enrichAnalysisType != 'GetAnno' && resultSetModel.smilesNoResults.size > 0}">
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
                <form action="/tox21enricher/analysisResults/regenNetwork" method="post" id="regen">
                    <p>This will determine the maximum number of results per data set and may affect how many nodes are generated during network generation. (default = 10). Larger values may increase the time it takes to complete network generation</p>
                    <label id="chartSelect">
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
        <g:if test="${resultSetModel.enrichAnalysisType != "CASRNS" && resultSetModel.smilesWithResults.size > 0 && resultSetModel.images.size() > 0}">
        <form action="enrich" method="post" id="enrichForm">
            <br>
            <h3>Re-enrich Selected Chemicals</h3>
            <br>
            <label for="reenrichAccordion">Select CASRNs for re-enrichment:
                <button class="tiny button" type="button" id="btnToggleAccordionsReenrich" onclick="toggleAccordionsReenrich();">Expand All</button>
                <button class="tiny button" id="selectReenrichButton" type="button" onclick = "selectAllReenrich()">Deselect All</button>
                <g:if test="${reactiveResults.size() > 0}">
                    <button class="tiny button" id="selectWarningsButton" type="button" onclick = "selectAllWarnings()">Deselect All With Warnings</button>
                </g:if>
            </label>
            <div class="accordion" id="reenrichAccordion" data-accordion data-multi-expand="true" data-allow-all-closed="true">
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
                                                    <th width="50">Select</th>
                                                    <th width="100" title="Click the chemical's image to view more details.">Chemical Structure</th>
                                                    <th width="200" title="A common name for the chemical.">Name</th>
                                                    <g:if test="${resultSetModel.enrichAnalysisType == 'SMILESSimilarity' || resultSetModel.enrichAnalysisType == 'InChISimilarity'}">
                                                        <th width="50" title="A measurement of how structurally similar this chemical is to the submitted chemical using a Tanimoto threshold.">Structural Similarity (Tanimoto)</th>
                                                    </g:if>
                                                    <!-- <th width="150">Biological Similarity (Pearson)</th> -->
                                                    <th width="50" word-break="break-all" title="The chemical's representation in SMILES notation.">SMILES</th>
                                                    <th width="50" title="The chemical's representation in CASRN notation, matching the one found in the EPA's CompTox Chemicals Dashboard.">CASRN</th>
                                                    <g:set var="foundMismatch" value="${false}" />
                                                    <g:each var="casrn" in="${dataSet.value}">
                                                        <g:if test="${reactiveResults.size() > 0 && foundMismatch == false}">
                                                            <g:each var="reactive" in="${reactiveResults}">
                                                                <g:if test="${reactive.casrn == casrn.id}">
                                                                    <th width="50" title="A warning explaining that a known, functionally hyperactive group(s) appears only in either the chemical you submitted or at least one of its results. It is recommended that you deselect any chemicals with this warning and perform re-enrichment.">Mismatch Structure Alert</th>
                                                                    <g:set var="foundMismatch" value="${true}" />
                                                                </g:if>
                                                            </g:each>
                                                        </g:if>
                                                    </g:each>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <g:each var="casrn" in="${dataSet.value}">
                                                        <tr>
                                                        <td>
                                                            <!-- from ResultsTagLib -->
                                                            <g:eachReactive reactive="${reactiveResults}" check="${casrn.id}" /> 
                                                        </td>
                                                        <td>
                                                            <g:set var="structureExists" value="${new File("/home/hurlab/tox21/grails-app/assets/images/structures/${casrn.id}.png").exists()}"></g:set>
                                                            <g:if test="${structureExists}">
                                                                <asset:image src="structures/${casrn.id}.png" width="75" height="75" data-open="${casrn.id}" onmouseover="" style="cursor: pointer;" />
                                                                <div class="reveal small" id="${casrn.id}" data-reveal data-options="close_on_background_click:true; close_on_esc: true;">
                                                                    <div class="row">
                                                                        <div class="medium-6 columns">
                                                                            <asset:image src="structures/${casrn.id}.png" width="500" height="500" />
                                                                        </div>
                                                                        <div class="medium-6 columns">
                                                                            <p class="lead">${casrn.name}</p>
                                                                            <div class="table-scroll">
                                                                                <table class="hover">
                                                                                <thead></thead>
                                                                                <tbody>
                                                                                    <tr>
                                                                                        <g:if test="${casrn.iupac != "none"}">
                                                                                            <td><b>IUPAC Name</b></td>
                                                                                            <td>${casrn.iupac}</td>
                                                                                        </g:if>
                                                                                    </tr>
                                                                                    <tr>
                                                                                        <td><b>CASRN</b></td>
                                                                                        <td>${casrn.id}</td>
                                                                                    </tr>
                                                                                    <tr>
                                                                                        <td><b>SMILES</b></td>
                                                                                        <td>${casrn.smiles}</td>
                                                                                    </tr>
                                                                                    <tr>
                                                                                        <g:if test="${casrn.inchi != "none"}">
                                                                                            <td><b>InChI</b></td>
                                                                                            <td>${casrn.inchi}</td>
                                                                                        </g:if>
                                                                                    </tr>
                                                                                    <tr>
                                                                                        <g:if test="${casrn.inchikey != "none"}">
                                                                                            <td><b>InChI Key</b></td>
                                                                                            <td>${casrn.inchikey}</td>
                                                                                        </g:if>
                                                                                    </tr>
                                                                                    <tr>
                                                                                        <g:if test="${casrn.formula != "none"}">
                                                                                            <td><b>Molecular Formula</b></td>
                                                                                            <td>${casrn.formula}</td>
                                                                                        </g:if>
                                                                                    </tr>
                                                                                    <tr>
                                                                                        <g:if test="${casrn.weight != "none"}">
                                                                                            <td><b>Molecular Weight</b></td>
                                                                                            <td>${casrn.weight}</td>
                                                                                        </g:if>
                                                                                    </tr>
                                                                                </tbody>
                                                                                </table>
                                                                            </div>
                                                                            <g:if test="${casrn.cid != "none"}">
                                                                                <p><a href="https://pubchem.ncbi.nlm.nih.gov/compound/${casrn.cid}" target="_blank">View at PubChem</a></p>
                                                                            </g:if>
                                                                            <g:if test="${casrn.dtxsid != "none"}">
                                                                                <p><a href="https://comptox.epa.gov/dashboard/dsstoxdb/results?abbreviation=TOX21SL&search=${casrn.dtxsid}" target="_blank">View at EPA</a></p>
                                                                            </g:if>
                                                                        </div>
                                                                    </div>
                                                                    <div class="row">
                                                                        <button class="close-button" data-close aria-label="Close modal" type="button">
                                                                            <span aria-hidden="true">&times;</span>
                                                                        </button>
                                                                    </div>
                                                                </div>
                                                            </g:if>
                                                            <g:if test="${!structureExists}">
                                                                <asset:image src="structures/no_img.png" width="75" height="75" />
                                                            </g:if>
                                                        </td>
                                                        <td>${casrn.name}</td>
                                                        <g:if test="${resultSetModel.enrichAnalysisType == 'SMILESSimilarity' || resultSetModel.enrichAnalysisType == 'InChISimilarity'}">
                                                            <td>${casrn.sim}</td>
                                                        </g:if>
                                                        <!-- <td>[not implemented yet]</td> -->
                                                        <td>${casrn.smiles}</td>
                                                        <td id="casrnToReenrich">${casrn.id}</td>
                                                        <g:if test="${reactiveResults.size() > 0}">
                                                            <g:each var="reactive" in="${reactiveResults}">
                                                                <g:if test="${reactive.casrn == casrn.id}">
                                                                    <td>
                                                                    <p style="color:red" data-tooltip tabindex="0" title="Warning: either this chemical contains a known reactive group(s) (${reactive.warn}) while your original submission did not, or this chemical does not contain a known reactive group(s) (${reactive.warn}) that your original submission contained. It is recommended that you deselect this chemical and perform re-enrichment on your data set."><i>${reactive.warn}</i></p>
                                                                    </td>
                                                                </g:if>
                                                            </g:each>
                                                        </g:if>
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
            </div>
            <br>
            <p name="reenrichWarning" id="reenrichWarning" style="color:red;display:none">At least one chemical must be selected to perform re-enrichment.</p>
            <br>
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
