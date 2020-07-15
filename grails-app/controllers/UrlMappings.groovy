class UrlMappings {

	static mappings = {
        "/$controller/$action?/$id?(.$format)?"{
            constraints {
                // apply constraints here
            }
        }

        "/tox21-api" (resources: 'apiAnalysis') {
            "/enrich" (controller: 'apiAnalysis', action: 'enrich')
        }

        "/" {
            controller = "analysis"
            action = "index"
            view = "/index"
        }


        "500"(view:'/error')
	}
}
