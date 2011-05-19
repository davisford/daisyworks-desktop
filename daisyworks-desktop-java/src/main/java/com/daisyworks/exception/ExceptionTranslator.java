/**
 * 
 */
package com.daisyworks.exception;

import flex.messaging.MessageException;

/**
 * @author davisford
 *
 */
public class ExceptionTranslator implements
		org.springframework.flex.core.ExceptionTranslator {

	/* (non-Javadoc)
	 * @see org.springframework.flex.core.ExceptionTranslator#handles(java.lang.Class)
	 */
	@Override
	public boolean handles(Class<?> clazz) {
		// TODO Auto-generated method stub
		return false;
	}

	/* (non-Javadoc)
	 * @see org.springframework.flex.core.ExceptionTranslator#translate(java.lang.Throwable)
	 */
	@Override
	public MessageException translate(Throwable t) {
		// TODO Auto-generated method stub
		return null;
	}

}
