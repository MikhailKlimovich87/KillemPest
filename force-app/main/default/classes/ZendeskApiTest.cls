@isTest
public class ZendeskApiTest {

    @IsTest
    static void getAllUsersTestCase1() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceSuccessMock());
        List<Lead> leadsBeforeExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areEqual(0, leadsBeforeExecuteTestMethod.size(), 'List of leads is not empty');
        Test.startTest();
        ZendeskApiService.getAllUsers();
        Test.stopTest();
        List<Lead> leadsAfterExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areNotEqual(0, leadsAfterExecuteTestMethod.size(), 'The leads must be appear');
        Assert.areNotEqual(
            leadsAfterExecuteTestMethod.size(),
            leadsBeforeExecuteTestMethod.size(),
            'The size of lead\'s list mustn\'t be the same after execute test method'
        );
        Assert.areEqual(4, leadsAfterExecuteTestMethod.size(),'The number of leads must be four');
    }

    @IsTest
    static void getAllUsersTestCase2() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceSuccessMock());
        Lead testLead = new Lead(
            LastName = 'John Snow',
            Email    = 'john.snow@gmail.com',
            Phone    = '+123456789'
        );
        insert testLead;
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            LastName = 'Jimmy Ball',
            Email    = 'jimmy.ball@gmail.com',
            Phone    = '+456789123456'
        ));
        testContacts.add(new Contact(
            LastName = 'Jilly Kean',
            Phone    = '+7845124578'
        ));
        insert testContacts;
        List<Lead> leadsBeforeExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areEqual(1, leadsBeforeExecuteTestMethod.size(), 'Only one leads must be before execute test method');
        Test.startTest();
        ZendeskApiService.getAllUsers();
        Test.stopTest();
        List<Lead> leadsAfterExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areNotEqual(
            leadsAfterExecuteTestMethod.size(),
            leadsBeforeExecuteTestMethod.size(),
            'The size of lead\'s list mustn\'t be the same after execute test method'
        );
        Assert.areNotEqual(0, leadsAfterExecuteTestMethod.size(), 'The leads must be appear');
        Assert.areEqual(2, leadsAfterExecuteTestMethod.size(),'The number of leads must be two');
    }

    @IsTest
    static void getAllUsersTestCase3() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceErrorMock());
        List<Lead> leadsBeforeExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areEqual(0, leadsBeforeExecuteTestMethod.size(), 'List of leads is not empty');
        Test.startTest();
        ZendeskApiService.getAllUsers();
        Test.stopTest();
        List<Lead> leadsAfterExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areEqual(0, leadsAfterExecuteTestMethod.size(), 'The leads must be appear');
        Assert.areEqual(
            leadsAfterExecuteTestMethod.size(),
            leadsBeforeExecuteTestMethod.size(),
            'The size of lead\'s list must be the same after execute test method'
        );
        Assert.areEqual(0, leadsAfterExecuteTestMethod.size(),'The number of leads must be zero');
    }

    @IsTest
    static void getAllUsersTestCase4() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceEmptyUserMock());
        List<Lead> leadsBeforeExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areEqual(0, leadsBeforeExecuteTestMethod.size(), 'List of leads is not empty');
        Test.startTest();
        ZendeskApiService.getAllUsers();
        Test.stopTest();
        List<Lead> leadsAfterExecuteTestMethod = [
            SELECT Id
            FROM Lead
        ];
        Assert.areEqual(0, leadsAfterExecuteTestMethod.size(), 'The leads must be appear');
        Assert.areEqual(
            leadsAfterExecuteTestMethod.size(),
            leadsBeforeExecuteTestMethod.size(),
            'The size of lead\'s list must be the same after execute test method'
        );
        Assert.areEqual(0, leadsAfterExecuteTestMethod.size(),'The number of leads must be zero');
    }

    @IsTest
    static void queryPostRequestTest() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceSuccessMock());
        Test.startTest();
        ZendeskApiHandler.ZendeskAPIResponseWrapper resultWrapper = ZendeskApiHandler.requestZendeskApi(
            'user',
            'POST',
            new Map<String, String>{
                'name' => 'Ben Johns',
                'email' => 'ben.johns@gmail.com',
                'phone' => '+78945145784'
            }
        );
        Test.stopTest();
        Assert.areEqual(null, resultWrapper.isError);
        Assert.areEqual(null, resultWrapper.errorMessage);
        Assert.areNotEqual(null, resultWrapper.responseBody);
    }

    @IsTest
    static void querySuccessPostRequestTest() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceSuccessMock());
        Test.startTest();
        ZendeskApiHandler.ZendeskAPIResponseWrapper resultWrapper = ZendeskApiHandler.requestZendeskApi(
            'user',
            'POST',
            new Map<String, String>{
                'name' => 'Ben Johns',
                'email' => 'ben.johns@gmail.com',
                'phone' => '+78945145784'
            }
        );
        Test.stopTest();
        Assert.areEqual(null, resultWrapper.isError);
        Assert.areEqual(null, resultWrapper.errorMessage);
        Assert.areNotEqual(null, resultWrapper.responseBody);
    }

    @IsTest
    static void queryErrorPostRequestTest() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceErrorMock());
        Test.startTest();
        ZendeskApiHandler.ZendeskAPIResponseWrapper resultWrapper = ZendeskApiHandler.requestZendeskApi(
            'user',
            'POST',
            new Map<String, String>{
                'name' => 'Ben Johns',
                'email' => 'ben.johns@gmail.com',
                'phone' => '+78945145784'
            }
        );
        Test.stopTest();
        Assert.areEqual(true, resultWrapper.isError);
        Assert.areEqual('Error test message', resultWrapper.errorMessage);
        Assert.areEqual(null, resultWrapper.responseBody);
    }

    public class ZendeskServiceSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{' +
                    '"users": [ ' +
                        '{' +
                            '"name":"John Snow", ' +
                            '"phone":"+123456789",' +
                            '"email":null' +
                        '},' +
                        '{' +
                            '"name":"Jimmy Ball", ' +
                            '"phone":"+456789123456",' +
                            '"email":"jimmy.ball@gmail.com"' +
                        '},' +
                        '{' +
                            '"name":"Ben Johns", ' +
                            '"phone":null,' +
                            '"email":"ben.johns@gmail.com"' +
                        '},' +
                        '{' +
                            '"name":"Jilly Kean", ' +
                            '"phone":"+7845124578",' +
                            '"email":null' +
                        '}' +
                    '],' +
                    '"count": 103' +
                '}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class ZendeskServiceErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{' +
                    '"error": {' +
                        '"message":"Error test message" ' +
                    '}' +
                '}');
            res.setStatusCode(400);
            return res;
        }
    }

    public class ZendeskServiceEmptyUserMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{' +
                    '"users": [],' +
                    '"count": 0' +
                '}');
            res.setStatusCode(200);
            return res;
        }
    }
}