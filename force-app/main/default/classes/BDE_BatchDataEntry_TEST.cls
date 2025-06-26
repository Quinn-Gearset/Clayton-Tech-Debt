/*
    Copyright (c) 2015 Salesforce.org
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
* @author Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
* @date 04/27/2011
* @group BatchDataEntry
* @description test class for the batch data entry, supports all the custom settings you might have.
*/
@isTest
private class BDE_BatchDataEntry_TEST {
    /*********************************************************************************************************
    * @description Validates the BDE_BatchDataEntry methods.
    */
    static testMethod void testBatchDataEntry(){
        BDE_BatchDataEntry bde;

        bde = new BDE_BatchDataEntry(null);
        System.assert(bde.getStatusMessage().contains('Success'), 'Assert that the BDE is successful.');

        bde = new BDE_BatchDataEntry('foo');
        System.assert(bde.getStatusMessage().contains('Failure'), 'Checks if the BDE is not a failure');        
        
        // There is no way to create the field set in apex,
        // so we are assuming in this test that one exists on Opportunity, and it includes the Name field.
        bde = new BDE_BatchDataEntry('Opportunity');
        System.assertEquals('Opportunity', bde.getObjectName(), 'Assert that the BLE object is the same as the BLE object.');
        System.assertEquals(true, bde.getSaveBatch(), 'Test if the save batch is true.');
        System.assertNotEquals(null, bde.getEntryFieldList(), 'Assert that the BDE is not null.');
        System.assertNotEquals(null, bde.getListFieldList(), 'Assert that the list of fields in the BDE is not null.');       
        System.assertEquals('Success', bde.getStatusMessage(), 'Assert that the BDE is successful.');
        System.assert(bde.getFieldSet().contains('Name'), 'Checks that the BDE field is set.');
        System.assertNotEquals(null, bde.getQueryString(), 'Assert that the query string is not null.');
        System.assertNotEquals(null, bde.getFailureMessage(), 'Asserts that the failure message is not null.');
        System.assertNotEquals(null, bde.getBatchLookupFieldName(), 'This method asserts that the field name of the BatchLookup object is not null.');
        System.assertNotEquals(0, BDE_BatchDataEntry.mapDevNameToLabelBDEObjects().size(), 'This method asserts that the number of BDE objects in the batch is not equal to zero');
        
        //Adding hard references to fieldset to make sure they don't get deleted from the package
        System.assertNotEquals(null, Schema.SObjectType.Account.fieldSets.BDE_Entry_FS.getFields(), 'This method asserts that the BDEEntry_FS is not null.');
        System.assertNotEquals(null, Schema.SObjectType.Account.fieldSets.BDE_List_FS.getFields(), 'This method asserts that the BDE List FS is not null.');
        System.assertNotEquals(null, Schema.SObjectType.Account.fieldSets.Manage_Household_Custom.getFields(), 'This method checks that the fields of the manage household custom are not null.');
        System.assertNotEquals(null, Schema.SObjectType.Batch__c.fieldSets.BatchDetailView.getFields(), 'This method asserts that the fields in the batch detail view are not null.');
        System.assertNotEquals(null, Schema.SObjectType.Contact.fieldSets.BDE_Entry_FS.getFields(), 'Checks that all BDE_Entry_FS fields are null.');       
	    System.assertNotEquals(null, Schema.SObjectType.Contact.fieldSets.BDE_List_FS.getFields(), 'Checks that all BDE_List_FS fields are null.');
	    System.assertNotEquals(null, Schema.SObjectType.Lead.fieldSets.BDE_Entry_FS.getFields(), 'Checks that the BDEEntryFS is not null.');
	    System.assertNotEquals(null, Schema.SObjectType.Lead.fieldSets.BDE_List_FS.getFields(), 'This method asserts that the BDE_List_FS is not null.');
	    System.assertNotEquals(null, Schema.SObjectType.Opportunity.fieldSets.BDE_Entry_FS_v2.getFields(), 'This method asserts that the fields in the BDE_Entry_FS_v2 are');
	    System.assertNotEquals(null, Schema.SObjectType.Opportunity.fieldSets.BDE_List_FS_v2.getFields(), 'This method is used to assert that the fields in the BDE list are not null.');
    }
}