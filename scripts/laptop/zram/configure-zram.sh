# Configures z-ram system process on arch for mbp t2 kernel.
# this can be validated by printing the configuration and checking the process monitor to see is swap is available,
pacman -Syu
swapon --show
systemctl status systemd-zram-setup@zram0.service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
cat /etc/systemd/zram-generator.conf
