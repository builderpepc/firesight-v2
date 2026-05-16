"""Download pre-converted model weights from Cactus-Compute HuggingFace.

Usage::

 from src.downloads import ensure\_model
 weights\_dir = ensure\_model("openai/whisper-tiny")
"""
import shutil
from pathlib import Path

\_PROJECT\_ROOT = Path(\_\_file\_\_).resolve().parent.parent.parent

def get\_model\_dir\_name(model\_id: str) -> str:
 """Convert HuggingFace model ID to local directory name."""
 return model\_id.split("/")\[-1\].lower()

def get\_weights\_dir(model\_id: str) -> Path:
 """Return \`\`/weights/\`\`."""
 if "silero-vad" in model\_id.lower():
 return \_PROJECT\_ROOT / "weights" / "silero-vad"
 return \_PROJECT\_ROOT / "weights" / get\_model\_dir\_name(model\_id)

def download\_from\_hf(model\_id: str, weights\_dir: Path, precision: str = "INT4") -> bool:
 """Download pre-converted weights from Cactus-Compute HuggingFace.

 Returns True on success, False if the model is unavailable or download fails.
 """
 try:
 from huggingface\_hub import hf\_hub\_download, list\_repo\_files
 import zipfile
 except ImportError:
 print("huggingface\_hub not installed — run: pip install huggingface\_hub")
 return False

 model\_name = get\_model\_dir\_name(model\_id)
 repo\_id = f"Cactus-Compute/{model\_id.split('/')\[-1\]}"

 try:
 precision\_lower = precision.lower()
 apple\_zip = f"{model\_name}-{precision\_lower}-apple.zip"
 standard\_zip = f"{model\_name}-{precision\_lower}.zip"

 repo\_files = list\_repo\_files(repo\_id, repo\_type="model")

 zip\_file = None
 if f"weights/{apple\_zip}" in repo\_files:
 zip\_file = apple\_zip
 elif f"weights/{standard\_zip}" in repo\_files:
 zip\_file = standard\_zip
 else:
 print(f"Pre-converted model not found in {repo\_id}")
 return False

 print(f"Downloading {repo\_id}/{zip\_file} ...")

 zip\_path = hf\_hub\_download(
 repo\_id=repo\_id,
 filename=f"weights/{zip\_file}",
 repo\_type="model",
 )

 weights\_dir.mkdir(parents=True, exist\_ok=True)

 print("Extracting model weights...")
 with zipfile.ZipFile(zip\_path, "r") as zip\_ref:
 zip\_ref.extractall(weights\_dir)

 if not (weights\_dir / "config.txt").exists():
 print(f"Error: downloaded model is missing config.txt")
 if weights\_dir.exists():
 shutil.rmtree(weights\_dir)
 return False

 config\_path = weights\_dir / "config.txt"
 config\_text = config\_path.read\_text()
 if "quantization=" not in config\_text:
 with open(config\_path, "a") as f:
 f.write(f"quantization={precision}\\n")

 print(f"Model ready at {weights\_dir}")
 return True

 except Exception as exc:
 print(f"Download failed: {exc}")
 if weights\_dir.exists():
 shutil.rmtree(weights\_dir)
 return False

def ensure\_model(model\_id: str, precision: str = "INT4") -> Path:
 """Return the weights directory, downloading if necessary.

 Raises \`\`RuntimeError\`\` if the model cannot be obtained.
 """
 weights\_dir = get\_weights\_dir(model\_id)
 if (weights\_dir / "config.txt").exists():
 return weights\_dir
 if not download\_from\_hf(model\_id, weights\_dir, precision):
 raise RuntimeError(f"Could not download model {model\_id}")
 return weights\_dir