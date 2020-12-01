<%--
  Created by IntelliJ IDEA.
  User: Larson
  Date: 7/19/2016
  Time: 6:30 PM
--%>
<!DOCTYPE html>
<%@ page import="tox21_test.ResultSetModelAnno" contentType="text/html;charset=UTF-8" %>
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
            //save UUID to JS variable for easy access
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

        </script>

        <title>Enrichment Results</title>
    </head>

    <body>

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
                        <g:each var="file" in="${fileSet.value}" >
                            <div class="small-3 column end"> 
                                <%-- display each result set file with tooltips --%>
                                <g:if test="${file.endsWith("ErrorCasrns.txt") && file.contains("__")}">
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" data-tooltip tabindex="0" title="This chemical does not have any annotations in Tox21 Enricher and/or is not a part of the Tox21 screening library.">${file}</g:link>
                                </g:if>
                                <g:else>
                                    <g:link controller="analysisResults" action="serveFile" params="[resultSet: resultSetModel.resultSet, filename: file]" data-tooltip tabindex="0" title="A list of annotations in Tox21 Enricher for this chemical.">${file}</g:link>
                                </g:else>
                            </div>
                        </g:each>
                    </div>
                </div>
            </li>
        </g:each>
        </ul>
        </div>
        <g:link uri="/analysisResults/downloadFile?resultSet=${resultSetModel.resultSet}&filename=tox21enricher.zip">Download Full Result Set (.zip)</g:link>

    </div>

    <script type="text/javascript">
        $(document).foundation();
    </script>
    </body>
</html>
