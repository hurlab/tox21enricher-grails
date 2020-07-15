<h1>Tox21 Enricher</h1>
The Tox21 Enricher is a web application that is still currently under development. It performs PubChem enrichment analysis on a set or sets of chemicals included in the the Tox21 collection and it is being created in collaboration with NIEHS as part of their suite of Tox21 tools.

<h2>Process</h2>
Chemicals are specified directly via their corresponding CASRN or indirectly with a SMILE string upon which a substructure search is executed. Once chemicals containing the given SMILE string(s) are identified, CASRNs are used and enrichment proceeds as if the system was given CASRN input originally. Enrichment is then performed on the CASRNs.

After performing enrichment, the results are displayed (heatmap images per set, gct, xls, txt files, cluster and chart full heatmaps) along with an option to view the cluster and chart full heatmaps visualized as networks. In the networks displayed, two nodes with a connecting edge indicate two annotations that have a statistically significant connection.

<h2>Development Tools</h2>
Tools used in the development of the Tox21 Enricher:

<br/>Groovy (2.5.6)
<br/>Grails (4.0.2)
<br/>Zurb Foundation for Sites (6)
<br/>cytoscape.js
<br/>RDKit
<br/>MySQL (8.0)
<br/>PostgreSQL (11)
