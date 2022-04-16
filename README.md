
# klipper4a (chroot install script)  

this script is for easy install kilpper gui (fluidd or Mainsail) for android based on [alpine-klipper](https://github.com/knoopx/alpine-klipper)

## requirements
+ phone (rooted)
+ sd card
+ custiom kernel (sometimes if not support by serial drivers)
+ chroot (I recomend [linuxdeploy](https://github.com/meefik/linuxdeploy))
+ otg cable or usb hub

## set linuxdeploy
+ select distribution (alpine)
+ Distribution suite (last-stable[if you want compile kilpper on a phone])
+ set password
+ enable ssh
in the settings menu 
+ check Lock wifi
+ check Wake lock
+ in top right corner menu click install

## login to ssh
```bash
curl -O https://raw.githubusercontent.com/Zlywilk/klipper4a/master/moonraker-android.sh
```
+ edit script using your favorite editor to add printer config (if you want nano use "sudo apk add nano")
+ android doesn't support serial by id therefore set serial to "/dev/ttyA**"
+ run script 
```bash
sh moonraker-android.sh
```
## after reboot
+ start conteiner and run script
```bash
./start.sh
```
## Future features
+ write script  for auto update if serial is changed
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
