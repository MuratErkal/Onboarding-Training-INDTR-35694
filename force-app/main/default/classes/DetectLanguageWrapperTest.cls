@isTest
public class DetectLanguageWrapperTest {
    static testMethod void testParse() {
		String json = '{'+
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
		DetectLanguageWrapper obj = DetectLanguageWrapper.parse(json);
		System.assert(obj != null);
	}
}