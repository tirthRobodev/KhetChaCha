import unittest
from fastapi.testclient import TestClient
from backend.app import app

class TestAiEngine(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    def test_health_check(self):
        response = self.client.get("/api/v1/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["service"], "KhetChaCha Agri AI Engine")

    def test_speech_intent_gujarati_pest(self):
        response = self.client.post("/api/v1/speech-intent", json={
            "text": "કપાસમાં ગુલાબી ઈયળ માટે કઈ દવા છાંટવી?",
            "language_code": "gu"
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["detected_crop"], "Cotton")
        self.assertEqual(data["intent"], "pest_disease")

    def test_speech_intent_hindi_fertilizer(self):
        response = self.client.post("/api/v1/speech-intent", json={
            "text": "गेहूं में यूरिया और डीएपी खाद कब डालना चाहिए?",
            "language_code": "hi"
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["detected_crop"], "Wheat")
        self.assertEqual(data["intent"], "fertilizer_management")

    def test_chat_endpoint_structure_gujarati(self):
        response = self.client.post("/api/v1/chat", json={
            "query": "મારા કપાસમાં પાન પીળા પડે છે અને સફેદ માખી દેખાય છે, શું કરવું?",
            "language_code": "gu",
            "grounding": {
                "detectedCrop": "Cotton",
                "district": "Rajkot",
                "state": "Gujarat"
            }
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["language_code"], "gu")
        self.assertIn("text", data)
        self.assertIn("sections", data)
        # Check all 6 parts exist
        sections = data["sections"]
        self.assertIn("problemUnderstanding", sections)
        self.assertIn("likelyCauses", sections)
        self.assertIn("recommendedActions", sections)
        self.assertIn("timingAndSteps", sections)
        self.assertIn("precautionsAndDosages", sections)
        self.assertIn("additionalInfoNeeded", sections)

    def test_chat_endpoint_empty_query(self):
        response = self.client.post("/api/v1/chat", json={
            "query": "   ",
            "language_code": "gu"
        })
        self.assertEqual(response.status_code, 400)

if __name__ == "__main__":
    unittest.main()
