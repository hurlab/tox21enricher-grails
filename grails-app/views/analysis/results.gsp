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

        <script>
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
        </script>

        <title>Enrichment Results</title>
    </head>

    <body>
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

        <g:if test="${resultSetModel.enrichAnalysisType == 'SMILES'}">
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

        
        <%-- for SMILES, show table --%> <%--
        <g:if test="${resultSetModel.enrichAnalysisType == 'SMILES' && resultSetModel.smilesWithResults != []}">
            <div class="table-scroll"> <!-- to allow table to horizontaly scroll if content overflows-->
                <table class="hover">
                    <thead>
                        <tr>
                        <th width="150">Select</th>
                        <th>Chemical Structure</th>
                        <th width="150">Name</th>
                        <th width="150">Structural Similarity (Tanimoto)</th>
                        <th width="150">Biological Similarity (Pearson)</th>
                        <th width="150">SMILES</th>
                        <th width="150">CASRN</th>
                        <th width="150">Mismatch Structure Alert</th>
                        </tr>
                    </thead>
                    <tbody>
                        <g:each var="smileWithResults" in="${resultSetModel.smilesWithResults}">
                            <tr>
                            <td><input type="checkbox" name="selectSmile" value="selectSmile" id="selectSmile" required></td>
                            <td>[CHEMICAL STRUCTURE IMAGE GOES HERE]</td>
                            <td>[NAME]</td>
                            <td>[0.5]</td>
                            <td>[0.5]</td>
                            <td>${smileWithResults}</td>
                            <td>[CASRN]</td>
                            <td>X</td>
                            </tr>
                        </g:each>
                    </tbody>
                </table>
            </div>
            <br />
            <g:link class="button">Re-Enrich Selected Chemicals</g:link>
        </g:if> --%>

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
    
    <script type="text/javascript">
        $(document).foundation();
    </script>
    </body>
</html>
