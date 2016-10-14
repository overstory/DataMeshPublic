import config.AppConfigBuilder
import config.ConfigModule
import handlers.NotFoundHandler
import handlers.record.RecordHandler
import handlers.api.ApiHandler
import handlers.rdf.RdfHandler
import handlers.record.RecordListHandler
import ratpack.config.ConfigData
import ratpack.handling.Context

import java.nio.file.Path

import static ratpack.groovy.Groovy.ratpack

ratpack
{
	ConfigObject configObject = AppConfigBuilder.appConfig()
	// Building this configData instance flattens the exclusion patterns list in ConfigObject to a String.  Holding on to both.
	ConfigData configData = ConfigData.builder().props (configObject.toProperties()).env().sysProps().build()

	serverConfig {
		AppConfigBuilder.loadLogback()
	}

	bindings {
		module new ConfigModule (configData, configObject)
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

//		path ("") {
//			Path asset = file ("public/index.html")
//
//			if (asset.toFile().exists()) render asset else next()
//		}

		path ('') {
			redirect ('/api')
		}

		path ('api') {
			insert (get (ApiHandler))
		}

		path ('rdf') {
			println "MATCH RDF ONLY"
			insert (get (RdfHandler))
		}
		path ('rdf/:which') {
			println "MATCH RDF SEARCH"
			insert (get (RdfHandler))
		}
		path ('rdf/:which/:id') {
			println "MATCH RDF PAGE ${request.path}"
			insert (get (RdfHandler))
		}

		path ('record') {
			println "MATCH SIMPLE RECORD"
			insert (get (RecordListHandler))
		}
		path ('record/:which') {
			insert (get (RecordListHandler))
		}
		path ('record/id/:id') {
			insert (get (RecordHandler))
		}
		path ('record/type/:id') {
			insert (get (RecordHandler))
		}

//		path ("datamesh/:page") {
//			println "MATCH ANGULAR PAGE"
//			Path asset = file (request.path)
//
//			if (asset.toFile().exists()) {
//				render asset
//			} else {
//				asset = file ("${request.path}.html")
//
//				if (asset.toFile().exists()) {
//					render asset
//				} else {
//					next()
//				}
//			}
//		}
//
//		path ("datamesh/::.+") {
//			println "MATCH PATH ${request.path}"
//			Path asset = file (request.path)
//
//			if (asset.toFile().exists()) render asset else next()
//		}

		path ("::.+") {
			println "MATCH ANYTHING ${request.path}"
			Path asset = file ("public/${request.path}")

			if (asset.toFile().exists()) render asset else next()
		}

		all {
			println "DEFAULT: NOT FOUND ${request.path}"

			insert (get (NotFoundHandler))
		}
	}
}

