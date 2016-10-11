package config

import com.google.inject.AbstractModule
import com.google.inject.name.Names
import handlers.MLPassThruHttpClientHandler
import handlers.NotFoundHandler
import handlers.record.RecordHandler
import handlers.api.ApiHandler
import handlers.rdf.RdfHandler
import handlers.record.RecordListHandler
import ratpack.config.ConfigData
import repositories.XmlRepository
import repositories.impl.XmlRepositoryImpl
import static config.AppConstants.*

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 9/24/16
 * Time: 3:56 AM
 */
class ConfigModule extends AbstractModule
{
	private final ConfigData configData
	private final ConfigObject configObject

	ConfigModule (ConfigData configData, ConfigObject configObject)
	{
		this.configData = configData
		this.configObject = configObject

		// A little Groovy meta-programming to add a new method to the ConfigData class
		// This method returns the default value if the property is not found
		configData.metaClass.get = { String path, Class valueClass, defaultValue ->
			try {
				delegate.get (path, valueClass)
			} catch (Exception e) {
				defaultValue
			}
		}
	}

	@Override
	protected void configure()
	{
		bind (ConfigData).toInstance (configData)

		bind MLPassThruHttpClientHandler
		bind NotFoundHandler
		bind ApiHandler
		bind RdfHandler
		bind RecordHandler
		bind RecordListHandler

		bind (RemoteServerProperties).annotatedWith (Names.named ("XmlRepoConfig")).toInstance (configData.get ("/${appPropertyName}/xmlreposervice", RemoteServerProperties))
		bind (XmlRepository).to (XmlRepositoryImpl).asEagerSingleton()
	}
}
