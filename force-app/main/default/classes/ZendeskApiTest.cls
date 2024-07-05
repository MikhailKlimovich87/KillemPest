@isTest
public class ZendeskApiTest {

    @IsTest
    static void getAllUsersTestCase1() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceMock());
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
        Assert.areEqual(3, leadsAfterExecuteTestMethod.size(),'The number of leads must be three');
    }

    @IsTest
    static void getAllUsersTestCase2() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceMock());
        Lead testLead = new Lead(
            LastName = 'John Snow',
            Email    = 'john.snow@gmail.com',
            Phone    = '+123456789'
        );
        insert testLead;
        Contact testContact = new Contact(
            LastName = 'Jimmy Ball',
            Email    = 'jimmy.ball@gmail.com',
            Phone    = '+456789123456'
        );
        insert testContact;
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
    static void queryPostRequestTest() {
        Test.setMock(HttpCalloutMock.class, new ZendeskServiceMock());
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

    public class ZendeskServiceMock implements HttpCalloutMock {
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
                            '"phone":"+78945145784",' +
                            '"email":"ben.johns@gmail.com"' +
                        '}' +
                    '],' +
                    '"count": 103' +
                '}');
            res.setStatusCode(200);
            return res;
        }
    }
}