#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Define UI for Tox21Enricher application
shinyUI(fluidPage(

    # Application title
    titlePanel("Tox21 Enricher"),

    # Sidebar
    sidebarLayout(
        
        sidebarPanel(
            useShinyjs(),
            p("Please see this ", tags$a(href="docs/Tox21Enricher_Manual_v3.0.pdf","link"), "for instructions on using this application and the descriptions about the chemical/biological categories. Other resources from the Tox21 toolbox can be viewed", tags$a(href="https://ntp.niehs.nih.gov/results/tox21/tbox/","here.")),
            # Enrichment type selection
            selectInput("enrich_from", h3("Enrich From:"),
                        choices = list("User-Provided CASRN List" = "User-Provided CASRN List",
                                       "Chemicals with Shared Substructures" = "Chemicals with Shared Substructures",
                                       "Chemicals with Structural Similarity" = "Chemicals with Structural Similarity")),
            hidden(
                actionButton("refresh", "Restart")
            )
        ),
        
        mainPanel(
            column(id = "enrichmentForm", 12,
                h1(textOutput("selected_enrich_from")),
                # Annotation selection
                fluidRow(
                    h3("Select Chemical/Biological Annotation Categories"),
                    column(6,
                        actionButton("select_all_annotations", "Deselect All")
                    ),
                ),
                fluidRow(
                    # Annotation class selection tabs
                    uiOutput("annotations") %>% withSpinner(),
                ),
                
                fluidRow(
                    h3("Select Enrichment Cutoff"),
                    #p("This will determine the maximum number of results per data set and may affect how many nodes are generated during network generation. (default = 10). Higher values may cause the enrichment process to take longer."),
                    bsTooltip(id="nodeCutoff", title="This will determine the maximum number of results per data set and may affect how many nodes are generated during network generation. (default = 10). Higher values may cause the enrichment process to take longer.", placement="right", trigger="hover"),
                    sliderInput(inputId = "nodeCutoff", label="Enrichment Cutoff", value=10, min=1, max=100,step=1)
                    
                ),
    
                # Chemical input
                fluidRow(
                    h3(textOutput("input_type")),
                    fluidRow(id = "casrnExamples",
                        column(3,
                            actionButton("example_casrns", "CASRNs Example Single Set"),
                            actionButton("example_casrnsMulti", "CASRNs Example Multiple Sets"))
                    ),
                    hidden( #hide SMILES example button by default
                        fluidRow(id = "smilesExamples",
                            column(3,
                                actionButton("example_smiles", "SMILES/InChI Example Set"),
                                actionButton("jsme_button", "Draw Molecules with JSME")),
                        )
                    ),
                    column(3,
                        actionButton("clear_casrns", "Clear")),
                    hidden(
                        fluidRow(id="jsmeInput",
                            column(12,
                                includeHTML("www/html/jsme.html")
                            )
                        )
                    ),
                    column(12,
                        tags$textarea(id = "submitted_chemicals",rows=5,cols=50,""))
                ),
                actionButton("submit", "Submit")
            ),
            hidden(
                fluidRow(id="resultsContainer",
                    column(id="enrichmentResults", 12,
                        uiOutput("resultsTabset") %>% withSpinner()
                    )
                )
            )
        )
    )
))
