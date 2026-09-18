"""Train YOLOv8n on the Mahjong tile dataset."""

from pathlib import Path
from ultralytics import YOLO

# Absolute path to the dataset's data.yaml — avoids the relative-path
# bug we just hit with the download script
data_yaml = Path(__file__).resolve().parent.parent / "data" / "roboflow_v2" / "data.yaml"

model = YOLO("yolov8n.pt")  # nano — best size/speed tradeoff for on-device CoreML

results = model.train(
    data=str(data_yaml),
    epochs=100,
    imgsz=640,
    batch=16,
    patience=20,        # early stop if val loss plateaus
    name="mahjong_tiles_v1",
)

metrics = model.val()
print(f"mAP50-95: {metrics.box.map:.4f}")
print(f"mAP50: {metrics.box.map50:.4f}")