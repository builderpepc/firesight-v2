#!/usr/bin/env python3
import sys
import os
import argparse
import re
import json
import subprocess
import shutil
import platform
from pathlib import Path

SCRIPT\_DIR = Path(\_\_file\_\_).resolve().parent

def \_looks\_like\_project\_root(path: Path) -> bool:
 return (
 (path / "python" / "src" / "cli.py").exists()
 and (path / "cactus").exists()
 and (path / "tests").exists()
 )

def \_resolve\_project\_root() -> Path:
 # Optional explicit override for environments running from installed packages.
 env\_root = os.getenv("CACTUS\_PROJECT\_ROOT", "").strip()
 if env\_root:
 candidate = Path(env\_root).expanduser().resolve()
 if \_looks\_like\_project\_root(candidate):
 return candidate

 # Prefer the repo containing this CLI module.
 module\_root = SCRIPT\_DIR.parent.parent
 if \_looks\_like\_project\_root(module\_root):
 return module\_root

 # Fallback: repo containing current working directory.
 cwd = Path.cwd().resolve()
 for candidate in \[cwd, \*cwd.parents\]:
 if \_looks\_like\_project\_root(candidate):
 return candidate

 # Final fallback for unusual layouts.
 return module\_root

PROJECT\_ROOT = \_resolve\_project\_root()
DEFAULT\_MODEL\_ID = "google/gemma-4-E2B-it"
DEFAULT\_TEST\_TRANSCRIBE\_MODEL\_ID = "nvidia/parakeet-tdt-0.6b-v3"
DEFAULT\_TEST\_WHISPER\_MODEL\_ID = "openai/whisper-small"
DEFAULT\_TEST\_DIARIZE\_MODEL\_ID = "pyannote/segmentation-3.0"
DEFAULT\_TEST\_EMBED\_SPEAKER\_MODEL\_ID = "pyannote/wespeaker-voxceleb-resnet34-LM"
WEIGHTS\_VARIANT\_CHOICES = \["auto", "apple", "standard"\]

with open(PROJECT\_ROOT / "models.json") as \_f:
 MODELS\_REGISTRY = json.load(\_f)

RED = '\\033\[0;31m'\
GREEN = '\\033\[0;32m'\
YELLOW = '\\033\[1;33m'\
BLUE = '\\033\[0;34m'\
NC = '\\033\[0m'\
\
def print\_color(color, message):\
 """Print a message with ANSI color codes."""\
 print(f"{color}{message}{NC}")\
\
from .downloads import get\_model\_dir\_name, get\_weights\_dir, download\_from\_hf as \_download\_from\_hf\_impl\
\
NEEDLE\_CHECKPOINT\_REPO = "Cactus-Compute/needle"\
NEEDLE\_TOKENIZER\_REPO = "Cactus-Compute/needle-tokenizer"\
NEEDLE\_CHECKPOINT\_FILE = "needle.pkl"\
\
def is\_needle\_model\_id(model\_id):\
 normalized = (model\_id or "").strip().lower()\
 if "/" in normalized:\
 normalized = normalized.split("/")\[-1\]\
 return normalized == "needle" or normalized.startswith("needle-") or normalized.startswith("needle\_")\
\
def get\_effective\_weights\_dir(model\_id, args=None):\
 if not is\_needle\_model\_id(model\_id):\
 return get\_weights\_dir(model\_id)\
 return (PROJECT\_ROOT / "weights" / "needle").resolve()\
\
def check\_command(cmd):\
 """Check if a command is available in PATH."""\
 return shutil.which(cmd) is not None\
\
def run\_command(cmd, cwd=None, check=True):\
 """Run a script or command and optionally exit on failure.\
\
 Args:\
 cmd: Script path (str) or command list. String paths are executed\
 directly without shell interpretation to handle spaces safely.\
 cwd: Working directory for the command.\
 check: If True, exit on non-zero return code.\
 """\
 # Convert string paths to list to avoid shell=True and handle spaces safely\
 if isinstance(cmd, str):\
 cmd = \[cmd\]\
 result = subprocess.run(cmd, cwd=cwd)\
 if check and result.returncode != 0:\
 sys.exit(result.returncode)\
 return result\
\
def \_is\_stale\_binary(binary\_path, dependency\_paths):\
 binary\_path = Path(binary\_path)\
 if not binary\_path.exists():\
 return True\
\
 try:\
 binary\_mtime = binary\_path.stat().st\_mtime\
 except OSError:\
 return True\
\
 for dep in dependency\_paths:\
 dep\_path = Path(dep)\
 if not dep\_path.exists():\
 continue\
 try:\
 if dep\_path.stat().st\_mtime > binary\_mtime:\
 return True\
 except OSError:\
 continue\
\
 return False\
\
def \_ensure\_chat\_binary(project\_root, lib\_path):\
 tests\_dir = project\_root / "tests"\
 build\_dir = tests\_dir / "build"\
 chat\_binary = build\_dir / "chat"\
 chat\_cpp = tests\_dir / "chat.cpp"\
\
 if not \_is\_stale\_binary(chat\_binary, \[lib\_path, chat\_cpp\]):\
 return chat\_binary\
\
 print\_color(YELLOW, "Refreshing chat binary for current Cactus library...")\
 build\_args = argparse.Namespace(\
 apple=False,\
 android=False,\
 flutter=False,\
 python=False,\
 )\
 result = cmd\_build(build\_args)\
 if result != 0 or not chat\_binary.exists():\
 raise RuntimeError("Failed to rebuild chat binary")\
\
 return chat\_binary\
\
def ensure\_vad\_weights(model\_id, weights\_dir, precision='INT8'):\
 """Bundle Silero VAD weights into /vad/ for ASR models."""\
 is\_asr = (\
 'whisper' in model\_id.lower()\
 or 'moonshine' in model\_id.lower()\
 or 'parakeet' in model\_id.lower()\
 )\
 if not is\_asr:\
 return\
 vad\_dir = weights\_dir / "vad"\
 if (vad\_dir / "config.txt").exists():\
 return\
 try:\
 import torch\
 import urllib.request\
 import tempfile\
 from .converter import convert\_silero\_vad\_weights\
\
 print\_color(YELLOW, "Bundling VAD weights for speech model...")\
 vad\_jit\_url = "https://github.com/snakers4/silero-vad/raw/master/src/silero\_vad/data/silero\_vad.jit"\
 with tempfile.NamedTemporaryFile(suffix='.jit', delete=False) as f:\
 jit\_path = f.name\
 urllib.request.urlretrieve(vad\_jit\_url, jit\_path)\
 vad\_model = torch.jit.load(jit\_path, map\_location='cpu')\
 os.unlink(jit\_path)\
\
 convert\_silero\_vad\_weights(vad\_model, str(vad\_dir), precision)\
 del vad\_model\
 if torch.cuda.is\_available():\
 torch.cuda.empty\_cache()\
 print\_color(GREEN, "VAD weights bundled successfully")\
 except Exception as e:\
 print\_color(RED, f"Warning: Failed to bundle VAD weights: {e}")\
 print("Transcription may fail without VAD. Try: cactus download snakers4/silero-vad")\
\
def download\_from\_hf(model\_id, weights\_dir, precision):\
 """Download pre-converted model from Cactus-Compute HuggingFace."""\
 return \_download\_from\_hf\_impl(model\_id, weights\_dir, precision)\
\
def cmd\_download(args):\
 """Download model weights. By default downloads pre-converted weights from Cactus-Compute."""\
 model\_id = args.model\_id\
 is\_local = Path(model\_id).is\_dir()\
 weights\_dir = get\_effective\_weights\_dir(model\_id, args)\
 reconvert = getattr(args, 'reconvert', False)\
 precision = getattr(args, 'precision', 'INT4')\
\
 if reconvert and weights\_dir.exists():\
 print\_color(YELLOW, f"Removing cached weights for reconversion...")\
 shutil.rmtree(weights\_dir)\
\
 if weights\_dir.exists() and (weights\_dir / "config.txt").exists():\
 ensure\_vad\_weights(model\_id, weights\_dir, precision)\
 print\_color(GREEN, f"Model weights found at {weights\_dir}")\
 return 0\
\
 print()\
 print\_color(YELLOW, f"Model weights not found. Downloading {model\_id}...")\
 print("=" \* 45)\
\
 if not is\_local and is\_needle\_model\_id(model\_id):\
 try:\
 from huggingface\_hub import hf\_hub\_download, snapshot\_download\
 from .converter import convert\_needle\_checkpoint\
\
 print\_color(YELLOW, "Using Needle exporter...")\
 token = getattr(args, 'token', None)\
 cache\_dir = getattr(args, 'cache\_dir', None)\
\
 ck\_path = hf\_hub\_download(repo\_id=NEEDLE\_CHECKPOINT\_REPO, filename=NEEDLE\_CHECKPOINT\_FILE,\
 repo\_type="model", token=token, cache\_dir=cache\_dir)\
 tk\_snap = Path(snapshot\_download(repo\_id=NEEDLE\_TOKENIZER\_REPO, repo\_type="dataset",\
 allow\_patterns=\["\*.model"\], token=token, cache\_dir=cache\_dir))\
 tk\_path = next(tk\_snap.rglob("\*.model"), None)\
 if not tk\_path:\
 raise FileNotFoundError(f"No .model file in tokenizer snapshot: {tk\_snap}")\
\
 convert\_needle\_checkpoint(ck\_path, tk\_path, weights\_dir, precision)\
 print\_color(GREEN, f"Successfully exported Needle weights to {weights\_dir}")\
 return 0\
 except Exception as e:\
 print\_color(RED, f"Error: {e}")\
 return 1\
\
 if not reconvert and not is\_local:\
 if download\_from\_hf(model\_id, weights\_dir, precision):\
 ensure\_vad\_weights(model\_id, weights\_dir, precision)\
 return 0\
\
 tokenizer\_labels = None\
\
 try:\
 import torch\
 from transformers import AutoTokenizer\
 except ImportError:\
 print\_color(RED, "Error: Required Python packages not found.")\
 print("Please run: ./setup")\
 return 1\
\
 from .converter import convert\_hf\_model\_weights\
 from .tokenizer import convert\_hf\_tokenizer\
 from .tensor\_io import format\_config\_value\
 from .config\_utils import is\_lfm2\_vl, pick\_dtype, vision\_weight\_sanity\_check\
\
 weights\_dir.mkdir(parents=True, exist\_ok=True)\
\
 precision = getattr(args, 'precision', 'INT4')\
 cache\_dir = getattr(args, 'cache\_dir', None)\
 token = getattr(args, 'token', None)\
\
 print(f"Converting {model\_id} to {precision}...")\
\
 from transformers import AutoTokenizer, AutoModelForCausalLM, AutoModel\
\
 import logging\
 logging.getLogger("transformers").setLevel(logging.ERROR)\
 import transformers\
 transformers.logging.set\_verbosity\_error()\
\
 def \_download\_config\_json(repo\_id, revision=None):\
 if Path(repo\_id).is\_dir():\
 config\_path = Path(repo\_id) / "config.json"\
 else:\
 from huggingface\_hub import hf\_hub\_download\
 config\_path = hf\_hub\_download(\
 repo\_id=repo\_id,\
 filename="config.json",\
 cache\_dir=cache\_dir,\
 token=token,\
 revision=revision,\
 )\
 with open(config\_path, 'r', encoding='utf-8') as fh:\
 return json.load(fh)\
\
 def \_resolve\_hf\_revision(repo\_id):\
 env\_revision = os.getenv("CACTUS\_HF\_REVISION", "").strip()\
 if env\_revision:\
 return env\_revision\
 if repo\_id.lower() == "nvidia/parakeet-tdt-0.6b-v3":\
 return "refs/pr/7"\
 return None\
\
 class \_MinimalTokenizer:\
 """Fallback tokenizer for Parakeet-TDT when HF tokenizer load fails."""\
 def \_\_init\_\_(self, name\_or\_path, config\_obj=None):\
 self.name\_or\_path = name\_or\_path\
 self.model\_max\_length = 131072\
 self.pad\_token\_id = 0\
 self.eos\_token\_id = 0\
\
 try:\
 pad\_id = config\_obj.get('pad\_token\_id', 0) if isinstance(config\_obj, dict) else 0\
 self.pad\_token\_id = int(pad\_id) if pad\_id is not None else 0\
 except Exception:\
 self.pad\_token\_id = 0\
\
 try:\
 decoding = config\_obj.get('decoding', {}) if isinstance(config\_obj, dict) else {}\
 blank\_id = decoding.get('blank\_id', None) if isinstance(decoding, dict) else None\
 if blank\_id is not None:\
 self.eos\_token\_id = int(blank\_id)\
 else:\
 self.eos\_token\_id = self.pad\_token\_id\
 except Exception:\
 self.eos\_token\_id = self.pad\_token\_id\
\
 def \_load\_raw\_hf\_state\_dict(repo\_id, cast\_to\_bf16=True):\
 from safetensors.torch import load\_file as load\_safetensors\_file\
\
 if Path(repo\_id).is\_dir():\
 snapshot\_path = Path(repo\_id)\
 else:\
 from huggingface\_hub import snapshot\_download\
 snapshot\_path = Path(snapshot\_download(\
 repo\_id=repo\_id,\
 cache\_dir=cache\_dir,\
 token=token,\
 allow\_patterns=\["\*.safetensors", "\*.safetensors.index.json", "\*.bin", "\*.bin.index.json"\],\
 ))\
\
 index\_candidates = \[\
 "model.safetensors.index.json",\
 "pytorch\_model.bin.index.json",\
 \]\
\
 shard\_files = \[\]\
 for index\_name in index\_candidates:\
 index\_path = snapshot\_path / index\_name\
 if index\_path.exists():\
 with open(index\_path, 'r', encoding='utf-8') as fh:\
 index\_data = json.load(fh)\
 shard\_files = sorted(set(index\_data.get("weight\_map", {}).values()))\
 if shard\_files:\
 break\
\
 if not shard\_files:\
 shard\_files = sorted(\[p.name for p in snapshot\_path.glob("\*.safetensors")\])\
 if not shard\_files:\
 shard\_files = sorted(\[p.name for p in snapshot\_path.glob("\*.bin")\])\
\
 if not shard\_files:\
 raise RuntimeError("No checkpoint shard files found in HuggingFace snapshot.")\
\
 print(f" Found {len(shard\_files)} checkpoint shard file(s)")\
 merged\_state\_dict = {}\
 for idx, shard\_name in enumerate(shard\_files, 1):\
 shard\_path = snapshot\_path / shard\_name\
 print(f" Loading shard {idx}/{len(shard\_files)}: {shard\_name}")\
 if shard\_name.endswith(".safetensors"):\
 shard\_state = load\_safetensors\_file(str(shard\_path), device="cpu")\
 elif shard\_name.endswith(".bin"):\
 shard\_state = torch.load(str(shard\_path), map\_location="cpu")\
 else:\
 continue\
 merged\_state\_dict.update(shard\_state)\
\
 if cast\_to\_bf16:\
 fp\_keys = \[\
 k for k, v in merged\_state\_dict.items()\
 if hasattr(v, "is\_floating\_point") and v.is\_floating\_point() and v.dtype != torch.bfloat16\
 \]\
 total\_fp = len(fp\_keys)\
 if total\_fp > 0:\
 print(f" Normalizing {total\_fp} floating tensors to bfloat16...")\
 for i, k in enumerate(fp\_keys, 1):\
 merged\_state\_dict\[k\] = merged\_state\_dict\[k\].to(torch.bfloat16)\
 if i % 200 == 0 or i == total\_fp:\
 print(f" dtype normalize progress: {i}/{total\_fp}")\
 else:\
 print(" Keeping checkpoint dtypes as-is (Gemma4 fast path)")\
\
 return merged\_state\_dict\
\
 try:\
 from transformers import Lfm2VlForConditionalGeneration\
 except ImportError:\
 Lfm2VlForConditionalGeneration = None\
\
 model\_name = str(model\_id)\
 is\_vlm = 'vl' in model\_name.lower() or 'vlm' in model\_name.lower()\
 is\_whisper = 'whisper' in model\_name.lower()\
 is\_parakeet = 'parakeet' in model\_name.lower()\
 is\_vad = 'silero-vad' in model\_name.lower()\
 is\_pyannote = 'segmentation-3.0' in model\_name.lower()\
 is\_wespeaker = 'wespeaker' in model\_name.lower()\
\
 try:\
 if is\_vlm:\
 from transformers import AutoProcessor, AutoModelForImageTextToText, AutoConfig\
 missing\_deps = \[\]\
 try:\
 from PIL import Image\
 except Exception:\
 missing\_deps.append('Pillow')\
 try:\
 import num2words\
 except Exception:\
 missing\_deps.append('num2words')\
 try:\
 import torchvision\
 except Exception:\
 missing\_deps.append('torchvision')\
\
 if missing\_deps:\
 print\_color(RED, f"Error: Missing packages for VLM: {', '.join(missing\_deps)}")\
 print(f"Install with: pip install {' '.join(missing\_deps)}")\
 return 1\
\
 processor = None\
 try:\
 processor = AutoProcessor.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, token=token)\
 except Exception as proc\_err:\
 if "TokenizersBackend" in str(proc\_err) or "does not exist or is not currently imported" in str(proc\_err):\
 print(f" Note: AutoProcessor failed, using fallback tokenizer loading...")\
 else:\
 raise\
\
 cfg = AutoConfig.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, token=token)\
 dtype = pick\_dtype()\
\
 if is\_lfm2\_vl(model\_id, cfg) and Lfm2VlForConditionalGeneration is not None:\
 model = Lfm2VlForConditionalGeneration.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, dtype=dtype, token=token)\
 else:\
 model = AutoModelForImageTextToText.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, dtype=dtype, token=token)\
\
 tokenizer = getattr(processor, "tokenizer", None) if processor else None\
 if tokenizer is None:\
 try:\
 tokenizer = AutoTokenizer.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, token=token)\
 except Exception as tok\_err:\
 if "TokenizersBackend" in str(tok\_err) or "does not exist or is not currently imported" in str(tok\_err):\
 from transformers import PreTrainedTokenizerFast\
 print(f" Note: Using PreTrainedTokenizerFast fallback for invalid tokenizer\_class...")\
 tokenizer = PreTrainedTokenizerFast.from\_pretrained(model\_id, cache\_dir=cache\_dir, token=token)\
 else:\
 raise\
\
 if is\_lfm2\_vl(model\_id, cfg) and not vision\_weight\_sanity\_check(model):\
 print\_color(RED, "Vision embeddings look randomly initialized.")\
 return 1\
\
 elif 'moonshine' in model\_id.lower():\
 from transformers import MoonshineForConditionalGeneration\
 print(f" Note: Loading Moonshine model using MoonshineForConditionalGeneration...")\
 model = MoonshineForConditionalGeneration.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, dtype=torch.bfloat16, token=token)\
 tokenizer = AutoTokenizer.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, token=token)\
\
 elif is\_whisper:\
 tokenizer = AutoTokenizer.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, token=token)\
 model = AutoModel.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, dtype=torch.bfloat16, token=token)\
\
 elif is\_parakeet:\
 from huggingface\_hub import hf\_hub\_download, snapshot\_download\
 from safetensors.torch import load\_file as load\_safetensors\
\
 revision = \_resolve\_hf\_revision(model\_id)\
 config\_obj = \_download\_config\_json(model\_id, revision=revision)\
 is\_parakeet\_tdt = 'parakeet-tdt' in model\_id.lower()\
 if 'parakeet-tdt' in model\_id.lower():\
 cfg\_labels = config\_obj.get('labels', \[\])\
 if isinstance(cfg\_labels, list) and cfg\_labels:\
 tokenizer\_labels = cfg\_labels\
 try:\
 tokenizer = AutoTokenizer.from\_pretrained(\
 model\_id,\
 cache\_dir=cache\_dir,\
 trust\_remote\_code=True,\
 token=token,\
 revision=revision,\
 )\
 except Exception as tok\_err:\
 tokenizer = None\
 if "TokenizersBackend" in str(tok\_err) or "does not exist or is not currently imported" in str(tok\_err):\
 from transformers import PreTrainedTokenizerFast\
 print(" Note: Using PreTrainedTokenizerFast fallback for Parakeet tokenizer...")\
 try:\
 tokenizer = PreTrainedTokenizerFast.from\_pretrained(\
 model\_id,\
 cache\_dir=cache\_dir,\
 token=token,\
 revision=revision,\
 )\
 except Exception as fast\_tok\_err:\
 tok\_err = fast\_tok\_err\
\
 if tokenizer is None:\
 if is\_parakeet\_tdt and isinstance(tokenizer\_labels, list) and tokenizer\_labels:\
 print(f" Note: Parakeet-TDT tokenizer load failed, using labels fallback ({tok\_err})")\
 tokenizer = \_MinimalTokenizer(model\_id, config\_obj)\
 else:\
 raise\
\
 state\_dict = None\
 try:\
 weights\_path = hf\_hub\_download(\
 repo\_id=model\_id,\
 filename="model.safetensors",\
 cache\_dir=cache\_dir,\
 token=token,\
 revision=revision,\
 )\
 state\_dict = load\_safetensors(weights\_path, device="cpu")\
 except Exception:\
 snapshot\_path = snapshot\_download(\
 repo\_id=model\_id,\
 cache\_dir=cache\_dir,\
 token=token,\
 revision=revision,\
 )\
 index\_path = Path(snapshot\_path) / "model.safetensors.index.json"\
 if not index\_path.exists():\
 raise\
 with open(index\_path, "r", encoding="utf-8") as f:\
 index\_data = json.load(f)\
 shard\_files = sorted(set(index\_data.get("weight\_map", {}).values()))\
 if not shard\_files:\
 raise RuntimeError("Parakeet safetensors index has no shard entries")\
 state\_dict = {}\
 for shard\_name in shard\_files:\
 shard\_path = Path(snapshot\_path) / shard\_name\
 shard\_state = load\_safetensors(str(shard\_path), device="cpu")\
 state\_dict.update(shard\_state)\
\
 class \_StateDictModel:\
 def \_\_init\_\_(self, config, state\_dict):\
 self.config = config\
 self.\_state\_dict = state\_dict\
\
 def state\_dict(self):\
 return self.\_state\_dict\
\
 model = \_StateDictModel(config\_obj, state\_dict)\
\
 elif is\_vad:\
 import urllib.request\
 import tempfile\
 from .converter import convert\_silero\_vad\_weights\
\
 vad\_jit\_url = "https://github.com/snakers4/silero-vad/raw/master/src/silero\_vad/data/silero\_vad.jit"\
 with tempfile.NamedTemporaryFile(suffix='.jit', delete=False) as f:\
 jit\_path = f.name\
 urllib.request.urlretrieve(vad\_jit\_url, jit\_path)\
 model = torch.jit.load(jit\_path, map\_location='cpu')\
 os.unlink(jit\_path)\
 convert\_silero\_vad\_weights(model, weights\_dir, precision, args)\
\
 del model\
 import torch\
 if torch.cuda.is\_available():\
 torch.cuda.empty\_cache()\
\
 print\_color(GREEN, f"Successfully downloaded and converted weights to {weights\_dir}")\
 return 0\
\
 elif is\_pyannote or is\_wespeaker:\
 try:\
 import warnings\
 with warnings.catch\_warnings():\
 warnings.simplefilter("ignore")\
 from pyannote.audio import Model as PyannoteModel\
 except ImportError:\
 print\_color(RED, "Error: pyannote.audio is required. Install with: pip install pyannote.audio")\
 return 1\
 from .converter import convert\_pyannote\_weights, convert\_wespeaker\_weights\
\
 import warnings\
 with warnings.catch\_warnings():\
 warnings.simplefilter("ignore")\
 pyannote\_model = PyannoteModel.from\_pretrained(model\_id, token=token)\
 pyannote\_model.eval()\
\
 if is\_pyannote:\
 convert\_pyannote\_weights(pyannote\_model, weights\_dir, precision, args)\
 else:\
 convert\_wespeaker\_weights(pyannote\_model, weights\_dir, precision, args)\
\
 del pyannote\_model\
 if torch.cuda.is\_available():\
 torch.cuda.empty\_cache()\
\
 print\_color(GREEN, f"Successfully downloaded and converted weights to {weights\_dir}")\
 return 0\
\
 else:\
 config\_json = \_download\_config\_json(model\_id)\
 model\_type = str(config\_json.get('model\_type', '')).lower()\
\
 try:\
 tokenizer = AutoTokenizer.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, token=token)\
 except Exception as tok\_err:\
 if "TokenizersBackend" in str(tok\_err) or "does not exist or is not currently imported" in str(tok\_err):\
 from transformers import PreTrainedTokenizerFast\
 print(" Note: Using PreTrainedTokenizerFast fallback for invalid tokenizer\_class...")\
 tokenizer = PreTrainedTokenizerFast.from\_pretrained(model\_id, cache\_dir=cache\_dir, token=token)\
 else:\
 raise\
\
 if (\
 model\_type == 'lfm2\_moe'\
 or model\_type.startswith('qwen3\_5')\
 or model\_type == 'youtu'\
 or 'gemma4' in model\_type\
 or 'gemma3n' in model\_type\
 ):\
 if model\_type == 'lfm2\_moe':\
 print(" Note: Loading raw checkpoint tensors for lfm2\_moe conversion...")\
 elif 'gemma4' in model\_type:\
 print(f" Note: Loading raw checkpoint tensors for {model\_type} conversion...")\
 else:\
 print(f" Note: Loading raw checkpoint tensors for {model\_type} conversion...")\
 cast\_to\_bf16 = ('gemma4' not in model\_type)\
 raw\_state\_dict = \_load\_raw\_hf\_state\_dict(model\_id, cast\_to\_bf16=cast\_to\_bf16)\
\
 class \_RawModelWrapper:\
 def \_\_init\_\_(self, state\_dict, config):\
 self.\_state\_dict = state\_dict\
 self.config = config\
\
 def state\_dict(self):\
 return self.\_state\_dict\
\
 model = \_RawModelWrapper(raw\_state\_dict, config\_json)\
 else:\
 try:\
 model = AutoModelForCausalLM.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, dtype=torch.bfloat16, token=token)\
 except ValueError:\
 model = AutoModel.from\_pretrained(model\_id, cache\_dir=cache\_dir, trust\_remote\_code=True, dtype=torch.bfloat16, token=token)\
\
 config = convert\_hf\_model\_weights(model, weights\_dir, precision, args)\
 del model\
\
 model\_id\_lower = model\_id.lower()\
 if 'extract' in model\_id\_lower:\
 config\['model\_variant'\] = 'extract'\
 elif 'vlm' in model\_id\_lower:\
 config\['model\_variant'\] = 'vlm'\
 elif 'rag' in model\_id\_lower:\
 config\['model\_variant'\] = 'rag'\
 else:\
 config.setdefault('model\_variant', 'default')\
\
 # Config precision stores the compute precision (weights are quantized, activations stay FP16)\
 if precision in ('INT8', 'INT4'):\
 config\['precision'\] = "FP16"\
 else:\
 config\['precision'\] = precision\
 config\['quantization'\] = precision # this is for CLI display only\
\
 config\_path = weights\_dir / "config.txt"\
 with open(config\_path, 'w') as f:\
 for key, value in config.items():\
 f.write(f"{key}={format\_config\_value(value)}\\n")\
\
 convert\_hf\_tokenizer(\
 tokenizer,\
 weights\_dir,\
 token=token,\
 model\_id=model\_id,\
 labels=tokenizer\_labels,\
 model\_type=config.get('model\_type'),\
 )\
\
 del tokenizer\
 import torch\
 if torch.cuda.is\_available():\
 torch.cuda.empty\_cache()\
\
 print\_color(GREEN, f"Successfully downloaded and converted weights to {weights\_dir}")\
 return 0\
\
 except Exception as e:\
 print\_color(RED, f"Error: {e}")\
 return 1\
\
def check\_libcurl():\
 """Check if libcurl development libraries are installed."""\
 import platform\
\
 if platform.system() == 'Darwin':\
 return True\
\
 if check\_command('pkg-config'):\
 result = subprocess.run(\['pkg-config', '--exists', 'libcurl'\], capture\_output=True)\
 if result.returncode == 0:\
 return True\
\
 curl\_paths = \[\
 '/usr/include/curl/curl.h',\
 '/usr/include/x86\_64-linux-gnu/curl/curl.h',\
 '/usr/include/aarch64-linux-gnu/curl/curl.h',\
 '/usr/local/include/curl/curl.h',\
 \]\
 for path in curl\_paths:\
 if Path(path).exists():\
 return True\
\
 return False\
\
def cmd\_build(args):\
 """Build the Cactus library and chat binary."""\
 if getattr(args, 'apple', False):\
 return cmd\_build\_apple(args)\
 if getattr(args, 'android', False):\
 return cmd\_build\_android(args)\
 if getattr(args, 'flutter', False):\
 return cmd\_build\_flutter(args)\
 if getattr(args, 'python', False):\
 return cmd\_build\_python(args)\
\
 print\_color(BLUE, "Building Cactus chat...")\
 print("=" \* 23)\
\
 if not check\_command('cmake'):\
 print\_color(RED, "Error: CMake is not installed")\
 print(" macOS: brew install cmake")\
 print(" Ubuntu: sudo apt-get install cmake build-essential")\
 return 1\
\
 if not check\_libcurl():\
 print\_color(RED, "Error: libcurl development libraries not found")\
 print(" macOS: brew install curl")\
 print(" Ubuntu: sudo apt-get install libcurl4-openssl-dev")\
 return 1\
\
 cactus\_dir = PROJECT\_ROOT / "cactus"\
 lib\_path = cactus\_dir / "build" / "libcactus.a"\
 vendored\_curl = PROJECT\_ROOT / "libs" / "curl" / "macos" / "libcurl.a"\
\
 print\_color(YELLOW, "Building Cactus library...")\
 build\_script = cactus\_dir / "build.sh"\
 if not build\_script.exists():\
 print\_color(RED, f"Error: build.sh not found at {build\_script}")\
 return 1\
 result = run\_command(str(build\_script), cwd=cactus\_dir, check=False)\
 if result.returncode != 0:\
 print\_color(RED, "Failed to build cactus library")\
 return 1\
\
 tests\_dir = PROJECT\_ROOT / "tests"\
 build\_dir = tests\_dir / "build"\
 build\_dir.mkdir(parents=True, exist\_ok=True)\
\
 print("Compiling chat.cpp...")\
\
 chat\_cpp = tests\_dir / "chat.cpp"\
 if not chat\_cpp.exists():\
 print\_color(RED, f"Error: chat.cpp not found at {chat\_cpp}")\
 return 1\
\
 is\_darwin = platform.system() == "Darwin"\
\
 sdl2\_available = False\
 sdl2\_flags = \[\]\
 sdl2\_link = \[\]\
 if is\_darwin:\
 sdl2\_check = subprocess.run(\["brew", "list", "sdl2"\], capture\_output=True)\
 if sdl2\_check.returncode == 0:\
 sdl2\_prefix\_result = subprocess.run(\["brew", "--prefix", "sdl2"\], capture\_output=True, text=True)\
 if sdl2\_prefix\_result.returncode == 0:\
 sdl2\_prefix = sdl2\_prefix\_result.stdout.strip()\
 sdl2\_flags = \["-DHAVE\_SDL2", f"-I{sdl2\_prefix}/include", f"-I{sdl2\_prefix}/include/SDL2"\]\
 sdl2\_link = \[f"-L{sdl2\_prefix}/lib", "-lSDL2"\]\
 sdl2\_available = True\
 else:\
 sdl2\_check = subprocess.run(\["pkg-config", "--exists", "sdl2"\], capture\_output=True)\
 if sdl2\_check.returncode == 0:\
 cflags = subprocess.run(\["pkg-config", "--cflags", "sdl2"\], capture\_output=True, text=True)\
 libs = subprocess.run(\["pkg-config", "--libs", "sdl2"\], capture\_output=True, text=True)\
 if cflags.returncode == 0 and libs.returncode == 0:\
 sdl2\_flags = \["-DHAVE\_SDL2"\] + cflags.stdout.strip().split()\
 sdl2\_link = libs.stdout.strip().split()\
 sdl2\_available = True\
\
 if sdl2\_available:\
 print\_color(GREEN, "SDL2 found - building with live audio support")\
 else:\
 print\_color(YELLOW, "SDL2 not found - live mic recording will be disabled")\
 print\_color(YELLOW, "Install SDL2 for live mic support: brew install sdl2 (macOS)")\
 print\_color(YELLOW, "Then run \`cactus build\`")\
\
 if is\_darwin:\
 if not vendored\_curl.exists():\
 print\_color(RED, f"Error: vendored libcurl not found at {vendored\_curl}")\
 print("Build it first and place it in libs/curl/macos/libcurl.a")\
 return 1\
 compiler = "clang++"\
 cmd = \[\
 compiler, "-std=c++20", "-O3",\
 "-DACCELERATE\_NEW\_LAPACK",\
 f"-I{PROJECT\_ROOT}",\
 \*sdl2\_flags,\
 str(chat\_cpp),\
 str(lib\_path),\
 "-o", "chat",\
 str(vendored\_curl),\
 "-framework", "Accelerate",\
 "-framework", "CoreML",\
 "-framework", "Foundation",\
 "-framework", "Security",\
 "-framework", "SystemConfiguration",\
 "-framework", "CFNetwork",\
 \*sdl2\_link,\
 \]\
 else:\
 compiler = "g++"\
 cmd = \[\
 compiler, "-std=c++20", "-O3",\
 f"-I{PROJECT\_ROOT}",\
 \*sdl2\_flags,\
 str(chat\_cpp),\
 str(lib\_path),\
 "-o", "chat",\
 "-lcurl",\
 "-pthread",\
 \*sdl2\_link,\
 \]\
\
 if not check\_command(compiler):\
 print\_color(RED, f"Error: {compiler} is not installed")\
 return 1\
\
 result = subprocess.run(cmd, cwd=build\_dir)\
 if result.returncode != 0:\
 print\_color(RED, "Build failed")\
 return 1\
\
 print\_color(GREEN, f"Build complete: {build\_dir / 'chat'}")\
\
 asr\_cpp = tests\_dir / "asr.cpp"\
 if asr\_cpp.exists():\
 print("Compiling asr.cpp...")\
\
 if is\_darwin:\
 cmd = \[\
 compiler, "-std=c++20", "-O3",\
 "-DACCELERATE\_NEW\_LAPACK",\
 f"-I{PROJECT\_ROOT}",\
 \*sdl2\_flags,\
 str(asr\_cpp),\
 str(lib\_path),\
 "-o", "asr",\
 str(vendored\_curl),\
 "-framework", "Accelerate",\
 "-framework", "CoreML",\
 "-framework", "Foundation",\
 "-framework", "Security",\
 "-framework", "SystemConfiguration",\
 "-framework", "CFNetwork",\
 \*sdl2\_link,\
 \]\
 else:\
 cmd = \[\
 compiler, "-std=c++20", "-O3",\
 f"-I{PROJECT\_ROOT}",\
 \*sdl2\_flags,\
 str(asr\_cpp),\
 str(lib\_path),\
 "-o", "asr",\
 "-lcurl",\
 "-pthread",\
 \*sdl2\_link,\
 \]\
\
 result = subprocess.run(cmd, cwd=build\_dir)\
 if result.returncode != 0:\
 print\_color(RED, "ASR build failed")\
 return 1\
\
 print\_color(GREEN, f"Build complete: {build\_dir / 'asr'}")\
\
 return 0\
\
def cmd\_build\_apple(args):\
 """Build Cactus for Apple platforms (iOS/macOS)."""\
 print\_color(BLUE, "Building Cactus for Apple platforms...")\
 print("=" \* 40)\
\
 if platform.system() != "Darwin":\
 print\_color(RED, "Error: Apple builds require macOS")\
 return 1\
\
 build\_script = PROJECT\_ROOT / "apple" / "build.sh"\
 if not build\_script.exists():\
 print\_color(RED, f"Error: build.sh not found at {build\_script}")\
 return 1\
\
 result = run\_command(str(build\_script), cwd=PROJECT\_ROOT / "apple", check=False)\
 if result.returncode != 0:\
 print\_color(RED, "Apple build failed")\
 return 1\
\
 print\_color(GREEN, "Apple build complete!")\
 return 0\
\
def cmd\_build\_android(args):\
 """Build Cactus for Android."""\
 print\_color(BLUE, "Building Cactus for Android...")\
 print("=" \* 32)\
\
 build\_script = PROJECT\_ROOT / "android" / "build.sh"\
 if not build\_script.exists():\
 print\_color(RED, f"Error: build.sh not found at {build\_script}")\
 return 1\
\
 result = run\_command(str(build\_script), cwd=PROJECT\_ROOT / "android", check=False)\
 if result.returncode != 0:\
 print\_color(RED, "Android build failed")\
 return 1\
\
 print\_color(GREEN, "Android build complete!")\
 return 0\
\
def cmd\_build\_flutter(args):\
 """Build Cactus for Flutter (iOS, macOS, Android)."""\
 print\_color(BLUE, "Building Cactus for Flutter...")\
 print("=" \* 32)\
\
 build\_script = PROJECT\_ROOT / "flutter" / "build.sh"\
 if not build\_script.exists():\
 print\_color(RED, f"Error: build.sh not found at {build\_script}")\
 return 1\
\
 result = run\_command(str(build\_script), cwd=PROJECT\_ROOT / "flutter", check=False)\
 if result.returncode != 0:\
 print\_color(RED, "Flutter build failed")\
 return 1\
\
 print\_color(GREEN, "Flutter build complete!")\
 print()\
 print("Output:")\
 print(f" flutter/libcactus.so")\
 print(f" flutter/cactus-ios.xcframework")\
 print(f" flutter/cactus-macos.xcframework")\
 return 0\
\
def cmd\_build\_python(args):\
 """Build Cactus shared library for Python FFI."""\
 print\_color(BLUE, "Building Cactus for Python...")\
 print("=" \* 30)\
\
 if not check\_command('cmake'):\
 print\_color(RED, "Error: CMake is not installed")\
 print(" macOS: brew install cmake")\
 print(" Ubuntu: sudo apt-get install cmake")\
 return 1\
\
 cactus\_dir = PROJECT\_ROOT / "cactus"\
 build\_script = cactus\_dir / "build.sh"\
 if not build\_script.exists():\
 print\_color(RED, f"Error: build.sh not found at {build\_script}")\
 return 1\
\
 result = run\_command(str(build\_script), cwd=cactus\_dir, check=False)\
 if result.returncode != 0:\
 print\_color(RED, "Build failed")\
 return 1\
\
 if platform.system() == "Darwin":\
 lib\_name = "libcactus.dylib"\
 else:\
 lib\_name = "libcactus.so"\
\
 lib\_path = cactus\_dir / "build" / lib\_name\
 if not lib\_path.exists():\
 print\_color(RED, f"Shared library not found at {lib\_path}")\
 return 1\
\
 print\_color(GREEN, "Python build complete!")\
 print(f"Library: {lib\_path}")\
 return 0\
\
def prompt\_for\_api\_key(config):\
 """Prompt user to set Cactus Cloud API key if not already configured. Returns the key or empty string."""\
 api\_key = config.get\_api\_key()\
 if api\_key:\
 return api\_key\
\
 print("\\n" + "="\*50)\
 print(" Cactus Cloud Setup (Optional)")\
 print("="\*50 + "\\n")\
 print("Get your cloud key at \\033\[1;36mhttps://www.cactuscompute.com/dashboard/api-keys\\033\[0m")\
 print("to enable automatic cloud fallback.\\n")\
\
 api\_key = input("Your Cactus Cloud key (press Enter to skip): ").strip()\
 if api\_key:\
 config.set\_api\_key(api\_key)\
 masked = api\_key\[:4\] + "..." + api\_key\[-4:\]\
 print\_color(GREEN, f"API key saved: {masked}")\
 print()\
 return api\_key\
\
def cmd\_run(args):\
 """Download model if needed and start interactive chat."""\
 from .config\_utils import CactusConfig\
\
 config = CactusConfig()\
 api\_key = prompt\_for\_api\_key(config)\
\
 if api\_key:\
 os.environ\["CACTUS\_CLOUD\_KEY"\] = api\_key\
\
 model\_id = args.model\_id\
\
 if getattr(args, 'no\_cloud\_tele', False):\
 os.environ\["CACTUS\_NO\_CLOUD\_TELE"\] = "1"\
\
 lib\_path = PROJECT\_ROOT / "cactus" / "build" / "libcactus.a"\
 if not lib\_path.exists():\
 print\_color(RED, "Error: Cactus library not built. Run 'cactus build' first.")\
 return 1\
\
 local\_path = Path(model\_id)\
 if local\_path.exists() and (local\_path / "config.txt").exists():\
 weights\_dir = local\_path\
 print\_color(GREEN, f"Using local model: {weights\_dir}")\
 else:\
 download\_result = cmd\_download(args)\
 if download\_result != 0:\
 return download\_result\
 weights\_dir = get\_effective\_weights\_dir(model\_id, args)\
\
 image\_path = getattr(args, 'image', None)\
 if image\_path:\
 image\_path = str(Path(image\_path).resolve())\
 if not Path(image\_path).exists():\
 print\_color(RED, f"Error: Image file not found: {image\_path}")\
 return 1\
 valid\_exts = {'.png', '.jpg', '.jpeg', '.bmp'}\
 if Path(image\_path).suffix.lower() not in valid\_exts:\
 print\_color(RED, f"Error: Unsupported image format. Supported: {', '.join(valid\_exts)}")\
 return 1\
\
 try:\
 chat\_binary = \_ensure\_chat\_binary(PROJECT\_ROOT, lib\_path)\
 except RuntimeError as exc:\
 print\_color(RED, f"Error: {exc}")\
 return 1\
\
 os.system('clear' if platform.system() != 'Windows' else 'cls')\
 print\_color(GREEN, f"Starting Cactus Chat with model: {model\_id}")\
 print()\
\
 audio\_path = getattr(args, 'audio', None)\
 if audio\_path:\
 audio\_path = str(Path(audio\_path).resolve())\
 if not Path(audio\_path).exists():\
 print\_color(RED, f"Error: Audio file not found: {audio\_path}")\
 return 1\
\
 cmd\_args = \[str(chat\_binary), str(weights\_dir)\]\
 if image\_path:\
 cmd\_args.extend(\['--image', image\_path\])\
 if audio\_path:\
 cmd\_args.extend(\['--audio', audio\_path\])\
 system\_prompt = getattr(args, 'system', None)\
 if system\_prompt:\
 cmd\_args.extend(\['--system', system\_prompt\])\
 prompt = getattr(args, 'prompt', None)\
 if prompt:\
 cmd\_args.extend(\['--prompt', prompt\])\
 if getattr(args, 'thinking', False):\
 cmd\_args.append('--thinking')\
\
 os.execv(str(chat\_binary), cmd\_args)\
\
DEFAULT\_ASR\_MODEL\_ID = "nvidia/parakeet-tdt-0.6b-v3"\
\
def \_pick\_android\_device\_id(preferred\_device=None):\
 if preferred\_device:\
 return preferred\_device\
\
 result = subprocess.run(\["adb", "devices"\], capture\_output=True, text=True)\
 if result.returncode != 0:\
 return None\
\
 devices = \[\]\
 for line in result.stdout.splitlines():\
 line = line.strip()\
 if not line or line.startswith("List of devices attached"):\
 continue\
 parts = line.split()\
 if len(parts) >= 2 and parts\[1\] == "device":\
 devices.append(parts\[0\])\
\
 if len(devices) == 1:\
 return devices\[0\]\
 return None\
\
def \_cmd\_transcribe\_android(weights\_dir, audio\_file, args):\
 if not audio\_file:\
 print\_color(RED, "Error: --android requires --file ")\
 return 1\
 if not check\_command("adb"):\
 print\_color(RED, "Error: adb not found in PATH")\
 return 1\
\
 audio\_path = Path(audio\_file).expanduser().resolve()\
 if not audio\_path.exists():\
 print\_color(RED, f"Error: audio file not found: {audio\_path}")\
 return 1\
\
 device\_id = \_pick\_android\_device\_id(getattr(args, "device", None))\
 if not device\_id:\
 print\_color(RED, "Error: could not select Android device. Use --device .")\
 return 1\
\
 print\_color(BLUE, f"Using Android device: {device\_id}")\
\
 android\_build\_script = PROJECT\_ROOT / "android" / "build.sh"\
 if not android\_build\_script.exists():\
 print\_color(RED, f"Error: build.sh not found at {android\_build\_script}")\
 return 1\
 if run\_command(str(android\_build\_script), cwd=PROJECT\_ROOT / "android", check=False).returncode != 0:\
 print\_color(RED, "Android library build failed")\
 return 1\
\
 if not check\_command("cmake"):\
 print\_color(RED, "Error: CMake is not installed")\
 return 1\
\
 android\_test\_dir = PROJECT\_ROOT / "tests" / "android"\
 android\_build\_dir = android\_test\_dir / "build"\
 ndk\_home = os.environ.get("ANDROID\_NDK\_HOME")\
 if not ndk\_home:\
 android\_home = os.environ.get("ANDROID\_HOME") or str(Path.home() / "Library" / "Android" / "sdk")\
 ndk\_root = Path(android\_home) / "ndk"\
 if ndk\_root.exists():\
 ndk\_versions = sorted(\[p for p in ndk\_root.iterdir() if p.is\_dir()\])\
 if ndk\_versions:\
 ndk\_home = str(ndk\_versions\[-1\])\
 if not ndk\_home or not Path(ndk\_home).exists():\
 print\_color(RED, "Error: Android NDK not found. Set ANDROID\_NDK\_HOME.")\
 return 1\
\
 toolchain = Path(ndk\_home) / "build" / "cmake" / "android.toolchain.cmake"\
 if not toolchain.exists():\
 print\_color(RED, f"Error: Android toolchain not found at {toolchain}")\
 return 1\
\
 android\_build\_dir.mkdir(parents=True, exist\_ok=True)\
 cfg\_cmd = \[\
 "cmake", "-S", str(android\_test\_dir), "-B", str(android\_build\_dir),\
 f"-DCMAKE\_TOOLCHAIN\_FILE={toolchain}",\
 "-DANDROID\_ABI=arm64-v8a",\
 f"-DANDROID\_PLATFORM={os.environ.get('ANDROID\_PLATFORM', 'android-21')}",\
 "-DCMAKE\_BUILD\_TYPE=Release",\
 \]\
 if subprocess.run(cfg\_cmd).returncode != 0:\
 print\_color(RED, "Failed to configure Android transcribe build")\
 return 1\
 build\_cmd = \["cmake", "--build", str(android\_build\_dir), "--target", "asr", "-j", str(os.cpu\_count() or 4)\]\
 if subprocess.run(build\_cmd).returncode != 0:\
 print\_color(RED, "Failed to build Android asr binary")\
 return 1\
\
 asr\_bin = android\_build\_dir / "asr"\
 if not asr\_bin.exists():\
 print\_color(RED, f"Error: Android asr binary not found at {asr\_bin}")\
 return 1\
\
 model\_name = Path(weights\_dir).name\
 device\_root = "/data/local/tmp/cactus\_transcribe"\
 device\_model\_root = f"{device\_root}/models"\
 device\_audio\_root = f"{device\_root}/audio"\
 device\_bin\_root = f"{device\_root}/bin"\
 device\_audio = f"{device\_audio\_root}/{audio\_path.name}"\
 device\_model = f"{device\_model\_root}/{model\_name}"\
\
 subprocess.run(\["adb", "-s", device\_id, "shell", f"mkdir -p {device\_bin\_root} {device\_model\_root} {device\_audio\_root}"\], check=False)\
 if subprocess.run(\["adb", "-s", device\_id, "push", str(asr\_bin), f"{device\_bin\_root}/asr"\]).returncode != 0:\
 print\_color(RED, "Failed to push Android asr binary")\
 return 1\
 subprocess.run(\["adb", "-s", device\_id, "shell", f"chmod +x {device\_bin\_root}/asr"\], check=False)\
 if subprocess.run(\["adb", "-s", device\_id, "push", str(weights\_dir), device\_model\_root\]).returncode != 0:\
 print\_color(RED, "Failed to push ASR model weights to device")\
 return 1\
 if subprocess.run(\["adb", "-s", device\_id, "push", str(audio\_path), device\_audio\]).returncode != 0:\
 print\_color(RED, "Failed to push audio file to device")\
 return 1\
\
 cloud\_api\_key = os.environ.get("CACTUS\_CLOUD\_KEY", os.environ.get("CACTUS\_CLOUD\_API\_KEY", ""))\
 cloud\_strict\_ssl = os.environ.get("CACTUS\_CLOUD\_STRICT\_SSL", "")\
 cloud\_handoff\_threshold = os.environ.get("CACTUS\_CLOUD\_HANDOFF\_THRESHOLD", "")\
 ca\_bundle = os.environ.get("CACTUS\_CA\_BUNDLE", "")\
 ca\_path = os.environ.get("CACTUS\_CA\_PATH", "")\
 force\_handoff = os.environ.get("CACTUS\_FORCE\_HANDOFF", "")\
 env\_exports = \[\]\
 if cloud\_api\_key:\
 env\_exports.append(f"export CACTUS\_CLOUD\_KEY='{cloud\_api\_key}'")\
 if cloud\_strict\_ssl:\
 env\_exports.append(f"export CACTUS\_CLOUD\_STRICT\_SSL='{cloud\_strict\_ssl}'")\
 if cloud\_handoff\_threshold:\
 env\_exports.append(f"export CACTUS\_CLOUD\_HANDOFF\_THRESHOLD='{cloud\_handoff\_threshold}'")\
 if ca\_bundle:\
 env\_exports.append(f"export CACTUS\_CA\_BUNDLE='{ca\_bundle}'")\
 if ca\_path:\
 env\_exports.append(f"export CACTUS\_CA\_PATH='{ca\_path}'")\
 if getattr(args, "no\_cloud\_tele", False):\
 env\_exports.append("export CACTUS\_NO\_CLOUD\_TELE=1")\
 if force\_handoff:\
 env\_exports.append(f"export CACTUS\_FORCE\_HANDOFF='{force\_handoff}'")\
\
 shell\_cmd = " && ".join(env\_exports + \[f"{device\_bin\_root}/asr {device\_model} {device\_audio}"\])\
 print\_color(BLUE, "Running Android transcription...")\
 return subprocess.run(\["adb", "-s", device\_id, "shell", shell\_cmd\]).returncode\
\
def \_cmd\_transcribe\_ios(weights\_dir, audio\_file, args):\
 if not audio\_file:\
 print\_color(RED, "Error: --ios requires --file ")\
 return 1\
\
 audio\_path = Path(audio\_file).expanduser().resolve()\
 if not audio\_path.exists():\
 print\_color(RED, f"Error: audio file not found: {audio\_path}")\
 return 1\
\
 ios\_script = PROJECT\_ROOT / "tests" / "ios" / "run.sh"\
 if not ios\_script.exists():\
 print\_color(RED, f"Error: iOS runner not found at {ios\_script}")\
 return 1\
\
 transcribe\_model\_id = Path(weights\_dir).name\
 env = os.environ.copy()\
 env\["CACTUS\_RUN\_ASR"\] = "1"\
 env\["CACTUS\_ASR\_AUDIO\_SOURCE"\] = str(audio\_path)\
 env\["CACTUS\_ASR\_AUDIO\_FILE"\] = audio\_path.name\
\
 cmd = \[str(ios\_script), transcribe\_model\_id, transcribe\_model\_id, "snakers4/silero-vad"\]\
 print\_color(BLUE, "Running iOS transcription...")\
 return subprocess.run(cmd, cwd=PROJECT\_ROOT / "tests" / "ios", env=env).returncode\
\
def cmd\_transcribe(args):\
 """Download ASR model if needed and start transcription."""\
 from .config\_utils import CactusConfig\
\
 config = CactusConfig()\
 api\_key = prompt\_for\_api\_key(config)\
\
 if api\_key:\
 os.environ\["CACTUS\_CLOUD\_KEY"\] = api\_key\
\
 model\_id = getattr(args, 'model\_id', DEFAULT\_ASR\_MODEL\_ID)\
 audio\_file = getattr(args, 'audio\_file', None)\
\
 if getattr(args, 'no\_cloud\_tele', False):\
 os.environ\["CACTUS\_NO\_CLOUD\_TELE"\] = "1"\
\
 if getattr(args, 'force\_handoff', False):\
 os.environ\["CACTUS\_FORCE\_HANDOFF"\] = "1"\
 else:\
 os.environ.pop("CACTUS\_FORCE\_HANDOFF", None)\
\
 audio\_extensions = ('.wav', '.mp3', '.flac', '.ogg', '.m4a', '.aac')\
 if model\_id and model\_id.lower().endswith(audio\_extensions):\
 audio\_file = model\_id\
 model\_id = DEFAULT\_ASR\_MODEL\_ID\
 args.model\_id = model\_id\
\
 local\_path = Path(model\_id)\
 if local\_path.exists() and (local\_path / "config.txt").exists():\
 weights\_dir = local\_path\
 print\_color(GREEN, f"Using local model: {weights\_dir}")\
 else:\
 download\_result = cmd\_download(args)\
 if download\_result != 0:\
 return download\_result\
 weights\_dir = get\_weights\_dir(model\_id)\
\
 if getattr(args, 'android', False) and getattr(args, 'ios', False):\
 print\_color(RED, "Error: choose only one of --android or --ios")\
 return 1\
 if getattr(args, 'android', False):\
 return \_cmd\_transcribe\_android(weights\_dir, audio\_file, args)\
 if getattr(args, 'ios', False):\
 return \_cmd\_transcribe\_ios(weights\_dir, audio\_file, args)\
\
 asr\_binary = PROJECT\_ROOT / "tests" / "build" / "asr"\
 if not asr\_binary.exists():\
 print\_color(RED, "Error: ASR binary not built. Run 'cactus build' first.")\
 return 1\
\
 os.system('clear' if platform.system() != 'Windows' else 'cls')\
 print\_color(GREEN, f"Starting Cactus ASR with model: {model\_id}")\
 print()\
\
 cmd\_args = \[str(asr\_binary), str(weights\_dir)\]\
 if audio\_file:\
 cmd\_args.append(audio\_file)\
 if hasattr(args, 'language') and args.language:\
 cmd\_args.extend(\['--language', args.language\])\
\
 os.execv(str(asr\_binary), cmd\_args)\
\
def cmd\_auth(args):\
 """Manage Cactus Cloud API key."""\
 from .config\_utils import CactusConfig\
\
 config = CactusConfig()\
\
 if args.clear:\
 config.clear\_api\_key()\
 print\_color(GREEN, "API key cleared.")\
 return 0\
\
 api\_key = config.get\_api\_key()\
\
 if api\_key:\
 masked = api\_key\[:4\] + "..." + api\_key\[-4:\]\
 print(f"Current API key: {masked}")\
 else:\
 print("No API key set.")\
\
 if args.status:\
 return 0\
\
 print()\
 print("Get your cloud key at \\033\[1;36mhttps://www.cactuscompute.com/dashboard/api-keys\\033\[0m")\
 new\_key = input("Enter new API key (press Enter to skip): ").strip()\
 if new\_key:\
 config.set\_api\_key(new\_key)\
 masked = new\_key\[:4\] + "..." + new\_key\[-4:\]\
 print\_color(GREEN, f"API key saved: {masked}")\
 return 0\
\
def cmd\_eval(args):\
 model\_id = getattr(args, 'model\_id', DEFAULT\_MODEL\_ID)\
\
 if PROJECT\_ROOT.parent.name != 'evals':\
 print\_color(RED, "Skipping internal eval checks: companion repo not found.")\
 return 1\
\
 # Check if cactus library exists\
 lib\_path = PROJECT\_ROOT / "cactus" / "build" / "libcactus.a"\
 if not lib\_path.exists():\
 print\_color(RED, "Error: Cactus library not built. Run 'cactus build' first.")\
 return 1\
\
 class DownloadArgs:\
 pass\
\
 dlargs = DownloadArgs()\
 dlargs.model\_id = model\_id\
 dlargs.precision = getattr(args, 'precision', 'INT4')\
 dlargs.cache\_dir = getattr(args, 'cache\_dir', None)\
 dlargs.token = getattr(args, 'token', None)\
 dlargs.reconvert = getattr(args, 'reconvert', False)\
\
 download\_result = cmd\_download(dlargs)\
 if download\_result != 0:\
 return download\_result\
\
 weights\_dir = get\_effective\_weights\_dir(model\_id, args)\
 extra = getattr(args, 'extra\_args', None) or \[\]\
\
 def extra\_has\_flag(flag: str) -> bool:\
 for a in extra:\
 if a == flag or a.startswith(flag + "="):\
 return True\
 return False\
\
 mode\_flags = \[\]\
 if getattr(args, 'tools', False): mode\_flags.append('tools')\
 if getattr(args, 'llm', False): mode\_flags.append('llm')\
 if getattr(args, 'stt', False): mode\_flags.append('stt')\
 if getattr(args, 'vlm', False): mode\_flags.append('vlm')\
 if getattr(args, 'embed', False): mode\_flags.append('embed')\
\
 if len(mode\_flags) > 1:\
 print\_color(RED, f"Error: choose only one eval mode flag, got: {' '.join(mode\_flags)}")\
 return 1\
\
 mode = mode\_flags\[0\] if mode\_flags else "tools"\
 repo\_root = PROJECT\_ROOT.parent # evals/\
 cwd = repo\_root\
\
 if mode == "tools":\
 eval\_runner = repo\_root / "tool-evals" / "run\_eval\_berk.py"\
 elif mode == "stt":\
 eval\_runner = repo\_root / "speech-evals" / "speech\_eval.py"\
 elif mode == "llm":\
 eval\_runner = repo\_root / "text-evals" / "perplexity\_eval.py"\
 elif mode == "vlm":\
 eval\_runner = repo\_root / "video-evals" / "run\_benchmarks.py"\
 elif mode == "embed":\
 print\_color(RED, f"Error: eval mode '{mode}' is not supported in this repo layout")\
 return 1\
 else:\
 print\_color(RED, f"Error: unknown eval mode '{mode}'")\
 return 1\
\
 if not eval\_runner.exists():\
 print\_color(RED, f"Eval runner not found at {eval\_runner}")\
 return 1\
\
 cmd = \[sys.executable, str(eval\_runner)\]\
\
 if mode == "vlm":\
 if not extra\_has\_flag("--model"):\
 cmd += \["--model", str(weights\_dir)\]\
 if not extra\_has\_flag("--all") and not extra\_has\_flag("--benchmarks"):\
 cmd += \["--all"\]\
 else:\
 if not extra\_has\_flag("--model-path"):\
 cmd += \["--model-path", str(weights\_dir)\]\
\
 if mode == "llm" and not extra\_has\_flag("--model-id"):\
 cmd += \["--model-id", str(model\_id)\]\
\
 if mode == "stt" and not extra\_has\_flag("--dataset-path"):\
 default\_dataset\_path = repo\_root / "speech-evals" / "dataset-retrieval"\
 cmd += \["--dataset-path", str(default\_dataset\_path)\]\
\
 if not extra\_has\_flag("--output-dir"):\
 if mode == "tools":\
 default\_out = repo\_root / "tool-evals" / "results"\
 elif mode == "stt":\
 default\_out = repo\_root / "speech-evals" / "results"\
 elif mode == "llm":\
 default\_out = repo\_root / "text-evals" / "results"\
 else:\
 default\_out = None\
 if default\_out is not None:\
 cmd += \["--output-dir", str(default\_out)\]\
\
 cmd += extra\
\
 print\_color(BLUE, f"\[cactus\] launching {mode} eval runner")\
 print(" ".join(cmd))\
\
 env = os.environ.copy()\
 if getattr(args, 'no\_cloud\_tele', False):\
 env\["CACTUS\_NO\_CLOUD\_TELE"\] = "1"\
 if mode == "vlm":\
 ffi\_dir = str(repo\_root / "cactus" / "tools" / "src")\
 existing = env.get("PYTHONPATH", "")\
 env\["PYTHONPATH"\] = ffi\_dir if not existing else (ffi\_dir + os.pathsep + existing)\
\
 r = subprocess.run(cmd, cwd=str(cwd), env=env)\
 return r.returncode\
\
def cmd\_test(args):\
 """Run the Cactus test suite."""\
 print\_color(BLUE, "Running test suite...")\
 print("=" \* 20)\
\
 if getattr(args, 'ios', False) and not getattr(args, 'reconvert', False):\
 print\_color(\
 YELLOW,\
 "Warning: iOS tests without --reconvert may use stale or inconsistent local weights. "\
 "If tests fail unexpectedly, rerun with --reconvert."\
 )\
\
 if getattr(args, 'benchmark', False):\
 args.model = 'LiquidAI/LFM2.5-VL-1.6B'\
 args.transcribe\_model = 'nvidia/parakeet-ctc-1.1b'\
 print\_color(BLUE, f"Using large models: {args.model}, {args.transcribe\_model}, {args.vad\_model}")\
\
 if getattr(args, 'reconvert', False):\
 reconvert\_models = \[\
 getattr(args, 'model', 'LiquidAI/LFM2-VL-450M'),\
 getattr(args, 'transcribe\_model', DEFAULT\_TEST\_TRANSCRIBE\_MODEL\_ID),\
 getattr(args, 'whisper\_model', DEFAULT\_TEST\_WHISPER\_MODEL\_ID),\
 getattr(args, 'vad\_model', 'snakers4/silero-vad'),\
 getattr(args, 'diarize\_model', DEFAULT\_TEST\_DIARIZE\_MODEL\_ID),\
 getattr(args, 'embed\_speaker\_model', DEFAULT\_TEST\_EMBED\_SPEAKER\_MODEL\_ID),\
 \]\
 for model\_id in reconvert\_models:\
 class DownloadArgs:\
 pass\
 dl\_args = DownloadArgs()\
 dl\_args.model\_id = model\_id\
 dl\_args.reconvert = True\
 dl\_args.cache\_dir = None\
 if args.precision:\
 dl\_args.precision = args.precision\
 else:\
 is\_asr = 'whisper' in model\_id.lower() or 'moonshine' in model\_id.lower() or 'silero-vad' in model\_id.lower()\
 is\_fp16\_only = 'segmentation-3.0' in model\_id.lower() or 'wespeaker' in model\_id.lower()\
 dl\_args.precision = 'FP16' if is\_fp16\_only else ('INT8' if is\_asr else 'INT4')\
 if args.token:\
 dl\_args.token = args.token\
 if cmd\_download(dl\_args) != 0:\
 return 1\
\
 test\_script = PROJECT\_ROOT / "tests" / "run.sh"\
\
 if not test\_script.exists():\
 print\_color(RED, f"Error: Test script not found at {test\_script}")\
 return 1\
\
 cmd = \[str(test\_script)\]\
\
 if args.model:\
 cmd.extend(\["--model", args.model\])\
 if args.transcribe\_model:\
 cmd.extend(\["--transcribe\_model", args.transcribe\_model\])\
 if getattr(args, 'whisper\_model', None):\
 cmd.extend(\["--whisper\_model", args.whisper\_model\])\
 if getattr(args, 'vad\_model', None):\
 cmd.extend(\["--vad\_model", args.vad\_model\])\
 if getattr(args, 'diarize\_model', None):\
 cmd.extend(\["--diarize\_model", args.diarize\_model\])\
 if getattr(args, 'embed\_speaker\_model', None):\
 cmd.extend(\["--embed\_speaker\_model", args.embed\_speaker\_model\])\
 if args.precision:\
 cmd.extend(\["--precision", args.precision\])\
 if getattr(args, 'no\_rebuild', False):\
 cmd.append("--no-rebuild")\
 if args.android:\
 cmd.append("--android")\
 if args.ios:\
 cmd.append("--ios")\
 if getattr(args, 'exhaustive', False):\
 cmd.append("--exhaustive")\
 test\_filter = args.only\
 for \_test\_name in \['llm', 'vlm', 'stt', 'embed', 'rag', 'graph', 'index', 'kernel', 'kv\_cache', 'performance'\]:\
 if getattr(args, \_test\_name, False):\
 test\_filter = \_test\_name\
 break\
 if test\_filter:\
 cmd.extend(\["--only", test\_filter\])\
 env = os.environ.copy()\
 if getattr(args, 'enable\_telemetry', False):\
 env.pop("CACTUS\_NO\_CLOUD\_TELE", None)\
 else:\
 env\["CACTUS\_NO\_CLOUD\_TELE"\] = "1"\
\
 result = subprocess.run(cmd, cwd=PROJECT\_ROOT / "tests", env=env)\
 return result.returncode\
\
def cmd\_clean(args):\
 """Remove all build artifacts, caches, and downloaded weights."""\
 print\_color(BLUE, "Cleaning all build artifacts from Cactus project...")\
 print(f"Project root: {PROJECT\_ROOT}")\
 print()\
\
 def remove\_if\_exists(path):\
 if path.is\_dir():\
 print(f"Removing: {path}")\
 shutil.rmtree(path)\
 else:\
 print(f"Not found: {path}")\
\
 remove\_if\_exists(PROJECT\_ROOT / "cactus" / "build")\
\
 remove\_if\_exists(PROJECT\_ROOT / "android" / "build")\
 remove\_if\_exists(PROJECT\_ROOT / "android" / "libs")\
 remove\_if\_exists(PROJECT\_ROOT / "android" / "arm64-v8a")\
\
 remove\_if\_exists(PROJECT\_ROOT / "apple" / "build")\
\
 remove\_if\_exists(PROJECT\_ROOT / "tests" / "build")\
\
 remove\_if\_exists(PROJECT\_ROOT / "venv")\
\
 remove\_if\_exists(PROJECT\_ROOT / "weights")\
\
 # Clean telemetry cache\
 telemetry\_cache = Path.home() / "Library" / "Caches" / "cactus" / "telemetry"\
 if telemetry\_cache.exists():\
 print(f"Removing telemetry cache: {telemetry\_cache}")\
 shutil.rmtree(telemetry\_cache)\
 else:\
 print(f"Telemetry cache not found: {telemetry\_cache}")\
\
 # Re-cache API key from config so users don't need to run \`cactus auth\` again\
 from .config\_utils import CactusConfig\
 config = CactusConfig()\
 saved\_key = config.load\_config().get("api\_key", "")\
 if saved\_key:\
 config.cache\_api\_key(saved\_key)\
 masked = saved\_key\[:4\] + "..." + saved\_key\[-4:\]\
 print(f"Restored cached API key: {masked}")\
\
 print()\
 print("Removing compiled libraries and frameworks...")\
\
 preserve\_roots = \[\
 PROJECT\_ROOT / "libs" / "curl",\
 PROJECT\_ROOT / "android" / "mbedtls",\
 PROJECT\_ROOT / "libs" / "mbedtls",\
 \]\
\
 def should\_preserve\_artifact(path: Path) -> bool:\
 try:\
 resolved = path.resolve()\
 except FileNotFoundError:\
 return False\
 for root in preserve\_roots:\
 try:\
 if resolved.is\_relative\_to(root.resolve()):\
 return True\
 except FileNotFoundError:\
 continue\
 return False\
\
 so\_count = 0\
 for so\_file in PROJECT\_ROOT.rglob("\*.so"):\
 so\_file.unlink()\
 so\_count += 1\
 print(f"Removed {so\_count} .so files" if so\_count else "No .so files found")\
\
 a\_count = 0\
 a\_preserved\_count = 0\
 for a\_file in PROJECT\_ROOT.rglob("\*.a"):\
 if should\_preserve\_artifact(a\_file):\
 a\_preserved\_count += 1\
 continue\
 a\_file.unlink()\
 a\_count += 1\
 if a\_count or a\_preserved\_count:\
 print(f"Removed {a\_count} .a files (preserved {a\_preserved\_count} vendored static libs)")\
 else:\
 print("No .a files found")\
\
 bin\_count = 0\
 for bin\_file in PROJECT\_ROOT.rglob("\*.bin"):\
 bin\_file.unlink()\
 bin\_count += 1\
 print(f"Removed {bin\_count} .bin files" if bin\_count else "No .bin files found")\
\
 xcf\_count = 0\
 for xcf\_dir in PROJECT\_ROOT.rglob("\*.xcframework"):\
 if xcf\_dir.is\_dir():\
 shutil.rmtree(xcf\_dir)\
 xcf\_count += 1\
 print(f"Removed {xcf\_count} .xcframework directories" if xcf\_count else "No .xcframework directories found")\
\
 pycache\_count = 0\
 for pycache\_dir in PROJECT\_ROOT.rglob("\_\_pycache\_\_"):\
 if pycache\_dir.is\_dir():\
 shutil.rmtree(pycache\_dir)\
 pycache\_count += 1\
 print(f"Removed {pycache\_count} \_\_pycache\_\_ directories" if pycache\_count else "No \_\_pycache\_\_ directories found")\
\
 egg\_count = 0\
 for egg\_dir in PROJECT\_ROOT.rglob("\*.egg-info"):\
 if egg\_dir.is\_dir():\
 shutil.rmtree(egg\_dir)\
 egg\_count += 1\
 print(f"Removed {egg\_count} .egg-info directories" if egg\_count else "No .egg-info directories found")\
\
 print()\
 print\_color(GREEN, "Clean complete!")\
 print("All build artifacts have been removed.")\
 print()\
\
 # Re-run setup automatically\
 print\_color(BLUE, "Re-running setup...")\
 setup\_script = PROJECT\_ROOT / "setup"\
 result = subprocess.run(\
 \["bash", "-c", f"source {setup\_script}"\],\
 cwd=PROJECT\_ROOT\
 )\
 if result.returncode == 0:\
 print\_color(GREEN, "Setup complete!")\
 else:\
 print\_color(YELLOW, "Setup had issues. Please run manually:")\
 print(" source ./setup")\
 return 0\
\
def merge\_lora\_adapter(base\_model\_id, lora\_path, cache\_dir=None, token=None):\
 """Merge a LoRA adapter into a base model and return the merged model."""\
 try:\
 from peft import PeftModel\
 except ImportError:\
 print\_color(RED, "Error: peft package required for LoRA merging")\
 print("Install with: pip install peft")\
 return None, None\
\
 from transformers import AutoModelForCausalLM, AutoTokenizer\
\
 print\_color(YELLOW, f"Loading base model: {base\_model\_id}")\
 base\_model = AutoModelForCausalLM.from\_pretrained(\
 base\_model\_id,\
 cache\_dir=cache\_dir,\
 trust\_remote\_code=True,\
 dtype=torch.bfloat16,\
 token=token\
 )\
 tokenizer = AutoTokenizer.from\_pretrained(\
 base\_model\_id,\
 cache\_dir=cache\_dir,\
 trust\_remote\_code=True,\
 token=token\
 )\
\
 print\_color(YELLOW, f"Loading LoRA adapter: {lora\_path}")\
 model = PeftModel.from\_pretrained(base\_model, lora\_path, token=token)\
\
 print\_color(YELLOW, "Merging LoRA weights into base model...")\
 merged\_model = model.merge\_and\_unload()\
\
 print\_color(GREEN, "LoRA merge complete")\
 return merged\_model, tokenizer\
\
def cmd\_convert(args):\
 """Convert a HuggingFace model to a custom output directory."""\
 import tempfile\
\
 model\_id = args.model\_name\
 output\_dir = args.output\_dir\
 lora\_path = getattr(args, 'lora', None)\
\
 if output\_dir is None:\
 output\_dir = get\_weights\_dir(model\_id)\
 else:\
 output\_dir = Path(output\_dir)\
\
 cache\_dir = getattr(args, 'cache\_dir', None)\
 token = getattr(args, 'token', None)\
\
 temp\_merged\_dir = None\
\
 if lora\_path:\
 merged\_model, tokenizer = merge\_lora\_adapter(model\_id, lora\_path, cache\_dir, token)\
 if merged\_model is None:\
 return 1\
\
 temp\_merged\_dir = tempfile.mkdtemp(prefix="cactus\_lora\_merged\_")\
 print\_color(YELLOW, f"Saving merged model to temp directory: {temp\_merged\_dir}")\
 merged\_model.save\_pretrained(temp\_merged\_dir)\
 tokenizer.save\_pretrained(temp\_merged\_dir)\
\
 lora\_tok\_config = Path(lora\_path) / "tokenizer\_config.json"\
 if lora\_tok\_config.exists():\
 shutil.copy2(lora\_tok\_config, Path(temp\_merged\_dir) / "tokenizer\_config.json")\
\
 del merged\_model\
 import torch\
 if torch.cuda.is\_available():\
 torch.cuda.empty\_cache()\
\
 model\_id = temp\_merged\_dir\
\
 class DownloadArgs:\
 pass\
\
 download\_args = DownloadArgs()\
 download\_args.model\_id = model\_id\
 download\_args.original\_model\_id = args.model\_name\
 download\_args.precision = args.precision\
 download\_args.cache\_dir = cache\_dir\
 download\_args.token = token\
 download\_args.reconvert = True\
\
 original\_get\_weights = get\_weights\_dir\
\
 def custom\_weights\_dir(mid):\
 return output\_dir\
\
 import src.cli as cli\_module\
 cli\_module.get\_weights\_dir = custom\_weights\_dir\
\
 try:\
 result = cmd\_download(download\_args)\
 return result\
 finally:\
 cli\_module.get\_weights\_dir = original\_get\_weights\
 if temp\_merged\_dir and Path(temp\_merged\_dir).exists():\
 print\_color(YELLOW, "Cleaning up temp directory...")\
 shutil.rmtree(temp\_merged\_dir)\
\
def cmd\_list(args):\
 """List all supported models and their download status."""\
 PIPELINE\_DISPLAY = {\
 "text-generation": "Text Generation",\
 "image-text-to-text": "Vision",\
 "automatic-speech-recognition": "Speech Recognition",\
 "feature-extraction": "Embeddings",\
 "voice-activity-detection": "Voice Activity Detection",\
 }\
 PIPELINE\_ORDER = list(PIPELINE\_DISPLAY.keys())\
 SHOW\_TAGS = {"tools", "vision", "embed", "transcription"}\
 EMBED\_ALIASES = {"text-embed", "image-embed", "speech-embed"}\
\
 DIM = '\\033\[2m'\
 BOLD = '\\033\[1m'\
\
 def filter\_tags(tags):\
 result = set()\
 for t in tags:\
 if t in SHOW\_TAGS:\
 result.add(t)\
 elif t in EMBED\_ALIASES:\
 result.add("embed")\
 return sorted(result)\
\
 def get\_dir\_size(path):\
 total = 0\
 for entry in path.rglob('\*'):\
 if entry.is\_file():\
 total += entry.stat().st\_size\
 return total\
\
 def format\_size(size\_bytes):\
 if size\_bytes >= 1\_000\_000\_000:\
 return f"{size\_bytes / 1\_073\_741\_824:.1f} GB"\
 return f"{size\_bytes / 1\_048\_576:.0f} MB"\
\
 # Group models by pipeline\_tag preserving order\
 groups = {}\
 for entry in MODELS\_REGISTRY:\
 tag = entry\["pipeline\_tag"\]\
 groups.setdefault(tag, \[\]).append(entry)\
\
 # Find max model name length for alignment\
 max\_name = max(len(e\["model"\]) for e in MODELS\_REGISTRY)\
 max\_tags\_len = 20\
\
 only\_downloaded = getattr(args, 'downloaded', False)\
\
 if only\_downloaded:\
 print(f"\\n {BOLD}Downloaded Models{NC}")\
 else:\
 print(f"\\n {BOLD}Supported Models{NC}")\
 print(f" {'─' \* 66}")\
\
 for ptag in PIPELINE\_ORDER:\
 models = groups.get(ptag)\
 if not models:\
 continue\
\
 section = PIPELINE\_DISPLAY\[ptag\]\
 section\_printed = False\
\
 for entry in models:\
 model\_id = entry\["model"\]\
 tags = filter\_tags(entry\["tags"\])\
 tags\_str = ", ".join(tags)\
\
 weights\_dir = get\_weights\_dir(model\_id)\
 config\_path = weights\_dir / "config.txt"\
 downloaded = config\_path.exists()\
\
 if only\_downloaded and not downloaded:\
 continue\
\
 if not section\_printed:\
 print(f"\\n {BOLD}{section}{NC}")\
 section\_printed = True\
\
 if downloaded:\
 prefix = f" {GREEN}\\u2b07{NC} "\
 # Read quantization (weight quantization level, not compute precision)\
 quantization = ""\
 try:\
 for line in config\_path.read\_text().splitlines():\
 if line.startswith("quantization="):\
 quantization = line.split("=", 1)\[1\].strip()\
 break\
 except OSError:\
 pass\
 dir\_size = get\_dir\_size(weights\_dir)\
 size\_str = format\_size(dir\_size)\
 if quantization:\
 info = f"{size\_str} ({quantization})"\
 else:\
 info = size\_str\
 else:\
 prefix = " "\
 info = ""\
\
 name\_pad = model\_id.ljust(max\_name)\
 tags\_pad = tags\_str.ljust(max\_tags\_len)\
\
 if info:\
 print(f"{prefix}{name\_pad} {DIM}{tags\_pad}{NC} {info}")\
 else:\
 print(f"{prefix}{name\_pad} {DIM}{tags\_pad}{NC}")\
\
 print()\
 return 0\
\
def create\_parser():\
 """Create the argument parser with all subcommands."""\
 parser = argparse.ArgumentParser(\
 formatter\_class=argparse.RawDescriptionHelpFormatter,\
 usage=argparse.SUPPRESS,\
 description="""\
\
 -----------------------------------------------------------------\
\
 How to use the Cactus Repo/CLI:\
\
 -----------------------------------------------------------------\
\
 cactus auth manage Cactus Cloud API key\
 shows status and prompts to set key\
\
 Optional flags:\
 --status show key status without prompting\
 --clear remove the saved API key\
\
 -----------------------------------------------------------------\
\
 cactus run  opens playground for the model\
 auto downloads and spins up\
\
 Optional flags:\
 --precision INT4\|INT8\|FP16 default: INT4\
 --token  HF token (for gated models)\
 --reconvert force model weights reconversion from source\
\
 -----------------------------------------------------------------\
\
 cactus transcribe \[model\] live microphone transcription\
 default model: parakeet-tdt-0.6b-v3\
\
 Optional flags:\
 --file  transcribe audio file instead of mic\
 --precision INT4\|INT8\|FP16 default: INT4\
 --token  HF token (for gated models)\
 --reconvert force model weights reconversion from source\
\
 Examples:\
 cactus transcribe live microphone transcription\
 cactus transcribe --file audio.wav transcribe single file\
 cactus transcribe nvidia/parakeet-ctc-1.1b use different model\
 cactus transcribe nvidia/parakeet-tdt-0.6b-v3 --file audio.wav\
\
 -----------------------------------------------------------------\
\
 cactus download  downloads model to ./weights\
 see supported weights on ReadMe\
\
 Optional flags:\
 --precision INT4\|INT8\|FP16 quantization (default: INT4)\
 --token  HuggingFace API token\
 --reconvert force model weights reconversion from source\
\
 -----------------------------------------------------------------\
\
 cactus convert  \[output\_dir\] converts model to custom directory\
 supports LoRA adapter merging\
\
 Optional flags:\
 --precision INT4\|INT8\|FP16 quantization (default: INT4)\
 --lora  LoRA adapter path to merge\
 --token  HuggingFace API token\
\
 -----------------------------------------------------------------\
\
 cactus build builds cactus for ARM chips\
 output: build/libcactus.a\
\
 Optional flags:\
 --apple build for Apple (iOS/macOS)\
 --android build for Android\
 --flutter build for Flutter (all platforms)\
 --python build shared lib for Python FFI\
\
 -----------------------------------------------------------------\
\
 cactus test runs unit tests and benchmarks\
 all must pass for contributions\
\
 Optional flags:\
 --model  default: LFM2-VL-450M\
 --transcribe\_model  default: nvidia/parakeet-tdt-0.6b-v3\
 --whisper\_model  default: openai/whisper-small (language detection)\
 --benchmark use larger models (LFM2.5-VL-1.6B + nvidia/parakeet-ctc-1.1b)\
 --precision INT4\|INT8\|FP16 regenerates weights with precision\
 --reconvert force model weights reconversion from source\
 --no-rebuild skip building library and tests\
 --llm run only LLM tests\
 --vlm run only VLM tests\
 --stt run only speech-to-text tests\
 --embed run only embedding tests\
 --rag run only RAG tests\
 --graph run only graph tests\
 --index run only index tests\
 --kernel run only kernel tests\
 --kv\_cache run only KV cache tests\
 --performance run only performance benchmarks\
 --ios run on connected iPhone\
 --android run on connected Android\
\
 -----------------------------------------------------------------\
\
 cactus list list all supported models\
 shows download status\
\
 -----------------------------------------------------------------\
\
 cactus clean removes all build artifacts\
\
 -----------------------------------------------------------------\
\
 cactus --help shows these instructions\
\
 -----------------------------------------------------------------\
\
 Python bindings:\
\
 Cactus python package is auto installed for researchers and testing\
 Please see python/example.py and run the following instructions.\
\
 1\. cactus build\
 2\. cactus download LiquidAI/LFM2-VL-450M\
 3\. python python/example.py\
\
 Note: Use any supported model\
\
 \-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\
"""\
 )\
\
 subparsers = parser.add\_subparsers(dest='command')\
 subparsers.required = False\
\
 for action in parser.\_actions:\
 if isinstance(action, argparse.\_SubParsersAction):\
 action.help = argparse.SUPPRESS\
\
 parser.\_action\_groups = \[\]\
\
 download\_parser = subparsers.add\_parser('download', help='Download and convert model weights')\
 download\_parser.add\_argument('model\_id', nargs='?', default=DEFAULT\_MODEL\_ID,\
 help=f'HuggingFace model ID (default: {DEFAULT\_MODEL\_ID})')\
 download\_parser.add\_argument('--precision', choices=\['INT4', 'INT8', 'FP16'\], default='INT4',\
 help='Quantization precision (default: INT4)')\
 download\_parser.add\_argument('--cache-dir', help='Cache directory for HuggingFace models')\
 download\_parser.add\_argument('--token', help='HuggingFace API token')\
\
 download\_parser.add\_argument('--weights-variant', choices=WEIGHTS\_VARIANT\_CHOICES, default='auto',\
 help='Weights package preference: auto (default), apple, or standard')\
 download\_parser.add\_argument('--reconvert', action='store\_true',\
 help='Download original model and convert (instead of using pre-converted from Cactus-Compute)')\
\
 build\_parser = subparsers.add\_parser('build', help='Build the chat application')\
 build\_parser.add\_argument('--apple', action='store\_true',\
 help='Build for Apple platforms (iOS/macOS)')\
 build\_parser.add\_argument('--android', action='store\_true',\
 help='Build for Android')\
 build\_parser.add\_argument('--flutter', action='store\_true',\
 help='Build for Flutter (iOS, macOS, Android)')\
 build\_parser.add\_argument('--python', action='store\_true',\
 help='Build shared library for Python FFI')\
\
 run\_parser = subparsers.add\_parser('run', help='Build, download (if needed), and run chat')\
 run\_parser.add\_argument('model\_id', nargs='?', default=DEFAULT\_MODEL\_ID,\
 help=f'HuggingFace model ID (default: {DEFAULT\_MODEL\_ID})')\
 run\_parser.add\_argument('--precision', choices=\['INT4', 'INT8', 'FP16'\], default='INT4',\
 help='Quantization precision (default: INT4)')\
 run\_parser.add\_argument('--cache-dir', help='Cache directory for HuggingFace models')\
 run\_parser.add\_argument('--token', help='HuggingFace API token')\
 run\_parser.add\_argument('--weights-variant', choices=WEIGHTS\_VARIANT\_CHOICES, default='auto',\
 help='Weights package preference for auto-download: auto, apple, or standard')\
 run\_parser.add\_argument('--no-cloud-tele', action='store\_true',\
 help='Disable cloud telemetry (write to cache only)')\
 run\_parser.add\_argument('--reconvert', action='store\_true',\
 help='Download original model and convert (instead of using pre-converted from Cactus-Compute)')\
 run\_parser.add\_argument('--image',\
 help='Path to image file for VLM inference (attached to first message)')\
 run\_parser.add\_argument('--audio',\
 help='Path to audio file (WAV) for audio chat (attached to first message)')\
 run\_parser.add\_argument('--system',\
 help='System prompt to prepend to all messages')\
 run\_parser.add\_argument('--prompt',\
 help='Initial prompt to send immediately')\
 run\_parser.add\_argument('--thinking', action='store\_true',\
 help='Enable thinking/reasoning for models that support it')\
\
 transcribe\_parser = subparsers.add\_parser('transcribe', help='Download ASR model and run transcription')\
 transcribe\_parser.add\_argument('model\_id', nargs='?', default=DEFAULT\_ASR\_MODEL\_ID,\
 help=f'HuggingFace model ID (default: {DEFAULT\_ASR\_MODEL\_ID})')\
 transcribe\_parser.add\_argument('--file', dest='audio\_file', default=None,\
 help='Audio file to transcribe (WAV format). Omit for live microphone.')\
 transcribe\_parser.add\_argument('--language', default='en',\
 help='Language code for transcription (default: en). Examples: es, fr, de, zh, ja')\
 transcribe\_parser.add\_argument('--precision', choices=\['INT4', 'INT8', 'FP16'\], default='INT4',\
 help='Quantization precision (default: INT4)')\
 transcribe\_parser.add\_argument('--cache-dir', help='Cache directory for HuggingFace models')\
 transcribe\_parser.add\_argument('--token', help='HuggingFace API token')\
 transcribe\_parser.add\_argument('--no-cloud-tele', action='store\_true',\
 help='Disable cloud telemetry (write to cache only)')\
 transcribe\_parser.add\_argument('--force-handoff', action='store\_true',\
 help='Force cloud handoff by assuming low confidence')\
 transcribe\_parser.add\_argument('--reconvert', action='store\_true',\
 help='Download original model and convert (instead of using pre-converted from Cactus-Compute)')\
 transcribe\_parser.add\_argument('--android', action='store\_true',\
 help='Run transcription on a connected Android device (requires --file)')\
 transcribe\_parser.add\_argument('--ios', action='store\_true',\
 help='Run transcription on a connected iOS device (requires --file)')\
 transcribe\_parser.add\_argument('--device', default=None,\
 help='ADB device ID to use with --android')\
\
 eval\_parser = subparsers.add\_parser('eval', help='Run evaluation scripts outside the cactus submodule')\
 eval\_parser.add\_argument('model\_id', nargs='?', default=DEFAULT\_MODEL\_ID,\
 help=f'HuggingFace model ID (default: {DEFAULT\_MODEL\_ID})')\
 eval\_parser.add\_argument('--precision', choices=\['INT4', 'INT8', 'FP16'\], default='INT4',\
 help='Quantization precision (default: INT4)')\
 eval\_parser.add\_argument('--cache-dir', help='Cache directory for HuggingFace models')\
 eval\_parser.add\_argument('--token', help='HuggingFace API token')\
 eval\_parser.add\_argument('--weights-variant', choices=WEIGHTS\_VARIANT\_CHOICES, default='auto',\
 help='Weights package preference for auto-download: auto, apple, or standard')\
 eval\_parser.add\_argument('--tools', action='store\_true', help='Run tools evals (default)')\
 eval\_parser.add\_argument('--vlm', action='store\_true', help='Run VLM-specific evals')\
 eval\_parser.add\_argument('--stt', action='store\_true', help='Run speech-to-text evals')\
 eval\_parser.add\_argument('--llm', action='store\_true', help='Run LLM evals')\
 eval\_parser.add\_argument('--embed', action='store\_true', help='Run embedding evals')\
 eval\_parser.add\_argument('--no-cloud-tele', action='store\_true',\
 help='Disable cloud telemetry (write to cache only)')\
 eval\_parser.add\_argument('--reconvert', action='store\_true',\
 help='Download original model and convert (instead of using pre-converted from Cactus-Compute)')\
\
 test\_parser = subparsers.add\_parser('test', help='Run the test suite')\
 test\_parser.add\_argument('--model', default='LiquidAI/LFM2-VL-450M',\
 help='Model to use for tests')\
 test\_parser.add\_argument('--transcribe\_model', default=DEFAULT\_TEST\_TRANSCRIBE\_MODEL\_ID,\
 help='Transcribe model to use')\
 test\_parser.add\_argument('--whisper\_model', default=DEFAULT\_TEST\_WHISPER\_MODEL\_ID,\
 help='Whisper model to use for language detection tests')\
 test\_parser.add\_argument('--vad\_model', default='snakers4/silero-vad',\
 help='VAD model to use')\
 test\_parser.add\_argument('--diarize\_model', default=DEFAULT\_TEST\_DIARIZE\_MODEL\_ID,\
 help='Diarization model to use')\
 test\_parser.add\_argument('--embed\_speaker\_model', default=DEFAULT\_TEST\_EMBED\_SPEAKER\_MODEL\_ID,\
 help='Speaker embedding model to use')\
 test\_parser.add\_argument('--benchmark', action='store\_true',\
 help='Use larger models (LFM2.5-VL-1.6B + nvidia/parakeet-ctc-1.1b)')\
 test\_parser.add\_argument('--precision', choices=\['INT4', 'INT8', 'FP16'\],\
 help='Regenerate weights with this precision (deletes existing weights)')\
 test\_parser.add\_argument('--no-rebuild', action='store\_true',\
 help='Skip building cactus library and tests')\
 test\_parser.add\_argument('--token', help='HuggingFace API token')\
 test\_parser.add\_argument('--android', action='store\_true',\
 help='Run tests on Android')\
 test\_parser.add\_argument('--ios', action='store\_true',\
 help='Run tests on iOS')\
 test\_parser.add\_argument('--exhaustive', action='store\_true',\
 help='Run exhaustive golden tests for all model families and precisions')\
 test\_parser.add\_argument('--only', help='(deprecated, use -- instead) Only run the specified test')\
 for \_test\_name in \['llm', 'vlm', 'stt', 'embed', 'rag', 'graph', 'index', 'kernel', 'kv\_cache', 'performance'\]:\
 test\_parser.add\_argument(f'--{\_test\_name}', action='store\_true',\
 help=f'Only run the {\_test\_name} tests')\
 test\_parser.add\_argument('--enable-telemetry', action='store\_true',\
 help='Enable cloud telemetry (disabled by default in tests)')\
 test\_parser.add\_argument('--reconvert', action='store\_true',\
 help='Download original model and convert (instead of using pre-converted from Cactus-Compute)')\
\
 auth\_parser = subparsers.add\_parser('auth', help='Manage Cactus Cloud API key')\
 auth\_parser.add\_argument('--clear', action='store\_true',\
 help='Remove the saved API key')\
 auth\_parser.add\_argument('--status', action='store\_true',\
 help='Show current key status without prompting')\
\
 clean\_parser = subparsers.add\_parser('clean', help='Remove all build artifacts')\
\
 list\_parser = subparsers.add\_parser('list', help='List supported models')\
 list\_parser.add\_argument('--downloaded', action='store\_true',\
 help='Only show downloaded models')\
\
 convert\_parser = subparsers.add\_parser('convert', help='Convert model to custom output directory')\
 convert\_parser.add\_argument('model\_name', help='HuggingFace model name')\
 convert\_parser.add\_argument('output\_dir', nargs='?', default=None,\
 help='Output directory (default: weights/)')\
 convert\_parser.add\_argument('--precision', choices=\['INT4', 'INT8', 'FP16'\], default='INT4',\
 help='Quantization precision (default: INT4)')\
 convert\_parser.add\_argument('--cache-dir', help='Cache directory for HuggingFace models')\
 convert\_parser.add\_argument('--token', help='HuggingFace API token')\
 convert\_parser.add\_argument('--lora', help='Path to LoRA adapter (local path or HuggingFace ID) to merge before conversion')\
\
 return parser\
\
def preprocess\_eval\_args(parser, argv):\
 args, unknown = parser.parse\_known\_args(argv)\
\
 if getattr(args, 'command', None) == 'eval':\
 setattr(args, 'extra\_args', unknown)\
 return args\
\
 if unknown:\
 parser.error(f"unrecognized arguments: {' '.join(unknown)}")\
\
 return args\
\
def main():\
 """Main entry point for the Cactus CLI."""\
 parser = create\_parser()\
\
 argv = sys.argv\[1:\]\
 args = preprocess\_eval\_args(parser, argv)\
\
 if args.command == 'download':\
 sys.exit(cmd\_download(args))\
 elif args.command == 'build':\
 sys.exit(cmd\_build(args))\
 elif args.command == 'run':\
 sys.exit(cmd\_run(args))\
 elif args.command == 'transcribe':\
 sys.exit(cmd\_transcribe(args))\
 elif args.command == 'test':\
 sys.exit(cmd\_test(args))\
 elif args.command == 'eval':\
 sys.exit(cmd\_eval(args))\
 elif args.command == 'auth':\
 sys.exit(cmd\_auth(args))\
 elif args.command == 'clean':\
 sys.exit(cmd\_clean(args))\
 elif args.command == 'list':\
 sys.exit(cmd\_list(args))\
 elif args.command == 'convert':\
 sys.exit(cmd\_convert(args))\
 else:\
 parser.print\_help()\
 sys.exit(1)\
\
if \_\_name\_\_ == '\_\_main\_\_':\
 main()