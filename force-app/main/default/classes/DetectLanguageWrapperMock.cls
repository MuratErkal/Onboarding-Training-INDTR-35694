global class DetectLanguageWrapperMock implements HttpCalloutMock {
    private final String json = '{'+
    '    \"data\": {'+
    '        \"detections\": ['+
    '            {'+
    '                \"language\": \"en\",'+
    '                \"isReliable\": true,'+
    '                \"confidence\": 13.7'+
    '            }'+
    '        ]'+
    '    }'+
    '}';

    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(json);
        res.setStatusCode(200);
        return res;
    }
}