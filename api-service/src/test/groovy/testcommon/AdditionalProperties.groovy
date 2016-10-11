package testcommon

import java.lang.annotation.ElementType
import java.lang.annotation.Retention
import java.lang.annotation.RetentionPolicy
import java.lang.annotation.Target

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 7/21/15
 * Time: 5:31 PM
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface AdditionalProperties {
	String [] value()
}
