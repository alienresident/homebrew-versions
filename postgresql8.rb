require 'formula'

class Postgresql8 < Formula
  homepage 'http://www.postgresql.org/'
  url 'http://ftp.postgresql.org/pub/source/v8.4.20/postgresql-8.4.20.tar.bz2'
  sha256 'e84e46083a6accd2bf37f0bd7253415649afcafc49f2564bc8481c10ed90d7c1'

  depends_on 'readline'
  depends_on 'libxml2' if MacOS.version == :leopard
  depends_on 'ossp-uuid' => :recommended

  option 'no-python', 'Build without Python support'
  option 'no-perl', 'Build without Perl support'

  # Fix build on 10.8 Mountain Lion
  # https://github.com/mxcl/homebrew/commit/cd77baf2e2f75b4ae141414bf8ff6d5c732e2b9a
  def patches
    DATA
  end

  def install
    ENV.libxml2 if MacOS.version >= :snow_leopard

    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --datadir=#{share}/#{name}
      --docdir=#{doc}
      --enable-thread-safety
      --with-gssapi
      --with-krb5
      --with-openssl
      --with-libxml
      --with-libxslt
    ]

    args << "--with-bonjour" unless MacOS.version >= :mavericks
    args << "--with-ossp-uuid" if build.with? 'ossp-uuid'
    args << "--with-python" unless build.include? 'no-python'
    args << "--with-perl" unless build.include? 'no-perl'

    if build.with? 'ossp-uuid'
      ENV.append 'CFLAGS', `uuid-config --cflags`.strip
      ENV.append 'LDFLAGS', `uuid-config --ldflags`.strip
      ENV.append 'LIBS', `uuid-config --libs`.strip
    end

    if MacOS.prefer_64_bit? and not build.include? 'no-python'
      args << "ARCHFLAGS='-arch x86_64'"
      check_python_arch
    end

    system "./configure", *args
    system "make install"

    %w[ adminpack dblink fuzzystrmatch lo uuid-ossp pg_buffercache pg_trgm
        pgcrypto tsearch2 vacuumlo xml2 intarray ].each do |a|
      system "cd contrib/#{a}; make install"
    end
  end

  def check_python_arch
    # On 64-bit systems, we need to look for a 32-bit Framework Python.
    # The configure script prefers this Python version, and if it doesn't
    # have 64-bit support then linking will fail.
    framework_python = Pathname.new "/Library/Frameworks/Python.framework/Versions/Current/Python"
    return unless framework_python.exist?
    unless (archs_for_command framework_python).include? :x86_64
      opoo "Detected a framework Python that does not have 64-bit support in:"
      puts <<-EOS.undent
          #{framework_python}

        The configure script seems to prefer this version of Python over any others,
        so you may experience linker problems as described in:
          http://osdir.com/ml/pgsql-general/2009-09/msg00160.html

        To fix this issue, you may need to either delete the version of Python
        shown above, or move it out of the way before brewing PostgreSQL.

        Note that a framework Python in /Library/Frameworks/Python.framework is
        the "MacPython" verison, and not the system-provided version which is in:
          /System/Library/Frameworks/Python.framework
      EOS
    end
  end

  def caveats
    s = <<-EOS.undent
      To build plpython against a specific Python, set PYTHON prior to brewing:
        PYTHON=/usr/local/bin/python brew install postgresql
      See:
        http://www.postgresql.org/docs/8.4/static/install-procedure.html


      If this is your first install, create a database with:
          initdb #{var}/postgres
    EOS

    s << gem_caveats if MacOS.prefer_64_bit?
    return s
  end

  def gem_caveats; <<-EOS.undent
    When installing the postgres gem, including ARCHFLAGS is recommended:
      ARCHFLAGS="-arch x86_64" gem install pg

    To install gems without sudo, see the Homebrew wiki.
    EOS
  end

  plist_options :manual => "pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres -l #{HOMEBREW_PREFIX}/var/postgres/server.log start"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_prefix}/bin/postgres</string>
        <string>-D</string>
        <string>#{var}/postgres</string>
        <string>-r</string>
        <string>#{var}/postgres/server.log</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
    </dict>
    </plist>
    EOS
  end
end

__END__
 # If we don't have a shared library and the platform doesn't allow it
--- a/contrib/uuid-ossp/uuid-ossp.c	2012-07-30 18:34:53.000000000 -0700
+++ b/contrib/uuid-ossp/uuid-ossp.c	2012-07-30 18:35:03.000000000 -0700
@@ -9,6 +9,8 @@
  *-------------------------------------------------------------------------
  */
 
+#define _XOPEN_SOURCE
+
 #include "postgres.h"
 #include "fmgr.h"
 #include "utils/builtins.h"

