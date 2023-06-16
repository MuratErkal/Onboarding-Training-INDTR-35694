import { LightningElement, api, wire } from 'lwc';

import getProducts from '@salesforce/apex/OSF_PersonAccountKPI.getData';

const CUSTOMER_SINCE_LABEL = 'Customer Since';
const CUSTOMER_SINCE_ICON = 'utility:clock';
const PENDING_CASES_LABEL = 'Pending Cases';
const PENDING_CASES_ICON = 'utility:cases';
const TOTAL_CASES_LABEL = 'No of Cases';
const TOTAL_CASES_ICON = 'utility:case';
const TOTAL_ORDERS_LABEL = 'No of Orders';
const TOTAL_ORDERS_ICON = 'utility:cart';
const AOV_LABEL = 'AOV';
const AOV_ICON = 'utility:payment_gateway';
const BIRTHDATE_LABEL = 'Birthday';
const BIRTHDATE_ICON = 'utility:date_time';
const YTD_LABEL = 'YTD';
const YTD_ICON = 'utility:currency';
const YTD5_LABEL = 'YTD5';
const YTD5_ICON = 'utility:money';

export default class OsfPersonAccountKPI extends LightningElement {
    @api recordId;

    isLoading;

    data;

    dataArr;
    

    @wire(getProducts, { pAccId: '$recordId' })
    recordList({ error, data}) {
        this.isLoading = true;
        if (data) {
            this.data = JSON.parse(data);
            this.generateDataArr(this.data);
            this.isLoading = false;
        } else if (error) {
            alert('Error: ' + JSON.stringify(error));
        }
    }

    generateDataArr(data) {
        const resultArr = [];

        //CUSTOMER SINCE
        
        const customerSinceValue = this.formatDate(data.personAccount.CreatedDate);
        resultArr.push(this.generateObject(CUSTOMER_SINCE_LABEL, customerSinceValue, CUSTOMER_SINCE_ICON, 0));

        //CASES
        let numOfOpenCasesValue, numOfCasesValue;
        if(data.personAccount.Cases) {
            const casesResult = this.calculateCases(data.personAccount.Cases);
            numOfOpenCasesValue = casesResult.numOfOpenCases;
            numOfCasesValue = casesResult.numOfCases;
        } else {
            numOfOpenCasesValue = 0;
            numOfCasesValue = 0;
        }
        resultArr.push(this.generateObject(TOTAL_CASES_LABEL, numOfCasesValue, TOTAL_CASES_ICON, 2));
        resultArr.push(this.generateObject(PENDING_CASES_LABEL, numOfOpenCasesValue, PENDING_CASES_ICON, 4));

        //BIRTHDATE
        let birthdateValue;
        if(data.personAccount.PersonBirthdate) {
            birthdateValue = this.formatDate(data.personAccount.PersonBirthdate);
        } else {
            birthdateValue = '';
        }
        resultArr.push(this.generateObject(BIRTHDATE_LABEL, birthdateValue, BIRTHDATE_ICON, 3));

        //ORDERS
        let numOfOrdersValue, avgOrderValueValue;
        if(data.personAccount.Orders) {
            const ordersResult = this.calculateOrders(data.personAccount.Orders);
            numOfOrdersValue = ordersResult.numOfOrders;
            avgOrderValueValue = ordersResult.avgOrderValue;
        } else {
            numOfOrdersValue = 0;
            avgOrderValueValue = '';
        }
        resultArr.push(this.generateObject(TOTAL_ORDERS_LABEL, numOfOrdersValue, TOTAL_ORDERS_ICON, 1));
        resultArr.push(this.generateObject(AOV_LABEL, avgOrderValueValue, AOV_ICON, 7));

        //YTD
        const ytdValue = (data.ytd.expr0 || '').toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        const ytd5Value = (data.ytd5.expr0 || '').toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        resultArr.push(this.generateObject(YTD_LABEL, ytdValue, YTD_ICON, 5));
        resultArr.push(this.generateObject(YTD5_LABEL, ytd5Value, YTD5_ICON, 6));

        this.dataArr = resultArr.sort((a, b) => a.index - b.index);
    }

    formatDate(dateStr) {
        const date = new Date(dateStr);
        const options = { month: 'long', day: 'numeric', year: 'numeric' };
        const formattedDate = new Intl.DateTimeFormat('en-US', options).format(date);
        return formattedDate;
    }

    calculateCases(cases) {
        const resultObj = {
            numOfOpenCases: 0
        };
        resultObj.numOfCases = cases.totalSize;
                
        cases.records.forEach(c => {
            if(c.Status !== 'Closed') {
                resultObj.numOfOpenCases++;
            }
        })

        return resultObj;
    }

    calculateOrders(orders) {
        const resultObj = {};

        resultObj.numOfOrders = this.data.personAccount.Orders.totalSize;

        let orderSum = 0;
        orders.records.forEach(o => {
            orderSum += o.TotalAmount;
        })
        resultObj.avgOrderValue = (orderSum / orders.totalSize).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

        return resultObj;
    }

    generateObject(label, value, icon, index) {
        return {
            label,
            value,
            icon,
            index
        };
    }
}