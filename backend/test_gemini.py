"""Quick test to list available Gemini models for your API key."""
import google.generativeai as genai

genai.configure(api_key="AIzaSyDSYqwUMtwr09gbqd6bAGnPkwCHRuGtbss")

print("=== Available Embedding Models ===")
for m in genai.list_models():
    if "embed" in m.name.lower() or "embedding" in m.name.lower():
        print(f"  {m.name} -- supports: {m.supported_generation_methods}")

print("\n=== All Models ===")
for m in genai.list_models():
    print(f"  {m.name} -- {m.supported_generation_methods}")
