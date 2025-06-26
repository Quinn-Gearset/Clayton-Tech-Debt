/*
 * Copyright (c) 2016-2017 FinancialForce.com, inc.  All rights reserved.
 */
@isTest
public with sharing class fflib_QualifiedMethodTest
{
	@isTest
	private static void equalsReturnsExpectedResults()
	{
		//Given
		fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class } );
		fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class } );
		fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ String.class } );
		fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod('Type2', 'Method2', new List<Type>{ Integer.class, String.class, fflib_QualifiedMethodTest.class } );
		fflib_QualifiedMethod qm5 = new fflib_QualifiedMethod('', '', new List<Type>{} );
		fflib_QualifiedMethod qm6 = new fflib_QualifiedMethod(null, null, null );

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
		fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class } );
		fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class } );
		fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ String.class } );
		fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod('Type2', 'Method2', new List<Type>{ Integer.class, String.class, fflib_QualifiedMethodTest.class } );
		fflib_QualifiedMethod qm5 = new fflib_QualifiedMethod('', '', new List<Type>{} );
		fflib_QualifiedMethod qm6 = new fflib_QualifiedMethod(null, null, null );

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

	@isTest
	public static void toStringReturnsExpectedResult()
	{
		System.assertEquals('MyClass.MyMethod(Integer)', new fflib_QualifiedMethod('MyClass', 'MyMethod', new List<Type>{ Integer.class }).toString(), 'Test for equality of declared methods on class MyClass.');
	}

	@isTest
	private static void equalsReturnsExpectedResultsForHasDependentMocks()
	{
		//Given
		String instance = 'My object instance';
		String instance2 = 'My other object instance';
		fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class } );
		fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class }, instance);
		fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class }, instance);
		fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class }, instance2);

		//When/thens
		fflib_ApexMocksConfig.HasIndependentMocks = false;
		
		System.assertEquals(qm1, qm2, 'Assert that two Quaternion objects are equal.');
		System.assertEquals(qm1, qm3, 'Assert that the two Quaternion objects are equal.');
		System.assertEquals(qm1, qm4, 'Assert equality of two Quaternion objects.');

		fflib_ApexMocksConfig.HasIndependentMocks = true;

		System.assertNotEquals(qm1, qm2, 'Assert that two Quaternion objects are not equal.');
		System.assertNotEquals(qm1, qm3, 'Assert that qm1 and qm3 are not equal.');
		System.assertNotEquals(qm1, qm4, 'Assert that qm1 and qm4 are not equal.');

		System.assertEquals(qm2, qm3, 'Assert equality of 2 and 3 MusicalMass objects.');
		System.assertNotEquals(qm2, qm4, 'Assert that 2 and 4 matrix objects are not equal.');

		System.assertNotEquals(qm3, qm4, 'Assert that qm3 and qm4 are not equal.');
	}

	@isTest
	private static void hashCodeReturnsExpectedResultsForHasDependentMocks()
	{
		//Given
		String instance = 'My object instance';
		String instance2 = 'My other object instance';
		fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class } );
		fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class }, instance);
		fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class }, instance);
		fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod('Type1', 'Method1', new List<Type>{ Integer.class }, instance2);

		//When/thens
		fflib_ApexMocksConfig.HasIndependentMocks = false;
		
		System.assertEquals(qm1.hashCode(), qm2.hashCode(), 'Assert that the hash codes of the two objects are the same.');
		System.assertEquals(qm1.hashCode(), qm3.hashCode(), 'Assert that the hash codes of the objects are the same.');
		System.assertEquals(qm1.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the objects are the same.');

		fflib_ApexMocksConfig.HasIndependentMocks = true;

		System.assertNotEquals(qm1.hashCode(), qm2.hashCode(), 'Assert that the hash codes of the two objects are not the same.');
		System.assertNotEquals(qm1.hashCode(), qm3.hashCode(), 'Assert that the hash codes of the objects are not the same.');
		System.assertNotEquals(qm1.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the objects are not the same.');

		System.assertEquals(qm2.hashCode(), qm3.hashCode(), 'Assert that the hash codes of the objects are the same.');
		System.assertNotEquals(qm2.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the 2 and 4 strings are not the same.');

		System.assertNotEquals(qm3.hashCode(), qm4.hashCode(), 'Assert that the hash codes of the 3 and 4 strings are not the same.');
	}
}