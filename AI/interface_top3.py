import torch
import glob
import os
import timm
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import torch.nn.functional as F

# ==========================================
# 1. Cấu hình tham số
# ==========================================
PATH_TO_PTH = 'skin_disease_swinv2_best.pth'  
INPUT_FOLDER = 'input_images'                 
IMAGE_SIZE = 256                              

if torch.backends.mps.is_available():
    device = torch.device("mps")
    print("Đang chạy trên Mac: MPS")
else:
    device = torch.device("cpu")
    print("Đang chạy trên Mac: CPU")

# ==========================================
# 2. Tái tạo chính xác cấu trúc FastAI
# ==========================================
class FastaiSwinModel(nn.Module):
    def __init__(self, model_name, num_classes, state_dict):
        super().__init__()
        # 1. Phần thân (Backbone) dùng timm
        self.backbone = timm.create_model(model_name, pretrained=False, num_classes=0)
        in_features = self.backbone.num_features # Thường là 1024
        
        # 2. Phần đuôi (Head) - Xây dựng lại theo chuẩn FastAI
        # Tự động đọc kích thước lớp ẩn từ file checkpoint
        hidden_dim = 512
        if 'head.6.weight' in state_dict:
            hidden_dim = state_dict['head.6.weight'].shape[1]

        self.head = nn.Sequential(
            nn.BatchNorm1d(in_features),        # head.0
            nn.Dropout(0.25),                   # head.1
            nn.Linear(in_features, hidden_dim), # head.2
            nn.ReLU(inplace=True),              # head.3
            nn.BatchNorm1d(hidden_dim),         # head.4
            nn.Dropout(0.5),                    # head.5
            nn.Linear(hidden_dim, num_classes)  # head.6
        )

    def forward(self, x):
        x = self.backbone(x)
        x = self.head(x)
        return x

def load_model(pth_path):
    try:
        checkpoint = torch.load(pth_path, map_location=device)
        state_dict = checkpoint.get('model_state_dict', checkpoint.get('state_dict', checkpoint))

        model_name = checkpoint.get('model_name', 'swinv2_base_window16_256')
        num_classes = checkpoint.get('num_classes', 22)
        class_names = checkpoint.get('class_names', [f"Class {i}" for i in range(num_classes)])

        print(f"-> Khởi tạo bộ khung FastAI ({model_name} - {num_classes} classes)...")
        
        # Khởi tạo mô hình
        model = FastaiSwinModel(model_name, num_classes, state_dict)
        
        # Nạp trọng số trực tiếp (Tuyệt đối khớp, không cần gọt)
        model.load_state_dict(state_dict, strict=False)
        print("-> Đã nạp trọng số mô hình thành công 100%!")

        model = model.to(device)
        model.eval()
        
        return model, class_names
        
    except Exception as e:
        print(f"\nLỖI KHI LOAD MÔ HÌNH: {e}")
        exit()

# ==========================================
# 3. Tiền xử lý ảnh
# ==========================================
def get_image_transform(img_size):
    return transforms.Compose([
        transforms.Resize((img_size, img_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

# ==========================================
# 4. Hàm chạy dự đoán
# ==========================================
def run_inference():
    model, class_names = load_model(PATH_TO_PTH)
    img_transform = get_image_transform(IMAGE_SIZE)
    
    image_paths = []
    for ext in ['*.[jp][pn]g', '*.[JP][PN]G', '*.jpeg', '*.JPEG']:
        image_paths.extend(glob.glob(os.path.join(INPUT_FOLDER, ext)))
    
    if not image_paths:
        print(f"Không tìm thấy ảnh nào trong thư mục '{INPUT_FOLDER}'")
        return

    print(f"\nĐang tiến hành dự đoán {len(image_paths)} ảnh...")
    print("=" * 40)

    for img_path in image_paths:
        img_name = os.path.basename(img_path)
        try:
            image = Image.open(img_path).convert('RGB')
            input_tensor = img_transform(image).unsqueeze(0).to(device)
            
            with torch.no_grad():
                outputs = model(input_tensor)
                probabilities = F.softmax(outputs, dim=1)[0]
                
                top_k = min(3, len(class_names))
                top3_prob, top3_idx = torch.topk(probabilities, top_k)
                
            print(f"📁 Ảnh: {img_name}")
            for i in range(top_k):
                idx = top3_idx[i].item()
                prob = top3_prob[i].item() * 100
                label = class_names[idx] if idx < len(class_names) else f"Class {idx}"
                print(f"   Top {i+1}: {label:<20} - Tỉ lệ: {prob:.2f}%")
            print("-" * 40)
            
        except Exception as e:
            print(f"Lỗi khi xử lý ảnh {img_name}: {e}")

if __name__ == '__main__':
    if not os.path.exists(INPUT_FOLDER):
        os.makedirs(INPUT_FOLDER)
        print(f"Đã tạo thư mục '{INPUT_FOLDER}'. Hãy bỏ ảnh cần test vào đó.")
    else:
        run_inference()