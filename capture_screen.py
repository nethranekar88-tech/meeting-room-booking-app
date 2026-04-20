from PIL import ImageGrab

img = ImageGrab.grab()
img.save('assets/images/login_page.png')
print('saved', img.size)
