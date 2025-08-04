# Image Data in Manufacturing 4.0 - Veo3 Video Generation & Stitching Guide

## 🎯 Objective

Create a 24-second video illustrating the ubiquity of image data in Manufacturing 4.0 by stitching together five AI-generated video segments using Google Veo 3.

## 📼 Final Segments Used

1. **seg1.mp4** — Hole Diameter Measurement (Stamping Line)
2. **seg2.mp4** — Painted Surface Defect Detection (Automotive Assembly)
3. **seg3.mp4** — Additive Manufacturing Monitoring (Laser Powder Bed Fusion)
4. **seg5a.mp4** — Outro Message: "image data / manufacturing 4.0"
5. **seg5b.mp4** — Credits

> Note: The original poka-yoke segment was skipped. Also, segments 5a and 5b were trimmed to remove rendering errors related to text generation.

---

## 🎬 Veo3 Prompts (Exact Prompts Used Per Segment)

### **Segment 1 — Hole Diameter Check (Stamping Line)**

> Show a stamped metal sheet moving on a high-speed conveyor inside a factory. A robotic vision system captures an image of a circular hole from above. Cut to a monitor displaying the image of the part. Overlay a circle and measurement line across the diameter. Show only the following simple text on screen (no punctuation):\
> – `hole check`\
> – `8 mm`\
> – `ok`\
> Background should include conveyor, rollers, and faint shop-floor movement. Use realistic lighting glare on the monitor. Transition out with a slow zoom into the measurement.

### **Segment 2 — Painted Surface Defect Detection (Automotive Assembly)**

> Show a completed car body moving slowly along a final inspection zone inside an automotive paint facility. The vehicle should be fully assembled — doors, windows, handles, and mirrors all present. The camera tracks along the driver-side door, which reflects bright overhead inspection lights.\
> Cut to a monitor view from a machine vision system inspecting the door’s surface. The screen shows a zoomed-in camera image of the painted metal door — clean, complete, and glossy. A small surface scratch is visible near the lower corner of the door panel.\
> Overlay a red rectangle on the scratch. Show only the following simple text near the defect (lowercase, no punctuation):\
> – `scratch`\
> – `zone b3`\
> – `review`\
> Use factory-accurate lighting (white inspection tubes above), maintain reflections, and ensure the window and trim are visible but untouched. Transition out with a slight pan as the car moves to the next station.

### **Segment 3 — Additive Manufacturing Monitoring (Laser Powder Bed Fusion)**

> Inside a metal 3D printing lab, show a laser powder bed fusion (LPBF) machine mid-process. Transition in from black. Display the glowing red laser tracing patterns in the chamber as thin powder layers are fused.\
> Cut to a large monitor beside the machine showing two synchronized camera feeds:\
> – Left: a thermal image of the build area with a glowing hotspot\
> – Right: a grayscale visual of the current printed layer\
> Overlay minimal and clean text directly on the monitor image (no punctuation):\
> – `layer 42`\
> – `hot zone`\
> – `check pore`\
> Use blue and orange tones to differentiate thermal and visible views. Reflections of lab tools, print operators, and soft interior lighting should add realism. End the scene with a zoom into the monitor as the camera locks onto the hotspot.

### **Segment 5a — Outro Message**

> Start with a solid black background. Fade in bold white text centered on screen with a soft pulse:\
> – `image data`\
> After 1 second, fade in a second line just below:\
> – `manufacturing 40`\
> Hold both lines for 2 seconds. Add a soft ambient glow around the text and a faint industrial hum in the background. End the scene with a slow fade to black.\
> Do not include any extra logos, punctuation, or visual effects. The screen should remain clean and focused.

### **Segment 5b — Credits**

> Begin with a solid black background. Fade in stacked white text centered on screen, in simple sans-serif font:\
> – `by fadel megahed`\
> – `via google veo 3`\
> – `generated on july 07 2025`\
> Hold for 2 seconds, then fade to black. Do not use punctuation or logos.

---

## 🛠️ FFmpeg Commands

### **1. Concatenate the Segments**

Create `mylist.txt`:

```text
file 'seg1.mp4'
file 'seg2.mp4'
file 'seg3.mp4'
file 'seg5a.mp4'
file 'seg5b.mp4'
```

Then run:

```bash
ffmpeg -f concat -safe 0 -i mylist.txt -c copy image_qc_full.mp4
```

### **2. (Optional) Slow Video to Half Speed**

```bash
ffmpeg -i image_qc_full.mp4 -vf "setpts=2*PTS" -af "atempo=0.5" -c:v libx264 -crf 18 -preset veryfast image_qc_full_slow.mp4
```

### **3. (Optional) Trim Final Video**

```bash
ffmpeg -i image_qc_full_slow.mp4 -t 00:00:24 -c copy image_qc_final_trimmed.mp4
```

---

## ✅ Final Output

You will end up with:

- `image_qc_full.mp4` (original stitched)
- `image_qc_full_slow.mp4` (optional slow version)
- `image_qc_final_trimmed.mp4` (optional trimmed to 24 sec)

This video highlights key industrial uses of image data in modern manufacturing environments, focusing on dimensional inspection, surface quality, advanced imaging, and visual messaging.

