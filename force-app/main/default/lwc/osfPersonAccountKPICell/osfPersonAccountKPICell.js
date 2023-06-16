import { LightningElement, api } from 'lwc';

export default class OsfPersonAccountKPICell extends LightningElement {

    @api label;
    @api value;
    @api icon;
}