/**
 * Copyright (c) 2014-2016, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
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
@isTest
public with sharing class fflib_MethodArgValuesTest
{
	@isTest
	private static void equalsReturnsExpectedResults()
	{
		//Given
		fflib_MethodArgValues qm1 = new fflib_MethodArgValues(new List<Object>{ 'hello' });
		fflib_MethodArgValues qm2 = new fflib_MethodArgValues(new List<Object>{ 'hello' });
		fflib_MethodArgValues qm3 = new fflib_MethodArgValues(new List<Object>{ 'hi' });
		fflib_MethodArgValues qm4 = new fflib_MethodArgValues(new List<Object>{ 'hello', 'hello', 'hello' });
		fflib_MethodArgValues qm5 = new fflib_MethodArgValues(new List<Object>());
		fflib_MethodArgValues qm6 = new fflib_MethodArgValues(null);

		//When/thens
		System.assertEquals(qm1, qm1, 'Assert that qm1 and qm2 are equal.');
		System.assertEquals(qm1, qm2, 'Assert that two Quaternion objects are equal.');
		System.assertNotEquals(qm1, qm3, 'Assert that qm1 and qm3 are not equal.');
		System.assertNotEquals(qm1, qm4, 'Assert that qm1 and qm4 are not equal.');
		System.assertNotEquals(qm1, qm5, 'Assert that the two Quaternion objects are not equal.');
		System.assertNotEquals(qm1, qm6, 'Assert that qm1 and qm6 are not equal.');

		System.assertEquals(qm2, qm2, 'Assert equality of two Quaternion objects.');
		System.assertNotEquals(qm2, qm3, 'Assert that 2 and 3 MusicQuery objects are not equal.');
		System.assertNotEquals(qm2, qm4, 'Assert that 2 and 4 matrix objects are not equal.');
		System.assertNotEquals(qm2, qm5, 'Assert that 2 and 5 musn t be equal.');
		System.assertNotEquals(qm2, qm6, 'Assert that qm2 and qm6 are not equal.');

		System.assertEquals(qm3, qm3, 'Assert that qm3 is equal to qm3');
		System.assertNotEquals(qm3, qm4, 'Assert that qm3 and qm4 are not equal.');
		System.assertNotEquals(qm3, qm5, 'Assert that qm3 and qm5 are not equal.');
		System.assertNotEquals(qm3, qm6, 'Assert that qm3 and qm6 are not equal.');

		System.assertEquals(qm4, qm4, 'Assert that qm4 is equal to qm4.');
		System.assertNotEquals(qm4, qm5, 'Assert that qm4 and qm5 are not equal.');
		System.assertNotEquals(qm4, qm6, 'Assert that qm4 and qm6 are not equal.');

		System.assertEquals(qm5, qm5, 'Assert that qm5 is equal to qm5');
		System.assertNotEquals(qm5, qm6, 'Assert that 5 and 6 numbers are not equal.');

		System.assertEquals(qm6, qm6, 'Assert equality of qm6 and qm6_x.');
	}

	@isTest
	private static void hashCodeReturnsExpectedResults()
	{
		//Given
		fflib_MethodArgValues qm1 = new fflib_MethodArgValues(new List<Object>{ 'hello' });
		fflib_MethodArgValues qm2 = new fflib_MethodArgValues(new List<Object>{ 'hello' });
		fflib_MethodArgValues qm3 = new fflib_MethodArgValues(new List<Object>{ 'hi' });
		fflib_MethodArgValues qm4 = new fflib_MethodArgValues(new List<Object>{ 'hello', 'hello', 'hello' });
		fflib_MethodArgValues qm5 = new fflib_MethodArgValues(new List<Object>());
		fflib_MethodArgValues qm6 = new fflib_MethodArgValues(null);

		//When/thens
		System.assertEquals(qm1.hashCode(), qm1.hashCode(), 'Assert that qm1 and qm2 are the same.');
		System.assertEquals(qm1.hashCode(), qm2.hashCode(), 'Assert that the hash codes of the two objects are the same.');
		System.assertNotEquals(qm1.hashCode(), qm3.hashCode(), 'Assert that the hash codes of the objects are not the same.');
		System.assertNotEquals(qm1.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the objects are not the same.');
		System.assertNotEquals(qm1.hashCode(), qm5.hashCode(), 'Assert that the hash codes of the two objects are not the same.');
		System.assertNotEquals(qm1.hashCode(), qm6.hashCode(), 'Assert that the hash codes of the objects are not the same.');

		System.assertEquals(qm2.hashCode(), qm2.hashCode(), 'Assert that qm2 and qm2 are the same.');
		System.assertNotEquals(qm2.hashCode(), qm3.hashCode(), 'Assert that the hash codes of the objects are not the same.');
		System.assertNotEquals(qm2.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the 2 and 4 strings are not the same.');
		System.assertNotEquals(qm2.hashCode(), qm5.hashCode(), 'Assert that 2 and 5 hash codes are not the same.');
		System.assertNotEquals(qm2.hashCode(), qm6.hashCode(), 'Assert that the hash codes of the objects are not the same.');

		System.assertEquals(qm3.hashCode(), qm3.hashCode(), 'Assert that the hash code of the 3 - tuple is the same as the hash code of');
		System.assertNotEquals(qm3.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the 3 and 4 strings are not the same.');
		System.assertNotEquals(qm3.hashCode(), qm5.hashCode(), 'Assert that the hash codes of the 3 and 5 objects are not the same.');
		System.assertNotEquals(qm3.hashCode(), qm6.hashCode(), 'Assert that the hash codes of the 3 and 6 are not the same.');

		System.assertEquals(qm4.hashCode(), qm4.hashCode(), 'Assert that the hash code of the 4 - character MM4 string is the same as the');
		System.assertNotEquals(qm4.hashCode(), qm5.hashCode(), 'Assert that the hash codes of the 4 and 5 objects are not the same.');
		System.assertNotEquals(qm4.hashCode(), qm6.hashCode(), 'Assert that the hash codes of the 4 and 6 symbols are not the same.');

		System.assertEquals(qm5.hashCode(), qm5.hashCode(), 'Assert that qm5 and qm4 are the same.');
		System.assertNotEquals(qm5.hashCode(), qm6.hashCode(), 'Assert that the hash codes of the objects are not the same.');

		System.assertEquals(qm6.hashCode(), qm6.hashCode(), 'Test for equality of hash code of qm6');
	}
}