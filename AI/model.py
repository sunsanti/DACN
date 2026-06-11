"""
Model loading + image inference for the skin-disease classifier.
Architecture mirrors interface_top3.py (Swin V2 backbone + FastAI-style head).
Reused by the FastAPI service (app.py).
"""
import os
import torch
import torch.nn as nn
import torch.nn.functional as F
import timm
from torchvision import transforms
from PIL import Image

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PATH_TO_PTH = os.path.join(BASE_DIR, os.getenv("MODEL_PTH", "skin_disease_swinv2_best.pth"))
CLASSES_TXT = os.path.join(BASE_DIR, "classes.txt")
IMAGE_SIZE = int(os.getenv("IMAGE_SIZE", "256"))


def _select_device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    # Apple Silicon (dev machines); falls back to CPU elsewhere.
    if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


DEVICE = _select_device()


def _load_class_names_from_txt():
    if os.path.exists(CLASSES_TXT):
        with open(CLASSES_TXT, "r", encoding="utf-8") as f:
            return [line.strip() for line in f if line.strip()]
    return None


class FastaiSwinModel(nn.Module):
    """timm Swin V2 backbone + FastAI-style classification head."""

    def __init__(self, model_name, num_classes, state_dict):
        super().__init__()
        self.backbone = timm.create_model(model_name, pretrained=False, num_classes=0)
        in_features = self.backbone.num_features

        hidden_dim = 512
        if "head.6.weight" in state_dict:
            hidden_dim = state_dict["head.6.weight"].shape[1]

        self.head = nn.Sequential(
            nn.BatchNorm1d(in_features),          # head.0
            nn.Dropout(0.25),                     # head.1
            nn.Linear(in_features, hidden_dim),   # head.2
            nn.ReLU(inplace=True),                # head.3
            nn.BatchNorm1d(hidden_dim),           # head.4
            nn.Dropout(0.5),                      # head.5
            nn.Linear(hidden_dim, num_classes),   # head.6
        )

    def forward(self, x):
        return self.head(self.backbone(x))


def _image_transform(img_size: int):
    return transforms.Compose([
        transforms.Resize((img_size, img_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])


class SkinDiseaseClassifier:
    """Loads the .pth once and serves top-k predictions for an image."""

    def __init__(self, pth_path: str = PATH_TO_PTH):
        if not os.path.exists(pth_path):
            raise FileNotFoundError(
                f"Model weights not found: {pth_path}. "
                "Đặt file skin_disease_swinv2_best.pth vào thư mục AI/."
            )
        checkpoint = torch.load(pth_path, map_location=DEVICE)
        state_dict = checkpoint.get(
            "model_state_dict", checkpoint.get("state_dict", checkpoint)
        )
        model_name = checkpoint.get("model_name", "swinv2_base_window16_256")
        num_classes = checkpoint.get("num_classes", 22)
        self.class_names = (
            checkpoint.get("class_names")
            or _load_class_names_from_txt()
            or [f"Class {i}" for i in range(num_classes)]
        )

        self.model = FastaiSwinModel(model_name, num_classes, state_dict)
        self.model.load_state_dict(state_dict, strict=False)
        self.model.to(DEVICE).eval()
        self.transform = _image_transform(IMAGE_SIZE)

    @torch.no_grad()
    def predict_topk(self, image: Image.Image, k: int = 3):
        tensor = self.transform(image.convert("RGB")).unsqueeze(0).to(DEVICE)
        probs = F.softmax(self.model(tensor), dim=1)[0]
        k = min(k, len(self.class_names))
        top_prob, top_idx = torch.topk(probs, k)
        return [
            {
                "disease": self.class_names[i.item()] if i.item() < len(self.class_names)
                else f"Class {i.item()}",
                "confidence": round(p.item(), 4),
            }
            for p, i in zip(top_prob, top_idx)
        ]
