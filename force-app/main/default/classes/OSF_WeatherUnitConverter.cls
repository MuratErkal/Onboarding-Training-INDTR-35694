public class OSF_WeatherUnitConverter {

    @InvocableMethod(callout=true label='Convert Celsius To Fahrenheit' description='Uses SOAP API') 
    public static List<String> getFahrenheit(List<String> celsius) {
        CelsiusToFah.TempConvertSoap converter = new CelsiusToFah.TempConvertSoap();

        String fahrenheit = converter.CelsiusToFahrenheit(celsius[0]);

        List<String> result = new List<String>{fahrenheit};

        return result;
    }

    // @InvocableMethod(callout=true label='Convert Fahrenheit To Celsius' description='Uses SOAP API') 
    public static List<String> getCelsius(List<String> fahrenheit) {
        CelsiusToFah.TempConvertSoap converter = new CelsiusToFah.TempConvertSoap();

        String celsius = converter.FahrenheitToCelsius(fahrenheit[0]);

        List<String> result = new List<String>{celsius};

        return result;
    }
}