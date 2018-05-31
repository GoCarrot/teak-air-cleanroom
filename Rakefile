require "rake/clean"
require "shellwords"
require "mustache"
require "httparty"
CLEAN.include "**/.DS_Store"

desc "Build Adobe Air package"
task :default

ADOBE_AIR_HOME = ENV.fetch('ADOBE_AIR_HOME', '/usr/local/share/adobe-air-sdk')

PROJECT_PATH = Rake.application.original_dir

TEAK_AIR_CLEANROOM_BUNDLE_ID = ENV.fetch('TEAK_AIR_CLEANROOM_BUNDLE_ID', 'io.teak.app.air.dev')
TEAK_AIR_CLEANROOM_APP_ID = ENV.fetch('TEAK_AIR_CLEANROOM_APP_ID', '613659812345256')
TEAK_AIR_CLEANROOM_API_KEY = ENV.fetch('TEAK_AIR_CLEANROOM_API_KEY', '41ff00cfd4cb85702e265aa3d5ab7858')

REPACK = ENV.fetch('REPACK', false)

USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION = true

TEST_DISTRIQT = ENV.fetch('TEST_DISTRIQT', false)
TEST_DISTRIQT_NOTIF = ENV.fetch('TEST_DISTRIQT_NOTIF', false)

KMS_KEY = `aws kms decrypt --ciphertext-blob fileb://kms/store_encryption_key.key --output text --query Plaintext | base64 --decode`
CIRCLE_TOKEN = ENV.fetch('CIRCLE_TOKEN') { `openssl enc -md MD5 -d -aes-256-cbc -in kms/encrypted_circle_ci_key.data -k #{KMS_KEY}` }
FORCE_CIRCLE_BUILD_ON_FETCH = ENV.fetch('FORCE_CIRCLE_BUILD_ON_FETCH', false)

def ci?
  ENV.fetch('CI', false).to_s == 'true'
end

#
# Play a sound after finished
#
at_exit do
  sh "afplay /System/Library/Sounds/Submarine.aiff" unless ci?
end

#
# Helper methods
#
def amxmlc(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "#{ADOBE_AIR_HOME}/bin/amxmlc #{escaped_args}"
end

def fastlane(*args, env:{})
  env = {
    TEAK_AIR_CLEANROOM_BUNDLE_ID: TEAK_AIR_CLEANROOM_BUNDLE_ID,
    ADOBE_AIR_HOME: ADOBE_AIR_HOME
  }.merge(env)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "#{env.map{|k,v| "#{k}='#{v}'"}.join(' ')} bundle exec fastlane #{escaped_args}"
end

def build_and_fetch(version, extension)
  filename = "teak-air-cleanroom-#{version}.#{extension}"
  if FORCE_CIRCLE_BUILD_ON_FETCH.to_s == 'true' || %x[aws s3 ls s3://teak-build-artifacts/air-cleanroom/ | grep #{filename}].empty?

    # Kick off a CircleCI build for that version
    puts "Version #{version} not found in S3, triggering a CircleCI build..."
    response = HTTParty.post("https://circleci.com/api/v1.1/project/github/GoCarrot/teak-air-cleanroom/tree/master?circle-token=#{CIRCLE_TOKEN}",
                              {
                                body: {
                                  build_parameters:{
                                    FL_TEAK_SDK_VERSION: version
                                  }
                                }.to_json,
                                headers: {
                                  'Content-Type' => 'application/json',
                                  'Accept' => 'application/json'
                                }
                              })
    build_num = response['build_num']
    previous_build_time_ms = response['previous_successful_build']['build_time_millis']
    previous_build_time_sec = previous_build_time_ms * 0.001

    # Sleep for 3/4 of the previous build time
    puts "Previous successful build took #{previous_build_time_sec} seconds."
    puts "Waiting #{previous_build_time_sec * 0.90} seconds..."
    sleep(previous_build_time_sec * 0.90)

    loop do
      # Get status
      response = HTTParty.get("https://circleci.com/api/v1.1/project/github/GoCarrot/teak-air-cleanroom/#{build_num}?circle-token=#{CIRCLE_TOKEN}",
                              {format: :json})
      break unless response['status'] == "running"
      puts "Build status: #{response['status']}, checking again in #{previous_build_time_sec * 0.1} seconds"
      sleep(previous_build_time_sec * 0.1)
    end
  end
  sh "aws s3 sync s3://teak-build-artifacts/air-cleanroom/ . --exclude '*' --include '#{filename}'"
  filename
end

#
# Tasks
#
task :clean do
  sh "git clean -fdx" unless ci?
end

namespace :package do
  task download: [:clean] do
    fastlane "sdk"
  end

  task copy: [:clean] do
    fastlane "sdk", env: {FL_TEAK_SDK_SOURCE: '../teak-air/'}
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
      bundle_id: TEAK_AIR_CLEANROOM_BUNDLE_ID,
      test_distriqt: TEST_DISTRIQT,
      test_distriqt_notif: TEST_DISTRIQT_NOTIF,
      application: REPACK ? '' : 'android:name="io.teak.sdk.wrapper.Application"',
      app_id: TEAK_AIR_CLEANROOM_APP_ID,
      api_key: TEAK_AIR_CLEANROOM_API_KEY
    }))
  end

  task android: [:app_xml] do
    fastlane "android", "build"

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

teak.app_id = #{TEAK_AIR_CLEANROOM_APP_ID}
teak.api_key = #{TEAK_AIR_CLEANROOM_API_KEY}
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
    fastlane "ios", "build"
  end
end

namespace :deploy do
  task :ios do
    sh "aws s3 cp teak-air-cleanroom.ipa s3://teak-build-artifacts/air-cleanroom/teak-air-cleanroom-`cat TEAK_VERSION`.ipa --acl public-read"
  end

  task :android do
    sh "aws s3 cp teak-air-cleanroom.apk s3://teak-build-artifacts/air-cleanroom/teak-air-cleanroom-`cat TEAK_VERSION`.apk --acl public-read"
  end
end

namespace :install do
  task :ios, [:version] do |t, args|
    ipa_path = args[:version] ? build_and_fetch(args[:version], :ipa) : "teak-air-cleanroom.ipa"

    begin
      sh "ideviceinstaller --uninstall #{TEAK_AIR_CLEANROOM_BUNDLE_ID}"
    rescue
    end
    # https://github.com/libimobiledevice/libimobiledevice/issues/510#issuecomment-347175312
    sh "ideviceinstaller --install #{ipa_path}"
  end

  task :android, [:version] do |t, args|
    apk_path = args[:version] ? build_and_fetch(args[:version], :apk) : "teak-air-cleanroom.apk"

    devicelist = %x[AndroidResources/devicelist].split(',').collect{ |x| x.chomp }
    devicelist.each do |device|
      adb = lambda { |*args| sh "adb -s #{device} #{args.join(' ')}" }

      begin
        adb.call "uninstall #{TEAK_AIR_CLEANROOM_BUNDLE_ID}"
      rescue
      end
      adb.call "install #{apk_path}"
      adb.call "shell am start -n #{TEAK_AIR_CLEANROOM_BUNDLE_ID}/#{TEAK_AIR_CLEANROOM_BUNDLE_ID}.AppEntry"
    end
  end
end

namespace :android do
  task :kill do
    devicelist = %x[AndroidResources/devicelist].split(',').collect{ |x| x.chomp }
    devicelist.each do |device|
      adb = lambda { |*args| sh "adb -s #{device} #{args.join(' ')}" }
      adb.call "shell", "pm", "clear", TEAK_AIR_CLEANROOM_BUNDLE_ID
    end
  end
end
