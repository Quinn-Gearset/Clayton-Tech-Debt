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
* @description Contact entity class in NPSP.
*/
public inherited sharing class NPSP_Contact {

    private Contact contact;
    private Contact oldContact;
    private IAddress mailingAddress;

    @TestVisible
    private ContactService contactService {
        get {
            if (contactService == null) {
                contactService = new ContactService();
            }
            return contactService;
        }
        set;
    }

    @TestVisible
    private AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

   public NPSP_Contact(Contact contact, Contact oldContact) {
        this.contact = contact;
        this.oldContact = oldContact;
    }

    public NPSP_Contact(Contact contact) {
        this.contact = contact;
    }

    /* Get the record. */
    public Contact getRecord() {
        return this.contact;
    }

    /* Sets the current address of the contact. */
    public void setCurrentAddress(IAddress npspAddress) {
        contact.Current_Address__c = npspAddress.getRecord()?.Id;
        mailingAddress(npspAddress);
    }

    /* Returns true if this contact is undeliverable. */
    public Boolean isUndeliverableMailingAddress() {
        return contact.Undeliverable_Address__c;
    }

    /* setUndeliverableMailingAddress This sets the value of the Undeliverable_Address */
    public void setUndeliverableMailingAddress(Boolean isUndeliverableAddress) {
        contact.Undeliverable_Address__c = isUndeliverableAddress;
    }

    /* Returns true if the Undeliverable_Address attribute of this Contact has changed. */
    public Boolean isUndeliverableStatusChanged() {
        return (isNewContact() && contact.Undeliverable_Address__c) || (!isNewContact() &&
            contact.Undeliverable_Address__c != oldContact.Undeliverable_Address__c);
    }

    /* Returns true if this is a new contact. */
    public Boolean isNewContact() {
        return oldContact == null;
    }

    /* Returns the current address of the contact. */
    public Id currentAddress() {
        return contact.Current_Address__c;
    }

    /* Returns true if the contact has an address override. */
    public Boolean hasAddressOverride() {
        return contact.is_Address_Override__c;
    }

    /* Returns true if the account has changed. */
    public Boolean accountChanged() {
        return oldContact?.AccountId != contact.AccountId;
    }

    /* Checks if the address of the contact has changed. */
    public Boolean isAddressChanged() {
        Boolean addressEmpty = isContactAddressEmpty();
        return oldContact == null ? !addressEmpty :
            addressService.isSObjectAddressDifferent(oldContact, mailingAddress()) ||
            (!addressEmpty && primaryAddressTypeChanged());
    }

    /* Returns true if the address is empty. */
    public Boolean isAddressEmpty() {
        return isContactAddressEmpty();
    }

    /*******************************************************************************************************
    * @description returns whether the contact's mailing address is empty
    * @return boolean. true if the Mailing Address fields are all empty
    ********************************************************************************************************/
    private Boolean isContactAddressEmpty() {
        Boolean isEmpty =
                contact.MailingStreet == null &&
                        contact.MailingCity == null &&
                        contact.MailingState == null &&
                        contact.MailingPostalCode == null &&
                        // note that we decided to ignore country so that a default value won't create unnecessary address objects
                        (contact.MailingCountry == null || orgConfig.isStateCountryPicklistsEnabled()) &&
                        // only test StateCode if picklists enabled.
                        (!orgConfig.isStateCountryPicklistsEnabled() || contact.get('MailingStateCode') == null);
        return isEmpty;
    }

    /* Returns true if the address override has changed. */
    public Boolean addressOverrideChanged() {
        return contact.is_Address_Override__c != oldContact?.is_Address_Override__c;
    }

    /* Returns true if the current address has changed. */
    public Boolean currentAddressChanged() {
        return contact.Current_Address__c != oldContact?.Current_Address__c;
    }

    /* Returns true if the primary address type has changed. */
    public Boolean primaryAddressTypeChanged() {
        return primaryAddressType(contact) != primaryAddressType(oldContact);
    }

    /* Returns true if the contact has an account. */
    public Boolean hasAccount() {
        return contact.AccountId != null;
    }

    /* Returns true if the Household and Account are different. */
    public Boolean householdAndAccountDiffer() {
        return contact.HHId__c != contact.AccountId;
    }

    /* Returns the account id of the contact. */
    public Id accountId() {
        return contact.AccountId;
    }

    /* Returns the household id of this contact. */
    public Id householdId() {
        return contact.npo02__household__c;
    }

    /* Returns true if the current node is moving to an anew household. */
    public Boolean isMovingToANewHousehold() {
        return accountChanged() && !isAddressEmpty();
    }

    /* mailingAddress - The address of the contact. */
    public void mailingAddress(IAddress anAddress) {
        addressService.copyOntoSObject(
                anAddress, contact, 'Mailing',
                'npe01__Primary_Address_Type__c');
        this.mailingAddress = anAddress;
    }

    /* Returns the mailing address. */
    public IAddress mailingAddress() {
        return mailingAddress != null ? mailingAddress : new NPSP_Address(contact);
    }

    /* Returns true if this address is different from the given address. */
    public Boolean mailingAddressIsDifferentFrom(IAddress other) {
       return mailingAddress().isDifferentIncludingLatLong(other) ||
               isCurrentAddressDifferent(other) ||
               isAddressTypeDifferent(other);
    }

    private Boolean isCurrentAddressDifferent(IAddress other) {
        return !addressService.equalsCaseSensitive(
                (String) currentAddress(contact),
                other.getRecord().Id);
    }

    private Boolean isAddressTypeDifferent(IAddress other) {
        return !addressService.equalsCaseSensitive(
                primaryAddressType(contact),
                other.getType());
    }

    private Object currentAddress(SObject sObj) {
        return sObj.get('Current_Address__c');
    }

    private String primaryAddressType(SObject sObj) {
        return (String) sObj.get
                ('npe01__Primary_Address_Type__c');
    }

    /* Returns an NPSP_Contact object that contains the old version of the contact. */
    public NPSP_Contact oldVersion() {
        return new NPSP_Contact(oldContact);
    }

    /* Returns true if the address override has been changed and the node has no address override. */
    public Boolean isClearingAddressOverride() {
        return (addressOverrideChanged() && !hasAddressOverride());
    }

    /* Returns true if the current version of the JVM had an address. */
    public Boolean hadAnAddress() {
        return oldVersion().currentAddress() != null;
    }

    /* Returns true if the fields of the fields that have been changed have been added to the address */
    public Boolean noAddressFieldsChanged() {
        return !isAddressChanged() && hadAnAddress();
    }

    /* Returns true if the current address is changing to an anew address. */
    public Boolean isChangingToANewCurrentAddress() {
        return isCurrentAddressChanged() && hasAddressOverride();
    }

    /* Returns true if the current address has changed. */
    public Boolean isCurrentAddressChanged() {
        return currentAddressChanged() && currentAddress() != null;
    }

}