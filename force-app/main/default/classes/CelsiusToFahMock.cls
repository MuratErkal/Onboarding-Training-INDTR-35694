@isTest
public class CelsiusToFahMock implements WebServiceMock {
    public void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
     
        CelsiusToFah.CelsiusToFahrenheitResponse_element response_x = new CelsiusToFah.CelsiusToFahrenheitResponse_element();
 
        response_x.CelsiusToFahrenheitResult = '1';

        response.put('response_x', response_x);
    }
}