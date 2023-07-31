# Maintainer: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
# Contributor: Jan de Groot <jgc@archlinux.org>

pkgbase=gstreamer
pkgname=(
  gstreamer
  gst-plugins-bad-libs   # Split badaudio first
  gst-plugins-base-libs
  gst-plugins-base
  gst-plugins-good
  gst-plugins-bad
  gst-plugin-gtk
  gst-plugin-msdk
  gst-plugin-opencv
  gst-plugin-qml6
  gst-plugin-qmlgl
  gst-plugin-qsv
  gst-plugin-va
  gst-plugin-wpe
  gst-plugins-ugly
  gst-libav
  gst-rtsp-server
  gst-editing-services
  gstreamer-vaapi
  gst-python
  gstreamer-docs
)
pkgver=1.22.2
pkgrel=1
pkgdesc="Multimedia graph framework"
url="https://gstreamer.freedesktop.org/"
arch=(x86_64)
license=(LGPL)
makedepends=(
  # superproject
  git meson

  # gstreamer
  valgrind libunwind gobject-introspection bash-completion gtk3 libcap python

  # gst-plugins-base
  cdparanoia graphene opus libtheora libxv sdl2 qt5-base qt5-tools zlib libglvnd
  wayland wayland-protocols libx11 libgudev libdrm mesa orc libxi

  # gst-plugins-good
  nasm v4l-utils aalib flac jack2 lame libcaca libdv mpg123 libraw1394
  libavc1394 libiec61883 qt5-declarative qt5-x11extras qt5-wayland libpulse
  libshout taglib twolame libvpx wavpack cairo libsoup3 qt6-declarative
  qt6-wayland qt6-tools nettle

  # gst-plugins-bad
  opencv vulkan-icd-loader vulkan-headers vulkan-validation-layers shaderc
  libltc bluez-libs libavtp libbs2b bzip2 chromaprint libdca faac faad2
  libfdk-aac fluidsynth libgme libkate liblrdf ladspa libde265 lilv libmodplug
  lv2 libmicrodns mjpegtools libmpcdec neon openal libdvdnav rtmpdump sbc
  soundtouch spandsp libsrtp svt-hevc zvbi libnice webrtc-audio-processing
  wildmidi zxing-cpp zbar libxml2 gsm libopenmpt wpewebkit libldac libfreeaptx
  qrencode json-glib libva libxkbcommon-x11

  # gst-plugins-ugly
  a52dec opencore-amr libcdio libdvdread libmpeg2 libsidplay x264

  # gst-libav
  ffmpeg

  # gstreamer-vaapi
  libxrandr

  # gst-python
  python-gobject
)
checkdepends=(xorg-server-xvfb)
source=(
  "git+https://gitlab.freedesktop.org/gstreamer/gstreamer.git?signed#tag=$pkgver"
  "https://gstreamer.freedesktop.org/src/gstreamer-docs/gstreamer-docs-$pkgver.tar.xz"{,.asc}
  0001-HACK-meson-Disable-broken-tests.patch
  0002-imagesequencesrc-Properly-set-default-location.patch
  0003-tests-allocators-Fix-fdmem-test-with-recent-GLib.patch
)
b2sums=('SKIP'
        '7156bcd222dd35d063711cafb86bb944cdd493362c945be57192be32987604f6bb1981c39c73f130347a108398907063cc7286f7d25950a0eeaa55c367888956'
        'SKIP'
        '9437da39122a15e6501a325193bce135b2706de72f6dd0133120b70ad1b05b8b0191aae4d740430ddfb9787164930cb184afa57ebd0b431edd9452317661d2e5'
        'fd5bfeaf5a08f225bfb81df1beac55c3d7332aa4ffb1ba0a3e662dccea6b5ca43eecee92578c54d2fc1e3aa2edc73eb09a02e9c0a8ac3ad2002995a6a0396fa2'
        '8ba563a47ef4aa063b244f0e2ca8be2aee2d61174bdd4affa86979131ef8862d44da0f1be2a965482fbe1a8bbaee5d8103fc6644806a78e2d977e3fd0e46ed23')
validpgpkeys=(D637032E45B8C6585B9456565D2EEE6F6F349D7C) # Tim Müller <tim@gstreamer-foundation.org>

prepare() {
  cd gstreamer

  # Disable broken tests
  git apply -3 ../0001-HACK-meson-Disable-broken-tests.patch

  # Fix crash
  # https://gitlab.freedesktop.org/gstreamer/gstreamer/-/merge_requests/4109
  git apply -3 ../0002-imagesequencesrc-Properly-set-default-location.patch

  # Fix fdmem test
  # https://gitlab.freedesktop.org/gstreamer/gstreamer/-/merge_requests/4381
  git apply -3 ../0003-tests-allocators-Fix-fdmem-test-with-recent-GLib.patch
}

build() {
  local meson_options=(
    # Superproject options
    -D devtools=disabled
    -D doc=disabled
    -D examples=disabled
    -D gobject-cast-checks=disabled
    -D gpl=enabled
    -D gst-examples=disabled
    -D libnice=disabled
    -D orc-source=system
    -D package-origin="https://www.archlinux.org/"
    -D vaapi=enabled

    # Package names
    -D gstreamer:package-name="Arch Linux gstreamer $pkgver-$pkgrel"
    -D gst-plugins-base:package-name="Arch Linux gst-plugins-base $pkgver-$pkgrel"
    -D gst-plugins-good:package-name="Arch Linux gst-plugins-good $pkgver-$pkgrel"
    -D gst-plugins-bad:package-name="Arch Linux gst-plugins-bad $pkgver-$pkgrel"
    -D gst-plugins-ugly:package-name="Arch Linux gst-plugins-ugly $pkgver-$pkgrel"
    -D gst-libav:package-name="Arch Linux gst-libav $pkgver-$pkgrel"
    -D gst-rtsp-server:package-name="Arch Linux gst-rtsp-server $pkgver-$pkgrel"

    # Subproject options
    -D gstreamer:dbghelp=disabled
    -D gstreamer:ptp-helper-permissions=capabilities
    -D gst-plugins-base:libvisual=disabled
    -D gst-plugins-base:tremor=disabled
    -D gst-plugins-good:rpicamsrc=disabled
    -D gst-plugins-bad:amfcodec=disabled
    -D gst-plugins-bad:directfb=disabled
    -D gst-plugins-bad:directshow=disabled
    -D gst-plugins-bad:directsound=disabled
    -D gst-plugins-bad:flite=disabled
    -D gst-plugins-bad:gs=disabled
    -D gst-plugins-bad:iqa=disabled
    -D gst-plugins-bad:isac=disabled
    -D gst-plugins-bad:magicleap=disabled
    -D gst-plugins-bad:onnx=disabled
    -D gst-plugins-bad:openh264=disabled
    -D gst-plugins-bad:openni2=disabled
    -D gst-plugins-bad:opensles=disabled
    -D gst-plugins-bad:tinyalsa=disabled
    -D gst-plugins-bad:voaacenc=disabled
    -D gst-plugins-bad:voamrwbenc=disabled
    -D gst-plugins-bad:wasapi2=disabled
    -D gst-plugins-bad:wasapi=disabled
    -D gst-plugins-bad:wic=disabled
    -D gst-plugins-bad:win32ipc=disabled
    -D gst-editing-services:validate=disabled
  )

  arch-meson gstreamer build "${meson_options[@]}"
  meson configure build  # Print config
  meson compile -C build
}

check() (
  export XDG_RUNTIME_DIR="$PWD/runtime-dir"
  mkdir -p -m 700 "$XDG_RUNTIME_DIR"

  # Flaky due to timeouts
  xvfb-run -s '-nolisten local' \
    meson test -C build --print-errorlogs -t 3
)

_install() {
  local src dir
  for src in "${files[@]}"; do
    dir="$pkgdir/$(dirname "$src")"
    mkdir -p "$dir"
    mv -v "$src" "$dir"
  done
}

package_gstreamer() {
  pkgdesc+=" - core"
  depends=(libxml2 glib2 libunwind libcap libelf)
  optdepends=('python: gst-plugins-doc-cache-generator')
  install=gstreamer.install

  DESTDIR="$srcdir/root" meson install -C build

  cd root; local files=(
    usr/include/gstreamer-1.0/gst/{base,check,controller,net,*.h}
    usr/lib/libgst{reamer,base,check,controller,net}-1.0.so*
    usr/lib/pkgconfig/gstreamer{,-base,-check,-controller,-net}-1.0.pc
    usr/lib/girepository-1.0/Gst{,Base,Check,Controller,Net}-1.0.typelib
    usr/share/gir-1.0/Gst{,Base,Check,Controller,Net}-1.0.gir

    usr/lib/gstreamer-1.0/gst-{completion,ptp}-helper
    usr/lib/gstreamer-1.0/gst-{hotdoc-plugins,plugin}-scanner
    usr/lib/gstreamer-1.0/gst-plugins-doc-cache-generator
    usr/lib/gstreamer-1.0/libgstcoreelements.so
    usr/lib/gstreamer-1.0/libgstcoretracers.so

    usr/share/locale/*/LC_MESSAGES/gstreamer-1.0.mo

    usr/bin/gst-{inspect,launch,stats,tester,typefind}-1.0
    usr/share/man/man1/gst-{inspect,launch,stats,typefind}-1.0.1

    usr/share/bash-completion/completions/gst-{inspect,launch}-1.0
    usr/share/bash-completion/helpers/gst

    usr/share/gdb/auto-load/usr/lib/libgstreamer-1.0.so*.py
    usr/share/gstreamer-1.0/gdb/glib_gobject_helper.py
    usr/share/gstreamer-1.0/gdb/gst_gdb.py

    usr/share/aclocal/gst-element-check-1.0.m4
  ); _install
}

package_gst-plugins-bad-libs() {
  pkgdesc+=" - bad"
  depends=(
    "gst-plugins-base-libs=$pkgver"
    orc libdrm libx11 libgudev libusb libxkbcommon-x11 libva libnice
    vulkan-icd-loader wayland wayland-protocols
  )

  cd root; local files=(
    usr/include/gstreamer-1.0/gst/audio/{audio-bad-prelude,gstnonstreamaudiodecoder,gstplanaraudioadapter}.h
    usr/include/gstreamer-1.0/gst/{basecamerabinsrc,codecparsers,cuda,insertbin,interfaces,isoff,mpegts,play,player,sctp,transcoder,uridownloader,va,vulkan,wayland,webrtc}
    usr/lib/libgst{adaptivedemux,badaudio,basecamerabinsrc,codecparsers,codecs,cuda,insertbin,isoff,mpegts}-1.0.so*
    usr/lib/libgst{photography,play,player,sctp,transcoder,uridownloader,va,vulkan,wayland,webrtc,webrtcnice}-1.0.so*
    usr/lib/pkgconfig/gstreamer-{bad-audio,codecparsers,cuda,insertbin,mpegts,photography,play,player,sctp,transcoder,vulkan{,-wayland,-xcb},va,wayland,webrtc{,-nice}}-1.0.pc
    usr/lib/girepository-1.0/{CudaGst,Gst{BadAudio,Codecs,Cuda,InsertBin,Mpegts,Play,Player,Transcoder,Va,Vulkan{,Wayland,XCB},WebRTC}}-1.0.typelib
    usr/share/gir-1.0/{CudaGst,Gst{BadAudio,Codecs,Cuda,InsertBin,Mpegts,Play,Player,Transcoder,Va,Vulkan{,Wayland,XCB},WebRTC}}-1.0.gir

    usr/lib/pkgconfig/gstreamer-plugins-bad-1.0.pc
    usr/lib/gstreamer-1.0/libgstaccurip.so
    usr/lib/gstreamer-1.0/libgstadpcmdec.so
    usr/lib/gstreamer-1.0/libgstadpcmenc.so
    usr/lib/gstreamer-1.0/libgstaiff.so
    usr/lib/gstreamer-1.0/libgstasfmux.so
    usr/lib/gstreamer-1.0/libgstaudiobuffersplit.so
    usr/lib/gstreamer-1.0/libgstaudiofxbad.so
    usr/lib/gstreamer-1.0/libgstaudiolatency.so
    usr/lib/gstreamer-1.0/libgstaudiomixmatrix.so
    usr/lib/gstreamer-1.0/libgstaudiovisualizers.so
    usr/lib/gstreamer-1.0/libgstautoconvert.so
    usr/lib/gstreamer-1.0/libgstbayer.so
    usr/lib/gstreamer-1.0/libgstbluez.so
    usr/lib/gstreamer-1.0/libgstcamerabin.so
    usr/lib/gstreamer-1.0/libgstcodecalpha.so
    usr/lib/gstreamer-1.0/libgstcodectimestamper.so
    usr/lib/gstreamer-1.0/libgstcoloreffects.so
    usr/lib/gstreamer-1.0/libgstdebugutilsbad.so
    usr/lib/gstreamer-1.0/libgstdecklink.so
    usr/lib/gstreamer-1.0/libgstdvb.so
    usr/lib/gstreamer-1.0/libgstdvbsubenc.so
    usr/lib/gstreamer-1.0/libgstdvbsuboverlay.so
    usr/lib/gstreamer-1.0/libgstdvdspu.so
    usr/lib/gstreamer-1.0/libgstfaceoverlay.so
    usr/lib/gstreamer-1.0/libgstfbdevsink.so
    usr/lib/gstreamer-1.0/libgstfestival.so
    usr/lib/gstreamer-1.0/libgstfieldanalysis.so
    usr/lib/gstreamer-1.0/libgstfreeverb.so
    usr/lib/gstreamer-1.0/libgstfrei0r.so
    usr/lib/gstreamer-1.0/libgstgaudieffects.so
    usr/lib/gstreamer-1.0/libgstgdp.so
    usr/lib/gstreamer-1.0/libgstgeometrictransform.so
    usr/lib/gstreamer-1.0/libgstid3tag.so
    usr/lib/gstreamer-1.0/libgstinter.so
    usr/lib/gstreamer-1.0/libgstinterlace.so
    usr/lib/gstreamer-1.0/libgstipcpipeline.so
    usr/lib/gstreamer-1.0/libgstivfparse.so
    usr/lib/gstreamer-1.0/libgstivtc.so
    usr/lib/gstreamer-1.0/libgstjp2kdecimator.so
    usr/lib/gstreamer-1.0/libgstjpegformat.so
    usr/lib/gstreamer-1.0/libgstkms.so
    usr/lib/gstreamer-1.0/libgstlegacyrawparse.so
    usr/lib/gstreamer-1.0/libgstmidi.so
    usr/lib/gstreamer-1.0/libgstmpegpsdemux.so
    usr/lib/gstreamer-1.0/libgstmpegpsmux.so
    usr/lib/gstreamer-1.0/libgstmpegtsdemux.so
    usr/lib/gstreamer-1.0/libgstmpegtsmux.so
    usr/lib/gstreamer-1.0/libgstmxf.so
    usr/lib/gstreamer-1.0/libgstnetsim.so
    usr/lib/gstreamer-1.0/libgstnvcodec.so
    usr/lib/gstreamer-1.0/libgstpcapparse.so
    usr/lib/gstreamer-1.0/libgstpnm.so
    usr/lib/gstreamer-1.0/libgstproxy.so
    usr/lib/gstreamer-1.0/libgstremovesilence.so
    usr/lib/gstreamer-1.0/libgstrfbsrc.so
    usr/lib/gstreamer-1.0/libgstrist.so
    usr/lib/gstreamer-1.0/libgstrtmp2.so
    usr/lib/gstreamer-1.0/libgstrtpmanagerbad.so
    usr/lib/gstreamer-1.0/libgstrtponvif.so
    usr/lib/gstreamer-1.0/libgstsdpelem.so
    usr/lib/gstreamer-1.0/libgstsegmentclip.so
    usr/lib/gstreamer-1.0/libgstshm.so
    usr/lib/gstreamer-1.0/libgstsiren.so
    usr/lib/gstreamer-1.0/libgstsmooth.so
    usr/lib/gstreamer-1.0/libgstspeed.so
    usr/lib/gstreamer-1.0/libgstsubenc.so
    usr/lib/gstreamer-1.0/libgstswitchbin.so
    usr/lib/gstreamer-1.0/libgsttranscode.so
    usr/lib/gstreamer-1.0/libgstuvch264.so
    usr/lib/gstreamer-1.0/libgstv4l2codecs.so
    usr/lib/gstreamer-1.0/libgstvideofiltersbad.so
    usr/lib/gstreamer-1.0/libgstvideoframe_audiolevel.so
    usr/lib/gstreamer-1.0/libgstvideoparsersbad.so
    usr/lib/gstreamer-1.0/libgstvideosignal.so
    usr/lib/gstreamer-1.0/libgstvmnc.so
    usr/lib/gstreamer-1.0/libgstvulkan.so
    usr/lib/gstreamer-1.0/libgstwaylandsink.so
    usr/lib/gstreamer-1.0/libgsty4mdec.so

    usr/share/gstreamer-1.0/encoding-profiles
    usr/share/gstreamer-1.0/presets/GstFreeverb.prs

    usr/share/locale/*/LC_MESSAGES/gst-plugins-bad-1.0.mo

    usr/bin/gst-transcoder-1.0
  ); _install
}

package_gst-plugins-base-libs() {
  pkgdesc+=" - base"
  depends=(
    "gstreamer=$pkgver"
    orc libxv iso-codes libgudev libgl mesa libxi wayland
  )

  cd root; local files=(
    usr/include/gstreamer-1.0/gst/{allocators,app,audio,fft,gl,pbutils,riff,rtp,rtsp,sdp,tag,video}
    usr/lib/libgst{allocators,app,audio,fft,gl,pbutils,riff,rtp,rtsp,sdp,tag,video}-1.0.so*
    usr/lib/pkgconfig/gstreamer-{allocators,app,audio,fft,gl{,-egl,-prototypes,-wayland,-x11},pbutils,riff,rtp,rtsp,sdp,tag,video}-1.0.pc
    usr/lib/girepository-1.0/Gst{Allocators,App,Audio,GL{,EGL,Wayland,X11},Pbutils,Rtp,Rtsp,Sdp,Tag,Video}-1.0.typelib
    usr/share/gir-1.0/Gst{Allocators,App,Audio,GL{,EGL,Wayland,X11},Pbutils,Rtp,Rtsp,Sdp,Tag,Video}-1.0.gir

    usr/lib/pkgconfig/gstreamer-plugins-base-1.0.pc
    usr/lib/gstreamer-1.0/include/gst/gl/gstglconfig.h
    usr/lib/gstreamer-1.0/libgstadder.so
    usr/lib/gstreamer-1.0/libgstapp.so
    usr/lib/gstreamer-1.0/libgstaudioconvert.so
    usr/lib/gstreamer-1.0/libgstaudiomixer.so
    usr/lib/gstreamer-1.0/libgstaudiorate.so
    usr/lib/gstreamer-1.0/libgstaudioresample.so
    usr/lib/gstreamer-1.0/libgstaudiotestsrc.so
    usr/lib/gstreamer-1.0/libgstcompositor.so
    usr/lib/gstreamer-1.0/libgstencoding.so
    usr/lib/gstreamer-1.0/libgstgio.so
    usr/lib/gstreamer-1.0/libgstoverlaycomposition.so
    usr/lib/gstreamer-1.0/libgstpbtypes.so
    usr/lib/gstreamer-1.0/libgstplayback.so
    usr/lib/gstreamer-1.0/libgstrawparse.so
    usr/lib/gstreamer-1.0/libgstsubparse.so
    usr/lib/gstreamer-1.0/libgsttcp.so
    usr/lib/gstreamer-1.0/libgsttypefindfunctions.so
    usr/lib/gstreamer-1.0/libgstvideoconvertscale.so
    usr/lib/gstreamer-1.0/libgstvideorate.so
    usr/lib/gstreamer-1.0/libgstvideotestsrc.so
    usr/lib/gstreamer-1.0/libgstvolume.so
    usr/lib/gstreamer-1.0/libgstximagesink.so
    usr/lib/gstreamer-1.0/libgstxvimagesink.so

    usr/share/locale/*/LC_MESSAGES/gst-plugins-base-1.0.mo

    usr/bin/gst-{device-monitor,discoverer,play}-1.0
    usr/share/man/man1/gst-{device-monitor,discoverer,play}-1.0.1

    usr/share/gst-plugins-base
  ); _install
}

package_gst-plugins-base() {
  pkgdesc+=" - base plugins"
  depends=(
    "gst-plugins-base-libs=$pkgver"
    alsa-lib cdparanoia libvorbis libtheora pango opus graphene libpng libjpeg
  )

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstalsa.so
    usr/lib/gstreamer-1.0/libgstcdparanoia.so
    usr/lib/gstreamer-1.0/libgstogg.so
    usr/lib/gstreamer-1.0/libgstopengl.so
    usr/lib/gstreamer-1.0/libgstopus.so
    usr/lib/gstreamer-1.0/libgstpango.so
    usr/lib/gstreamer-1.0/libgsttheora.so
    usr/lib/gstreamer-1.0/libgstvorbis.so
  ); _install
}

package_gst-plugins-good() {
  pkgdesc+=" - good plugins"
  depends=(
    "gst-plugins-base-libs=$pkgver"
    libpulse libsoup3 gst-plugins-base-libs wavpack aalib taglib libdv libshout
    libvpx gdk-pixbuf2 libcaca libavc1394 libiec61883 libxdamage v4l-utils cairo
    libgudev speex flac libraw1394 lame mpg123 twolame nettle
    libjack.so
  )

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgst1394.so
    usr/lib/gstreamer-1.0/libgstaasink.so
    usr/lib/gstreamer-1.0/libgstadaptivedemux2.so
    usr/lib/gstreamer-1.0/libgstalaw.so
    usr/lib/gstreamer-1.0/libgstalpha.so
    usr/lib/gstreamer-1.0/libgstalphacolor.so
    usr/lib/gstreamer-1.0/libgstapetag.so
    usr/lib/gstreamer-1.0/libgstaudiofx.so
    usr/lib/gstreamer-1.0/libgstaudioparsers.so
    usr/lib/gstreamer-1.0/libgstauparse.so
    usr/lib/gstreamer-1.0/libgstautodetect.so
    usr/lib/gstreamer-1.0/libgstavi.so
    usr/lib/gstreamer-1.0/libgstcacasink.so
    usr/lib/gstreamer-1.0/libgstcairo.so
    usr/lib/gstreamer-1.0/libgstcutter.so
    usr/lib/gstreamer-1.0/libgstdebug.so
    usr/lib/gstreamer-1.0/libgstdeinterlace.so
    usr/lib/gstreamer-1.0/libgstdtmf.so
    usr/lib/gstreamer-1.0/libgstdv.so
    usr/lib/gstreamer-1.0/libgsteffectv.so
    usr/lib/gstreamer-1.0/libgstequalizer.so
    usr/lib/gstreamer-1.0/libgstflac.so
    usr/lib/gstreamer-1.0/libgstflv.so
    usr/lib/gstreamer-1.0/libgstflxdec.so
    usr/lib/gstreamer-1.0/libgstgdkpixbuf.so
    usr/lib/gstreamer-1.0/libgstgoom.so
    usr/lib/gstreamer-1.0/libgstgoom2k1.so
    usr/lib/gstreamer-1.0/libgsticydemux.so
    usr/lib/gstreamer-1.0/libgstid3demux.so
    usr/lib/gstreamer-1.0/libgstimagefreeze.so
    usr/lib/gstreamer-1.0/libgstinterleave.so
    usr/lib/gstreamer-1.0/libgstisomp4.so
    usr/lib/gstreamer-1.0/libgstjack.so
    usr/lib/gstreamer-1.0/libgstjpeg.so
    usr/lib/gstreamer-1.0/libgstlame.so
    usr/lib/gstreamer-1.0/libgstlevel.so
    usr/lib/gstreamer-1.0/libgstmatroska.so
    usr/lib/gstreamer-1.0/libgstmonoscope.so
    usr/lib/gstreamer-1.0/libgstmpg123.so
    usr/lib/gstreamer-1.0/libgstmulaw.so
    usr/lib/gstreamer-1.0/libgstmultifile.so
    usr/lib/gstreamer-1.0/libgstmultipart.so
    usr/lib/gstreamer-1.0/libgstnavigationtest.so
    usr/lib/gstreamer-1.0/libgstoss4.so
    usr/lib/gstreamer-1.0/libgstossaudio.so
    usr/lib/gstreamer-1.0/libgstpng.so
    usr/lib/gstreamer-1.0/libgstpulseaudio.so
    usr/lib/gstreamer-1.0/libgstreplaygain.so
    usr/lib/gstreamer-1.0/libgstrtp.so
    usr/lib/gstreamer-1.0/libgstrtpmanager.so
    usr/lib/gstreamer-1.0/libgstrtsp.so
    usr/lib/gstreamer-1.0/libgstshapewipe.so
    usr/lib/gstreamer-1.0/libgstshout2.so
    usr/lib/gstreamer-1.0/libgstsmpte.so
    usr/lib/gstreamer-1.0/libgstsoup.so
    usr/lib/gstreamer-1.0/libgstspectrum.so
    usr/lib/gstreamer-1.0/libgstspeex.so
    usr/lib/gstreamer-1.0/libgsttaglib.so
    usr/lib/gstreamer-1.0/libgsttwolame.so
    usr/lib/gstreamer-1.0/libgstudp.so
    usr/lib/gstreamer-1.0/libgstvideo4linux2.so
    usr/lib/gstreamer-1.0/libgstvideobox.so
    usr/lib/gstreamer-1.0/libgstvideocrop.so
    usr/lib/gstreamer-1.0/libgstvideofilter.so
    usr/lib/gstreamer-1.0/libgstvideomixer.so
    usr/lib/gstreamer-1.0/libgstvpx.so
    usr/lib/gstreamer-1.0/libgstwavenc.so
    usr/lib/gstreamer-1.0/libgstwavpack.so
    usr/lib/gstreamer-1.0/libgstwavparse.so
    usr/lib/gstreamer-1.0/libgstximagesrc.so
    usr/lib/gstreamer-1.0/libgstxingmux.so
    usr/lib/gstreamer-1.0/libgsty4menc.so

    usr/share/gstreamer-1.0/presets/GstIirEqualizer{3,10}Bands.prs
    usr/share/gstreamer-1.0/presets/Gst{QTMux,VP8Enc}.prs

    usr/share/locale/*/LC_MESSAGES/gst-plugins-good-1.0.mo
  ); _install
}

package_gst-plugins-bad() {
  pkgdesc+=" - bad plugins"
  depends=(
    "gst-plugins-bad-libs=$pkgver"
    aom libass libbs2b bzip2 chromaprint pango lcms2 curl libxml2 libdc1394
    libde265 openssl libdca faac faad2 libfdk-aac fluidsynth libgme nettle
    libkate liblrdf lilv libmodplug mjpegtools libmpcdec neon openal openexr
    openjpeg2 opus libdvdnav libdvdread librsvg rtmpdump sbc libsndfile libltc
    soundtouch spandsp srt libsrtp zvbi libwebp webrtc-audio-processing wildmidi
    x265 zbar gsm libopenmpt libldac libfreeaptx qrencode json-glib libavtp
    libmicrodns svt-hevc zxing-cpp
  )

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstaes.so
    usr/lib/gstreamer-1.0/libgstaom.so
    usr/lib/gstreamer-1.0/libgstassrender.so
    usr/lib/gstreamer-1.0/libgstavtp.so
    usr/lib/gstreamer-1.0/libgstbs2b.so
    usr/lib/gstreamer-1.0/libgstbz2.so
    usr/lib/gstreamer-1.0/libgstchromaprint.so
    usr/lib/gstreamer-1.0/libgstclosedcaption.so
    usr/lib/gstreamer-1.0/libgstcolormanagement.so
    usr/lib/gstreamer-1.0/libgstcurl.so
    usr/lib/gstreamer-1.0/libgstdash.so
    usr/lib/gstreamer-1.0/libgstdc1394.so
    usr/lib/gstreamer-1.0/libgstde265.so
    usr/lib/gstreamer-1.0/libgstdtls.so
    usr/lib/gstreamer-1.0/libgstdtsdec.so
    usr/lib/gstreamer-1.0/libgstfaac.so
    usr/lib/gstreamer-1.0/libgstfaad.so
    usr/lib/gstreamer-1.0/libgstfdkaac.so
    usr/lib/gstreamer-1.0/libgstfluidsynthmidi.so
    usr/lib/gstreamer-1.0/libgstgme.so
    usr/lib/gstreamer-1.0/libgstgsm.so
    usr/lib/gstreamer-1.0/libgsthls.so
    usr/lib/gstreamer-1.0/libgstkate.so
    usr/lib/gstreamer-1.0/libgstladspa.so
    usr/lib/gstreamer-1.0/libgstldac.so
    usr/lib/gstreamer-1.0/libgstlv2.so
    usr/lib/gstreamer-1.0/libgstmicrodns.so
    usr/lib/gstreamer-1.0/libgstmodplug.so
    usr/lib/gstreamer-1.0/libgstmpeg2enc.so
    usr/lib/gstreamer-1.0/libgstmplex.so
    usr/lib/gstreamer-1.0/libgstmusepack.so
    usr/lib/gstreamer-1.0/libgstneonhttpsrc.so
    usr/lib/gstreamer-1.0/libgstopenal.so
    usr/lib/gstreamer-1.0/libgstopenaptx.so
    usr/lib/gstreamer-1.0/libgstopenexr.so
    usr/lib/gstreamer-1.0/libgstopenjpeg.so
    usr/lib/gstreamer-1.0/libgstopenmpt.so
    usr/lib/gstreamer-1.0/libgstopusparse.so
    usr/lib/gstreamer-1.0/libgstqroverlay.so
    usr/lib/gstreamer-1.0/libgstresindvd.so
    usr/lib/gstreamer-1.0/libgstrsvg.so
    usr/lib/gstreamer-1.0/libgstrtmp.so
    usr/lib/gstreamer-1.0/libgstsbc.so
    usr/lib/gstreamer-1.0/libgstsctp.so
    usr/lib/gstreamer-1.0/libgstsmoothstreaming.so
    usr/lib/gstreamer-1.0/libgstsndfile.so
    usr/lib/gstreamer-1.0/libgstsoundtouch.so
    usr/lib/gstreamer-1.0/libgstspandsp.so
    usr/lib/gstreamer-1.0/libgstsrt.so
    usr/lib/gstreamer-1.0/libgstsrtp.so
    usr/lib/gstreamer-1.0/libgstsvthevcenc.so
    usr/lib/gstreamer-1.0/libgstteletext.so
    usr/lib/gstreamer-1.0/libgsttimecode.so
    usr/lib/gstreamer-1.0/libgstttmlsubs.so
    usr/lib/gstreamer-1.0/libgstwebp.so
    usr/lib/gstreamer-1.0/libgstwebrtc.so
    usr/lib/gstreamer-1.0/libgstwebrtcdsp.so
    usr/lib/gstreamer-1.0/libgstwildmidi.so
    usr/lib/gstreamer-1.0/libgstx265.so
    usr/lib/gstreamer-1.0/libgstzbar.so
    usr/lib/gstreamer-1.0/libgstzxing.so
  ); _install
}

package_gst-plugin-gtk() {
  pkgdesc+=" - gtk plugin"
  depends=("gst-plugins-bad-libs=$pkgver" gtk3)

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstgtk.so
    usr/lib/gstreamer-1.0/libgstgtkwayland.so
  ); _install
}

package_gst-plugin-msdk() {
  pkgdesc+=" - msdk plugin"
  depends=("gst-plugins-bad-libs=$pkgver" libmfx)

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstmsdk.so
  ); _install
}

package_gst-plugin-opencv() {
  pkgdesc+=" - opencv plugin"
  depends=("gst-plugins-base-libs=$pkgver" opencv)

  cd root; local files=(
    usr/include/gstreamer-1.0/gst/opencv
    usr/lib/libgstopencv-1.0.so*

    usr/lib/gstreamer-1.0/libgstopencv.so
  ); _install
}

package_gst-plugin-qml6() {
  pkgdesc+=" - qml6 plugin"
  depends=(
    "gst-plugins-base-libs=$pkgver"
    qt6-declarative qt6-wayland
  )

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstqml6.so
  ); _install
}

package_gst-plugin-qmlgl() {
  pkgdesc+=" - qmlgl plugin"
  depends=(
    "gst-plugins-base-libs=$pkgver"
    qt5-declarative qt5-x11extras qt5-wayland
  )

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstqmlgl.so
  ); _install
}

package_gst-plugin-qsv() {
  pkgdesc+=" - qsv plugin"
  depends=("gst-plugins-bad-libs=$pkgver" libmfx)

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstqsv.so
  ); _install
}


package_gst-plugin-va() {
  pkgdesc+=" - va plugin"
  depends=("gst-plugins-bad-libs=$pkgver")

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstva.so
  ); _install
}

package_gst-plugin-wpe() {
  pkgdesc+=" - wpe plugin"
  depends=("gst-plugins-base-libs=$pkgver" wpewebkit)

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstwpe.so
    usr/lib/gst-plugins-bad/wpe-extension/libgstwpeextension.so
  ); _install
}

package_gst-plugins-ugly() {
  pkgdesc+=" - ugly plugins"
  depends=(
    "gst-plugins-base-libs=$pkgver"
    libdvdread libmpeg2 a52dec libsidplay libcdio x264 opencore-amr
  )

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgsta52dec.so
    usr/lib/gstreamer-1.0/libgstamrnb.so
    usr/lib/gstreamer-1.0/libgstamrwbdec.so
    usr/lib/gstreamer-1.0/libgstasf.so
    usr/lib/gstreamer-1.0/libgstcdio.so
    usr/lib/gstreamer-1.0/libgstdvdlpcmdec.so
    usr/lib/gstreamer-1.0/libgstdvdread.so
    usr/lib/gstreamer-1.0/libgstdvdsub.so
    usr/lib/gstreamer-1.0/libgstmpeg2dec.so
    usr/lib/gstreamer-1.0/libgstrealmedia.so
    usr/lib/gstreamer-1.0/libgstsid.so
    usr/lib/gstreamer-1.0/libgstx264.so

    usr/share/gstreamer-1.0/presets/Gst{Amrnb,X264}Enc.prs

    usr/share/locale/*/LC_MESSAGES/gst-plugins-ugly-1.0.mo
  ); _install
}

package_gst-libav() {
  pkgdesc+=" - libav plugin"
  depends=("gst-plugins-base-libs=$pkgver" bzip2 ffmpeg)
  provides=("gst-ffmpeg=$pkgver")

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstlibav.so
  ); _install
}

package_gst-rtsp-server() {
  pkgdesc+=" - rtsp server"
  depends=("gst-plugins-base-libs=$pkgver")

  cd root; local files=(
    usr/include/gstreamer-1.0/gst/rtsp-server
    usr/lib/libgstrtspserver-1.0.so*
    usr/lib/pkgconfig/gstreamer-rtsp-server-1.0.pc
    usr/lib/girepository-1.0/GstRtspServer-1.0.typelib
    usr/share/gir-1.0/GstRtspServer-1.0.gir

    usr/lib/gstreamer-1.0/libgstrtspclientsink.so
  ); _install
}

package_gst-editing-services() {
  pkgdesc+=" - editing services"
  depends=("gst-plugins-base-libs=$pkgver" python)

  cd root; local files=(
    usr/include/gstreamer-1.0/ges
    usr/lib/libges-1.0.so*
    usr/lib/pkgconfig/gst-editing-services-1.0.pc
    usr/lib/girepository-1.0/GES-1.0.typelib
    usr/share/gir-1.0/GES-1.0.gir

    usr/lib/gstreamer-1.0/libgstges.so
    usr/lib/gstreamer-1.0/libgstnle.so

    usr/lib/python*/site-packages/gi/overrides/GES.py

    usr/bin/ges-launch-1.0
    usr/share/man/man1/ges-launch-1.0.1

    usr/share/bash-completion/completions/ges-launch-1.0
  ); _install

  python -m compileall -d /usr/lib "$pkgdir/usr/lib"
  python -O -m compileall -d /usr/lib "$pkgdir/usr/lib"
}

package_gstreamer-vaapi() {
  pkgdesc+=" - vaapi plugin"
  depends=("gst-plugins-bad-libs=$pkgver" libxrandr)

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstvaapi.so
  ); _install
}

package_gst-python() {
  pkgdesc+=" - python plugin"
  depends=("gst-plugins-base-libs=$pkgver" python-gobject)

  cd root; local files=(
    usr/lib/gstreamer-1.0/libgstpython.so
    usr/lib/python*/site-packages/gi/overrides
  ); _install

  python -m compileall -d /usr/lib "$pkgdir/usr/lib"
  python -O -m compileall -d /usr/lib "$pkgdir/usr/lib"
}

package_gstreamer-docs() {
  pkgdesc+=" - documentation"
  license=(GPL3 LGPL custom:BSD custom:CC-BY-SA-4.0 custom:MIT custom:OPL)

  # make sure there are no files left to install
  find root -depth ! -type d
  find root -depth -print0 | xargs -0 rmdir

  cd gstreamer-docs-${pkgver%%+*}

  mkdir -p "$pkgdir/usr/share"
  cp -a devhelp "$pkgdir/usr/share/devhelp"

  install -Dt "$pkgdir/usr/share/licenses/$pkgname" -m644 COPYING LICENSE*
}

# vim:set sw=2 sts=-1 et:
