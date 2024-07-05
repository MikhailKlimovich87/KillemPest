@isTest
public class cmpServiceConfigureWorkOrdersTracker {
    
    private static ServiceContract testServiceContract;
    private static List < ContractLineItem > testLstOfServiceContractLineItem;
    
    @testSetup static void dataSetup() {
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account' ;
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.StageName = 'Quotation Signed';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.CloseDate = System.today();
        testOpportunity.Type_of_Service__c = 'General Pest';
        testOpportunity.Revenue_Type__c = 'New-Contract';
        testOpportunity.Property_Type_Macro__c = 'Residential';
        testOpportunity.Invitation_Date__c = System.today();
        testOpportunity.Rev_Per_Service__c = '800';
        testOpportunity.Problem__c = 'Ants';
        testOpportunity.Site_Address__c = '7-42-2,jdnfsfs';
        testOpportunity.Payment_Terms__c = 'Per Service';
        testOpportunity.Payment_Type__c = 'Prepaid';
        testOpportunity.Payment_Status__c = 'Not Paid';
        insert testOpportunity;
        
        Product2 testProduct = new Product2(Name = 'Testing Product', Product_Type__c = 'Treatment', Family = 'Best Practices', IsActive = true , ProductCode = '123');
        insert testProduct;
        
        PriceBookEntry testPricebookEntry = new PriceBookEntry(IsActive = true, PriceBook2Id = Test.getStandardPricebookId(), Product2Id = testProduct.Id, UnitPrice = 123);
        insert testPricebookEntry;
        
        Quote testQuote = new Quote();
        testQuote.Name = 'Test Quote';
        testQuote.OpportunityId = testOpportunity.Id;
        testQuote.Email = 'test@email.com';
        testQuote.Selected_Option__c = 'Option 1';
        testQuote.Pricebook2Id = Test.getStandardPricebookId();
        insert testQuote;
        
        QuoteLineItem testQuoteLineItem = new QuoteLineItem(QuoteId = testQuote.id ,Killempest_Sales_Price__c = 100,
                                                            Location__c = 'Ground floor area of the site inclusive of basement (If any)' ,
                                                            Product2Id = testProduct.Id, Quantity = 3.00 ,
                                                            GST__c = Null,
                                                            Option__c ='Option 2',UnitPrice = 12 , PricebookEntryId = testPricebookEntry.id);
        
        
        insert testQuoteLineItem;
        
        testServiceContract = new ServiceContract();
        testServiceContract.Name = 'test Contract';
        testServiceContract.Pricebook2Id = Test.getStandardPricebookId();
        testServiceContract.Quote__c = testQuote.Id;
        testServiceContract.ApprovalStatus = 'Approved';
        
        insert testServiceContract;
        
        ContractLineItem testServiceContractLineItem = new ContractLineItem();
        testServiceContractLineItem.ServiceContractId = testServiceContract.Id;
        testServiceContractLineItem.PricebookEntryId = testPricebookEntry.Id;
        testServiceContractLineItem.Quantity = 1;
        testServiceContractLineItem.UnitPrice = 10;
        testServiceContractLineItem.Frequency1__c = 'Daily';
        testServiceContractLineItem.Every__c = 7;
        testServiceContractLineItem.StartDate = System.today();
        testServiceContractLineItem.EndDate = System.today().addMonths(6);
        testServiceContractLineItem.Suggested_Start_Time__c = Time.newInstance(1, 0, 0, 0);
        testServiceContractLineItem.Month_Factor__c = '2'; 
        testServiceContractLineItem.Month_Day_Factor__c = '2';
        insert testServiceContractLineItem;
        
        testServiceContractLineItem.Id = null;
        insert testServiceContractLineItem;
        
        WorkType testWorkType = new WorkType();
        testWorkType.Name = 'DEFAULT WORK TYPE';
        testWorkType.EstimatedDuration = 60;
        testWorkType.ShouldAutoCreateSvcAppt = true;
        insert testWorkType;
        
    }
    
    static testMethod void testGetBaseInformationService() {
        fetchData();
        
        AuraResponse auraResponse = cmpServiceConfigureWorkOrders.getBaseInformationService(testServiceContract.Id);
        System.assertEquals(true, auraResponse.isSuccess);
    }
    
    static testMethod void testGenerateWorkOrdersServiceDaily() {
        fetchData();
        
        AuraResponse auraResponse = cmpServiceConfigureWorkOrders.generateWorkOrdersService(testServiceContract.Id, JSON.serialize(testLstOfServiceContractLineItem));
        System.assertEquals(true, auraResponse.isSuccess);
    }
    
    static testMethod void testGenerateWorkOrdersServiceWeekly() {
        fetchData();
        
        testLstOfServiceContractLineItem[0].Frequency1__c = 'Weekly';
        testLstOfServiceContractLineItem[0].Week_Days__c = 'Monday;Tuesday';
        
        AuraResponse auraResponse = cmpServiceConfigureWorkOrders.generateWorkOrdersService(testServiceContract.Id, JSON.serialize(testLstOfServiceContractLineItem));
        System.assertEquals(true, auraResponse.isSuccess);
    }
    
    static testMethod void testGenerateWorkOrdersServiceMonthly() {
        fetchData();
        
        testLstOfServiceContractLineItem[0].Frequency1__c = 'Monthly';
        testLstOfServiceContractLineItem[0].Month_Factor__c = '2';
        
        AuraResponse auraResponse = cmpServiceConfigureWorkOrders.generateWorkOrdersService(testServiceContract.Id, JSON.serialize(testLstOfServiceContractLineItem));
        System.assertEquals(true, auraResponse.isSuccess);
    }
    
    static testMethod void testContractToBeRenewedService() {
        fetchData();
        
        AuraResponse auraResponse = cmpServiceConfigureWorkOrders.contractToBeRenewedService(testServiceContract.Id);
        System.assertEquals(true, auraResponse.isSuccess);
    }
    
    private static void fetchData() {
        testServiceContract = [SELECT Id FROM ServiceContract];
        
        testLstOfServiceContractLineItem = [SELECT Id, Product2Id, Product2.Name, Product2.Product_Type__c,
                                            StartDate, Schedule__c, Manpower_mins__c, Product2.Description,
                                            Frequency1__c, EndDate, Every__c, ServiceContractId, Suggested_Start_Time__c,
                                            ServiceContract.StartDate, ServiceContract.EndDate, ServiceContract.Service_Territory__c,
                                            Week_Days__c, Date_of_Month__c, ServiceContract.AccountId, Total_Visits__c,
                                            ServiceContract.Marked_for_Renewal__c, ServiceContract.BillingStreet,
                                            ServiceContract.BillingPostalCode, ServiceContract.BillingState,
                                            ServiceContract.BillingCountry, ServiceContract.BillingCity, ServiceContract.Bulk_Order_Generation_Status__c,
                                            Month_Day_Factor__c, Month_Factor__c, ServiceContract.Pricebook2Id, PriceBookEntryId
                                            FROM ContractLineItem
                                            WHERE ServiceContractId =: testServiceContract.Id ORDER BY Suggested_Start_Time__c ASC];
        
    }
}