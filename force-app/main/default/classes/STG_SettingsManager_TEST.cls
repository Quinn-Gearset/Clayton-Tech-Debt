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
* @author Salesforce.org
* @date 01/13/2014
* @group Settings
* @description test code for all of Settings
*/
@isTest
private with sharing class STG_SettingsManager_TEST {
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();
    /***
    * @description Installment Opportunities Auto Creation Setting API value
    */
    private static final String OPTION_NAME_DISABLE_FIRST = RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name();
    private static final String OPTION_NAME_DISABLE_ALL = RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
    private static final String OPTION_NAME_ALWAYS_CREATE_NEXT = RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name();

    /**
    * @description Reference new labels in 238 that are not being picked up by the Packaging Spider
    *
    * TODO IN 240 : CONSIDER CREATING A NEW APEX CLASS WITH NEW LABELS ADDED TO THE RELEASE, BUT ONLY FOR LABELS THAT ARE 
    *    REFERENCED BY VISUALFORCE PAGES ONLY (I.E., NO APEX/LWC/AURA REFERENCE)
    */
    private static final List<String> LABEL_REFERENCES_FOR_238_BETA = new List<String>{ 
        Label.stgNavRD2StatusAutomation,
        Label.stgHHDataRefreshTitle,
        Label.conMergeStageCurrent,
        Label.conMergeStageComplete,
        Label.REL_ViewerGraphical,
        Label.REL_ViewerTabular,
        Label.conMergeStageNotStarted,
        Label.lblEmpty,
        Label.stgBtnRunHHDeceasedBatch,
        Label.stgHHDataRefreshTitle,
        Label.stgHelpHHData,
        Label.stgHelpDeceasedBatch,
        Label.stgLabelDeceasedBatch
    };

    /*********************************************************************************************************
    * @description Tests the Settings Manager page
    * @return void
    */
    @isTest
    private static void testSettingsManager() {
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL();
        system.assertEquals('idPanelHome', STG_SettingsManager_CTRL.idPanelCurrent, 'Checks that the current ID of the Panel is the same as the idPanelHome.');
        system.assertEquals(null, ctrl.setPanelCurrent(), 'Assert that the panel is currently active.');
    }

    /*********************************************************************************************************
    * @description Tests setting up TDTM and the Schedulables
    * @return void
    */
    @isTest
    private static void testRequiredJobsAreScheduledWhenNpspSettingsPageLoads() {
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL();

        Test.startTest();
        ctrl.onNpspSettingsLoad();
        Test.stopTest();

        List<CronTrigger> masterJobs = [
            SELECT Id, CronJobDetail.Id
            FROM CronTrigger
            WHERE CronJobDetail.Name IN :UTIL_MasterSchedulableHelper.defaultScheduledJobs.keySet() AND
                CronJobDetail.JobType = '7'
        ];
        System.assertEquals(UTIL_MasterSchedulableHelper.defaultScheduledJobs.keySet().size(), masterJobs.size(), 'Checks that the number of default scheduled jobs is the same as the number of master jobs.');

        System.assertNotEquals(null, STG_Panel.stgService, 'This method asserts that the STG_Panel. stgService is not null.');
    }


    /*********************************************************************************************************
    * @description Tests an exception message is displayed if the record type settings update throws an exception
    * @return void
    */
    @isTest
    private static void testRecordTypeSettingsUpdateExceptionIsDisplayed() {
        Test.setCurrentPage(Page.STG_SettingsManager);

        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL();

        UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock mockUpdateSettings = new UTIL_RecordTypeSettingsUpdate_TEST.UpdateSettingsMock().throwException();
        UTIL_RecordTypeSettingsUpdate.instance = mockUpdateSettings;

        Test.startTest();
        ctrl.onNpspSettingsLoad();
        Test.stopTest();

        UTIL_UnitTestData_TEST.assertPageHasError('Test Exception');
    }

    /*********************************************************************************************************
    * @description Verifies if it unchecks the default allocations enabled checkbox and clears the value
      of default id in allocations settings when no GAU is found.
    * @return void
    */
    @isTest
    private static void shouldRemoveAllocDefaultIfGauDoesNotExist() {
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL();

        //set payment allocations to true for the error messages
        STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c = true;
        STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c = true;
        STG_Panel.stgService.stgAllo.Default__c = 'a9302003536469';
        upsert STG_Panel.stgService.stgAllo;

        System.assertEquals(0, [SELECT count() FROM Error__c], 'Test for equality of all errors.');

        Test.startTest();
            ctrl.onNpspSettingsLoad();
        Test.stopTest();

        System.assertEquals(false, STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c, 'Settings should be unchecked');
        System.assertEquals(null, STG_Panel.stgService.stgAllo.Default__c, 'Default GAU value should not be filled in.');
        System.assertEquals(1, [SELECT count() FROM Error__c], 'Test for equality of the number of errors in the database.');
        System.assertEquals(System.Label.stgErrorMissingDefaultGauRecordWithPmtAllocEnabled, ctrl.errorMsg, 'assertEquals - This is a test for the case where the default GA record is missing');
    }

    /*********************************************************************************************************
    * @description Verifies if it displays error message when payment allocations is disabled and default GAU
     is enabled, also clears custom settings when no GAU is found.
    * @return void
    */
    @isTest
    private static void shouldDisplayErrorMessageWhenPaymentdisabled() {
        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL();

        //set payment allocations to true for the error messages
        STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c = false;
        STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c = true;
        STG_Panel.stgService.stgAllo.Default__c = 'a9302003536469';
        upsert STG_Panel.stgService.stgAllo;

        System.assertEquals(0, [SELECT count() FROM Error__c], 'Test for equality of all errors.');

        Test.startTest();
            ctrl.onNpspSettingsLoad();
        Test.stopTest();

        System.assertEquals(false, STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c, 'Settings should be unchecked');
        System.assertEquals(null, STG_Panel.stgService.stgAllo.Default__c, 'Default GAU value should not be filled in.');
        System.assertEquals(1, [SELECT count() FROM Error__c], 'Test for equality of the number of errors in the database.');
        System.assertEquals(System.Label.stgErrorMissingDefaultGauRecord, ctrl.errorMsg, 'assertEquals - This is a test for the case where the default GARecord is missing');
    }

    /*********************************************************************************************************
    * @description Verifies Default GAU is not cleared if default GAU is present.
    * @return void
    */
    @isTest
    private static void shouldNotRemoveAllocDefaultIfGauExist() {
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;

        STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL();

        STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c = true;
        STG_Panel.stgService.stgAllo.Default__c = gau.id;
        upsert STG_Panel.stgService.stgAllo;

        Test.startTest();
            ctrl.onNpspSettingsLoad();
        Test.stopTest();

        System.assertEquals(true, STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c, 'Settings should be checked');
        System.assertEquals(gau.id, STG_Panel.stgService.stgAllo.Default__c, 'Default GAU value should be filled in.');
        System.assertEquals(0, [SELECT count() FROM Error__c], 'Test for equality of all errors.');
        System.assertEquals(null, ctrl.errorMsg, 'assertEquals - Tests that errorMsg is null.');
    }

    /**
    * @description Verifies that when the options are selected, the displayed string will be converted to Label and the
    * actual values will stay in Api format
    */
    @isTest
    private static void shouldConvertToLabelForDisplayAndApiValueForSaving() {
        STG_DataBoundMultiSelect_CTRL ctrl = new STG_DataBoundMultiSelect_CTRL();
        List<SelectOption> options = new List<SelectOption> {
            new SelectOption('value1', 'label1'),
            new SelectOption('value2', 'label2'),
            new SelectOption('value3', 'label3')
        };

        Contact con = new Contact();

        con.npo02__Naming_Exclusions__c = 'value1;value2';
        ctrl.sobjBinding = con;
        ctrl.listSelectOption = options;
        ctrl.strField = 'npo02__Naming_Exclusions__c';

        System.assertEquals('label1;label2', ctrl.strValues, 'strValues should be convert to label for display');
        System.assertEquals('value1;value2', con.npo02__Naming_Exclusions__c, 'Field value should remain the API value');

        Test.startTest();
        ctrl.listStrValues = new List<String>{'value2', 'value3'};
        Test.stopTest();

        System.assertEquals('label2;label3', ctrl.strValues, 'strValues should be convert to label for display');
        System.assertEquals('value2;value3', con.npo02__Naming_Exclusions__c, 'Field value should remain the API value');
    }

    /*********************************************************************************************************
    * @description Tests the panel infrastructure and shared lists of SelectOptions
    * @return void
    */
    @isTest
    private static void testPanel() {
        STG_Panel ctrl = new STG_Panel();
        system.assertEquals(null, ctrl.idPanel(), 'Assert that idPanel is null.');
        ctrl.isEditMode = true;
        system.assertEquals(true, ctrl.isEditMode, 'Checks if the current user is in edit mode.');
        system.assertEquals(false, ctrl.isReadOnlyMode, 'Checks if the current mode is read - only.');
        system.assertNotEquals(null, STG_Panel.stgService, 'Checks that STG_Panel. stgService is not null.');
        system.assertEquals(null, ctrl.saveSettings(), 'Assert that saveSettings is called after saveSettings has been called.');
        system.assertEquals(false, ctrl.isEditMode, 'Checks if the current user is in edit mode.');
        system.assertEquals(null, ctrl.editSettings(), 'Assert that editSettings is null.');
        system.assertEquals(true, ctrl.isEditMode, 'Checks if the current user is in edit mode.');
        system.assertEquals(null, ctrl.cancelEdit(), 'Checks that cancelEdit is called.');
        system.assertEquals(false, ctrl.isEditMode, 'Checks if the current user is in edit mode.');
        system.assertEquals(3, STG_Panel.listSOAccountModels.size(), 'Checks that 3 stg_panel. listSOAccountModels. size');
        system.assertNotEquals(null, STG_Panel.listSOHHRules, 'Checks that the list of all the SOFT rules is not null.');
        system.assertNotEquals(null, STG_Panel.listSOContactRecTypes, 'Checks that the list of STG_Panel. listSOContactRecTypes is not null');
        system.assertNotEquals(null, STG_Panel.listSOAccountRecTypeIds, 'This function asserts that the list of record types in STG_Panel is not null.');
        system.assertNotEquals(null, STG_Panel.listSOOppRecTypes, 'Assert that STG_Panel. listSOOppRecTypes is not null.');
        system.assertNotEquals(null, STG_Panel.listSOOppRecTypesIds, 'Checks that the list of all the STG_Panel. listSOOppRecTypes');
        system.assertNotEquals(null, STG_Panel.listSOOppContactRoles, 'Checks that the list of all the contact roles is not null.');
        system.assertNotEquals(null, STG_Panel.listSOOppTypes, 'Assert that STG_Panel. listSOOppTypes is not null.');
        system.assertNotEquals(null, STG_Panel.listSORelTypes, 'Assert that STG_Panel. listSORelTypes is not null.');
        system.assertNotEquals(null, STG_Panel.listSOCampaignTypes, 'Checks that STG_Panel. listSOCampaignTypes is not null');
        system.assertNotEquals(null, STG_Panel.listSOMailingReportIds, 'Checks that STG_Panel. listSOMailingReportIds is not null.');
        system.assertNotEquals(null, ctrl.isDisplayingRD2UpgradePage, 'Checks that the current page is not displaying the RD2 upgrade page.');
    }

    /*********************************************************************************************************
    * @description Tests that the Settings Service has each settings object loaded
    * @return void
    */
    @isTest
    private static void testSettingsService() {
        STG_SettingsService svc = STG_SettingsService.stgService;
        system.assertNotEquals(null, svc, 'Assert that the given service is not null.');
        system.assertNotEquals(null, svc.stgCon, 'Assert that the STGCon object is not null.');
        system.assertNotEquals(null, svc.stgHH, 'asserts that stgHH is not null');
        system.assertNotEquals(null, svc.stgRD, 'Assert that the STG RD is not null.');
        system.assertNotEquals(null, svc.stgRel, 'Assert that the STGRel is not null.');
        system.assertNotEquals(null, svc.stgAffl, 'Assert that the STGAffl is not null.');
        system.assertNotEquals(null, svc.stgBDE, 'Assert that the STG BDE is not null.');
        system.assertNotEquals(null, svc.stgCRLP, 'Assert that the STGCRLP is not null.');
        system.assertNotEquals(null, svc.mapRDCustomField, 'This function asserts that the mapRDCustomField is not null.');
        system.assertNotEquals(null, svc.listRDCustomInstallment, 'This function asserts that the list of RD Custom Installments is not null.');
        system.assertNotEquals(null, svc.listRDCustomFieldMapping, 'Asserts that the list of RDCustomFieldMappings returned by the service is not null.');
        system.assertNotEquals(null, svc.listPMTFieldMapping, 'Checks that the listPMTFieldMapping method is not null.');
        svc.saveAll();
    }

    /*********************************************************************************************************
    * @description Tests the Affiliations panel
    * @return void
    */
    @isTest
    private static void testPanelAffl() {
        STG_PanelAffiliations_CTRL panel = new STG_PanelAffiliations_CTRL();
        system.assertEquals('idPanelAffl', panel.idPanel(), 'Checks that the idPanelAffl is the same as the panel idPanel.');
        STG_Panel.stgService.stgAffl.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgAffiliationsSettings().npe5__Automatic_Affiliation_Creation_Turned_On__c, 'asserts that automatic affiliation creation is turned on');
        STG_Panel.stgService.stgAffl.npe5__Automatic_Affiliation_Creation_Turned_On__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgAffiliationsSettings().npe5__Automatic_Affiliation_Creation_Turned_On__c, 'asserts that automatic affiliation creation is turned on');
    }

    /*********************************************************************************************************
    * @description Tests the Allocations panel
    * @return void
    */
    @isTest
    private static void testPanelAllo() {
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(name='foo');
        insert gau;

        STG_PanelAllocations_CTRL panel = new STG_PanelAllocations_CTRL();
        system.assertEquals('idPanelAllocations', panel.idPanel(), 'Checks that the idPanelAllocations property of the panel is equal to the idPanelAlloc');
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgAllocationsSettings().Payment_Allocations_Enabled__c, 'Payment Allocations should not be enabled.');
        system.assertEquals(panel.strAllocationLevel, STG_Panel.oppLabel, 'If Payment Allocations are not enabled, allocation level should be opportunity');
        // Simulate selecting Payment Allocations without default GAU set
        panel.strAllocationLevel = STG_Panel.paymentLabel;

        panel.saveSettings();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        system.assertEquals(1, msgs.size(), 'Default GAU must be enabled');
        system.assert(msgs[0].getDetail().contains(Label.alloDefaultNotEnabled), 'Check if default is enabled');

        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgAllocationsSettings().Default_Allocations_Enabled__c, 'Settings should not save successfully.');
        system.assertEquals(null,UTIL_CustomSettingsFacade.getOrgAllocationsSettings().Default__c, 'Default GAU value should not be filled in.');

        // Try again with just default allocations enabled
        STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c = true;

        panel.saveSettings();

        msgs = ApexPages.getMessages();
        system.assertEquals(2, msgs.size(), 'New error, a Default GAU value must be set');
        system.assert(msgs[1].getDetail().contains(Label.alloDefaultGAUMissing), 'Checks that default gaum missing label is present.');

        // Finally, set everything correctly
        STG_PanelAllocations_CTRL.allo = null;
        STG_Panel.stgService.stgAllo.Default__c = gau.id;

        panel.saveSettings();

        msgs = ApexPages.getMessages();
        system.assertEquals(2, msgs.size(), 'No new error messages');
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgAllocationsSettings().Default_Allocations_Enabled__c, 'Settings should save successfully.');
        system.assertNotEquals(null,UTIL_CustomSettingsFacade.getOrgAllocationsSettings().Default__c, 'Default GAU value should be filled in.');
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgAllocationsSettings().Payment_Allocations_Enabled__c, 'Payment Allocations should be enabled.');
    }

    /*********************************************************************************************************
    * @description Tests the Batch Data Entry panel
    * @return void
    */
    @isTest
    private static void testPanelBDE() {
        STG_PanelBDE_CTRL panel = new STG_PanelBDE_CTRL();
        system.assertEquals('idPanelBDE', panel.idPanel(), 'Checks that the idPanelBDE is the same as the panel.');
        STG_Panel.stgService.stgBDE.Opportunity_Naming__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgBDESettings().Opportunity_Naming__c, 'asserts that the opportunity naming is set in the system settings');
        STG_Panel.stgService.stgBDE.Opportunity_Naming__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgBDESettings().Opportunity_Naming__c, 'asserts that the opportunity naming is turned off');
    }

    /*********************************************************************************************************
    * @description Tests the Contact Roles panel
    * @return void
    */
    @isTest
    private static void testPanelContactRoles() {
        STG_PanelContactRoles_CTRL panel = new STG_PanelContactRoles_CTRL();
        system.assertEquals('idPanelConRoles', panel.idPanel(), 'Checks that the panel s id is equal to the idConRoles property of the panel.');
        STG_Panel.stgService.stgCon.npe01__Enable_Opportunity_Contact_Role_Trigger__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Enable_Opportunity_Contact_Role_Trigger__c, 'asserts that Enable Opportunity Contact Role Trigger is enabled');
        STG_Panel.stgService.stgCon.npe01__Enable_Opportunity_Contact_Role_Trigger__c = false;
        STG_Panel.stgService.stgCon.npe01__Opportunity_Contact_Role_Default_role__c = 'Decision Maker';
        STG_Panel.stgService.stgHH.npo02__Household_Contact_Roles_On__c = true;
        STG_Panel.stgService.stgHH.npo02__Household_Member_Contact_Role__c = 'Decision Maker';
        STG_Panel.stgService.stgHH.npo02__Soft_Credit_Roles__c = 'Decision Maker;Something Else';
        panel.saveSettings();
        system.assertEquals(2, ApexPages.getMessages().size(), 'Two error messages should be created for identical the role values.' + ApexPages.getMessages());
    }

    /*********************************************************************************************************
    * @description Tests the Contacts panel
    * @return void
    */
    @isTest
    private static void testPanelContacts() {
        String hhAccountRecTypeLabel = STG_PanelContacts_CTRL.strHHAccountRecordTypeLabel;
        String oneToOneRecordTypeLabel = STG_PanelContacts_CTRL.strOneToOneRecordTypeLabel;

        STG_PanelContacts_CTRL panel = new STG_PanelContacts_CTRL();
        system.assertEquals('idPanelCon', panel.idPanel(), 'Assert that the panel is the same as the panel con.');

        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR;
        panel.saveSettings();

        system.assertEquals('Household Account', UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Account_Processor__c, 'asserts that Household Account is set in the org contacts settings');

        STG_Panel.stgService.stgCon.npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR;
        panel.saveSettings();

        system.assertEquals('One-to-One', UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Account_Processor__c, 'Checks that Account Processor is set to One - to - One');
    }

    /*********************************************************************************************************
    @description
        Tests Refresh Household Names batch when Automatic Household Naming is turned off
        and Household Naming Settings is invalid
    verify:
        Household Naming batch has not been run.
        Automatic Household Naming field is still turned off.
        The Page contains an error.
    **********************************************************************************************************/
    @isTest
    private static void testPanelRenameHHDoesNotRunBatchWhenHHNamingSettingsIsInvalid() {
        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();
        UTIL_UnitTestData_TEST.setupInvalidHHNamingSettings();

        Test.setCurrentPage(Page.STG_PanelRenameHouseholds);

        STG_PanelRenameHouseholds_CTRL ctrl = new STG_PanelRenameHouseholds_CTRL();
        System.assert(!ctrl.isRunningRenameHouseholdsBatch, 'The batch should not run');

        Test.startTest();
        PageReference pg = ctrl.runRenameHouseholdsBatch();
        Test.stopTest();

        System.assertEquals(null, pg, 'Returned PageReference should be null');
        System.assert(!ctrl.isRunningRenameHouseholdsBatch, 'The batch should not run');
        System.assertEquals(false, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Advanced_Household_Naming__c, 'Automatic Household Naming should be turned off');

        UTIL_UnitTestData_TEST.assertPageHasError('Invalid field');
    }

    /*********************************************************************************************************
    @description
        Tests Refresh Household Names batch when Automatic Household Naming is turned off
        and Household Naming Settings is valid
    verify:
        Household Naming batch has been run.
        Automatic Household Naming field is turned on.
        The Page contains no error.
    **********************************************************************************************************/
    @isTest
    private static void testPanelRenameHHRunsBatchWhenAutomaticHHNamingIsOff() {
        UTIL_UnitTestData_TEST.turnOffAutomaticHHNaming();

        Test.setCurrentPage(Page.STG_PanelRenameHouseholds);

        STG_PanelRenameHouseholds_CTRL ctrl = new STG_PanelRenameHouseholds_CTRL();
        System.assert(!ctrl.isRunningRenameHouseholdsBatch, 'The batch should not run');

        Test.startTest();
        PageReference pg = ctrl.runRenameHouseholdsBatch();
        Test.stopTest();

        System.assertEquals(null, pg, 'Returned PageReference should be null');
        System.assert(ctrl.isRunningRenameHouseholdsBatch, 'The batch should run');
        System.assertEquals(true, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Advanced_Household_Naming__c, 'Automatic Household Naming should be turned on');

        System.assertEquals(0, ApexPages.getMessages().size(), 'The page should not contain any error: ' + ApexPages.getMessages());
    }

    /*********************************************************************************************************
    @description
        Tests Refresh Household Names batch when Automatic Household Naming is turned on
    verify:
        Household Naming batch has been run.
        The Page contains no error.
    **********************************************************************************************************/
    @isTest
    private static void testPanelRenameHHRunsBatchWhenAutomaticHHNamingIsOn() {
        UTIL_UnitTestData_TEST.turnOnAutomaticHHNaming();

        Test.setCurrentPage(Page.STG_PanelRenameHouseholds);

        STG_PanelRenameHouseholds_CTRL ctrl = new STG_PanelRenameHouseholds_CTRL();
        System.assert(!ctrl.isRunningRenameHouseholdsBatch, 'The batch should not run');

        Test.startTest();
        PageReference pg = ctrl.runRenameHouseholdsBatch();
        Test.stopTest();

        System.assertEquals(null, pg, 'Returned PageReference should be null');
        System.assert(ctrl.isRunningRenameHouseholdsBatch, 'The batch should run');
        System.assertEquals(true, UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Advanced_Household_Naming__c, 'Automatic Household Naming should be turned on');

        System.assertEquals(0, ApexPages.getMessages().size(), 'The page should not contain any error: ' + ApexPages.getMessages());
    }

    /*********************************************************************************************************
    * @description Tests the Leads panel
    * @return void
    */
    @isTest
    private static void testPanelLeads() {
        STG_PanelLeads_CTRL panel = new STG_PanelLeads_CTRL();
        system.assertEquals('idPanelLeads', panel.idPanel(), 'Checks that the idPanelLeads property of the panel is equal to the idPanel of');
        STG_Panel.stgService.stgCon.npe01__Default_Opp_on_Convert__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Default_Opp_on_Convert__c, 'Checks if the default opp on convert is turned on or off.');
        STG_Panel.stgService.stgCon.npe01__Default_Opp_on_Convert__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Default_Opp_on_Convert__c, 'asserts that the default opp on convert is turned off');
    }

    /*********************************************************************************************************
    * @description Tests the Membership panel
    * @return void
    */
    @isTest
    private static void testPanelMembership() {
        STG_PanelMembership_CTRL panel = new STG_PanelMembership_CTRL();
        system.assertEquals('idPanelMembership', panel.idPanel(), 'Checks that the panel membership is the same as the panel itself.');
        STG_Panel.stgService.stgHH.npo02__Membership_Grace_Period__c = 10;
        panel.saveSettings();
        system.assertEquals(10, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Membership_Grace_Period__c, 'Checks membership grace period.');
        STG_Panel.stgService.stgHH.npo02__Membership_Grace_Period__c = 20;
        panel.saveSettings();
        system.assertEquals(20, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Membership_Grace_Period__c, 'Checks membership grace period.');
    }

    /*********************************************************************************************************
    * @description Tests the Run Opp Rollups Batch panel
    * @return void
    */
    @isTest
    private static void testPanelOppBatch() {
        STG_PanelOppBatch_CTRL panel = new STG_PanelOppBatch_CTRL();
        system.assertEquals('idPanelOppBatch', panel.idPanel(), 'Assert that the idPanelOppBatch is the same as the panel idPanel.');
        system.assertEquals(false, panel.isRunningBatch, 'Asserts that the panel is running batch.');
        panel.runBatch();
        system.assertEquals(true, panel.isRunningBatch, 'Checks that the panel is running batch.');
    }

    /*********************************************************************************************************
    * @description Tests the Donor Statistics panel
    * @return void
    */
    @isTest
    private static void testPanelOppRollups() {
        STG_PanelOppRollups_CTRL panel = new STG_PanelOppRollups_CTRL();
        system.assertEquals('idPanelOppRollup', panel.idPanel(), 'Checks that the idPanelOppRollup is the same as the idPanel of the');
        STG_Panel.stgService.stgHH.npo02__Batch_Size__c = 10;
        panel.saveSettings();
        system.assertEquals(10, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Batch_Size__c, 'asserts that batch size is equal to 10');
        STG_Panel.stgService.stgHH.npo02__Batch_Size__c = 20;
        panel.saveSettings();
        system.assertEquals(20, UTIL_CustomSettingsFacade.getOrgHouseholdsSettings().npo02__Batch_Size__c, 'check that batch size is equal to 20');
    }

    /*********************************************************************************************************
    * @description Tests the Payments panel
    * @return void
    */
    @isTest
    private static void testPanelOpps() {
        STG_PanelOpps_CTRL panel = new STG_PanelOpps_CTRL();
        system.assertEquals('idPanelOpp', panel.idPanel(), 'Checks that the idPanelOpp is the same as the panel.');
        STG_Panel.stgService.stgCon.npe01__Payments_Enabled__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Payments_Enabled__c, 'asserts that payments are enabled');
        STG_Panel.stgService.stgCon.npe01__Payments_Enabled__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgContactsSettings().npe01__Payments_Enabled__c, 'asserts that payments are enabled');
    }

    /*********************************************************************************************************
    * @description Tests the opportunity naming panel
    * @return void
    */
    @isTest
    private static void testPanelOppNaming() {
        STG_PanelOppNaming_CTRL panel = new STG_PanelOppNaming_CTRL();
        system.assertEquals('idPanelOppNaming', panel.idPanel(), 'Assert that the panel s opp naming is the same as the panel s opp naming');
        panel.newONS();
        panel.currentONS.Date_Format__c = 'YYYY-MM-dd';
        panel.currentONS.Opportunity_Name_Format__c = '{!Contact.LastName} {!CloseDate}';
        system.assert(panel.isValidNameFormats(), 'Validation should pass.');
        panel.saveONS();
        system.assertEquals(1, panel.mapOppNameSettings.size(), 'The opportunity naming setting should be saved.');
    }

    /*********************************************************************************************************
    * @description Tests the Payment Mappings panel
    * @return void
    */
    @isTest
    private static void testPanelPaymentMapping() {
        STG_PanelPaymentMapping_CTRL panel = new STG_PanelPaymentMapping_CTRL();
        system.assertEquals('idPanelPaymentMapping', panel.idPanel(), 'Asserts that the idPanelPaymentMapping is the same as the panel idPanel.');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        system.assertNotEquals(null, panel.getSourceFields(), 'Assert that the source fields of the panel are not null.');
        system.assertNotEquals(null, panel.getTargetFields(), 'Assert that the target fields are not null.');
        system.assertEquals(null, panel.newPfm(), 'Assert that panel is not null.');
        system.assertNotEquals(null, panel.pfmNew, 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertEquals(null, panel.cancelPfmEdit(), 'Asserts that cancelPfmEdit is called.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertEquals(null, panel.newPfm(), 'Assert that panel is not null.');
        system.assertNotEquals(null, panel.pfmNew, 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.pfmNew.npe01__Opportunity_Field__c = null;
        panel.pfmNew.npe01__Payment_Field__c = null;
        system.assertEquals(null, panel.savePfm(), 'Assert that the panel s savePfm property is null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.pfmNew.npe01__Opportunity_Field__c = 'Amount';
        system.assertEquals(null, panel.onSelectSourceField(), 'Assert that the source field of the panel is the same as the onSelectSourceField method');
        panel.pfmNew.npe01__Payment_Field__c = 'npe01__Payment_Amount__c';
        system.assertEquals(true, panel.isPfmNewValid, 'Checks if the panel is valid.');
        system.assertEquals(null, panel.savePfm(), 'Assert that the panel s savePfm property is null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.listPMTFieldMapping, 'Assert that the panel s listPMTFieldMapping is not null.');
        system.assertEquals(1, panel.listPMTFieldMapping.size(), 'Checks that the size of the panel is equal to 1.');
        panel.pfmIdDelete = panel.listPMTFieldMapping[0].Id;
        system.assertEquals(null, panel.deletePfm(), 'Delete the panel.');
        system.assertNotEquals(null, panel.listPMTFieldMapping, 'Assert that the panel s listPMTFieldMapping is not null.');
        system.assertEquals(0, panel.listPMTFieldMapping.size(), 'Checks that the number of PMT fields is the same as the number of PMT fields');

        // save a bogus mapping, and verify our check complains
        panel.pfmNew.npe01__Opportunity_Field__c = 'NoExist';
        panel.pfmNew.npe01__Payment_Field__c = 'NoExist';
        system.assertEquals(true, panel.isPfmNewValid, 'Checks if the panel is valid.');
        system.assertEquals(null, panel.savePfm(), 'Assert that the panel s savePfm property is null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.listPMTFieldMapping, 'Assert that the panel s listPMTFieldMapping is not null.');
        system.assertEquals(1, panel.listPMTFieldMapping.size(), 'Checks that the size of the panel is equal to 1.');

    }

    /*********************************************************************************************************
    * @description Tests the Recurring Donations panel
    * @return void
    */
    @isTest
    private static void testPanelRD() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        system.assertEquals('idPanelRD', panel.idPanel(), 'Assert that idPanelRD is the same as panel.');
        panel.init();
        system.assertNotEquals(null, panel.listSORDCloseOptions, 'Assert that listSORDCloseOptions is not null');
        system.assertNotEquals(null, panel.listSORDCloseOptions, 'Assert that listSORDCloseOptions is not null');

        STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c = 10;
        system.assertEquals(null, panel.saveSettings(), 'Assert that the settings of the panel are equal.');
        system.assertEquals(10, STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c, 'Opportunity forecast months c');
        STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c = 5;
        system.assertEquals(null, panel.saveSettings(), 'Assert that the settings of the panel are equal.');
        system.assertEquals(5, STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c, 'Opportunity forecast months are equal to 5');
        STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c = 15;
        system.assertEquals(null, panel.saveSettings(), 'Assert that the settings of the panel are equal.');
        system.assertEquals(15, STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c, 'Opportunity forecast months are equal to OPPORTunity forecast months.');
        system.assertEquals(15, UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings().npe03__Opportunity_Forecast_Months__c, 'Checks that the NPE - 03 Opportunity Forecast Months are set in the');
    }

    /*********************************************************************************************************
    * @description verify the RD2 constants closeactions contains select options when RD2 is enabled
    * @return void
    */
    @isTest
    private static void shouldReturnEnhancedRDCloseActionsWhenRD2IsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<RD2_Constants.CloseActions> options = RD2_Constants.CloseActions.values();

        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        panel.init();

        System.assertEquals(options.size(), panel.listSORDCloseOptions.size(), 'Panel should return options');
        for (Integer i = 0; i < options.size(); i++) {
            System.assertEquals(options[i].name(), panel.listSORDCloseOptions[i].getValue(), 'Options should match');
        }
    }

    /*********************************************************************************************************
    * @description verify the Recurring Donations closeoptions contains the select options
    * for Legacy Recurring Donations
    * @return void
    */
    @isTest
    private static void shouldReturnLegacyRDCloseActionsWhenRD2IsNotEnabled() {
        List<RD_RecurringDonations.RecurringDonationCloseOptions> options = RD_RecurringDonations.RecurringDonationCloseOptions.values();

        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        panel.init();

        System.assertEquals(options.size(), panel.listSORDCloseOptions.size(), 'Panel should return options');
        for (Integer i = 0; i < options.size(); i++) {
            System.assertEquals(options[i].name(), panel.listSORDCloseOptions[i].getValue(), 'Options should match');
        }
    }

    /***
    * @description Every Installment Auto Creation Setting option should be converted into SelectOption
    */
    @isTest
    private static void shouldHaveValidSelectOptionsForInstallmentAutoCreationSetting() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        List<String> optionValues = new List<String>();

        Test.startTest();
        for (SelectOption option : panel.installmentCreateOptions) {
            optionValues.add(option.getValue());
        }
        Test.stopTest();

        List<String> options = new List<String>();

        for (RD2_Constants.InstallmentCreateOptions option : RD2_Constants.InstallmentCreateOptions.values()) {
            options.add(option.name());
        }

        System.assertEquals(options, optionValues,
            'Every Installment Creation Options should be in the list for selection');
    }
    /***
    * @description The label currently being displayed should match the actual Installment Opp Auto Creation Setting
    */
    @isTest
    private static void shouldHaveCorrectAutoCreationLabelDisplayed() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();

        Test.startTest();
        panel.init();
        Test.stopTest();

        String currentOppSettingLabel = panel.convertToInstallmentLabel(
            Stg_Panel.stgService.stgRD.InstallmentOppAutoCreateOption__c);

        System.assertEquals(currentOppSettingLabel, panel.selectedInstallmentCreateOption,
            'The installment opp displayed label should matches the one stored in the NPSP setting');
    }

    /***
    * @description The label currently being displayed should match the actual Installment Opp Auto Creation Setting
    */
    @isTest
    private static void shouldDisplayAlwaysCreateWhenSettingIsNullOrRandomString() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();

        Map<String, Object> rdSettingMap = new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => null
        };

        RD2_Settings_TEST.setUpConfiguration(rdSettingMap);

        Test.startTest();
        panel.init();
        Test.stopTest();

        System.assertEquals(System.Label.stgInstallmentOppEnableAll, panel.selectedInstallmentCreateOption,
            'The installment opp displayed label should be set to Always Create Next Installment When Setting value is not recognizable');
    }

    /**
    * @description Installment Auto Creation Settings - Always Allow Next Installment
    * should be correctly conoverted to the respected label when displayed onto the RD panel
    */
    @isTest
    private static void shouldConvertInstallmentOppAutoCreationAlwaysAllowToLabel() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();

        Test.startTest();
        String convertedLabel = panel.convertToInstallmentLabel(OPTION_NAME_ALWAYS_CREATE_NEXT);
        Test.stopTest();

        System.assertEquals(System.Label.stgInstallmentOppEnableAll, convertedLabel,
            'Installment Auto Creation Setting should be correctly converted to respected custom label');
    }

    /**
    * @description Installment Auto Creation Settings - Disalbe First Installment
    * should be correctly conoverted to the respected label when displayed onto the RD panel
    */
    @isTest
    private static void shouldConvertInstallmentOppAutoCreationDisableFirstToLabel() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();

        Test.startTest();
        String convertedLabel = panel.convertToInstallmentLabel(OPTION_NAME_DISABLE_FIRST);
        Test.stopTest();

        System.assertEquals(System.Label.stgInstallmentOppDisableFirst, convertedLabel,
            'Installment Auto Creation Setting should be correctly converted to respected custom label');
    }

    /**
    * @description Installment Auto Creation Settings - Disable All Installment
    * should be correctly conoverted to the respected label when displayed onto the RD panel
    */
    @isTest
    private static void shouldConvertInstallmentOppAutoCreationDisableAllToLabel() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();

        Test.startTest();
        String convertedLabel = panel.convertToInstallmentLabel(OPTION_NAME_DISABLE_ALL);
        Test.stopTest();

        System.assertEquals(System.Label.stgInstallmentOppDisableAll, convertedLabel,
            'Installment Auto Creation Setting should be correctly converted to respected custom label');
    }

    /***
    * @description Verifies that RD Naming Options include all options for selection 
    */
    @isTest
    private static void shouldHaveAllRDNamingFormatOptionsForSelection() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        Set<String> rdNamingApiValues = new Set<String>();

        Test.startTest();
        for (SelectOption option : panel.rdNamingOptions) {
            rdNamingApiValues.add(option.getValue());
        }
        Test.stopTest();

        List<String> expectedApiValues = new List<String> {
            '',
            RD2_NamingService.RD_NAMING_OPTION_1,
            RD2_NamingService.RD_NAMING_OPTION_2,
            RD2_NamingService.RD_NAMING_OPTION_3
        };

        for (String exptectedValue : expectedApiValues) {
            System.assert(rdNamingApiValues.contains(exptectedValue),
                exptectedValue + ' should be include as one of the rd naming option');
        }
    }

    /**
    * @description Verifies that when RD Auto Naming is off, Disable label should be displayed 
    */
    @isTest
    private static void shouldHaveCorrectRDNamingFormatBeingDisplayedWhenAutoNamingIsOff() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        STG_Panel.stgService.stgRD.EnableAutomaticNaming__c = false;

        Test.startTest();
        String displayedFormat = panel.displayedRDNamingFormat;
        String selectedFormat = panel.selectedRDNamingFormat;
        Test.stopTest();

        System.assertEquals(System.Label.stgRDNamingDisable, displayedFormat, 'RD naming Disable Label should be displayed. ' + displayedFormat);
        System.assertEquals('', selectedFormat, 'Correct api value should be selected. ' + selectedFormat);
    }

    /**
    * @desctiption Verifies that when RD setting has Option 1 as stored format, the label version should be displayed
    */
    @isTest
    private static void shouldHaveCorrectRDNamingFormatBeingDisplayedWhenRDSettingNameFormatOption1() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        STG_Panel.stgService.stgRD.EnableAutomaticNaming__c = true;
        STG_Panel.stgService.stgRD.RecurringDonationNameFormat__c = RD2_NamingService.RD_NAMING_OPTION_1;

        Test.startTest();
        String convertedLabel = panel.displayedRDNamingFormat;
        String selectedFormat = panel.selectedRDNamingFormat;
        Test.stopTest();

        String expectedLabel = RD2_NamingService.RD_NAMING_OPTION_1.replace('$RECURRING_NAME_SUFFIX$', System.Label.RecurringDonationNameSuffix);

        System.assertEquals(expectedLabel, convertedLabel, 'RD Naming format should be converted to Label');
        System.assertEquals(RD2_NamingService.RD_NAMING_OPTION_1, selectedFormat, 'Correct api value should be selected. ' + selectedFormat);
    }

    /**
    * @desctiption Verifies that when RD setting has Option 2 as stored format, the label version should be displayed
    */
    @isTest
    private static void shouldHaveCorrectRDNamingFormatBeingDisplayedWhenRDSettingNameFormatOption2() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        STG_Panel.stgService.stgRD.EnableAutomaticNaming__c = true;
        STG_Panel.stgService.stgRD.RecurringDonationNameFormat__c = RD2_NamingService.RD_NAMING_OPTION_2;

        Test.startTest();
        String convertedLabel = panel.displayedRDNamingFormat;
        String selectedFormat = panel.selectedRDNamingFormat;
        Test.stopTest();

        String expectedLabel =
            RD2_NamingService.RD_NAMING_OPTION_2.replace('$RECURRING_OBJECT_NAME$', UTIL_Describe.getObjectLabel('npe03__Recurring_Donation__c'));

        System.assertEquals(expectedLabel, convertedLabel, 'RD Naming format should be converted to Label');
        System.assertEquals(RD2_NamingService.RD_NAMING_OPTION_2, selectedFormat, 'Correct api value should be selected. ' + selectedFormat);
    }

    /**
    * @desctiption Verifies that when RD setting has Option 3 as stored format, the label version should be displayed
    */
    @isTest
    private static void shouldHaveCorrectRDNamingFormatBeingDisplayedWhenRDSettingNameFormatOption3() {
        STG_PanelRD_CTRL panel = new STG_PanelRD_CTRL();
        STG_Panel.stgService.stgRD.EnableAutomaticNaming__c = true;
        STG_Panel.stgService.stgRD.RecurringDonationNameFormat__c = RD2_NamingService.RD_NAMING_OPTION_3;

        Test.startTest();
        String convertedLabel = panel.displayedRDNamingFormat;
        String selectedFormat = panel.selectedRDNamingFormat;
        Test.stopTest();

        String expectedLabel = RD2_NamingService.RD_NAMING_OPTION_3;

        System.assertEquals(expectedLabel, convertedLabel, 'RD Naming format should be converted to Label');
        System.assertEquals(RD2_NamingService.RD_NAMING_OPTION_3, selectedFormat, 'Correct api value should be selected. ' + selectedFormat);
    }

    /**
    * @description Should prevent read only user to delete opportunity naming settings
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteOppNamingWhenUserDoesNotHaveDeletePermission() {
        Opportunity_Naming_Settings__c settings = setUpOppNamingSettings();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelOppNaming);
            STG_PanelOppNaming_CTRL panel = new STG_PanelOppNaming_CTRL();

            panel.currentONS = settings;
            panel.currentONSName = settings.Name;

            panel.delONS();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, panel.listOppNameSettings.size(), 'Checks that the number of opp name settings is equal to 1.');
            System.assertEquals(1, panel.mapOppNameSettings.size(), 'Checks that the size of the mapOppNameSettings is equal to 1.');
            System.assertEquals(1, Opportunity_Naming_Settings__c.getAll().size(), 'Assert that Opportunity_Naming_Settings is exactly 1.');
        }

        Test.stopTest();

    }

    /**
    * @description Verify if admin users can delete opportunity naming settings
    */
    @isTest
    private static void shouldAllowDeleteOppNamingWhenUserHasAdminPermission() {
        Opportunity_Naming_Settings__c settings = setUpOppNamingSettings();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelOppNaming);
        STG_PanelOppNaming_CTRL panel = new STG_PanelOppNaming_CTRL();

        panel.currentONS = settings;
        panel.currentONSName = settings.Name;

        panel.delONS();

        //verify if the settings are deleted
        System.assertEquals(0, Opportunity_Naming_Settings__c.getAll().size(), 'Assert that all Opportunity_Naming_Settings are set.');
        System.assertEquals(0, panel.listOppNameSettings.size(), 'Checks that the number of opp name settings is the same as the number of opp');

        Test.stopTest();
    }

    /**
    * @description Should prevent read only user to delete custom field mapping setting
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteForFieldMappingWhenUserDoesNotHaveDelPermission() {
        npe03__Custom_Field_Mapping__c cfm = setUpCustomFieldMapping();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelRDCustomFieldMapping);
            STG_PanelRDCustomFieldMapping_CTRL panel = new STG_PanelRDCustomFieldMapping_CTRL();

            panel.fmNew.npe03__Recurring_Donation_Field__c = cfm.npe03__Recurring_Donation_Field__c;
            panel.fmNew.npe03__Opportunity_Field__c = cfm.npe03__Opportunity_Field__c;

            panel.fmIdDelete = panel.listRDCustomFieldMapping[0].Id;
            panel.deleteFm();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, npe03__Custom_Field_Mapping__c.getAll().size(), 'This test asserts that the size of the mapping table is equal to 1.');
            System.assertEquals(1, panel.listRDCustomFieldMapping.size(), 'This method asserts that the size of the panel is equal to the number of custom fields in');
        }

        Test.stopTest();
    }

    /**
    * @description Verify if admin users can delete custom field mapping settings
    */
    @isTest
    private static void shouldAllowDeleteForFieldMappingWhenUserHasAdminPermission() {
        npe03__Custom_Field_Mapping__c cfm = setUpCustomFieldMapping();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelRDCustomFieldMapping);
        STG_PanelRDCustomFieldMapping_CTRL panel = new STG_PanelRDCustomFieldMapping_CTRL();

        panel.fmNew.npe03__Recurring_Donation_Field__c = cfm.npe03__Recurring_Donation_Field__c;
        panel.fmNew.npe03__Opportunity_Field__c = cfm.npe03__Opportunity_Field__c;
        panel.fmIdDelete = panel.listRDCustomFieldMapping[0].Id;
        panel.deleteFm();

        //verify if the settings are deleted
        System.assertEquals(0, npe03__Custom_Field_Mapping__c.getAll().size(), 'This test asserts that all mappings are initialized.');
        system.assertEquals(0, panel.listRDCustomFieldMapping.size(), 'Checks that the size of the list of custom field mappings is the same as the size of');

        Test.stopTest();

    }

    /**
    * @description Should prevent read only user to delete custom installment setting
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteForCustomInstallmtWhenUserDoesNotHaveDelPermission() {
        npe03__Custom_Installment_Settings__c cfm = setUpCustomInstallmentSettings();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelRDCustomInstallment);
            STG_PanelRDCustomInstallment_CTRL panel = new STG_PanelRDCustomInstallment_CTRL();

            panel.ciNew.Name = cfm.Name;
            panel.ciNew.npe03__Value__c = cfm.npe03__Value__c;
            panel.ciNew.npe03__Increment__c = cfm.npe03__Increment__c;

            panel.ciIdDelete = STG_Panel.stgService.listRDCustomInstallment[0].Id;
            panel.deleteCi();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, npe03__Custom_Installment_Settings__c.getAll().size(), 'Checks that all the installed NPE03 s settings are available.');
            System.assertEquals(1, STG_Panel.stgService.listRDCustomInstallment.size(), 'This method is used to check that the size of STG_Panel. stgService');
        }

        Test.stopTest();
    }

    /**
    * @description Verify if admin users can delete custom installment settings
    */
    @isTest
    private static void shouldAllowDeleteForCustomInstallmtWhenUserHasAdminPermission() {
        npe03__Custom_Installment_Settings__c cfm = setUpCustomInstallmentSettings();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelRDCustomInstallment);
        STG_PanelRDCustomInstallment_CTRL panel = new STG_PanelRDCustomInstallment_CTRL();

        panel.ciNew.Name = cfm.Name;
        panel.ciNew.npe03__Value__c = cfm.npe03__Value__c;
        panel.ciNew.npe03__Increment__c = cfm.npe03__Increment__c;

        panel.ciIdDelete = STG_Panel.stgService.listRDCustomInstallment[0].Id;
        panel.deleteCi();

        //verify if the settings are deleted
        System.assertEquals(0, npe03__Custom_Installment_Settings__c.getAll().size(), 'Checks that all the custom installment settings are available.');
        system.assertEquals(0, STG_Panel.stgService.listRDCustomInstallment.size(), 'Checks that the number of STG_Panel. stgService. listRDCustomInstall');

        Test.stopTest();

    }

    /**
    * @description Should prevent read only user to delete payment field mapping setting
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteForPaymentMapWhenUserDoesNotHaveDelPermission() {
        npe01__Payment_Field_Mapping_Settings__c cfm = setUpPaymentFieldMapSettings();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelPaymentMapping);
            STG_PanelPaymentMapping_CTRL panel = new STG_PanelPaymentMapping_CTRL();

            panel.pfmNew.npe01__Opportunity_Field__c = cfm.npe01__Opportunity_Field__c;
            panel.pfmNew.npe01__Payment_Field__c = cfm.npe01__Payment_Field__c;

            panel.pfmIdDelete = panel.listPMTFieldMapping[0].Id;
            panel.deletePfm();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, npe01__Payment_Field_Mapping_Settings__c.getAll().size(), 'This function asserts that the number of payment field mapping settings is equal to 1.' );
            System.assertEquals(1, STG_Panel.stgService.listPMTFieldMapping.size(), 'This method is used to check that the number of mappings in the STG panel is equal');
        }

        Test.stopTest();
    }

    /**
    * @description Verify if admin users can delete payment field mapping settings
    */
    @isTest
    private static void shouldAllowDeleteForPaymentMapWhenUserHasAdminPermission() {
        npe01__Payment_Field_Mapping_Settings__c cfm = setUpPaymentFieldMapSettings();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelPaymentMapping);
        STG_PanelPaymentMapping_CTRL panel = new STG_PanelPaymentMapping_CTRL();

        panel.pfmNew.npe01__Opportunity_Field__c = cfm.npe01__Opportunity_Field__c;
        panel.pfmNew.npe01__Payment_Field__c = cfm.npe01__Payment_Field__c;

        panel.pfmIdDelete = panel.listPMTFieldMapping[0].Id;
        panel.deletePfm();
        //verify if the settings are deleted
        System.assertEquals(0, npe01__Payment_Field_Mapping_Settings__c.getAll().size(), 'This function asserts that all PaymentField_Mapping_Settings are set.');
        System.assertEquals(0, panel.listPMTFieldMapping.size(), 'Checks that the size of the panel listPMTFieldMapping is equal to the number of');

        Test.stopTest();

    }

    /**
    * @description Should prevent read only user to delete relationship lookup setting
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteForRelReciprocalWhenUserDoesNotHaveDelPermission() {
        npe4__Relationship_Lookup__c cfm = setUpRelationshipLookup();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelRelReciprocal);
            STG_PanelRelReciprocal_CTRL panel = new STG_PanelRelReciprocal_CTRL();

            panel.rlNew.Name = cfm.Name;
            panel.rlNew.npe4__Male__c = cfm.npe4__Male__c;
            panel.rlNew.npe4__Female__c = cfm.npe4__Female__c;
            panel.rlNew.npe4__Neutral__c = cfm.npe4__Neutral__c;

            panel.rlIdDelete = panel.listRelLookup[0].Id;
            panel.deleteRl();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, npe4__Relationship_Lookup__c.getAll().size(), 'Checks that the size of the relationship table is equal to 1.');
            System.assertEquals(1, panel.listRelLookup.size(), 'Checks that the size of the panel list is equal to 1.');
        }

        Test.stopTest();
    }

    /**
    * @description Verify if admin users can delete relationship lookup settings
    */
    @isTest
    private static void shouldAllowDeleteForRelReciprocalWhenUserHasAdminPermission() {
        npe4__Relationship_Lookup__c cfm = setUpRelationshipLookup();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelRelReciprocal);
        STG_PanelRelReciprocal_CTRL panel = new STG_PanelRelReciprocal_CTRL();

        panel.rlNew.Name = cfm.Name;
        panel.rlNew.npe4__Male__c = cfm.npe4__Male__c;
        panel.rlNew.npe4__Female__c = cfm.npe4__Female__c;
        panel.rlNew.npe4__Neutral__c = cfm.npe4__Neutral__c;

        panel.rlIdDelete = panel.listRelLookup[0].Id;
        panel.deleteRl();

        System.assertEquals(0, npe4__Relationship_Lookup__c.getAll().size(), 'Checks that all relationships are available.');
        System.assertEquals(0, panel.listRelLookup.size(), 'Checks that the panel list is empty.');

        Test.stopTest();
    }

    /**
    * @description Should prevent read only user to delete relationship autocreate setting
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteForRelAutoWhenUserDoesNotHaveDelPermission() {
        npe4__Relationship_Auto_Create__c cfm = setUpRelationshipAutoCreate();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelRelAuto);
            STG_PanelRelAuto_CTRL panel = new STG_PanelRelAuto_CTRL();

            panel.acNew.npe4__Object__c = cfm.npe4__Object__c;
            panel.acNew.npe4__Field__c = cfm.npe4__Field__c;
            panel.acNew.npe4__Relationship_Type__c = cfm.npe4__Relationship_Type__c;


            panel.acIdDelete = panel.listRelAutoCreate[0].Id;
            panel.deleteAc();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, npe4__Relationship_Auto_Create__c.getAll().size(), 'Assert that all relationships are initialized.');
            System.assertEquals(1, panel.listRelAutoCreate.size(), 'Checks that the number of auto - create panels is equal to one.');
        }

        Test.stopTest();
    }

    /**
    * @description Verifies that the user cannot update Error Settings without update permission 
    */
    @isTest
    private static void shouldPreventUpdateErrorSettingsWhenUserDoesNotHaveUpdatePermission() {
        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelHealthCheck);
            STG_PanelHealthCheck_CTRL panel = new STG_PanelHealthCheck_CTRL();

            STG_Panel.stgService.stgErr.DisableRecordDataHealthChecks__c = true;
            panel.saveSettings();

            UTIL_UnitTestData_TEST.assertPageHasError(Schema.SObjectType.Error_Settings__c.getLabel());
        }

        Test.stopTest();
    }

    /**
    * @description Verify if admin users can delete relationship auto create settings
    */
    @isTest
    private static void shouldAllowDeleteForRelAutoWhenUserHasAdminPermission() {
        npe4__Relationship_Auto_Create__c cfm = setUpRelationshipAutoCreate();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelRelAuto);
        STG_PanelRelAuto_CTRL panel = new STG_PanelRelAuto_CTRL();

        panel.acNew.npe4__Object__c = cfm.npe4__Object__c;
        panel.acNew.npe4__Field__c = cfm.npe4__Field__c;
        panel.acNew.npe4__Relationship_Type__c = cfm.npe4__Relationship_Type__c;


        panel.acIdDelete = panel.listRelAutoCreate[0].Id;
        panel.deleteAc();

        System.assertEquals(0, npe4__Relationship_Auto_Create__c.getAll().size(), 'Asserts that all relationships are initialized.');
        System.assertEquals(0, panel.listRelAutoCreate.size(), 'Checks that the number of auto - create panels is the same.');

        Test.stopTest();
    }

    /**
    * @description Should prevent read only user to delete user roll up field setting
    * as they do not have delete permission
    */
    @isTest
    private static void shouldPreventDeleteForUserRollupWhenUserDoesNotHaveDelPermission() {
        npo02__User_Rollup_Field_Settings__c HHurfs = setUpUserRollupFieldSettings();

        Test.startTest();

        System.runAs(createReadOnlyUser()) {
            Test.setCurrentPage(Page.STG_PanelUserRollup);
            STG_PanelUserRollup_CTRL panel = new STG_PanelUserRollup_CTRL();
            panel.startBuild();

            panel.activeUDR.SourceField = HHurfs.npo02__Source_Field__c;
            panel.activeUDR.Operation = HHurfs.npo02__Field_Action__c;
            panel.activeUDR.TargetObject = HHurfs.npo02__Object_Name__c;
            panel.activeUDR.TargetField = HHurfs.npo02__Target_Field__c;

            panel.activeUDR = panel.udrlist[0];
            panel.activeUDR.deleteMe();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.stgDeletePermissionError);
            System.assertEquals(1, npo02__User_Rollup_Field_Settings__c.getAll().size(), 'This function asserts that the number of rollup fields is equal to 1.');
            System.assertEquals(1, panel.udrlist.size(), 'Assert that the size of the UDR list is equal to 1.');
        }

        Test.stopTest();
    }

    /**
    * @description Verify if admin users can delete user rollup field settings
    */
    @isTest
    private static void shouldAllowDeleteForUserRollupWhenUserHasAdminPermission() {
        npo02__User_Rollup_Field_Settings__c HHurfs = setUpUserRollupFieldSettings();

        Test.startTest();

        Test.setCurrentPage(Page.STG_PanelUserRollup);
        STG_PanelUserRollup_CTRL panel = new STG_PanelUserRollup_CTRL();

        panel.startBuild();

        panel.activeUDR.SourceField = HHurfs.npo02__Source_Field__c;
        panel.activeUDR.Operation = HHurfs.npo02__Field_Action__c;
        panel.activeUDR.TargetObject = HHurfs.npo02__Object_Name__c;
        panel.activeUDR.TargetField = HHurfs.npo02__Target_Field__c;

        panel.activeUDR = panel.udrlist[0];
        panel.activeUDR.deleteMe();
        panel.udrList = null;
        UTIL_ListCustomSettingsFacade.mapUserRollupFieldSettings = null;

        System.assertEquals(0, npo02__User_Rollup_Field_Settings__c.getAll().size(), 'This function asserts that the number of Rollup Field Settings is equal to the number of Roll');
        System.assertEquals(0, panel.udrlist.size(), 'Assert that the size of the panel is equal to the number of UDRs currently displayed');

        Test.stopTest();
    }

    /**
    * @description Verifies that the api value of the picklist will be converted into corresponding label
    */
    @isTest
    private static void shouldConvertPicklistApiValueIntoLabelValue() {
        System.runAs(UTIL_UnitTestData_TEST.createNonEnglishUserWithoutInsert(UTIL_UnitTestData_TEST.PROFILE_STANDARD_USER)) {
            Schema.DescribeFieldResult fieldResult = UTIL_Describe.getFieldDescribe('OpportunityContactRole', 'Role');
            String label = fieldResult.getPicklistValues()[0].getLabel();
            String apiValue = fieldResult.getPicklistValues()[0].getValue();

            Test.startTest();
            String convertedLabel = STG_Panel.getPicklistLabelFromValue('OpportunityContactRole', 'Role', apiValue);
            Test.stopTest();

            System.assertEquals(label, convertedLabel, 'The api value should be correctly converted into the corressponding label');
        }
    }

    /*********************************************************************************************************
    * @description Tests the Run RD Batch panel
    * @return void
    */
    @isTest
    private static void testPanelRDBatch() {
        STG_PanelRDBatch_CTRL panel = new STG_PanelRDBatch_CTRL();
        system.assertEquals('idPanelRDBatch', panel.idPanel(), 'Checks that the panel is the correct panel in the rDBatch.');
        system.assertEquals(false, panel.isRunningBatch, 'Asserts that the panel is running batch.');
        panel.runBatch();
        system.assertEquals(true, panel.isRunningBatch, 'Checks that the panel is running batch.');
    }

    /*********************************************************************************************************
    * @description Tests the RD Custom Field Mapping panel
    * @return void
    */
    @isTest
    private static void testPanelRDCustomFieldMapping() {
        STG_PanelRDCustomFieldMapping_CTRL panel = new STG_PanelRDCustomFieldMapping_CTRL();
        system.assertEquals('idPanelRDFieldMap', panel.idPanel(), 'Assert that idPanelRDFieldMap is the same as panel.');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        system.assertNotEquals(null, STG_PanelRDCustomFieldMapping_CTRL.listSORDFields, 'This function asserts that the STG_PanelRDCustomFieldMapping_CTRL. list');
        system.assertNotEquals(null, STG_PanelRDCustomFieldMapping_CTRL.listSOOppFields, 'This function asserts that the list of custom fields in STG_PanelRDCustomFieldMapping');
        system.assertEquals(null, panel.newCustomFieldMapping(), 'Asserts that the panel has a custom field mapping.');
        system.assertNotEquals(null, panel.fmNew, 'Assert that panel. fmNew is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertEquals(null, panel.cancelCustomFieldMapping(), 'Asserts that cancelCustomFieldMapping is called on the same panel.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertEquals(null, panel.newCustomFieldMapping(), 'Asserts that the panel has a custom field mapping.');
        system.assertNotEquals(null, panel.fmNew, 'Assert that panel. fmNew is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.fmNew.npe03__Recurring_Donation_Field__c = null;
        panel.fmNew.npe03__Opportunity_Field__c = null;
        system.assertEquals(null, panel.createCustomFieldMapping(), 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.fmNew.npe03__Opportunity_Field__c = 'Amount';
        panel.fmNew.npe03__Recurring_Donation_Field__c = 'npe03__Amount__c';
        system.assertEquals(null, panel.createCustomFieldMapping(), 'Assert that the panel is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.listRDCustomFieldMapping, 'Assert that the panel. listRDCustomFieldMapping is not null.');
        system.assertEquals(1, panel.listRDCustomFieldMapping.size(), 'Checks that the size of the list of custom field mappings is equal to 1.');
        panel.fmIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteFm(), 'Asserts that the deleteFm property of the panel is not null.');
        panel.fmIdDelete = panel.listRDCustomFieldMapping[0].Id;
        system.assertEquals(null, panel.deleteFm(), 'Asserts that the deleteFm property of the panel is not null.');
        system.assertNotEquals(null, panel.listRDCustomFieldMapping, 'Assert that the panel. listRDCustomFieldMapping is not null.');
        system.assertEquals(0, panel.listRDCustomFieldMapping.size(), 'Checks that the size of the list of custom field mappings is the same as the size of');
    }

    /*********************************************************************************************************
    * @description Tests the RD Custom Installments panel
    * @return void
    */
    @isTest
    private static void testPanelRDCustomInstallment() {
        STG_PanelRDCustomInstallment_CTRL panel = new STG_PanelRDCustomInstallment_CTRL();
        system.assertEquals('idPanelRDInstPd', panel.idPanel(), 'Assert that idPanelRDInstPd is the same as panel.');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        system.assertNotEquals(null, STG_PanelRDCustomInstallment_CTRL.listSORDCustomPeriod, 'Checks that the list of SORD custom installments is not null.');
        system.assertEquals(null, panel.newCustomInstallment(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.ciNew, 'Assert that panel. ciNew is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertEquals(null, panel.cancelCustomInstallment(), 'Checks that cancel custom installment is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertEquals(null, panel.newCustomInstallment(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.ciNew, 'Assert that panel. ciNew is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.ciNew.Name = null;
        panel.ciNew.npe03__Value__c = null;
        panel.ciNew.npe03__Increment__c = null;
        system.assertEquals(null, panel.createCustomInstallment(), 'Checks that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.ciNew.Name = 'TestInstallment';
        panel.ciNew.npe03__Value__c = 10;
        panel.ciNew.npe03__Increment__c = 'Days';
        system.assertEquals(null, panel.createCustomInstallment(), 'Checks that the panel is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, STG_Panel.stgService.listRDCustomInstallment, 'This method asserts that STG_Panel. stgService. listRDCustomInstallment');
        system.assertEquals(1, STG_Panel.stgService.listRDCustomInstallment.size(), 'Checks that the number of STG_Panel. stgService. listRDCustomInstall');
        //system.assertEquals(null, panel.getSettingsFirstTime());
        panel.ciIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteCi(), 'Asserts that the deleteCi method is called.');
        panel.ciIdDelete = STG_Panel.stgService.listRDCustomInstallment[0].Id;
        system.assertEquals(null, panel.deleteCi(), 'Asserts that the deleteCi method is called.');
        system.assertNotEquals(null, STG_Panel.stgService.listRDCustomInstallment, 'This method asserts that STG_Panel. stgService. listRDCustomInstallment');
        system.assertEquals(0, STG_Panel.stgService.listRDCustomInstallment.size(), 'Checks that the number of STG_Panel. stgService. listRDCustomInstall');
    }

    /*********************************************************************************************************
    * @description Tests the Relationships panel
    * @return void
    */
    @isTest
    private static void testPanelRel() {
        STG_PanelRel_CTRL panel = new STG_PanelRel_CTRL();
        system.assertEquals('idPanelRel', panel.idPanel(), 'Asserts that the panel is the same as the panel rel.');
        STG_Panel.stgService.stgRel.npe4__Allow_AutoCreated_Duplicates__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgRelationshipSettings().npe4__Allow_AutoCreated_Duplicates__c, 'asserts that the NPE4 settings are set correctly');
        STG_Panel.stgService.stgRel.npe4__Allow_AutoCreated_Duplicates__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgRelationshipSettings().npe4__Allow_AutoCreated_Duplicates__c, 'asserts that the NPE4 settings are not set.');

        STG_Panel.stgService.stgRel.Enable_Custom_Field_Sync__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgRelationshipSettings().Enable_Custom_Field_Sync__c, 'asserts that Enable_Custom_Field_Sync is true for the current organization');
        STG_Panel.stgService.stgRel.Enable_Custom_Field_Sync__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgRelationshipSettings().Enable_Custom_Field_Sync__c, 'asserts that Enable_Custom_Field_Sync is false');

        STG_Panel.stgService.stgRel.npe4__Gender_Field__c = 'description';
        panel.saveSettings();
        system.assertEquals(UTIL_Describe.getFieldLabel('Contact','description'),panel.strGenderFieldLabel,'Gender label doesn\'t match.');

        // no settings to start
        system.assertEquals(0,panel.listExcludedFields.size(), 'Checks that there are no fields in the panel.');
        system.assertEquals('',panel.excludedLabels,'Excluded Labels is not blank.');
        // add a value to listExcludedFields and confirm that correct setting was added
        panel.listExcludedFields = new List<String>{'npe4__description__c'};
        panel.saveSettings();
        system.assertEquals(1,UTIL_ListCustomSettingsFacade.getMapRelationshipFieldSyncSettings().size(), 'asserts that 1 map relationship field sync settings is set');
        system.assertEquals(UTIL_Describe.getFieldLabel('npe4__Relationship__c','npe4__description__c'),panel.excludedLabels.trim(), 'assert that the label of the relationship and the description of the panel are not excluded');

        // cause deletion of that setting record by setting empty string, confirm results
        panel.listExcludedFields = new List<String>();
        panel.saveSettings();
        system.assertEquals(0,UTIL_ListCustomSettingsFacade.getMapRelationshipFieldSyncSettings().size(),'Exclusion field map not empty.');

        // these SelectOption lists will always have at least the ---None--- entry
        system.assertNotEquals(null, panel.listSOGenderFieldOptions,'listSOGenderFieldOptions is not null.');
        system.assertNotEquals(null,panel.listSOSyncFieldOptions,'listSOSyncFieldOptions is not null.');

    }

    /*********************************************************************************************************
    * @description Tests the Automatic Relationships panel
    * @return void
    */
    @isTest
    private static void testPanelRelAuto() {
        STG_PanelRelAuto_CTRL panel = new STG_PanelRelAuto_CTRL();
        system.assertEquals('idPanelRelAuto', panel.idPanel(), 'Assert that the panel is the same as the panel relAuto.');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        system.assertEquals(null, panel.newRelAutoCreate(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.acNew, 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertEquals(null, panel.cancelRelAutoCreate(), 'Assert that cancelRelAutoCreate is called.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertEquals(null, panel.newRelAutoCreate(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.acNew, 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.acNew.npe4__Object__c = null;
        panel.acNew.npe4__Field__c = null;
        panel.acNew.npe4__Relationship_Type__c = null;
        panel.acNew.npe4__Campaign_Types__c = null;
        system.assertEquals(null, panel.createRelAutoCreate(), 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.acNew.npe4__Object__c = 'Contact';
        panel.acNew.npe4__Field__c = 'ReportsToId';
        panel.acNew.npe4__Relationship_Type__c = 'coworker';
        panel.acNew.npe4__Campaign_Types__c = null;
        system.assertEquals(null, panel.createRelAutoCreate(), 'Assert that the panel is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.listRelAutoCreate, 'Assert that the panel s listRelAutoCreate property is not null.');
        system.assertEquals(1, panel.listRelAutoCreate.size(), 'Checks that the number of auto - create panels is equal to 1.');
        panel.acIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteAc(), 'Delete the Ac dialog.');
        panel.acIdDelete = panel.listRelAutoCreate[0].Id;
        system.assertEquals(null, panel.deleteAc(), 'Delete the Ac dialog.');
        system.assertNotEquals(null, panel.listRelAutoCreate, 'Assert that the panel s listRelAutoCreate property is not null.');
        system.assertEquals(0, panel.listRelAutoCreate.size(), 'Assert that the number of auto - create panels is the same.');
        panel.acNew.npe4__Object__c = 'Contact';
        system.assertNotEquals(null, panel.listSOACfield, 'Assert that the panel is not null.');
        panel.acNew.npe4__Object__c = 'CampaignMember';
        system.assertNotEquals(null, panel.listSOACfield, 'Assert that the panel is not null.');
    }

    /*********************************************************************************************************
    * @description Tests the Reciprocal Relationships panel
    * @return void
    */
    @isTest
    private static void testPanelRelReciprocal() {
        STG_PanelRelReciprocal_CTRL panel = new STG_PanelRelReciprocal_CTRL();
        system.assertEquals('idPanelRelReciprocal', panel.idPanel(), 'Checks that the panel is the same as the panel relreciprocal panel.');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        system.assertEquals(null, panel.newRelLookup(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.rlNew, 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertEquals(null, panel.cancelRelLookup(), 'Assert that cancelRelLookup is called.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertEquals(null, panel.newRelLookup(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.rlNew, 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.rlNew.Name = null;
        panel.rlNew.npe4__Male__c = null;
        panel.rlNew.npe4__Female__c = null;
        panel.rlNew.npe4__Neutral__c = null;
        system.assertEquals(null, panel.createRelLookup(), 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.rlNew.Name = 'foo';
        panel.rlNew.npe4__Male__c = 'bar';
        panel.rlNew.npe4__Female__c = 'baz';
        panel.rlNew.npe4__Neutral__c = 'buz';
        system.assertEquals(null, panel.createRelLookup(), 'Assert that the panel is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.listRelLookup, 'Assert that the panel is not null.');
        system.assertEquals(1, panel.listRelLookup.size(), 'Checks that the number of panels is equal to 1.');
        panel.rlIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteRl(), 'Asserts that the delete panel is not null.');
        panel.rlIdDelete = panel.listRelLookup[0].Id;
        system.assertEquals(null, panel.deleteRl(), 'Asserts that the delete panel is not null.');
        system.assertNotEquals(null, panel.listRelLookup, 'Assert that the panel is not null.');
        system.assertEquals(0, panel.listRelLookup.size(), 'Assert that the panel list is empty.');
    }

    /*********************************************************************************************************
    * @description Tests the User Defined Rollups panel
    * @return void
    */
    @isTest
    private static void testPanelUserRollup() {
        STG_PanelUserRollup_CTRL panel = new STG_PanelUserRollup_CTRL();
        system.assertEquals('idPanelUserRollup', panel.idPanel(), 'Checks that the idPanelUserRollup is the same as the panel idPanel');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        panel.startBuild();
        system.assertNotEquals(null, panel.activeUDR, 'Assert that the UDR is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertNotEquals(null, panel.getSourceFields(), 'Assert that the source fields of the panel are not null.');
        system.assertNotEquals(null, panel.getTargetFields(), 'Assert that the target fields are not null.');
        system.assertNotEquals(null, panel.getTargetObjects(), 'Assert that the target objects of the panel are not null.');
        system.assertNotEquals(null, panel.getValidOperators(), 'Assert that all operators are not null.');
        panel.clearForSourceField();
        panel.clearForOperation();
        panel.clearForTargetObject();
        panel.cancel();
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        panel.startBuild();
        system.assertNotEquals(null, panel.activeUDR, 'Assert that the UDR is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.activeUDR.SourceField = null;
        panel.activeUDR.Operation = null;
        panel.activeUDR.TargetObject = null;
        panel.activeUDR.TargetField = null;
        system.assertEquals(false, panel.activeUDR.getisValid(), 'Checks that the UDR is valid.');
        panel.activeUDR.save();
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.activeUDR.SourceField = 'Amount';
        panel.activeUDR.Operation = 'SUM';
        panel.activeUDR.TargetObject = 'Contact';
        panel.activeUDR.TargetField = 'Description';
        system.assertEquals(true, panel.activeUDR.getisValid(), 'Checks that the UDR is valid.');
        system.assertNotEquals(null, panel.getSourceFields(), 'Assert that the source fields of the panel are not null.');
        system.assertNotEquals(null, panel.getTargetFields(), 'Assert that the target fields are not null.');
        system.assertNotEquals(null, panel.getTargetObjects(), 'Assert that the target objects of the panel are not null.');
        system.assertNotEquals(null, panel.getValidOperators(), 'Assert that all operators are not null.');
        system.assertNotEquals(null, panel.udrList, 'Assert that the panel is not null.');
        panel.activeUDR.TargetObject = 'Account';
        system.assertNotEquals(null, panel.getTargetFields(), 'Assert that the target fields are not null.');
        panel.activeUDR.TargetObject = 'npo02__Household__c';
        system.assertNotEquals(null, panel.getTargetFields(), 'Assert that the target fields are not null.');
        panel.activeUDR.TargetObject = 'Contact';
        panel.activeUDR.save();
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.udrlist, 'Assert that the panel is not null.');
        panel.udrList = null;
        UTIL_ListCustomSettingsFacade.mapUserRollupFieldSettings = null;
        system.assertEquals(1, panel.udrlist.size(), 'Assert that the number of UDRs in the panel is equal to 1.');
        panel.startBuild();
        system.assertNotEquals(null, panel.getTargetFields(), 'Assert that the target fields are not null.');
        panel.activeUDR = panel.udrlist[0];
        panel.activeUDR.deleteMe();
        panel.udrList = null;
        UTIL_ListCustomSettingsFacade.mapUserRollupFieldSettings = null;
        system.assertNotEquals(null, panel.udrlist, 'Assert that the panel is not null.');
        system.assertEquals(0, panel.udrlist.size(), 'Assert that the size of the UDR list is the same as the number of UDR');

    }

    /*********************************************************************************************************
    * @description Tests the User Rollup Settings panel
    * @return void
    */
    @isTest
    private static void TEST_userRollupSettings() {
        Test.setCurrentPageReference(new PageReference('Page.STG_SettingsManager'));

        //pass the controller into the extension
        STG_PanelUserRollup_CTRL controller = new STG_PanelUserRollup_CTRL();

        //kickoff a new rollup
        controller.startBuild();

        //call the major getter methods
        list<SelectOption> oppyList = controller.getSourceFields();
        controller.activeUDR.SourceField = 'Amount';

        list<SelectOption> operatorList = controller.getValidOperators();
        system.assert(operatorList.size() == 4, 'This function asserts that there are exactly 4 operators in the operator list.');

        controller.activeUDR.SourceField = 'CloseDate';
        operatorList = controller.getValidOperators();
        system.assert(operatorList.size() == 2, 'This function asserts that there is only one operator in the list.');

        controller.activeUDR.Operation = 'MAX';

        list<SelectOption> targetObjectList = controller.getTargetObjects();
        system.assertEquals(targetObjectList.size(), 3, 'Checks that the number of objects in the target object list equals 3.');

        controller.activeUDR.TargetObject = 'Account';

        list<SelectOption> targetFieldList = controller.getTargetFields();

        //change target object to test other options
        controller.activeUDR.TargetObject = 'npo02__Household__c';
        targetFieldList = controller.getTargetFields();

        controller.activeUDR.TargetObject = 'Contact';
        targetFieldList = controller.getTargetFields();
        controller.activeUDR.TargetField = 'Birthdate';
        STG_PanelUserRollup_CTRL.UDR udr = controller.activeUDR;
        controller.activeUDR.save();
        //load a UDR
        udr.loadMe();

        //run through the loop with a newly inserted UDR
        targetFieldList = controller.getTargetFields();

        //blank out settings so they are queried again
        controller.udrList = null;
        UTIL_ListCustomSettingsFacade.mapUserRollupFieldSettings = null;

        //existing invalid rollups will cause test failure
        system.assertEquals(controller.activeUDR.getisValid(), true, 'Checks that the active UDR is valid.');
        list<STG_PanelUserRollup_CTRL.UDR> udrlist = controller.udrList;
        system.assert(udrList.size() > 0, 'asserts that there is no ucr list');

        //test clearing the three different lists
        controller.clearForTargetObject();
        system.assert(controller.activeUDR.TargetField == null, 'This method is called when the controller is not active.');
        controller.clearForOperation();
        system.assert(controller.activeUDR.TargetObject != null, 'This method is called by the UI thread when the active UDR is active.');
        controller.clearForSourceField();
        system.assert(controller.activeUDR.Operation == null, 'This method is called by the controller when it is not active.');

        controller.cancel();
        system.assertEquals(null, controller.activeUDR, 'Assert that the UDR is active.');

        //generate a new one so we can call its delete sequence
        controller.startBuild();
        //delete it
        controller.activeUDR.deleteMe();

        //call the other UDR contructor
        STG_PanelUserRollup_CTRL.UDR u = new STG_PanelUserRollup_CTRL.UDR('', '', '', '', controller);

        //insert invalid rollup to test error handling methods
        npo02__User_Rollup_Field_Settings__c badurfs = new npo02__User_Rollup_Field_Settings__c(
        Name = 'Invalid Test Rollup',
        npo02__Target_Field__c = 'InvalidTargetField__test',
        npo02__Source_Field__c = 'InvalidSourceField__test',
        npo02__Object_Name__c = 'Account',
        npo02__Field_Action__c = 'TEST'
        );
        insert badurfs;

        //exercise household code
        npo02__User_Rollup_Field_Settings__c HHurfs = new npo02__User_Rollup_Field_Settings__c(
        Name = 'Household Test Rollup',
        npo02__Target_Field__c = 'lastoppamount__c',
        npo02__Source_Field__c = 'Amount',
        npo02__Object_Name__c = 'npo02__Household__c',
        npo02__Field_Action__c = 'MAX'
        );
        insert HHurfs;

        npo02__User_Rollup_Field_Settings__c badobject = new npo02__User_Rollup_Field_Settings__c(
        Name = 'Invalid Object Rollup',
        npo02__Target_Field__c = 'InvalidTargetField__test',
        npo02__Source_Field__c = 'InvalidSourceField__test',
        npo02__Object_Name__c = 'BadAccount',
        npo02__Field_Action__c = 'TEST'
        );
        insert badobject;
    }

    /*********************************************************************************************************
    * @description Tests the Customizable Rollups CRLP panel
    * @return void
    */
    @isTest
    private static void testPanelCRLP() {
        STG_PanelCustomizableRollup_CTRL panel = new STG_PanelCustomizableRollup_CTRL();
        System.assertEquals('idPanelCustomizableRollup', panel.idPanel(), 'Checks that the idPanelCustomizableRollup property of the underlying Panel is equal to the');
        System.assertEquals(true, panel.isRunningUserIsAdmin, 'Checks if the current user is an admin.');
        System.assertEquals(false, panel.isPolling, 'Checks if the panel is polling.');
        System.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        System.assert(panel.showCRLPSettings, 'Checks if CRLP settings are displayed.');
        System.assert(panel.isRunningUserIsAdmin, 'Checks if the current user is an admin.');
        System.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');

        // Clear cache so test passes in orgs that have rollups
        CRLP_Rollup_SEL.cachedRollups = new List<Rollup__mdt>();
        panel.enableCRLPs();
        System.assertNotEquals(null, panel.jobId, 'JobId should not be null');
        System.assertEquals(true, panel.isPolling, 'Polling should be active.');
        //fake the success result.
        UTIL_CustomSettingsFacade.getCustomizableRollupSettings().CMT_API_Status__c = '123 Succeeded';
        PageReference deploymentPR = panel.checkDeploymentStatus();
        System.assertEquals(null, deploymentPR, 'Returned PageReference should be null');
        System.assertEquals(false, panel.isPolling, 'Polling should not be active.');

        panel.resetRollupsToDefaultConfig();
        System.assertEquals(true, panel.isPolling, 'Polling should be active.');
        //fake the success result.
        UTIL_CustomSettingsFacade.getCustomizableRollupSettings().CMT_API_Status__c = '123 Succeeded';
        deploymentPR = panel.checkDeploymentStatus();
        System.assertEquals(null, deploymentPR, 'Returned PageReference should be null');
        System.assertEquals(false, panel.isPolling, 'Polling should not be active.');

        panel.disableCRLPs();
        System.assertEquals(false, panel.isPolling, 'Polling should not be active.');
        //fake the fail result.
        UTIL_CustomSettingsFacade.getCustomizableRollupSettings().CMT_API_Status__c = '123 Failed';
        deploymentPR = panel.checkDeploymentStatus();
        System.assertEquals(null, deploymentPR, 'Returned PageReference should be null');
        System.assertEquals(false, panel.isPolling, 'Polling should not be active.');

        PageReference navPR = panel.navigate();
        System.debug(navPR);
        System.assertNotEquals(null, navPR, 'Returned PageReference should not be null');

    }

    /*********************************************************************************************************
    * @description Tests the Schedule panel
    * @return void
    */
    @isTest
    private static void testPanelSchedule() {
        STG_PanelSchedule_CTRL panel = new STG_PanelSchedule_CTRL();
        system.assertEquals('idPanelSchedule', panel.idPanel(), 'Assert that the panel schedule is the same as the panel.');
        STG_Panel.stgService.stgErr.Don_t_Auto_Schedule_Default_NPSP_Jobs__c = true;
        panel.saveSettings();
        system.assertEquals(true, UTIL_CustomSettingsFacade.getOrgErrorSettings().Don_t_Auto_Schedule_Default_NPSP_Jobs__c, 'This function checks if the value of Don t Auto - Schedule Default NSP Jobs is set');
        STG_Panel.stgService.stgErr.Don_t_Auto_Schedule_Default_NPSP_Jobs__c = false;
        panel.saveSettings();
        system.assertEquals(false, UTIL_CustomSettingsFacade.getOrgErrorSettings().Don_t_Auto_Schedule_Default_NPSP_Jobs__c, 'This function should only be used in unit tests.');
    }

    /*********************************************************************************************************
    * @description Tests the Trigger Handler panel
    * @return void
    */
    @isTest
    private static void testPanelTDTM() {
        STG_PanelTDTM_CTRL panel = new STG_PanelTDTM_CTRL();
        system.assertEquals('idPanelTDTM', panel.idPanel(), 'Assert that the panel is the same as the one in the panel panel table.');
        system.assertEquals(false, ApexPages.hasMessages(), 'Checks that ApexPages has messages.');
        system.assertEquals(null, panel.newTh(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.thNew, 'Assert that panel. thNew is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        system.assertEquals(null, panel.cancelTh(), 'Asserts that the cancel panel is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertEquals(null, panel.newTh(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.thNew, 'Assert that panel. thNew is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.thNew.Object__c = null;
        panel.thNew.Class__c = null;
        panel.thNew.Trigger_Action__c = null;
        panel.thNew.Load_Order__c = null;
        system.assertEquals(null, panel.createTh(), 'Assert that the panel is not null.');
        system.assertEquals(true, panel.isEditMode, 'Checks if the panel is in edit mode.');
        panel.thNew.Object__c = 'foo';
        panel.thNew.Class__c = 'bar';
        panel.thNew.Trigger_Action__c = 'AfterInsert';
        panel.thNew.Load_Order__c = 1;
        panel.thNew.Active__c = false;
        system.assertEquals(null, panel.createTh(), 'Assert that the panel is not null.');
        system.assertEquals(false, panel.isEditMode, 'Checks that the panel is in edit mode.');
        system.assertNotEquals(null, panel.listTH, 'Assert that the panel is not null.');
        system.assertEquals(1, panel.listTH.size(), 'Assert that the panel list is exactly 1.');
        panel.thIdDelete = 'not a valid id';
        system.assertEquals(null, panel.deleteTh(), 'Asserts that the deleteTh method is called.');
        panel.thIdDelete = panel.listTH[0].Id;
        system.assertEquals(null, panel.deleteTh(), 'Asserts that the deleteTh method is called.');
        system.assertNotEquals(null, panel.listTH, 'Assert that the panel is not null.');
        system.assertEquals(0, panel.listTH.size(), 'Assert that panel list is empty');
        system.assertNotEquals(null, panel.listSOTriggerAction, 'Assert that the panel is not null.');
    }

    /*********************************************************************************************************
    * @description Tests the Error Log panel
    * @return void
    */
    @isTest
    private static void testPanelErrorLog() {
        STG_PanelErrorLog_CTRL panel = new STG_PanelErrorLog_CTRL();
        system.assertEquals('idPanelErrorLog', panel.idPanel(), 'Checks that the idPanelErrorLog is the same as the panel id.');
        UTIL_SoqlListView_CTRL slv = new UTIL_SoqlListView_CTRL();
        panel.setComponentController(slv);
        slv.pageController = panel;
        system.assertNotEquals(null, panel.getStrSoql(), 'Assert that the string is not null.');
        system.assertNotEquals(null, panel.getstrFields(), 'Assert that all the fields in the panel are not null.');
        system.assertNotEquals(null, panel.getstrNameField(), 'Assert that the name field of the panel is not null.');
        system.assertNotEquals(null, panel.getstrObjectType(), 'Assert that the panel is not null.');
        system.assertEquals(null, panel.NewItem(), 'Assert that the panel is not null.');
        system.assertNotEquals(null, panel.EditItem(null), 'Asserts that the currently displayed panel is not the same as the currently displayed panel.');
        system.assertNotEquals(null, panel.getslvConsumer(), 'Assert that the slv consumer is not null.');
        system.assertEquals(null, panel.clearErrorLog(), 'Assert that the error log is cleared.');
        system.assertNotEquals(null, slv.setCon, 'Assert that slv. setCon is not null.');
        system.assertNotEquals(null, slv.cRecordsPerPage, 'Assert that slv. cRecordsPerPage is not null.');
        system.assertEquals(null, slv.showMoreRecordsPerPage(), 'Assert that slv. showMoreRecordsPerPage is called.');
        system.assertNotEquals(null, slv.NumberOfPages, 'This method asserts that the value of slv. NumberOfPages is not equal to null');
        system.assertNotEquals(null, slv.NumberOfItems, 'This test asserts that the number of items in the collection is not equal to the number of');
        system.assertNotEquals(null, slv.listSLVObj, 'Assert that slv. listSLVObj is not null.');
        system.assertNotEquals(null, slv.listSLVObjCurrent, 'Assert that the list of SLV objects is not null.');
        slv.strAlphaFilter = '%';
        system.assertNotEquals(null, slv.strAlphaFilter, 'Assert that the filter is not equal to the filter.');
        system.assertEquals(null, slv.AlphaFilter(), 'This test asserts that the alpha filter is null.');
        system.assertNotEquals(null, slv.listAlphaFilters, 'Assert that slv. listAlphaFilters is not null.');
        system.assertNotEquals(null, slv.SortItemField, 'assert that sortItemField is not null');
        system.assertNotEquals(null, slv.SortItemAsc, 'Sort is not equal to sort. SortItemAsc');
        system.assertEquals(null, slv.SortItem(), 'Assert that slv. SortItem is null.');
        system.assertNotEquals(null, slv.showCheckboxes, 'Assert that slv. showCheckboxes is not null.');

    }

    /*********************************************************************************************************
    * @description Tests the Health Check panel
    * @return void
    */
    @isTest
    private static void testPanelHealthCheck() {
        STG_PanelHealthCheck_CTRL panel = new STG_PanelHealthCheck_CTRL();
        
        System.assertEquals('idPanelHealthCheck', panel.idPanel(), 'Checks that the panel health check is the same as the one in the panel.');
        System.assertEquals(null, panel.runDetector(), 'Assert that the panel is not null.');
    }

    /*********************************************************************************************************
    * @description Tests the Level Assignment Batch panel
    * @return void
    */
    @isTest
    private static void testPanelLvlAssignBatch() {
        STG_PanelLvlAssignBatch_CTRL panel = new STG_PanelLvlAssignBatch_CTRL();
        system.assertEquals('idPanelLvlAssignBatch', panel.idPanel(), 'Assert that idPanelLvlAssignBatch is the same as idPanel');
        system.assertEquals(false, panel.isRunningBatch, 'Asserts that the panel is running batch.');
        panel.runBatch();
        system.assertEquals(true, panel.isRunningBatch, 'Checks that the panel is running batch.');
    }

    /*********************************************************************************************************
    * @description Tests the Remove Duplicate Primary OCRs Batch panel.
    * @return void
    */
    @isTest
    private static void testPanelPanelPrimaryContactRoleMergeBatch() {
        STG_PanelPrimaryContactRoleMerge_CTRL panel = new STG_PanelPrimaryContactRoleMerge_CTRL();
        system.assertEquals('idPanelPrimaryContactRoleMergeBatch', panel.idPanel(), 'Assert that the primary panel has the same primary contact role merge batch as the panel.');
        system.assertEquals(false, panel.isRunningBatch, 'Asserts that the panel is running batch.');
        Test.startTest();
        panel.runBatch();
        Test.stopTest();
        system.assertEquals(true, panel.isRunningBatch, 'Checks that the panel is running batch.');
    }

    /***
    * @description Verifies that when RD2 is not enabled, the legacy RD batch description should be displayed
    */
    @isTest
    private static void shouldDisplayLegacyRDPageDescriptionWhenRD2IsNotEnabled() {
        STG_PanelRDBatch_CTRL controller = new STG_PanelRDBatch_CTRL();

        Test.startTest();
        String batchDescription = controller.getPageDescription();
        Test.stopTest();

        System.assertEquals(System.Label.stgHelpRDBatch, batchDescription, 'The Legacy RD batch description should be displayed');
    }

    /***
    * @description Verifies that when RD2 is enabled, the RD2 batch description should be displayed
    */
    @isTest
    private static void shouldDisplayRD2PageDescriptionWhenRD2IsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        STG_PanelRDBatch_CTRL controller = new STG_PanelRDBatch_CTRL();

        Test.startTest();
        String batchDescription = controller.getPageDescription();
        Test.stopTest();

        System.assertEquals(System.Label.stgHelpEnhancedRDBatch, batchDescription, 'RD2 batch description should be displayed');
    }

    /**
    * @description Verifies when RD2 is not enabled, the RD2 Upgrade page should be displayed 
    */
    @isTest
    private static void shouldDisplayRD2UpgradePageIfRD2IsNotEnabled() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c());
        STG_Panel panel = new STG_Panel();

        System.assertEquals(true, panel.isDisplayingRD2UpgradePage, 'Should Display RD2 Upgrade page if user has not initiate RD2 upgrade');
    }

    /**
    * @description Verifies when RD2 is enabled but not fully complete, the RD2 Upgrade page should be displayed 
    */
    @isTest
    private static void shouldDisplayRD2UpgradePageIfRD2IsNotFullyEnabled() {
        RD2_EnablementDelegate_TEST.setEnablementDelegateRD2Enabled();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        STG_Panel panel = new STG_Panel();

        System.assertEquals(true, panel.isDisplayingRD2UpgradePage,
            'Should Display RD2 Upgrade page if user has not initiate RD2 upgrade');
    }

    /**
    * @description Verifies when RD2 is enabled but migration has not run yet, the RD2 Upgrade page should be displayed 
    */
    @isTest
    private static void shouldDisplayRD2UpgradePageIfRD2MigrationHasNotRun() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        STG_Panel panel = new STG_Panel();

        Test.startTest();
        Boolean isDisplayingRD2UpgradePage = panel.isDisplayingRD2UpgradePage;
        Test.stopTest();

        System.assertEquals(true, isDisplayingRD2UpgradePage,
            'Should not display RD2 Upgrade page if migration batch job has completed but the job cannot be found');
    }

    /**
    * @description Verifies when RD2 is enabled, dry run has ran but Migration hasn't ran yet, the RD2 Upgrade page shuold be displayed
    */
    @isTest
    private static void shouldDisplayRD2UpgradePageIfRD2DryRunHasRanButMigrationHasnotRan() {
        Integer MigrationJobRanDay = 5;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        UTIL_BatchJobService.JobSummary summary = new UTIL_BatchJobService.JobSummary(UTIL_BatchJobService_TEST.MOCK_BATCH_ID)
            .withTotalRecordsProcessed(2);
    
        Map<String, UTIL_BatchJobService.JobSummary> summaryByType = new Map<String, UTIL_BatchJobService.JobSummary> {
            'dryRun' => summary
        };

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                RecurringDonations2MigrationState__c = JSON.serialize(summaryByType)
            )
        );

        STG_Panel panel = new STG_Panel();

        System.assertEquals(true, panel.isDisplayingRD2UpgradePage,
            'Should display RD2 Upgrade page if user has ran Migration job in the past 7 days');
    }

    /**
    * @description Verifies when RD2 is enabled and migration async job is completed less than 7 days ago,
    * the RD2 Upgrade page should be displayed 
    */
    @isTest
    private static void shouldDisplayRD2UpgradePageIfRD2MigrationHasRunLessThan7DaysAgo() {
        Integer MigrationJobRanDay = 5;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        UTIL_BatchJobService.JobSummary summary = new UTIL_BatchJobService.JobSummary(UTIL_BatchJobService_TEST.MOCK_BATCH_ID)
            .withTotalRecordsProcessed(2);
    
        Map<String, UTIL_BatchJobService.JobSummary> summaryByType = new Map<String, UTIL_BatchJobService.JobSummary> {
            'run' => summary
        };

        STG_Panel.batchJobService = (UTIL_BatchJobService) Test.createStub(
            UTIL_BatchJobService.class, new UTIL_BatchJobService_TEST.Stub().withCompletedDaysBetween(MigrationJobRanDay)
        );

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                RecurringDonations2MigrationState__c = JSON.serialize(summaryByType)
            )
        );

        STG_Panel panel = new STG_Panel();

        System.assertEquals(true, panel.isDisplayingRD2UpgradePage,
            'Should display RD2 Upgrade page if user has ran Migration job in the past 7 days');
    }

    /**
    * @description Verifies when RD2 is enabled and migration async job is completed more than 7 days ago,
    * the RD2 Upgrade page should be hidden 
    */
    @isTest
    private static void shouldNotDisplayRD2UpgradePageIfRD2MigrationHasRunMoreThan7DaysAgo() {
        Integer MigrationJobRanDay = 8;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        UTIL_BatchJobService.JobSummary summary = new UTIL_BatchJobService.JobSummary(UTIL_BatchJobService_TEST.MOCK_BATCH_ID)
            .withTotalRecordsProcessed(2);
    
        Map<String, UTIL_BatchJobService.JobSummary> summaryByType = new Map<String, UTIL_BatchJobService.JobSummary> {
            'run' => summary
        };

        STG_Panel.batchJobService = (UTIL_BatchJobService) Test.createStub(
            UTIL_BatchJobService.class, new UTIL_BatchJobService_TEST.Stub().withCompletedDaysBetween(MigrationJobRanDay)
        );

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                RecurringDonations2MigrationState__c = JSON.serialize(summaryByType)
            )
        );

        STG_Panel panel = new STG_Panel();

        System.assertEquals(false, panel.isDisplayingRD2UpgradePage,
            'Should not display RD2 Upgrade page if user has ran Migration job more than 7 days ago');
    }

    /**
    * @description Verifies when RD2 is enabled and migration async job is already deleted,
    * the RD2 Upgrade page should be hidden 
    */
    @isTest
    private static void shouldNotDisplayRD2UpgradePageIfRD2MigrationHasRunInThePast() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        UTIL_BatchJobService.JobSummary summary = new UTIL_BatchJobService.JobSummary(UTIL_BatchJobService_TEST.MOCK_BATCH_ID)
            .withTotalRecordsProcessed(2);
    
        Map<String, UTIL_BatchJobService.JobSummary> summaryByType = new Map<String, UTIL_BatchJobService.JobSummary> {
            'run' => summary
        };

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                RecurringDonations2MigrationState__c = JSON.serialize(summaryByType)
            )
        );

        STG_Panel panel = new STG_Panel();

        System.assertEquals(false, panel.isDisplayingRD2UpgradePage,
            'Should not display RD2 Upgrade page if user has ran Migration long time ago');
    }

    /**
    * @description Verifies RD2 Upgrade page should display when the user goes through simple upgrade and less than
    * 7 RD2 nightly batch job has ran.
    */
    @isTest
    private static void shouldDisplaySimpleRD2UpgradePageAfterUpgradeCompleteAndButLessThan7NightlyBatchJobHasRan() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        for (Integer i = 0; i < 6; i++) {
            Database.executeBatch(new RD2_OpportunityEvaluation_BATCH(), 1);
        }

        Test.startTest();
        Boolean isDisplayingRD2UpgradePage = new STG_Panel().isDisplayingRD2UpgradePage;
        Test.stopTest();
    
        System.assertEquals(true, isDisplayingRD2UpgradePage,
            'Should display RD2 Upgrade page if simple RD2 upgrade has completed but less than 7 RD2 nightly batch job has ran.');
    }

    /**
    * @description Verifies when RD2 is enabled through simple upgrade and nightly batch job has ran more than 7 times,
    * the RD2 Upgrade page should be hidden
    */
    @isTest
    private static void shouldNotDisplaySimpleRD2UpgradePageAfterUpgradeCompleteAndMoreThan7NightlyBatchJobHasRan() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        for (Integer i = 0; i < 7; i++) {
            Database.executeBatch(new RD2_OpportunityEvaluation_BATCH(), 1);
        }

        Test.startTest();
        Boolean isDisplayingRD2UpgradePage = new STG_Panel().isDisplayingRD2UpgradePage;
        Test.stopTest();
    
        System.assertEquals(false, isDisplayingRD2UpgradePage,
            'Should not display RD2 Upgrade page if user has upgrade RD through Simple Upgrade and ran nightly batch job 7 times');
    }

    /**
    * @description Verifies that when the User without Customize Application permission 
    *   executes the saveSettings in System mode (directly calling saveSettings Apex class),
    *   the code will still enfore Salesforce Security on updating RD Settings custom settings.
    */
    @isTest
    private static void shouldBlockUpdateRDSettingWhenUserDoesNotHaveUpdatePermission() {
        STG_PanelRD_CTRL controller = new STG_PanelRD_CTRL();

        Test.startTest();
        System.runAs(createReadOnlyUser()) {
            controller.saveSettings(); 
        }
        Test.stopTest();

        Error__c error = errorGateway.getRecords()[0];
        String expectedMessage = String.format(
            System.Label.flsError, 
            new List<String>{System.Label.stgLabelRDSettings}
        );
        
        System.assert(error.Full_Message__c.contains(expectedMessage),
            'User with Read Only Profile should not be abled to update RD Setting: ' + error.Full_Message__c);
    }

    /**
    * @description Verifies that when DisableRecordDataHealthChecks__c is enabled,
    *    all data record health checks should be disabled and have warning records created
    */
    @isTest
    private static void shouldCreateWarningRecordsWhenDisabledRecordHealthCheckIsEnabled() {
        STG_PanelHealthCheck_CTRL panel = new STG_PanelHealthCheck_CTRL();

        STG_Panel.stgService.stgErr.DisableRecordDataHealthChecks__c = true;
        
        Test.startTest();
        panel.runDetector();
        Test.stopTest();

        List<STG_PAnelHealthCheck_CTRL.DetectResult> results = panel.listDR;
        Boolean hasDisabledHealthCheckWarningMessage = false;

        for (STG_PAnelHealthCheck_CTRL.DetectResult result : results) {
            if (result.strStatus == STG_PanelHealthCheck_CTRL.statusWarning && result.strName == System.Label.healthLabelDataBatchNotRun) {
                hasDisabledHealthCheckWarningMessage = true;
                break;
            }
        }

        System.assert(hasDisabledHealthCheckWarningMessage,
            'A Warning message indicates Record Data Health Checks are not run should exist'
        );
    }

    //Helper Methods
    /**
     * @description Builds a read only user with readonly profile
     * @return User
    */
    private static User createReadOnlyUser() {
        User usr = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);
        return usr;
    }

    /**
    * @description create a instance of opportunity naming settings
    * @return opportunity naming settings
    */
    private static Opportunity_Naming_Settings__c setUpOppNamingSettings() {
        String optionName = STG_PanelOppNaming_CTRL.AttributionOptions.Contact_Donations.name();
        return OPP_OpportunityNaming_TEST.setUpOppNamingSettings(new Map<String, Object>{ 'Attribution__c' => optionName });

    }

    /**
    * @description create a instance of custom field mapping settings
    * @return custom field mapping
    */
    private static npe03__Custom_Field_Mapping__c setUpCustomFieldMapping() {
        npe03__Custom_Field_Mapping__c settings = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert settings;

        return settings;

    }

    /**
    * @description create a instance of custom installment settings
    * @return custom installment settings
    */
    private static npe03__Custom_Installment_Settings__c setUpCustomInstallmentSettings() {
        npe03__Custom_Installment_Settings__c settings = new npe03__Custom_Installment_Settings__c(
            Name = 'TestInstallment',
            npe03__Value__c = 10,
            npe03__Increment__c = 'Days'
        );
        insert settings;

        return settings;
    }

    /**
    * @description create a instance of payment field mapping settings
    * @return payment field mapping settings
    */
    private static npe01__Payment_Field_Mapping_Settings__c setUpPaymentFieldMapSettings() {
        npe01__Payment_Field_Mapping_Settings__c settings = new npe01__Payment_Field_Mapping_Settings__c(
            Name = 'TestMapping',
            npe01__Opportunity_Field__c = 'Opportunity',
            npe01__Payment_Field__c = 'npe01__OppPayment__c'
        );
        insert settings;

        return settings;
    }

    /**
    * @description create a instance of relationship lookup settings
    * @return relationship lookup settings
    */
    private static npe4__Relationship_Lookup__c setUpRelationshipLookup() {
        npe4__Relationship_Lookup__c settings = new npe4__Relationship_Lookup__c(
            Name = 'TestMapping',
            npe4__Male__c = 'bar',
            npe4__Female__c = 'baz',
            npe4__Neutral__c = 'byz'

        );
        insert settings;

        return settings;
    }

    /**
    * @description create a instance of relationship auto create settings
    * @return relationship auto create settings
    */
     private static npe4__Relationship_Auto_Create__c setUpRelationshipAutoCreate() {
        npe4__Relationship_Auto_Create__c settings = new npe4__Relationship_Auto_Create__c(
            Name = 'TestMapping',
            npe4__Object__c = 'Contact',
            npe4__Field__c = 'ReportsToId',
            npe4__Relationship_Type__c = 'coworker'

        );
        insert settings;

        return settings;
    }

    /**
    * @description create a instance of user roll up field settings
    * @return user roll up field settings
    */
     private static npo02__User_Rollup_Field_Settings__c setUpUserRollupFieldSettings() {
        npo02__User_Rollup_Field_Settings__c settings = new npo02__User_Rollup_Field_Settings__c(
            Name = 'Household Test Rollup',
            npo02__Target_Field__c = 'lastoppamount__c',
            npo02__Source_Field__c = 'Amount',
            npo02__Object_Name__c = 'npo02__Household__c',
            npo02__Field_Action__c = 'MAX'
        );
        insert settings;

        return settings;
    }

}