public without sharing class ZendeskApiHandler {
    private static final String ZENDESK_API_ENDPOINT = 'callout:ZendeskApi';

    /**
     * Sends a request to the Zendesk API using the provided endpoint and parameters
     * @param endpoint The API endpoint to call, e.g. "charges"
     * @param method The HTTP method to use, e.g. "POST", "GET", "DELETE", "PUT", etc.
     * @param params A map of request parameters to send
     * @param apiKey The API key to use for authentication
     * @return The response from the API as a string
     */

    public static ZendeskAPIResponseWrapper requestZendeskApi(
        String endpoint,
        String method,
        Map<String, String> params
    ) {
        HttpRequest httpRequest = new HttpRequest();
        String apiUrl = ZENDESK_API_ENDPOINT + '/v2/' + endpoint;

        if (method == 'GET' && params != null && !params.isEmpty()) {
            apiUrl += '?' + generateQueryString(params);
        }

        httpRequest.setEndpoint(apiUrl);
        httpRequest.setMethod(method);

        if (method == 'POST' || method == 'PUT') {
            String requestBody = '';

            if (params != null && !params.isEmpty()) {
                requestBody = generateRequestBody(params);
            }

            httpRequest.setHeader('Content-Type', 'application/json; charset=utf-8');
            httpRequest.setBody(requestBody);
        }
        ZendeskAPIResponseWrapper resp = new ZendeskAPIResponseWrapper();
        Http http = new Http();
        HttpResponse httpResponse = http.send(httpRequest);

        if (httpResponse.getStatusCode() >= 200 && httpResponse.getStatusCode() < 300) {
            resp.responseBody = httpResponse.getBody();
        } else {
            resp.isError = true;
            resp.errorMessage = parseErrorCodes(httpResponse.getBody());
        }
        return resp;
    }

    /**
     * Generates a query string for a GET request
     *
     * @param params A map of request parameters to include in the query string
     * @return The query string as a string
     */

    private static String generateQueryString(Map<String, String> params) {
        List<String> paramList = new List<String>();
        for (String key : params.keySet()) {
            paramList.add(key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }

        return String.join(paramList, '&');
    }

    /**
     * Generates the request body for a POST or PUT request
     *
     * @param params A map of request parameters to include in the body
     * @return The request body as a string
     */

    private static String generateRequestBody(Map<String, String> params) {
        List<String> paramList = new List<String>();
        for (String key : params.keySet()) {
            paramList.add(key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }

        return String.join(paramList, '&');
    }

    public static String parseErrorCodes(String responseBody) {
        Map<String, Object> errors = new Map<String, Object>();

        if (responseBody != null && responseBody.trim().length() > 0) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            errors = (Map<String, Object>) responseData.get('error');
            System.debug('ERRORS: ' + errors.get('message'));
        }

        return String.valueOf(errors.get('message'));
    }

    public class ZendeskAPIResponseWrapper {
        public String responseBody;
        public String errorMessage;
        public Boolean isError;
    }
}