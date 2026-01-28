 Clone the repo on the Pi
 
cd /opt
sudo git clone https://github.com/morelos-ricardo/InkyRic eink
cd eink
sudo ./install.sh

This will download all files into /opt/eink
Your installer already points slideshow.py to /opt/eink/images
Put your images inside the images folder in the repo before cloning, or copy them afterward
