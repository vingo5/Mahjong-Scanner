"""Downloads the Roboflow Mahjong dataset (CC BY 4.0, project-xv49e/mahjong-x5dzz)
into ml/data/ in YOLOv8 format."""

import os
from pathlib import Path
from dotenv import load_dotenv
from roboflow import Roboflow

# Explicit path — robust no matter what directory you run this script from
env_path = Path(__file__).resolve().parent.parent / ".env"  # ml/.env
load_dotenv(dotenv_path=env_path)

api_key = os.environ.get("ROBOFLOW_API_KEY")
if not api_key:
    raise RuntimeError(f"Set ROBOFLOW_API_KEY in {env_path} first")

rf = Roboflow(api_key=api_key)
project = rf.workspace("project-xv49e").project("mahjong-x5dzz")

data_dir = Path(__file__).resolve().parent.parent / "data" / "roboflow_v2"
dataset = project.version(2).download("yolov8", location=str(data_dir))

print(f"Downloaded to: {dataset.location}")