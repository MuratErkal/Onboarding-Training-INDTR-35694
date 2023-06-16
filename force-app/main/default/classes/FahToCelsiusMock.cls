@isTest
public class FahToCelsiusMock implements WebServiceMock {
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
     
        CelsiusToFah.FahrenheitToCelsiusResponse_element response_x = new CelsiusToFah.FahrenheitToCelsiusResponse_element();
 
        response_x.FahrenheitToCelsiusResult = '1';

        response.put('response_x', response_x);
    }
}