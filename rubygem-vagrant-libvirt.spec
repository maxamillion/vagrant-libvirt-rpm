# Based on the spec file that was generated from 
# vagrant-libvirt-0.0.18.gem by gem2rpm -*- rpm-spec -*-
%global gem_name vagrant-libvirt

Name: rubygem-%{gem_name}
Version: 0.0.16
Release: 1%{?dist}
Summary: Vagrant provider for libvirt
Group: Development/Languages
License: MIT
URL: https://github.com/pradels/vagrant-libvirt
Source0: https://rubygems.org/gems/%{gem_name}-%{version}.gem
Source1: https://gist.githubusercontent.com/purpleidea/8071962/raw/ee27c56e66aafdcb9fd9760f123e7eda51a6a51e/.bashrc_vagrant.sh
Source2: vagrant-libvirt.pkla
Requires: ruby(release)
Requires: ruby(rubygems) 
Requires: rubygem(fog) => 1.15
Requires: rubygem(fog) < 2
Requires: rubygem(ruby-libvirt) => 0.4.0
Requires: rubygem(ruby-libvirt) < 0.5
#Requires: rubygem(nokogiri) => 1.5.9
#Requires: rubygem(nokogiri) < 1.6
Requires: rubygem(nokogiri)
Requires: rubygem(multi_json)
Requires: polkit-pkla-compat
BuildRequires: ruby(release)
BuildRequires: rubygems-devel 
BuildRequires: ruby 
BuildArch: noarch
Provides: rubygem(%{gem_name}) = %{version}

%description
Vagrant provider for libvirt.


%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{name}.

%prep
gem unpack %{SOURCE0}

%setup -q -D -T -n  %{gem_name}-%{version}

gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

# %%gem_install compiles any C extensions and installs the gem into ./%%gem_dir
# by default, so that we can move it into the buildroot in %%install
%gem_install

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/
%mkdir -p %{buildroot}%{_sysconfdir}/profile.d
%cp %{SOURCE1} %{buildroot}%{_sysconfdir}/profile.d/vagrant-libvirt.sh
%chmod 755 %{buildroot}%{_sysconfdir}/profile.d/vagrant-libvirt.sh

# pkla file for users in vagrant group
%mkdir -p %{buildroot}%{_sysconfdir}/polkit-1/localauthority/50-local.d/
install -m 0644 -o root -g root %{SOURCE2} %{buildroot}%{_sysconfdir}/polkit-1/localauthority/50-local.d/vagrant-libvirt.pkla

%files
%dir %{gem_instdir}
%{gem_libdir}

%dir %{_sysconfdir}/profile.d
%{_sysconfdir}/profile.d/vagrant-libvirt.sh'

%dir %{_sysconfdir}/polkit-1/
%dir %{_sysconfdir}/polkit-1/localauthority/
%dir %{_sysconfdir}/polkit-1/localauthority/50-local.d/
%{_sysconfdir}/polkit-1/localauthority/50-local.d/vagrant-libvirt.pkla

%doc %dir %{gem_instdir}/example_box
%doc %{gem_instdir}/example_box

%doc %{gem_instdir}/CHANGELOG.md
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/vagrant-libvirt.gemspec

%dir %{gem_instdir}/locales
%{gem_instdir}/locales

%dir %{gem_instdir}/tools
%{gem_instdir}/tools

%exclude %{gem_cache}
%exclude %{gem_instdir}/.gitignore
%{gem_spec}

%files doc
%doc %{gem_docdir}

%changelog
* Fri Jun 27 2014 Adam Miller <maxamillion@fedoraproject.org> - 0.0.16-1
- Initial package for Fedora
