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

        <script>
            function toggleAccordions() {
                $("ul.accordion").each(function() {
                    var isDown = $(this).data("tox21_isExpanded");
                    var direction = "up";
                    if (!isDown)
                        direction = "down";

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
        </script>

        <title>Enrichment Results</title>
    </head>

    <body>
        <h5>Enrichment Results</h5>

        <button class="button" type="button" id="btnToggleAccordions" onclick="toggleAccordions();">Expand All</button>

        <g:set var="count" value="${0}" />
        <ul class="accordion" data-accordion data-multi-expand="true" data-allow-all-closed="true">
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

        <g:if test="${resultSetModel.numSets >= 2}">
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
                    <g:link class="button" controller="analysisResults" action="createNetwork" params="[resultSet: resultSetModel.resultSet, network: 1, numSets: resultSetModel.numSets, qval: 0.05]">Begin Chart Full Network Creation</g:link>
                </div>

                <div class="small-6 column" >
                    <g:link class="button" controller="analysisResults" action="createNetwork" params="[resultSet: resultSetModel.resultSet, network: 2, numSets: resultSetModel.numSets, qval: 0.05]">Begin Cluster Network Creation</g:link>
                </div>
            </div>
        </g:if>
        <br />

        <g:link uri="/analysisResults/downloadFile?resultSet=${resultSetModel.resultSet}&filename=tox21enricher.zip">Download Full Result Set (zip)</g:link>
        <br />
    <script type="text/javascript">
        $(document).foundation();
    </script>
    </body>
</html>
