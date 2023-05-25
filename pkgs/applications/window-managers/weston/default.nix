{ lib, stdenv, fetchurl
, meson, ninja, pkg-config, python3, wayland-scanner
, cairo, dbus, lcms2, libdrm, libevdev, libinput, libjpeg, seatd, libxkbcommon
, mesa, wayland, wayland-protocols
, pipewire ? null, pango ? null, freerdp ? null
, libXcursor ? null, libva ? null, libwebp ? null, xwayland ? null
# beware of null defaults, as the parameters *are* supplied by callPackage by default
, buildDemo ? true
, buildRemoting ? true, gst_all_1
}:

stdenv.mkDerivation rec {
  pname = "weston";
  version = "11.0.2";

  src = fetchurl {
    url = "https://gitlab.freedesktop.org/wayland/weston/-/releases/${version}/downloads/weston-${version}.tar.xz";
    hash = "sha256-ckB1LO8LfeYiuvi9U0jmP8axnwLvgklhsq3Rd9llKVI=";
  };

  depsBuildBuild = [ pkg-config ];
  nativeBuildInputs = [ meson ninja pkg-config python3 wayland-scanner ];
  buildInputs = [
    cairo dbus freerdp lcms2 libXcursor libdrm libevdev libinput libjpeg seatd
    libva libwebp libxkbcommon mesa pango pipewire wayland wayland-protocols
  ] ++ lib.optionals buildRemoting [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
  ];

  mesonFlags= [
    "-Dbackend-drm-screencast-vaapi=${lib.boolToString (libva != null)}"
    "-Dbackend-rdp=${lib.boolToString (freerdp != null)}"
    "-Dxwayland=${lib.boolToString (xwayland != null)}" # Default is true!
    (lib.mesonBool "remoting" buildRemoting)
    "-Dpipewire=${lib.boolToString (pipewire != null)}"
    "-Dimage-webp=${lib.boolToString (libwebp != null)}"
    (lib.mesonBool "demo-clients" buildDemo)
    "-Dsimple-clients="
    "-Dtest-junit-xml=false"
  ] ++ lib.optionals (xwayland != null) [
    "-Dxwayland-path=${xwayland.out}/bin/Xwayland"
  ];

  passthru.providedSessions = [ "weston" ];

  meta = with lib; {
    description = "A lightweight and functional Wayland compositor";
    longDescription = ''
      Weston is the reference implementation of a Wayland compositor, as well
      as a useful environment in and of itself.
      Out of the box, Weston provides a very basic desktop, or a full-featured
      environment for non-desktop uses such as automotive, embedded, in-flight,
      industrial, kiosks, set-top boxes and TVs. It also provides a library
      allowing other projects to build their own full-featured environments on
      top of Weston's core. A small suite of example or demo clients are also
      provided.
    '';
    homepage = "https://gitlab.freedesktop.org/wayland/weston";
    license = licenses.mit; # Expat version
    platforms = platforms.linux;
    maintainers = with maintainers; [ primeos ];
  };
}
