Pod::Spec.new do |s|
  s.name             = 'SpeechRecognizerButton'
  s.version          = '0.1.8'
  s.summary          = 'UIButton subclass with push to talk recording, speech recognition and Siri-style waveform view'

  s.homepage         = 'https://github.com/alexruperez/SpeechRecognizerButton'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'Alex Rupérez' => 'contact@alexruperez.com' }
  s.source           = { :git => 'https://github.com/alexruperez/SpeechRecognizerButton.git', :tag => s.version.to_s }
  s.social_media_url = "https://twitter.com/alexruperez"

  s.ios.deployment_target = '10.0'

  s.source_files     ="SpeechRecognizerButton/*.{h,swift}"
end
