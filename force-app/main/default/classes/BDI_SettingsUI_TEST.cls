/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer Settings user interface
*/

@isTest
private with sharing class BDI_SettingsUI_TEST {

    /*********************************************************************************************************
    * @description operation: 
    *    ensure methods of controller are tested 
    * verify: 
    *    all code tested in controller
    **********************************************************************************************************/            
    static testMethod void testBDISettingsUI() {
        
        // instantiate the controller
        BDI_SettingsUI_CTRL ctrl = new BDI_SettingsUI_CTRL();
        ctrl.diBatch = new DataImportBatch__c();

        Test.startTest();
        System.assertEquals(false, ctrl.isEditMode, 'Checks if the current mode is edit mode.');
        System.assertEquals(true, ctrl.isReadOnlyMode, 'Tests if the current mode is read - only.');
        System.assertNotEquals(null, ctrl.listSODonationFields, 'This function asserts that the list of SODonationFields is not null.');
        System.assertNotEquals(null, ctrl.listSOContactUniqueID, 'This method asserts that the listSOContactUniqueID is not null.');
        System.assertNotEquals(null, ctrl.listSOAccountUniqueID, 'This method asserts that the listSOAccountUniqueID property is not null.');
        System.assertEquals(BDI_DataImport_API.DoNotMatch, ctrl.getDoNotMatch(), 'This method asserts that the current ctrl s DoNotMatch value is the same as the current');
        System.assertEquals(BDI_DataImport_API.RequireNoMatch, ctrl.getRequireNoMatch(), 'This method should only be used for testing.');
        System.assertEquals(BDI_DataImport_API.RequireExactMatch, ctrl.getRequireExactMatch(), 'This method asserts that the RequireExactMatch value is the same as the current RequireExactMatch');
        System.assertEquals(BDI_DataImport_API.ExactMatchOrCreate, ctrl.getExactMatchOrCreate(), 'This method asserts that the current data import is exactly the same as the current data import.');
        System.assertEquals(BDI_DataImport_API.RequireBestMatch, ctrl.getRequireBestMatch(), 'This method should only be called if the RequireBestMatch is the same as the current Require');
        System.assertEquals(BDI_DataImport_API.BestMatchOrCreate, ctrl.getBestMatchOrCreate(), 'This method asserts that the best match is created.');
        Test.stopTest();
    }

    /*******************************************************************************************************************
     * @description Verifies that the right Mapping Method is loaded - Help Text
     *
     */
    @IsTest
    static void testBDI_SettingsUIMapping_HelpText(){
        UTIL_CustomSettingsFacade.enableHelpTextMapping();
        BDI_SettingsUI_CTRL ctrl = new BDI_SettingsUI_CTRL();
        Boolean containsImportedField = false;

        for (SelectOption option : ctrl.listSODonationFields) {

            String paymentOriginIdField = SObjectType.DataImport__c.fields.Payment_Origin_Id__c.Name.toLowerCase();
            if (option.getValue() == paymentOriginIdField) {
                containsImportedField = true;
                break;
            }
        }
        Test.startTest();
        System.assert(!containsImportedField, 'Help Text Mapping Enabled');
        Test.stopTest();
    }

    /*******************************************************************************************************************
     * @description Verifies that the right Mapping Method is loaded - Advanced Mapping
     *
     */
    @IsTest
    static void testBDI_SettingsUIMapping_AdvancedMapping(){
        UTIL_CustomSettingsFacade.enableAdvancedMapping();
        BDI_SettingsUI_CTRL ctrl = new BDI_SettingsUI_CTRL();
        Boolean containsImportedField = false;

        for (SelectOption option : ctrl.listSODonationFields) {

            String paymentOriginIdField = SObjectType.DataImport__c.fields.Payment_Origin_Id__c.Name.toLowerCase();
            if (option.getValue() == paymentOriginIdField) {
                containsImportedField = true;
                break;
            }
        }
        Test.startTest();
        System.assert(containsImportedField, 'Advanced Field Mapping Enabled');
        Test.stopTest();
    }
}