/**
 * File Name: sflib_sflib_OperatorUtilsTest
 *
 * @author architect ir. Wilhelmus G.J. Velzeboer
 *
 * Copyright (c), W.G.J. Velzeboer,
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above author notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the author nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
@IsTest
private class fflib_OperatorUtilsTest
{
	@IsTest
	static void testBehavior()
	{
		System.assertEquals('=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.EQUALS), 'Assert that all binary values are equal.');
		System.assertEquals('!=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.NOT_EQUALS), 'Assert that all values in the string are not equal.');
		System.assertEquals('<', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.LESS_THAN), 'Assert that all binary operators are less than or equal to <.');
		System.assertEquals('<=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.LESS_THAN_OR_EQUAL_TO), 'Assert that all binary values are less than or equals to.');
		System.assertEquals('>', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.GREATER_THAN), 'Assert that all binary operators are greater than or equal to >.');
		System.assertEquals('>=', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.GREATER_THAN_OR_EQUAL_TO), 'Assert that all values in the range are greater than or equal to.');
		System.assertEquals('like', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.LIKEx), 'Assert that like operator is true.');
		System.assertEquals('IN', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.INx), 'Assert that all operands are the same as in.');
		System.assertEquals('NOT IN', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.NOT_IN), 'Assert that all operators in the array are NOT IN.');
		System.assertEquals('INCLUDES', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.INCLUDES), 'Assert that all include operators are equal.');
		System.assertEquals('EXCLUDES', fflib_OperatorUtils.operatorToString(fflib_OperatorUtils.EXCLUDES), 'Assert that all exclude operators in the exclude list are true.');
		System.assertEquals(null, fflib_OperatorUtils.operatorToString(null), 'Assert that all null operators are equal.');
	}
}