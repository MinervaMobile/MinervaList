Pod::Spec.new do |s|
  s.name = "MinervaList"
  s.version = "3.0.0"
  s.license = { :type => 'MIT', :file => 'LICENSE' }

  s.summary = "A Swift MVVM Framework"
  s.homepage = "https://github.com/MinervaMobile/MinervaList"
  s.author = { "Joe Laws" => "joe.laws@gmail.com" }

  s.source = { :git => "https://github.com/MinervaMobile/MinervaList.git", :tag => s.version }

  s.default_subspecs = 'List'

  s.requires_arc = true
  s.swift_versions = '5.3'

  s.ios.deployment_target = '11.0'
  s.ios.frameworks = 'Foundation', 'UIKit'

  s.subspec 'List' do |ss|
    ss.source_files = 'Source/List/**/*.swift'

    ss.dependency 'IGListKit'

    ss.ios.deployment_target = '11.0'
    ss.ios.frameworks = 'Foundation', 'UIKit'

    ss.tvos.deployment_target = '11.0'
    ss.tvos.frameworks = 'Foundation', 'UIKit'
  end

end
