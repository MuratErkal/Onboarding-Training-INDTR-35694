import { LightningElement, api, wire } from 'lwc';
import getProducts from '@salesforce/apex/OSF_GetMasterAccountMostPurchased.getProducts';
//use UPPERCASE for constants
const COLUMNS = [
    { label: 'Product', fieldName: 'product' },
    { label: 'Quantity', fieldName: 'quantity'},
    { label: 'Total', fieldName: 'total'}
];

export default class OsfMasterAccountMostPurchased extends LightningElement {
    @api recordId;
    
    columns = COLUMNS;
    tableData;
    data;
    error;

    limitNum;

    @wire(getProducts, { mAccId: '$recordId', limitNum: '$limitNum'})
    recordList({ error, data}) {
        if (data) {
            this.tableData = JSON.parse(data).slice(0, this.limitNum ? this.limitNum : 10)
                                            .sort((a,b) => Number(b.quantity) - Number(a.quantity));
        } else if (error) {
            this.error = error;
            this.tableData = undefined;
        }
    }

    connectedCallback() {
        this.limitNum = 10;
    }

    get options() {
        return [
            { label: '10', value: 10 },
            { label: '25', value: 25 },
            { label: '50', value: 50 },
        ];
    }

    handleChange(event) {
        this.limitNum = Number(event.detail.value);
    }
}