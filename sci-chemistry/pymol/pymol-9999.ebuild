# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

PYTHON_MODNAME="chempy pmg_tk pymol"
APBS_PATCH="090618"

inherit distutils subversion flag-o-matic

ESVN_REPO_URI="https://pymol.svn.sourceforge.net/svnroot/pymol/trunk/pymol"

DESCRIPTION="A Python-extensible molecular graphics system."
HOMEPAGE="http://pymol.sourceforge.net/"
SRC_URI=""

LICENSE="PSF-2.2"
IUSE="apbs numpy shaders vmd"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="dev-lang/python[tk]
		dev-python/numpy
		dev-python/pmw
		media-libs/freetype:2
		media-libs/libpng
		media-video/mpeg-tools
		sys-libs/zlib
		virtual/glut
		apbs? (
			sci-chemistry/pymol-apbs-plugin
			dev-libs/maloc
			sci-chemistry/apbs
			sci-chemistry/pdb2pqr
		)"
DEPEND="${RDEPEND}"

pkg_setup(){
	python_version
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-data-path.patch || die

	# Turn off splash screen.  Please do make a project contribution
	# if you are able though. #299020
	epatch "${FILESDIR}"/nosplash-gentoo.patch

	# Respect CFLAGS
	sed -i \
		-e "s:\(ext_comp_args=\).*:\1[]:g" \
		"${S}"/setup.py

	use shaders && \
		sed \
			-e '/PYMOL_OPENGL_SHADERS/s:^#::g' \
			-i setup.py

	use vmd && \
		sed \
			-e 's:\] + 0 \* \[:] + 1 * [:g' \
			-e '/contrib\/uiuc\/plugins/s:^#::g' \
			-e '/PYMOL_VMD_PLUGINS/s:^#::g' \
			-i setup.py

	use numpy && \
		sed \
			-e '/PYMOL_NUMPY/s:^#::g' \
			-i setup.py
}

src_configure() {
	:
}

src_install() {
	distutils_src_install

	# These environment variables should not go in the wrapper script, or else
	# it will be impossible to use the PyMOL libraries from Python.
	cat >> "${T}"/20pymol <<- EOF
		PYMOL_PATH=$(python_get_sitedir)/${PN}
		PYMOL_DATA="/usr/share/pymol/data"
		PYMOL_SCRIPTS="/usr/share/pymol/scripts"
	EOF

	doenvd "${T}"/20pymol || die "Failed to install env.d file."

	cat >> "${T}"/pymol <<- EOF
	#!/bin/sh
	${python} -O \${PYMOL_PATH}/__init__.py \$*
	EOF

	dobin "${T}"/pymol || die "Failed to install wrapper."

	insinto /usr/share/pymol
	doins -r test data scripts || die "no shared data"

	insinto /usr/share/pymol/examples
	doins -r examples || die "Failed to install docs."

	dodoc DEVELOPERS README || die "Failed to install docs."

	rm "${D}"$(python_get_sitedir)/pmg_tk/startup/apbs_tools.py
}
