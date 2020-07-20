<!DOCTYPE html>

<html>

<head>

    <title>Tox21 Enrichment Analysis</title>
    <meta name="layout" content="main" />
	
    <asset:javascript src="enrichmentForm.js" />
<%-- may want to look for an alternative for the jquery form validator as it is no longer being developed --%>
    <script src="//cdnjs.cloudflare.com/ajax/libs/jquery-form-validator/2.3.26/jquery.form-validator.min.js"></script> 

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

        function exampleSmile() {
            var setSmile = "CC(=O)C1=CC=C(C=C1)[N+]([O-])\n" +
                    "ClCC1=CC=CC=C1\n" +
                    "CN(C)C1=CC=C(C=C1)\n";
            document.getElementById("SMILEBox").value= setSmile;
        }
        function exampleInchi() {
            var setInchi =  "#TestSet1\n" +
                            "AOXRBFRFYPMWLR-XGXHKTLJSA-N\n" +
                            "UYIFTLBWAOGQBI-BZDYCCQFSA-N\n" +
                            "RSEPBGGWRJCQGY-RBRWEJTLSA-N\n" +
                            "FHXBMXJMKMWVRG-SLHNCBLASA-N\n" +
                            "LHHGDZSESBACKH-UHFFFAOYSA-N\n" +
                            "#TestSet2\n" +
                            "MBMQEIFVQACCCH-QBODLPLBSA-N\n" +
                            "ONKUMRGIYFNPJW-KIEAKMPYSA-N\n" +
                            "PWZUUYSISTUNDW-VAFBSOEGSA-N\n" +
                            "UOACKFBJUYNSLK-XRKIENNPSA-N\n" +
                            "RFWTZQAOOLFXAY-BZDYCCQFSA-N\n" +
                            "YTSDTJNDMGOTFN-UHFFFAOYSA-M\n";

            document.getElementById("InChIBox").value= setInchi;
        }

        function exampleSmileSimilarity() {
            var setSmile = "CC(=O)C1=CC=C(C=C1)[N+]([O-])\n" +
                    "ClCC1=CC=CC=C1\n" +
                    "CN(C)C1=CC=C(C=C1)\n";
            document.getElementById("SMILESimilarityBox").value= setSmile;
        }

        function exampleInchiSimilarity() {
            var setInchi =  "#TestSet1\n" +
                            "AOXRBFRFYPMWLR-XGXHKTLJSA-N\n" +
                            "UYIFTLBWAOGQBI-BZDYCCQFSA-N\n" +
                            "RSEPBGGWRJCQGY-RBRWEJTLSA-N\n" +
                            "FHXBMXJMKMWVRG-SLHNCBLASA-N\n" +
                            "LHHGDZSESBACKH-UHFFFAOYSA-N\n" +
                            "#TestSet2\n" +
                            "MBMQEIFVQACCCH-QBODLPLBSA-N\n" +
                            "ONKUMRGIYFNPJW-KIEAKMPYSA-N\n" +
                            "PWZUUYSISTUNDW-VAFBSOEGSA-N\n" +
                            "UOACKFBJUYNSLK-XRKIENNPSA-N\n" +
                            "RFWTZQAOOLFXAY-BZDYCCQFSA-N\n" +
                            "YTSDTJNDMGOTFN-UHFFFAOYSA-M\n";

            document.getElementById("InChISimilarityBox").value= setInchi;
        }

        function singleSet() {
            var set1 = "965-90-2\n" +
                    "50-50-0\n" +
                    "979-32-8\n" +
                    "4245-41-4\n" +
                    "143-50-0\n" +
                    "17924-92-4\n"+
                    "297-76-7\n" +
                    "152-43-2\n" +
                    "313-06-4\n" +
                    "4956-37-0\n" +
                    "112400-86-9";
            document.getElementById("CASRNBox").value= set1;
            CASRNBox.value= set1;
        }

        function multiSet() {
            var setMany = "#BPA analogs\n" +
                            "2081-08-5\n" +
                            "2467-02-9\n" +
                            "1478-61-1\n" +
                            "41481-66-7\n" +
                            "5613-46-7\n" +
                            "57-63-6\n" +
                            "620-92-8\n" +
                            "77-40-7\n" +
                            "79-94-7\n" +
                            "79-95-8\n" +
                            "79-97-0\n" +
                            "80-05-7\n" +
                            "80-09-1\n" +
                            "843-55-0\n" +
                            "94-18-8\n\n" +

                            "#Flame retardants\n" +
                            "115-86-6\n" +
                            "115-96-8\n" +
                            "1241-94-7\n" +
                            "1330-78-5\n" +
                            "13674-87-8\n" +
                            "29761-21-5\n" +
                            "5436-43-1\n" +
                            "56803-37-3\n" +
                            "68937-41-7\n" +
                            "78-30-8\n" +
                            "79-94-7\n\n" +

                            "#PAH\n" +
                            "120-12-7\n" +
                            "129-00-0\n" +
                            "191-24-2\n" +
                            "206-44-0\n" +
                            "218-01-9\n" +
                            "50-32-8\n" +
                            "53-70-3\n" +
                            "56-55-3\n" +
                            "83-32-9\n" +
                            "85-01-8\n";

            document.getElementById("CASRNBox").value = setMany;
            CASRNBox.value= setMany;
        }

        function clearText() {
            document.getElementById("CASRNBox").value= "";
            CASRNBox.value= "";
        }

        var isPerformingEnrichment = false;

        function submitSmiles() {
            document.getElementById("analysisType").value = "SMILES";
            document.getElementById("transactionId").value = transactionId;
            $('#main').hide();
            $('#wait').show();
            isPerformingEnrichment = true;
            $('#enrichForm').submit();
        }

        function submitInchi() {
            document.getElementById("analysisType").value = "InChI";
            document.getElementById("transactionId").value = transactionId;
            $('#main').hide();
            $('#wait').show();
            isPerformingEnrichment = true;
            $('#enrichForm').submit();
        }

        function submitSmilesSimilarity() {
            document.getElementById("analysisType").value = "SMILESSimilarity";
            document.getElementById("transactionId").value = transactionId;
            $('#main').hide();
            $('#wait').show();
            isPerformingEnrichment = true;
            $('#enrichForm').submit();
        }

        function submitInchiSimilarity() {
            document.getElementById("analysisType").value = "InChISimilarity";
            document.getElementById("transactionId").value = transactionId;
            $('#main').hide();
            $('#wait').show();
            isPerformingEnrichment = true;
            $('#enrichForm').submit();
        }

        function submitCasrns() {
            document.getElementById("analysisType").value = "CASRNS";
            document.getElementById("transactionId").value = transactionId;
            $('#main').hide();
            $('#wait').show();
            isPerformingEnrichment = true;
            $('#enrichForm').submit();
        }

        var simCustom = false;

        function toggleSimilarity() {
            //activate manual textbox input
            if (simCustom === false) {
                $("#thresholdSelectValueManual").show();
                $("#thresholdSelectValue").hide();
                $("#similaritySlider").hide();
                $("#btnSimCustom").text("Pick");
                simCustom = true;
            }
            //activate slider input
            else if (simCustom === true) {
                $("#thresholdSelectValueManual").val("").change();
                $("#thresholdSelectValue").show();
                $("#similaritySlider").show();
                $("#thresholdSelectValueManual").hide();
                $("#btnSimCustom").text("Custom");
                simCustom = false;
            }
        }

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

        function toggleCategories() {       //toggle enrichment category checkboxes
            $("input[type=checkbox]").each(function() {
                var isChecked = $(this).data("tox21_isChecked");
                var doCheck = true;
                if (!isChecked)
                    doCheck = false;

                if(doCheck == true) {
                    $("#btnToggleCategories").text("Deselect All");
                } else {
                    $("#btnToggleCategories").text("Select All");
                }

                $(this).data("tox21_isChecked", !$(this).data("tox21_isChecked"));
                if ($(this).attr('id') != "goBiop") {
                    $(this).prop('checked', doCheck);
                }
            });
        }

        var substructureInputSMILES = true;   //true = currently smiles, false = currently inchi
        function toggleSubstructureSearch () { //for shared substructure search, toggle between SMILES and InChI input
            if(substructureInputSMILES == true) {  //if currently SMILES, switch to InChI
                $('#smileBoxContainer').hide();
                $('#inchiBoxContainer').show();
                $('#toggleSubstructureSearchButton').text("Switch to SMILES input");
                $('#SMILEBox').val("");
                $('#smileSubmitContainer').hide();
                $('#inchiSubmitContainer').show();
                substructureInputSMILES = false;
            }
            else {                              //if currently InChI, switch to SMILES
                $('#inchiBoxContainer').hide();
                $('#smileBoxContainer').show();
                $('#toggleSubstructureSearchButton').text("Switch to InChI input");
                $('#InChIBox').val("");
                $('#inchiSubmitContainer').hide();
                $('#smileSubmitContainer').show();
                substructureInputSMILES = true;
            }

        }

        var substructureSimilarityInputSMILES = true;   //true = currently smiles, false = currently inchi
        function toggleSubstructureSimilaritySearch () { //for shared substructure search, toggle between SMILES and InChI input
            if(substructureSimilarityInputSMILES == true) {  //if currently SMILES, switch to InChI
                $('#smileSimilarityBoxContainer').hide();
                $('#inchiSimilarityBoxContainer').show();
                $('#toggleSubstructureSimilaritySearchButton').text("Switch to SMILES input");
                $('#SMILESimilarityBox').val("");
                $('#smileSimilaritySubmitContainer').hide();
                $('#inchiSimilaritySubmitContainer').show();
                substructureSimilarityInputSMILES = false;
            }
            else {                              //if currently InChI, switch to SMILES
                $('#inchiSimilarityBoxContainer').hide();
                $('#smileSimilarityBoxContainer').show();
                $('#toggleSubstructureSimilaritySearchButton').text("Switch to InChI input");
                $('#InChISimilarityBox').val("");
                $('#inchiSimilaritySubmitContainer').hide();
                $('#smileSimilaritySubmitContainer').show();
                substructureSimilarityInputSMILES = true;
            }

        }
        
        //Periodically refresh the waiting page to update queue position and transaction status
        setInterval(function(){
            if(isPerformingEnrichment === true) {
                $('#waittable').load("http://localhost:8080/tox21enricher/analysis/getQueueData?tid="+transactionId+" #waittable");
                //$('#waittable').load("http://134.129.166.26:8080/tox21enricher/analysis/getQueueData?tid="+transactionId+" #waittable");
            }
        }, 2000);

    </script>
</head>
<body>
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
                    <th width="150">Items Submitted</th>
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
                    <td>${items}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <br />
    </div>

    <div id="main">
        <form action="analysis/enrich" method="post" id="enrichForm">
            <div class="row" id="checkboxes">
                <br>

                Please see <g:link controller="analysisResults" action="serveUserManual" params="[filename: 'Tox21Enricher_Manual_v2.1.pdf']" target="_blank">this link </g:link> for instructions on using this application and the descriptions about the chemical/biological categories. Other resources from the Tox21 toolbox can be viewed <g:link url="https://ntp.niehs.nih.gov/results/tox21/tbox/">here.</g:link>
                <br>
                <div class="accordion" id="categoriesHeader">
                    <h3>Select chemical/biological annotation categories</h3>

                    <button class="button" type="button" id="btnToggleCategories" onclick="toggleCategories();">Deselect All</button>

                </div>

            </div>
            <div class="row">
                <div class="columns">
                    <br>
                    <h3>Enrich From...</h3>
                    <p>Note: Please verify you are using the correct chemical identifiers by referencing the <a href="https://comptox.epa.gov/dashboard">EPA's CompTox Chemicals Dashboard.</a> </p>
                </div>
            </div>

            <div class="row">
                <div class="columns">
                    <ul class="tabs" data-tabs id="example-tabs">
                        <li class="tabs-title is-active"><a href="#panel1" aria-selected="true">User Provided CASRN List</a></li>
                        <li class="tabs-title"><a href="#panel2">Chemicals With Shared Substructures</a></li>
                        <li class="tabs-title"><a href="#panel3">Chemicals With Structural Similarity</a></li>
                        <!-- <li class="tabs-title"><a href="#panel4">Chemicals With Biological Similarity</a></li>  -->
                    </ul>

                <%--User Provided CASRN List--%>
                    <div class="tabs-content" data-tabs-content="example-tabs">
                        <div class="tabs-panel is-active" id="panel1">
                            <h4>User Provided CASRN List</h4>
                            <label for="CASRNBox">Add '#SetName' before each set, if using multiple sets at once. Ex)
                                <button class="tiny button" type="button" onclick = "singleSet()">Single Set</button>
                                <button class="tiny button" type="button" onclick ="multiSet()">Multiple Sets</button>
                                <g:if test="${isCasrnErrors}">
                                    <g:textArea class="extralarge" name="CASRNBox" ><%--
                                --%><g:each in="${goodCasrns}">
                                    <%--                                --%>${it}<%--
                                --%></g:each><%--
                            --%></g:textArea>
                                    <g:each in="${errorCasrns}">
                                        <p style="color:red">Invalid CASRN "${it.casrn}" on line ${it.index + 1}</p>
                                    </g:each>
                                    <g:if test="${noCasrnInput}">
                                        <p style="color:red">Input is required to perform enrichment</p>
                                    </g:if>
                                </g:if>
                                <g:else>
                                    <g:textArea class="extralarge" name="CASRNBox" ></g:textArea>
                                    <br>
                                </g:else>
                                <input type="button" class="button" name="begin" value="Begin Enrichment Analysis" onclick="submitCasrns()" />
                            </label>

                        </div>

                    <%--Chemicals w/ Shared Substructures (SMILES/InChI)--%>
                        <div class="tabs-panel" id="panel2">
                            <h4>Chemicals With Shared Substructures</h4>

                            <%-- <input type="radio" name="smilesSearchType" value="Substructure" id="substructureRadio"><label for="substructureRadio">Substructure</label> --%>

                            <button class="button" type="button" id="toggleSubstructureSearchButton" onclick="toggleSubstructureSearch()">Switch to InChI input</button>
                            <br>

                            <%-- SMILES Box --%>
                            <div id="smileBoxContainer">   

                                <label for="SMILEBox">Enter partial or complete SMILES strings, one per line. Ex)
                                    <button class="tiny button" type="button" onclick = "exampleSmile()">SMILES strings</button>
                                </label>

                                <g:if test="${isSmileErrors}">
                                    <!--This line is all on one line with no whitespace because of the way the textArea is being populated.-->
                                    <g:textArea class="extralarge" name="SMILEBox" ><%--
                                --%><g:each in="${psqlGoodSmiles}">
                                    <%--                            --%>${it.smile}<%--
                                --%></g:each><%--
                        --%></g:textArea>
                                    <g:each in="${psqlErrorSmiles}">
                                        <p style="color:red">Invalid SMILE "${it.smile}" on line ${it.index + 1}</p>
                                    </g:each>
                                    <g:if test="${noSmileInput}">
                                        <p style="color:red">Input is required to perform enrichment</p>
                                    </g:if>
                                </g:if>
                                <g:else>
                                    <g:textArea class="extralarge" name="SMILEBox" id="SMILEBox" ></g:textArea>
                                    <br>
                                </g:else>
                            </div>

                            <%-- InChI Box --%>
                            <div id="inchiBoxContainer" style="display: none">
                                <label for="InChIBox">Enter InChI strings, one per line. Add '#SetName' before each set, if using multiple sets at once. Ex)
                                    <button class="tiny button" type="button" onclick = "exampleInchi()">InChi strings</button>
                                </label>
                                <g:textArea class="extralarge" name="InChIBox" id="InChIBox" ></g:textArea>
                                <br>
                            </div>

                            <div id="smileSubmitContainer">
                                <input type="button" class="button" name="begin" value="Begin Enrichment Analysis" onclick="submitSmiles()"  />
                            </div>
                            <div id="inchiSubmitContainer" style="display: none">
                                <input type="button" class="button" name="begin" value="Begin Enrichment Analysis" onclick="submitInchi()"  />
                            </div>
                        </div>

                    <%--Chemicals w/ Structural Similarity (SMILES)--%>
                        <div class="tabs-panel" id="panel3">
                                <h4>Chemicals With Structural Similarity</h4>
                                
                                <!-- <input type="radio" name="smilesSearchType" value="Similarity" id="similarityRadio"><label for="similarityRadio">Similarity</label> -->
                                <div>
                                    <label id="thresholdSelect">Select similarity threshold (%)
                                            <input type="text" name="thresholdSelectValue" id="thresholdSelectValue">
                                                <div class="grid-x grid-margin-x">
                                                <div id="similaritySlider" class="cell small-10">
                                                    <div class="slider" data-slider data-start="1" data-initial-start="50" data-end="100" data-step="1" data-decimal="2">
                                                    <span class="slider-handle"  data-slider-handle role="slider" tabindex="1" aria-controls="thresholdSelectValue"></span>
                                                    <span class="slider-fill" data-slider-fill></span>
                                                    </div>
                                                </div>
                                                </div>
                                    </label>
                                </div>

                                
                                <button class="button" type="button" id="toggleSubstructureSimilaritySearchButton" onclick="toggleSubstructureSimilaritySearch()">Switch to InChI input</button>
                                <br>

                                <%-- SMILES Box --%>
                                <div id="smileSimilarityBoxContainer"> 

                                    <label for="SMILEStructuralBox">Enter partial or complete SMILES strings, one per line Ex)
                                        <button class="tiny button" type="button" onclick = "exampleSmileSimilarity()">SMILES strings</button>
                                    </label>
                                    
                                    <g:if test="${isSmileErrors}">
                                        <!--This line is all on one line with no whitespace because of the way the textArea is being populated.-->
                                        <g:textArea class="extralarge" name="SMILESimilarityBox" ><%--
                                    --%><g:each in="${psqlGoodSmiles}">
                                        <%--                            --%>${it.smile}<%--
                                    --%></g:each><%--
                            --%></g:textArea>
                                        <g:each in="${psqlErrorSmiles}">
                                            <p style="color:red">Invalid SMILE "${it.smile}" on line ${it.index + 1}</p>
                                        </g:each>
                                        <g:if test="${noSmileInput}">
                                            <p style="color:red">Input is required to perform enrichment</p>
                                        </g:if>
                                    </g:if>
                                    <g:else>
                                        <g:textArea class="extralarge" name="SMILESimilarityBox" ></g:textArea>
                                        <br>
                                    </g:else>
                                </div>

                            <%-- InChI Box --%>
                            <div id="inchiSimilarityBoxContainer" style="display: none">
                                <label for="InChISimilarityBox">Enter InChI strings, one per line. Add '#SetName' before each set, if using multiple sets at once. Ex)
                                    <button class="tiny button" type="button" onclick = "exampleInchiSimilarity()">InChi strings</button>
                                </label>
                                <g:textArea class="extralarge" name="InChISimilarityBox" id="InChISimilarityBox" ></g:textArea>
                                <br>
                            </div>

                            <div id="smileSimilaritySubmitContainer">
                                <input type="button" class="button" name="begin" value="Begin Enrichment Analysis" onclick="submitSmilesSimilarity()"  />
                            </div>
                            <div id="inchiSimilaritySubmitContainer" style="display: none">
                                <input type="button" class="button" name="begin" value="Begin Enrichment Analysis" onclick="submitInchiSimilarity()"  />
                            </div>


                            </div>
                        
                        <%--Chemicals w/ Biological Similarity (SMILES)--%> <%--
                            <div class="tabs-panel" id="panel4">
                                    <h4>Chemicals With Biological Similarity</h4>

                            </div>
                        --%>

                        </div>
                        <%-- Slider for selecting cutoff for how many nodes to generate during network generation--%>
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
                
                    </div>
                </div>
            </div>
        </div>
            <input type="hidden" name="analysisType" id="analysisType" value="CASRNS" />
            
            <input type="hidden" name="transactionId" id="transactionId" value="none">
        </form>
    </div>
</body>
</html>
