public class DetectLanguageWrapper {
    public Data data;

	public class Data {
		public List<Detections> detections;
	}

	public class Detections {
		public String language;
		public Boolean isReliable;
		public Double confidence;
	}

	
	public static DetectLanguageWrapper parse(String json) {
		return (DetectLanguageWrapper) System.JSON.deserialize(json, DetectLanguageWrapper.class);
	}
}