require "rake/clean"
require "shellwords"
require "mustache"
CLEAN.include "**/.DS_Store"

desc "Build Adobe Air package"
task :default

ADOBE_AIR_HOME = ENV.fetch('ADOBE_AIR_HOME', '/usr/local/share/adobe-air-sdk')

PROJECT_PATH = Rake.application.original_dir

BUNDLE_ID = ENV.fetch('TEAK_AIR_CLEANROOM_BUNDLE_ID', 'io.teak.app.air.dev')

REPACK = ENV.fetch('REPACK', false)

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

#
# Tasks
#
task :clean do
  #sh "git clean -fdx"
  puts "DO CLEAN HERE WHEN DONE"
end

namespace :package do
  task download: [:clean] do
    sh "bundle exec fastlane sdk"
  end

  task copy: [:clean] do
    sh "FL_TEAK_SDK_SOURCE='../teak-air/' bundle exec fastlane sdk"
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
      bundle_id: BUNDLE_ID,
      test_distriqt: TEST_DISTRIQT,
      test_distriqt_notif: TEST_DISTRIQT_NOTIF,
      application: REPACK ? '' : 'android:name="io.teak.sdk.wrapper.air.Application"'
    }))
  end

  task android: [:app_xml] do
    sh "bundle exec fastlane android build"

    # Test unpack/repack APK method of integration
    if REPACK
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
    else
      # No repack needed, just copy the file
      cp "build/teak-air-cleanroom.apk", "teak-air-cleanroom.apk"
    end
  end

  task ios: [:app_xml] do
    sh "bundle exec fastlane ios build"
  end
end

namespace :install do
  task :ios do
    begin
      sh "ideviceinstaller --uninstall #{BUNDLE_ID}"
    rescue
    end
    # https://github.com/libimobiledevice/libimobiledevice/issues/510#issuecomment-347175312
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
      adb.call "shell am start -n #{BUNDLE_ID}/#{BUNDLE_ID}.AppEntry"
    end
  end
end
