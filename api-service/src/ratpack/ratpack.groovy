import config.ConfigModule
import handlers.MLPassThruHttpClientHandler
import handlers.RecordHandler
import ratpack.handling.Context

import java.nio.file.Path

import static ratpack.groovy.Groovy.ratpack

ratpack
{
	serverConfig {
	}

	bindings {
		module ConfigModule
	}

	handlers {
		all { Context c ->
			println "Request: verb: ${c.request.method}, uri: ${c.request.uri}"
			c.next()
		}

//		path ("feed/:file") { Context c ->
//			byMethod {
//				get {
//					Path asset = file ("json/${c.pathTokens['file']}.json")
//					if (asset.toFile().exists()) render asset else next()
//				}
//			}
//		}

		path ("") {
			Path asset = file ("public/index.html")

			if (asset.toFile().exists()) render asset else next()
		}

		path ('datamesh') {
			redirect ('/datamesh/api')
		}

		path ('datamesh/record') {
			insert (get (RecordHandler))
		}

		path ("datamesh/:page") {
			println "MATCH ANGULAR PAGE"
			Path asset = file (request.path)

			if (asset.toFile().exists()) {
				render asset
			} else {
				asset = file ("${request.path}.html")

				if (asset.toFile().exists()) {
					render asset
				} else {
					next()
				}
			}
		}

		path ("datamesh/::.+") {
			println "MATCH PATH ${request.path}"
			Path asset = file (request.path)

			if (asset.toFile().exists()) render asset else next()
		}

		path ("::.+") {
			println "MATCH ANYTHING ${request.path}"
			Path asset = file ("public/${request.path}")

			if (asset.toFile().exists()) render asset else next()
		}

		all {
			response.status (404)
			Path asset = file ("public/404.html")

			if (asset.toFile().exists()) {
				render asset
			} else {
				response.contentType ('text/plain')
				response.send ('Oh dear, I don\'t seem to have one of those\n')
			}
		}
	}
}

