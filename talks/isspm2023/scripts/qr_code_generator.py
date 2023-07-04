
import numpy as np

import matplotlib.pyplot as plt

def spc_chart(data, control_limits):
    # Calculate the mean and standard deviation
    mean = np.mean(data)
    std = np.std(data)

    # Calculate the control limits
    upper_limit = mean + 3 * std
    lower_limit = mean - 3 * std

    # Plot the data and control limits
    plt.plot(data, 'bo-', label='Data')
    plt.axhline(upper_limit, color='r', linestyle='--', label='Upper Control Limit')
    plt.axhline(lower_limit, color='r', linestyle='--', label='Lower Control Limit')
    plt.axhline(mean, color='g', linestyle='-', label='Mean')

    # Highlight out-of-control points
    for i, point in enumerate(data):
        if point > upper_limit or point < lower_limit:
            plt.plot(i, point, 'ro')

    plt.xlabel('Sample')
    plt.ylabel('Value')
    plt.title('Generative AI Use in SPC')
    plt.legend()
    plt.show()

# Example usage
data = [10, 12, 11, 9, 10, 12, 8, 9, 11, 10, 12, 11, 9, 10, 12]
control_limits = (8, 12)  # Specify your control limits here

spc_chart(data, control_limits)



# import modules
import qrcode
from PIL import Image

# taking image which user wants
# in the QR code center
Logo_link = '../figs/representative_control_chart.png'

logo = Image.open(Logo_link)

# taking base width
basewidth = 250

# adjust image size
wpercent = (basewidth/float(logo.size[0]))
hsize = int((float(logo.size[1])*float(wpercent)))
logo = logo.resize((basewidth, hsize), Image.ANTIALIAS)
QRcode = qrcode.QRCode(
	error_correction=qrcode.constants.ERROR_CORRECT_H
)

# taking url or text
url = 'https://fmegahed.github.io/talks/isspm2023/generative_ai_spc.html'

# adding URL or text to QRcode
QRcode.add_data(url)

# generating QR code
QRcode.make()

# taking color name from user
QRcolor = 'Gray'

# adding color to QR code
QRimg = QRcode.make_image(
	fill_color=QRcolor, back_color="white").convert('RGB')

# set size of QR code
pos = ((QRimg.size[0] - logo.size[0]) // 2,
	(QRimg.size[1] - logo.size[1]) // 2)
QRimg.paste(logo, pos)

# save the QR code generated
QRimg.save('../figs/generative_ai_qr_code.png')

print('QR code generated!')

import os
print(os.getcwd())
