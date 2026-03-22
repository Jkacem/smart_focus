import google.generativeai as genai
genai.configure(api_key="AIzaSyDSYqwUMtwr09gbqd6bAGnPkwCHRuGtbss")
print("\nAVAILABLE MODELS:")
for m in genai.list_models():
    if "generateContent" in m.supported_generation_methods:
        print(f"- {m.name}")
