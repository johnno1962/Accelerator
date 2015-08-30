Pod::Spec.new do |s|
    s.name     = 'Accelerator'
    s.version  = '100.9.9'
    s.license  = { :type => 'MIT', :file => 'LICENSE' }
    s.summary  = 'Inline fameworks of CocoaPods projects for faster launch'
    s.homepage = 'https://github.com/johnno1962/Accelerator'
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.authors  = { 'John Holdsworth' => 'suppport@injectionforxcode.com' }
    s.source   = { :git => 'https://github.com/johnno1962/Accelerator.git', :tag => s.version.to_s }

    s.source_files    = "Accelerator.{h,m}"
    s.preserve_paths  = "patch.rb"

    s.prepare_command = "echo 'Remember to patch using Pods/Accelerator/patch.rb'"
end
