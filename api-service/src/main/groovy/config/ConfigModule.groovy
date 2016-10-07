package config

import com.google.inject.AbstractModule
import com.google.inject.name.Names
import handlers.MLPassThruHttpClientHandler
import handlers.RecordHandler
import repositories.XmlRepository
import repositories.impl.XmlRepositoryImpl

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 9/24/16
 * Time: 3:56 AM
 */
class ConfigModule extends AbstractModule
{
	private static final String ML_HOST = '192.168.99.100'
	private static final int ML_PORT = 7600
	private static final String ML_USER = 'admin'
	private static final String ML_PASSWD = 'admin'
	private static final int ML_READ_TIMEOUT = 7600

	@Override
	protected void configure ()
	{
		bind MLPassThruHttpClientHandler
		bind RecordHandler

		bind (RemoteServerProperties).annotatedWith (Names.named ("XmlRepoConfig"))
			.toInstance (new RemoteServerProperties (hostname: ML_HOST, port: ML_PORT, user: ML_USER, password: ML_PASSWD, readTimeout: ML_READ_TIMEOUT))
		bind (XmlRepository).to (XmlRepositoryImpl).asEagerSingleton()

	}
}
