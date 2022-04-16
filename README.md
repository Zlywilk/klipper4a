
# klipper4a (chroot install script)  

this script is for easy install kilpper gui (fluidd or Mainsail) on android based on [alpine-klipper](https://github.com/knoopx/alpine-klipper)

## requirements
+ phone(rooted)
+ sdcard
+ custiom kernel (sometimes if doesn't support serial drivers)
+ chroot( I recomended [linuxdeploy](https://github.com/meefik/linuxdeploy))
+ otg cable or usb hub

## set linuxdeploy
+ select description(alpine)
+ Distribution suite (last-stable[if you want compile on the phone])
+ set password
+ enable ssh
at the settings menu 
+ check Lock wifi
+ check Wake lock
+ at right corner menu click install

## login to ssh
```bash
curl -O https://raw.githubusercontent.com/Zlywilk/klipper4a/master/moonraker-android.sh
```
+ edit script using your favorite editor to add printer config (if you want nano use sudo apk add nano)
+ android doesn't support serial by id set serial to /dev/ttyA**
+ run script 
```bash
sh moonraker-android.sh
```
## after reboot
+ start conteiner and run script
```bash
./start.sh
```
## TO-DO
+ write script  for auto updating serial if change
+ port klipper scereen for alpine
+ add update support for alpine in moonraker
+ write debian script
+ write native app for android

## FAQ
**Q:** why root?

**A:** there is one method (proot) which you can run linux on android whitout root but doesn't support mmap which is essential to run moonraker

## special thanks
+ [feelfreelinux](https://github.com/feelfreelinux) for octo4a
+ [knoopx](https://github.com/knoopx) for alpine-klipper
+ [meefik](https://github.com/meefik) for linuxdeploy
+ [Arksine](https://github.com/Arksine) for moonraker
+ [Cadriel](https://github.com/fluidd-core) for fluidd
+ [Mainsail-Crew](https://github.com/mainsail-crew) for mainsail
+ [lllgts](https://github.com/lllgts) for custom kernel for lg V30
