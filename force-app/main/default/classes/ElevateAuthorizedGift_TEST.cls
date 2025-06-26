/*
 * Copyright (c) 2020, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
@isTest
public with sharing class ElevateAuthorizedGift_TEST {

    private static final Integer DUMMY_AMOUNT = 100;
    private static final String DUMMY_TOKEN = 'token-1234';
    private static final String DUMMY_LAST_NAME = 'Bond';
    private static final String DUMMY_FIRST_NAME = 'James';
    private static final String DUMMY_PAYMENT_TYPE = 'card';
    private static final String DUMMY_ID = 'id-123456789';
    private static final String DUMMY_STATUS = 'AUTHORIZED';
    private static final String DUMMY_CARD_NETWORK = 'visa';
    private static final String DUMMY_CARD_LAST_4 = '1234';
    private static final DateTime DUMMY_DATE = System.today();
    private static final String DUMMY_EXPIRATION_YEAR = String.valueOf(DUMMY_DATE.addYears(1).year());
    private static final String DUMMY_EXPIRATION_MONTH = String.valueOf(DUMMY_DATE.addYears(1).month());


    @IsTest
    private static void valueQueriesShouldReturnCorrectValues() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        ElevateBatchItem batchItem;

        Test.startTest();
            batchItem = new ElevateBatchItem(createAuthorizedGiftResponse());
        Test.stopTest();

        System.assertEquals(DUMMY_PAYMENT_TYPE, batchItem.paymentMethod(), 'The batchItem. paymentMethod property is only used for testing.');
        System.assertEquals(DUMMY_ID, batchItem.id(), 'Assert that DUMMY_ID is the same as the batchItem s id.');
        System.assertEquals(DUMMY_ID, batchItem.gatewayTransactionId(), 'This method asserts that DUMMY_ID is the same as the gateway transaction id.');
        System.assertEquals(DUMMY_ID, batchItem.originalTransactionId(), 'Asserts that the original transaction id is the same as the DUMMY_ID.');
        System.assertEquals(DUMMY_ID, batchItem.elevateBatchId(), 'Assert that the DUMMY_ID is the same as the batchItem s elevation batch');
        System.assertEquals(System.today().addDays(1), batchItem.authExpiration(), 'Assert that the current time is equal to the batchItem s authExpiration.');
        System.assertEquals(DUMMY_STATUS, batchItem.status(), 'Checks that the status of the batch item is DUMMY_STATUS.');
        System.assertEquals(DUMMY_EXPIRATION_YEAR, batchItem.cardExpirationYear(), 'The DUMMY_EXPIRATION_YEAR is the same as the card expiration year.');
        System.assertEquals(DUMMY_EXPIRATION_MONTH, batchItem.cardExpirationMonth(), 'The DUMMY_EXPIRATION_MONTH is the same as the card expiration month.');
        System.assertEquals(DUMMY_ID, batchItem.gatewayId(), 'The DUMMY_ID is the same as the gatewayId.');
        System.assertEquals(DUMMY_ID, batchItem.gatewayTransactionId(), 'This method asserts that DUMMY_ID is the same as the gateway transaction id.');
        System.assertEquals(DUMMY_CARD_LAST_4, batchItem.cardLast4(), 'DUMMY_CARD_LAST_4 is the last 4 card of the batch item');
        System.assertEquals(DUMMY_DATE, batchItem.authorizedAt(), 'Checks that the current date is the same as the DUMMY_DATE.');
        System.assertEquals(DUMMY_CARD_NETWORK, batchItem.cardNetwork(), 'DUMMY_CARD_NETWORK is the same as the batchItem. cardNetwork.');
        System.assertEquals(null, batchItem.declineReason(), 'Assert that the declineReason of the batchItem is not null.');
    }

    private static ElevateBatchItemCreateResponse createAuthorizedGiftResponse() {
        ElevateBatchItemCreateResponse createBatchItemResponse = new ElevateBatchItemCreateResponse();
        createBatchItemResponse.batchItemType = ElevateBatchItemType.ONE_TIME;
        createBatchItemResponse.purchaseResponse = new ElevateBatchItemCreateResponse.PurchaseResponse();
        createBatchItemResponse.purchaseResponse.cardData = new ElevateBatchItemCreateResponse.CardData();
        createBatchItemResponse.purchaseResponse.id = DUMMY_ID;
        createBatchItemResponse.purchaseResponse.authExpiresAt = System.today().addDays(1);
        createBatchItemResponse.purchaseResponse.gatewayTransactionId = DUMMY_ID;
        createBatchItemResponse.purchaseResponse.paymentType = DUMMY_PAYMENT_TYPE;
        createBatchItemResponse.purchaseResponse.originalTransactionId = DUMMY_ID;
        createBatchItemResponse.purchaseResponse.batchId = DUMMY_ID;
        createBatchItemResponse.purchaseResponse.status = ElevateTransactionStatus.AUTHORIZED.name();
        createBatchItemResponse.purchaseResponse.cardData.expirationYear = String.valueOf(DUMMY_DATE.addYears(1).year());
        createBatchItemResponse.purchaseResponse.cardData.expirationMonth = String.valueOf(DUMMY_DATE.addYears(1).month());
        createBatchItemResponse.purchaseResponse.cardData.last4 = DUMMY_CARD_LAST_4;
        createBatchItemResponse.purchaseResponse.cardData.brand = DUMMY_CARD_NETWORK;
        createBatchItemResponse.purchaseResponse.gatewayId = DUMMY_ID;
        createBatchItemResponse.purchaseResponse.gatewayTransactionId = DUMMY_ID;
        createBatchItemResponse.purchaseResponse.authorizedAt = DUMMY_DATE;
        return createBatchItemResponse;
    }
}