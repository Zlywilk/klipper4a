# klipper4a (chroot install script)  
   <p align="center">
   <a aria-label="Discord" href="https://discord.gg/EAdA5kupxt">
      <img src="https://img.shields.io/discord/967461271974846544?color=%235865F2&label=discord&logo=discord&logoColor=white&style=flat-square">
  </a>
    </p>
    

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
if you use debian set image size
in the settings menu 
+ check Lock wifi
+ check Wake lock
+ in top right corner menu click install

## login to ssh
```bash
sudo apk add bash curl #if you use alpine
curl -O https://raw.githubusercontent.com/Zlywilk/klipper4a/master/moonraker-android.sh
```
+ edit script using your favorite editor to add printer config (if you want nano use "sudo apk add nano")
+ set serial to "$SERIAL"
+ run script 
```bash
bash moonraker-android.sh
```
## after reboot
+ start conteiner and run script
```bash
./start.sh
```
## Future features
+ [x] write script  for auto update if serial is changed
+ add update support for alpine in moonraker
+ [X] write debian script
+ write native app for android

## camera support
if you have existing installation edit file /etc/nginx/http.d/default.conf (alipine)
change from
```
listen 8080 default_server;
```
to
```
listen 8085 default_server;
```
and add to start.sh line after #!/bin/bash
```
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8085
```
now you can vist gui at port 80
## accelerometer
if you use accelerometer set line 237

and after evry restart run command
```
sudo chown -R "$USER":"$USER" /dev/ACM0 #your path to device
```
### method 1(use low resources but sometimes brake stream)
download IP Webcam form play store
<p align="center">
<a href="https://play.google.com/store/apps/details?id=com.pas.webcam" target="_blank"><img src="https://cdn.rawgit.com/steverichey/google-play-badge-svg/master/img/en_get.svg" width="50%" alt="play store icon"></a>
</p>
start ip webcam server

set camera url to /webcam/video

### method 2
download CamON Live Streaming form play store
<p align="center">
<a href="https://play.google.com/store/apps/details?id=com.spynet.camon" target="_blank"><img src="https://cdn.rawgit.com/steverichey/google-play-badge-svg/master/img/en_get.svg" width="50%" alt="play store icon"></a>
</p>
start CamON server

set camera url to /webcam/video/mjpeg
### obico(SpaghettiDetective)
first you must config and run camera in background if you run existing instalation simply run 
```bash
bash obico.sh
```
if you run fresh install you must remeber run camera in backgraund otherwise you don't get install promt
## FAQ
**Q:** why root?

**A:** there is one method (proot) which you can run linux on android whitout root but doesn't support mmap which is essential to run moonraker

## Disclaimer

```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

TL;DR: If your house burns down because this app malfunctioned, you cannot sue me.

## special thanks
+ [feelfreelinux](https://github.com/feelfreelinux) for octo4a
+ [knoopx](https://github.com/knoopx) for alpine-klipper
+ [meefik](https://github.com/meefik) for linuxdeploy
+ [Arksine](https://github.com/Arksine) for moonraker
+ [Cadriel](https://github.com/fluidd-core) for fluidd
+ [Mainsail-Crew](https://github.com/mainsail-crew) for mainsail
+ [lllgts](https://github.com/lllgts) for custom kernel for lg V30
