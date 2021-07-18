public class ToolingAPIService {

    public static Map<String, Object> fetchDataFromQuery(String query){
        Map<String, Object> returnMap = new Map<String, Object>();
        try {
            String endpointURL = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v48.0/tooling/query/?q=' + query;
            HTTPResponse res = makeCallout(endpointURL,'GET', '');
            String body = res.getBody();


            returnMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        } catch (Exception e) {
            throw new ApplicationException('Invalid Query');
        }
        return returnMap;
    }

    public static HTTPResponse makeCallout(String endpoint, String method, String body){
        try {
            HttpRequest request;
            HTTPResponse res = new HTTPResponse();
            if(String.isNotBlank(endpoint) && String.isNotBlank(method)){
                request = new HttpRequest();
                request.setHeader('Authorization', 'Bearer ' + URL.getSalesforceBaseUrl().toExternalForm());
                request.setHeader('Content-Type', 'application/json');
                request.setEndpoint(endpoint);
                request.setMethod(method);
                if(String.isNotBlank(body))
                    request.setBody(body);
                Http http = new Http();
                if(!Test.isRunningTest())
                    res = http.send(request);
            }
            return res;   
        } catch (Exception e) {
            throw new ApplicationException('CALLOUT EXCEPTION');
        }
    }

    public static void createAndUpdatePicklistData(Map<String, Object> data, Set<String> picklistRecords, Map<String, String> valueFieldAPIName){
        try {
            if(data != null && picklistRecords != null){
                List<Object> records = (List<Object>)data.get('records');
                Map<String, Object> metaDataMap;
                Map<String, Object> finalMap = new Map<String, Object>();
                String fullName = '';
                String fieldId = '';
                if(records != null){
                    for(Object rec : records){
                        Map<String, Object> recordMap = (Map<String, Object>)rec;
                        if(recordMap != null){
                            if(recordMap.get('FullName') != null){
                                fullName = (String)recordMap.get('FullName');
                            }
                            if(recordMap.get('Id') != null){
                                fieldId = (String)recordMap.get('Id');
                            }
                            if(recordMap.get('Metadata') != null){
                                metaDataMap = (Map<String, Object>) recordMap.get('Metadata');
                                Map<String, Object> valueSet = (Map<String, Object>)metaDataMap.get('valueSet');
                                valueSet.put('valueSettings', (Object) new List<String>());
                                Map<String, Object> valueSetDefinition = (Map<String, Object>)valueSet.get('valueSetDefinition');
                                List<Object> value = (List<Object>)valueSetDefinition.get('value');
                                for(String valueRec: picklistRecords){
                                    String apiName = valueFieldAPIName != null && String.isNotBlank(valueFieldAPIName.get(valueRec)) ? valueFieldAPIName.get(valueRec) : valueRec;
                                    value.add((Object) createValueMap(apiName, valueRec));
                                }
                            }
                        }
                    }
                }
                finalMap.put('Metadata', metaDataMap);
                finalMap.put('FullName', fullName);
                String body = json.serialize(finalMap);
                String endpointURL = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v41.0/tooling/sobjects/CustomField/' + fieldId;
                HTTPResponse res = makeCallout(endpointURL,'PATCH', body);
            }
        } catch (Exception e) {
            throw new ApplicationException(Constants.ERROR_MESSAGE_CALLOUT_EXCEPTION);
        }
    }

    @TestVisible
    private static Map<String, Object> createValueMap(String valueName, String apiName){
        Map<String, Object> valueMap = new Map<String, Object>();
        if(String.isNotBlank(valueName)){
            valueMap.put('valueName', apiName);
            valueMap.put('label', valueName);
            valueMap.put('urls', null);
            valueMap.put('isActive', null);
            valueMap.put('default', false);
            valueMap.put('color', null);
            valueMap.put('description', null);
        }
        return valueMap;
    }

}