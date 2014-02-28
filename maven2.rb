require 'formula'

class Maven2 < Formula
  homepage 'http://maven.apache.org/'
  url 'http://archive.apache.org/dist/maven/binaries/apache-maven-2.2.1-bin.tar.gz'
  sha1 '3ac63025e5860c4d856e172ab556d14b52f9b1f1'

  def install
    # Remove windows files
    rm_f Dir["bin/*.bat"]

    # Install jars in libexec to avoid conflicts
    prefix.install %w{ NOTICE.txt LICENSE.txt README.txt }
    libexec.install Dir['*']

    # Symlink binaries
    bin.mkpath
    Dir["#{libexec}/bin/*"].each do |f|
      ln_s f, bin+File.basename(f)
    end
  end

  def caveats; <<-EOS.undent
    WARNING: This older version will conflict with Maven if installed at the
    same time.
    EOS
  end
end
