import { LightningElement, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import getMetadata from '@salesforce/apex/OSF_WebToCaseLWC.getMetadata'
import getCases from '@salesforce/apex/OSF_WebToCaseLWC.getCases'

const EMPTY_STRING = '';
const FORCE_STRING = 'Force';
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+$/;
const PHONE_PATTERN = /^\d+$/;
const EMPTY_FIELDS_ERROR_STRING = 'Please fill in all the fields.';
const INVALID_EMAIL_ERROR_STRING = 'Please provide a valid email.';
const INVALID_PHONE_ERROR_STRING = 'Please provide a valid phone number';
const TEXTAREA_TYPE_STRING = 'textarea';
const EMAIL_FIELD_STRING = 'SuppliedEmail';
const PHONE_FIELD_STRING = 'SuppliedPhone';

export default class OsfWebToCaseLWC extends LightningElement {
    @api siteName;

    isLoading;
    error;

    fields = [];

    inputFields = [];
    textareaFields = [];
    fieldValues = {};

    cases = [];

    connectedCallback() {
        this.isLoading = true;
        this.loadMetadata();
    }

    get brandName() {
        return this.siteName ? this.siteName : FORCE_STRING;
    }

    async loadMetadata() {
        await getMetadata({ brand: this.brandName })
        .then(result => {
            this.fields = result.OSF_WtC_Form_Fields__r;

            this.inputFields = this.generateTextFields(result.OSF_WtC_Form_Fields__r);

            this.textareaFields = this.generateTextareaFields(result.OSF_WtC_Form_Fields__r);

            this.generateFieldValues(result.OSF_WtC_Form_Fields__r);

            this.isLoading = false;
        });
    }

    generateFieldValues(fields) {
        fields.forEach(field => {
            this.fieldValues[field.Name__c] = field.Default_Value__c ? field.Default_Value__c : EMPTY_STRING ;
        })
    }

    generateTextFields(fields) {
        return fields.filter(field => field.isVisible__c && field.Type__c !== TEXTAREA_TYPE_STRING)
                     .map(field => {
                        field.Default_Value__c = field.Default_Value__c ? field.Default_Value__c : EMPTY_STRING;
                        field.Max_Length__c = field.Max_Length__c ? field.Max_Length__c : EMPTY_STRING;
                        field.Min_Length__c = field.Min_Length__c ? field.Min_Length__c : EMPTY_STRING;
                        return field;
                     })
                     .sort((a, b) => a.Index__c - b.Index__c);
    }

    generateTextareaFields(fields) {
        return fields.filter(field => field.isVisible__c && field.Type__c === TEXTAREA_TYPE_STRING)
                    .map(field => {
                        field.Default_Value__c = field.Default_Value__c ? field.Default_Value__c : EMPTY_STRING;
                        field.Max_Length__c = field.Max_Length__c ? field.Max_Length__c : EMPTY_STRING;
                        field.Min_Length__c = field.Min_Length__c ? field.Min_Length__c : EMPTY_STRING;
                        return field;
                    })
                    .sort((a, b) => a.Index__c - b.Index__c);
    }

    handleInputChange(event) {
        this.fieldValues[event.target.name] = event.detail.value;
        this.error = null;
    }

    async handleCaseSubmit(e) {
        e.preventDefault();
        this.isloading = true;
        const values = JSON.parse(JSON.stringify(this.fieldValues));

        try{
            this.validateInputs(values)
            await createRecord({ 'apiName': 'Case', 'fields': values });
            this.cases = await getCases({ caseEmail: values.SuppliedEmail, brand: this.brandName });
        } catch(err) {
            this.error = err.message;
            this.isLoading = false;
        }
        
        this.isloading = false;
    }

    handleBackToForm(e) {
        e.preventDefault();

        this.isLoading = true;
        this.cases = [];
        this.generateFieldValues(this.fields)
        this.isLoading = false;
    }

    validateInputs(inputs) {
        for (let key in inputs) {
            if (!inputs[key]) {
                throw new Error(EMPTY_FIELDS_ERROR_STRING);
            }

            if (key === EMAIL_FIELD_STRING && !this.validateEmail(inputs[key])) {
                throw new Error(INVALID_EMAIL_ERROR_STRING);
            }

            if (key === PHONE_FIELD_STRING && !this.validatePhone(Number(inputs[key]))) {
                throw new Error(INVALID_PHONE_ERROR_STRING);
            }
        }
    }

    validateEmail(email) {
        return EMAIL_PATTERN.test(email);
    }

    validatePhone(phone) {
        return PHONE_PATTERN.test(phone);
    }
}