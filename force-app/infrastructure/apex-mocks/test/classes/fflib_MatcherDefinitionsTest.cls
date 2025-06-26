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
public class fflib_MatcherDefinitionsTest
{
	private static final List<fflib_IMatcher> INTERNAL_MATCHERS = new List<fflib_IMatcher>{
																new fflib_MatcherDefinitions.StringContains('bob'),
																new fflib_MatcherDefinitions.StringContains('tom'),
																new fflib_MatcherDefinitions.StringContains('fred')
															};

	private static final Date TODAY = System.today();
	private static final Datetime NOW = System.now();

	private static final SObject ACCOUNT_RECORD;
	private static final Schema.SObjectType ACCOUNT_OBJECT_TYPE;
	private static final Schema.SObjectType OPPORTUNITY_OBJECT_TYPE;
	private static final Schema.SobjectType GROUP_OBJECT_TYPE;
	private static final Sobject[] GROUP_RECORDS;
	
	static
	{
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

		ACCOUNT_OBJECT_TYPE = globalDescribe.get('Account');
		OPPORTUNITY_OBJECT_TYPE = globalDescribe.get('Opportunity');
		GROUP_OBJECT_TYPE = globalDescribe.get('Group');
		
		SObject accountRecord = ACCOUNT_OBJECT_TYPE.newSObject();
		accountRecord.put('Name', 'MatcherDefinitionTestAccount' + System.now());
		accountRecord.Id = fflib_IDGenerator.generate(Account.SObjectType);
		ACCOUNT_RECORD = accountRecord;
        
		GROUP_RECORDS = new list<Group> {
			new Group(Name = 'MatcherDefnTestGroup0'+System.now(), DeveloperName='MatcherDefnTestGroup0'+System.now().getTime(),Type='Queue'),
			new Group(Name = 'MatcherDefnTestGroup1'+System.now(), DeveloperName='MatcherDefnTestGroup1'+System.now().getTime(),Type='Queue')
		};
		insert GROUP_RECORDS;    
        
	}

	@isTest
	private static void whenConstructingCombinedWithNullConnectiveExpressionShouldThrowException()
	{
		try
		{
			fflib_IMatcher matcher = new fflib_MatcherDefinitions.Combined(null, INTERNAL_MATCHERS);
			System.assert(false, 'Expecting exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Invalid connective expression: null', e.getMessage(), 'Assert that the given connective expression is valid.');
		}
	}

	@isTest
	private static void whenConstructingCombinedWithNullInternalMatchersShouldThrowException()
	{
		try
		{
			fflib_IMatcher matcher = new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.ALL, null);
			System.assert(false, 'Expecting exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Invalid inner matchers: null', e.getMessage(), 'Assert that the inner matchers are null.');
		}
	}

	@isTest
	private static void whenConstructingCombinedWithEmptyInternalMatchersShouldThrowException()
	{
		try
		{
			fflib_IMatcher matcher = new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.ALL, new List<fflib_IMatcher>());
			System.assert(false, 'Expecting exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Invalid inner matchers: ()', e.getMessage(), 'Assert that the inner matchers are valid.');
		}
	}

	@isTest
	private static void whenCombinedMatchesWithAllExpressionShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.ALL, INTERNAL_MATCHERS);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('ted'), 'Checks that the string is tedted.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches('tomfred'), 'Checks that the string is not tofred.');
		System.assert(matcher.matches('bobtomfred'), 'Checks that the string is not empty.');
	}

	@isTest
	private static void whenCombinedMatchesWithAtLeastOneExpressionShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.AT_LEAST_ONE, INTERNAL_MATCHERS);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('ted'), 'Checks that the string is tedted.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('tomfred'), 'Assert that the string is not tofred.');
		System.assert(matcher.matches('bobtomfred'), 'Checks that the string is not empty.');
	}

	@isTest
	private static void whenCombinedMatchesWithNoneExpressionShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.NONE, INTERNAL_MATCHERS);
		System.assert(matcher.matches(null), 'Assert that the matcher matches null.');
		System.assert(matcher.matches('ted'), 'Assert that the string is tedted.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches('tomfred'), 'Checks that the string is not tofred.');
		System.assert(!matcher.matches('bobtomfred'), 'Checks that the string is not empty.');
	}

	@isTest
	private static void whenCombinedMatcherToStringReturnsExpectedString()
	{
		List<fflib_IMatcher> innerMatchers = new List<fflib_IMatcher>{
			new StringMatcher('one'),
			new StringMatcher('two'),
			new StringMatcher('three')
		};

		System.assertEquals(
			'[any of: "one", "two", "three"]',
			'' + new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.AT_LEAST_ONE, innerMatchers), 'Assert that all conditions in the hierarchy are equal.'
		);
		System.assertEquals(
			'[all of: "one", "two", "three"]',
			'' + new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.ALL, innerMatchers), 'Assert that all conditions are equal.'
		);
		System.assertEquals(
			'[none of: "one", "two", "three"]',
			'' + new fflib_MatcherDefinitions.Combined(fflib_MatcherDefinitions.Connective.NONE, innerMatchers), 'Assert that all conditions in the hierarchy are equal.'
		);
	}

	@isTest
	private static void constructEq_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.Eq(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenEqMatchesShouldReturnCorrectResults()
	{
		List<String> s1 = new List<String> {'bob', 'tom'};
		List<String> s2 = new List<String> {'bob', 'tom'};
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.Eq(s1);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(new List<String> {'bob'}), 'Checks that the string is not empty.');
		System.assert(matcher.matches(s2), 'Assert that s2 matches s1.');
		System.assert(matcher.matches(s1), 'Assert that s1 matches s2.');		
	}

	@isTest
	private static void whenEqToStringShouldReturnExpectedString()
	{
		System.assertEquals('[equals 1]', '' + new fflib_MatcherDefinitions.Eq(1), 'Assert that all strings in the argument are equal.');
	}

	@isTest
	private static void constructRefEq_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.RefEq(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenRefEqMatchesShouldReturnCorrectResults()
	{
		List<String> s1 = new List<String> {'bob', 'tom'};
		List<String> s2 = new List<String> {'bob', 'tom'};
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.RefEq(s1);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(s2), 'Checks that s2 is not the same as s1.');
		System.assert(matcher.matches(s1), 'Assert that s1 matches s2.');		
	}

	@isTest
	private static void whenRefEqToStringReturnsExpectedString()
	{
        List<String> s1 = new List<String> {'bob', 'tom'};
		System.assertEquals('[reference equals ' + JSON.serialize(s1, false) + ']', '' + new fflib_MatcherDefinitions.RefEq(s1), 'Assert that s1 and s2 are equal.');
	}

	@isTest
	private static void whenAnyBooleanMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyBoolean();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(9), 'Checks that 9 is a valid IP address.');
		System.assert(matcher.matches(true), 'Assert that the matcher matches the true value.');
		System.assert(matcher.matches(false), 'Checks that the matcher matches false.');
	}

	@isTest
	private static void whenAnyBooleanToStringReturnsExpectedString()
	{
		System.assertEquals('[any Boolean]', '' + new fflib_MatcherDefinitions.AnyBoolean(), 'Test if any Boolean is equal to any other Boolean.');
	}

	@isTest
	private static void whenAnyDateMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyDate();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(NOW), 'Checks that the current time is not the same as the current time.');
		System.assert(matcher.matches(TODAY), 'Checks that the current date is TODAY.');
	}

	@isTest
	private static void whenAnyDateToStringReturnsExpectedString()
	{
		System.assertEquals('[any Date]', '' + new fflib_MatcherDefinitions.AnyDate(), 'Checks if any date in the matcher is equal to any date in the system.');
	}

	@isTest
	private static void whenAnyDatetimeMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyDatetime();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(matcher.matches(NOW), 'Assert that the current time is within the current time range.');
		System.assert(matcher.matches(TODAY), 'Checks that the current date is TODAY.');
	}

	@isTest
	private static void whenAnyDatetimeToStringReturnsExpectedString()
	{
		System.assertEquals('[any DateTime]', '' + new fflib_MatcherDefinitions.AnyDatetime(), 'Checks if any DateTime is equal to any DateTime matcher.');
	}

	@isTest
	private static void whenAnyDecimalMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyDecimal();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(9), 'Test for presence of 9 characters in a string.');
		System.assert(matcher.matches(9L), 'Checks that 9. 9. 0 is a valid UUID.');
		System.assert(matcher.matches(9.99), 'Test for the presence of 9. 99.');
	}

	@isTest
	private static void whenAnyDecimalToStringReturnsExpectedString()
	{
		System.assertEquals('[any Decimal]', '' + new fflib_MatcherDefinitions.AnyDecimal(), 'Checks that all decimal matchers are equal.');
	}

	@isTest
	private static void whenAnyDoubleMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyDouble();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(9), 'Test for presence of 9 characters in a string.');
		System.assert(matcher.matches(9L), 'Checks that 9. 9. 0 is a valid UUID.');
		System.assert(matcher.matches(9.99), 'Test for the presence of 9. 99.');
	}

	@isTest
	private static void whenAnyDoubleToStringReturnsExpectedString()
	{
		System.assertEquals('[any Double]', '' + new fflib_MatcherDefinitions.AnyDouble(), 'Checks if any double is equal to any other value.');
	}

	@isTest
	private static void whenAnyFieldSetMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyFieldSet();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');

		Schema.FieldSet anyFieldSet = fflib_ApexMocksUtilsTest.findAnyFieldSet();
		if (anyFieldSet != null)
		{
			System.assert(matcher.matches(anyFieldSet), 'Checks that the set of fields matches the set of fields.');	
		}
	}

	@isTest
	private static void whenAnyFieldSetToStringReturnsExpectedString()
	{
		System.assertEquals('[any FieldSet]', '' + new fflib_MatcherDefinitions.AnyFieldSet(), 'Checks if all fields in the FieldSet match the Matcher.');
	}

	@isTest
	private static void whenAnyIdMatchesShouldReturnCorrectResults()
	{
		String idString = fflib_IDGenerator.generate(Account.SObjectType);
		Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyId();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(idString), 'Assert that the idString matches the matcher.');
		System.assert(matcher.matches(accountId), 'Checks that the account id matches the account id provided.');
	}

	@isTest
	private static void whenAnyIdToStringReturnsExpectedString()
	{
		System.assertEquals('[any Id]', '' + new fflib_MatcherDefinitions.AnyId(), 'Assert that all strings in the string are equal.');
	}

	@isTest
	private static void whenAnyIntegerMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyInteger();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(9L), 'Checks that 9. 9. 0 is a valid regex.');
		System.assert(!matcher.matches(9.99), 'Test for a bug in the JUnit 9. 99.');
		System.assert(matcher.matches(9), 'Test for presence of 9 characters in a string.');
	}

	@isTest
	private static void whenAnyIntegerToStringReturnsExpectedString()
	{
		System.assertEquals('[any Integer]', '' + new fflib_MatcherDefinitions.AnyInteger(), 'Checks if any integer is equal to any integer in the system.');
	}

	@isTest
	private static void whenAnyListMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyList();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(new List<String>()), 'Checks that the list of strings matches the matcher.');
		System.assert(matcher.matches(new List<Integer>()), 'Checks that the list of integers matches the matcher.');
		System.assert(matcher.matches(new List<Object>()), 'Checks that the list of objects matches the matcher.');
	}

	@isTest
	private static void whenAnyListToStringReturnsExpectedString()
	{
		System.assertEquals('[any list]', '' + new fflib_MatcherDefinitions.AnyList(), 'Assert that all strings in the list match the pattern.');
	}

	@isTest
	private static void whenAnyLongMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyLong();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(9.99), 'Test for a bug in the JUnit 9. 99.');
		System.assert(matcher.matches(9), 'Test for presence of 9 characters in a string.');
		System.assert(matcher.matches(9L), 'Checks that 9. 9. 0 is a valid UUID.');
	}

	@isTest
	private static void whenAnyLongToStringReturnsExpectedString()
	{
		System.assertEquals('[any Long]', '' + new fflib_MatcherDefinitions.AnyLong(), 'Test if any Long is equal to any other Matcher.');
	}

	@isTest
	private static void whenAnyObjectMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyObject();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(9), 'Test for presence of 9 characters in a string.');
		System.assert(matcher.matches(new List<String>()), 'Checks that the list of strings matches the matcher.');
	}

	@isTest
	private static void whenAnyObjectToStringReturnsExpectedString()
	{
		System.assertEquals('[any Object]', '' + new fflib_MatcherDefinitions.AnyObject(), 'Test if any object in the matcher is equal to any other object.');
	}

	@isTest
	private static void whenAnyStringMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnyString();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(9), 'Checks that 9 is a valid IP address.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
	}

	@isTest
	private static void whenAnyStringToStringReturnsExpectedString()
	{
		System.assertEquals('[any String]', '' + new fflib_MatcherDefinitions.AnyString(), 'Assert that all strings in the string matcher are equal.');
	}

	@isTest
	private static void whenAnySObjectMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnySObject();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(new Account()), 'Checks that the account is valid.');
	}

	@isTest
	private static void whenAnySObjectToStringReturnsExpectedString()
	{
		System.assertEquals('[any SObject]', '' + new fflib_MatcherDefinitions.AnySObject(), 'Test if any SObject in the matcher is equal to any other SObject.');
	}

	@isTest
	private static void whenAnySObjectFieldMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnySObjectField();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(new Account()), 'Checks that the account is not empty.');
		System.assert(matcher.matches(Account.Id), 'Checks that Account. Id matches');
	}

	@isTest
	private static void whenAnySObjectFieldToStringReturnsExpectedString()
	{
		System.assertEquals('[any SObjectField]', '' + new fflib_MatcherDefinitions.AnySObjectField(), 'assertEquals - Asserts that all fields in a fflib object match');
	}

	@isTest
	private static void whenAnySObjectTypeMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.AnySObjectType();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(new Account()), 'Checks that the account is not empty.');
		System.assert(matcher.matches(Account.SObjectType), 'Checks that the account type matches the expected type.');
	}

	@isTest
	private static void whenAnySObjectTypeToStringReturnsExpectedString()
	{
		System.assertEquals('[any SObjectType]', '' + new fflib_MatcherDefinitions.AnySObjectType(), 'Checks if all matchers in the matcher are equal.');
	}

	@isTest
	private static void constructDatetimeAfter_WithNullFromDatetime_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeAfter(null, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDatetimeAfter_WithNullInclusive_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeAfter(System.now(), null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenDatetimeAfterMatchesWithoutInclusiveShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeAfter(NOW, false);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(NOW.addSeconds(-1)), 'Checks that the current time is not greater than 1 second.');
		System.assert(!matcher.matches(NOW), 'Checks that the current time is not the same as the current time.');
		System.assert(matcher.matches(NOW.addSeconds(1)), 'Checks that the current time is within the interval specified by the matcher.');
	}

	@isTest
	private static void whenDatetimeAfterMatchesWithInclusiveShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeAfter(NOW, true);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(NOW.addSeconds(-1)), 'Checks that the current time is not greater than 1 second.');
		System.assert(matcher.matches(NOW), 'Assert that the current time is within the current time range.');
		System.assert(matcher.matches(NOW.addSeconds(1)), 'Checks that the current time is within the interval specified by the matcher.');
	}

	@isTest
	private static void whenDatetimeAfterWithInclusiveToStringReturnsExpectedString()
	{
		// Given
		DateTime fromDate = DateTime.newInstanceGmt(2019, 1, 1, 12, 0, 0);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeAfter(fromDate, true);

		// When
		String actual = '' + matcher;

		// Then
		System.assertEquals('[on or after "2019-01-01T12:00:00.000Z"]', actual, 'Assert that actual time is on or after 2017 - 01 - 01T12 - 00.');
	}

	@isTest
	private static void whenDatetimeAfterWithNotInclusiveToStringReturnsExpectedString()
	{
		// Given
		DateTime fromDate = DateTime.newInstanceGmt(2019, 1, 1, 12, 0, 0);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeAfter(fromDate, false);

		// When
		String actual = '' + matcher;

		// Then
		System.assertEquals('[after "2019-01-01T12:00:00.000Z"]', actual, 'Assert that actual time is after 2017 - 01 - 01T12 - 00. 000Z');
	}

	@isTest
	private static void constructDatetimeBefore_WithNullToDatetime_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeBefore(null, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDatetimeBefore_WithNullInclusive_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeBefore(System.now(), null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenDatetimeBeforeMatchesWithoutInclusiveShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBefore(NOW, false);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(NOW.addSeconds(1)), 'Checks that the current time is not greater than 1 second.');
		System.assert(!matcher.matches(NOW), 'Checks that the current time is not the same as the current time.');
		System.assert(matcher.matches(NOW.addSeconds(-1)), 'Checks that the current time is within the range of the current time.');
	}

	@isTest
	private static void whenDatetimeBeforeMatchesWithInclusiveShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBefore(NOW, true);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(NOW.addSeconds(1)), 'Checks that the current time is not greater than 1 second.');
		System.assert(matcher.matches(NOW), 'Assert that the current time is within the current time range.');
		System.assert(matcher.matches(NOW.addSeconds(-1)), 'Checks that the current time is within the range of the current time.');
	}

	@isTest
	private static void whenDatetimeBeforeWithInclusiveToStringReturnsExpectedString()
	{
		// Given
		DateTime toDate = DateTime.newInstanceGmt(2019, 1, 1, 12, 0, 0);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBefore(toDate, true);

		// When
		String actual = '' + matcher;

		// Then
		System.assertEquals('[on or before "2019-01-01T12:00:00.000Z"]', actual, 'Assert that actual time is on or before 2015 - 01 - 01T12 : 00.');
	}

	@isTest
	private static void whenDatetimeBeforeWithNotInclusiveToStringReturnsExpectedString()
	{
		// Given
		DateTime toDate = DateTime.newInstanceGmt(2019, 1, 1, 12, 0, 0);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBefore(toDate, false);

		// When
		String actual = '' + matcher;

		// Then
		System.assertEquals('[before "2019-01-01T12:00:00.000Z"]', actual, 'Assert that actual time is after 2017 - 01 - 01T12 - 00. 000Z');
	}

	@isTest
	private static void constructDatetimeBetween_WithNullFromDatetime_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeBetween(null, true, System.now(), true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDatetimeBetween_WithNullToDatetime_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeBetween(System.now(), true, null, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDatetimeBetween_WithNullInclusiveFrom_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeBetween(System.now(), null, System.now(), true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDatetimeBetween_WithNullInclusiveTo_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DatetimeBetween(System.now(), true, System.now(), null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenDatetimeBetweenMatchesWithInclusiveFromWithoutInclusiveToShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBetween(NOW.addSeconds(-1), true, NOW.addSeconds(1), false);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(NOW.addSeconds(-2)), 'Checks that the current time is not greater than 2 seconds ago.');
		System.assert(!matcher.matches(NOW.addSeconds(1)), 'Checks that the current time is not greater than 1 second.');
		System.assert(matcher.matches(NOW.addSeconds(-1)), 'Checks that the current time is within the range of the current time.');
		System.assert(matcher.matches(NOW), 'Assert that the current time is within the current time range.');
	}

	@isTest
	private static void whenDatetimeBetweenMatchesWithInclusiveToWithoutInclusiveFromShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBetween(NOW.addSeconds(-1), false, NOW.addSeconds(1), true);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches(NOW.addSeconds(2)), 'Checks that the current time is not greater than 2 seconds ago.');
		System.assert(!matcher.matches(NOW.addSeconds(-1)), 'Checks that the current time is not greater than 1 second.');
		System.assert(matcher.matches(NOW), 'Assert that the current time is within the current time range.');
		System.assert(matcher.matches(NOW.addSeconds(1)), 'Checks that the current time is within the interval specified by the matcher.');
	}

	@isTest
	private static void whenDatetimeBetweenWithInclusiveToStringReturnsExpectedString()
	{
		// Given
		DateTime fromDate = DateTime.newInstanceGmt(2019, 1, 1, 12, 0, 0);
		DateTime toDate = DateTime.newInstanceGmt(2019, 1, 3, 12, 0, 0);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBetween(fromDate, true, toDate, true);

		// When
		String actual = '' + matcher;

		// Then
		System.assertEquals('[on or after "2019-01-01T12:00:00.000Z" and on or before "2019-01-03T12:00:00.000Z"]', actual, 'Assert that actual time is on or before 2015 - 01 - 01T12 - 00.');
	}

	@isTest
	private static void whenDatetimeBetweenWithNotInclusiveToStringReturnsExpectedString()
	{
		// Given
		DateTime fromDate = DateTime.newInstanceGmt(2019, 1, 1, 12, 0, 0);
		DateTime toDate = DateTime.newInstanceGmt(2019, 1, 3, 12, 0, 0);
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.DatetimeBetween(fromDate, false, toDate, false);

		// When
		String actual = '' + matcher;

		// Then
		System.assertEquals('[after "2019-01-01T12:00:00.000Z" and before "2019-01-03T12:00:00.000Z"]', actual, 'Assert that two timestamps are equal.');
	}

	@isTest
	private static void constructDecimalBetween_WithNullLower_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalBetween(null, true, 123, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDecimalBetween_WithNullInclusiveLower_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalBetween(123, null, 123, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDecimalBetween_WithNullUpper_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalBetween(123, true, null, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDecimalBetween_WithNullInclusiveUpper_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalBetween(123, true, 123, null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenDecimalBetweenMatchesShouldReturnCorrectResults()
	{
		Integer lower = 5;
		Integer upper = 10;

		fflib_IMatcher exLowerExUpper = new fflib_MatcherDefinitions.DecimalBetween(lower, false, upper, false);
		fflib_IMatcher exLowerInUpper = new fflib_MatcherDefinitions.DecimalBetween(lower, false, upper, true);
		fflib_IMatcher inLowerExUpper = new fflib_MatcherDefinitions.DecimalBetween(lower, true, upper, false);
		fflib_IMatcher inLowerInUpper = new fflib_MatcherDefinitions.DecimalBetween(lower, true, upper, true);

		//Exclusive lower, exclusive upper
		System.assert(!exLowerExUpper.matches(lower - 1), 'Test for invalid characters.');
		System.assert(!exLowerExUpper.matches(lower), 'Checks that the string lower is not a valid string.');
		System.assert(exLowerExUpper.matches(lower + 1), 'Test that the string is a valid string.');
		System.assert(exLowerExUpper.matches(upper - 1), 'Checks that upper is a valid range.');
		System.assert(!exLowerExUpper.matches(upper), 'Checks that upper is not a valid string.');
		System.assert(!exLowerExUpper.matches(upper + 1), 'Test that upper + 1 is not a valid range.');
		System.assert(!exLowerExUpper.matches(null), 'Checks that the string is not null and that it is not a valid regular expression.');
		System.assert(!exLowerExUpper.matches('NotADecimal'), 'Checks that the string is not a decimal.');

		//Exclusive lower, inclusive upper
		System.assert(!exLowerInUpper.matches(lower - 1), 'Checks that the string lower - 1 is not a valid character.');
		System.assert(!exLowerInUpper.matches(lower), 'Checks that the string lower is not a valid string.');
		System.assert(exLowerInUpper.matches(lower + 1), 'Test that the string is a valid string.');
		System.assert(exLowerInUpper.matches(upper - 1), 'Test that upper - 1 is a valid range.');
		System.assert(exLowerInUpper.matches(upper), 'Checks that the upper case is valid.');
		System.assert(!exLowerInUpper.matches(upper + 1), 'Test that upper + 1 is not matched.');
		System.assert(!exLowerInUpper.matches(null), 'Checks that the string is not null.');
		System.assert(!exLowerInUpper.matches('NotADecimal'), 'Checks that the string is not a decimal.');
		
		//Inclusive lower, exclusive upper
		System.assert(!inLowerExUpper.matches(lower - 1), 'Checks that the string is not lower - or - upper.');
		System.assert(inLowerExUpper.matches(lower), 'Checks that the input string is a valid lowercase string and that it is a valid upper case');
		System.assert(inLowerExUpper.matches(lower + 1), 'Checks that the string is a valid string.');
		System.assert(inLowerExUpper.matches(upper - 1), 'Checks that the upper bound of the string matches the lower bound of the string.');
		System.assert(!inLowerExUpper.matches(upper), 'Checks that the upper case is not in lower case.');
		System.assert(!inLowerExUpper.matches(upper + 1), 'Checks that the upper bound is not in lower and not in upper bound.');
		System.assert(!inLowerExUpper.matches(null), 'Checks that the string is not null and is not in lower - case or not in upper');
		System.assert(!inLowerExUpper.matches('NotADecimal'), 'Checks that the string is not a decimal.');
		
		//Inclusive lower, inclusive upper
		System.assert(!inLowerInUpper.matches(lower - 1), 'Checks that the string is not lower - or upper - case.');
		System.assert(inLowerInUpper.matches(lower), 'Checks that the input string is a valid lower case string and that it is a valid upper');
		System.assert(inLowerInUpper.matches(lower + 1), 'Checks that the input is a valid string.');
		System.assert(inLowerInUpper.matches(upper - 1), 'Checks that the range of characters in lower and upper matches the range of characters in upper.');
		System.assert(inLowerInUpper.matches(upper), 'Checks that the input string matches the upper case.');
		System.assert(!inLowerInUpper.matches(upper + 1), 'Checks that the range is not 0 - based.');
		System.assert(!inLowerInUpper.matches(null), 'Checks that the input string is not null.');
		System.assert(!inLowerInUpper.matches('NotADecimal'), 'Checks that the string is not a decimal.');
	}

	@isTest
	private static void whenDecimalBetweenToStringReturnsExpectedString()
	{
		Integer lower = 5;
		Integer upper = 10;

		List<Integer> formatList = new List<Integer>{lower, upper};

		System.assertEquals(String.format('greater than {0} and less than {1}', formatList), 
			'' + new fflib_MatcherDefinitions.DecimalBetween(lower, false, upper, false), 'Assert that all values in the formatList are equal.');
		System.assertEquals(String.format('greater than {0} and less than or equal to {1}', formatList),
			'' + new fflib_MatcherDefinitions.DecimalBetween(lower, false, upper, true), 'Checks that all conditions in the list are equal.');
		System.assertEquals(String.format('greater than or equal to {0} and less than {1}', formatList),
			'' + new fflib_MatcherDefinitions.DecimalBetween(lower, true, upper, false), 'Checks that all conditions are equal.');
		System.assertEquals(String.format('greater than or equal to {0} and less than or equal to {1}', formatList),
			'' + new fflib_MatcherDefinitions.DecimalBetween(lower, true, upper, true), 'Assert equality with a list of rules.');
	}

	@isTest
	private static void constructDecimalLessThan_WithNullToMatch_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalLessThan(null, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void constructDecimalLessThan_WithNullInclusive_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalLessThan(123, null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenDecimalLessThanMatchesShouldReturnCorrectResults()
	{
		Integer toMatch = 5;

		fflib_IMatcher exclusive = new fflib_MatcherDefinitions.DecimalLessThan(toMatch, false);
		fflib_IMatcher inclusive = new fflib_MatcherDefinitions.DecimalLessThan(toMatch, true);
		
		//Exclusive
		System.assert(exclusive.matches(toMatch - 1), 'Test if the expression matches the exclusive expression.');
		System.assert(!exclusive.matches(toMatch), 'Checks that the toMatch matches the exclusive pattern.');
		System.assert(!exclusive.matches(toMatch + 1), 'Test if the next match is not exclusive.');
		System.assert(!exclusive.matches(null), 'Checks that exclusive matches are not null.');
		System.assert(!exclusive.matches('NotADecimal'), 'Checks that the string is not exclusive.');

		//Inclusive
		System.assert(inclusive.matches(toMatch - 1), 'Assert that the expression matches the expression.');
		System.assert(inclusive.matches(toMatch), 'Assert that the expression matches the expression.');
		System.assert(!inclusive.matches(toMatch + 1), 'Assert that the next match is not inclusive.');
		System.assert(!inclusive.matches(null), 'Checks that the expression is not inclusive.');
		System.assert(!inclusive.matches('NotADecimal'), 'Checks that the string is not a decimal number.');
	}

	@isTest
	private static void whenDecimalLessThanToStringReturnsExpectedString()
	{
		Integer toMatch = 5;

		System.assertEquals('[less than or equal to ' + toMatch + ']',
			'' + new fflib_MatcherDefinitions.DecimalLessThan(toMatch, true), 'Assert that the value of toMatch is less than or equal to the value of toMatch');
		System.assertEquals('[less than ' + toMatch + ']', 
			'' + new fflib_MatcherDefinitions.DecimalLessThan(toMatch, false), 'assert that the number of vowels in the catalog is less than the number of terms in');
	}

	@isTest
	private static void constructDecimalMoreThan_WithNullToMatch_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalMoreThan(null, true);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}
		
	@isTest
	private static void constructDecimalMoreThan_WithNullInclusive_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.DecimalMoreThan(123, null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}
		
	@isTest
	private static void whenDecimalMoreThanMatchesShouldReturnCorrectResults()
	{
		Integer toMatch = 5;

		fflib_IMatcher exclusive = new fflib_MatcherDefinitions.DecimalMoreThan(toMatch, false);
		fflib_IMatcher inclusive = new fflib_MatcherDefinitions.DecimalMoreThan(toMatch, true);
		
		//Exclusive
		System.assert(!exclusive.matches(toMatch - 1), 'Test if the current match is not exclusive.');
		System.assert(!exclusive.matches(toMatch), 'Checks that the toMatch matches the exclusive pattern.');
		System.assert(exclusive.matches(toMatch + 1), 'Assert that exclusive matches are not being used.');
		System.assert(!exclusive.matches(null), 'Checks that exclusive matches are not null.');
		System.assert(!exclusive.matches('NotADecimal'), 'Checks that the string is not exclusive.');

		//Inclusive
		System.assert(!inclusive.matches(toMatch - 1), 'Checks that the expression matches the expression.');
		System.assert(inclusive.matches(toMatch), 'Assert that the expression matches the expression.');
		System.assert(inclusive.matches(toMatch + 1), 'Assert that the next match is within the range of the range.');
		System.assert(!inclusive.matches(null), 'Checks that the expression is not inclusive.');
		System.assert(!inclusive.matches('NotADecimal'), 'Checks that the string is not a decimal number.');
	}

	@isTest
	private static void whenDecimalMoreThanToStringReturnsExpectedString()
	{
		Integer toMatch = 5;

		System.assertEquals('[greater than or equal to ' + toMatch + ']',
			'' + new fflib_MatcherDefinitions.DecimalMoreThan(toMatch, true), 'Assert that all values in the target value are equal or greater than or equal to the specified');
		System.assertEquals('[greater than ' + toMatch + ']', 
			'' + new fflib_MatcherDefinitions.DecimalMoreThan(toMatch, false), 'assert that vnd - tree element is equal to or greater than toMatch');
	}

	@isTest
	private static void constructFieldSetEquivalentTo_WithNullFieldSet_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.FieldSetEquivalentTo(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenFieldSetEquivalentToWithoutFieldSetShouldNeverMatch()
	{
		//Cheap test to maintain 100% code coverage, even in orgs without field sets defined.
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.FieldSetEquivalentTo();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
	}

	@isTest
	private static void whenFieldSetEquivalentToMatchesShouldReturnCorrectResults()
	{
		Schema.FieldSet anyFieldSet = fflib_ApexMocksUtilsTest.findAnyFieldSet();
		if (anyFieldSet == null)
		{
			return;
		}

		fflib_IMatcher matcher = new fflib_MatcherDefinitions.FieldSetEquivalentTo(anyFieldSet);
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('hello'), 'Test if hello is not empty.');
		System.assert(matcher.matches(anyFieldSet), 'Checks that the set of fields matches the set of fields.');
	}

	@isTest
	private static void whenFieldSetEquivalentToToStringReturnsExpectedString()
	{
		Schema.FieldSet anyFieldSet = fflib_ApexMocksUtilsTest.findAnyFieldSet();
		if (anyFieldSet == null)
		{
			return;
		}
		Set<Schema.FieldSetMember> fieldSetMembers = new Set<Schema.FieldSetMember>((anyFieldSet).getFields());

		System.assertEquals('[FieldSet with fields ' + JSON.serialize(fieldSetMembers, false) + ']', 
			'' + new fflib_MatcherDefinitions.FieldSetEquivalentTo(anyFieldSet), 'Assert that all fields in the FieldSet are equivalent to any FieldSet.');
	}

	@isTest
	private static void whenIsNullMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.IsNull();
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(null), 'Assert that the matcher matches null.');
	}

	@isTest
	private static void whenIsNullToStringReturnsExpectedString()
	{
		System.assertEquals('[is null]', '' + new fflib_MatcherDefinitions.IsNull(), 'Test if any of the matchers is null.');
	}

	@isTest
	private static void whenIsNotNullMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.IsNotNull();
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
	}

	@isTest
	private static void whenIsNotNullToStringReturnsExpectedString()
	{
		System.assertEquals('[is not null]', '' + new fflib_MatcherDefinitions.IsNotNull(), 'Assert that all string representations of a matcher are null.');
	}

	@isTest
	private static void whenListContainsMatchesShouldReturnCorrectResults()
	{
		List<String> names = new List<String>{ 'bob', 'tom', 'fred' };
		List<String> empty = new List<String>();
		
		System.assert(!new fflib_MatcherDefinitions.ListContains('fred').matches(null), 'Check that fred string is not empty.');
		System.assert(!new fflib_MatcherDefinitions.ListContains('fred').matches(empty), 'Check that all strings in the system are empty.');
		System.assert(!new fflib_MatcherDefinitions.ListContains('jack').matches(names), 'Check that all jacks in the system match the names.');
		System.assert(new fflib_MatcherDefinitions.ListContains('fred').matches(names), 'Check that all fred names in the system match the wildcard.');
		System.assert(!new fflib_MatcherDefinitions.ListContains('fred').matches('NotAList'), 'Check if string is a list of fred characters.');
	}

	@isTest
	private static void whenListContainsToStringReturnsExpectedString()
	{
		System.assertEquals('[list containing "hello"]', '' + new fflib_MatcherDefinitions.ListContains('hello'), 'assert that all strings in the string list contains hello');
	}

	@isTest
	private static void whenListIsEmptyMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.ListIsEmpty();
		
		List<String> names = new List<String>{ 'bob', 'tom', 'fred' };
		List<String> empty = new List<String>();
		
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(names), 'Checks that the names match the matcher.');
		System.assert(matcher.matches(empty), 'Assert that the matcher matches an empty string.');
		System.assert(!matcher.matches('NotAList'), 'Checks that the string Not A List is not empty.');
	}

	@isTest
	private static void whenListIsEmptyToStringReturnsExpectedString()
	{
		System.assertEquals('[empty list]', '' + new fflib_MatcherDefinitions.ListIsEmpty(), 'Checks if given list is empty.');
	}

	@isTest
	private static void constructSObjectOfType_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.SObjectOfType(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenSObjectOfTypeMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectOfType(ACCOUNT_OBJECT_TYPE);

		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(OPPORTUNITY_OBJECT_TYPE.newSObject()), 'Checks that the current object is not an OPPORTUNITY object.');
		System.assert(!matcher.matches('NotASObject'), 'Checks that the string is not a valid ASObject.');

		System.assert(matcher.matches(ACCOUNT_OBJECT_TYPE.newSObject()), 'Checks that the account object is valid.');
		System.assert(matcher.matches(ACCOUNT_RECORD), 'Checks that the account record matches the pattern.');
	}

	@isTest
	private static void whenSObjectOfTypeToStringReturnsExpectedString()
	{
		System.assertEquals('[SObject of type Account]', '' + new fflib_MatcherDefinitions.SObjectOfType(ACCOUNT_OBJECT_TYPE), 'Checks if all the matcher definitions are equal.');
	}

	@isTest
	private static void constructSObjectWith_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.SObjectWith(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null/empty: null', e.getMessage(), 'Assert that the message of the exception is equal to the message of the exception.');
		}
	}

	@isTest
	private static void constructSObjectWith_WithEmptyArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.SObjectWith(new Map<Schema.SObjectField, Object>());	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null/empty: {}', e.getMessage(), 'Assert that the argument is not null and not empty.');
		}
	}

	@isTest
	private static void whenSObjectWithMatchesShouldReturnCorrectResults()
	{
		Map<String, Schema.SObjectField> fields = ACCOUNT_OBJECT_TYPE.getDescribe().fields.getMap();
		Schema.SObjectField idField = fields.get('Id');
		Schema.SObjectField nameField = fields.get('Name');
		Schema.SObjectField createdDateField = fields.get('CreatedDate');
		
		Map<Schema.SObjectField, Object> queriedFieldValues = new Map<Schema.SObjectField, Object>
		{
			idField => ACCOUNT_RECORD.Id,
			nameField => ACCOUNT_RECORD.get('Name')
		};

		Map<Schema.SObjectField, Object> notQueriedFieldValues = new Map<Schema.SObjectField, Object>
		{
			createdDateField => System.now()
		};

		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectWith(queriedFieldValues);
		
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(OPPORTUNITY_OBJECT_TYPE.newSObject()), 'Checks that the current object is not an OPPORTUNITY object.');
		System.assert(!matcher.matches(ACCOUNT_OBJECT_TYPE.newSObject()), 'Checks that the account object is not null.');
		System.assert(!matcher.matches('NotASObject'), 'Checks that the string is not a valid ASObject.');

		System.assert(matcher.matches(ACCOUNT_RECORD), 'Checks that the account record matches the pattern.');

		System.assert(!new fflib_MatcherDefinitions.SObjectWith(notQueriedFieldValues).matches(ACCOUNT_RECORD), 'Check that all fields in the AccountRecord match');
	}

	@isTest
	private static void whenSObjectWithToStringReturnsExpectedString()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectWith(new Map<Schema.SObjectField, Object>{
			Account.Name => 'Test'
		});
		System.assertEquals('[SObject with fields {"Name":"Test"}]', '' + matcher, 'Assert that the matcher is equal to the object.');
	}

	@isTest
	private static void whenSObjectsWithInOrderMatchesShouldReturnCorrectResults()
	{
		Map<String, Schema.SObjectField> fields = GROUP_OBJECT_TYPE.getDescribe().fields.getMap();
		Schema.SObjectField idField = fields.get('Id');
		Schema.SObjectField nameField = fields.get('Name');
		Schema.SObjectField createdDateField = fields.get('CreatedDate');
		
		list<Map<Schema.SObjectField, Object>> queriedFieldValues = new list<Map<Schema.SObjectField, Object>>
		{
            new map<Schema.SObjectField,Object> 
            {
                idField => GROUP_RECORDS[0].Id,
				nameField => GROUP_RECORDS[0].get('Name')
            },
            new map<Schema.SObjectField,Object> 
            {
                idField => GROUP_RECORDS[1].Id,
				nameField => GROUP_RECORDS[1].get('Name')
            }               
		};

		list<Map<Schema.SObjectField, Object>> failingFieldValues = new list<Map<Schema.SObjectField, Object>>
		{
			new map<Schema.SObjectField,Object>
			{
				idField => GROUP_RECORDS[0].Id,
				nameField => GROUP_RECORDS[0].get('Name')
			},
			new map<Schema.SObjectField,Object>
			{
				idField => GROUP_RECORDS[1].Id,
				nameField => GROUP_RECORDS[1].get('Name') + 'test'
			}
		};

		list<Map<Schema.SObjectField, Object>> notQueriedFieldValues = new list<Map<Schema.SObjectField, Object>>
		{
			new map<Schema.SObjectField,Object> 
            {
                createdDateField => System.now()
            },
            new map<Schema.SObjectField,Object> 
            {
                createdDateField => System.now()
            }    
		};

		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectsWith(queriedFieldValues);
		
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(new list<SObject>
                                       {
                                           OPPORTUNITY_OBJECT_TYPE.newSObject(),
                                           OPPORTUNITY_OBJECT_TYPE.newSObject()    
                                       }
                                      ), 'This method is called from the assert code to assert that the list of objects in the system');
		System.assert(!matcher.matches(new list<SObject>
                                       {
                                           GROUP_OBJECT_TYPE.newSObject(),
                                           GROUP_OBJECT_TYPE.newSObject()
                                       }
                                      ),'sObjectsWith arity agrees but arg doesn\'t');
		System.assert(!matcher.matches('NotAListofSObject'), 'Checks that the string is not a list of SObjects.');

		System.assert(matcher.matches(GROUP_RECORDS),'toMatch and args have same arity and in same order');
        System.assert (!matcher.matches(new list<SObject> {GROUP_RECORDS[1],GROUP_RECORDS[0]}),
                                     'sObjectsWith toMatch and args have same arity but args are in different order than toMatch') ;            
                      

		System.assert(!new fflib_MatcherDefinitions.SObjectsWith(notQueriedFieldValues).matches(GROUP_RECORDS), 'Check that all group records in the group match the pattern specified in the group_rec_');
		System.assert(!new fflib_MatcherDefinitions.SObjectsWith(failingFieldValues).matches(GROUP_RECORDS), 'Check that all group records in the group match the pattern specified in the FATAL_FIELD');
	}

    @isTest
	private static void whenSObjectsInAnyOrderWithMatchesShouldReturnCorrectResults()
	{
		Map<String, Schema.SObjectField> fields = GROUP_OBJECT_TYPE.getDescribe().fields.getMap();
		Schema.SObjectField idField = fields.get('Id');
		Schema.SObjectField nameField = fields.get('Name');
		Schema.SObjectField createdDateField = fields.get('CreatedDate');
		
		list<Map<Schema.SObjectField, Object>> queriedFieldValues = new list<Map<Schema.SObjectField, Object>>
		{
            new map<Schema.SObjectField,Object> 
            {
                idField => GROUP_RECORDS[0].Id,
				nameField => GROUP_RECORDS[0].get('Name')
            },
            new map<Schema.SObjectField,Object> 
            {
                idField => GROUP_RECORDS[1].Id,
				nameField => GROUP_RECORDS[1].get('Name')
            }               
		};

		list<Map<Schema.SObjectField, Object>> notQueriedFieldValues = new list<Map<Schema.SObjectField, Object>>
		{
			new map<Schema.SObjectField,Object> 
            {
                createdDateField => System.now()
            },
            new map<Schema.SObjectField,Object> 
            {
                createdDateField => System.now()
            }    
		};

		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectsWith(queriedFieldValues,false); // any order
		
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(new list<SObject>
                                       {
                                           OPPORTUNITY_OBJECT_TYPE.newSObject(),
                                           OPPORTUNITY_OBJECT_TYPE.newSObject()    
                                       }
                                      ), 'This method is called from the assert code to assert that the list of objects in the system');
		System.assert(!matcher.matches(new list<SObject>
                                       {
                                           GROUP_OBJECT_TYPE.newSObject(),
                                           GROUP_OBJECT_TYPE.newSObject()
                                       }
                                      ),'sObjectsWith arity agrees but arg doesn\'t match matcher');
		System.assert(!matcher.matches('NotAListofSObject'), 'Checks that the string is not a list of SObjects.');

		System.assert(matcher.matches(GROUP_RECORDS),'toMatch and args have same arity and in same order. Match should be OK');
        System.assert (matcher.matches(new list<SObject> {GROUP_RECORDS[1],GROUP_RECORDS[0]}),
                                     'sObjectsWith toMatch and args have same arity but args are in diff order than matcher. Should be OK') ;            
                      

		System.assert(!new fflib_MatcherDefinitions.SObjectsWith(notQueriedFieldValues,false).matches(GROUP_RECORDS), 'Check that all group records in the group match the pattern group_recors.');
	}

	@isTest
	private static void whenSObjectsWithToStringReturnsExpectedString()
	{
		List<Map<Schema.SObjectField, Object>> toMatch = new List<Map<Schema.SObjectField, Object>>{
			new Map<Schema.SObjectField, Object> {
				Account.Name => 'Test'
			}
		};

		System.assertEquals('[ordered SObjects with [{"Name":"Test"}]]', '' + new fflib_MatcherDefinitions.SObjectsWith(toMatch, true), 'Assert that all objects in the specified order match the objects in the specified order.');
		System.assertEquals('[unordered SObjects with [{"Name":"Test"}]]', '' + new fflib_MatcherDefinitions.SObjectsWith(toMatch, false), 'Assert that all objects in the tree match the given matchers.');
	}

	@isTest
	private static void whenSObjectsWithDifferentArityMatchesShouldReturnFalse()
	{
		List<Map<Schema.SObjectField, Object>> toMatch = new List<Map<Schema.SObjectField, Object>>{
			new Map<Schema.SObjectField, Object> {
				Account.Name => 'Test'
			}
		};
		Boolean matchResult = new fflib_MatcherDefinitions.SObjectsWith(toMatch).matches(new List<SObject>{});
		System.assertEquals(matchResult, false, 'Assert that the matchResult is false.');	
	}

	@isTest
	private static void constructSObjectsWith_WithNullArg_ThrowsException()
	{
		try {
			new fflib_MatcherDefinitions.SObjectsWith(null);
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null/empty/other than list of map<Schema.SobjectField,Object>: null', e.getMessage(), 'Assert that arg is not null or empty other than list of maps');
		}
	}

	@isTest
	private static void constructSObjectWithId_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.SObjectWithId(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenSObjectWithIdMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectWithId(ACCOUNT_RECORD.Id);

		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(OPPORTUNITY_OBJECT_TYPE.newSObject()), 'Checks that the current object is not an OPPORTUNITY object.');
		System.assert(!matcher.matches(ACCOUNT_OBJECT_TYPE.newSObject()), 'Checks that the account object is not null.');
		System.assert(!matcher.matches('NotASObject'), 'Checks that the string is not a valid ASObject.');

		System.assert(matcher.matches(ACCOUNT_RECORD), 'Checks that the account record matches the pattern.');
	}

	@isTest
	private static void whenSObjectWithIdToStringReturnsExpectedString()
	{
		Id recordId = '001000000000001AAA';
		System.assertEquals('[SObject with Id "001000000000001AAA"]', '' + new fflib_MatcherDefinitions.SObjectWithId(recordId), 'Checks that recordId is equal to 01000000000001AAA.');
	}

	@isTest
	private static void constructSObjectWithName_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.SObjectWithName(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenSObjectWithNameMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.SObjectWithName((String)ACCOUNT_RECORD.get('Name'));

		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(OPPORTUNITY_OBJECT_TYPE.newSObject()), 'Checks that the current object is not an OPPORTUNITY object.');
		System.assert(!matcher.matches(ACCOUNT_OBJECT_TYPE.newSObject()), 'Checks that the account object is not null.');
		System.assert(!matcher.matches('NotASObject'), 'Checks that the string is not a valid ASObject.');

		System.assert(matcher.matches(ACCOUNT_RECORD), 'Checks that the account record matches the pattern.');
	}

	@isTest
	private static void whenSObjectWithNameToStringReturnsExpectedString()
	{
		System.assertEquals('[SObject with Name "Test"]', '' + new fflib_MatcherDefinitions.SObjectWithName('Test'), 'Test matcher for string equality.');
	}

	@isTest
	private static void whenStringContainsMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.StringContains('bob');
		System.assert(!matcher.matches(7), 'Checks that the current system is not running on a machine running on a machine running on a');
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(''), 'Checks that the string is not empty.');
		System.assert(!matcher.matches('blob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('bobby'), 'Checks that the string is a valid barebones string.');
	}

	@isTest
	private static void constructStringContains_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.StringContains(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenStringContainsToStringReturnsExpectedStrings()
	{
		System.assertEquals('[contains "hello"]', '' + new fflib_MatcherDefinitions.StringContains('hello'), 'Assert that all string elements in the string match the regex.');
	}

	@isTest
	private static void whenStringEndsWithMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.StringEndsWith('bob');
		System.assert(!matcher.matches(7), 'Checks that the current system is not running on a machine running on a machine running on a');
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(''), 'Checks that the string is not empty.');
		System.assert(!matcher.matches('bobby'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('jimbob'), 'Assert that jimbob is not empty.');
	}

	@isTest
	private static void constructStringEndsWith_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.StringEndsWith(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenStringEndsWithToStringReturnsExpectedStrings()
	{
		System.assertEquals('[ends with "hello"]', '' + new fflib_MatcherDefinitions.StringEndsWith('hello'), 'Test if string ends with hello');
	}

	@isTest
	private static void whenIsBlankWithMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.StringIsBlank();
		System.assert(!matcher.matches(7), 'Checks that the current system is not running on a machine running on a machine running on a');
		System.assert(!matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches(null), 'Assert that the matcher matches null.');
		System.assert(matcher.matches(''), 'Assert that the string is empty.');
	}

	@isTest
	private static void whenStringIsBlankToStringReturnsExpectedStrings()
	{
		System.assertEquals('[blank String]', '' + new fflib_MatcherDefinitions.StringIsBlank(), 'Checks if all string elements are null.');
	}

	@isTest
	private static void whenIsNotBlankWithMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.StringIsNotBlank();
		System.assert(!matcher.matches(7), 'Checks that the current system is not running on a machine running on a machine running on a');
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(''), 'Checks that the string is not empty.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
	}

	@isTest
	private static void whenStringIsNotBlankToStringReturnsExpectedStrings()
	{
		System.assertEquals('[non-blank String]', '' + new fflib_MatcherDefinitions.StringIsNotBlank(), 'Assert that string is not blank.');
	}

	@isTest
	private static void whenStringMatchesMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.StringMatches('(b|m)o[a-z]*');
		System.assert(!matcher.matches(7), 'Checks that the current system is not running on a machine running on a machine running on a');
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches('bib'), 'Checks that the string is not empty.');
		System.assert(!matcher.matches('jimbob'), 'Checks that jimbob is not empty.');
		System.assert(!matcher.matches('tom'), 'Checks that the string is not to the top of the string.');
		System.assert(!matcher.matches('bob1'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('bobby'), 'Checks that the string is a valid barebones string.');
		System.assert(matcher.matches('mo'), 'Test if mo is empty.');
	}

	@isTest
	private static void whenStringMatchesToStringReturnsExpectedStrings()
	{
		System.assertEquals('[matches regex "hello"]', '' + new fflib_MatcherDefinitions.StringMatches('hello'), 'Assert that all string elements in the string match regex.');
	}

	@isTest
	private static void constructStringMatches_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.StringMatches(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenStringStartsWithMatchesShouldReturnCorrectResults()
	{
		fflib_IMatcher matcher = new fflib_MatcherDefinitions.StringStartsWith('bob');
		System.assert(!matcher.matches(7), 'Checks that the current system is not running on a machine running on a machine running on a');
		System.assert(!matcher.matches(null), 'Assert that the matcher does not match null.');
		System.assert(!matcher.matches(''), 'Checks that the string is not empty.');
		System.assert(!matcher.matches('jimbob'), 'Checks that jimbob is not empty.');
		System.assert(matcher.matches('bob'), 'Checks that the string is not empty.');
		System.assert(matcher.matches('bobby'), 'Checks that the string is a valid barebones string.');
	}

	@isTest
	private static void whenStringStartsWithToStringReturnsExpectedStrings()
	{
		System.assertEquals('[starts with "hello"]', '' + new fflib_MatcherDefinitions.StringStartsWith('hello'), 'Test if string starts with hello');
	}

	@isTest
	private static void constructStringStartsWith_WithNullArg_ThrowsException()
	{
		try
		{
			new fflib_MatcherDefinitions.StringStartsWith(null);	
			System.assert(false, 'Expected exception');
		}
		catch (fflib_ApexMocks.ApexMocksException e)
		{
			System.assertEquals('Arg cannot be null: null', e.getMessage(), 'Assert that the given argument is not null.');
		}
	}

	@isTest
	private static void whenJSONExceptionOccursStringifyShouldReturnsObjectToString()
	{
		// SObjectField object definitely can't be serialized by JSON.serialize() method
		Schema.SObjectField sObjField = Account.Description;
		System.assertEquals('' + sObjField, fflib_MatcherDefinitions.stringify(sObjField), 'assertEquals - Assert equality of string');
	}

	private class StringMatcher implements fflib_IMatcher
	{
		private final String value;

		public StringMatcher(String value)
		{
			this.value = value;
		}

		public Boolean matches(Object arg)
		{
			return true;
		}

		public override String toString()
		{
			return '"' + value + '"';
		}
	}
}
