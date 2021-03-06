Pod::Spec.new do |s|
	# info
	s.name = 'AppwiseCore'
	s.version = '0.10.4'
	s.summary = 'Just a library of some stuff we use internally.'
	s.description = <<-DESC
	Contains a few generic types (appdelegate, config, router, client) and some helper methods.
	DESC
	s.homepage = 'https://github.com/appwise-labs/AppwiseCore'
	s.authors = {
		'David Jennes' => 'david.jennes@gmail.com'
	}
	s.license = {
		:type => 'MIT',
		:file => 'LICENSE'
	}
	s.ios.deployment_target = '9.0'
	s.swift_version = '4.2'

	# files
	s.source = {
		:git => 'https://github.com/appwise-labs/AppwiseCore.git',
		:tag => s.version,
		:submodules => true
	}
	s.preserve_paths = ['Scripts/*', 'Sourcery/*']
	s.default_subspec = 'Core', 'Behaviours', 'UI'

	# VC behaviours
	s.subspec 'Behaviours' do |ss|
		ss.source_files = 'Sources/Behaviours/**/*.swift'

		# dependencies
		ss.dependency 'AppwiseCore/Common'
		ss.dependency 'Then', '~> 2.3'
	end

	# Common files
	s.subspec 'Common' do |ss|
		ss.source_files = 'Sources/Common/**/*.swift'
		ss.pod_target_xcconfig = {
			'SWIFT_ACTIVE_COMPILATION_CONDITIONS[config=Debug]' => 'DEBUG'
		}
	end

	# core spec
	s.subspec 'Core' do |ss|
		ss.source_files = 'Sources/Core/**/*.swift'
		ss.resource_bundles = {
			'AppwiseCore-Core' => ['Resources/Core/*.lproj']
		}

		# dependencies
		ss.dependency 'AppwiseCore/Common'
		ss.dependency 'Alamofire', '~> 4.7'
		ss.dependency 'CocoaLumberjack/Swift', '~> 3.4'
		ss.dependency 'CodableAlamofire', '~> 1.1'
		ss.dependency 'CrashlyticsRecorder', '~> 2.2'
		ss.dependency 'Then', '~> 2.4'
	end

	# coredata
	s.subspec 'CoreData' do |ss|
		ss.source_files = 'Sources/CoreData/**/*.swift'

		# dependencies
		ss.dependency 'AppwiseCore/Common'
		ss.dependency 'AppwiseCore/Core'
		ss.dependency 'Groot', '~> 3.0'
		ss.dependency 'SugarRecord/CoreData', '~> 3.1'
	end

	# deeplinking
	s.subspec 'DeepLink' do |ss|
		ss.source_files = 'Sources/DeepLink/**/*.swift'

		# dependencies
		ss.dependency 'AppwiseCore/Behaviours'
		ss.dependency 'AppwiseCore/Common'
	end

	# UI
	s.subspec 'UI' do |ss|
		ss.source_files = 'Sources/UI/**/*.swift'

		# dependencies
		ss.dependency 'AppwiseCore/Core'
		ss.dependency 'AppwiseCore/Behaviours'
		ss.dependency 'IBAnimatable', '~> 5.2'
	end
end
