public class ProcessRelatedWorkOrderRecordsQueueable implements Queueable {

    private List < ContractLineItem > lstOfContractLineItems;
    private Map < Date, List < WorkOrder >> mapOfWorkOrders;
    private Map < Date, WorkOrder > mapOfInsertedWorkOrders;
    private List < WorkOrder > lstOfImpactedWorkOrders;
    private Map < Id, WorkOrder > mapOfIdVsWorkOrder;
    private ServiceContract serviceContractRecord;
    private List < WorkOrder > lstOfWorkOrder;
    
    public ProcessRelatedWorkOrderRecordsQueueable setLstOfImpactedWorkOrders(List < WorkOrder > lstOfImpactedWorkOrders) {
        this.lstOfImpactedWorkOrders = lstOfImpactedWorkOrders;
        return this;
    }
    
    public ProcessRelatedWorkOrderRecordsQueueable setLstOfContractLineItems(List < ContractLineItem > lstOfContractLineItems) {
        this.lstOfContractLineItems = lstOfContractLineItems;
        return this;
    }
    
    public ProcessRelatedWorkOrderRecordsQueueable setServiceContractRecord(ServiceContract serviceContractRecord) {
        this.serviceContractRecord = serviceContractRecord;
        return this;
    }
    
    public ProcessRelatedWorkOrderRecordsQueueable setMapOfWorkOrders(Map < Date, List < WorkOrder >> mapOfWorkOrders) {
        this.mapOfWorkOrders = mapOfWorkOrders;
        return this;
    }
    
    public ProcessRelatedWorkOrderRecordsQueueable setLstOfWorkOrder(List < WorkOrder > lstOfWorkOrder) {
        this.lstOfWorkOrder = lstOfWorkOrder;
        return this;
    }

    public void execute(QueueableContext context) {
        try {

            processWorkOrderLineItems();
            adjustServiceAppointments();
            delete lstOfImpactedWorkOrders;
            update lstOfContractLineItems;

            serviceContractRecord.Bulk_Order_Generation_Status__c = 'Completed';
            serviceContractRecord.Bulk_Order_Generation_Log__c = 'Completed Successfully';
            update serviceContractRecord;
        
        } catch (Exception ex) {
            serviceContractRecord.Bulk_Order_Generation_Status__c = 'Failed';
            serviceContractRecord.Bulk_Order_Generation_Log__c = 'Failed in Class ProcessRelatedWorkOrderRecordsQueueable. Details : ' + ex.getStackTraceString();
            update serviceContractRecord;
        }
    }

    private void processWorkOrderLineItems() {

        mapOfInsertedWorkOrders = new Map < Date, WorkOrder > ();
        mapOfIdVsWorkOrder = new Map < Id, WorkOrder > ();

        for (WorkOrder insertedWorkOrder: lstOfWorkOrder) {
            mapOfIdVsWorkOrder.put(insertedWorkOrder.Id, insertedWorkOrder);
            mapOfInsertedWorkOrders.put(Date.ValueOf(insertedWorkOrder.StartDate), insertedWorkOrder);
        }

        List < WorkOrderLineItem > lstOfWOLI = new List < WorkOrderLineItem > ();

        for (Date workOrderDate: mapOfWorkOrders.keySet()) {
            for (WorkOrder woRecord: mapOfWorkOrders.get(workOrderDate)) {
                lstOfWOLI.add(getWorkOrderLineItem(woRecord, workOrderDate));
            }
        }

        if (lstOfWOLI.isEmpty())
            return;

        insert lstOfWOLI;
    }

    private void adjustServiceAppointments() {
        if (mapOfIdVsWorkOrder == null || mapOfIdVsWorkOrder.isEmpty())
            return;

        List < ServiceAppointment > lstOfServiceAppointments = new List < ServiceAppointment > ();
        for (ServiceAppointment SArecord: [SELECT Id, ParentRecordId FROM ServiceAppointment
                WHERE ParentRecordId IN: mapOfIdVsWorkOrder.Keyset()
            ]) {
            SArecord.Duration = mapOfIdVsWorkOrder.get(SArecord.ParentRecordId).Duration;
            SArecord.DurationType = 'Minutes';
            SArecord.EarliestStartTime = mapOfIdVsWorkOrder.get(SArecord.ParentRecordId).StartDate;
            SArecord.DueDate = mapOfIdVsWorkOrder.get(SArecord.ParentRecordId).EndDate;
            SArecord.SchedStartTime = mapOfIdVsWorkOrder.get(SArecord.ParentRecordId).StartDate;
            SArecord.SchedEndTime = mapOfIdVsWorkOrder.get(SArecord.ParentRecordId).EndDate;
            SArecord.ContactId = mapOfIdVsWorkOrder.get(SArecord.ParentRecordId).ContactId;
            lstOfServiceAppointments.add(SArecord);
        }

        if (!lstOfServiceAppointments.isEmpty())
            update lstOfServiceAppointments;
    }

    private WorkOrderLineItem getWorkOrderLineItem(WorkOrder woRecord, Date workOrderDate) {
        return new WorkOrderLineItem(
            WorkOrderId = mapOfInsertedWorkOrders.get(workOrderDate).Id,
            PricebookEntryId = woRecord.PriceBookEntryId_For_Dev__c,
            ServiceTerritoryId = woRecord.ServiceTerritoryId,
            Description = woRecord.Description,
            PostalCode = woRecord.PostalCode,
            Subject = woRecord.Subject,
            Country = woRecord.Country,
            DurationType = 'Minutes',
            Street = woRecord.Street,
            State = woRecord.State,
            City = woRecord.City,
        	LocationId = woRecord.LocationId,
        	Frequency__c = woRecord.Frequency_Dev__c,
        	Location__c = woRecord.Location_Dev__c,
        	Other_Location__c = woRecord.Other_Location__c);
    }
}