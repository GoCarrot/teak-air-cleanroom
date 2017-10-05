require "rake/clean"
require "shellwords"
require "mustache"
CLEAN.include "**/.DS_Store"

desc "Build Adobe Air package"
task :default

ADOBE_AIR_HOME = ENV.fetch('ADOBE_AIR_HOME', '/usr/local/share/adobe-air-sdk')

PROJECT_PATH = Rake.application.original_dir

KEYS_PATH = ENV.fetch('TEAK_AIR_CLEANROOM_KEYS', File.join(ENV['HOME'], 'teak-air-cleanroom-keys'))

BUNDLE_ID = ENV.fetch('TEAK_AIR_CLEANROOM_BUNDLE_ID', 'com.teakio.pushtest')

USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION = true

TEST_DISTRIQT = ENV.fetch('TEST_DISTRIQT', false)
TEST_DISTRIQT_NOTIF = ENV.fetch('TEST_DISTRIQT_NOTIF', false)

#
# Play a sound after finished
#
at_exit do
  sh "afplay /System/Library/Sounds/Submarine.aiff"
end

#
# Helper methods
#
def amxmlc(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "#{ADOBE_AIR_HOME}/bin/amxmlc #{escaped_args}"
end

def adt(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "AIR_NOANDROIDFLAIR=true #{ADOBE_AIR_HOME}/bin/adt #{escaped_args}"
end

def codesign(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "codesign #{escaped_args}"
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
    distriqt_lines = ["-define+=CONFIG::test_distriqt,#{TEST_DISTRIQT}", "-define+=CONFIG::test_distriqt_notif,#{TEST_DISTRIQT_NOTIF}"]
    if TEST_DISTRIQT then
      distriqt_lines << "-compiler.library-path=src/extensions/com.distriqt.Core.ane"
    end
    if TEST_DISTRIQT_NOTIF then
      distriqt_lines << "-compiler.library-path=src/extensions/com.distriqt.PushNotifications.ane"
    end

    amxmlc *distriqt_lines, "-compiler.library-path=src/extensions/io.teak.sdk.Teak.ane",
      "-compiler.library-path=src/extensions/AirFacebook.ane",
      "-define+=CONFIG::use_air_to_register_notifications,#{USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION}",
      "-define+=CONFIG::use_teak_to_register_notifications,#{!USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION}",
      "-output", "build/teak-air-cleanroom.swf", "-swf-version=29", "-default-size=320,480",
      "-default-background-color=#b1b1b1", "-debug", "-compiler.include-libraries=src/assets/feathers.swc,src/assets/MetalWorksMobileTheme.swc,src/assets/starling.swc",
      "src/io/teak/sdk/cleanroom/Test.as", "src/io/teak/sdk/cleanroom/Main.as", "src/Cleanroom.as"
  end

  task :app_xml do
    template = File.read(File.join(PROJECT_PATH, 'src', 'app.xml.template'))
    File.write(File.join(PROJECT_PATH, 'src', 'app.xml'), Mustache.render(template, {
      bundle_id: BUNDLE_ID, test_distriqt: TEST_DISTRIQT, test_distriqt_notif: TEST_DISTRIQT_NOTIF
    }))
  end

  task android: [:app_xml] do
    adt "-package", "-target", "apk-captive-runtime", "-keystore", "#{KEYS_PATH}/sample-android.p12",
      "-storetype", "pkcs12", "-storepass", "123456",
      "build/teak-air-cleanroom.apk", "src/app.xml", "src/mm.cfg", "-C", "build", "teak-air-cleanroom.swf",
      "-C", "src/assets", "teak-ea-icon-square-1024x1024.png", "teak-ea-icon-square-144x144.png",
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
debug.keystore = #{File.join(KEYS_PATH, 'sample-android.p12')}
debug.keypass = 123456
debug.alias = alias_name

release.storetype = pkcs12
release.keystore = #{File.join(KEYS_PATH, 'sample-android.p12')}
release.keypass = 123456
release.alias = alias_name
""")

    cd "../teak-air/android/repacker/" do
      sh "ant -Duse-config=#{config_path} unpack patch copy_res"
      cp_r "#{File.join(PROJECT_PATH, 'src', 'res')}", "#{File.join(PROJECT_PATH, 'build', '_apktemp')}"
      sh "ant -Duse-config=#{config_path} repack debug_sign zipalign"
    end
    #cp "build/teak-air-cleanroom.apk", "teak-air-cleanroom.apk"
  end

  task ios: [:app_xml] do
    adt "-package", "-target", "ipa-debug", "-keystore", "#{KEYS_PATH}/sample-ios.p12",
      "-storetype", "pkcs12", "-storepass", "123456",
      "-provisioning-profile", "#{KEYS_PATH}/sample-ios.mobileprovision",
      "build/teak-air-cleanroom.ipa", "src/app.xml", "src/mm.cfg", "-C", "build", "teak-air-cleanroom.swf",
      "-C", "src/assets", "teak-ea-icon-square-1024x1024.png", "teak-ea-icon-square-144x144.png",
      "Default@2x.png", "Default-568h@2x.png", "-extdir", "src/extensions"
    cp 'build/teak-air-cleanroom.ipa', 'teak-air-cleanroom.ipa'
  end
end

namespace :install do
  task :ios do
    begin
      sh "ideviceinstaller --uninstall #{BUNDLE_ID}"
    rescue
    end
    sh "ideviceinstaller --install teak-air-cleanroom.ipa"
  end

  task :android do
    devicelist = %x[AndroidResources/devicelist].split(',').collect{ |x| x.chomp }
    devicelist.each do |device|
      adb = lambda { |*args| sh "adb -s #{device} #{args.join(' ')}" }

      begin
        adb.call "uninstall #{BUNDLE_ID}"
      rescue
      end
      adb.call "install teak-air-cleanroom.apk"
      adb.call "shell am start -W -a android.intent.action.VIEW -d https://teakangrybots.jckpt.me/ESW-__uzW #{BUNDLE_ID}"
    end
  end
end
