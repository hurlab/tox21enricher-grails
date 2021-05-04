#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(catmaply)
library(CePa)
library(httr)
library(plotly)
library(uuid)
library(xlsx)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

    # Display enrichment type on title
    output$selected_enrich_from <- renderText({
        paste("Enrich from ", input$enrich_from)
    })
    
    # Get list of annotation classes & types from Postgres database
    get_annotations <- function(){
        # get names & types
        query <- sqlInterpolate(ANSI(), "SELECT annoclassname, annotype FROM annotation_class;",
            id = input$get_annotations)
        outp <- dbGetQuery(pool, query)
        
        loopIndex <- 0
        return(outp)
    }
    annoClasses <- reactiveValues(classes = c())
    
    # Display list of annotations to select
    output$annotations <- renderUI({
        annoListFull <- get_annotations()
        annoList <- annoListFull[1]
        selectedAnnoList <- reactiveValues()
        
        # Lists for each class type
        classPubChem <- vector("list",2)
        classDrugMatrix <- vector("list",16)
        classDrugBank <- vector("list",6)
        classCTD <- vector("list",10)
        classOther <- vector("list",7)
        
        # Indices for different class types
        iPubChem <- 1
        iDrugMatrix <- 1
        iDrugBank <- 1
        iCTD <- 1
        iOther <- 1
        for (anno in 1:nrow(annoListFull)) {
            aname <- annoListFull[anno, "annoclassname"]
            atype <- annoListFull[anno, "annotype"]
            if (atype == "PubChem Compound Annotation") {
                classPubChem[[iPubChem]] <- aname
                iPubChem <- iPubChem + 1
            }
            else if (atype == "DrugMatrix Annotation") {
                classDrugMatrix[[iDrugMatrix]] <- aname
                iDrugMatrix <- iDrugMatrix + 1
            }
            else if (atype == "DrugBank Annotation") {
                classDrugBank[[iDrugBank]] <- aname
                iDrugBank <- iDrugBank + 1
            }
            else if (atype == "CTD Annotation") {
                classCTD[[iCTD]] <- aname
                iCTD <- iCTD + 1
            }
            else {
                classOther[[iOther]] <- aname
                iOther <- iOther + 1
            }
        }
        
        annoClassList = list()
        annoClassList[[1]] <- classPubChem
        annoClassList[[2]] <- classDrugMatrix
        annoClassList[[3]] <- classDrugBank
        annoClassList[[4]] <- classCTD
        annoClassList[[5]] <- classOther
        annoClasses$classes <- annoClassList
        
        print(annoClassList)

        # Render checkboxes for each annotation class
        column(12,
            tabsetPanel(id="annotationClasses", type="pills",
                tabPanel("PubChem Compound Annotations",fluidRow(checkboxGroupInput("checkboxPubChem","PubChem Compound Annotations", choices = classPubChem, selected = classPubChem))),
                tabPanel("DrugMatrix Annotations",fluidRow(checkboxGroupInput("checkboxDrugMatrix","DrugMatrix Annotations", choices = classDrugMatrix, selected = classDrugMatrix))),
                tabPanel("DrugBank Annotations",fluidRow(checkboxGroupInput("checkboxDrugBank","DrugBank Annotations", choices = classDrugBank, selected = classDrugBank))),
                tabPanel("CTD Annotations",fluidRow(checkboxGroupInput("checkboxCTD","CTD Annotations", choices = classCTD, selected = classCTD))),
                tabPanel("Other Annotations",fluidRow(checkboxGroupInput("checkboxOther","Other Annotations", choices = classOther, selected = classOther)))
            )
        )
    })
    
    # Display chemical input type
    output$input_type <- renderText({
        if(input$enrich_from == "User-Provided CASRN List") {
            paste("Input CASRNs")
        } else {
            paste("Input SMILE/InChI Strings")
        }
    })
    
    # Change enrichment settings
    observeEvent(input$enrich_from, {
        if(input$enrich_from == "User-Provided CASRN List") {
          enrichmentType$enrichType <- "casrn"
          shinyjs::show(id = "casrnExamples")
          shinyjs::hide(id = "smilesExamples")
        } else {
          if(input$enrich_from == "Chemicals with Shared Substructures") {
            enrichmentType$enrichType <- "substructure"
          } else {
            enrichmentType$enrichType <- "similarity"
          }
          shinyjs::hide(id = "casrnExamples")
          shinyjs::show(id = "smilesExamples")
        }
    })
    
    # Toggle Select/Deselect all for annotation classes
    selectStatus <- reactiveValues(option = character())
    selectStatus$option <- "deselect"
    observeEvent(input$select_all_annotations, {
        # Grab list of annotation classes
            # 1 = PubChem
            # 2 = DrugMatrix
            # 3 = DrugBank
            # 4 = CTD
            # 5 = Other
        annoClassList = annoClasses$classes
        if(selectStatus$option == "deselect") {
            updateCheckboxGroupInput(session, "checkboxPubChem", selected = "")
            updateCheckboxGroupInput(session, "checkboxDrugMatrix", selected = "")
            updateCheckboxGroupInput(session, "checkboxDrugBank", selected = "")
            updateCheckboxGroupInput(session, "checkboxCTD", selected = "")
            updateCheckboxGroupInput(session, "checkboxOther", selected = "")
            updateActionButton(session, "select_all_annotations", label = "Select All")
            selectStatus$option <- "select"
        } else {
            updateCheckboxGroupInput(session, "checkboxPubChem", selected = annoClassList[[1]])
            updateCheckboxGroupInput(session, "checkboxDrugMatrix", selected = annoClassList[[2]])
            updateCheckboxGroupInput(session, "checkboxDrugBank", selected = annoClassList[[3]])
            updateCheckboxGroupInput(session, "checkboxCTD", selected = annoClassList[[4]])
            updateCheckboxGroupInput(session, "checkboxOther", selected = annoClassList[[5]])
            updateActionButton(session, "select_all_annotations", label = "Deselect All")
            selectStatus$option <- "deselect"
        }
        
    })
    
    # Provide CASRNs example set (single) when button is clicked
    observeEvent(input$example_casrns, {
        updateTextAreaInput(session, "submitted_chemicals", value = "965-90-2\n50-50-0\n979-32-8\n4245-41-4\n143-50-0\n17924-92-4\n297-76-7\n152-43-2\n313-06-4\n4956-37-0\n112400-86-9")
    })
    
    # Provide CASRNs example set (multiple) when button is clicked
    observeEvent(input$example_casrnsMulti, {
        updateTextAreaInput(session, "submitted_chemicals", value = "#BPA analogs\n2081-08-5\n2467-02-9\n1478-61-1\n41481-66-7\n5613-46-7\n57-63-6\n620-92-8\n77-40-7\n79-94-7\n79-95-8\n79-97-0\n80-05-7\n80-09-1\n843-55-0\n94-18-8\n#Flame retardants\n115-86-6\n115-96-8\n1241-94-7\n1330-78-5\n13674-87-8\n29761-21-5\n5436-43-1\n56803-37-3\n68937-41-7\n78-30-8\n79-94-7\n#PAH\n120-12-7\n129-00-0\n191-24-2\n206-44-0\n218-01-9\n50-32-8\n53-70-3\n56-55-3\n83-32-9\n85-01-8\n")
    })
    
    # Provide SMILES example set when button is clicked
    observeEvent (input$example_smiles, {
        updateTextAreaInput(session, "submitted_chemicals", value = "ClCC1=CC=CC=C1\nCOCCOC(=O)CC#N\nInChI=1S/C8H11N/c1-9(2)8-6-4-3-5-7-8/h3-7H,1-2H3")
    })
    
    # Clear CASRNs input box
    observeEvent(input$clear_casrns, {
        updateTextAreaInput(session, "submitted_chemicals", value = "")
    })
    
    # Show/hide JSME input
    jsmeState <- reactiveValues(jsmeShowState = "")
    jsmeState$jsmeShowState <- "show"
    
    observeEvent(input$jsme_button, {
        if (jsmeState$jsmeShowState == "show") {
            shinyjs::show("jsmeInput")
            updateActionButton(session, "jsme_button", label = "Hide JSME")
            jsmeState$jsmeShowState <- "hide"
        }
        else {
            shinyjs::hide("jsmeInput")
            updateActionButton(session, "jsme_button", label = "Draw Molecules with JSME")
            jsmeState$jsmeShowState <- "show"
        }
    })
    
    # Refresh enrichment form
    observeEvent(input$refresh, {
        # Initialize all annotation classes to checked and button mode to "deselect"
        annoClassList = annoClasses$classes
        updateCheckboxGroupInput(session, "checkboxPubChem", selected = annoClassList[[1]])
        updateCheckboxGroupInput(session, "checkboxDrugMatrix", selected = annoClassList[[2]])
        updateCheckboxGroupInput(session, "checkboxDrugBank", selected = annoClassList[[3]])
        updateCheckboxGroupInput(session, "checkboxCTD", selected = annoClassList[[4]])
        updateCheckboxGroupInput(session, "checkboxOther", selected = annoClassList[[5]])
        updateActionButton(session, "select_all_annotations", label = "Deselect All")
        selectStatus$option <- "deselect"
        shinyjs::reset("enrichmentForm")
        shinyjs::show("enrichmentForm")
        shinyjs::reset("select_all_annotations")
        
        # Clear the chemical submission text area
        updateTextAreaInput(session, "submitted_chemicals", value="")
        
        # Allow user to change enrichment type
        shinyjs::enable("enrich_from")
        
        # Hide the refresh button
        shinyjs::hide("refresh")
        
        # clear the previous enrichment's results and hide
        shinyjs::hide("resultsContainer")
        shinyjs::reset("resultsContainer")
        #removeUI(selector="#resultsTabset")
        #insertUI(
        #    selector="#enrichmentResults",
        #    where="afterBegin",
        #    ui=uiOutput("resultsTabset") %>% withSpinner()
        #)
        output[["resultsTabset"]] <- renderUI(
            div(id="resultsTmp")
        )
        #removeUI(selector="#resultsTmp")
    })
    
    # Keep track of what enrichment type is currently selected
    enrichmentType <- reactiveValues(enrichType = character())
    enrichmentType$enrichType <- "casrn"
    
    
    # Perform CASRN enrichment analysis when submit button is pressed
    observeEvent(input$submit, {
        performEnrichment(input$submitted_chemicals)  
    })
    
    # Create reactive variable to store chemicals to re-enrich
    checkboxList <- reactiveValues(checkboxes = NULL)

    performEnrichment <- function(casrnBox) {
        # Hide original form when done with enrichment
        shinyjs::hide(id="enrichmentForm")
      
        # Disable changing input type when button is clicked
        shinyjs::disable(id="enrich_from")
        
        # Show 'Restart' button, disable by default so user can't interfere with enrichment process
        shinyjs::show(id="refresh")
        shinyjs::disable(id="refresh")
      
        # Show loading spinner
        shinyjs::show(id="resultsContainer")
      
        # Get node cutoff
        cutoff <- input$nodeCutoff
      
        print(enrichmentType$enrichType)
      
        # Get user-submitted CASRNS from box
        #casrnBox <- input$submitted_chemicals
        
        
        # Initialize list to hold result chemicals for reenrichment (Substructure & Similarity only)
        # TODO: Don't initialize like this, it makes it slow
        reenrichResults <- list()
        
        # Split CASRNBox to get each line and organize into sets
        if (enrichmentType$enrichType == "casrn") {
            casrnBoxSplit <- strsplit(casrnBox,"\n",fixed=TRUE)
                # Clean casrnBoxSplit to get rid of blank lines
                #for (i in casrnBoxSplit[[1]]) {
                #    if (i == "") {
                #        print("remove this")
                #        casrnBoxSplit[[1]][i] <- NULL
                #    }
                #}
            #print(casrnBoxSplit)
            
            enrichmentSets <- list()
            
            if (grepl("#",casrnBox,fixed=TRUE)) { # If more than 1 set
                setName <- ""
            } else { # Give arbitrary name if user only submitted a single set
                setName <- "Set1"
            }
            setIndex <- 1
            for (i in casrnBoxSplit[[1]]) {
                if (grepl("#", i, fixed=TRUE)) {
                    #print(i)
                    setName <- gsub(" ", "", sub('.', '', i), fixed=TRUE)
                    setIndex <- 1
                    enrichmentSets[[setName]] <- c()
                } else {
                    enrichmentSets[[setName]][setIndex] <- i
                    setIndex = setIndex + 1
                }
            }
        } else {
            casrnBoxSplit <- strsplit(casrnBox,"\n",fixed=TRUE)
            enrichmentSets <- list()
            #setNameToShow <- ""
            setName <- ""
            setIndex <- 1
            totalSetsIndex <- 1
            
            #TODO: fix this
            for (i in casrnBoxSplit[[1]]) {
                # This is just so we can preserve showing submitted InChIs as InChIs and not SMILES
                #setNameToShow <- i
                
                # First, check if we have any InChIs, and convert to SMILES
                if (grepl("InChI=",i,fixed=TRUE)) {
                    queryInchi <- sqlInterpolate(ANSI(), paste0("SELECT smiles FROM chemical_detail WHERE inchis = '", i, "';"),
                                                 id = "smilesResults")
                    outpInchi <- dbGetQuery(pool, queryInchi)
                    setName <- outpInchi[[1]]
                } else {
                    setName <- i
                }
              
                if (enrichmentType$enrichType == "substructure") {
                    querySmiles <- sqlInterpolate(ANSI(), paste0("SELECT * FROM mols_2 WHERE m @> CAST('", setName, "' AS mol);"),
                                            id = "smilesResults")
                } else {
                    querySmiles <- sqlInterpolate(ANSI(), paste0("SELECT * FROM get_mfp2_neighbors('", setName, "');"),
                                            id = "smilesResults")
                }
                outpSmiles <- dbGetQuery(pool, querySmiles)
                reenrichResults[[paste0("Set", totalSetsIndex)]] <- outpSmiles
                
                print(outpSmiles)
                
                for (j in outpSmiles[[1]]) {
                    enrichmentSets[[paste0("Set", totalSetsIndex)]][setIndex] <- j
                    setIndex = setIndex + 1
                }
                totalSetsIndex <- totalSetsIndex + 1
            }
        }
        
        
        print(enrichmentSets)
          
        # Generate UUID for this query
        transactionId <- UUIDgenerate()

        inDir <- paste0("/home/hurlab/tox21r/tox21enricher/Input/", transactionId, "/")
        outDir <- paste0("/home/hurlab/tox21r/tox21enricher/Output/", transactionId, "/")
        outDirWeb <- paste0("output/", transactionId, "/")
        outDirHeatmap <- paste0("/home/hurlab/tox21r/tox21enricher/Output/", transactionId, "/gct_per_set/ -color=BR")
        outDirHeatmapMulti <- paste0("/home/hurlab/tox21r/tox21enricher/Output/", transactionId, "/gct/")
        
        # Get selected annotation classes
        # TODO: use map() to make this more R-like
        annoSelectStr <- ""
        for (i in input$checkboxPubChem) {
            annoSelectStr <- paste0(annoSelectStr, i, "=checked,")
        }
        for (i in input$checkboxDrugMatrix) {
            annoSelectStr <- paste0(annoSelectStr, i, "=checked,")
        }
        for (i in input$checkboxDrugBank) {
            annoSelectStr <- paste0(annoSelectStr, i, "=checked,")
        }
        for (i in input$checkboxCTD) {
            annoSelectStr <- paste0(annoSelectStr, i, "=checked,")
        }
        for (i in input$checkboxOther) {
            annoSelectStr <- paste0(annoSelectStr, i, "=checked,")
        }
        
        print(annoSelectStr)
        
        # Create input directory
        dir.create(inDir)
        # Create output directory
        dir.create(outDir)
        
        # Create input set txt for enrichment
        for (i in names(enrichmentSets)) {
            #print(i)
            inFile <- file(paste0(inDir, i, ".txt"))
            outString <- ""
            for (j in enrichmentSets[[i]]) {
                query <- sqlInterpolate(ANSI(), paste0("SELECT testsubstance_chemname FROM chemical_detail WHERE CASRN LIKE '", j, "';"),
                                        id = j)
                outp <- dbGetQuery(pool, query)
                if (dim(outp)[1] > 0 & dim(outp)[2] > 0) {
                    outString <- paste0(outString, j, "\t", outp, "\n\n")
                }
            }
            
            writeLines(outString,inFile)
            close(inFile)
        }
        
        
        
        # Run enrichment by querying Plumber API
        print(paste0("QUERYING:: http://localhost:8082/enrich?enrichmentUUID=", transactionId, "&annoSelectStr=", annoSelectStr))
        GET(url=paste0("http://localhost:8082/enrich?enrichmentUUID=", transactionId, "&annoSelectStr=", annoSelectStr))
        
        
        # Render results page
        output$resultsTabset <- renderUI({
            fluidRow(
                fluidRow(
                    column(12,
                        h1(id="resultsHeader", "Enrichment Results"),
                        do.call(tabsetPanel, c(id='tab',lapply(names(enrichmentSets), function(i) {
                            tabPanel(
                                title=paste0(i),
                                uiOutput(paste0("outTab_", i))
                            )
                        })))
                    )
                ),
                fluidRow(
                    column(12, 
                           uiOutput("reenrichItemsOut")
                    )
                ),
                fluidRow(
                    column(12, 
                        uiOutput("reenrichButtonOut")
                    )
                ),
                fluidRow(
                    column(6,
                        h3("Chart Full Heatmap"),
                        uiOutput("chartHeatmap")
                    ),
                    column(6,
                        h3("Cluster Heatmap"),
                        uiOutput("clusterHeatmap")
                    )
                )
            )
        })
        
        lapply(names(enrichmentSets),
            function(i) {
                gctFile <- read.table(paste0(outDir, "gct_per_set/", i, "__Chart.gct"), skip=2, header=TRUE, sep="\t", row.names=1, comment.char="", fill=FALSE, colClasses=c("Name"="NULL","integer") )
                gctFileMatrix <- data.matrix(gctFile)
                gctCASRNNames <- rownames(gctFile)
                gctAnnoNames <- colnames(gctFile)
                
                output[[paste0("outTab_", i)]] <- renderUI(
                    column(12,
                        tabPanel(paste0("tab_", i), 
                             fluidRow(
                                 column(id=paste0("resultFileChart_", i), 4, 
                                        bsTooltip(id=paste0("resultFileChart_", i), title="A list of all significant annotations (.txt format).", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__Chart.txt"), paste0(i, "__Chart.txt"))),
                                 column(id=paste0("resultFileChartX_", i), 4, 
                                        bsTooltip(id=paste0("resultFileChartX_", i), title="A list of all significant annotations (.xls format).", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__Chart.xlsx"), paste0(i, "__Chart.xlsx")))
                             ),
                             fluidRow(
                                 column(id=paste0("resultFileChartSimple_", i), 4, 
                                        bsTooltip(id=paste0("resultFileChartSimpleI", i), title="A list of the top 10 most signicant annotations for each annotation class (.txt format).", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__ChartSimple.txt"), paste0(i, "__ChartSimple.txt"))),
                                 column(id=paste0("resultFileChartSimpleX_", i), 4, 
                                        bsTooltip(id=paste0("resultFileChartSimpleX_", i), title="A list of the top 10 most signicant annotations for each annotation class (.xls format).", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__ChartSimple.xlsx"), paste0(i, "__ChartSimple.xlsx")))
                             ),
                             fluidRow(
                                 column(id=paste0("resultFileCluster_", i), 4, 
                                        bsTooltip(id=paste0("resultFileCluster_", i), title="A list of significant terms in which functionally similar annotations are grouped together to remove redundancy. This is performed with respect to the whole annotation set rather than to individual annotation classes (.txt format).", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__Cluster.txt"), paste0(i, "__Cluster.txt"))),
                                 column(id=paste0("resultFileClusterX_", i), 4, 
                                        bsTooltip(id=paste0("resultFileClusterX_", i), title="A list of significant terms in which functionally similar annotations are grouped together to remove redundancy. This is performed with respect to the whole annotation set rather than to individual annotation classes (.xls format).", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__Cluster.xlsx"), paste0(i, "__Cluster.xlsx")))
                             ),
                             fluidRow(
                                 column(id=paste0("resultFileMatrix_", i), 4, 
                                        bsTooltip(id=paste0("resultFileMatrix_", i), title="A text representation of the heatmap.", placement="right", trigger="hover"),
                                        tags$a(href=paste0(outDirWeb, i, "__Matrix.txt"), paste0(i, "__Matrix.txt")))
                             )
                        ),
                        fluidRow(
                            plot_ly(x = gctAnnoNames, y = gctCASRNNames, z = gctFileMatrix, colors = colorRamp(c("white", "red")), type="heatmap", xgap=2, ygap=2 ) %>% layout(margin = list(b = 160), xaxis=list(tickangle=45), yaxis=list(type="category"))
                            #catmaply(df = gctFile, x = gctAnnoNames, y = gctCASRNNames, color_palette = viridis::magma)
                        ),
                        fluidRow(
                            uiOutput(paste0("table_{i}")),
                        )
                    )
                )
            }
        )
        
        # Render reenrichment if Substructure or Similarity
        if (enrichmentType$enrichType != "casrn") {
            reenrichResultsTotalLength <- 0
            for (i in names(reenrichResults)) {
                reenrichResultsTotalLength <- reenrichResultsTotalLength + nrow(reenrichResults[[i]])
            }
            print(reenrichResultsTotalLength)
            
            reenrichChoices <- vector("list", reenrichResultsTotalLength)
            
            lapply(names(reenrichResults),
                function(i) {
                    # Get chemical structure images and add to table
                    resultImages <- character()
                    imgPath1 <- '<img src="images/structures/'
                    imgPath2 <- '.png" height="100" width="100"></img>'
                    resultImages <- sapply(reenrichResults[[i]][1], function(casrnName) return(paste0(imgPath1, casrnName, imgPath2)))
                    
                    output[[paste0("table_", i)]] <- renderUI(
                        column(12,
                            h3("Result Chemicals"),
                            # Render reenrichment table (solution from https://stackoverflow.com/questions/37356625/adding-a-column-with-true-false-and-showing-that-as-a-checkbox/37356792#37356792)
                            DT::datatable({
                                data.frame(structure=resultImages, reenrichResults[[i]])
                            }, escape = FALSE, options = list( 
                                  paging=FALSE,
                                  preDrawCallback = JS('function() { Shiny.unbindAll(this.api().table().node()); }'), 
                                  drawCallback = JS('function() { Shiny.bindAll(this.api().table().node()); } ') 
                            ))
                        )
                    )
                }
            )
            
            # Checkbox input to select chemicals for re-enrichment
            reenrichIndex <- 1
            for (i in names(reenrichResults)) {
                for(j in reenrichResults[[i]][1]) {
                    for (k in j) {
                        print(k)
                        reenrichChoices[reenrichIndex] <- paste0(k, "__", i)
                        reenrichIndex <- reenrichIndex + 1
                    }
                }
            }
            
            print(reenrichChoices)
              
            tmpCb <- checkboxGroupInput(inputId = paste0("cbgi"), choices=reenrichChoices, selected=reenrichChoices, label = NULL)
            print(tmpCb)
            
            checkboxList$checkboxes[[i]] <- tmpCb
            
            output[["reenrichItemsOut"]] <- renderUI(
              tmpCb
            )
            
            # Render re-enrich button
            output[["reenrichButtonOut"]] <- renderUI(
              actionButton("reenrichButton", "Reenrich Selected Chemicals")
            )
        }
        
        
        # Render Chart & Cluster heatmaps for all sets
        gctFileChart <- read.table(paste0(outDir, "gct/Chart_Top", cutoff, "_ALL__P_0.05_P__ValueMatrix.gct"), skip=2, header=TRUE, sep="\t", row.names=1, comment.char="", fill=FALSE, colClasses=c("Terms"="NULL","integer") )
        gctFileChartMatrix <- data.matrix(gctFileChart)
        gctCASRNNamesChart <- rownames(gctFileChart)
        gctAnnoNamesChart <- colnames(gctFileChart)
        
        gctFileCluster <- read.table(paste0(outDir, "gct/Cluster_Top", cutoff, "_ALL__P_0.05_P__ValueMatrix.gct"), skip=2, header=TRUE, sep="\t", row.names=1, comment.char="", fill=FALSE, colClasses=c("Terms"="NULL","integer") )
        gctFileClusterMatrix <- data.matrix(gctFileCluster)
        gctCASRNNamesCluster <- rownames(gctFileCluster)
        gctAnnoNamesCluster <- colnames(gctFileCluster)
        
        output[["chartHeatmap"]] <- renderUI(
            fluidRow(
                plot_ly(x = gctAnnoNamesChart, y = gctCASRNNamesChart, z = gctFileChartMatrix, colors = colorRamp(c("white", "red")), type="heatmap", xgap=2, ygap=2) %>% layout(margin = list(b = 160), xaxis=list(tickangle=45), yaxis=list(type="category")),
            )
        )
        output[["clusterHeatmap"]] <- renderUI(
            fluidRow(
                plot_ly(x = gctAnnoNamesCluster, y = gctCASRNNamesCluster, z = gctFileClusterMatrix, colors = colorRamp(c("white", "red")), type="heatmap", xgap=2, ygap=2) %>% layout(margin = list(b = 160), xaxis=list(tickangle=45), yaxis=list(type="category"))
            )
        )
        
        # Re-enable refresh button
        shinyjs::enable(id="refresh")
    }
    
    
    # Enrichment methods
    # Generate individual gct file for significant terms
    
    generateGctFiles <- function(inDir, outDir, nodeCutoff, sig, sigColumn, sigCutoff, valColumn) {
      # -------------------------------------
      # Get the corresponding directory names
      # -------------------------------------
      inputDir <- inDir
      baseDir <- outDir
      outputDir <- paste0(outDir, "gct_per_set/")
      
      # -------------------------------------
      # Load CASRN names
      # -------------------------------------
      casrnFile <- file("Annotation/Tox21_CASRN_Names.anno", "r")
      while (TRUE) {
          line <- readlines(casrnFile, n=1)
          if (length(line) == 0) {
              break
          }
          #process each line here
          
          
      }
      close(casrnFile)
    
    }
    
    
    
    # Perform re-enrichment on selected result chemicals
    observeEvent(input$reenrichButton, {
        #print(input$cbgi)
        
        # Get total size of how many elements are checked so we can initialize the CASRNBox
        #cgbiSize <- 0
        #for (i in input$cbgi) {
        #    cgbiSize = cgbiSize + 1
        #}
        #reenrichCASRNBox <- vector("list", cgbiSize)

        reenrichCASRNBox <- ""
       
        reenrichCurrentSet <- ""
        for (i in input$cbgi) {
            reenrichTmpSplit <- strsplit(i,"__")
            for (j in reenrichTmpSplit) {
                print(j[1])  
                if (reenrichCurrentSet == "") {
                    reenrichCASRNBox <- paste0(reenrichCASRNBox, "#", j[2], "\n", j[1], "\n")
                    reenrichCurrentSet = j[2]
                }
                else if (reenrichCurrentSet != j[2] & reenrichCurrentSet != "") {
                    reenrichCASRNBox <- paste0(reenrichCASRNBox, "\n#", j[2], "\n", j[1], "\n")
                    reenrichCurrentSet = j[2]
                }
                else {
                    reenrichCASRNBox <- paste0(reenrichCASRNBox, "\n", j[1], "\n")
                }
            }
        }
      
        print (reenrichCASRNBox)
        enrichmentType$enrichType <- "casrn"
        performEnrichment(reenrichCASRNBox)
    })
    
})

