

# Copy the contents

sudo cp Image /boot/Image-6.1.75-axon
sudo cp fusb302_fix.sh /usr/bin/
sudo cp fusb302_fix.service /etc/systemed/system/


# add chmod permission
sudo chmod +x /usr/bin/fusb302_fix.sh

# enable and start the service
sudo systemctl enable fusb302_fix.service
sudo systemctl start fusb302_fix.service 

# reboot the board
sudo sync
sudo reboot now

