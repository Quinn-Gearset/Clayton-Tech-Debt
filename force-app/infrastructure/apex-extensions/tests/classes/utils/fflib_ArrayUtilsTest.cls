/**
 * File Name: fflib_ArrayUtilsTest
 * @description
 *
 * @author architect ir. Wilhelmus G.J. Velzeboer | wim@velzeboer.nl
 */
@IsTest(IsParallel=true)
private class fflib_ArrayUtilsTest
{

    @IsTest
    static void testObjectToString()
    {
        System.assertEquals(
                new List<String> {'123', '456', '789'},
                fflib_ArrayUtils.objectToString(
                        new List<Object> {123, 456, 789}
                ), 'Checks if all the tag IDs in the list are equal.'
        );
    }

    @IsTest
    static void testObjectStringToString()
    {
        System.assertEquals(
                new List<String> {'123', '456', '789'},
                fflib_ArrayUtils.objectToString(
                        new List<Object> {'123', '456', '789'}
                ), 'Test if all conditions in the list are equal.'
        );
    }

    @IsTest
    static void itShouldReturnEmptyListOnEmptyObjectToString()
    {
        System.assertEquals(
                new List<String>(),
                fflib_ArrayUtils.objectToString(
                        new List<Object>()
                ), 'Test if all conditions in the list are equal.'
        );
    }

    @IsTest
    static void itShouldConvertSetToListOfString()
    {
        System.assertEquals(
                new List<String> {'1', '2', '3'},
                fflib_ArrayUtils.objectToString(
                        new Set<Object> {1, 2, 3}
                ), 'Test if all the conditions in the specified packages are equal.'
        );
    }

    @IsTest
    static void itShouldConvertSetObjectToSetOfIds()
    {
        Id idA = fflib_IDGenerator.generate(Account.SObjectType);
        Id idB = fflib_IDGenerator.generate(Account.SObjectType);
        System.assertEquals(
                new Set<Id> {idA, idB},
                fflib_ArrayUtils.objectToIds(
                        new Set<Object>
                        {
                                (Object) idA,
                                (Object) idB
                        }
                ), 'FFCOL Method for equality of two sets of IDs.'
        );
    }

    @IsTest
    static void itShouldReturnReversedObjectList()
    {
        System.assertEquals(
                new List<Object>
                {
                        (Object) 'C',
                        (Object) 'B',
                        (Object) 'A'
                },
                fflib_ArrayUtils.reverse(
                        new List<Object>
                        {
                                (Object) 'A',
                                (Object) 'B',
                                (Object) 'C'
                        }
                ), 'System. assertEquals - Test if all conditions in a list are equal.'
        );
    }

    @IsTest
    static void itShouldReturnReversedSObjectList()
    {
        System.assertEquals(
                new List<SObject>
                {
                        (SObject) new Account(Name = 'C'),
                        (SObject) new Account(Name = 'B'),
                        (SObject) new Account(Name = 'A')
                },
                fflib_ArrayUtils.reverse(
                        new List<SObject>
                        {
                                (SObject) new Account(Name = 'A'),
                                (SObject) new Account(Name = 'B'),
                                (SObject) new Account(Name = 'C')
                        }
                ), 'Check if all of the managed objects in the list are equals.'
        );
    }

    @IsTest
    static void itShouldConvertListOfStringsIntoUpperCase()
    {
        System.assertEquals(
                new List<String>
                {
                        'TEST A',
                        'TEST B',
                        'TEST C'
                },
                fflib_ArrayUtils.upperCase(
                        new List<String>
                        {
                                'test a',
                                'test b',
                                'test c'
                        }
                ), 'System. assertEquals - Test case.'
        );
    }

    @IsTest
    static void testLowerCase()
    {
        System.assertEquals(
                new List<String> {'abc', 'def'},
                fflib_ArrayUtils.lowerCase(
                        new List<String> {'ABC', 'DEF'}
                ), 'Test if all the strings in the list are equal.'
        );
    }

    @IsTest
    static void testIsEmpty()
    {
        List<String> aNull = null;
        System.assertEquals(true, fflib_ArrayUtils.isEmpty(aNull), 'Test if all the arguments are null.');
        System.assertEquals(true, fflib_ArrayUtils.isEmpty(new List<String> {}), 'Assert that all strings in the list are empty.');
        System.assertEquals(false, fflib_ArrayUtils.isEmpty(new List<String> {'a'}), 'Assert that all strings in the list are empty.');
        System.assertEquals(false, fflib_ArrayUtils.isEmpty(new List<String> {'a', 'b'}), 'Assert that all strings in the list are empty.');
        System.assertEquals(true, fflib_ArrayUtils.isEmpty(new List<Integer> {}), 'Assert that all integer values in the list are empty.');
        System.assertEquals(false, fflib_ArrayUtils.isEmpty(new List<Integer> {1}), 'Assert that all integer values are empty.');
        System.assertEquals(false, fflib_ArrayUtils.isEmpty(new List<Integer> {1, 2}), 'Assert that all the ints in the list are empty.');
    }

    @IsTest
    static void testIsNotEmpty()
    {
        List<String> aNull = null;
        System.assertEquals(false, fflib_ArrayUtils.isNotEmpty(aNull), 'Test if all the arguments are null.');
        System.assertEquals(false, fflib_ArrayUtils.isNotEmpty(new List<String> {}), 'Assert that all strings in the list are empty.');
        System.assertEquals(true, fflib_ArrayUtils.isNotEmpty(new List<String> {'a'}), 'Assert that all strings in the list are empty.');
        System.assertEquals(true, fflib_ArrayUtils.isNotEmpty(new List<String> {'a', 'b'}), 'Assert that all strings in the list are empty.');
        System.assertEquals(false, fflib_ArrayUtils.isNotEmpty(new List<Integer> {}), 'Assert that all integer values in the list are empty.');
        System.assertEquals(true, fflib_ArrayUtils.isNotEmpty(new List<Integer> {1}), 'Assert that all values in the list are set to 1.');
        System.assertEquals(true, fflib_ArrayUtils.isNotEmpty(new List<Integer> {1, 2}), 'Assert that all the elements in the list are equal.');
        System.assertEquals(false, fflib_ArrayUtils.isNotEmpty(new List<Account> {}), 'Assert that all accounts in the system are empty.');
        System.assertEquals(true, fflib_ArrayUtils.isNotEmpty(new List<Account> {new Account(Name = 'test')}), 'Assert that all the members of the list are empty.');
    }

    @IsTest
    static void itShouldReturnMostRecentDatetime()
    {
        // GIVEN - a list of unsorted Datetime values
        List<Datetime> datetimes = generateDateTimes();

        // WHEN - we request the maxDatetime
        Datetime maxDatetime = fflib_ArrayUtils.maxDatetime(datetimes);

        // THEN - the highest Datetime should be returned
        System.assertEquals(datetimes.get(1), maxDatetime, 'Assert that the current time is equal to the max time.');
    }

    @IsTest
    static void itShouldReturnOldestDatetime()
    {
        // GIVEN - a list of unsorted Datetime values
        List<Datetime> datetimes = generateDateTimes();

        // WHEN - we request the maxDatetime
        Datetime maxDatetime = fflib_ArrayUtils.minDatetime(datetimes);

        // THEN - the highest Datetime should be returned
        System.assertEquals(datetimes.get(4), maxDatetime, 'Assert that the current time is greater than or equal to the max datetime.');
    }

    @IsTest
    static void itShouldHandleNullInputsForMaxDatatime()
    {
        System.assertEquals(
                null, fflib_ArrayUtils.maxDatetime(new List<Datetime>()),
                'maxDatetime method was unable to handle an empty list as input'
        );
        System.assertEquals(
                null, fflib_ArrayUtils.maxDatetime(null),
                'maxDatetime method was unable to handle null as input'
        );
    }

    @IsTest
    static void itShouldCloneAndSortTheList()
    {
        // GIVEN - a list of unsorted numbers
        List<Integer> unsorted = new List<Integer>
        {
                1, 30, 2, 76, -7
        };

        // WHEN - we request the a cloned and sorted list
        List<Integer> sorted = fflib_ArrayUtils.cloneAndSort(unsorted);
        System.assertNotEquals(unsorted, sorted, 'The original object was modified, something went wrong with the cloning');
        System.assertEquals(new List<Integer> {-7, 1, 2, 30, 76}, sorted, 'Incorrect sorted list returned');
    }

    @IsTest
    static void itShouldReturnTheLastValueInTheList()
    {
        // GIVEN - a list of unsorted values
        List<Object> objects = new List<Object> {1, 2, 3, 9, 4, 7, 8};

        // WHEN - we request the last value
        Object result = fflib_ArrayUtils.lastValue(objects);

        // THEN - the highest Datetime should be returned
        System.assertEquals(8, result, 'Did not return the last value in the list of objects');
    }

    private static List<Datetime> generateDateTimes()
    {
        return new List<Datetime>
        {
                Datetime.newInstance(2020, 01, 01, 07, 59, 7),
                Datetime.newInstance(2020, 02, 01, 07, 40, 7),
                Datetime.newInstance(2020, 02, 01, 07, 00, 7),
                Datetime.newInstance(2019, 02, 01, 07, 59, 7),
                Datetime.newInstance(2018, 07, 07, 07, 7, 7)
        };
    }
}