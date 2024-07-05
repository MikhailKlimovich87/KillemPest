@isTest
public class ServiceContractLITest {
 @isTest static void savePDFQuote() {
        Account testAccount = new Account();
        testAccount.Name='Test Account' ;
        insert testAccount;
        
        Contact cont = new Contact();
		cont.FirstName='Test';
		cont.LastName='Test';
     	cont.email='a@b.com';
     	cont.Phone ='09876543210';
		cont.Accountid= testAccount.id;
		insert cont;
     	
     	/*CGCB__Xero_Connection__c XC = new CGCB__Xero_Connection__c();
     	XC.CGCB__tenantId__c='7add059f-ced1-4fe3-928f-08cfbb6fedca';
     	XC.CGCB__Tenant_Name__c='Pestmanagers Pte Ltd';
     	XC.CGCB__Org_ID__c='B905F78C2EC548338809A3A3B220DE32';
     	insert XC;*/
        
        Opportunity opportunityToCreate = new Opportunity();
        opportunityToCreate.StageName = 'Quotation Signed';
        opportunityToCreate.AccountId = testAccount.Id;
        opportunityToCreate.Name = 'Test Opportunity';
        opportunityToCreate.CloseDate = System.today();
     	opportunityToCreate.Type_of_Service__c='General Pest';
        opportunityToCreate.Revenue_Type__c='New-Contract';
     	opportunityToCreate.Property_Type_Macro__c='Residential';
     	opportunityToCreate.Invitation_Date__c=System.today();
     	opportunityToCreate.Rev_Per_Service__c='800';
     	opportunityToCreate.Problem__c='Ants';
     	opportunityToCreate.Site_Address__c='7-42-2,jdnfsfs';
     	opportunityToCreate.Payment_Terms__c='Per Service';
     	opportunityToCreate.Payment_Type__c='Prepaid';
     	opportunityToCreate.Payment_Status__c='Not Paid';
        insert opportunityToCreate;
        
        Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book 2009', Description = 'Price Book 2009 Products', IsActive = true );
        insert pb;
        Product2 prod = new Product2(Name = 'Testing Product',Product_Type__c='Treatment', Family = 'Best Practices', IsActive = true);
        insert prod;
        List<Pricebook2> standardPbList = [select id, name, isActive from Pricebook2 where IsStandard = true ];
        
        List<PricebookEntry> listPriceBook = new List<PricebookEntry>();
        PricebookEntry pbe = New PricebookEntry ();
        for(Pricebook2 p : standardPbList ){
            
            pbe = new PricebookEntry(Pricebook2Id = p.Id, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            listPriceBook.add(pbe);
        }
        insert listPriceBook;
        
        PriceBookEntry pre = new PriceBookEntry(
         IsActive = true,
         PriceBook2Id = Test.getStandardPricebookId(), 
         Product2Id = prod.Id , 
         UnitPrice=123);
insert pre;
        List<Quote> quoteList = new List<Quote>();
        Quote testQuote = new Quote();
            testQuote.Name = 'Test Quote';
            testQuote.OpportunityId = opportunityToCreate.Id;
            testQuote.Email = 'test@email.com';
            testQuote.Selected_Option__c = 'Option 1';
            testQuote.Pricebook2Id = Test.getStandardPricebookId();
        
        insert testQuote;
        Quote testQuote1 = new Quote();
            testQuote1.Name = 'Test Quote';
            testQuote1.OpportunityId = opportunityToCreate.Id;
            testQuote1.Email = 'test@email.com';
            testQuote1.Pricebook2Id = pbe.Pricebook2Id;        
        insert testQuote1;
        
        List<QuoteLineItem> listval = new   List<QuoteLineItem>();
        Integer Annualvalue = 1000 ;
            QuoteLineItem qutlineitemtest = new QuoteLineItem();
            qutlineitemtest = new QuoteLineItem(QuoteId = testQuote.id ,Killempest_Sales_Price__c =100,
                                                Location__c= 'Ground floor area of the site inclusive of basement (If any)' ,
                                                Product2Id = prod.Id, Quantity = 3.00 ,
                                                GST__c = Null,
                                                Option__c ='Option 2',UnitPrice = 12 , PricebookEntryId = pre.id);
            
         
       insert qutlineitemtest;
        QuoteLineItem qutlineitemtest1 = new QuoteLineItem();
            qutlineitemtest1 = new QuoteLineItem(QuoteId = testQuote.id ,Killempest_Sales_Price__c =100,
                                                Location__c= 'Ground floor area of the site inclusive of basement (If any)' ,
                                                Product2Id = prod.Id, Quantity = 3.00 ,
                                                GST__c = 100,
                                                Option__c ='Option 1',UnitPrice = 12 , PricebookEntryId = pre.id);
            
         
       insert qutlineitemtest1;
        List<ServiceContract> serContList = new List<ServiceContract>();
        ServiceContract serContract = new ServiceContract();
            serContract.Name = 'test Contract';
            serContract.Pricebook2Id =Test.getStandardPricebookId();
            serContract.Quote__c = testQuote.Id;

        insert serContract;
     
     workOrder wo = new workorder();
     wo.AccountId = testAccount.id;
     wo.ServiceContractId = serContract.id;
     wo.ContactId=cont.id;
     insert wo;
     ServiceAppointment SA = new ServiceAppointment();
     SA.ContactId = cont.id;
     SA.ParentRecordId =  wo.id;
     SA.Status = 'None';
     insert SA;
     SA.Status = 'Scheduled';
     update SA;
     SA.Status = 'Dispatched';
     update SA;
     SA.Status = 'In Progress';
     update SA;
     ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            Insert cv;
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = SA.Id;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;
     SA.Status = 'Completed';
     update SA;
     
 }
}