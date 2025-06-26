/*
    Copyright (c) 2014, Salesforce.org
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
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
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
* @date 2014
* @group Address Management
* @description Test class for batch address verification.
*/
@isTest
public with sharing class ADDR_Validator_Batch_TEST {

    private static OrgConfig orgConfig = new OrgConfig();

    public static void createDefaultSettings() {
    	// use the household account model
        UTIL_CustomSettingsFacade.getContactsSettings();

        // create the basic api settings - SmartyStreets off
        Addr_Verification_Settings__c settings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
        settings.Auth_ID__c = 'hey';
        settings.Auth_Token__c = 'there';
        settings.Address_Verification_Endpoint__c = 'api.smartystreets.com/street-address';
        settings.Zipcode_Verification_Endpoint__c = 'api.smartystreets.com/zipcode';
        settings.Class__c = 'ADDR_SmartyStreets_Validator';
        settings.Enable_Automatic_Verification__c = false;
        settings.Reject_Ambiguous_Addresses__c = true;
   
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
    }
    
    public static testmethod void oneValidAddress() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

    	TDTM_DefaultConfig.startTestDataInit();
    	createDefaultSettings();
        
        //create contact 
        Contact contact = new contact(firstname='Test', lastname='Person');
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'California';
        contact.MailingPostalCode = '95014'; 
        contact.MailingCountry = 'United States';
        insert contact;

        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId, 'Asserts that accountId is not null.');
        
        //check address record got created for household
        Address__c[] av = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size(), 'Assert that the size of the array is equal to 1.');
        System.assertEquals('single-address', av[0].MailingStreet__c, 'Assert that the first address is the single - address.');
        System.assertEquals('California', av[0].MailingState__c, 'Assert that California is the same as the first mailing state.');
        System.assertEquals('95014', av[0].MailingPostalCode__c, 'Assert that the first address is 95014.');
        System.assertEquals(false, av[0].Verified__c, 'Assert that the values of the array are equal.');
        
        //run batch address verification
        TDTM_DefaultConfig.stopTestDataInit();
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address record was verified
        av = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size(), 'Assert that the size of the array is equal to 1.');
        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c, 'Assert that 1 Infinite Loop is equal to the first Infinite Loop.');
        if (!orgConfig.isStateCountryPicklistsEnabled()) {
            System.assertEquals('CA', av[0].MailingState__c, 'Assert that the current mailing state is CA.');
        } else {
            System.assertEquals('California', av[0].MailingState__c, 'Assert that California is the same as the first mailing state.');
        }
        System.assertEquals('95014-2083', av[0].MailingPostalCode__c, 'Assert that the first address is 95014 - 2083.');
        System.assertEquals(true, av[0].Verified__c, 'Assert that the values of the array are equal.');
        
        /*
        //check verified data got pushed to contact 
        contact = [select id, MailingStreet, MailingCity, MailingPostalCode, MailingState
                         from contact where id = :contact.id];
        System.assertEquals('1 Infinite Loop', contact.MailingStreet);
        System.assertEquals('Cupertino', contact.MailingCity);
        System.assertEquals('95014-2083', contact.MailingPostalCode);
        System.assertEquals('CA', contact.MailingState);
        
        //check verified data got pushed to account
        Account account = [select id, BillingStreet, BillingCity, BillingPostalCode, BillingState
                         from Account where id = :accountId];
        System.assertEquals('1 Infinite Loop', account.BillingStreet);
        System.assertEquals('Cupertino', account.BillingCity);
        System.assertEquals('95014-2083', account.BillingPostalCode);
        System.assertEquals('CA', account.BillingState);*/
    }
    
    public static testmethod void multipleValidAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        Integer batchSize = 100;

        UTIL_Debug.disableDebugLogging();
        TDTM_DefaultConfig.startTestDataInit();
    	createDefaultSettings();
        
        //create contacts
        List<Contact> contacts = new List<Contact>();
        for(integer i = 0; i< batchSize; i++) {
	        Contact contact = new contact(firstname='Test', lastname='Person' + i);
	        contact.MailingStreet = 'multiple-address';
	        contact.MailingCity = 'Cupertino';
	        contact.MailingState = 'California';
	        contact.MailingPostalCode = '95014';
	        contact.MailingCountry = 'United States';
	        contacts.add(contact);
        }
        insert contacts;

        //check households got created for contacts
        List<Id> AccountIDs = new List<Id>();
        List<Contact> contactsWithAccId = [select Account.Id from Contact where Id IN :contacts];
        System.assertEquals(batchSize, contactsWithAccId.size(), 'This method asserts that the batch size of the contactsWithAccId is equal to the batch');
        for(Contact c : contactsWithAccId) {    
	        Id accountId = c.Account.Id;
	        System.assertNotEquals(null, accountId, 'Asserts that accountId is not null.');
	        AccountIDs.add(accountId);
        }
        
        //check address records got created for households, but have not yet been verified
        List<Address__c> addresses = [select Verified__c from Address__c where Household_Account__c IN :AccountIDs];
        System.assertEquals(batchSize, addresses.size(), 'Checks that the batch size is equal to the number of batches in the batched query.');
        for(Address__c addr : addresses) {
        	System.assertEquals(false, addr.Verified__c, 'Test for the presence of the verified flag.');
        }
        
        //run batch address verification
        TDTM_DefaultConfig.stopTestDataInit();
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address records were verified
        addresses = [select MailingStreet__c, MailingState__c, MailingPostalCode__c,
                Verified__c, MailingCountry__c
                    from Address__c where Household_Account__c IN :AccountIDs];
        System.assertEquals(batchSize, addresses.size(), 'Checks that the batch size is equal to the number of batches in the batched query.');
        Integer i = 1;
        for(Address__c addr : addresses) {
        	UTIL_Debug.debug(LoggingLevel.WARN, '****Asserting address record #' + i);
	        System.assertEquals('1 Infinite Loop', addr.MailingStreet__c, 'Test for equality of 1 Infinite Loop.');
            //Not compatible when State/Country pl enabled
            if (orgConfig.isStateCountryPicklistsEnabled()) {
	            System.assertEquals('California', addr.MailingState__c, 'Assert that the California mailing state is equal to the mailing state.');
	            System.assertEquals('United States', addr.MailingCountry__c, 'Assert that the current country is United States.');
            } else {
	            System.assertEquals('CA', addr.MailingState__c, 'Assert that the current mailing state is the same as the current one.');
	            System.assertEquals('US', addr.MailingCountry__c, 'Assert that the current country is US.');
            }
	        System.assertEquals('95014-2083', addr.MailingPostalCode__c, 'Checks that the postal code is the same as the postal code of the address.');
	        System.assertEquals(true, addr.Verified__c, 'Test for the presence of the verified field.');
	        i++;
        }
    }
    
    public static testmethod void oneValidZipcode() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        TDTM_DefaultConfig.startTestDataInit();
        createDefaultSettings();
        
        Contact contact = new contact(firstname='Test', lastname='Person'); 
        contact.MailingPostalCode = '90210';
        contact.MailingCity = 'single-zip';
        insert contact;

        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId, 'Asserts that accountId is not null.');
        
        //check address record got created for household
        Address__c[] addresses = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, addresses.size(), 'Checks that the size of the address table is equal to 1.');
        System.assertEquals('90210', addresses[0].MailingPostalCode__c, 'Checks that the first address is 90210.');
        System.assertEquals(false, addresses[0].Verified__c, 'Test for equality of the verified address.');
        
        //run batch address verification
        TDTM_DefaultConfig.stopTestDataInit();
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address record was verified
        addresses = [select MailingCity__c, MailingState__c, MailingPostalCode__c, Verified__c
                from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, addresses.size(), 'Checks that the size of the address table is equal to 1.');
        System.assertEquals('98236', addresses[0].MailingPostalCode__c, 'Checks that the first address is the same as the first one.');
        System.assertEquals('Clinton', addresses[0].MailingCity__c, 'Assert that the first address is the CLinton address.');
        if (!orgConfig.isStateCountryPicklistsEnabled()) {
            System.assertEquals('WA', addresses[0].MailingState__c, 'Assert that the current address is the WA address.');
        } else {
            System.assertEquals('Washington', addresses[0].MailingState__c, 'Assert that the first address is the Washington address.');
        }
        System.assertEquals(true, addresses[0].Verified__c, 'Assert that the address is verified.');
    }
    
    public static testmethod void multipleValidZipcodes() {
        createDefaultSettings();
    }
    
    public static testmethod void multipleValidAddressessZipcodes() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        TDTM_DefaultConfig.startTestDataInit();
    	createDefaultSettings();
    	
    	//create contacts 
        Contact addressContact = new contact(firstname='Test', lastname='Person');
        addressContact.MailingStreet = 'single-address';
        addressContact.MailingCity = 'Cupertino';
        addressContact.MailingState = 'California';
        addressContact.MailingPostalCode = '95014'; 
        addressContact.MailingCountry = 'United States';
        
        Contact zipContact = new contact(firstname='Test', lastname='Person'); 
        zipContact.MailingCity = 'single-zip';
        zipContact.MailingPostalCode = '90210';
        
        insert new Contact[] {addressContact, zipContact};

        //check household got created for contact
        addressContact = [select Account.Id from Contact where Id = :addressContact.Id];
        Id addrAccountId = addressContact.Account.Id;
        System.assertNotEquals(null, addrAccountId, 'Assert that addrAccountId is not null.');
        
        //check household got created for contact
        zipContact = [select Account.Id from Contact where Id = :zipContact.Id];
        Id zipAccountId = zipContact.Account.Id;
        System.assertNotEquals(null, zipAccountId, 'Asserts that zipAccountId is not null.');
        
        //check address record got created for household
        Address__c[] av1 = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :addrAccountId];
        System.assertEquals(1, av1.size(), 'Assert that the size of the array is equal to 1.');
        System.assertEquals('single-address', av1[0].MailingStreet__c, 'Assert that single - address is the same as the first address.');
        System.assertEquals('California', av1[0].MailingState__c, 'Assert that California is the same as the mailing state.');
        System.assertEquals('95014', av1[0].MailingPostalCode__c, 'Test for equality of the postal code of the first AVS.');
        System.assertEquals(false, av1[0].Verified__c, 'Assert that the values of av1 are equal.');

        //check address record got created for household
        Address__c[] av2 = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :zipAccountId];
        System.assertEquals(1, av2.size(), 'Assert that the size of the lists is equal to 1.');
        System.assertEquals('90210', av2[0].MailingPostalCode__c, 'Assert that 90210 is the same as 90210.');
        System.assertEquals(false, av2[0].Verified__c, 'Assert that the values of av2 are equal.');
        
        //run batch address verification
        TDTM_DefaultConfig.stopTestDataInit();
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address record was verified
        av1 = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :addrAccountId];
        System.assertEquals(1, av1.size(), 'Assert that the size of the array is equal to 1.');
        System.assertEquals('1 Infinite Loop', av1[0].MailingStreet__c, 'Assert that 1 Infinite Loop is equal to the first address.');
        if (!orgConfig.isStateCountryPicklistsEnabled()) {
            System.assertEquals('CA', av1[0].MailingState__c, 'Assert that the CA is the same as the CA.');
        } else {
            System.assertEquals('California', av1[0].MailingState__c, 'Assert that California is the same as the mailing state.');
        }
        System.assertEquals('95014-2083', av1[0].MailingPostalCode__c, 'Checks that the first AVS is the same as the second AVS.');
        System.assertEquals(true, av1[0].Verified__c, 'Assert that the values of av1 are equal.');
        
        //check address record was verified
        av2 = [select MailingCity__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :zipAccountId];
        System.assertEquals(1, av2.size(), 'Assert that the size of the lists is equal to 1.');
        System.assertEquals('98236', av2[0].MailingPostalCode__c, 'Assert that the first AVS is the same as the first AVS.');
        System.assertEquals('Clinton', av2[0].MailingCity__c, 'Assert that the first AVS is the CLinton.');
        if (!orgConfig.isStateCountryPicklistsEnabled()) {
            System.assertEquals('WA', av2[0].MailingState__c, 'Assert that the current mailbox is the WA mailbox.');
        } else {
            System.assertEquals('Washington', av2[0].MailingState__c, 'Assert that the Washington mailbox is the same as the first MailingState.');
        }
        System.assertEquals(true, av2[0].Verified__c, 'Assert that the values of av2 are equal.');
    }
    
    public static testmethod void validAddressInvalidZipcode() {
        createDefaultSettings();
    }     
}