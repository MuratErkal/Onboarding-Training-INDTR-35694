@isTest
private class OSF_WeatherUnitConverterTest {
    @isTest static void testCelToFah() {
        Test.setMock(WebServiceMock.class, new CelsiusToFahMock());

        List<String> fahrenheit = OSF_WeatherUnitConverter.getFahrenheit(new List<String>{'14'});

        System.assertEquals(new List<String>{'1'}, fahrenheit);
    }

    @isTest static void testFahToCel() {
        Test.setMock(WebServiceMock.class, new FahToCelsiusMock());

        List<String> celsius = OSF_WeatherUnitConverter.getCelsius(new List<String>{'14'});

        System.assertEquals(new List<String>{'1'}, celsius);
    }
}