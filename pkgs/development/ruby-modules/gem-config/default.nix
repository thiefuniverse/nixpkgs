# The standard set of gems in nixpkgs including potential fixes.
#
# The gemset is derived from two points of entry:
# - An attrset describing a gem, including version, source and dependencies
#   This is just meta data, most probably automatically generated by a tool
#   like Bundix (https://github.com/aflatter/bundix).
#   {
#     name = "bundler";
#     version = "1.6.5";
#     sha256 = "1s4x0f5by9xs2y24jk6krq5ky7ffkzmxgr4z1nhdykdmpsi2zd0l";
#     dependencies = [ "rake" ];
#   }
# - An optional derivation that may override how the gem is built. For popular
#   gems that don't behave correctly, fixes are already provided in the form of
#   derivations.
#
# This seperates "what to build" (the exact gem versions) from "how to build"
# (to make gems behave if necessary).

{ lib, fetchurl, writeScript, ruby, kerberos, libxml2, libxslt, python, stdenv, which
, libiconv, postgresql, v8_3_16_14, clang, sqlite, zlib, imagemagick
, pkgconfig , ncurses, xapian_1_2_22, gpgme, utillinux, fetchpatch, tzdata, icu, libffi
, cmake, libssh2, openssl, mysql, darwin, git, perl, pcre, gecode_3, curl
, msgpack, qt59, libsodium, snappy, libossp_uuid, lxc, libpcap, xorg, gtk2, buildRubyGem
, cairo, re2, rake, gobject-introspection, gdk_pixbuf, zeromq, czmq, graphicsmagick, libcxx
, file, libvirt, glib, vips, taglib, libopus, linux-pam, libidn, protobuf
, libselinux ? null, libsepol ? null
}@args:

let
  v8 = v8_3_16_14;

  rainbow_rake = buildRubyGem {
    pname = "rake";
    gemName = "rake";
    source.sha256 = "01j8fc9bqjnrsxbppncai05h43315vmz9fwg28qdsgcjw9ck1d7n";
    type = "gem";
    version = "12.0.0";
  };
in

{
  atk = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ gtk2 pcre rake ];
  };

  bundler = attrs:
    let
      templates = "${attrs.ruby.gemPath}/gems/${attrs.gemName}-${attrs.version}/lib/bundler/templates/";
    in {
      # patching shebangs would fail on the templates/Executable file, so we
      # temporarily remove the executable flag.
      preFixup  = "chmod -x $out/${templates}/Executable";
      postFixup = ''
        chmod +x $out/${templates}/Executable

        # Allows to load another bundler version
        sed -i -e "s/activate_bin_path/bin_path/g" $out/bin/bundle
      '';
    };

  cairo = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ gtk2 pcre xorg.libpthreadstubs xorg.libXdmcp];
  };

  cairo-gobject = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ cairo pcre xorg.libpthreadstubs xorg.libXdmcp ];
  };

  capybara-webkit = attrs: {
    buildInputs = [ qt59.qtbase qt59.qtwebkit ] ++ stdenv.lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Cocoa ];
    NIX_CFLAGS_COMPILE = stdenv.lib.optionalString stdenv.isDarwin "-I${libcxx}/include/c++/v1";
  };

  charlock_holmes = attrs: {
    buildInputs = [ which icu zlib ];
  };

  cld3 = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ protobuf ];
  };

  curb = attrs: {
    buildInputs = [ curl ];
  };

  curses = attrs: {
    buildInputs = [ ncurses ];
  };

  dep-selector-libgecode = attrs: {
    USE_SYSTEM_GECODE = true;
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -i $installPath/lib/dep-selector-libgecode.rb -e 's@VENDORED_GECODE_DIR =.*@VENDORED_GECODE_DIR = "${gecode_3}"@'
    '';
  };

  digest-sha3 = attrs: {
    hardeningDisable = [ "format" ];
  };

  ethon = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace lib/ethon/curls/settings.rb \
        --replace "libcurl" "${curl.out}/lib/libcurl${stdenv.hostPlatform.extensions.sharedLibrary}"
    '';
  };

  fog-dnsimple = attrs: {
    postInstall = ''
      cd $(cat $out/nix-support/gem-meta/install-path)
      rm {$out/bin,bin,../../bin}/{setup,console}
    '';
  };

  redis-rack = attrs: {
    dontBuild = false;
    preBuild = ''
      exec 3>&1
      output="$(gem build $gemspec | tee >(cat - >&3))"
      exec 3>&-
      sed -i 's!"rake".freeze!!' $gemspec
    '';
  };

  ffi-rzmq-core = attrs: {
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -i $installPath/lib/ffi-rzmq-core/libzmq.rb -e 's@inside_gem =.*@inside_gem = "${zeromq}/lib"@'
    '';
  };

  mini_magick = attrs: {
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      echo -e "\nENV['PATH'] += ':${graphicsmagick}/bin'\n" >> $installPath/lib/mini_magick/configuration.rb
    '';
  };

  do_sqlite3 = attrs: {
    buildInputs = [ sqlite ];
  };

  eventmachine = attrs: {
    buildInputs = [ openssl ];
  };

  ffi = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ libffi ];
  };

  gdk_pixbuf2 = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ rake gdk_pixbuf ];
  };

  gpgme = attrs: {
    buildInputs = [ gpgme ];
  };

  gio2 = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ gtk2 pcre gobject-introspection ] ++ lib.optionals stdenv.isLinux [ utillinux libselinux libsepol ];
  };

  gitlab-markup = attrs: { meta.priority = 1; };

  glib2 = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ gtk2 pcre ];
  };

  gtk2 = attrs: {
    nativeBuildInputs = [ pkgconfig ] ++ lib.optionals stdenv.isLinux [ utillinux libselinux libsepol ];
    buildInputs = [ gtk2 pcre xorg.libpthreadstubs xorg.libXdmcp];
    # CFLAGS must be set for this gem to detect gdkkeysyms.h correctly
    CFLAGS = "-I${gtk2.dev}/include/gtk-2.0 -I/non-existent-path";
  };

  gobject-introspection = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ gobject-introspection gtk2 pcre ];
  };

  grpc = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ openssl ];
    hardeningDisable = [ "format" ];
    NIX_CFLAGS_COMPILE = [ "-Wno-error=stringop-overflow" "-Wno-error=implicit-fallthrough" ];
  };

  hitimes = attrs: {
    buildInputs =
      stdenv.lib.optionals stdenv.isDarwin
        [ darwin.apple_sdk.frameworks.CoreServices ];
  };

  iconv = attrs: {
    buildFlags = lib.optional stdenv.isDarwin "--with-iconv-dir=${libiconv}";
  };

  idn-ruby = attrs: {
    buildInputs = [ libidn ];
  };

  # disable bundle install as it can't install anything in addition to what is
  # specified in pkgs/applications/misc/jekyll/Gemfile anyway. Also do chmod_R
  # to compensate for read-only files in site_template in nix store.
  jekyll = attrs: {
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -i $installPath/lib/jekyll/commands/new.rb \
          -e 's@Exec.run("bundle", "install"@Exec.run("true"@' \
          -e 's@FileUtils.cp_r site_template + "/.", path@FileUtils.cp_r site_template + "/.", path; FileUtils.chmod_R "u+w", path@'
    '';
  };

  # note that you need version >= v3.16.14.8,
  # otherwise the gem will fail to link to the libv8 binary.
  # see: https://github.com/cowboyd/libv8/pull/161
  libv8 = attrs: {
    buildInputs = [ which v8 python ];
    buildFlags = [ "--with-system-v8=true" ];
  };

  libxml-ruby = attrs: {
    buildFlags = [
      "--with-xml2-lib=${libxml2.out}/lib"
      "--with-xml2-include=${libxml2.dev}/include/libxml2"
    ];
  };

  magic = attrs: {
    buildInputs = [ file ];
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -e 's@ENV\["MAGIC_LIB"\] ||@ENV\["MAGIC_LIB"\] || "${file}/lib/libmagic.so" ||@' -i $installPath/lib/magic/api.rb
    '';
  };

  metasploit-framework = attrs: {
    preInstall = ''
      export HOME=$TMPDIR
    '';
  };

  msgpack = attrs: {
    buildInputs = [ msgpack ];
  };

  mysql = attrs: {
    buildInputs = [ mysql.connector-c zlib openssl ];
  };

  mysql2 = attrs: {
    buildInputs = [ mysql.connector-c zlib openssl ];
  };

  ncursesw = attrs: {
    buildInputs = [ ncurses ];
    buildFlags = [
      "--with-cflags=-I${ncurses.dev}/include"
      "--with-ldflags=-L${ncurses.out}/lib"
    ];
  };

  nokogiri = attrs: {
    buildFlags = [
      "--use-system-libraries"
      "--with-zlib-dir=${zlib.dev}"
      "--with-xml2-lib=${libxml2.out}/lib"
      "--with-xml2-include=${libxml2.dev}/include/libxml2"
      "--with-xslt-lib=${libxslt.out}/lib"
      "--with-xslt-include=${libxslt.dev}/include"
      "--with-exslt-lib=${libxslt.out}/lib"
      "--with-exslt-include=${libxslt.dev}/include"
    ] ++ lib.optional stdenv.isDarwin "--with-iconv-dir=${libiconv}";
  };

  opus-ruby = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace lib/opus-ruby.rb \
        --replace "ffi_lib 'opus'" \
                  "ffi_lib '${libopus}/lib/libopus${stdenv.hostPlatform.extensions.sharedLibrary}'"
    '';
  };

  ovirt-engine-sdk = attrs: {
    buildInputs = [ curl libxml2 ];
  };

  pango = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ gtk2 xorg.libXdmcp pcre xorg.libpthreadstubs ];
  };

  patron = attrs: {
    buildInputs = [ curl ];
  };

  pcaprub = attrs: {
    buildInputs = [ libpcap ];
  };

  pg = attrs: {
    buildFlags = [
      "--with-pg-config=${postgresql}/bin/pg_config"
    ];
  };

  puma = attrs: {
    buildInputs = [ openssl ];
  };

  rainbow = attrs: {
    buildInputs = [ rainbow_rake ];
  };

  rbczmq = { ... }: {
    buildInputs = [ zeromq czmq ];
    buildFlags = [ "--with-system-libs" ];
  };

  rbnacl = spec:
    if lib.versionOlder spec.version "6.0.0" then {
      postInstall = ''
        sed -i $(cat $out/nix-support/gem-meta/install-path)/lib/rbnacl.rb -e "2a \
        RBNACL_LIBSODIUM_GEM_LIB_PATH = '${libsodium.out}/lib/libsodium${stdenv.hostPlatform.extensions.sharedLibrary}'
        "
      '';
    } else {
      buildInputs = [ libsodium ];
    };

  re2 = attrs: {
    buildInputs = [ re2 ];
  };

  rmagick = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ imagemagick which ];
  };

  rpam2 = attrs: {
    buildInputs = [ linux-pam ];
  };

  ruby-libvirt = attrs: {
    buildInputs = [ libvirt pkgconfig ];
    buildFlags = [
      "--with-libvirt-include=${libvirt}/include"
      "--with-libvirt-lib=${libvirt}/lib"
    ];
  };

  ruby-lxc = attrs: {
    buildInputs = [ lxc ];
  };

  ruby-terminfo = attrs: {
    buildInputs = [ ncurses ];
    buildFlags = [
      "--with-cflags=-I${ncurses.dev}/include"
      "--with-ldflags=-L${ncurses.out}/lib"
    ];
  };

  ruby-vips = attrs: {
    postInstall = ''
      cd "$(cat $out/nix-support/gem-meta/install-path)"

      substituteInPlace lib/vips.rb \
        --replace "glib-2.0" "${glib.out}/lib/libglib-2.0${stdenv.hostPlatform.extensions.sharedLibrary}"

      substituteInPlace lib/vips.rb \
        --replace "gobject-2.0" "${glib.out}/lib/libgobject-2.0${stdenv.hostPlatform.extensions.sharedLibrary}"

      substituteInPlace lib/vips.rb \
        --replace "vips_libname = 'vips'" "vips_libname = '${vips}/lib/libvips${stdenv.hostPlatform.extensions.sharedLibrary}'"
    '';
  };

  rugged = attrs: {
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ cmake openssl libssh2 zlib ];
    dontUseCmakeConfigure = true;
  };

  sassc = attrs: {
    nativeBuildInputs = [ rake ];
  };

  scrypt = attrs:
    if stdenv.isDarwin then {
      dontBuild = false;
      postPatch = ''
        sed -i -e "s/-arch i386//" Rakefile ext/scrypt/Rakefile
      '';
    } else {};

  semian = attrs: {
    buildInputs = [ openssl ];
  };

  sequel_pg = attrs: {
    buildInputs = [ postgresql ];
  };

  snappy = attrs: {
    buildInputs = [ args.snappy ];
  };

  sqlite3 = attrs: {
    buildFlags = [
      "--with-sqlite3-include=${sqlite.dev}/include"
      "--with-sqlite3-lib=${sqlite.out}/lib"
    ];
  };

  sup = attrs: {
    dontBuild = false;
    # prevent sup from trying to dynamically install `xapian-ruby`.
    nativeBuildInputs = [ rake ];
    postPatch = ''
      cp ${./mkrf_conf_xapian.rb} ext/mkrf_conf_xapian.rb

      substituteInPlace lib/sup/crypto.rb \
        --replace 'which gpg2' \
                  '${which}/bin/which gpg'
    '';
  };

  rb-readline = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace lib/rbreadline.rb \
        --replace 'infocmp' '${ncurses.dev}/bin/infocmp'
    '';
  };

  taglib-ruby = attrs: {
    buildInputs = [ taglib ];
  };

  thrift = attrs: {
    # See: https://stackoverflow.com/questions/36378190/cant-install-thrift-gem-on-os-x-el-capitan/36523125#36523125
    # Note that thrift-0.8.0 is a dependency of fluent-plugin-scribe which is a dependency of fluentd.
    buildFlags = lib.optional (stdenv.isDarwin && lib.versionOlder attrs.version "0.9.2.0")
      "--with-cppflags=\"-D_FORTIFY_SOURCE=0 -Wno-macro-redefined -Wno-shift-negative-value\"";
  };

  timfel-krb5-auth = attrs: {
    buildInputs = [ kerberos ];
  };

  tiny_tds = attrs: {
    nativeBuildInputs = [ pkgconfig openssl ];
  };

  therubyracer = attrs: {
    buildFlags = [
      "--with-v8-dir=${v8}"
      "--with-v8-include=${v8}/include"
      "--with-v8-lib=${v8}/lib"
    ];
  };

  typhoeus = attrs: {
    buildInputs = [ curl ];
  };

  tzinfo = attrs: lib.optionalAttrs (lib.versionAtLeast attrs.version "1.0") {
    dontBuild = false;
    postPatch =
      let
        path = if lib.versionAtLeast attrs.version "2.0"
               then "lib/tzinfo/data_sources/zoneinfo_data_source.rb"
               else "lib/tzinfo/zoneinfo_data_source.rb";
      in
        ''
          substituteInPlace ${path} \
            --replace "/usr/share/zoneinfo" "${tzdata}/share/zoneinfo"
        '';
  };

  uuid4r = attrs: {
    buildInputs = [ which libossp_uuid ];
  };

  xapian-ruby = attrs: {
    # use the system xapian
    dontBuild = false;
    nativeBuildInputs = [ rake pkgconfig ];
    buildInputs = [ xapian_1_2_22 zlib ];
    postPatch = ''
      cp ${./xapian-Rakefile} Rakefile
    '';
    preInstall = ''
      export XAPIAN_CONFIG=${xapian_1_2_22}/bin/xapian-config
    '';
  };

   zookeeper = attrs: {
     buildInputs = stdenv.lib.optionals stdenv.isDarwin [ darwin.cctools ];
   };

}
