#!/usr/bin/env python3
"""QDQ a packaged Gemma4 assistant cactus weights directory back to HF safetensors."""
from \_\_future\_\_ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

import torch
from safetensors.torch import save\_file

sys.path.insert(0, "/workspace/turboquant\_sanitized/scripts/export")
from cactus\_packed\_to\_qdq\_fp16 import ( # noqa: E402
 CONFIG\_FILES,
 PRECISION\_CQ,
 PRECISION\_FP16,
 PRECISION\_FP32,
 PRECISION\_INT8,
 dequantize\_cq\_file,
 dequantize\_fp\_file,
 dequantize\_int8\_file,
 read\_header,
)

DIRECT = {
 "token\_embeddings": "model.embed\_tokens.weight",
 "output\_weight": "lm\_head.weight",
 "output\_norm": "model.norm.weight",
 "pre\_projection": "pre\_projection.weight",
 "post\_projection": "post\_projection.weight",
 "masked\_embedding\_centroids": "masked\_embedding.centroids.weight",
}

LAYER\_SUFFIXES = {
 "attn\_q": "self\_attn.q\_proj.weight",
 "attn\_output": "self\_attn.o\_proj.weight",
 "ffn\_gate": "mlp.gate\_proj.weight",
 "ffn\_up": "mlp.up\_proj.weight",
 "ffn\_down": "mlp.down\_proj.weight",
 "input\_norm": "input\_layernorm.weight",
 "attn\_q\_norm": "self\_attn.q\_norm.weight",
 "post\_attn\_norm": "post\_attention\_layernorm.weight",
 "pre\_ffn\_norm": "pre\_feedforward\_layernorm.weight",
 "post\_ffn\_norm": "post\_feedforward\_layernorm.weight",
 "layer\_scalar": "layer\_scalar",
}

def hf\_key\_for\_file(path: Path) -> str \| None:
 stem = path.name.removesuffix(".weights")
 if stem in DIRECT:
 return DIRECT\[stem\]
 parts = stem.split("\_", 2)
 if len(parts) == 3 and parts\[0\] == "layer" and parts\[1\].isdigit():
 suffix = LAYER\_SUFFIXES.get(parts\[2\])
 if suffix:
 return f"model.layers.{parts\[1\]}.{suffix}"
 return None

def copy\_runtime\_files(src: Path, out: Path) -> None:
 for path in src.iterdir():
 if path.is\_file() and path.name in CONFIG\_FILES:
 shutil.copy2(path, out / path.name)

def load\_weight(path: Path, dtype: torch.dtype, row\_batch\_size: int) -> torch.Tensor:
 header = read\_header(path)
 if header.precision in PRECISION\_CQ:
 return dequantize\_cq\_file(path, header, dtype, row\_batch\_size)
 if header.precision in {PRECISION\_FP16, PRECISION\_FP32}:
 return dequantize\_fp\_file(path, header, dtype)
 if header.precision == PRECISION\_INT8:
 return dequantize\_int8\_file(path, header, dtype)
 raise ValueError(f"{path.name}: unsupported precision={header.precision}")

def load\_token\_ordering(src: Path) -> torch.Tensor \| None:
 sidecar = src / "masked\_embedding\_token\_ordering.json"
 if not sidecar.exists():
 return None
 data = json.loads(sidecar.read\_text(encoding="utf-8"))
 return torch.tensor(data\["values"\], dtype=torch.long).reshape(tuple(data\["shape"\]))

def write\_index\_if\_needed(out: Path, tensors: dict\[str, torch.Tensor\], shard: str = "model.safetensors") -> None:
 total = sum(t.numel() \* t.element\_size() for t in tensors.values())
 index = {
 "metadata": {"total\_size": str(total)},
 "weight\_map": {key: shard for key in sorted(tensors)},
 }
 (out / "model.safetensors.index.json").write\_text(json.dumps(index, indent=2) + "\\n", encoding="utf-8")

def main() -> None:
 parser = argparse.ArgumentParser()
 parser.add\_argument("--cactus", default="/workspace/gemma4\_assistant\_quant/gemma4\_e2b\_it\_assistant\_cactus\_cq4\_smoke")
 parser.add\_argument("--out", default="/workspace/gemma4\_assistant\_quant/gemma4\_e2b\_it\_assistant\_cactus\_qdq\_smoke")
 parser.add\_argument("--dtype", choices=\["float16", "bfloat16", "float32"\], default="bfloat16")
 parser.add\_argument("--row-batch-size", type=int, default=512)
 parser.add\_argument("--force", action="store\_true")
 args = parser.parse\_args()

 dtype = {"float16": torch.float16, "bfloat16": torch.bfloat16, "float32": torch.float32}\[args.dtype\]
 src = Path(args.cactus)
 out = Path(args.out)
 if out.exists():
 if not args.force:
 raise SystemExit(f"{out} exists; pass --force")
 shutil.rmtree(out)
 out.mkdir(parents=True, exist\_ok=True)
 copy\_runtime\_files(src, out)

 tensors: dict\[str, torch.Tensor\] = {}
 manifest = \[\]
 for path in sorted(src.glob("\*.weights")):
 key = hf\_key\_for\_file(path)
 if key is None:
 raise SystemExit(f"no HF key mapping for {path.name}")
 tensor = load\_weight(path, dtype, args.row\_batch\_size)
 if key in tensors:
 raise SystemExit(f"duplicate HF key {key}")
 tensors\[key\] = tensor
 manifest.append({"file": path.name, "hf\_key": key, "shape": list(tensor.shape), "dtype": str(tensor.dtype)})

 ordering = load\_token\_ordering(src)
 if ordering is not None:
 tensors\["masked\_embedding.token\_ordering"\] = ordering
 manifest.append({
 "file": "masked\_embedding\_token\_ordering.json",
 "hf\_key": "masked\_embedding.token\_ordering",
 "shape": list(ordering.shape),
 "dtype": str(ordering.dtype),
 })

 save\_file(tensors, out / "model.safetensors")
 write\_index\_if\_needed(out, tensors)
 (out / "qdq\_manifest.json").write\_text(json.dumps(manifest, indent=2) + "\\n", encoding="utf-8")
 summary = {
 "source": str(src),
 "out": str(out),
 "tensor\_count": len(tensors),
 "dtype": args.dtype,
 "bytes": sum(t.numel() \* t.element\_size() for t in tensors.values()),
 }
 (out / "qdq\_summary.json").write\_text(json.dumps(summary, indent=2) + "\\n", encoding="utf-8")
 print(json.dumps(summary, indent=2))

if \_\_name\_\_ == "\_\_main\_\_":
 main()