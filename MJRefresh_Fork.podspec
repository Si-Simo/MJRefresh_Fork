Pod::Spec.new do |s|
    s.name         = 'MJRefresh_Fork'
    # 格式是MJ版本号拼接自身的版本号  (MJ版本号a.b.c + 自身版本号d.e.f = a.b.cdef)
    s.version      = '3.7.9101'
    s.summary      = 'Fork from MJRefresh'
    s.homepage     = 'https://github.com/Si-Simo/MJRefresh_Fork'
    s.license      = 'MIT'
    s.authors      = {'Si-Simo' => 'mhdtzhangshuai@163.com'}
    s.platform     = :ios, '12.0'
    s.source       = {:git => 'https://github.com/Si-Simo/MJRefresh_Fork.git', :tag => s.version}
    s.source_files = 'MJRefresh/**/*.{h,m}'
    s.exclude_files = 'MJRefresh/include/**'
    s.resource = 'MJRefresh/MJRefresh.bundle'
    s.resource_bundles = { 'MJRefresh.Privacy' => 'MJRefresh/PrivacyInfo.xcprivacy' }
    s.requires_arc = true
end
