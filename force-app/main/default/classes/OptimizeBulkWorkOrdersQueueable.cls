public class OptimizeBulkWorkOrdersQueueable implements Queueable {

    private static final String DEFAULT_WORK_TYPE_NAME = 'DEFAULT WORK TYPE';

    private List < ContractLineItem > lstOfContractLineItems;
    private Map < Date, List < WorkOrder >> mapOfWorkOrders;
    private List < WorkOrder > lstOfImpactedWorkOrders;
    private ServiceContract serviceContractRecord;
    private List < WorkOrder > lstOfWorkOrder;
    private List < WorkType > defaultWorkType;
    
    public OptimizeBulkWorkOrdersQueueable setLstOfImpactedWorkOrders(List < WorkOrder > lstOfImpactedWorkOrders) {
        this.lstOfImpactedWorkOrders = lstOfImpactedWorkOrders;
        return this;
    }
    
    public OptimizeBulkWorkOrdersQueueable setLstOfContractLineItems(List < ContractLineItem > lstOfContractLineItems) {
        this.lstOfContractLineItems = lstOfContractLineItems;
        return this;
    }
    
    public OptimizeBulkWorkOrdersQueueable setServiceContractRecord(ServiceContract serviceContractRecord) {
        this.serviceContractRecord = serviceContractRecord;
        return this;
    }
    
    public OptimizeBulkWorkOrdersQueueable setMapOfWorkOrders(Map < Date, List < WorkOrder >> mapOfWorkOrders) {
        this.mapOfWorkOrders = mapOfWorkOrders;
        return this;
    }

    public void execute(QueueableContext context) {
        try {
            
            getDefaultWorkType();
            optimizeJobs();

            ProcessRelatedWorkOrderRecordsQueueable optimizeJob = new ProcessRelatedWorkOrderRecordsQueueable();
            optimizeJob.setLstOfImpactedWorkOrders(lstOfImpactedWorkOrders);
            optimizeJob.setLstOfContractLineItems(lstOfContractLineItems);
            optimizeJob.setServiceContractRecord(serviceContractRecord);
            optimizeJob.setMapOfWorkOrders(mapOfWorkOrders);
            optimizeJob.setLstOfWorkOrder(lstOfWorkOrder);
            
            if(!Test.isRunningTest())
            	System.enqueueJob(optimizeJob);
            else
                optimizeJob.execute(null);
        
        } catch (Exception ex) {
            serviceContractRecord.Bulk_Order_Generation_Status__c = 'Failed';
            serviceContractRecord.Bulk_Order_Generation_Log__c = 'Failed in Class OptimizeBulkWorkOrdersQueueable. Details : ' + ex.getStackTraceString();
            update serviceContractRecord;
        }
    }

    private void getDefaultWorkType() {
        defaultWorkType = [SELECT Id FROM WorkType WHERE Name =: DEFAULT_WORK_TYPE_NAME];
    }

    private void optimizeJobs() {
        lstOfWorkOrder = new List < WorkOrder > ();
        String description, subject;
        WorkOrder workOrderRecord;
        Decimal totalMinutes = 0;
        DateTime minStartDate;

        for (Date workOrderDate: mapOfWorkOrders.keySet()) {

            if (mapOfWorkOrders.get(workOrderDate).size() > 1) {

                minStartDate = mapOfWorkOrders.get(workOrderDate)[0].StartDate;
                totalMinutes = 0;
                description = '';
                subject = '';

                workOrderRecord = new WorkOrder();

                for (WorkOrder childWorkOrder: mapOfWorkOrders.get(workOrderDate)) {

                    description += childWorkOrder.Description + '-';
                    subject += childWorkOrder.Subject + '-';

                    workOrderRecord.ServiceTerritoryId = childWorkOrder.ServiceTerritoryId;
                    workOrderRecord.ServiceContractId = childWorkOrder.ServiceContractId;
                    workOrderRecord.Pricebook2Id = childWorkOrder.Pricebook2Id;
                    workOrderRecord.PostalCode = childWorkOrder.PostalCode;
                    workOrderRecord.AccountId = childWorkOrder.AccountId;
                    workOrderRecord.Country = childWorkOrder.Country;
                    workOrderRecord.Street = childWorkOrder.Street;
                    workOrderRecord.State = childWorkOrder.State;
                    workOrderRecord.City = childWorkOrder.City;
                    //Prashanth code start
                    workOrderRecord.ContactId = childWorkOrder.ContactId;
                    //Prashanth code ends

                    minStartDate = minStartDate > childWorkOrder.StartDate ? childWorkOrder.StartDate : minStartDate;
                    totalMinutes += childWorkOrder.Duration;
                }

                workOrderRecord.StartDate = minStartDate;

                workOrderRecord.Description = description.length() > 3200 ? description.substring(0, 3199) : description;
                workOrderRecord.EndDate = workOrderRecord.StartDate.addMinutes(Integer.valueOf(totalMinutes));
                workOrderRecord.WorkTypeId = defaultWorkType.isEmpty() ? null : defaultWorkType[0].Id;
                workOrderRecord.Subject = subject.length() > 255 ? subject.substring(0, 254) : subject;
                workOrderRecord.Duration = totalMinutes;

                lstOfWorkOrder.add(workOrderRecord);

            } else {
                lstOfWorkOrder.add(mapOfWorkOrders.get(workOrderDate)[0]);
            }
        }

        if (lstOfWorkOrder.isEmpty())
            return;

        insert lstOfWorkOrder;
    }
}