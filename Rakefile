require "rake/clean"
require "shellwords"
CLEAN.include "**/.DS_Store"

desc "Build Adobe Air package"
task :default

PROJECT_PATH = Rake.application.original_dir

#
# Helper methods
#
def amxmlc(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "amxmlc #{escaped_args}"
end

def adt(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "AIR_NOANDROIDFLAIR=true adt #{escaped_args}"
end

#
# Tasks
#
task :clean do
  #sh "git clean -fdx"
  puts "DO CLEAN HERE WHEN DONE"
end

namespace :package do
  task download: [:clean] do
    sh "curl -o src/extensions/io.teak.sdk.Teak.ane https://s3.amazonaws.com/teak-build-artifacts/air/io.teak.sdk.Teak.ane"
  end

  task copy: [:clean] do
    cp '../teak-air/bin/io.teak.sdk.Teak.ane', 'src/extensions/io.teak.sdk.Teak.ane'
  end
end

namespace :build do
  task :air do
    amxmlc "-compiler.library-path=src/extensions/io.teak.sdk.Teak.ane",
      "-compiler.library-path=src/extensions/AirFacebook.ane",
      "-output", "build/teak-air-cleanroom.swf", "-swf-version=29", "-default-size=320,480",
      "-default-background-color=#b1b1b1", "-debug", "src/TeakCleanroom.as"
  end

  task :android do
    adt "-package", "-target", "apk-captive-runtime", "-keystore", "keys/sample-android.p12",
      "-storetype", "pkcs12", "-storepass", "123456",
      "build/teak-air-cleanroom.apk", "src/app.xml", "src/mm.cfg", "-C", "build", "teak-air-cleanroom.swf",
      "-C", "src/assets", "berlinSky.jpg", "londonSky.jpg", "sfSky.jpg", "placeholder.jpg",
      "Default@2x.png", "Default-568h@2x.png", "-extdir", "src/extensions"

    config_path = File.join(PROJECT_PATH, 'src', 'air-repack.config')
    File.write(config_path, """
android.build-tools = /usr/local/share/android-sdk/build-tools/25.0.2/
android.platform-tools = /usr/local/share/android-sdk/platform-tools/

temp.path = #{File.join(PROJECT_PATH, 'build', '_apktemp')}
temp.apk = #{File.join(PROJECT_PATH, 'build', '_temp.apk')}

input.apk = #{File.join(PROJECT_PATH, 'build', 'teak-air-cleanroom.apk')}
output.apk = #{File.join(PROJECT_PATH, 'teak-air-cleanroom.apk')}

teak.app_id = 1136371193060244
teak.api_key = 1f3850f794b9093864a0778009744d03
teak.gcm_sender_id = 944348058057

debug.storetype = pkcs12
debug.keystore = #{File.join(PROJECT_PATH, 'keys', 'sample-android.p12')}
debug.keypass = 123456
debug.alias = alias_name

release.storetype = pkcs12
release.keystore = #{File.join(PROJECT_PATH, 'keys', 'sample-android.p12')}
release.keypass = 123456
release.alias = alias_name
""")

    cd "../teak-air/android/repacker/" do
      sh "ant -Duse-config=#{config_path}"
    end
  end

  task :ios do
    adt "-package", "-target", "ipa-ad-hoc", "-keystore", "keys/sample-ios.p12",
      "-storetype", "pkcs12", "-storepass", "123456",
      "-provisioning-profile", "keys/sample-ios.mobileprovision",
      "build/teak-air-cleanroom.ipa", "src/app.xml", "src/mm.cfg", "-C", "build", "teak-air-cleanroom.swf",
      "-C", "src/assets", "berlinSky.jpg", "londonSky.jpg", "sfSky.jpg", "placeholder.jpg",
      "Default@2x.png", "Default-568h@2x.png", "-extdir", "src/extensions"
    cp 'build/teak-air-cleanroom.ipa', 'teak-air-cleanroom.ipa'
  end
end

namespace :install do
  task :ios do
    sh "ideviceinstaller -i teak-air-cleanroom.ipa"
  end

  task :android do
    devicelist = %x[AndroidResources/devicelist].split(',').collect{ |x| x.chomp }
    devicelist.each do |device|
      adb = lambda { |*args| sh "adb -s #{device} #{args.join(' ')}" }

      adb.call "uninstall com.teakio.pushtest"
      adb.call "install teak-air-cleanroom.apk"
      adb.call "shell am start -W -a android.intent.action.VIEW -d https://teakangrybots.jckpt.me/ESW-__uzW com.teakio.pushtest"
    end
  end
end
