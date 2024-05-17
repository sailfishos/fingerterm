Name: fingerterm
Version: 1.3.12
Release: 1
Summary: A terminal emulator with a custom virtual keyboard
License: GPLv2
Source0: %{name}-%{version}.tar.gz
URL:     https://github.com/sailfishos/fingerterm/
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Gui)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt0Feedback)
BuildRequires: qt5-qttools-linguist
Requires: qt5-qtdeclarative-import-xmllistmodel
Requires: qt5-qtdeclarative-import-window2
Requires: nemo-qml-plugin-configuration-qt5

%description
%{summary}.

%package ts-devel
Summary:   Translation source for %{name}

%description ts-devel
Translation source for %{name}

%prep
%setup -q -n %{name}-%{version}

%build
qmake -qt=5 CONFIG+=enable-feedback DEFINES+='VERSION_STRING=\"\\\"\"%{version}\"\\\"\"'
%make_build

%install
%qmake5_install

%files
%license COPYING
%{_bindir}/*
%{_datadir}/applications/*.desktop
%{_datadir}/translations/%{name}_eng_en.qm
%{_datadir}/%{name}

%files ts-devel
%{_datadir}/translations/source/%{name}.ts
