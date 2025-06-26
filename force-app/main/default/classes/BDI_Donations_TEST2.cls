/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Batch Data Import
* @description Second part of tests specific to the Batch Data Importer Donations batch processing and record creation.
*/

@isTest
public with sharing class BDI_Donations_TEST2 {
    @isTest
    private static void shouldCreateAndUpdateACHPaymentsForElevateDI () {
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c = 
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //Adding test payment field mapping for regression testing
        npe01__Payment_Field_Mapping_Settings__c testPFMS =
                new npe01__Payment_Field_Mapping_Settings__c(Name = 'TestPFMSasdf',
                                                        npe01__Opportunity_Field__c = 'Name',
                                                        npe01__Payment_Field__c = 'npe01__Check_Reference_Number__c');
        PMT_PaymentCreator.paymentMappings.put(testPFMS.Name, testPFMS);

        String CLOSED_LOST_STAGE = 'Closed Lost';
        String SUBMITTED_STATUS = 'SUBMITTED';
        String DECLINED_STATUS = 'DECLINED';
        String SETTLED_STATUS = 'SETTLED';

        // Testing Closed Won / SUBMITTED to SETTLED
        DataImport__c testDI1 = new DataImport__c(Contact1_FirstName__c = 'Testy',
                                                Contact1_LastName__c = 'TestCont1',
                                                Contact1_Personal_Email__c = 'testDI1@fakeDI.com',
                                                Donation_Amount__c = 100,
                                                Payment_Elevate_ID__c = '123',
                                                Payment_ACH_Last_4__c = '4567',
                                                Payment_Method__c = 'ACH',
                                                Payment_Status__c = SUBMITTED_STATUS,
                                                Payment_Paid__c = 'True');

        // Testing Closed Won / SUBMITTED to Closed Lost / DECLINED
        DataImport__c testDI2 = new DataImport__c(Contact1_FirstName__c = 'Testy',
                                                Contact1_LastName__c = 'TestCont2',
                                                Contact1_Personal_Email__c = 'testDI2@fakeDI.com',
                                                Donation_Amount__c = 100,
                                                Payment_Elevate_ID__c = '124',
                                                Payment_ACH_Last_4__c = '4568',
                                                Payment_Method__c = 'ACH',
                                                Payment_Status__c = SUBMITTED_STATUS,
                                                Payment_Paid__c = 'True');

        //Testing Closed Lost / DECLINED
        DataImport__c testDI3 = new DataImport__c(Contact1_FirstName__c = 'Testy',
                                                Contact1_LastName__c = 'TestCont3',
                                                Contact1_Personal_Email__c = 'testDI3@fakeDI.com',
                                                Donation_Amount__c = 100,
                                                Payment_Elevate_ID__c = '125',
                                                Payment_ACH_Last_4__c = '4569',
                                                Payment_Method__c = 'ACH',
                                                Payment_Status__c = DECLINED_STATUS,
                                                Payment_Paid__c = 'False',
                                                Donation_Stage__c = CLOSED_LOST_STAGE);

        DataImport__c[] testDIs = new DataImport__c[]{testDI1,testDI2,testDI3};
        insert testDIs;

        BDI_DataImport_API.processDataImportRecords(dis, testDIs,false);

        DataImport__c[] resultDis = [SELECT Id,
                                    FailureInformation__c,
                                    Status__c,
                                    DonationCampaignImported__c,
                                    Contact1Imported__c,
                                    PaymentImported__c,
                                    PaymentImportStatus__c,
                                    DonationImported__c,
                                    DonationImportStatus__c,
                                    HouseholdAccountImported__c,
                                    Home_Zip_Postal_Code__c,
                                    Home_Street__c,
                                    HomeAddressImported__c,
                                    Contact1_Personal_Email__c,
                                    Donation_Date__c
                                FROM DataImport__c];

        DataImport__c di1;
        DataImport__c di2;
        DataImport__c di3;

        for (DataImport__c di : resultDis) {
            if (di.Contact1_Personal_Email__c	 == 'testDI1@fakeDI.com') {
                di1 = di;
            } else if (di.Contact1_Personal_Email__c	 == 'testDI2@fakeDI.com') {
                di2 = di;
            } else if (di.Contact1_Personal_Email__c	 == 'testDI3@fakeDI.com') {
                di3 = di;
            }
        }

        //Confirm that the DIs are Imported and that the correct status is in place for each Oppt/Payment
        System.assertEquals('Imported', di1.Status__c, 'Checks that the import status is the same as the imported status.');
        System.assertEquals(System.label.bdiCreated,di1.DonationImportStatus__c, 'Assert that the label of the system is bdiCreated.');
        System.assertEquals(System.label.bdiCreated,di1.PaymentImportStatus__c, 'Assert that the label of the BDI created is the same as the payment import status.');
        System.assertNotEquals(null,di1.DonationImported__c, 'This method asserts that di1. DonationImported__c is not null.');
        System.assertNotEquals(null,di1.PaymentImported__c, 'This method asserts that PaymentImported is not null.');
        System.assertEquals('Imported', di2.Status__c, 'Checks that the import is imported.');
        System.assertEquals(System.label.bdiCreated,di2.DonationImportStatus__c, 'Assert that System. label. bdiCreated is the same as di2. Donation');
        System.assertEquals(System.label.bdiCreated,di2.PaymentImportStatus__c, 'Assert that the label of the BDI created is the same as the label of the B');
        System.assertNotEquals(null,di2.DonationImported__c, 'This method is called from di2. DonationImported when the module is not imported.');
        System.assertNotEquals(null,di2.PaymentImported__c, 'This method is called to assert that the payment imported class is not null.');
        System.assertEquals('Imported', di3.Status__c, 'Checks that the import is imported.');
        System.assertEquals(System.label.bdiCreated,di3.DonationImportStatus__c, 'Assert that the label of the system is bdiCreated.');
        System.assertEquals(System.label.bdiCreated,di3.PaymentImportStatus__c, 'Assert that the label of the BDI created is the same as the label of the B');
        System.assertNotEquals(null,di3.DonationImported__c, 'This method asserts that di3. DonationImported__c is not null.');
        System.assertNotEquals(null,di3.PaymentImported__c, 'This test asserts that di3. PaymentImported__c is not null.');

        npe01__OppPayment__c pmt1;
        npe01__OppPayment__c pmt2;
        npe01__OppPayment__c pmt3;

        npe01__OppPayment__c[] paymentResults = [SELECT Id, 
                                                        npe01__Payment_Amount__c, 
                                                        npe01__Opportunity__c,
                                                        Elevate_Payment_Id__c,
                                                        npe01__Check_Reference_Number__c,
                                                        npe01__Paid__c,
                                                        Elevate_Payment_API_Status__c,
                                                        Elevate_Payment_API_Declined_Reason__c,
                                                        ACH_Code__c,
                                                        ACH_Last_4__c,
                                                        npe01__Opportunity__r.StageName,
                                                        npe01__Opportunity__r.Amount,
                                                        npe01__Opportunity__r.IsClosed,
                                                        npe01__Opportunity__r.IsWon,
                                                        npe01__Opportunity__r.Name
                                                FROM npe01__OppPayment__c];

        for (npe01__OppPayment__c pmt : paymentResults) {
            if (pmt.Elevate_Payment_Id__c == '123') {
                pmt1 = pmt;
            } else if (pmt.Elevate_Payment_Id__c == '124') {
                pmt2 = pmt;
            } else if (pmt.Elevate_Payment_Id__c == '125') {
                pmt3 = pmt;
            }
        }

        System.assertEquals(3,paymentResults.size(), 'Checks that the number of payment results is equal to 3.');

        //Confirm that the Oppt is Closed Won and the Payment is SUBMITTED
        System.assertNotEquals(null, pmt1, 'Assert that pmt1 is not null.');
        System.assertEquals(100,pmt1.npe01__Payment_Amount__c, 'This function asserts that the payment amount is equal to 100.');
        System.assertEquals(SUBMITTED_STATUS,pmt1.Elevate_Payment_API_Status__c, 'asserts that the payment API status is the same as the subscribed status');
        System.assertEquals(true, pmt1.npe01__Paid__c, 'Test for equality of true and false.');
        System.assertEquals('4567', pmt1.ACH_Last_4__c, 'This test asserts that the string is the same as the string in the pmt1 file');
        System.assertEquals(true, pmt1.npe01__Opportunity__r.IsClosed, 'Tests that the Opportunity r is closed.');
        System.assertEquals(true, pmt1.npe01__Opportunity__r.IsWon, 'This operation asserts that the IsWon operator is true.');
        //Checking that payment mapping worked correctly.
        System.assertEquals(pmt1.npe01__Opportunity__r.Name, pmt1.npe01__Check_Reference_Number__c, 'Check that the Opportunity Name and Reference Number are equal.');

        //Confirm that the Oppt is Closed Won and the Payment is submitted
        System.assertNotEquals(null, pmt2, 'Assert that pmt2 is not null.');
        System.assertEquals(100,pmt2.npe01__Payment_Amount__c, 'Test for the amount of payment in the NPE01 system.');
        System.assertEquals(SUBMITTED_STATUS,pmt2.Elevate_Payment_API_Status__c, 'asserts that the payment API status is the same as the subscribed status');
        System.assertEquals(true, pmt2.npe01__Paid__c, 'Test for equality of true and false.');
        System.assertEquals('4568', pmt2.ACH_Last_4__c, 'This test asserts that the string is the same as the string in the pmt2 table');
        System.assertEquals(true, pmt2.npe01__Opportunity__r.IsClosed, 'Tests that the Opportunity r is closed.');
        System.assertEquals(true, pmt2.npe01__Opportunity__r.IsWon, 'This operation asserts that the value of IsWon is true.');
        //Checking that payment mapping worked correctly.
        System.assertEquals(pmt2.npe01__Opportunity__r.Name, pmt2.npe01__Check_Reference_Number__c, 'Check that the name of the OPportunity is the same as the check reference number of');

        //Confirm that the Oppt is Closed Lost and the Payment is DECLINED
        System.assertNotEquals(null, pmt3, 'Assert that pmt3 is not null.');
        System.assertEquals(100,pmt3.npe01__Payment_Amount__c, 'Test for the amount of payment.');
        System.assertEquals(DECLINED_STATUS,pmt3.Elevate_Payment_API_Status__c, 'Checks that declined payment API status is equal to pmt3. Elevate');
        System.assertEquals(false, pmt3.npe01__Paid__c, 'Test for equality of false and pmt3. npe01Paidc.');
        System.assertEquals('4569', pmt3.ACH_Last_4__c, 'Assert that 4569 is the same as 4569.');
        System.assertEquals(true, pmt3.npe01__Opportunity__r.IsClosed, 'Tests that the Opportunity r is closed.');
        System.assertEquals(false, pmt3.npe01__Opportunity__r.IsWon, 'This function asserts that the IsWon operator is true.');
        //Checking that payment mapping worked correctly.
        System.assertEquals(pmt3.npe01__Opportunity__r.Name, pmt3.npe01__Check_Reference_Number__c, 'Checks that the name of the OPportunity object is the same as the check reference number');

        //Now prepare new DIs to simulate update of the previously processed payment
        DataImport__c diUpdate1 = new DataImport__c(DonationImported__c = pmt1.npe01__Opportunity__c,
                                                    Donation_Stage__c = null,
                                                    PaymentImported__c = pmt1.Id,
                                                    Payment_Status__c = SETTLED_STATUS,
                                                    Payment_Paid__c = null,
                                                    Payment_Elevate_ID__c = '123',
                                                    Payment_Method__c = 'ACH');
        DataImport__c diUpdate2 = new DataImport__c(DonationImported__c = pmt2.npe01__Opportunity__c,
                                                    Donation_Stage__c = CLOSED_LOST_STAGE,
                                                    PaymentImported__c = pmt2.Id,
                                                    Payment_Status__c = DECLINED_STATUS,
                                                    Payment_Paid__c = 'False',
                                                    Payment_Elevate_ID__c = '124',
                                                    Payment_Method__c = 'ACH');

        DataImport__c[] diUpdates = new DataImport__c[]{diUpdate1,diUpdate2};
        insert diUpdates;

        Map<Id,DataImport__c> diUpdateMap = new Map<Id,DataImport__c>(diUpdates);

        Test.startTest();
        BDI_DataImport_API.processDataImportRecords(dis, diUpdates,false);
        Test.stopTest();

        DataImport__c di1update;
        DataImport__c di2update;

        DataImport__c[] resultDis2 = [SELECT Id,
                FailureInformation__c,
                Status__c,
                DonationCampaignImported__c,
                Contact1Imported__c,
                PaymentImported__c,
                PaymentImportStatus__c,
                Payment_Elevate_ID__c,
                DonationImported__c,
                DonationImportStatus__c,
                HouseholdAccountImported__c,
                Home_Zip_Postal_Code__c,
                Home_Street__c,
                HomeAddressImported__c,
                Contact1_Personal_Email__c,
                Donation_Date__c
        FROM DataImport__c
        WHERE Id IN: diUpdateMap.keySet()];

        for (DataImport__c di : resultDis2) {

            if (di.Payment_Elevate_ID__c == '123') {
                di1update = di;
            } else if (di.Payment_Elevate_ID__c == '124') {
                di2update = di;
            }
        }

        //Confirm that both data import records were imported successfully and Oppts and Payments were marked as updated
        System.assertEquals('Imported', di1update.Status__c, 'Checks that the import status is the same as the imported status.');
        System.assertEquals(System.label.bdiMatchedId,di1update.DonationImportStatus__c, 'Assert that the label of the BDI matched is the same as the DonationImportStatus');
        System.assertEquals(System.label.bdiUpdated,di1update.PaymentImportStatus__c, 'Assert that the label of the BDI updated field is the same as the label of the');
        System.assertEquals('Imported', di2update.Status__c, 'Checks that the import is imported.');
        System.assertEquals(System.label.bdiUpdated,di2update.DonationImportStatus__c, 'Assert that the label of the system is bdiUpdated and the label of the donation');
        System.assertEquals(System.label.bdiUpdated,di2update.PaymentImportStatus__c, 'Assert that the label of the BDI updated field is the same as the label of the');
        
        npe01__OppPayment__c[] paymentResults2 = [SELECT Id,
                                                        npe01__Payment_Amount__c,
                                                        npe01__Opportunity__c,
                                                        Elevate_Payment_Id__c,
                                                        npe01__Payment_Date__c,
                                                        npe01__Paid__c,
                                                        Elevate_Payment_API_Status__c,
                                                        Elevate_Payment_API_Declined_Reason__c,
                                                        ACH_Code__c,
                                                        ACH_Last_4__c,
                                                        npe01__Opportunity__r.IsClosed,
                                                        npe01__Opportunity__r.IsWon,
                                                        npe01__Opportunity__r.Amount
                                                FROM npe01__OppPayment__c];

        npe01__OppPayment__c pmtUpdate1;
        npe01__OppPayment__c pmtUpdate2;

        for (npe01__OppPayment__c pmt : paymentResults2) {
            if (pmt.Elevate_Payment_Id__c == '123') {
                pmtUpdate1 = pmt;
            } else if (pmt.Elevate_Payment_Id__c == '124') {
                pmtUpdate2 = pmt;
            }
        }

        System.assertEquals(3,paymentResults2.size(), 'Test for the number of payment results.');

        //Confirm that the Payment Status was updated to Settled and the Oppt is still Closed Won
        System.assertNotEquals(null, pmtUpdate1, 'This function asserts that pmtUpdate1 is not null.');
        System.assertEquals(100,pmtUpdate1.npe01__Payment_Amount__c, 'This function asserts that the payment amount is equal to 100.');
        System.assertEquals(SETTLED_STATUS,pmtUpdate1.Elevate_Payment_API_Status__c, 'This is a test function to assert that the status of the pmtUpdate1 is the');
        System.assertEquals(true, pmtUpdate1.npe01__Paid__c, 'Test whether the pmtUpdate1. npe01Paidc is the same as');
        System.assertEquals('4567', pmtUpdate1.ACH_Last_4__c, 'This test asserts that the pmtUpdate1. Ale_Last_4_c');
        System.assertEquals(true, pmtUpdate1.npe01__Opportunity__r.IsClosed, 'Tests if the Opportunity is closed.');
        System.assertEquals(true, pmtUpdate1.npe01__Opportunity__r.IsWon, 'This function asserts that the Opportunity r is Won.');

        //Confirm that the payment status was changed to DECLINED and the Oppt was changed to Closed Lost
        System.assertNotEquals(null, pmtUpdate2, 'This is a test to make sure that pmtUpdate2 is not null.');
        System.assertEquals(100,pmtUpdate2.npe01__Payment_Amount__c, 'This function is a workaround to check the payment amount of the NPE01 payment.');
        System.assertEquals(DECLINED_STATUS,pmtUpdate2.Elevate_Payment_API_Status__c, 'Checks that declined payment API status is equal to the one specified in pmtUpdate2');
        System.assertEquals(false, pmtUpdate2.npe01__Paid__c, 'Test for equality of false and true in pmtUpdate2. npe01. Pa');
        System.assertEquals('4568', pmtUpdate2.ACH_Last_4__c, 'This test asserts that the last 4 bytes of the PMT are equal to the last 4');
        System.assertEquals(true, pmtUpdate2.npe01__Opportunity__r.IsClosed, 'Tests if the Opportunity is closed.');
        System.assertEquals(false, pmtUpdate2.npe01__Opportunity__r.IsWon, 'This function asserts that the Opportunity r is Won.');
    }
}