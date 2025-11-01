# 🧠 Civic Issue Object Classification using YOLOv9c

## 📘 Project Overview

This project automates the detection and classification of **urban civic issues**—such as potholes, garbage accumulation, waterlogging, broken streetlights, and damaged road signs—using a fine-tuned **YOLOv9c model** built on top of **PyTorch**.

The system forms part of a complete smart-city workflow where users can upload civic issue images, and **municipal officers** can manage, assign, and track issue resolution in real time.

The project leverages a robust **technical stack** integrating **machine learning, modern web frameworks, and cloud hosting** for a scalable end-to-end civic monitoring platform.

---

## 🎯 Key Objectives

- Automate the classification of civic issues from street-level images.
- Reduce manual inspection and reporting delays.
- Build an integrated system connecting citizens with municipal authorities.
- Enable data-driven city management and transparency.

---

## ⚙️ Model Details

| Feature                    | Description                                                  |
| -------------------------- | ------------------------------------------------------------ |
| **Model Architecture**     | YOLOv9c                                                      |
| **Parameters**             | 25.05 M Images                                               |
| **Fine Tuned Parameters**  | 7000 Images                                                  |
| **Total Layers**           | 314 Layers                                                   |
| **Framework**              | PyTorch                                                      |
| **Transfer Learning**      | Yes (fine-tuned with pre-trained YOLOv9c weights)            |
| **Training Dataset Size**  | 7,000 labeled images                                         |
| **Classes**                | 5 civic issue categories                                     |
| **Categories **            | Potholes, graffiti, fallen tree, damaged road sign , garbage |
| **Image Resolution**       | 640×640                                                      |
| **Optimizer**              | AdamW                                                        |
| **Loss Function**          | Composite (Bounding Box + Classification + Objectness)       |
| **Learning Rate Schedule** | Cosine Annealing                                             |
| **mAP@0.5**                | 70%                                                          |
| **FLOPS**                  | 102.8 B                                                      |
| **Latency**                | 18 ms                                                        |
| **Precision / Recall**     | 0.89 / 0.84                                                  |

---

## 🧠 About YOLOv9c

**YOLO (You Only Look Once)** is a one-stage, real-time object detection algorithm that predicts bounding boxes and class probabilities in a single network pass.

The **YOLOv9c variant** used in this project consists of approximately **150 layers**, making it both **compact and efficient** for edge deployment.

### Key Architectural Components:

- **Backbone:** CSP-Darknet — extracts multiscale image features.
- **Neck:** PANet — fuses low- and high-level features for object detection.
- **Head:** Decoupled detection head for simultaneous localization and classification.
- **SPPF (Spatial Pyramid Pooling – Fast):** Captures spatial context efficiently.

This configuration enables the model to identify small, irregular civic issues (like potholes or debris) under real-world lighting and perspective variations.

---

## 🗂️ Dataset Structure

```
dataset/
├── train/
│   ├── images/
│   └── labels/
├── val/
│   ├── images/
│   └── labels/
└── data.yaml
```

**Classes:**

- Pothole
- Garbage
- Waterlogging
- Broken Streetlight
- Open Manhole
- Damaged Road Sign

---

## 🧩 Model Training

1. **Environment Setup**

   ```bash
   git clone https://github.com/ultralytics/yolov9.git
   cd yolov9
   pip install -r requirements.txt
   ```

2. **Prepare Dataset**

   - Place images and labels under `/datasets`
   - Update `data.yaml` with paths and class names

3. **Training Command**

   ```bash
   yolo train model=yolov9c.pt data=data.yaml epochs=100 imgsz=640 batch=16 device=0
   ```

4. **Monitoring Training**
   ```bash
   tensorboard --logdir runs/train
   ```

---

## 🧰 Technical Stack

### 🔧 Hosting

- **Vercel**, **Docker**

### 💻 Frontend

- **Flutter** (mobile interface)
- **Next.js** (web dashboard)

### ⚙️ Backend

- **Python**, **Node.js**

### 🧠 Machine Learning

- **PyTorch**, **Scikit-Learn**

### 🗃️ Database

- **Supabase** (for cloud storage, user data, and issue repositories)

### 🧩 Models

- **YOLOv9c** (object detection and classification)
- **ResNet** (image feature extraction for similarity checks)

---

## 🧭 System Workflow

### 🧍‍♂️ User Side

1. **Upload Image:** User captures and uploads an image of a civic issue.
2. **Classification:** Fine-tuned YOLOv9c model classifies the object (pothole, garbage, broken sign, etc.).
3. **Location Tagging:** GPS coordinates are used to record the issue’s exact location.
4. **Duplicate Check:** System checks if a similar issue exists within a 20m radius using ResNet embeddings.
   - ✅ If **same issue**: report is added to the existing repository.
   - ❌ If **new issue**: a new repository entry is created.
5. **Repository Submitted:** Data stored in Supabase for review by municipal staff.

---

### 🏢 MNC (Municipal Corporation) Side

1. **Officer Review:** Officer accesses the dashboard and reviews issue repositories.
2. **Task Assignment:** Officer assigns the issue to field workers with a defined timeline.
3. **Work Execution:** Worker completes the assigned task and uploads proof images.
4. **Public Verification:** The public reviews completed work.
5. **Closure or Reversion:**
   - If work is **approved**, the repository is closed.
   - If **not approved**, it is reverted for rework.

This creates a **closed-loop civic maintenance system** ensuring transparency and accountability.

---

## 📊 Model Evaluation

| Metric              | Value                   |
| ------------------- | ----------------------- |
| **mAP@0.5**         | 0.7                     |
| **Precision**       | 0.89                    |
| **Recall**          | 0.84                    |
| **F1-Score**        | 0.86                    |
| **Inference Speed** | ~18 ms/frame (RTX 4060) |

---

## 💡 Applications

- Smart City Surveillance
- Automated Civic Issue Management
- Waste and Infrastructure Monitoring
- Urban Planning and Reporting

---

## 🧾 Future Enhancements

- Integration with live GPS tracking and GIS dashboards
- Edge deployment on Jetson Nano / Raspberry Pi
- Real-time alert system for high-priority issues
- Addition of multilingual voice-based reporting

---

## 🏆 Acknowledgements

- **Ultralytics YOLOv9** – Object Detection Framework
- **Roboflow** – Data Augmentation and Labeling
- **Supabase** – Cloud Database
- **Open Images Dataset** – Pretraining reference

---
