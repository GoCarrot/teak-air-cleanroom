# frozen_string_literal: true

require 'rake/clean'
require 'shellwords'
require 'mustache'
require 'httparty'
CLEAN.include '**/.DS_Store'

desc 'Build Adobe Air package'
task :default

ADOBE_AIR_HOME = ENV.fetch('ADOBE_AIR_HOME', '/usr/local/share/adobe-air-sdk')

PROJECT_PATH = Rake.application.original_dir

TEAK_AIR_CLEANROOM_BUNDLE_ID = ENV.fetch('TEAK_AIR_CLEANROOM_BUNDLE_ID', 'io.teak.app.air.dev')
TEAK_AIR_CLEANROOM_APP_ID = ENV.fetch('TEAK_AIR_CLEANROOM_APP_ID', '613659812345256')
TEAK_AIR_CLEANROOM_API_KEY = ENV.fetch('TEAK_AIR_CLEANROOM_API_KEY', '41ff00cfd4cb85702e265aa3d5ab7858')

# Builtin AIR does not let us use iOS 12 Provisional (yet)
USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION = true

TEST_DISTRIQT = ENV.fetch('TEST_DISTRIQT', false)
TEST_DISTRIQT_NOTIF = ENV.fetch('TEST_DISTRIQT_NOTIF', false)

KMS_KEY = `aws kms decrypt --ciphertext-blob fileb://kms/store_encryption_key.key --output text --query Plaintext | base64 --decode`.freeze
CIRCLE_TOKEN = ENV.fetch('CIRCLE_TOKEN') { `openssl enc -md MD5 -d -aes-256-cbc -in kms/encrypted_circle_ci_key.data -k #{KMS_KEY}` }
FORCE_CIRCLE_BUILD_ON_FETCH = ENV.fetch('FORCE_CIRCLE_BUILD_ON_FETCH', false)

def ci?
  ENV.fetch('CI', false).to_s == 'true'
end

def repack?
  ENV.fetch('REPACK', !ci?).to_s == 'true'
end

#
# Play a sound after finished
#
at_exit do
  sh 'afplay /System/Library/Sounds/Submarine.aiff' unless ci?
end

#
# Helper methods
#
def amxmlc(*args)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "#{ADOBE_AIR_HOME}/bin/amxmlc #{escaped_args}"
end

def fastlane(*args, env: {})
  env = {
    TEAK_AIR_CLEANROOM_BUNDLE_ID: TEAK_AIR_CLEANROOM_BUNDLE_ID,
    ADOBE_AIR_HOME: ADOBE_AIR_HOME
  }.merge(env)
  escaped_args = args.map { |arg| Shellwords.escape(arg) }.join(' ')
  sh "#{env.map { |k, v| "#{k}='#{v}'" }.join(' ')} bundle exec fastlane #{escaped_args}"
end

#
# Tasks
#
task :clean do
  sh 'git clean -fdx' unless ci?
end

namespace :package do
  task download: [:clean] do
    fastlane 'sdk'
  end

  task copy: [:clean] do
    fastlane 'sdk', env: { FL_TEAK_SDK_SOURCE: '../teak-air/' }
  end
end

namespace :build do
  task :air do
    distriqt_lines = ["-define+=CONFIG::test_distriqt,#{TEST_DISTRIQT}", "-define+=CONFIG::test_distriqt_notif,#{TEST_DISTRIQT_NOTIF}"]
    distriqt_lines << '-compiler.library-path=src/extensions/com.distriqt.Core.ane' if TEST_DISTRIQT
    distriqt_lines << '-compiler.library-path=src/extensions/com.distriqt.PushNotifications.ane' if TEST_DISTRIQT_NOTIF

    amxmlc *distriqt_lines, '-compiler.library-path=src/extensions/io.teak.sdk.Teak.ane',
           '-compiler.library-path=src/extensions/AirFacebook.ane',
           "-define+=CONFIG::use_air_to_register_notifications,#{USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION}",
           "-define+=CONFIG::use_teak_to_register_notifications,#{!USE_BUILTIN_AIR_NOTIFICATION_REGISTRATION}",
           '-output', 'build/teak-air-cleanroom.swf', '-swf-version=29', '-default-size=320,480',
           '-default-background-color=#b1b1b1', '-debug', '-compiler.include-libraries=src/assets/feathers.swc,src/assets/MetalWorksMobileTheme.swc,src/assets/starling.swc',
           'src/io/teak/sdk/cleanroom/Test.as', 'src/io/teak/sdk/cleanroom/Main.as', 'src/Cleanroom.as'
  end

  task :app_xml do
    template = File.read(File.join(PROJECT_PATH, 'src', 'app.xml.template'))
    File.write(File.join(PROJECT_PATH, 'src', 'app.xml'), Mustache.render(template,
                                                                          bundle_id: TEAK_AIR_CLEANROOM_BUNDLE_ID,
                                                                          test_distriqt: TEST_DISTRIQT,
                                                                          test_distriqt_notif: TEST_DISTRIQT_NOTIF,
                                                                          application: repack? ? '' : 'android:name="io.teak.sdk.wrapper.Application"',
                                                                          app_id: TEAK_AIR_CLEANROOM_APP_ID,
                                                                          api_key: TEAK_AIR_CLEANROOM_API_KEY))
  end

  task android: [:app_xml] do
    fastlane 'android', 'build'

    # Test unpack/repack APK method of integration
    if repack?
      fastlane 'android', 'repack'
    else
      # No repack needed, just copy the file
      cp 'build/teak-air-cleanroom.apk', 'teak-air-cleanroom.apk'
    end
  end

  task ios: [:app_xml] do
    fastlane 'ios', 'build'
    fastlane 'ios', 'repack'
  end
end

namespace :deploy do
  task :ios do
    sh 'aws s3 cp teak-air-cleanroom.ipa s3://teak-build-artifacts/air-cleanroom/teak-air-cleanroom-`cat TEAK_VERSION`.ipa --acl public-read'
  end

  task :android do
    sh 'aws s3 cp teak-air-cleanroom.apk s3://teak-build-artifacts/air-cleanroom/teak-air-cleanroom-`cat TEAK_VERSION`.apk --acl public-read'
  end
end

namespace :install do
  task :ios, [:version] do
    ipa_path = 'teak-air-cleanroom.ipa'

    begin
      sh "ideviceinstaller --uninstall #{TEAK_AIR_CLEANROOM_BUNDLE_ID}"
    rescue StandardError
    end
    # https://github.com/libimobiledevice/libimobiledevice/issues/510#issuecomment-347175312
    sh "ideviceinstaller --install #{ipa_path}"
  end

  task :android, [:version] do
    apk_path = 'teak-air-cleanroom.apk'

    devicelist = `AndroidResources/devicelist`.split(',').collect(&:chomp)
    devicelist.each do |device|
      adb = ->(*lambda_args) { sh "adb -s #{device} #{lambda_args.join(' ')}" }

      begin
        adb.call "uninstall #{TEAK_AIR_CLEANROOM_BUNDLE_ID}"
      rescue StandardError
      end
      adb.call "install #{apk_path}"
      adb.call "shell am start -n #{TEAK_AIR_CLEANROOM_BUNDLE_ID}/#{TEAK_AIR_CLEANROOM_BUNDLE_ID}.AppEntry"
    end
  end
end

namespace :android do
  task :kill do
    devicelist = `AndroidResources/devicelist`.split(',').collect(&:chomp)
    devicelist.each do |device|
      adb = ->(*args) { sh "adb -s #{device} #{args.join(' ')}" }
      adb.call 'shell', 'pm', 'clear', TEAK_AIR_CLEANROOM_BUNDLE_ID
    end
  end
end
