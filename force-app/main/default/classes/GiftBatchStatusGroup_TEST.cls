/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Unit tests for GiftBatchStatusGroup.cls
*/
@isTest
private with sharing class GiftBatchStatusGroup_TEST {

    @isTest
    private static void shouldReturnTrueWithCorrectRecordCountForImportedStatusGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(String.valueOf(DataImport__c.fields.Status__c), BDI_DataImport_API.bdiImported)
            .withAliasAndValue('recordCount', 10);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isImported(), 'Checks that the statusGroup is imported.');
        System.assertEquals(10, statusGroup.recordCount(), 'Test for equality of the status group count.');
    }

    @isTest
    private static void shouldReturnFalseForNotImportedGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(String.valueOf(DataImport__c.fields.Status__c), 'Dummy Status');

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(!statusGroup.isImported(), 'Checks that the status group is not imported.');
    }

    @isTest
    private static void shouldReturnTrueWithCorrectRecordCountForFailedStatusGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(String.valueOf(DataImport__c.fields.Status__c), BDI_DataImport_API.bdiFailed)
            .withAliasAndValue('recordCount', 5);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isProcessingFailed(), 'Checks that processing failed.');
        System.assertEquals(5, statusGroup.recordCount(), 'Checks that the statusGroup count is equal to 5.');
    }

    @isTest
    private static void shouldReturnFalseForNoneFailedGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(String.valueOf(DataImport__c.fields.Status__c), BDI_DataImport_API.bdiImported);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(!statusGroup.isProcessingFailed(), 'Checks that processing failed.');
    }


    @isTest
    private static void shouldReturnTrueWithCorrectCountForGroupWithFailedPayments() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(
                String.valueOf(DataImport__c.fields.Payment_Status__c), 
                ElevateTransactionStatus.DECLINED.name())
            .withAliasAndValue('recordCount', 7);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isPaymentFailed(), 'Checks if the status group is not payment failed.');
        System.assert(!statusGroup.isPaymentAuthorized(), 'Checks that the current user is not authorized to perform a payment.');
        System.assertEquals(7, statusGroup.recordCount(), 'Checks that the statusGroup count is equal to 7.');
    }

    @isTest
    private static void shouldReturnFalseForGroupWithoutPaymentFailures() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(
                String.valueOf(DataImport__c.fields.Payment_Status__c), 
                ElevateTransactionStatus.AUTHORIZED.name());

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(!statusGroup.isPaymentFailed(), 'Checks that the status group is not payment failed.');
    }

    @isTest
    private static void shouldReturnTrueWithCorrectRecordCountForAuthorizedStatusGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue(
                String.valueOf(DataImport__c.fields.Payment_Status__c), 
                ElevateTransactionStatus.AUTHORIZED.name())
            .withAliasAndValue('recordCount', 3);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isPaymentAuthorized(), 'Checks if the current user is authorized to perform a payment.');
        System.assertEquals(3, statusGroup.recordCount(), 'Checks that the number of records in the status group is equal to 3.');
    }

    @IsTest
    private static void shouldReturnCorrectRecordCountForProcessingGifts() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
                .withAliasAndValue(
                        String.valueOf(DataImport__c.fields.Status__c),
                        BDI_DataImport_API.bdiProcessing)
                .withAliasAndValue('recordCount', 5);
        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isProcessing(), 'Checks that the status group is processing.');
    }

}
