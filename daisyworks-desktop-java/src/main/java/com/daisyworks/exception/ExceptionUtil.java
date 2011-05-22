/**
 * 
 */
package com.daisyworks.exception;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;

/**
 * 
 */
public class ExceptionUtil {

	/** 
	 * Convert a stack trace to a printable string
	 * @param t throwable
	 * @return string with stack trace
	 */
	public static String getStackTraceAsString(Throwable t) {
		final Writer result = new StringWriter();
		final PrintWriter printWriter = new PrintWriter(result);
		t.printStackTrace(printWriter);
		return result.toString();
	}
}
