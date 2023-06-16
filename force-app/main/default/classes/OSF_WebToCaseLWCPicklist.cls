global class OSF_WebToCaseLWCPicklist extends VisualEditor.DynamicPickList{
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(
            'Default (Force)', 'Default'
        );
        return defaultValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows pickListValues = new VisualEditor.DynamicPickListRows();
        VisualEditor.DataRow forceValue = new VisualEditor.DataRow('Force', 'Force');
        VisualEditor.DataRow salesValue = new VisualEditor.DataRow('Sales', 'Sales');
        pickListValues.addRow(forceValue);
        pickListValues.addRow(salesValue);
        return pickListValues;
    }
}