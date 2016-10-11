package config

import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.classic.gaffer.GafferConfigurator
import ch.qos.logback.core.util.StatusPrinter
import groovy.util.logging.Slf4j
import org.apache.commons.io.IOUtils
import org.slf4j.LoggerFactory

/**
 * Created by IntelliJ IDEA.
 * User: craig
 * Date: 15-07-22
 * Time: 9:27 PM
 */
@Slf4j
class AppConfigBuilder {

	static private List<String> DEFAULT_PROPERTY_FILES = [
		'/config/application.properties.groovy',
		'/etc/content-service/application.properties.groovy',
		"${System.getProperty('user.home')}/.content-service/application.properties.groovy",
		'/config/testing.properties.groovy',
		'/generated/version.properties.groovy'
	]
	static private List<String> CUSTOM_PROPERTY_FILES = []

	static ConfigObject appConfig()
	{
		/*
		 In order of descending precedence:
		 - classpath --> testing.properties
		 - user location --> ~/.content-service
		 - system location --> /etc/content-service
		 - classpath --> application.property.groovy
		 */

		ConfigObject finalProperties = new ConfigObject()
		List<String> allProperties = DEFAULT_PROPERTY_FILES + CUSTOM_PROPERTY_FILES
		allProperties.each {
			ConfigObject config
			File propertyFile = new File(it)
			InputStream propertyClasspath = getClass().getResourceAsStream(it)

			String propertyString = ''
			if (propertyClasspath)
				propertyString = IOUtils.toString(propertyClasspath)
			else if (propertyFile.exists())
				propertyString = propertyFile.text


			config = new ConfigSlurper().parse(propertyString)
			finalProperties = (ConfigObject) finalProperties.merge(config)
		}

		return finalProperties
	}

	static def addPropertyFile(String s)
	{
		String propertyFile
		if (!s.startsWith('/'))
			propertyFile = "/${s}"
		else
			propertyFile = s

		CUSTOM_PROPERTY_FILES.add(propertyFile)
	}

	static void clearProperties()
	{
		CUSTOM_PROPERTY_FILES.clear()
	}

	static boolean logBackLoaded = false

	static void loadLogback()
	{
		if (logBackLoaded) return

		/*
			Check for logback.groovy in either /etc/content-service or ~/content-service
		*/
		File systemConfigFile = new File('/etc/content-service/logback.groovy')
		File userConfigFile = new File("${System.getProperty('user.home')}/.content-service/logback.groovy")

		File configFileToLoad

		if (userConfigFile.exists())
		{
			log.debug('Located logback.groovy in ~/.content-service')
			configFileToLoad = userConfigFile
		}
		else if (systemConfigFile.exists())
		{
			log.debug('Located logback.groovy in /etc/content-service')
			configFileToLoad = systemConfigFile
		}

		if (configFileToLoad)
		{
			LoggerContext context = (LoggerContext) LoggerFactory.getILoggerFactory()
			context.reset()
			GafferConfigurator gafferConfigurator = new GafferConfigurator(context)
			gafferConfigurator.run(configFileToLoad)

			StatusPrinter.printInCaseOfErrorsOrWarnings(context)
		}

		logBackLoaded = true
	}
}
