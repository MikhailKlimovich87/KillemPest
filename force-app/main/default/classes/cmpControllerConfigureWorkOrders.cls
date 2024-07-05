public without sharing class cmpControllerConfigureWorkOrders {
    private static final String RENEW_ERROR = 'This reconfiguration increases the number of visits. Please renew the Contract';
    private static final String DEFAULT_WORK_TYPE_NAME = 'DEFAULT WORK TYPE';
    private static final String SUCCESS_LABEL = 'Success';
    private static final String ERROR_LABEL = 'Error';

    private static final Map<String, Integer> mapOfWeekDays = new Map<String, Integer>{
        'Sunday' => 1,
        'Monday' => 2,
        'Tuesday' => 3,
        'Wednesday' => 4,
        'Thursday' => 5,
        'Friday' => 6,
        'Saturday' => 7
    };

    private List<ContractLineItem> lstOfContractLineItems;
    private Map<Date, WorkOrder> mapOfInsertedWorkOrders;
    private Map<Date, List<WorkOrder>> mapOfWorkOrders;
    private List<WorkOrder> lstOfImpactedWorkOrders;
    private Map<Id, WorkOrder> mapOfIdVsWorkOrder;
    private ServiceContract serviceContractRecord;
    private List<WorkType> defaultWorkType;
    private List<WorkOrder> lstOfWorkOrder;
    private Integer reconfiguredServiceCount;
    private Boolean isMarkedForRenewal;
    private String contractRecordId;
    private JSONGenerator gen;

    public cmpControllerConfigureWorkOrders(String recordId) {
        contractRecordId = recordId;
    }

    public cmpControllerConfigureWorkOrders(String recordId, List<ContractLineItem> lstOfContractLineItems) {
        this.lstOfContractLineItems = lstOfContractLineItems;
        contractRecordId = recordId;
    }

    public AuraResponse getBaseInformation() {
        try {
            getContractLineItems();
            setJSON();
        } catch (Exception ex) {
            return new AuraResponse(false, ex.getMessage(), ERROR_LABEL);
        }

        return new AuraResponse(true, SUCCESS_LABEL, gen.getAsString());
    }

    public AuraResponse contractToBeRenewed() {
        Savepoint sp = Database.setSavepoint();

        try {
            getImpactedWorkOrders();

            delete lstOfImpactedWorkOrders;
            update new ServiceContract(Id = contractRecordId, Marked_for_Renewal__c = true);

            setJSON();
        } catch (Exception ex) {
            Database.Rollback(sp);
            return new AuraResponse(false, ex.getMessage(), ERROR_LABEL);
        }

        return new AuraResponse(true, SUCCESS_LABEL, gen.getAsString());
    }

    public AuraResponse generateWorkOrders() {
        Savepoint sp = Database.setSavepoint();

        try {
            getImpactedWorkOrders();
            getContractRecord();
            getDefaultWorkType();
            createSampledWorkOrders();

            /*if (serviceContractRecord.Total_Visits__c != 0 && reconfiguredServiceCount > serviceContractRecord.Total_Visits__c)
             return new AuraResponse(false, RENEW_ERROR, ERROR_LABEL);*/

            invokeQueueableProcess();
            setJSON();
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getLineNumber());
            Database.Rollback(sp);
            return new AuraResponse(false, ex.getMessage(), ERROR_LABEL);
        }

        return new AuraResponse(true, SUCCESS_LABEL, gen.getAsString());
    }

    private void invokeQueueableProcess() {
        serviceContractRecord.Bulk_Order_Generation_Status__c = 'In Progress';
        serviceContractRecord.Bulk_Order_Generation_Log__c = '';
        update serviceContractRecord;

        OptimizeBulkWorkOrdersQueueable optimizeJob = new OptimizeBulkWorkOrdersQueueable();
        optimizeJob.setLstOfImpactedWorkOrders(lstOfImpactedWorkOrders);
        optimizeJob.setLstOfContractLineItems(lstOfContractLineItems);
        optimizeJob.setServiceContractRecord(serviceContractRecord);
        optimizeJob.setMapOfWorkOrders(mapOfWorkOrders);

        System.enqueueJob(optimizeJob);
    }

    private void getImpactedWorkOrders() {
        lstOfImpactedWorkOrders = [
            SELECT Id
            FROM WorkOrder
            WHERE Status = 'New' AND StartDate > TODAY AND ServiceContractId = :contractRecordId
        ];
    }

    private void getDefaultWorkType() {
        defaultWorkType = [SELECT Id FROM WorkType WHERE Name = :DEFAULT_WORK_TYPE_NAME];
    }

    private void getContractRecord() {
        serviceContractRecord = [
            SELECT
                Id,
                StartDate,
                ContactId,
                EndDate,
                Total_Visits__c,
                Marked_for_Renewal__c,
                Service_Territory__c,
                Additional_Emails__c,
                PMP_Notes__c
            FROM ServiceContract
            WHERE Id = :contractRecordId
        ];
        system.debug('serviceContractRecord.ContactId::' + serviceContractRecord.ContactId);
    }

    private void createSampledWorkOrders() {
        mapOfWorkOrders = new Map<Date, List<WorkOrder>>();
        DateTime iterationDateTime, iterationDateTimeUTC;
        reconfiguredServiceCount = 0;
        Date iterationDate, endDate;

        for (ContractLineItem lineItem : lstOfContractLineItems) {
            iterationDate = lineItem.StartDate != null ? lineItem.StartDate : serviceContractRecord.StartDate;
            iterationDate = iterationDate > System.today() ? iterationDate : System.today();
            iterationDateTime = lineItem.Suggested_Start_Time__c != null
                ? DateTime.newInstance(iterationDate, lineItem.Suggested_Start_Time__c)
                : iterationDate;
            endDate = lineItem.EndDate != null ? lineItem.EndDate : serviceContractRecord.EndDate;

            if (lineItem.Frequency1__c == 'Daily') {
                lineItem.Total_Visits__c = getWorkOrderForDaysFrequency(lineItem, iterationDateTime, endDate);
            } else if (lineItem.Frequency1__c == 'Weekly') {
                lineItem.Total_Visits__c = getWorkOrderForWeeksFrequency(lineItem, iterationDateTime, endDate);
            } else if (lineItem.Frequency1__c == 'Monthly') {
                lineItem.Total_Visits__c = getWorkOrderForMonthsFrequency(lineItem, iterationDateTime, endDate);
            }

            //iterationDateTimeUTC = iterationDateTime.addSeconds(Timezone.getTimeZone('UTC').getOffset(iterationDateTime) / 1000);
            //lineItem.Suggested_Start_Time__c = Time.newInstance(iterationDateTimeUTC.hour(), iterationDateTimeUTC.minute(), iterationDateTimeUTC.second(), iterationDateTimeUTC.millisecond());
            reconfiguredServiceCount += Integer.valueOf(lineItem.Total_Visits__c);
        }
    }

    private Integer getWorkOrderForDaysFrequency(ContractLineItem lineItem, DateTime iterationDateTime, Date endDate) {
        if (lineItem.Every__c == null)
            return 0;

        iterationDateTime = iterationDateTime.addDays((Integer) lineItem.Every__c);
        Integer totalVisits = 0;

        while (endDate > Date.valueOf(iterationDateTime)) {
            totalVisits = addGeneratedWorkOrder(iterationDateTime, lineItem, endDate, totalVisits);
            iterationDateTime = iterationDateTime.addDays((Integer) lineItem.Every__c);
        }

        return totalVisits;
    }

    private Integer getWorkOrderForWeeksFrequency(ContractLineItem lineItem, DateTime iterationDateTime, Date endDate) {
        if (lineItem.Week_Days__c == null || lineItem.Every__c == null)
            return 0;

        Set<String> setOfWeekDays = new Set<String>(lineItem.Week_Days__c.split(';'));
        Integer totalVisits = 0, weekDayCounter;
        Date minStartDate = Date.valueOf(iterationDateTime);
        DateTime weekStartDate;
        System.debug(iterationDateTime);
        System.debug(lineItem.Suggested_Start_Time__c);
        while (endDate > Date.valueOf(iterationDateTime) || endDate > Date.valueOf(iterationDateTime).toStartofWeek()) {
            weekStartDate = DateTime.newInstance(
                Date.valueOf(iterationDateTime).toStartofWeek(),
                lineItem.Suggested_Start_Time__c
            );
            weekDayCounter = 1;

            while (weekDayCounter <= 7) {
                if (
                    Date.valueOf(weekStartDate) >= minStartDate &&
                    Date.valueOf(weekStartDate) <= endDate &&
                    setOfWeekDays.contains(weekStartDate.format('EEEE'))
                ) {
                    totalVisits = addGeneratedWorkOrder(weekStartDate, lineItem, endDate, totalVisits);
                }

                weekStartDate = weekStartDate.addDays(1);
                weekDayCounter++;
            }

            iterationDateTime = iterationDateTime.addDays((Integer) (lineItem.Every__c * 7));
        }

        return totalVisits;
    }

    private Integer getWorkOrderForMonthsFrequency(
        ContractLineItem lineItem,
        DateTime iterationDateTime,
        Date endDate
    ) {
        if (lineItem.Every__c == null)
            return 0;

        DateTime nextIterationDateTime;
        Date nextIterationDate;
        Integer totalVisits = 0;

        if (lineItem.Date_of_Month__c != null) {
            while (endDate > iterationDateTime) {
                nextIterationDate = Date.newinstance(
                    iterationDateTime.year(),
                    iterationDateTime.month(),
                    (Integer) lineItem.Date_of_Month__c
                );
                nextIterationDateTime = lineItem.Suggested_Start_Time__c != null
                    ? DateTime.newinstance(nextIterationDate, lineItem.Suggested_Start_Time__c)
                    : nextIterationDate;
                totalVisits = addGeneratedWorkOrder(nextIterationDateTime, lineItem, endDate, totalVisits);
                iterationDateTime = iterationDateTime.addMonths((Integer) lineItem.Every__c);
            }
        } else if (lineItem.Month_Factor__c != null && lineItem.Month_Day_Factor__c != null) {
            //Addedd to offset the month
            iterationDateTime = iterationDateTime.addMonths(-Integer.valueOf(lineItem.Month_Factor__c));

            Integer nextServiceDay = iterationDateTime.day();

            while (endDate > iterationDateTime) {
                nextServiceDay = getNextDate(
                    iterationDateTime.year(),
                    iterationDateTime.month(),
                    iterationDateTime.day(),
                    mapOfWeekDays.get(((DateTime) iterationDateTime).format('EEEE')),
                    Integer.valueOf(lineItem.Month_Day_Factor__c),
                    Integer.ValueOf(lineItem.Month_Factor__c)
                );
                nextIterationDate = Date.newinstance(
                    iterationDateTime.year(),
                    iterationDateTime.month() + 1,
                    (Integer) nextServiceDay
                );
                nextIterationDateTime = lineItem.Suggested_Start_Time__c != null
                    ? DateTime.newinstance(nextIterationDate, lineItem.Suggested_Start_Time__c)
                    : nextIterationDate;
                totalVisits = addGeneratedWorkOrder(nextIterationDateTime, lineItem, endDate, totalVisits);
                iterationDateTime = iterationDateTime.addMonths((Integer) lineItem.Every__c);
            }
        }

        return totalVisits;
    }

    private Integer addGeneratedWorkOrder(
        DateTime appointmentDate,
        ContractLineItem lineItem,
        Date endDate,
        Integer totalVisits
    ) {
        WorkOrder generatedWO = getWorkOrder(appointmentDate, lineItem);

        if (generatedWO.StartDate < endDate && generatedWO.StartDate > System.today()) {
            if (!mapOfWorkOrders.containsKey(Date.valueOf(generatedWO.startDate)))
                mapOfWorkOrders.put(Date.valueOf(generatedWO.startDate), new List<WorkOrder>());

            mapOfWorkOrders.get(Date.valueOf(generatedWO.startDate)).add(generatedWO);
            totalVisits++;
        }

        return totalVisits;
    }

    private Integer getNextDate(
        Integer year,
        Integer month,
        Integer dayOfMonth,
        Integer dayOfWeek,
        Integer targetDayOfWeek,
        Integer occurrenceOfDayOfWeek
    ) {
        Integer monthMarchIs1 = (Math.mod((month + 9), 12)) + 1;
        Integer isMonthFeb = monthMarchIs1 / 12;
        Integer isYearDivBy4 = (1 - (Math.mod(year, 4) + 3) / 4);
        Integer isYearDivBy100 = (1 - (Math.mod(year, 100) + 99) / 100);
        Integer isYearDivBy400 = (1 - (Math.mod(year, 400) + 399) / 400);
        Integer isLeapYear = isYearDivBy4 * (1 - isYearDivBy100) + isYearDivBy400;
        Integer daysInMonth =
            28 +
            Math.mod((month + month / 8), 2) +
            Math.mod(2, month) +
            2 * (1 / month) +
            isMonthFeb * isLeapYear;
        Integer daysToFirst = daysInMonth - dayOfMonth + 1;
        Integer weekdayOfFirst = Math.mod((dayOfWeek + daysToFirst), 7);
        Integer dateOfTargetWeekday = Math.mod((targetDayOfWeek - weekdayOfFirst + 7), 7) + 1;
        Integer dateOfTarget = dateOfTargetWeekday + (occurrenceOfDayOfWeek - 1) * 7;

        return dateOfTarget;
    }

    private WorkOrder getWorkOrder(DateTime appointmentDate, ContractLineItem lineItem) {
        WorkOrder record = new WorkOrder();
        record.StartDate = appointmentDate;
        record.EndDate = lineItem.Manpower_mins__c != null
            ? record.StartDate.addMinutes(Integer.valueOf(lineItem.Manpower_mins__c))
            : record.StartDate.addMinutes(30);
        record.Duration = lineItem.Manpower_mins__c != null ? lineItem.Manpower_mins__c : 30;
        record.WorkTypeId = defaultWorkType.isEmpty() ? null : defaultWorkType[0].Id;
        record.ServiceTerritoryId = serviceContractRecord.Service_Territory__c;
        record.PriceBookEntryId_For_Dev__c = lineItem.PriceBookEntryId;
        record.PostalCode = lineItem.ServiceContract.ShippingPostalCode;
        record.Pricebook2Id = lineItem.ServiceContract.Pricebook2Id;
        record.Description = 'Service for ' + lineItem.Product2.Name;
        record.Description += lineItem.Product2.Description != null
            ? ' ; Details : ' + lineItem.Product2.Description
            : '';
        record.Subject = 'Service for ' + lineItem.Product2.Name;
        record.Country = lineItem.ServiceContract.ShippingCountry;
        record.Street = lineItem.ServiceContract.ShippingStreet;
        record.AccountId = lineItem.ServiceContract.AccountId;
        record.ServiceContractId = lineItem.ServiceContractId;
        record.State = lineItem.ServiceContract.ShippingState;
        record.City = lineItem.ServiceContract.ShippingCity;
        record.ContactId = lineItem.ServiceContract.ContactId;
        record.Location_Dev__c = lineItem.Location__c;
        record.Frequency_Dev__c = lineItem.Frequency__c;
        record.Other_Location__c = lineitem.Other_Location__c;
        // record.Additional_Email_1__c = serviceContractRecord.Additional_Email_1__c;
        // record.Additional_Email_2__c = serviceContractRecord.Additional_Email_2__c;
        record.Additional_Emails__c = serviceContractRecord.Additional_Emails__c;
        record.PMP_Notes__c = serviceContractRecord.PMP_Notes__c;
        return record;
    }

    private void getContractLineItems() {
        lstOfContractLineItems = [
            SELECT
                Id,
                Product2Id,
                Product2.Name,
                Product2.Product_Type__c,
                StartDate,
                Schedule__c,
                Manpower_mins__c,
                Product2.Description,
                Frequency1__c,
                EndDate,
                Every__c,
                ServiceContractId,
                Suggested_Start_Time__c,
                ServiceContract.StartDate,
                ServiceContract.EndDate,
                ServiceContract.Service_Territory__c,
                Week_Days__c,
                Date_of_Month__c,
                ServiceContract.AccountId,
                Total_Visits__c,
                ServiceContract.Marked_for_Renewal__c,
                ServiceContract.BillingStreet,
                ServiceContract.BillingPostalCode,
                ServiceContract.BillingState,
                ServiceContract.BillingCountry,
                ServiceContract.BillingCity,
                ServiceContract.Bulk_Order_Generation_Status__c,
                Month_Day_Factor__c,
                Month_Factor__c,
                ServiceContract.Pricebook2Id,
                PriceBookEntryId,
                ServiceContract.ContactId,
                Location__c,
                Other_Location__c,
                Frequency__c,
                ServiceContract.ShippingStreet,
                ServiceContract.ShippingPostalCode,
                ServiceContract.ShippingState,
                ServiceContract.ShippingCountry,
                ServiceContract.ShippingCity,
                ServiceContract.Additional_Emails__c,
                ServiceContract.PMP_Notes__c
            FROM ContractLineItem
            WHERE ServiceContractId = :contractRecordId
            ORDER BY Suggested_Start_Time__c ASC
        ];

        isMarkedForRenewal = lstOfContractLineItems.isEmpty()
            ? false
            : lstOfContractLineItems[0].ServiceContract.Marked_for_Renewal__c;
        serviceContractRecord = lstOfContractLineItems.isEmpty()
            ? new ServiceContract()
            : lstOfContractLineItems[0].ServiceContract;
    }
    public void setJSON() {
        gen = JSON.createGenerator(true);
        gen.writeStartObject();

        if (lstOfContractLineItems != null) {
            gen.writeObjectField('lstOfContractLineItems', lstOfContractLineItems);
        }

        if (isMarkedForRenewal != null) {
            gen.writeObjectField('isMarkedForRenewal', isMarkedForRenewal);
        }

        if (serviceContractRecord != null) {
            gen.writeObjectField('serviceContractRecord', serviceContractRecord);
        }

        gen.writeEndObject();
    }
}