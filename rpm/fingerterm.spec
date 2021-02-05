Name: fingerterm
Version: 1.3.12
Release: 1
Summary: A terminal emulator with a custom virtual keyboard
License: GPLv2
Source0: %{name}-%{version}.tar.gz
URL:     https://git.sailfishos.org/mer-core/fingerterm
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Gui)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt0Feedback)
BuildRequires: pkgconfig(nemonotifications-qt5) >= 1.0.4
BuildRequires: qt5-qttools-linguist
Requires: qt5-qtdeclarative-import-xmllistmodel
Requires: qt5-qtdeclarative-import-window2
#Requires:  %{name}-all-translations
Obsoletes: meego-terminal <= 0.2.2
Provides: meego-terminal > 0.2.2

%description
%{summary}.

%package ts-devel
Summary:   Translation source for %{name}

%description ts-devel
Translation source for %{name}

%files
%defattr(-,root,root,-)
%{_bindir}/*
%{_datadir}/applications/*.desktop
%{_datadir}/translations/%{name}_eng_en.qm
%{_datadir}/%{name}

%files ts-devel
%defattr(-,root,root,-)
%{_datadir}/translations/source/%{name}.ts

%prep
%setup -q -n %{name}-%{version}

%build
qmake -qt=5 CONFIG+=enable-feedback CONFIG+=enable-nemonotifications DEFINES+='VERSION_STRING=\"\\\"\"%{version}\"\\\"\"'
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make INSTALL_ROOT=%{buildroot} install
