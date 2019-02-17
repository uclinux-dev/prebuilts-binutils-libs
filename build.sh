#!/bin/bash
# Distributed under the terms of the GNU General Public License v2

set -e

# The version of binutils we use.
PV="2.26.1"
PN="binutils"
P="${PN}-${PV}"
# Where to get the source.
SRC_URI="https://ftp.gnu.org/gnu/${PN}/${P}.tar.bz2"
# Where to save the source.
DISTDIR="${PWD}/distdir"

NCPUS=$(getconf _NPROCESSORS_ONLN)

ARCHES=(
	arm
	bfin
#	e1
	h8300
	m68k
	microblaze
#	nios
	nios2
	sh
	sparc
	v850
	xtensa
)
TARGETS=${ARCHES[@]/%/-elf}

run_configure() {
	CFLAGS='-Os -pipe' \
	"${S}"/configure \
		--disable-werror \
		--disable-nls \
		--without-zlib \
		--disable-shared \
		--enable-static \
		--disable-plugins \
		"$@" \
		>& configure.log
}

run_compile() {
	make all-{libiberty,bfd} -j${NCPUS} "$@" >& make.log
}

# Install headers & libs.
# run_install <source> <dest install path>
run_install() {
	local S="$1"
	local D="$2"

	rm -rf "${D}"
	mkdir -p "${D}"/{bfd,include/elf,libiberty}
	cp bfd/bfd.h bfd/libbfd.a "${D}"/bfd/
	cp libiberty/libiberty.a "${D}"/libiberty/
	cp \
		"${S}"/include/{ansidecl,filenames,hashtab,libiberty,symcat}.h \
		"${D}"/include/
	cp "${S}"/include/elf/{arm,bfin,h8,m68k,microblaze,nios2,reloc-macros,sh,sparc,v850,xtensa}.h "${D}"/include/elf/
}

# Build binutils for a single target.
# build <version> <arch> [tuple]
build() {
	local PV="$1"
	local P="${PN}-${PV}"
	local ARCH="$2"
	local S="${PWD}/${P}"
	local D="${PWD}/output/${ARCH}"
	local VD="${PWD}/output/${PV}"
	local WORKDIR="${PWD}/workdir/${ARCH}"
	local CTARGET="${3:-${ARCH}-elf}"

	echo "### Building ${P} ${ARCH} (${CTARGET})"
	rm -rf "${WORKDIR}"
	mkdir -p "${WORKDIR}"
	pushd "${WORKDIR}" >/dev/null
	run_configure --target="${CTARGET}" || return
	run_compile || return

	# Install everything to the arch dir.
	run_install "${S}" "${D}"
	# Move the headers over to the common dir.
	mkdir -p "${VD}"/{bfd,include}
	mv "${D}"/bfd/*.h "${VD}"/bfd/
	local f
	for f in "${D}"/bfd/*.h; do
		ln -sf ../../${PV}/bfd/${f##*/} "${D}"/bfd/
	done
	cp -pPR "${D}"/include/* "${VD}"/include/
	rm -rf "${D}"/include
	ln -s ../${PV}/include "${D}"/include

	popd >/dev/null
}

# Build binutils for multiple targets.
# build_multi <version> [targets]
build_multi() {
	local PV="$1"
	local P="${PN}-${PV}"
	local S="${PWD}/${P}"
	local D="${PWD}/output/${PV}"
	local WORKDIR="${PWD}/workdir/${PV}"

	shift
	echo "### Building ${P} $*"
	rm -rf "${WORKDIR}"
	mkdir -p "${WORKDIR}"
	pushd "${WORKDIR}" >/dev/null
	run_configure --enable-targets="$*" || return
	run_compile || return
	# Install everything.
	run_install "${S}" "${D}"
	popd >/dev/null
}

usage() {
	cat <<-EOF
Usage: $0

Build binutils for use by elf2flt.
EOF
	if [[ $# -gt 0 ]]; then
		echo "error: unknown argument: $1"
		exit 1
	else
		exit 0
	fi
}

main() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h|--help) usage ;;
		*) usage "$1" ;;
		esac
		shift
	done

	# Make sure the source is ready.
	if [[ ! -d ${P} ]]; then
		if [[ ! -e ${DISTDIR}/${P}.tar.bz2 ]]; then
			wget -c "${SRC_URI}" -P "${DISTDIR}"
		fi
		tar xf "${DISTDIR}"/${P}.tar.bz2
	fi

	# We only do multi now as we can get a smaller build.
	build_multi ${PV} "${TARGETS[@]}"
	return

	# Old logic for building one target at a time.
	local arch
	for arch in "${ARCHES[@]}"; do
		build ${PV} ${arch}
	done
}
main "$@"
