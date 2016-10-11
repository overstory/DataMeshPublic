package testcommon.docker

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 6/5/15
 * Time: 5:31 PM
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface RequiresDockerContainer{
	String [] value()
}
