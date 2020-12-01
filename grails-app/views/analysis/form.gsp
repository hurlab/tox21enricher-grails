<!DOCTYPE html>

<html>

<head>

    <title>Tox21 Enrichment Analysis</title>
    <meta name="layout" content="main" />
	
    <asset:javascript src="enrichmentForm.js" />
<%-- may want to look for an alternative for the jquery form validator as it is no longer being developed --%>
    <script src="//cdnjs.cloudflare.com/ajax/libs/jquery-form-validator/2.3.26/jquery.form-validator.min.js"></script> 

    <%-- JSME --%>
    <asset:javascript src="JSME_2020-06-11/jsme/jsme.nocache.js" />

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
        //set url to root. This is so stuff doesn't get broken if enrichment processes return errors
        window.history.pushState("", "", '/tox21enricher/');

        //save UUID to JS variable for easy access
        var transactionId = "<%=tid%>";

        //this function will be called after the JavaScriptApplet code has been loaded.
        function jsmeOnLoad() {
            jsmeApplet = new JSApplet.JSME("jsme_container", "380px", "340px");
        }

        var jsmeOpen = false;
        function openJsme() {
            if (jsmeOpen == false) {
                $('#jsme_container').show();
                $('#jsmeInstructions').show();
                $('#drawButtonSubstructure').text("Hide JSME");
                $('#drawButtonSimilarity').text("Hide JSME");
                jsmeOpen = true;
            }
            else {
                $('#jsme_container').hide();
                $('#jsmeInstructions').hide();
                $('#drawButtonSubstructure').text("Draw chemical with JSME");
                $('#drawButtonSimilarity').text("Draw chemical with JSME");
                jsmeOpen = false;
            }
        }      

        function exampleSmile() {
            var setSmile = "CC(=O)C1=CC=C(C=C1)[N+]([O-])\n" +
                    "ClCC1=CC=CC=C1\n" +
                    "CN(C)C1=CC=C(C=C1)\n";
            document.getElementById("SMILEBox").value= setSmile;
        }
        function exampleInchi() {
            var setInchi =  "InChI=1S/C8H7NO2/c1-6(10)7-2-4-8(9-11)5-3-7/h2-5H,1H3\n" +
                            "InChI=1S/C7H7Cl/c8-6-7-4-2-1-3-5-7/h1-5H,6H2\n" +
                            "InChI=1S/C8H11N/c1-9(2)8-6-4-3-5-7-8/h3-7H,1-2H3\n";
            document.getElementById("InChIBox").value= setInchi;
        }

        function exampleSmileSimilarity() {
            var setSmile = "COCCOC(=O)CC#N\n" +             //cyanide w/o warnings
                    "C1=CC=C(C=C1)CSC#N\n" +                //cyanide warning
                    "C1OC1C1=CC=CC=C1\n" +                  //epoxide warning
                    "CC1(C)CC(CC(C)(CN=C=O)C1)N=C=O\n" +    //isocyanate warning
                    "OC(=O)C(\\Cl)=C(\\Cl)C=O\n" +          //aldehyde warning
                    "CN(C)C1=CC=C(C=C1)\n";                 //no warnings
            document.getElementById("SMILESimilarityBox").value= setSmile;
        }

        function exampleInchiSimilarity() {
            var setInchi =  "InChI=1S/C8H7NO2/c1-6(10)7-2-4-8(9-11)5-3-7/h2-5H,1H3\n" +
                            "InChI=1S/C7H7Cl/c8-6-7-4-2-1-3-5-7/h1-5H,6H2\n" +
                            "InChI=1S/C8H11N/c1-9(2)8-6-4-3-5-7-8/h3-7H,1-2H3\n";
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

        //TODO: this function was here already, but I'm not sure if it is being used
        function clearText() {
            document.getElementById("CASRNBox").value= "";
            CASRNBox.value= "";
        }

        //clear boxes
        function clearInputCasrn() {
            document.getElementById("CASRNBox").value="";
            CASRNBox.value= "";
        }

        function clearInputSmileSubstructure() {
            document.getElementById("SMILEBox").value= "";
        }

        function clearInputInchiSubstructure() {
            document.getElementById("InChIBox").value= "";
        }

        function clearInputSmileSimilarity() {
            document.getElementById("SMILESimilarityBox").value= "";
        }

        function clearInputInchiSimilarity() {
            document.getElementById("InChISimilarityBox").value= "";
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

        function getAnnotations() {
            document.getElementById("analysisType").value = "Annotation";
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
        
        //Periodically refresh the waiting page to update queue position and transaction status
        setInterval(function() {
            if (isPerformingEnrichment === true) {
                $('#waittable').load("analysis/getQueueData?tid="+transactionId+" #waittable");
                $('#submittedItemsList').load("analysis/getQueueData?tid="+transactionId+" #submittedItemsList");
            }
        }, 2000);

    </script>
</head>
<body>
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

    <div id="main">
        <form action="/tox21enricher/analysis/enrich" method="post" id="enrichForm">
            <div class="row" id="checkboxes">
                <br>
                Please see <g:link controller="analysisResults" action="serveUserManual" params="[filename: 'Tox21Enricher_Manual_v3.3.1.pdf']" target="_blank">this link </g:link> for instructions on using this application and the descriptions about the chemical/biological categories. Other resources from the Tox21 toolbox can be viewed <g:link url="https://ntp.niehs.nih.gov/results/tox21/tbox/">here.</g:link>
                <br>
                <div class="accordion" id="categoriesHeader">
                    <h3>Select chemical/biological annotation categories</h3>

                    <button class="button" type="button" id="btnToggleAccordions" onclick="toggleAccordions();">Expand All</button>
                    <button class="button" type="button" id="btnToggleCategories" onclick="toggleCategories();">Deselect All</button>

                </div>
            </div>

            <div class="row">
                <div class="columns">
                    <br>
                    <%-- Slider for selecting cutoff for how many nodes to generate during network generation--%>
                    <h3>Select enrichment cutoff</h3>
                    <p>This will determine the maximum number of results per data set and may affect how many nodes are generated during network generation. (default = 10). Larger values may increase the time it takes to complete the enrichment process.</p>
                    <br>
                    <label id="chartSelect">
                    <input type="text" name="nodeCutoff" id="nodeCutoff">
                        <div class="grid-x grid-margin-x">
                            <div id="similaritySlider" class="cell small-10">
                                <div class="slider" data-slider data-start="10" data-initial-start="10" data-end="50" data-step="1">
                                <span class="slider-handle"  data-slider-handle role="slider" tabindex="1" aria-controls="nodeCutoff"></span>
                                <span class="slider-fill" data-slider-fill></span>
                                </div>
                            </div>
                        </div>
                    </label>
                    <br>
                    <h3>Select enrichment type</h3>
                    <b>Note:</b> Please verify you are using the correct chemical identifiers by referencing the <a href="https://comptox.epa.gov/dashboard">EPA's CompTox Chemicals Dashboard.</a>
                </div>
            </div>

            <div class="row">
                <div class="large-3 columns">
                    <div id="jsme_container" style="display:none"></div>
                </div>
                <div class="large-6 columns">
                    <div id="jsmeInstructions" style="display:none">
                        <h4>
                            Draw Chemical with JSME
                        </h4>
                        <p>
                            For instructions on using JSME to draw chemicals, <a href="https://peter-ertl.com/jsme/2013_03/help.html" target="_blank">view the guide here</a>.
                            <br>
                            When finished drawing, right-click by the drawing and select <b>"Copy as SMILES"</b> or <b>"Copy as InChI"</b> to copy a SMILES or InChI string to paste below.
                            <br>
                            JSME is created by Peter Ertl and Bruno Bienfait.
                        </p>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="columns">
                    <ul class="tabs" data-tabs id="example-tabs">
                        <li class="tabs-title is-active"><a href="#panel1" aria-selected="true">User-Provided CASRN List</a></li>
                        <li class="tabs-title"><a href="#panel2">Chemicals With Shared Substructures</a></li>
                        <li class="tabs-title"><a href="#panel3">Chemicals With Structural Similarity</a></li>
                        <!-- <li class="tabs-title"><a href="#panel4">Chemicals With Biological Similarity</a></li>  -->
                        <li class="tabs-title"><a href="#panel5">View Annotations for Tox21 Chemicals</a></li>
                    </ul>

                <%--User Provided CASRN List--%>
                    <div class="tabs-content" data-tabs-content="example-tabs">
                        <div class="tabs-panel is-active" id="panel1">
                            <h4>User-Provided CASRN List</h4>
                            <label for="CASRNBox">Add "#SetName" before each set, if using multiple sets at once.
                                <button class="tiny button" type="button" onclick = "singleSet()">Example Single Set</button>
                                <button class="tiny button" type="button" onclick ="multiSet()">Example Multiple Sets</button>
                                <button class="tiny button" type="button" onclick ="clearInputCasrn()">Clear input</button>
                                <g:if test="${isCasrnErrors}">
                                    <g:textArea class="extralarge" name="CASRNBox" ><%--
                                --%><g:each in="${goodCasrns}">
                                    <%--                                --%>${it}<%--
                                --%></g:each><%--
                            --%></g:textArea>
                                    <g:each in="${errorCasrns}">
                                        <p style="color:red">Invalid CASRN "${it.casrn}" on line ${it.index + 1}.</p>
                                    </g:each>
                                    <g:if test="${noCasrnInput}">
                                        <p style="color:red">Input is required to perform enrichment.</p>
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
                            
                            <button class="button" type="button" id="toggleSubstructureSearchButton" onclick="toggleSubstructureSearch()">Switch to InChI input</button>
                            <br>

                            <%-- SMILES Box --%>
                            <div id="smileBoxContainer">   

                                <label for="SMILEBox">Enter partial or complete SMILES strings, one per line.
                                    <button class="tiny button" type="button" onclick = "exampleSmile()">Example SMILES strings</button>
                                    <button class="tiny button" type="button" onclick = "openJsme()" id="drawButtonSubstructure">Draw chemical with JSME</button>
                                    <button class="tiny button" type="button" onclick ="clearInputSmileSubstructure()">Clear input</button>
                                </label>

                                <g:if test="${isSmileErrors}">
                                    <g:textArea class="extralarge" name="SMILEBox" >${psqlGoodSmiles}</g:textArea>
                                    <g:each in="${psqlErrorSmiles}">
                                        <p style="color:red">Invalid SMILE "${it.smile}" on line ${it.index + 1}.</p>
                                    </g:each>
                                    <g:if test="${noSmileInput}">
                                        <p style="color:red">Input is required to perform enrichment.</p>
                                    </g:if>
                                </g:if>
                                <g:else>
                                    <g:textArea class="extralarge" name="SMILEBox" id="SMILEBox" ></g:textArea>
                                    <br>
                                </g:else>
                            </div>

                            <%-- InChI Box --%>
                            <div id="inchiBoxContainer" style="display: none">
                                <label for="InChIBox">Enter InChI strings, one per line.
                                    <button class="tiny button" type="button" onclick = "exampleInchi()">Example InChI strings</button>
                                    <button class="tiny button" type="button" onclick = "openJsme()" id="drawButtonSubstructure">Draw chemical with JSME</button>
                                    <button class="tiny button" type="button" onclick ="clearInputInchiSubstructure()">Clear input</button>
                                </label>
                                <g:if test="${isInChIErrors}">
                                    <g:textArea class="extralarge" name="InChIBox" >${psqlGoodSmiles}</g:textArea>
                                    <g:each in="${psqlErrorSmiles}">
                                        <p style="color:red">Invalid SMILE "${it.smile}" on line ${it.index + 1}.</p>
                                    </g:each>
                                    <g:if test="${noSmileInput}">
                                        <p style="color:red">Input is required to perform enrichment.</p>
                                    </g:if>
                                </g:if>
                                <g:else>
                                    <g:textArea class="extralarge" name="InChIBox" id="InChIBox" ></g:textArea>
                                    <br>
                                </g:else>

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
                                <div>
                                    <label id="thresholdSelect">Select Tanimoto similarity threshold (%)
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
                                    <label for="SMILEStructuralBox">Enter partial or complete SMILES strings, one per line.
                                        <button class="tiny button" type="button" onclick = "exampleSmileSimilarity()">Example SMILES strings</button>
                                        <button class="tiny button" type="button" onclick = "openJsme()" id="drawButtonSimilarity">Draw chemical with JSME</button>
                                        <button class="tiny button" type="button" onclick ="clearInputSmileSimilarity()">Clear input</button>
                                    </label>
                                    
                                    <g:if test="${isSmileSimErrors}">
                                        <g:textArea class="extralarge" name="SMILESimilarityBox" >${psqlGoodSmiles}</g:textArea>
                                        <g:each in="${psqlErrorSmiles}">
                                            <p style="color:red">Invalid SMILE "${it.smile}" on line ${it.index + 1}.</p>
                                        </g:each>
                                        <g:if test="${noSmileInput}">
                                            <p style="color:red">Input is required to perform enrichment.</p>
                                        </g:if>
                                    </g:if>
                                    <g:else>
                                        <g:textArea class="extralarge" name="SMILESimilarityBox" ></g:textArea>
                                        <br>
                                    </g:else>
                                </div>

                            <%-- InChI Box --%>
                            <div id="inchiSimilarityBoxContainer" style="display: none">
                                <label for="InChISimilarityBox">Enter InChI strings, one per line.
                                    <button class="tiny button" type="button" onclick = "exampleInchiSimilarity()">Example InChI strings</button>
                                    <button class="tiny button" type="button" onclick = "openJsme()" id="drawButtonSimilarity">Draw chemical with JSME</button>
                                    <button class="tiny button" type="button" onclick ="clearInputInchiSimilarity()">Clear input</button>
                                </label>
                                <g:if test="${isInChISimErrors}">
                                    <g:textArea class="extralarge" name="InChISimilarityBox" >${psqlGoodSmiles}</g:textArea>
                                    <g:each in="${psqlErrorSmiles}">
                                        <p style="color:red">Invalid SMILE "${it.smile}" on line ${it.index + 1}.</p>
                                    </g:each>
                                    <g:if test="${noSmileInput}">
                                        <p style="color:red">Input is required to perform enrichment.</p>
                                    </g:if>
                                </g:if>
                                <g:else>
                                    <g:textArea class="extralarge" name="InChISimilarityBox" id="InChISimilarityBox" ></g:textArea>
                                    <br>
                                </g:else>
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

                        <%--Grab all annotations for a chemical in Tox21--%>
                            <div class="tabs-content" data-tabs-content="example-tabs">
                                <div class="tabs-panel" id="panel5">
                                    <h4>View Annotations for Tox21 Chemicals</h4>
                                    <label for="AnnoBox">Enter the CASRNs for <a href="https://comptox.epa.gov/dashboard/chemical_lists/TOX21SL" target="_blank">chemicals in the Tox21 screening library</a> (one per line) to view each of their associated annotations in Tox21 Enricher.
                                        <g:if test="${isAnnoErrors}">
                                            <g:textArea class="extralarge" name="AnnoBox" ><%--
                                        --%><g:each in="${goodCasrns}">
                                            <%--                                --%>${it}<%--
                                        --%></g:each><%--
                                    --%></g:textArea>
                                            <g:each in="${errorCasrns}">
                                                <p style="color:red">Invalid CASRN "${it.casrn}" on line ${it.index + 1}.</p>
                                            </g:each>
                                            <g:if test="${noAnnoInput}">
                                                <p style="color:red">Input is required to view annotations.</p>
                                            </g:if>
                                        </g:if>
                                        <g:else>
                                            <g:textArea class="extralarge" name="AnnoBox" ></g:textArea>
                                            <br>
                                        </g:else>
                                        <input type="button" class="button" name="begin" value="Get Annotations" onclick="getAnnotations()" />
                                    </label>

                                </div>

                        </div>
                    </div>
                </div>
            </div>
        </div>
            <input type="hidden" name="analysisType" id="analysisType" value="CASRNS" />
            <input type="hidden" name="transactionId" id="transactionId" value="none" />
        </form>
    </div>
</body>
</html>
