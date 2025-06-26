/*
    Copyright (c) 2019 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer batch processing and record creation
*/

@isTest
public with sharing class BDI_DataImport_TEST {
    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = firstname + '@' + lastname + '.com'
        );
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @param donationamount the amount to use for the donation
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, Integer donationamount) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = firstname + '@' + lastname + '.com',
           Donation_Amount__c = donationamount,
           Donation_Date__c = System.today()
        );
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @param firstname2 the firstname to specify for Contact2
    * @param lastname2 the lastname to specify for Contact2
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, String firstname2, String lastname2) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = (lastname == null ? null : firstname + '@' + lastname + '.com'),
           Contact2_Firstname__c = firstname2,
           Contact2_Lastname__c = lastname2,
           Contact2_Personal_Email__c = (lastname2 == null ? null : firstname2 + '@' + lastname2 + '.com')
        );
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @param firstname2 the firstname to specify for Contact2
    * @param lastname2 the lastname to specify for Contact2
    * @param address the address to use for the Data Import record
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, String firstname2, String lastname2, Address__c address) {
        return new DataImport__c(
                Contact1_Firstname__c = firstname,
                Contact1_Lastname__c = lastname,
                Contact1_Personal_Email__c = (lastname == null ? null : firstname + '@' + lastname + '.com'),
                Contact2_Firstname__c = firstname2,
                Contact2_Lastname__c = lastname2,
                Contact2_Personal_Email__c = (lastname2 == null ? null : firstname2 + '@' + lastname2 + '.com'),
                Home_City__c = (address.MailingCity__c == null ? null : address.MailingCity__c),
                Home_State_Province__c = (address.MailingState__c == null ? null : address.MailingState__c),
                Home_Country__c = (address.MailingCountry__c == null ? null : address.MailingCountry__c)
        );
    }

    /*
    * @description checks if the batch status gets set to Open
    * when dis are not all Imported
    * and when we don't have Failed dis
    * and the remaining dis are in an open state
    */
    @IsTest
    static void shouldSetBatchStatusToOpen() {
        DataImportBatch__c bdi = BDI_DataImportAPI_TEST.newBatch('testBatch', true);

        DataImport__c di1 = newDi('fname1', 'lname1');
        di1.NPSP_Data_Import_Batch__c = bdi.Id;
        DataImport__c di2 = newDi('fname2', 'lname2');
        di2.NPSP_Data_Import_Batch__c = bdi.Id;
        DataImport__c di3 = newDi('fname3', 'lname3');
        di3.NPSP_Data_Import_Batch__c = bdi.Id;
        List<DataImport__c> dis = new List<DataImport__c> {di1, di2, di3};
        insert dis;

        bdi = [SELECT Id, Batch_Status__c FROM DataImportBatch__c
                WHERE Id = :bdi.Id];

        System.assertEquals(BDI_DataImport_API.BATCH_STATUS_OPEN, bdi.Batch_Status__c,
                            'The batch status should be Open when all ' +
                            'data import records are Open.');

        Test.startTest();
        // set the statuses to a mix of dry run validated, and dry run error
        di1.Status__c = BDI_DataImport_API.bdiDryRunValidated;
        di2.Status__c = BDI_DataImport_API.bdiDryRunValidated;
        di3.Status__c = BDI_DataImport_API.bdiDryRunError;
        update dis;
        Test.stopTest();

        bdi = [SELECT Id, Batch_Status__c FROM DataImportBatch__c
                WHERE Id = :bdi.Id];

        System.assertEquals(BDI_DataImport_API.BATCH_STATUS_OPEN, bdi.Batch_Status__c,
                            'The batch status should be Open when all ' +
                            'data import records are Open.');
    }

    /*
    * @description checks if the batch status gets set to failed
    * when at least one di record has failed
    */
    @IsTest
    static void shouldSetBatchStatusToFailed() {
        DataImportBatch__c bdi = BDI_DataImportAPI_TEST.newBatch('testBatch', true);

        DataImport__c di1 = newDi('fname1', 'lname1');
        di1.NPSP_Data_Import_Batch__c = bdi.Id;
        DataImport__c di2 = newDi('fname2', 'lname2');
        di2.NPSP_Data_Import_Batch__c = bdi.Id;
        DataImport__c di3 = newDi('fname3', 'lname3');
        di3.NPSP_Data_Import_Batch__c = bdi.Id;
        List<DataImport__c> dis = new List<DataImport__c> {di1, di2, di3};
        insert dis;

        Test.startTest();
        // make one di record fail
        di2.Status__c = BDI_DataImport_API.bdiFailed;
        update di2;
        Test.stopTest();

        bdi = [SELECT Id, Batch_Status__c FROM DataImportBatch__c
                WHERE Id = :bdi.Id];

        System.assertEquals(BDI_DataImport_API.BATCH_STATUS_FAILED, bdi.Batch_Status__c,
                            'The batch status should be Failed when at least one ' +
                            'data import record has failed.');

    }

    /*
    * @description checks if the batch status gets set to imported
    * when all the di records are imported
    */
    @IsTest
    static void shouldSetBatchStatusToCompleted() {
        DataImportBatch__c bdi = BDI_DataImportAPI_TEST.newBatch('testBatch', true);

        DataImport__c di1 = newDi('fname1', 'lname1');
        di1.NPSP_Data_Import_Batch__c = bdi.Id;
        DataImport__c di2 = newDi('fname2', 'lname2');
        di2.NPSP_Data_Import_Batch__c = bdi.id;
        DataImport__c di3 = newDi('fname3', 'lname3');
        di3.NPSP_Data_Import_Batch__c = bdi.Id;
        List<DataImport__c> dis = new List<DataImport__c> {di1, di2, di3};
        insert dis;

        Test.startTest();
        // make all dis imported
        di1.Status__c = BDI_DataImport_API.bdiImported;
        di2.Status__c = BDI_DataImport_API.bdiImported;
        di3.Status__c = BDI_DataImport_API.bdiImported;
        update dis;
        Test.stopTest();

        bdi = [SELECT Id, Batch_Status__c FROM DataImportBatch__c
                WHERE Id = :bdi.Id];

        System.assertEquals(BDI_DataImport_API.BATCH_STATUS_COMPLETED, bdi.Batch_Status__c,
                            'The batch status should be Completed when all ' +
                            'data import records have been imported.');

        // set one di to Open
        di3.Status__c = BDI_DataImport_API.bdiDryRunValidated;
        update di3;

        // check the batch is no longer in the completed stage
        bdi = [SELECT Id, Batch_Status__c FROM DataImportBatch__c
                WHERE Id = :bdi.Id];

        System.assertNotEquals(BDI_DataImport_API.BATCH_STATUS_COMPLETED, bdi.Batch_Status__c,
                            'The batch status should be Completed when all ' +
                            'data import records have been imported.');
    }

    /*********************************************************************************************************
    * @description operation
    *     import matching contacts within the same di record
    * verify:
    *     only one contact created
    **********************************************************************************************************/
    static testMethod void OneDIDuplicateNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c1', 'C1'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size(), 'Test that the list is exactly 1.');
        System.assertEquals('c1 C1', listCon[0].Name, 'Checks that the first list con is the same as the first one.');

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size(), 'Checks that the number of data imports is equal to 1.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[0].Contact2Imported__c, listCon[0].Id, 'Assert that the Contact2Imported class is the same as the Contact1.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiMatched, dataImports[0].Contact2ImportStatus__c, 'Assert that the bdi matched is the same as the label.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import different contacts within the same di record
    * verify:
    *        two contacts created
    **********************************************************************************************************/
    static testMethod void OneDITwoNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertNotEquals(listCon[1].Name, listCon[0].Name, 'Assert that the names of the two lists are not the same.');

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size(), 'Checks that the number of data imports is equal to 1.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[0].Contact2Imported__c, listCon[1].Id, 'Assert that the Contact2Imported class is the same as the Contact1Imported class.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact2ImportStatus__c, 'Assert that the Contact2ImportStatus is the same as the Contact2ImportStatus.');
    }

    /*********************************************************************************************************
    * @description operation
    *        match a contact with no firstname
    * verify:
    *        contact matched
    **********************************************************************************************************/
    static testMethod void OneDIWithoutFirstName() {
        // this test won't pass if middle name or suffix is enabled due to a
        // salesforce won't fix issue: https://success.salesforce.com/issues_view?id=a1p30000000eQRxAAM
        if (UTIL_Describe.isMiddleNameEnabled() || UTIL_Describe.isNameSuffixEnabled()) {
            return;
        }

        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Lastname,Email';

        insert new Contact(
            Lastname='foo',
            Email='foo@bar.com'
        );

        insert new DataImport__c(
            Contact1_Lastname__c = 'Foo',
            Contact1_Personal_Email__c = 'foo@bar.com'
        );

        //run batch data import
        Test.StartTest();
        ID ApexJobId = Database.executeBatch(new BDI_DataImport_BATCH(), 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = getContacts();
        System.assertEquals(1, contacts.size(), 'Checks that the number of contacts is equal to 1.');
        System.assertEquals(null, contacts[0].FirstName, 'Assert that the first contact is the same as the first contact.');

        List<DataImport__c> imports = getDataImports();
        System.assertEquals(1, imports.size(), 'Checks that the number of imports is equal to 1.');
        System.assertEquals(imports[0].Contact1Imported__c, contacts[0].Id, 'Checks that Contact1 is the same as Contact2.');
        System.assertNotEquals(null, imports[0].HouseholdAccountImported__c, 'This method asserts that the HouseholdAccountImported class is not null.');
        System.assertEquals(System.Label.bdiMatched, imports[0].Contact1ImportStatus__c, 'Assert that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching contacts within multiple di records in the same batch
    * verify:
    *        only one contact created
    **********************************************************************************************************/
    static testMethod void TwoDIDuplicateNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c1', 'C1'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size(), 'Test that the list is exactly 1.');
        System.assertEquals('c1 C1', listCon[0].Name, 'Checks that the first list con is the same as the first one.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c, 'This method is called from the HouseholdAccount class. It asserts that the dataImports');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiMatched, dataImports[1].Contact1ImportStatus__c, 'Checks if the BDI matched by the label is the same as the BDI matched by');
    }

    /*********************************************************************************************************
    * @description operation
    *        import different contacts within multiple di records in the same batch
    * verify:
    *        two contacts created
    **********************************************************************************************************/
    static testMethod void TwoDITwoNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertNotEquals(listCon[1].Name, listCon[0].Name, 'Assert that the names of the two lists are not the same.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id, 'Assert that Contact1 is the same as Contact2.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c, 'This method is called from the HouseholdAccount class. It asserts that the dataImports');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiCreated, dataImports[1].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching contacts within multiple di records in the same batch
    * verify:
    *        only two contacts created
    *        only 1 household account created
    **********************************************************************************************************/
    static testMethod void TwoDIDuplicateNewContactsDifferentOrder() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c2', 'C2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertEquals('c1 C1', listCon[0].Name, 'Checks that the first list con is the same as the first one.');
        System.assertEquals('c2 C2', listCon[1].Name, 'Checks that the name of the con column is equal to the name of the con column.');

        // verify only one household account
        List<Account> listAcc = getAccounts();
        // because c2 is first created as a contact1, it will get a hh account, that will
        // later get orphaned when we move c2 to c1's hh account.
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals(listAcc[0].Id, listCon[0].AccountId, 'Assert that the account ID and account ID are equal.');
        System.assertEquals(listAcc[0].Id, listCon[1].AccountId, 'Assert that the list accounts are equal');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id, 'Assert that Contact1 is the same as Contact2.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c, 'This method is called from the HouseholdAccount class. It asserts that the dataImports');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiCreated, dataImports[1].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiMatched, dataImports[0].Contact2ImportStatus__c, 'Assert that the bdi matched is the same as the label.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts within the same di record
    * verify:
    *        two contacts matched
    **********************************************************************************************************/
    static testMethod void OneDITwoExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertNotEquals(listCon[1].Name, listCon[0].Name, 'Assert that the names of the two lists are not the same.');

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size(), 'Checks that the number of data imports is equal to 1.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[0].Contact2Imported__c, listCon[1].Id, 'Assert that the Contact2Imported class is the same as the Contact1Imported class.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertEquals(label.bdiMatched, dataImports[0].Contact1ImportStatus__c, 'Checks if the BDI matched by the label is the same as the BDI matched by');
        System.assertEquals(label.bdiMatched, dataImports[0].Contact2ImportStatus__c, 'Assert that the bdi matched is the same as the label.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts that match a 1x1 contact
    * verify:
    *        error given, di not processed.
    **********************************************************************************************************/
    static testMethod void OneDIExistingContacts1x1() {
        // existing 1x1 contact
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 1, 0);
        List<Contact> listConExisting = getContacts();

        Contact matched00Contact = listConExisting[0];

        System.assertEquals(1, listConExisting.size(), 'Checks that the list is equal to one.');
        System.assertEquals(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, listConExisting[0].Account.npe01__System_AccountType__c, 'This function checks that the listConExisting parameter is the one to one organization type.');
        System.assert(matched00Contact.Name.startsWith('TestFirstName00'),
            'The name of the First Contact retrieved does not start with "TestFirstName00"');
        listConExisting[0].Email = 'foo@bar.com';
        update listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI(matched00Contact.FirstName, matched00Contact.LastName, 'c2', 'C2', new Address__c(MailingCity__c='Seattle')));
        dataImports[0].Contact1_Personal_Email__c = 'foo@bar.com';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        Boolean usingAdv = ADV_PackageInfo_SVC.useAdv();
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size(), 'Test that the list is exactly 1.');
        System.assertEquals(matched00Contact.Name, listCon[0].Name, 'This test asserts that the names of the contacts are the same.');

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size(), 'Checks that the number of data imports is equal to 1.');
        System.assertEquals(null, dataImports[0].Contact1Imported__c, 'This method is called when the first contact is imported.');
        System.assertEquals(null, dataImports[0].Contact2Imported__c, 'This method is called when the contact2Imported property is null.');
        System.assertEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class.');
        // With ADV installed, 1x1 Contacts can make Donations, but there cannot be a second Contact on the DI record
        String importError = usingAdv ? label.bdiErrorOneToOneMultiContact : label.bdiErrorNonHHAccountContact;
        System.assertEquals(importError, dataImports[0].Contact1ImportStatus__c, 'Checks if the importError is the same as the importError of the first data import.');
        System.assertEquals(null, dataImports[0].Contact2ImportStatus__c, 'Checks that the Contact2ImportStatus object is null.');
        List<Address__c> listAddr = getAddresses();
        System.assertEquals(0, listAddr.size(), 'Assert that the list is empty.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import different accounts within the same di record
    * verify:
    *        two accounts created
    **********************************************************************************************************/
    static testMethod void OneDITwoNewAccounts() {

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertNotEquals(listAcc[1].Name, listAcc[0].Name, 'Assert that the names of the lists are not the same.');

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size(), 'Checks that the number of data imports is equal to 1.');
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the first one');
        System.assertEquals(dataImports[0].Account2Imported__c, listAcc[1].Id, 'This function is called when the account2 imported class is the same as the one in the');
        System.assertEquals(label.bdiCreated, dataImports[0].Account1ImportStatus__c, 'Checks that label. bdiCreated is the same as label. bdiCreated.');
        System.assertEquals(label.bdiCreated, dataImports[0].Account2ImportStatus__c, 'Check that label. bdiCreated is the same as label. bdiCreated');
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching accounts within the same di record
    * verify:
    *        one accounts created
    **********************************************************************************************************/
    static testMethod void OneDITwoSameAccounts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A1'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(1, listAcc.size(), 'Checks that the size of the list is equal to 1.');

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size(), 'Checks that the number of data imports is equal to 1.');
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the first one');
        System.assertEquals(dataImports[0].Account2Imported__c, listAcc[0].Id, 'This function is called when the account2Imported property of the first dataImport is the same');
        System.assertEquals(label.bdiCreated, dataImports[0].Account1ImportStatus__c, 'Checks that label. bdiCreated is the same as label. bdiCreated.');
        System.assertEquals(label.bdiMatched, dataImports[0].Account2ImportStatus__c, 'Test if the BDI matched by the label is the same as the BDI matched by');
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching accounts in different di records
    * verify:
    *        one account created
    **********************************************************************************************************/
    static testMethod void TwoDISameAccounts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(1, listAcc.size(), 'Checks that the size of the list is equal to 1.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the first one');
        System.assertEquals(dataImports[1].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the second import');
        System.assertEquals(label.bdiCreated, dataImports[0].Account1ImportStatus__c, 'Checks that label. bdiCreated is the same as label. bdiCreated.');
        System.assertEquals(label.bdiMatched, dataImports[1].Account1ImportStatus__c, 'Test if label matches the BDI matched by the dataImports member.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing accounts
    * verify:
    *        no accounts created, just matched
    **********************************************************************************************************/
    static testMethod void TwoDIExistingAccounts() {
        List<Account> listAcc = new List<Account>();
        listAcc.add(new Account(name='A1', BillingCity='Seattle'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAcc);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account1_City__c='Seattle'));
        dataImports.add(new DataImport__c(Account1_Name__c='A2'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the first one');
        System.assertEquals(dataImports[1].Account1Imported__c, listAcc[1].Id, 'This function is called when the first import of the account1 is the same as the second');
        System.assertEquals(label.bdiMatched, dataImports[0].Account1ImportStatus__c, 'Test if label matches the BDI matched by the dataImports member.');
        System.assertEquals(label.bdiMatched, dataImports[1].Account1ImportStatus__c, 'Test if label matches the BDI matched by the dataImports member.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing accounts, matched by Salesforce Id
    * verify:
    *        no accounts created, just matched
    **********************************************************************************************************/
    static testMethod void TwoDIExistingAccountsSalesforceId() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<Account> listAcc = new List<Account>();
        listAcc.add(new Account(name='A1'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAcc);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1',
            Account1Imported__c=listAcc[0].Id));
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C2', Contact2_Firstname__c='c2',
            Account1Imported__c=listAcc[0].Id, Account2Imported__c=listAcc[1].Id));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        listAcc = getOrganizations();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the first one');
        System.assertEquals(dataImports[1].Account1Imported__c, listAcc[0].Id, 'This function is called when the first import of the account is the same as the second import');
        System.assertEquals(dataImports[1].Account2Imported__c, listAcc[1].Id, 'This function is called when the first import of the second account is the same as the first');
        System.assertEquals(label.bdiMatched, dataImports[0].Account1ImportStatus__c, 'Test if label matches the BDI matched by the dataImports member.');
        System.assertEquals(label.bdiMatched, dataImports[1].Account1ImportStatus__c, 'Test if label matches the BDI matched by the dataImports member.');
        System.assertEquals(label.bdiMatched, dataImports[1].Account2ImportStatus__c, 'Test if label matches the BDI matched by the dataImports member.');
    }

    /*********************************************************************************************************
    operation:
    *        import contacts with Preferred Email set
    * verify:
    *        ensure the appropriate contact email field gets copied into the standard email field.
    **********************************************************************************************************/
    /** can't use this test because it relies on our workflow rules being active, which we can't enforce.
    static testMethod void ThreeDINewContactsWithPreferredEmail() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports.add(newDI('c3', 'C3'));
        dataImports[0].Contact1_Preferred_Email__c = 'Home';
        dataImports[0].Contact1_Personal_Email__c = 'c1@home.com';
        dataImports[1].Contact1_Preferred_Email__c = 'Work';
        dataImports[1].Contact1_Work_Email__c = 'c2@work.com';
        dataImports[2].Contact1_Preferred_Email__c = 'Alternate';
        dataImports[2].Contact1_Personal_Email__c = 'c3@alt.com';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(3, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);
        System.assertEquals('c1@home.com', listCon[0].Email);
        System.assertEquals('c2 C2', listCon[1].Name);
        System.assertEquals('c2@work.com', listCon[1].Email);
        System.assertEquals('c3 C3', listCon[2].Name);
        System.assertEquals('c3@alt.com', listCon[2].Email);
    }
    ***************/

    /*********************************************************************************************************
    * @description operation
    *        import contacts with accounts
    * verify:
    *        contacts created
    *        accounts created
    *        affiliations created between contacts and accounts
    **********************************************************************************************************/
    static testMethod void TwoDIAffiliations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4'));
        dataImports[0].Account1_Name__c = 'A1';
        dataImports[1].Account2_Name__c = 'A2';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size(), 'Checks that the number of contacts is equal to 4.');

        dataImports = getDataImports();

        for (DataImport__c di : dataImports) {
            System.assert(contactById.containsKey(di.Contact1Imported__c), 'This is a no - op if the contact is imported.');
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name, 'This is a hack to avoid the import of the Contact1. Name property.');
            System.assert(contactById.containsKey(di.Contact2Imported__c), 'Checks that Contact2Imported__c is imported.');
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name, 'This is a hack to avoid the import of the same name twice.');
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId, 'Checks that Contact1Importedc has an AccountId that is not null.');
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId, 'Checks that the Account ID is not null.');
        }

        List<Account> listAcc = getOrganizations();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals(contactById.get(dataImports[0].Contact1Imported__c).Primary_Affiliation__c, listAcc[0].Id, 'This method is called when the primary affiliation of the contact is the same as the primary');
        System.assertEquals(contactById.get(dataImports[0].Contact2Imported__c).Primary_Affiliation__c, null, 'This method is called when the contact is imported and the primary affiliation is null.');
        System.assertEquals(contactById.get(dataImports[1].Contact1Imported__c).Primary_Affiliation__c, null, 'This method is called when the contact is imported and the primary affiliation is null.');
        System.assertEquals(contactById.get(dataImports[1].Contact2Imported__c).Primary_Affiliation__c, listAcc[1].Id, 'This function is called when the primary affiliation of the contact is the same as the primary');

        list<npe5__Affiliation__c> listAffl = getAffiliations();
        System.assertEquals(2, listAffl.size(), 'Test that the size of the affl list is equal to 2.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listAffl[0].npe5__Contact__c, 'Checks that the values of the dataImports and listAffl are the same.');
        System.assertEquals(dataImports[1].Contact2Imported__c, listAffl[1].npe5__Contact__c, 'Checks that the two Contact objects are the same.');

    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with home addresses
    * verify:
    *        address objects created
    *        contacts' mailing address set
    *        hh accounts' billing address set
    **********************************************************************************************************/
    static testMethod void TwoDIHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2', new Address__c(MailingCity__c='Seattle')));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4', new Address__c(MailingCity__c='Portland')));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size(), 'Checks that the number of contacts is equal to 4.');
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        for (DataImport__c di : dataImports) {
            System.assert(contactById.containsKey(di.Contact1Imported__c), 'This is a no - op if the contact is imported.');
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name, 'This is a hack to avoid the import of the Contact1. Name property.');
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact1Imported__c).MailingCity, 'This is a test function to assert that homeCity and mailingCity are the same.');
            System.assert(contactById.containsKey(di.Contact2Imported__c), 'Checks that Contact2Imported__c is imported.');
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name, 'This is a hack to avoid the import of the same name twice.');
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact2Imported__c).MailingCity, 'This is a test function to assert that homeCity and mailingCity are the same.');
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId, 'Checks that Contact1Importedc has an AccountId that is not null.');
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId, 'Checks that the Account ID is not null.');
        }

        List<Address__c> listAddr = getAddresses();
        System.assertEquals(2, listAddr.size(), 'Assert that the size of the list is 2.');
        System.assertEquals(dataImports[0].Home_City__c, listAddr[0].MailingCity__c, 'Test if the data imports are the same.');
        System.assertEquals(dataImports[0].HomeAddressImported__c, listAddr[0].Id, 'Assert that home address imported is the same as the list address.');
        System.assertEquals(label.bdiCreated, dataImports[0].HomeAddressImportStatus__c, 'Checks that the home address import status is the same as the one created by the first data');
        System.assertEquals(dataImports[1].Home_City__c, listAddr[1].MailingCity__c, 'Test if the dataimports are the same.');
        System.assertEquals(dataImports[1].HomeAddressImported__c, listAddr[1].Id, 'This function is called when the user is asserting that the home address is imported from the');
        System.assertEquals(label.bdiCreated, dataImports[1].HomeAddressImportStatus__c, 'Checks that the home address import status is the same as the one in the data imports.');

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals(dataImports[0].Home_City__c, listAcc[0].BillingCity, 'Checks that home city and billing city are the same.');
        System.assertEquals(dataImports[1].Home_City__c, listAcc[1].BillingCity, 'This function is used to assert that the home city and billing city are the same.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with home addresses
    * verify:
    *        address objects not duplicated
    *        contacts' mailing address set
    *        hh accounts' billing address set
    **********************************************************************************************************/
    static testMethod void TwoDIExistingHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@C3.com', MailingCity='Seattle'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2', new Address__c(MailingCity__c='Portland')));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4', new Address__c(MailingCity__c='Portland')));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size(), 'Checks that the number of contacts is equal to 4.');
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        for (DataImport__c di : dataImports) {
            System.assert(contactById.containsKey(di.Contact1Imported__c), 'This is a no - op if the contact is imported.');
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name, 'This is a hack to avoid the import of the Contact1. Name property.');
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact1Imported__c).MailingCity, 'This is a test function to assert that homeCity and mailingCity are the same.');
            System.assert(contactById.containsKey(di.Contact2Imported__c), 'Checks that Contact2Imported__c is imported.');
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name, 'This is a hack to avoid the import of the same name twice.');
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact2Imported__c).MailingCity, 'This is a test function to assert that homeCity and mailingCity are the same.');
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId, 'Checks that Contact1Importedc has an AccountId that is not null.');
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId, 'Checks that the Account ID is not null.');
        }

        List<Address__c> listAddr = getAddresses();
        System.assertEquals(4, listAddr.size(), 'Test that the size of the list is equal to 4.');
        System.assertEquals(dataImports[0].Home_City__c, listAddr[2].MailingCity__c, 'Test if the dataimports are the same.');
        System.assertEquals(dataImports[0].HomeAddressImported__c, listAddr[2].Id, 'Assert that the home address imported is the same as the list address.');
        System.assertEquals(label.bdiCreated, dataImports[0].HomeAddressImportStatus__c, 'Checks that the home address import status is the same as the one created by the first data');
        System.assertEquals(dataImports[1].Home_City__c, listAddr[3].MailingCity__c, 'Test if the dataimports are the same.');
        System.assertEquals(dataImports[1].HomeAddressImported__c, listAddr[3].Id, 'Assert that the home address imported from the list is the same as the list address.');
        System.assertEquals(label.bdiCreated, dataImports[1].HomeAddressImportStatus__c, 'Checks that the home address import status is the same as the one in the data imports.');

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals(dataImports[0].Home_City__c, listAcc[0].BillingCity, 'Checks that home city and billing city are the same.');
        System.assertEquals(dataImports[1].Home_City__c, listAcc[1].BillingCity, 'This function is used to assert that the home city and billing city are the same.');

    }

    /*********************************************************************************************************
    * @description operation
    *        import duplicate contacts with duplicate home addresses
    * verify:
    *        no duplicate address objects created
    *        contacts' mailing address set
    *        hh accounts' billing address set
    **********************************************************************************************************/
    static testMethod void ManyDISameHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports.add(newDI('c2', 'C2'));

        // add same address to all
        for (DataImport__c di : dataImports) {
            di.Home_Street__c = '123 45th St NE';
            di.Home_City__c = 'Seattle';
            di.Home_State_Province__c = 'Washington';
            di.Home_Zip_Postal_Code__c = '98052';
            di.Home_Country__c = 'United States';
        }
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        dataImports = getDataImports();
        System.assertEquals(5, dataImports.size(), 'Checks that the number of data imports is equal to 5.');

        for (Contact con : listCon) {
            System.assertEquals(dataImports[0].Home_Street__c, con.MailingStreet, 'Assert that the home street is the same as the mailing street.');
            System.assertEquals(dataImports[0].Home_City__c, con.MailingCity, 'Test if the home city is the same as the mailing city.');
            System.assertEquals(dataImports[0].Home_State_Province__c, con.MailingState, 'Test if the home state is the same as the mailing state.');
            System.assertEquals(dataImports[0].Home_Zip_Postal_Code__c, con.MailingPostalCode, 'This function is used to test if the home postal code is the same as the postal code');
            System.assertEquals(dataImports[0].Home_Country__c, con.MailingCountry, 'Checks that the home country is the same as the mailing country.');
        }

        List<Address__c> listAddr = getAddresses();
        System.assertEquals(1, listAddr.size(), 'Assert that the size of the list is equal to 1.');
        System.assertEquals(dataImports[0].Home_Street__c, listAddr[0].MailingStreet__c, 'Assert that home and mailing addresses are the same.');
        System.assertEquals(dataImports[0].Home_City__c, listAddr[0].MailingCity__c, 'Test if the data imports are the same.');
        System.assertEquals(dataImports[0].Home_State_Province__c, listAddr[0].MailingState__c, 'Test if the data imports are the same.');
        System.assertEquals(dataImports[0].Home_Zip_Postal_Code__c, listAddr[0].MailingPostalCode__c, 'This function is used to assert that the dataImports are the same.');
        System.assertEquals(dataImports[0].Home_Country__c, listAddr[0].MailingCountry__c, 'Checks that the country of the data imported is the same as the country of the mailing');

        List<Account> listAcc = getAccounts();
        // because c2 is first created as a contact1, it will get a hh account, that will
        // later get orphaned when we move c2 to c1's hh account.
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals(dataImports[0].Home_Street__c, listAcc[0].BillingStreet, 'This function is used to assert that the home street is the same as the billing street.');
        System.assertEquals(dataImports[0].Home_City__c, listAcc[0].BillingCity, 'Checks that home city and billing city are the same.');
        System.assertEquals(dataImports[0].Home_State_Province__c, listAcc[0].BillingState, 'Checks that home state is the same as billing state');
        System.assertEquals(dataImports[0].Home_Zip_Postal_Code__c, listAcc[0].BillingPostalCode, 'This function is used to test if the home zip postal code and billing postal code are the');
        System.assertEquals(dataImports[0].Home_Country__c, listAcc[0].BillingCountry, 'This function is used to assert that the country of the home account is the same as the');

        integer cCreated = 0;
        integer cMatched = 0;
        for (DataImport__c di : dataImports) {
            System.assertEquals(di.HomeAddressImported__c, listAddr[0].Id, 'asserts that home address imported is the same as the first address imported');
            if (di.HomeAddressImportStatus__c == label.bdiCreated)
                cCreated++;
            else if (di.HomeAddressImportStatus__c == label.bdiMatched)
                cMatched++;
        }
        // we didn't have an easy way to track the specific DI record that caused the addr to be created vs matched
        // in these duplicate (but new) scenarios, so we will live with marking them all as created.
        System.assertEquals(5, cCreated, 'Test for the case where cCreated is equal to 5.');
        System.assertEquals(0, cMatched, 'Assert that cMatched is the same as cMatched.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with home addresses, while address management is disabled
    * verify:
    *        address objects NOT created
    *    contacts' mailing address set
    *    hh accounts' billing address set
    **********************************************************************************************************/
    static testMethod void TwoDIHomeAddressesAddrMgmtOff() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Household_Account_Addresses_Disabled__c = true
        ));

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2', new Address__c(MailingCity__c='Seattle')));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4', new Address__c(MailingCity__c='Portland')));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size(), 'Checks that the number of contacts is equal to 4.');
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        for (DataImport__c di : dataImports) {
            System.assert(contactById.containsKey(di.Contact1Imported__c), 'This is a no - op if the contact is imported.');
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name, 'This is a hack to avoid the import of the Contact1. Name property.');
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact1Imported__c).MailingCity, 'This is a test function to assert that homeCity and mailingCity are the same.');
            System.assert(contactById.containsKey(di.Contact2Imported__c), 'Checks that Contact2Imported__c is imported.');
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name, 'This is a hack to avoid the import of the same name twice.');
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact2Imported__c).MailingCity, 'This is a test function to assert that homeCity and mailingCity are the same.');
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId, 'Checks that Contact1Importedc has an AccountId that is not null.');
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId, 'Checks that the Account ID is not null.');
        }

        List<Address__c> listAddr = getAddresses();
        System.assertEquals(0, listAddr.size(), 'Assert that the list is empty.');

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals('Seattle', listAcc[0].BillingCity, 'Checks that the billing city of the account is the same as the first billing city.');
        System.assertEquals('Portland', listAcc[1].BillingCity, 'Checks that the billing city of the first account is the same as the billing city of the');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with the same home address
    * verify:
    *        contacts matched
    *        address matched
    **********************************************************************************************************/
    static testMethod void TwoDIMixedAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', MailingCity='Portland'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports[0].Home_City__c = 'Seattle';
        dataImports[1].Home_City__c = 'Bellevue';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');

        List<Address__c> listAddr = getAddresses();
        System.assertEquals(3, listAddr.size(), 'Assert that the size of the list is equal to 3.');
        System.assertEquals('Seattle', listAddr[0].MailingCity__c, 'Assert that the first mailing city is Seattle.');
        System.assertEquals('Portland', listAddr[1].MailingCity__c, 'Assert that the first address is the Portland.');
        System.assertEquals('Bellevue', listAddr[2].MailingCity__c, 'assert that listAddr is of the form Bellevue');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id, 'Assert that Contact1 is the same as Contact2.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c, 'This method is called from the HouseholdAccount class. It asserts that the dataImports');
        System.assertEquals(label.bdiMatched, dataImports[0].Contact1ImportStatus__c, 'Checks if the BDI matched by the label is the same as the BDI matched by');
        System.assertEquals(label.bdiMatched, dataImports[1].Contact1ImportStatus__c, 'Checks if the BDI matched by the label is the same as the BDI matched by');
        System.assertEquals(listAddr[0].Id, dataImports[0].HomeAddressImported__c, 'This function is called when the listAddr is equal to the homeAddressImported attribute of the');
        System.assertEquals(listAddr[2].Id, dataImports[1].HomeAddressImported__c, 'This function is called when the listAddr is the same as the dataImports.');
        System.assertEquals(label.bdiMatched, dataImports[0].HomeAddressImportStatus__c, 'Assert that the BDI matched by the label is the same as the home address import status');
        System.assertEquals(label.bdiCreated, dataImports[1].HomeAddressImportStatus__c, 'Checks that the home address import status is the same as the one in the data imports.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with the same home address, with Address Management off
    * verify:
    *        contacts matched
    *       no addresses created
    *       account addresses updated
    *       contact addresses updated
    **********************************************************************************************************/
    static testMethod void TwoDIMixedAddressesAddrMgmtOff() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Household_Account_Addresses_Disabled__c = true
        ));

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', MailingCity='Portland'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports[0].Home_City__c = 'Bellevue';
        dataImports[1].Home_City__c = 'Bellevue';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertEquals('Bellevue', listCon[0].MailingCity, 'Assert that the first mailing city is Bellevue');
        System.assertEquals('Bellevue', listCon[1].MailingCity, 'Assert that the first mailing city is Bellevue.');

        List<Address__c> listAddr = getAddresses();
        System.assertEquals(0, listAddr.size(), 'Assert that the list is empty.');

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals('Bellevue', listAcc[0].BillingCity, 'Checks that the billing city of the first account is Bellevue.');
        System.assertEquals('Bellevue', listAcc[1].BillingCity, 'Checks that the billing city of the first account is Bellevue.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & payment information
    * verify:
    *        opportunity objects created
    *       payment objects created
    *       ocr's created
    *       contacts' rollups updated
    *       hh account's rollups updated
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4'));
        dataImports[0].Donation_Amount__c = 100;
        dataImports[1].Donation_Amount__c = 200;
        dataImports[0].Payment_Check_Reference_Number__c = 'abc';
        dataImports[1].Payment_Check_Reference_Number__c = '1234';
        dataImports[0].Payment_Method__c = 'Check';
        dataImports[1].Payment_Method__c = 'Visa';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size(), 'Checks that the number of contacts is equal to 4.');
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        for (DataImport__c di : dataImports) {
            System.assert(contactById.containsKey(di.Contact1Imported__c), 'This is a no - op if the contact is imported.');
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name, 'This is a hack to avoid the import of the Contact1. Name property.');
            System.assertEquals(0, contactById.get(di.Contact1Imported__c).npo02__TotalOppAmount__c, 'This test asserts that the total OPP amount of imported Contact1 is equal to the total');
            System.assert(contactById.containsKey(di.Contact2Imported__c), 'Checks that Contact2Imported__c is imported.');
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name, 'This is a hack to avoid the import of the same name twice.');
            System.assertEquals(0, contactById.get(di.Contact2Imported__c).npo02__TotalOppAmount__c, 'This test asserts that the total OPP amount of the imported Contact2 is equal to the');
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId, 'Checks that Contact1Importedc has an AccountId that is not null.');
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId, 'Checks that the Account ID is not null.');
        }

        // we no longer run rollups, unless the setting is specified

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c, 'Test for equality of the total OPP amount of the NPO - 2. 0 list');
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c, 'Test for equality of the total OPP amount of the NPO - 2.');

        List<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size(), 'Assert that 2 opp lists are equal.');
        System.assertEquals(100, listOpp[0].Amount, 'Test if the sum of the opps is equal to 100.');
        System.assertEquals(200, listOpp[1].Amount, 'Test that the sum of the operations in the listOpp is 200.');
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId, 'Assert that the list account ID and account ID are the same.');
        System.assertEquals(listAcc[1].Id, listOpp[1].AccountId, 'This function is used to assert that the two lists are identical.');

        List<npe01__OppPayment__c> listPmt = getPayments();
        System.assertEquals(2, listPmt.size(), 'Test that the size of the list is equal to 2.');
        System.assertEquals(100, listPmt[0].npe01__Payment_Amount__c, 'This function is used to check if the payment amount of the first NPE01 payment is');
        System.assertEquals(200, listPmt[1].npe01__Payment_Amount__c, 'This function is used to check the payment amount of the NPE01 payment.');
        System.assertEquals('Check', listPmt[0].npe01__Payment_Method__c, 'This method is called to assert that the payment method is checked.');
        System.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c, 'This method is called in the NPE01 class. It asserts that the payment method is');
        System.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c, 'Checks that the reference number of the PMT is equal to abc.');
        System.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c, 'Checks that the reference number of the PMT is equal to the reference number of the P');

        List<OpportunityContactRole> listOCR = getOCRs();
        System.assertEquals(4, listOCR.size(), 'Checks that the OCR list is exactly 4.');
        for (OpportunityContactRole ocr : listOCR) {
            System.assert(contactById.containsKey(ocr.ContactId), 'This method is called by OCR to assert that the contact is in the contactById map');
        }

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].DonationImported__c, listOpp[0].Id, 'Assert that the dataImports and listOpp are the same.');
        System.assertEquals(dataImports[1].DonationImported__c, listOpp[1].Id, 'Assert that the dataImports and listOpp are identical.');
        System.assertEquals(label.bdiCreated, dataImports[0].DonationImportStatus__c, 'Checks that the label of the data imports is the same as the label of the data import');
        System.assertEquals(label.bdiCreated, dataImports[1].DonationImportStatus__c, 'Checks that the label of the data imports is the same as the label of the data import');
    }

    /*********************************************************************************************************
    * @description operation
    *        import accounts with donation & payment information
    * verify:
    *       opportunity objects created
    *       payment objects created
    *       ocr's created
    *       account's rollups updated
    **********************************************************************************************************/
    static testMethod void TwoDIWithAccountDonations() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        dataImports.add(new DataImport__c(Account1_Name__c='A2'));
        dataImports[0].Donation_Donor__c = 'Account1';
        dataImports[1].Donation_Donor__c = 'Account1';
        dataImports[0].Donation_Amount__c = 100;
        dataImports[1].Donation_Amount__c = 200;
        dataImports[0].Payment_Check_Reference_Number__c = 'abc';
        dataImports[1].Payment_Check_Reference_Number__c = '1234';
        dataImports[0].Payment_Method__c = 'Check';
        dataImports[1].Payment_Method__c = 'Visa';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c, 'Test for equality of the total OPP amount of the NPO - 2. 0 list');
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c, 'Test for equality of the total OPP amount of the NPO - 2.');

        List<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size(), 'Assert that 2 opp lists are equal.');
        System.assertEquals(100, listOpp[0].Amount, 'Test if the sum of the opps is equal to 100.');
        System.assertEquals(200, listOpp[1].Amount, 'Test that the sum of the operations in the listOpp is 200.');
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId, 'Assert that the list account ID and account ID are the same.');
        System.assertEquals(listAcc[1].Id, listOpp[1].AccountId, 'This function is used to assert that the two lists are identical.');

        list<npe01__OppPayment__c> listPmt = getPayments();
        System.assertEquals(2, listPmt.size(), 'Test that the size of the list is equal to 2.');
        System.assertEquals(100, listPmt[0].npe01__Payment_Amount__c, 'This function is used to check if the payment amount of the first NPE01 payment is');
        System.assertEquals(200, listPmt[1].npe01__Payment_Amount__c, 'This function is used to check the payment amount of the NPE01 payment.');
        System.assertEquals('Check', listPmt[0].npe01__Payment_Method__c, 'This method is called to assert that the payment method is checked.');
        System.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c, 'This method is called in the NPE01 class. It asserts that the payment method is');
        System.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c, 'Checks that the reference number of the PMT is equal to abc.');
        System.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c, 'Checks that the reference number of the PMT is equal to the reference number of the P');

        list<OpportunityContactRole> listOCR = getOCRs();
        System.assertEquals(0, listOCR.size(), 'Checks that the OCR list is empty.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].DonationImported__c, listOpp[0].Id, 'Assert that the dataImports and listOpp are the same.');
        System.assertEquals(dataImports[1].DonationImported__c, listOpp[1].Id, 'Assert that the dataImports and listOpp are identical.');
        System.assertEquals(label.bdiCreated, dataImports[0].DonationImportStatus__c, 'Checks that the label of the data imports is the same as the label of the data import');
        System.assertEquals(label.bdiCreated, dataImports[1].DonationImportStatus__c, 'Checks that the label of the data imports is the same as the label of the data import');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign information
    * verify:
    *        opportunity objects created
    *    opportunities added to campaigns
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaigns() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name='CmpExisting'));
        insert campaigns;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 100));
        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[0].Donation_Campaign_Name__c = 'CmpExisting';
        dataImports[1].Donation_Campaign_Name__c = 'CmpNew';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = getContacts();
        System.assertEquals(2, contacts.size(), 'Checks that the number of contacts is equal to 2.');

        List<Account> accounts = getAccounts();
        System.assertEquals(2, accounts.size(), 'Checks that 2 accounts are in the account list.');
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, accounts[0].npo02__TotalOppAmount__c, 'This function is used to assert that the total OPP amount of the NPO02 account');
        System.assertEquals(0, accounts[1].npo02__TotalOppAmount__c, 'This function is used to assert that the total OPP amount of the NPO 2.');

        List<Opportunity> opps = getOpps();
        System.assertEquals(2, opps.size(), 'Assert that 2 opps are in the opps list.');
        System.assertEquals(100, opps[0].Amount, 'Assert that the current opps are equal to 100.');
        System.assertEquals(200, opps[1].Amount, 'Test that the current opps are equal to 200.');
        System.assertEquals(accounts[0].Id, opps[0].AccountId, 'Assert that the account IDs are the same.');
        System.assertEquals(accounts[1].Id, opps[1].AccountId, 'Checks that the two opps are equal.');

        campaigns = getCampaigns();
        System.assertEquals(2, campaigns.size(), 'Asserts that 2 campaigns are in the list.');
        System.assertEquals(opps[0].CampaignId, campaigns[0].Id, 'Checks that the opps and campaigns are equal.');
        System.assertEquals(opps[1].CampaignId, campaigns[1].Id, 'Checks that the opps are equal.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        System.assertEquals(dataImports[0].DonationImported__c, opps[0].Id, 'Assert that the dataImports and opps are the same.');
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationImportStatus__c, 'Assert that the label of the first data import is the same as the label of the first');
        System.assertEquals(System.Label.bdiMatched, dataImports[0].DonationCampaignImportStatus__c, 'Assert that the BDI label of the first data import is the same as the BDI');
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c, 'This method is called to assert that the campaigns are the same.');

        System.assertEquals(dataImports[1].DonationImported__c, opps[1].Id, 'Assert that the dataImports and opps are identical.');
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationImportStatus__c, 'Assert that the label of the first data import is the same as the label of the second');
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationCampaignImportStatus__c, 'Checks that the BDI created label is the same as the BDI created label.');
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c, 'This method is called when the campaigns are imported from the data - imports file.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign IDs and Names
    * verify:
    *    opportunity objects created
    *    campaigns added to opportunities
    *    campaigns matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIds() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name='CmpExisting'));
        campaigns.add(new Campaign(Name='AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = getOpps();
        System.assertEquals(2, opps.size(), 'Assert that 2 opps are in the opps list.');
        System.assertEquals(100, opps[0].Amount, 'Assert that the current opps are equal to 100.');
        System.assertEquals(200, opps[1].Amount, 'Test that the current opps are equal to 200.');

        campaigns = getCampaigns();
        System.assertEquals(2, campaigns.size(), 'Asserts that 2 campaigns are in the list.');
        System.assertEquals(campaigns[0].Id, opps[0].CampaignId, 'Checks that the campaigns are equal.');
        System.assertEquals(campaigns[1].Id, opps[1].CampaignId, 'Checks that the campaigns are equal.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        System.assertEquals(opps[0].Id, dataImports[0].DonationImported__c, 'Assert that the opps are the same and the dataImports are the same.');
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationImportStatus__c, 'Assert that the label of the first data import is the same as the label of the first');
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c, 'This method is called to assert that the campaigns are the same.');
        System.assertEquals(System.Label.bdiMatchedId, dataImports[0].DonationCampaignImportStatus__c, 'This method is called when the BDI label of the first DonationCampaignImport is matched');

        System.assertEquals(opps[1].Id, dataImports[1].DonationImported__c, 'Assert that the dataImports of the first opps object is the same as the donation');
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationImportStatus__c, 'Assert that the label of the first data import is the same as the label of the second');
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c, 'This method is called when the campaigns are imported from the data - imports file.');
        System.assertEquals(System.Label.bdiMatched, dataImports[1].DonationCampaignImportStatus__c, 'Checks that the BDI label of the first data import is the same as the BDI');

    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign names -- Only Dry Run
    * verify:
    *    no opportunity objects created
    *    no campaign objects created
    *    correct campaign status for dry run matching
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndDuplicateCampaignNameInDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        String duplicateCampaignName = 'Matching Campaign Name';

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].Donation_Campaign_Name__c = duplicateCampaignName;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].Donation_Campaign_Name__c = duplicateCampaignName;

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImportService dataImportService =
            new BDI_DataImportService(true, BDI_MappingServiceHelpText.getInstance());

        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(dataImportService);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = getOpps();
        System.assertEquals(0, opps.size(), 'Assert that all opps are empty.');

        List<Campaign> campaigns = getCampaigns();
        System.assertEquals(0, campaigns.size(), 'Asserts that the campaigns are empty.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        System.assertEquals(null, dataImports[0].DonationCampaignImported__c, 'This method is called when the first DonationCampaign is imported.');
        System.assertEquals(System.Label.bdiDryRunNoMatch, dataImports[0].DonationCampaignImportStatus__c, 'This test asserts that the bdi dry - run command is not matching the dataImports label');
        System.assertEquals(null, dataImports[1].DonationCampaignImported__c, 'This method is called from the testing framework to assert that the dataImports attribute is set to');
        System.assertEquals(System.Label.bdiDryRunNoMatch, dataImports[1].DonationCampaignImportStatus__c, 'This test asserts that the bdi dry - run command is not matching the bdi dry');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign names
    * verify:
    *    opportunity objects created
    *    singular campaign object created
    *    campaign ID added to all opportunities
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndDuplicateCampaignNames() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        String duplicateCampaignName = 'Matching Campaign Name';

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].Donation_Campaign_Name__c = duplicateCampaignName;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].Donation_Campaign_Name__c = duplicateCampaignName;

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = getOpps();
        System.assertEquals(2, opps.size(), 'Assert that 2 opps are in the opps list.');
        System.assertEquals(100, opps[0].Amount, 'Assert that the current opps are equal to 100.');
        System.assertEquals(200, opps[1].Amount, 'Test that the current opps are equal to 200.');

        List<Campaign> campaigns = getCampaigns();
        System.assertEquals(1, campaigns.size(), 'Asserts that the number of campaigns is equal to 1.');
        System.assertEquals(campaigns[0].Id, opps[0].CampaignId, 'Checks that the campaigns are equal.');
        System.assertEquals(campaigns[0].Id, opps[1].CampaignId, 'Checks that the campaigns are equal.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');

        System.assertEquals(opps[0].Id, dataImports[0].DonationImported__c, 'Assert that the opps are the same and the dataImports are the same.');
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationImportStatus__c, 'Assert that the label of the first data import is the same as the label of the first');
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c, 'This method is called to assert that the campaigns are the same.');
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationCampaignImportStatus__c, 'Assert that the BDI created label is the same as the ImportStatus label.');

        System.assertEquals(opps[1].Id, dataImports[1].DonationImported__c, 'Assert that the dataImports of the first opps object is the same as the donation');
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationImportStatus__c, 'Assert that the label of the first data import is the same as the label of the second');
        System.assertEquals(campaigns[0].Id, dataImports[1].DonationCampaignImported__c, 'This method is called when the campaigns are imported from the data import.');
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationCampaignImportStatus__c, 'Checks that the BDI created label is the same as the BDI created label.');

    }

    /*********************************************************************************************************
    * @description operation
    *        run dry run contacts with donation & campaign IDs and Names
    * verify:
    *    DonationCampaignImported__c is set on ID and name match
    *    Campaign Status is still matched instead of Matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIdsInDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'CmpExisting'));
        campaigns.add(new Campaign(Name = 'AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImportService dataImportService =
            new BDI_DataImportService(true, BDI_MappingServiceHelpText.getInstance());

        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(dataImportService);
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        //verify dry run statuses and import fields
        dataImports = getDataImports();
        System.assertEquals(System.Label.bdiDryRunMatchedId, dataImports[0].DonationCampaignImportStatus__c, 'This test asserts that the bdi dry run is matched by the import status of the first');
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c, 'This method is called to assert that the campaigns are the same.');
        System.assertEquals(System.Label.bdiDryRunMatched, dataImports[1].DonationCampaignImportStatus__c, 'Checks that the bdi dry run flag is matched.');
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c, 'This method is called when the campaigns are imported from the data - imports file.');
    }

    /*********************************************************************************************************
    * @description operation
    *        run dry run contacts with donation & campaign IDs and Names and THEN process the batch
    * verify:
    *    DonationCampaignImported__c is set on ID and name match
    *    Campaign Status is still matched instead of Matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIdsAfterDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'CmpExisting'));
        campaigns.add(new Campaign(Name = 'AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();

        // create import service for dry run
        BDI_DataImportService dataImportService =
            new BDI_DataImportService(true, BDI_MappingServiceHelpText.getInstance());

        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH(dataImportService);
        ID ApexJobId = Database.executeBatch(bdi, 10);

        // create import service without dry run
        dataImportService = new BDI_DataImportService(false, BDI_MappingServiceHelpText.getInstance());
        bdi = new BDI_DataImport_BATCH(dataImportService);
        ID ApexJobId2 = Database.executeBatch(bdi, 10);
        Test.stopTest();

        //verify dry run statuses and import fields
        dataImports = getDataImports();

        Map<Id, DataImport__c> dataImportsByCampaignId = new Map<Id, DataImport__c>();
        dataImportsByCampaignId.put(dataImports[0].DonationCampaignImported__c, dataImports[0]);
        dataImportsByCampaignId.put(dataImports[1].DonationCampaignImported__c, dataImports[1]);

        System.assert(dataImportsByCampaignId.containsKey(campaigns[0].Id),
            'A data import should have matched '+campaigns[0].Name);
        System.assert(dataImportsByCampaignId.containsKey(campaigns[1].Id),
            'A data import should have matched '+campaigns[1].Name);

        System.assertEquals(System.Label.bdiMatchedId,
            dataImportsByCampaignId.get(campaigns[0].Id).DonationCampaignImportStatus__c, 'This method is called when the campaign import status is matched.');
        System.assertEquals(System.Label.bdiMatched,
            dataImportsByCampaignId.get(campaigns[1].Id).DonationCampaignImportStatus__c, 'This method is called when the campaign import status is matched.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with campaign information (no donation)
    * verify:
    *        opportunity objects created
    *    opportunities added to campaigns
    **********************************************************************************************************/
    static testMethod void TwoDIWithCampaignMembers() {
        List<Campaign> listC = new List<Campaign>();
        listC.add(new Campaign(Name='CmpExisting'));
        insert listC;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));

        dataImports[0].Donation_Campaign_Name__c = 'CmpExisting';
        dataImports[1].Donation_Campaign_Name__c = 'CmpNew';
        dataImports[1].Campaign_Member_Status__c = 'zMyStatus';
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');

        List<Campaign> listCmp = getCampaigns();
        System.assertEquals(2, listCmp.size(), 'Assert that 2 lists are equal.');

        list<CampaignMember> listCM = getCampaignMembers();
        System.assertEquals(2, listCM.size(), 'Assert that the size of the list is equal to 2.');
        System.assertEquals(listCon[0].Id, listCM[0].ContactId, 'Assert that the Contacts are the same');
        System.assertNotEquals('zMyStatus', listCM[0].Status, 'Assert that zMyStatus is not the same as zMyStatus');
        System.assertEquals(listCon[1].Id, listCM[1].ContactId, 'Assert that listCon and listCM are equal');
        System.assertEquals('zMyStatus', listCM[1].Status, 'Checks that zMyStatus is the same as zMyStatus in the listCM.');

    }

    /*********************************************************************************************************
    * @description operation
    *        import accounts with invalid donation information
    * verify:
    *        opportunity objects created only for valid di
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationErrors() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        dataImports.add(new DataImport__c(Account1_Name__c='A2'));
        dataImports[0].Donation_Donor__c = 'Account1';
        dataImports[1].Donation_Donor__c = 'illegal value here!';
        dataImports[0].Donation_Amount__c = 100;
        dataImports[1].Donation_Amount__c = 200;
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c, 'Test for equality of the total OPP amount of the NPO - 2. 0 list');
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c, 'Test for equality of the total OPP amount of the NPO - 2.');

        List<Opportunity> listOpp = getOpps();
        System.assertEquals(1, listOpp.size(), 'Assert that the size of the listOpp is equal to 1.');
        System.assertEquals(100, listOpp[0].Amount, 'Test if the sum of the opps is equal to 100.');
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId, 'Assert that the list account ID and account ID are the same.');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].DonationImported__c, listOpp[0].Id, 'Assert that the dataImports and listOpp are the same.');
        System.assertEquals(dataImports[1].DonationImported__c, null, 'Assert that the first data import is the donation imported.');
        System.assertEquals(label.bdiCreated, dataImports[0].DonationImportStatus__c, 'Checks that the label of the data imports is the same as the label of the data import');
        System.assertEquals(label.bdiErrorInvalidDonor, dataImports[1].DonationImportStatus__c, 'Checks that the label of the donor is the same as the label of the donor');
        System.assertEquals(BDI_DataImport_API.bdiImported, dataImports[0].Status__c, 'This is a test function to assert that the BDI_DataImport_API. b');
        System.assertEquals(BDI_DataImport_API.bdiFailed, dataImports[1].Status__c, 'Checks that BDI_DataImport_API. bdiFailed equals to dataImports [');
    }

    /*********************************************************************************************************
    * @description operation
    *        import different contacts within multiple di records in the same batch setting Household fields
    * verify:
    *        two contacts created
    **********************************************************************************************************/
    static testMethod void TwoDITwoNewContactsHouseholdFields() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Lastname__c = 'c1', Household_Phone__c = '425-111-2222'));
        dataImports.add(new DataImport__c(Contact1_Lastname__c = 'c2', Household_Phone__c = '425-111-2222'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertNotEquals(listCon[1].Name, listCon[0].Name, 'Assert that the names of the two lists are not the same.');
        System.assertEquals(dataImports[0].Household_Phone__c, listCon[0].Account.Phone, 'Checks that the Household_Phone class is the same as the Account class.');
        System.assertEquals(dataImports[1].Household_Phone__c, listCon[1].Account.Phone, 'Checks that the phone number of the Household is the same as the account on the');

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size(), 'Checks that 2 data imports are present.');
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id, 'Assert that the Contact1 is the same as the Contact2');
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id, 'Assert that Contact1 is the same as Contact2.');
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c, 'This method is called from the TestCase in the HouseholdAccount class. It is');
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c, 'This method is called from the HouseholdAccount class. It asserts that the dataImports');
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
        System.assertEquals(label.bdiCreated, dataImports[1].Contact1ImportStatus__c, 'Checks that the Contact1ImportStatus is the same as the Contact1ImportStatus.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import new contacts into existing household accounts
    * verify:
    *        provided household account used
    **********************************************************************************************************/
    static testMethod void TwoDINewContactsExistingsHousehold() {
        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        // get their households
        listConExisting = getContacts();
        System.assertEquals(2, listConExisting.size(), 'Test that the size of the list is equal to 2.');

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='a1', Contact1_Lastname__c='C1',
            HouseholdAccountImported__c=listConExisting[0].AccountId));
        dataImports.add(new DataImport__c(Contact1_Firstname__c='a2', Contact1_Lastname__c='C2', Contact2_Firstname__c='b2',
            HouseholdAccountImported__c=listConExisting[1].AccountId));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(5, listCon.size(), 'Test for equality of the size of the list.');
        System.assertEquals(listConExisting[0].AccountId, listCon[0].AccountId, 'Assert that the account id of the list con is the same as the account id of the');
        System.assertEquals(listConExisting[1].AccountId, listCon[1].AccountId, 'This method is called to assert that the account id of the list con is the same as');
        System.assertEquals(listConExisting[0].AccountId, listCon[2].AccountId, 'This method is called to assert that the account IDs of the two lists are the same.');
        System.assertEquals(listConExisting[1].AccountId, listCon[3].AccountId, 'This method is called to assert that the account IDs of the two lists are the same.');
        System.assertEquals(listConExisting[1].AccountId, listCon[4].AccountId, 'This method is called to assert that the account IDs of the two lists are the same.');

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size(), 'Assert that 2 lists are equal.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts, from the same household
    * verify:
    *        no problems updating additional fields on C1 and C2
    *        c2 matched in household
    **********************************************************************************************************/
    static testMethod void OneDIExistingContactsExistingHousehold() {
        // existing contacts into the same household
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', Salutation='Mr'));
        insert listConExisting;
        ID hhId = getContacts()[0].AccountId;
        listConExisting.add(new Contact(Firstname='c2', Lastname='C1', Email='c2@C2.com', Salutation='Mrs', AccountId=hhId));
        upsert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com', Contact1_Salutation__c='Dr',
            Contact2_Firstname__c='c2', Contact2_Salutation__c='Prof'));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size(), 'Test if the size of the list is equal to 2.');
        System.assertEquals(hhId, listCon[0].AccountId, 'This method is called when the HREF of the first list con is equal to the ACCOUNT');
        System.assertEquals(hhId, listCon[1].AccountId, 'assertEquals - This function is used to assert that the HREF of the listCon is');
        System.assertEquals('Dr', listCon[0].Salutation, 'Assert that the salutation of the list con is equal to the salutation of the first');
        System.assertEquals('Prof', listCon[1].Salutation, 'Test if the prof is the same as the last profile.');
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contact with names using different case, make sure matching is case insensitive
    * verify:
    *        c1 matched despite email case mismatch
    *        c2 matched in household despite firstname case mismatch
    *        no problems updating additional fields on C1 and C2
    **********************************************************************************************************/
    static testMethod void OneDIExistingContactsCaseInsensitive() {
        // existing contacts into the same household
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(
            new Contact(
                FirstName='C1',
                LastName='C1',
                Email='c1@c1.com',
                Salutation='Mr'
            )
        );
        insert existingContacts;
        ID hhId = getContacts()[0].AccountId;
        existingContacts.add(
            new Contact(
                FirstName='C2',
                LastName='C1',
                Email='c2@c2.com',
                Salutation='Mrs',
                AccountId=hhId
            )
        );
        upsert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(
            new DataImport__c(
                Contact1_Firstname__c='c1',
                Contact1_Lastname__c='c1',
                Contact1_Personal_Email__c='C1@C1.com',
                Contact1_Salutation__c='Dr',
                Contact2_Firstname__c='c2',
                Contact2_Salutation__c='Prof'
            )
        );
        insert dataImports;

        //run batch data import
        Test.startTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = getContacts();
        System.assertEquals(2, contacts.size(), 'Contacts should be matched, despite case mismatch');
        System.assertEquals(hhId, contacts[0].AccountId, 'Contacts should be in same household.');
        System.assertEquals(hhId, contacts[1].AccountId, 'Contacts should be in same household.');
        System.assertEquals('Dr', contacts[0].Salutation, 'Contact should be updated with salutation from the data import.');
        System.assertEquals('Prof', contacts[1].Salutation, 'Contact should be updated with salutation from the data import.');
        System.assertEquals('C1', contacts[0].LastName, 'Contact should not be updated with the lowercase last name from the data import.');
        System.assertEquals('c1@c1.com', contacts[0].Email, 'Contact should not be updated with the uppercase email from the data import.');
        System.assertEquals('C2', contacts[1].FirstName, 'Contact should not be updated with the lowercase first name from the data import.');
    }

    /*********************************************************************************************************
     * @description When the Data Import Service has been mocked to simulate coming in through the UI, verify
     * that the instrumentation service logs the two records.
     *        two contacts created
     **********************************************************************************************************/
    @IsTest
    private static void shouldInstrumentNewDonationsWhenThroughUserInterface() {
        BDI_DataImportService.isFromGiftEntryUI = true;     // simulate the service coming through the UI
        SfdoInstrumentationMock_TEST.MockService mockService = SfdoInstrumentationMock_TEST.injectMockedInstrumentationService();

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 100));
        dataImports.add(newDI('c2', 'C2', 100));
        dataImports.add(newDI('c2', 'C2')); // this third entry is not a gift, but just a Contact
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        System.assertEquals(2, mockService.value, 'The instrumentation service should have indicated two new Gifts were inserted');
        System.assertEquals(sfdoInstrumentationEnum.Feature.GiftEntry, mockService.feature,
            'The instrumentation service should have indicated GiftEntry');
    }

    /*********************************************************************************************************
    * @description When the Data Import Service has been mocked to simulate coming in through the UI, verify
    * that the instrumentation service logs the two records.
    *        two contacts created
    **********************************************************************************************************/
    @IsTest
    private static void shouldNotInstrumentNewDonationsWhenNotThroughUserInterface() {
        SfdoInstrumentationMock_TEST.MockService mockService = SfdoInstrumentationMock_TEST.injectMockedInstrumentationService();

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 100));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        System.assertEquals(null, mockService.value, 'The instrumentation service should have indicated two new Gifts were inserted');
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves data import records in the order they were created during the test.
    * @return List<DataImport__c> All data import records in creation order
    **********************************************************************************************************/
    private static List<DataImport__c> getDataImports() {
        return [
                SELECT Account1Imported__c, Account1ImportStatus__c, Account1_Name__c,
                        Account2Imported__c, Account2ImportStatus__c, Account2_Name__c, Contact1_Preferred_Email__c, Contact1_Preferred_Phone__c,
                        Contact1Imported__c, Contact1ImportStatus__c, Contact1_Firstname__c, Contact1_Lastname__c, Contact1_Title__c,
                        Contact2Imported__c, Contact2ImportStatus__c, Contact2_Firstname__c, Contact2_Lastname__c,
                        DonationImported__c, DonationImportStatus__c, Donation_Campaign_Name__c, DonationCampaignImported__c, DonationCampaignImportStatus__c,
                        FailureInformation__c, Status__c, HomeAddressImported__c, HomeAddressImportStatus__c, HouseholdAccountImported__c,
                        Home_Street__c, Home_City__c, Home_State_Province__c, Home_Zip_Postal_Code__c, Home_Country__c
                FROM DataImport__c
                ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves account records in the order they were created during the test.
    * @return List<Account> All account records in creation order
    **********************************************************************************************************/
    private static List<Account> getAccounts() {
        return [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, Phone, npo02__TotalOppAmount__c
            FROM Account
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves account records in the order they were created during the test.
    * @return List<Account> All account records, where type is not a Household, in creation order
    **********************************************************************************************************/
    private static List<Account> getOrganizations() {
        return [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, Phone, npo02__TotalOppAmount__c
            FROM Account
            WHERE Type != 'Household'
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves contact records in the order they were created during the test.
    * @return List<Contact> All contacts records in creation order
    **********************************************************************************************************/
    private static List<Contact> getContacts() {
        return [
            SELECT Id, AccountId, Birthdate, HomePhone,  MobilePhone, Name, FirstName, LastName, Title, Salutation, Account.Phone,
                Account.npe01__System_AccountType__c, MailingState, MailingPostalCode, MailingCountry, MailingStreet, MailingCity,
                Primary_Affiliation__c, Email, npe01__HomeEmail__c, npe01__AlternateEmail__c, npe01__Preferred_Email__c,
                npe01__PreferredPhone__c, npe01__WorkEmail__c, npe01__WorkPhone__c, npo02__TotalOppAmount__c
            FROM Contact
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves address records in the order they were created during the test.
    * @return List<Address__c> All address records in creation order
    **********************************************************************************************************/
    private static List<Address__c> getAddresses() {
        return [
            SELECT Id, Household_Account__c, MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c
            FROM Address__c
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves affiliation records in the order they were created during the test.
    * @return List<npe5__Affiliation__c> All affiliation records in creation order
    **********************************************************************************************************/
    private static List<npe5__Affiliation__c> getAffiliations() {
        return [SELECT Id, npe5__Contact__c, npe5__Organization__c FROM npe5__Affiliation__c ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves opportunity records in the order they were created during the test.
    * @return List<Opportunity> All opportunity records in creation order
    **********************************************************************************************************/
    private static List<Opportunity> getOpps() {
        return [SELECT Id, Name, Amount, AccountId, CampaignId FROM Opportunity ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves opportunity contact role records in the order they were created during the test.
    * @return List<OpportunityContactRole> All opportunity contact role records in creation order
    **********************************************************************************************************/
    private static List<OpportunityContactRole> getOCRs() {
        return [SELECT Id, ContactId, OpportunityId FROM OpportunityContactRole  ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves payment records in the order they were created during the test.
    * @return List<npe01__OppPayment__c> All payment records in creation order
    **********************************************************************************************************/
    private static List<npe01__OppPayment__c> getPayments() {
        return [
            SELECT Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c
            FROM npe01__OppPayment__c
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves campaign records in the order they were created during the test.
    * @return List<Campaign> All campaign records
    **********************************************************************************************************/
    private static List<Campaign> getCampaigns() {
        return [SELECT Id, Name FROM Campaign ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves campaign member records in the order they were created during the test.
    * @return List<CampaignMember> All campaign member records
    **********************************************************************************************************/
    private static List<CampaignMember> getCampaignMembers() {
        return [SELECT Id, ContactId, Status FROM CampaignMember ORDER BY Id];
    }
}